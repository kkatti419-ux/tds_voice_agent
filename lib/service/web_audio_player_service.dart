import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:universal_html/html.dart' as html;

import 'web_audio_js_bridge_stub.dart'
    if (dart.library.html) 'web_audio_js_bridge_web.dart' as js_bridge;

/// Console / DevTools filter: `VoiceAudio`
const String _kLogName = 'VoiceAudio';

/// Web [HTMLMediaElement.playbackRate] for TTS / URL playback (1.0 = normal).
const double _kWebPlaybackRate = 1.5;

void _voiceAudioLog(String message) {
  debugPrint('[$_kLogName] $message');
  developer.log(message, name: _kLogName);
}

void _voiceAudioLogPrint(String message) {
  _voiceAudioLog(message);
  print('[$_kLogName] $message');
}

class AudioPlayerService {
  FlutterSoundPlayer? _player;
  html.AudioElement? _webAudio;
  final Queue<_QueueItem> _queue = Queue<_QueueItem>();
  bool _isPlaying = false;

  /// Correlates enqueue → PLAY_START → PLAY_DONE / PLAY_FAIL in DevTools.
  int _nextPlayId = 0;

  /// In-flight HTML playback await; [stop] completes this so [_playLoop] never hangs.
  Completer<void>? _activePlaybackCompleter;

  /// Blob URL for active [_playWebBytes] — revoked on [stop] and on natural completion.
  String? _activeBlobObjectUrl;

  int _stopGeneration = 0;

  /// Shared Web Audio context for TTS decode (matches proven HTML `decodeAudioData` flow).
  static dynamic _sharedDecodeContext;

  /// Current [AudioBufferSourceNode] — [stop] uses [stop](0) for instant interrupt like HTML.
  static dynamic _activeBufferSource;

  /// Creates / resumes the shared decode [AudioContext]. Call from mic start (user gesture).
  static Future<void> ensurePlaybackAudioContext() async {
    if (!kIsWeb) return;
    try {
      _sharedDecodeContext ??= js_bridge.createAudioContextOrNull();
      final ctx = _sharedDecodeContext;
      if (ctx == null) return;
      final state = ctx.state?.toString() ?? '';
      if (state == 'suspended') {
        await js_bridge.resumeAudioContextPromise(ctx);
        _voiceAudioLog('shared AudioContext resumed (was suspended)');
      }
    } catch (e) {
      _voiceAudioLog('ensurePlaybackAudioContext: $e');
    }
  }

  /// Resume suspended Web Audio context (helps after tab focus / background).
  static Future<void> resumeAudioContextIfNeeded() async {
    await ensurePlaybackAudioContext();
  }

  static void _stopActiveBufferSource() {
    final src = _activeBufferSource;
    _activeBufferSource = null;
    if (src == null) return;
    js_bridge.audioBufferSourceStop(src, 0);
    js_bridge.audioBufferSourceDisconnect(src);
  }

  /// [HTMLMediaElement.play] can reject with NotAllowedError until a user gesture;
  /// uses JS [play] + [resumeAudioContextIfNeeded] to avoid broken Promise interop
  /// on first plays (`JSNoSuchMethodError` / `non-function` from [promiseToFuture]).
  Future<void> _playElementWithRetry(
    html.AudioElement audio, {
    required String context,
  }) async {
    await resumeAudioContextIfNeeded();
    try {
      await js_bridge.playMediaElement(audio);
      return;
    } catch (e) {
      _voiceAudioLog(
        '$context: play() failed ($e) — retry after resume + short delay',
      );
      await resumeAudioContextIfNeeded();
      await Future<void>.delayed(const Duration(milliseconds: 48));
      try {
        audio.load();
      } catch (_) {}
      await js_bridge.playMediaElement(audio);
      _voiceAudioLog('$context: play() OK after retry');
    }
  }

  /// Stops queue, completes in-flight playback await, revokes blob URL, pauses element.
  Future<void> stop() async {
    _stopGeneration++;
    _voiceAudioLog(
      'stop #$_stopGeneration: abort in-flight + clear queue (pending=${_queue.length})',
    );

    _stopActiveBufferSource();
    _completeActivePlayback(reason: 'stop()');

    final pending = _queue.toList(growable: false);
    _queue.clear();
    for (final item in pending) {
      if (!item.completer.isCompleted) {
        item.completer.complete();
      }
    }

    try {
      if (kIsWeb) {
        _webAudio?.pause();
        _webAudio = null;
      } else {
        final player = _player;
        if (player != null) {
          await player.stopPlayer();
        }
      }
    } catch (_) {}
  }

  void _completeActivePlayback({required String reason}) {
    final c = _activePlaybackCompleter;
    if (c != null && !c.isCompleted) {
      _voiceAudioLog('complete active playback ($reason)');
      c.complete();
    }
    _activePlaybackCompleter = null;

    final u = _activeBlobObjectUrl;
    if (u != null) {
      try {
        html.Url.revokeObjectUrl(u);
        _voiceAudioLog('revokeObjectUrl ($reason)');
      } catch (_) {}
      _activeBlobObjectUrl = null;
    }
  }

  Future<void> play(String url) {
    final playId = ++_nextPlayId;
    final urlShort =
        url.length > 80 ? '${url.substring(0, 80)}…' : url;
    
    _voiceAudioLogPrint(
      'play URL ENQUEUE id=$playId url=$urlShort '
      'queueLen=${_queue.length} isPlaying=$_isPlaying stopGen=$_stopGeneration',
    );
    final completer = Completer<void>();
    _queue.add(_QueueItem.url(url, completer, playId));
    _voiceAudioLog('play URL ENQUEUED id=$playId queueLen=${_queue.length}');
    if (_isPlaying) return completer.future;

    _isPlaying = true;
    _playLoop();
    return completer.future;
  }

  /// Plays raw bytes from the server (e.g. TTS binary frames). Web only.
  Future<void> playBytes(Uint8List bytes) {
    if (!kIsWeb) {
      return Future<void>.value();
    }
    if (bytes.isEmpty) {
      return Future<void>.value();
    }
    final owned = Uint8List.fromList(bytes);
    final playId = ++_nextPlayId;
    _voiceAudioLogPrint(
      'playBytes ENQUEUE id=$playId len=${owned.length} '
      'queueLen=${_queue.length} isPlaying=$_isPlaying stopGen=$_stopGeneration',
    );
    final completer = Completer<void>();
    _queue.add(_QueueItem.bytes(owned, completer, playId));
    _voiceAudioLog('playBytes ENQUEUED id=$playId queueLen=${_queue.length}');
    if (_isPlaying) return completer.future;

    _isPlaying = true;
    _playLoop();
    return completer.future;
  }

  /// Waits until the playback queue is drained (best-effort for streamed TTS).
  Future<void> waitUntilPlaybackIdle() async {
    var spins = 0;
    while (_queue.isNotEmpty || _isPlaying) {
      await Future<void>.delayed(const Duration(milliseconds: 24));
      spins++;
      if (spins > 6000) {
        _voiceAudioLog(
          'waitUntilPlaybackIdle: timeout (queue=${_queue.length} playing=$_isPlaying)',
        );
        break;
      }
    }
  }

  Future<void> _playLoop() async {
    try {
      while (_queue.isNotEmpty) {
        final next = _queue.removeFirst();
        final kind = next.bytes != null ? 'bytes' : 'url';
        final detail = next.bytes != null
            ? 'len=${next.bytes!.length}'
            : () {
                final u = next.url!;
                return u.length > 72 ? 'url=${u.substring(0, 72)}…' : 'url=$u';
              }();
        _voiceAudioLogPrint(
          'PLAY_START id=${next.playId} kind=$kind $detail '
          'remainingQueue=${_queue.length} stopGen=$_stopGeneration',
        );

        try {
          if (kIsWeb) {
            if (next.bytes != null) {
              await _playWebBytes(next.bytes!, playId: next.playId);
            } else if (next.url != null) {
              await _playWeb(next.url!, playId: next.playId);
            }
          } else {
            if (next.url != null) {
              await _playNative(next.url!, playId: next.playId);
            }
          }
          if (!next.completer.isCompleted) next.completer.complete();
          _voiceAudioLogPrint(
            'PLAY_DONE id=${next.playId} kind=$kind stopGen=$_stopGeneration',
          );
        } catch (e) {
          _voiceAudioLogPrint(
            'PLAY_FAIL id=${next.playId} kind=$kind error=$e stopGen=$_stopGeneration',
          );
          if (!next.completer.isCompleted) {
            next.completer.completeError(e);
          }
        }
      }
    } finally {
      _isPlaying = false;
      _voiceAudioLog('_playLoop exit queueEmpty=${_queue.isEmpty}');
    }
  }

  Future<void> _playWeb(String url, {required int playId}) async {
    final done = Completer<void>();
    _activePlaybackCompleter = done;

    _webAudio?.pause();
    final audio = html.AudioElement(url);
    _webAudio = audio;
    _voiceAudioLog('url AudioElement created id=$playId');
    try {
      audio.setAttribute('playsinline', 'true');
      audio.setAttribute('webkit-playsinline', 'true');
    } catch (_) {}

    void completeSafe() {
      if (!done.isCompleted) done.complete();
      if (identical(_activePlaybackCompleter, done)) {
        _activePlaybackCompleter = null;
      }
    }

    audio.loop = false;
    audio.playbackRate = _kWebPlaybackRate;

    audio.onEnded.first.then((_) {
      _voiceAudioLog('url play: onEnded');
      completeSafe();
    });
    audio.onError.first.then((_) {
      _logMediaError(audio, context: 'play url');
      completeSafe();
    });

    try {
      _voiceAudioLog('url play: start');
      await _playElementWithRetry(audio, context: 'url');
    } catch (e) {
      _voiceAudioLog('play(url) threw after retry: $e');
      completeSafe();
      rethrow;
    }
    await done.future;
  }

  static String _headerHex(Uint8List b, int maxBytes) {
    final n = b.length < maxBytes ? b.length : maxBytes;
    final parts = <String>[];
    for (var i = 0; i < n; i++) {
      parts.add(b[i].toRadixString(16).padLeft(2, '0'));
    }
    return parts.join(' ');
  }

  /// Best-effort sniff for Blob MIME; wrong type often means silent decode failure.
  static String _guessAudioMime(Uint8List b) {
    if (b.length < 4) {
      return 'audio/mpeg';
    }
    if (b.length >= 12 &&
        b[0] == 0x52 &&
        b[1] == 0x49 &&
        b[2] == 0x46 &&
        b[3] == 0x46 &&
        b[8] == 0x57 &&
        b[9] == 0x41 &&
        b[10] == 0x56 &&
        b[11] == 0x45) {
      return 'audio/wav';
    }
    if (b.length >= 4 &&
        b[0] == 0x66 &&
        b[1] == 0x4c &&
        b[2] == 0x61 &&
        b[3] == 0x43) {
      return 'audio/flac';
    }
    if (b.length >= 4 &&
        b[0] == 0x4f &&
        b[1] == 0x67 &&
        b[2] == 0x67 &&
        b[3] == 0x53) {
      return 'audio/ogg';
    }
    if (b.length >= 4 &&
        b[0] == 0x1a &&
        b[1] == 0x45 &&
        b[2] == 0xdf &&
        b[3] == 0xa3) {
      return 'audio/webm';
    }
    if (b.length >= 3 &&
        b[0] == 0x49 &&
        b[1] == 0x44 &&
        b[2] == 0x33) {
      return 'audio/mpeg';
    }
    if (b.length >= 2 && b[0] == 0xff && (b[1] & 0xe0) == 0xe0) {
      return 'audio/mpeg';
    }
    if (b.length >= 2 && b[0] == 0xff && (b[1] & 0xf6) == 0xf0) {
      return 'audio/aac';
    }
    _voiceAudioLog(
      'mime fallback audio/mpeg — unknown header (first12=${_headerHex(b, 12)})',
    );
    return 'audio/mpeg';
  }

  void _logMediaError(html.AudioElement audio, {required String context}) {
    final err = audio.error;
    if (err != null) {
      _voiceAudioLog(
        'MediaError ($context): code=${err.code} message=${err.message}',
      );
    } else {
      _voiceAudioLog('MediaError ($context): (no error object)');
    }
  }

  Future<void> _playWebBytes(Uint8List bytes, {required int playId}) async {
    final sw = Stopwatch()..start();
    final mime = _guessAudioMime(bytes);
    final head4 = bytes.length >= 4 ? _headerHex(bytes, 4) : _headerHex(bytes, bytes.length);
    _voiceAudioLog(
      'playBytes pipeline id=$playId len=${bytes.length} mime=$mime header4=$head4',
    );

    if (await _tryPlayWebBytesDecode(bytes, playId: playId)) {
      _voiceAudioLogPrint(
        'playBytes DECODE_PATH_OK id=$playId elapsedMs=${sw.elapsedMilliseconds}',
      );
      return;
    }
    _voiceAudioLog('playBytes id=$playId decode skipped/failed → blob fallback');
    await _playWebBytesBlob(bytes, playId: playId);
    _voiceAudioLogPrint(
      'playBytes BLOB_PATH_DONE id=$playId elapsedMs=${sw.elapsedMilliseconds}',
    );
  }

  /// HTML reference: [AudioContext.decodeAudioData] + [AudioBufferSourceNode] queue.
  Future<bool> _tryPlayWebBytesDecode(Uint8List bytes, {required int playId}) async {
    try {
      await ensurePlaybackAudioContext();
      final ctx = _sharedDecodeContext;
      if (ctx == null) {
        _voiceAudioLog('decode id=$playId: no AudioContext');
        return false;
      }

      // Standalone buffer: exact WAV/MP3 length for decodeAudioData (no tail garbage).
      final payload = Uint8List.fromList(bytes);

      final decodeSw = Stopwatch()..start();
      final audioBuf = await js_bridge.decodeAudioDataPromise(
        ctx,
        payload.buffer,
      );
      decodeSw.stop();
      if (audioBuf == null) {
        _voiceAudioLog(
          'decode id=$playId: decodeAudioData returned null (${decodeSw.elapsedMilliseconds}ms)',
        );
        return false;
      }

      final done = Completer<void>();
      _activePlaybackCompleter = done;

      final src = js_bridge.audioContextCreateBufferSource(ctx);
      if (src == null) {
        _voiceAudioLog('decode id=$playId: createBufferSource returned null');
        return false;
      }
      js_bridge.audioBufferSourceSetBuffer(src, audioBuf as Object?);
      js_bridge.audioBufferSourceConnectToContextDestination(src, ctx);
      _activeBufferSource = src;

      js_bridge.setBufferSourceOnEnded(src, () {
        if (identical(_activeBufferSource, src)) {
          _activeBufferSource = null;
        }
        if (!done.isCompleted) done.complete();
        if (identical(_activePlaybackCompleter, done)) {
          _activePlaybackCompleter = null;
        }
      });

      js_bridge.audioBufferSourceStart(src, 0);
      _voiceAudioLogPrint(
        'WebAudio BUFFER_PLAYING id=$playId inLen=${bytes.length} '
        'decodeMs=${decodeSw.elapsedMilliseconds}',
      );
      await done.future; 
      _voiceAudioLog('WebAudio BUFFER_ENDED id=$playId inLen=${bytes.length}');
      return true;
    } catch (e) {
      _voiceAudioLog('decodeAudioData / WebAudio id=$playId: $e');
      return false;
    }
  }

  Future<void> _playWebBytesBlob(Uint8List bytes, {required int playId}) async {
    if (bytes.isEmpty) {
      _voiceAudioLog('blob id=$playId skip: empty payload (no blob URL)');
      return;
    }
    final mime = _guessAudioMime(bytes);
    final done = Completer<void>();
    _activePlaybackCompleter = done;

    _webAudio?.pause();
    final blob = html.Blob([bytes], mime);
    final url = html.Url.createObjectUrlFromBlob(blob);
    _activeBlobObjectUrl = url;

    final audio = html.AudioElement(url);
    _webAudio = audio;
    audio.loop = false;
    audio.playbackRate = _kWebPlaybackRate;
    try {
      audio.setAttribute('playsinline', 'true');
      audio.setAttribute('webkit-playsinline', 'true');
    } catch (_) {}

    void completeSafe() {
      if (!done.isCompleted) done.complete();
      if (identical(_activePlaybackCompleter, done)) {
        _activePlaybackCompleter = null;
      }
      final u = _activeBlobObjectUrl;
      if (u != null) {
        try {
          html.Url.revokeObjectUrl(u);
        } catch (_) {}
        _activeBlobObjectUrl = null;
      }
    }

    final canPlay = audio.canPlayType(mime);
    _voiceAudioLog('canPlayType("$mime") => "$canPlay"');

    audio.onEnded.first.then((_) {
      _voiceAudioLog('blob play: onEnded (len=${bytes.length})');
      completeSafe();
    });
    audio.onError.first.then((_) {
      _logMediaError(audio, context: 'blob playBytes');
      completeSafe();
    });

    try {
      _voiceAudioLogPrint(
        'blob play START id=$playId len=${bytes.length} mime=$mime',
      );
      await _playElementWithRetry(audio, context: 'blob');
      _voiceAudioLogPrint('blob play PLAY_RESOLVED id=$playId len=${bytes.length}');
    } catch (e) {
      _voiceAudioLogPrint(
        'blob play PLAY_FAILED id=$playId error=$e — if NotAllowedError, tap mic once to unlock audio',
      );
      _logMediaError(audio, context: 'after play() catch');
      completeSafe();
      rethrow;
    }
    await done.future;
  }

  Future<void> _playNative(String url, {required int playId}) async {
    _voiceAudioLog('native PLAY id=$playId url=${url.length > 64 ? "${url.substring(0, 64)}…" : url}');
    final player = _player ??= FlutterSoundPlayer();
    if (!player.isOpen()) {
      await player.openPlayer();
    }

    final done = Completer<void>();
    await player.startPlayer(
      fromURI: url,
      codec: Codec.mp3,
      whenFinished: () {
        if (!done.isCompleted) done.complete();
      },
    );

    await done.future;
    _voiceAudioLog('native PLAY_DONE id=$playId');
  }
}

class _QueueItem {
  _QueueItem.url(this.url, this.completer, this.playId) : bytes = null;
  _QueueItem.bytes(this.bytes, this.completer, this.playId) : url = null;

  final String? url;
  final Uint8List? bytes;
  final Completer<void> completer;
  final int playId;
}
