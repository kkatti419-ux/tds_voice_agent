import 'dart:collection';
import 'dart:async';
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
    _queue.add(_QueueItem(url, completer));
    if (_isPlaying) return completer.future;

    _isPlaying = true;
    _playLoop();
    return completer.future;
  }

  Future<void> _playLoop() async {
    try {
      while (_queue.isNotEmpty) {
        final next = _queue.removeFirst();

        try {
          if (kIsWeb) {
            await _playWeb(next.url);
          } else {
            await _playNative(next.url);
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
  _QueueItem(this.url, this.completer);
  final String url;
  final Completer<void> completer;
}