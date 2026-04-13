import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:universal_html/html.dart' as html;

/// Console / DevTools filter: `VoiceAudio`
const String _kLogName = 'VoiceAudio';

void _voiceAudioLog(String message) {
  debugPrint('[$_kLogName] $message');
  developer.log(message, name: _kLogName);
}

class AudioPlayerService {
  FlutterSoundPlayer? _player;
  html.AudioElement? _webAudio;
  final Queue<_QueueItem> _queue = Queue<_QueueItem>();
  bool _isPlaying = false;

  /// Stops current playback and clears any pending audio chunks.
  Future<void> stop() async {
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
    } catch (_) {
      // Ignore if the player isn't in a state to stop.
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
    while (_queue.isNotEmpty || _isPlaying) {
      await Future<void>.delayed(const Duration(milliseconds: 24));
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
          if (!next.completer.isCompleted) {
            next.completer.completeError(e);
          }
        }
      }
    } finally {
      _isPlaying = false;
    }
  }

  Future<void> _playWeb(String url) async {
    _webAudio?.pause();
    final audio = html.AudioElement(url);
    _webAudio = audio;
    final done = Completer<void>();

    void completeSafe() {
      if (!done.isCompleted) done.complete();
    }

    audio.loop = false;

    audio.onEnded.first.then((_) {
      completeSafe();
    });
    audio.onError.first.then((_) {
      _logMediaError(audio, context: 'play url');
      completeSafe();
    });

    try {
      await audio.play();
    } catch (e) {
      _voiceAudioLog('play(url) threw: $e');
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
    // WAV: RIFF....WAVE
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
    // FLAC
    if (b.length >= 4 &&
        b[0] == 0x66 &&
        b[1] == 0x4c &&
        b[2] == 0x61 &&
        b[3] == 0x43) {
      return 'audio/flac';
    }
    // Ogg
    if (b.length >= 4 &&
        b[0] == 0x4f &&
        b[1] == 0x67 &&
        b[2] == 0x67 &&
        b[3] == 0x53) {
      return 'audio/ogg';
    }
    // WebM / Matroska EBML
    if (b.length >= 4 &&
        b[0] == 0x1a &&
        b[1] == 0x45 &&
        b[2] == 0xdf &&
        b[3] == 0xa3) {
      return 'audio/webm';
    }
    // ID3 tag or MPEG frame sync (MP3)
    if (b.length >= 3 &&
        b[0] == 0x49 &&
        b[1] == 0x44 &&
        b[2] == 0x33) {
      return 'audio/mpeg';
    }
    if (b.length >= 2 && b[0] == 0xff && (b[1] & 0xe0) == 0xe0) {
      return 'audio/mpeg';
    }
    // AAC ADTS
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
    final head4 = bytes.length >= 4 ? _headerHex(bytes, 4) : _headerHex(bytes, bytes.length);
    _voiceAudioLog(
      'playBytes: len=${bytes.length} mime=$mime header4=$head4',
    );

    _webAudio?.pause();
    final blob = html.Blob([bytes], mime);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final audio = html.AudioElement(url);
    _webAudio = audio;
    audio.loop = false;
    final done = Completer<void>();

    void completeSafe() {
      if (!done.isCompleted) done.complete();
      html.Url.revokeObjectUrl(url);
    }

    final canPlay = audio.canPlayType(mime);
    _voiceAudioLog('canPlayType("$mime") => "$canPlay"');

    audio.onEnded.first.then((_) {
      _voiceAudioLog('onEnded: playback finished (len=${bytes.length})');
      completeSafe();
    });
    audio.onError.first.then((_) {
      _logMediaError(audio, context: 'blob playBytes');
      completeSafe();
    });

    try {
      await audio.play();
    } catch (e) {
      _voiceAudioLog('audio.play() threw: $e');
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
