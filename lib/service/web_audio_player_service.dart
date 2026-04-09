import 'dart:collection';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:universal_html/html.dart' as html;

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
      completeSafe();
    });

    try {
      await audio.play();
    } catch (e) {
      rethrow;
    }
    await done.future;
  }

  String _guessAudioMime(Uint8List b) {
    if (b.length >= 4 &&
        b[0] == 0x52 &&
        b[1] == 0x49 &&
        b[2] == 0x46 &&
        b[3] == 0x46) {
      return 'audio/wav';
    }
    return 'audio/mpeg';
  }

  Future<void> _playWebBytes(Uint8List bytes) async {
    _webAudio?.pause();
    final blob = html.Blob([bytes], _guessAudioMime(bytes));
    final url = html.Url.createObjectUrlFromBlob(blob);
    final audio = html.AudioElement(url);
    _webAudio = audio;
    audio.loop = false;
    final done = Completer<void>();

    void completeSafe() {
      if (!done.isCompleted) done.complete();
      html.Url.revokeObjectUrl(url);
    }

    audio.onEnded.first.then((_) {
      completeSafe();
    });
    audio.onError.first.then((_) {
      completeSafe();
    });

    try {
      await audio.play();
    } catch (e) {
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