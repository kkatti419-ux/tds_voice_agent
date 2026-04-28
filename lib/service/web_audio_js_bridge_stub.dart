import 'dart:typed_data';

/// Non-web stub so `web_audio_player_service` analyzes on VM; decode runs only on web.
Future<Object?> decodeAudioDataPromise(dynamic ctx, ByteBuffer buffer) async {
  throw UnsupportedError('WebAudio decode is web-only');
}

void setBufferSourceOnEnded(dynamic src, void Function() onDone) {}

Future<Object?> resumeAudioContextPromise(dynamic ctx) async {
  throw UnsupportedError('WebAudio is web-only');
}

dynamic createAudioContextOrNull() => null;

dynamic audioContextCreateBufferSource(dynamic audioContext) => null;

void audioBufferSourceSetBuffer(dynamic src, Object? audioBuffer) {}

void audioBufferSourceConnectToContextDestination(
  dynamic src,
  dynamic audioContext,
) {}

void audioBufferSourceSetPlaybackRate(dynamic src, double rate) {}

void audioBufferSourceStart(dynamic src, double when) {}

void audioBufferSourceStop(dynamic src, double when) {}

void audioBufferSourceDisconnect(dynamic src) {}

Future<void> playMediaElement(Object audioElement) async {}
