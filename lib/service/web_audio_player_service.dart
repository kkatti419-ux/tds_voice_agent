import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:universal_html/html.dart' as html;

/// Console / DevTools filter: `VoiceAudio`
const String _kLogName = 'VoiceAudio';

/// Web [HTMLMediaElement.playbackRate] for TTS / URL playback (1.0 = normal).
const double _kWebPlaybackRate = 1.3;

void _voiceAudioLog(String message) {
  debugPrint('[$_kLogName] $message');
  developer.log(message, name: _kLogName);
}

class AudioPlayerService {
  FlutterSoundPlayer? _player;
  html.AudioElement? _webAudio;
  final Queue<_QueueItem> _queue = Queue<_QueueItem>();
  bool _isPlaying = false;

  /// In-flight HTML playback await; [stop] completes this so [_playLoop] never hangs.
  Completer<void>? _activePlaybackCompleter;

  /// Blob URL for active [_playWebBytes] — revoked on [stop] and on natural completion.
  String? _activeBlobObjectUrl;

  int _stopGeneration = 0;

  /// Resume suspended Web Audio context (helps after tab focus / background).
  static Future<void> resumeAudioContextIfNeeded() async {
    if (!kIsWeb) return;
    try {
      final w = html.window as dynamic;
      final ctor = w.AudioContext;
      if (ctor == null) return;
      final ctx = ctor() as dynamic;
      final state = ctx.state?.toString() ?? '';
      if (state == 'suspended') {
        await ctx.resume();
        _voiceAudioLog('AudioContext resumed (was suspended)');
      }
    } catch (e) {
      _voiceAudioLog('AudioContext resume skipped: $e');
    }
  }

  /// [HTMLMediaElement.play] can reject with NotAllowedError until a user gesture;
  /// [resumeAudioContextIfNeeded] then one retry often succeeds after mic tap unlocks audio.
  Future<void> _playElementWithRetry(
    html.AudioElement audio, {
    required String context,
  }) async {
    try {
      await audio.play();
      return;
    } catch (e) {
      _voiceAudioLog(
        '$context: play() failed ($e) — retry after AudioContext resume',
      );
      await resumeAudioContextIfNeeded();
      await audio.play();
      _voiceAudioLog('$context: play() OK after retry');
    }
  }

  /// Stops queue, completes in-flight playback await, revokes blob URL, pauses element.
  Future<void> stop() async {
    _stopGeneration++;
    _voiceAudioLog(
      'stop #$_stopGeneration: abort in-flight + clear queue (pending=${_queue.length})',
    );

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
    final completer = Completer<void>();
    _queue.add(_QueueItem.url(url, completer));
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
    final completer = Completer<void>();
    _queue.add(_QueueItem.bytes(bytes, completer));
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

        try {
          if (kIsWeb) {
            if (next.bytes != null) {
              await _playWebBytes(next.bytes!);
            } else if (next.url != null) {
              await _playWeb(next.url!);
            }
          } else {
            if (next.url != null) {
              await _playNative(next.url!);
            }
          }
          if (!next.completer.isCompleted) next.completer.complete();
        } catch (e) {
          _voiceAudioLog('_playLoop item error: $e');
          if (!next.completer.isCompleted) {
            next.completer.completeError(e);
          }
        }
      }
    } finally {
      _isPlaying = false;
      _voiceAudioLog('_playLoop exit');
    }
  }

  Future<void> _playWeb(String url) async {
    final done = Completer<void>();
    _activePlaybackCompleter = done;

    _webAudio?.pause();
    final audio = html.AudioElement(url);
    _webAudio = audio;

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
    if (b.length >= 3 && b[0] == 0x49 && b[1] == 0x44 && b[2] == 0x33) {
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

  Future<void> _playWebBytes(Uint8List bytes) async {
    final mime = _guessAudioMime(bytes);
    final head4 = bytes.length >= 4
        ? _headerHex(bytes, 4)
        : _headerHex(bytes, bytes.length);
    _voiceAudioLog('playBytes: len=${bytes.length} mime=$mime header4=$head4');

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
      _voiceAudioLog('blob play: start');
      await _playElementWithRetry(audio, context: 'blob');
      _voiceAudioLog('blob play: play() resolved');
    } catch (e) {
      _voiceAudioLog(
        'audio.play() failed after retry: $e — if NotAllowedError, tap mic once to unlock audio',
      );
      _logMediaError(audio, context: 'after play() catch');
      completeSafe();
      rethrow;
    }
    await done.future;
  }

  Future<void> _playNative(String url) async {
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
  }
}

class _QueueItem {
  _QueueItem.url(this.url, this.completer) : bytes = null;
  _QueueItem.bytes(this.bytes, this.completer) : url = null;

  final String? url;
  final Uint8List? bytes;
  final Completer<void> completer;
}
