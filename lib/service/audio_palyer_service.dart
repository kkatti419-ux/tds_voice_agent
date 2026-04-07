import 'package:flutter_sound/flutter_sound.dart';

class AudioPlayerService {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  Future<void> play(String url) async {
    await _player.openPlayer();

    await _player.startPlayer(
      fromURI: url,
      codec: Codec.mp3,
    );
  }
}