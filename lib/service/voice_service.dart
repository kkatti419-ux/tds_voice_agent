import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:universal_html/html.dart' as html;

class VoiceService {
  final Dio _dio = Dio();

  static const String _httpBaseUrl = String.fromEnvironment(
    "VOICE_HTTP_URL",
    defaultValue: "http://localhost:8000/voice",
  );
  static const String _wsUrl = String.fromEnvironment(
    "VOICE_WS_URL",
    defaultValue: "wss://demo.nitya.ai/new/ws",
  );

  Future<Map<String, dynamic>> sendAudio(String path) async {
    final bytes = await _readAudioBytes(path);
    FormData data = FormData.fromMap({
      "file": MultipartFile.fromBytes(
        bytes,
        filename: "voice.wav",
        contentType: DioMediaType.parse("audio/wav"),
      ),
    });

    final response = await _dio.post(
      _httpBaseUrl,
      data: data,
    );

    return response.data;
  }

  /// Streaming mode (ChatGPT-like):
  /// - server sends `text_delta` and chunked `audio_url`
  Future<void> sendAudioStream(
    String path, {
    required void Function(String delta) onTextDelta,
    required void Function(String audioUrl) onAudioUrl,
    required void Function() onDone,
    void Function(Object error)? onError,
  }) async {
    final channel = WebSocketChannel.connect(Uri.parse(_wsUrl));

    try {
      final bytes = await _readAudioBytes(path);
      final audioBase64 = base64Encode(bytes);

      channel.sink.add(
        jsonEncode({
          "type": "audio",
          "audio_base64": audioBase64,
          "mime": "audio/wav",
        }),
      );

      final done = Completer<void>();

      late final StreamSubscription sub;
      sub = channel.stream.listen(
        (message) async {
          final raw = message.toString();
          final data = jsonDecode(raw) as Map<String, dynamic>;
          final type = data["type"];

          if (type == "text_delta") {
            onTextDelta((data["delta"] ?? "").toString());
          } else if (type == "audio_url") {
            final url = (data["audio_url"] ?? "").toString();
            if (url.isNotEmpty) onAudioUrl(url);
          } else if (type == "done") {
            if (!done.isCompleted) done.complete();
          } else if (type == "error") {
            if (!done.isCompleted) done.completeError(data["error"]);
          }
        },
        onError: (e) {
          if (!done.isCompleted) done.completeError(e);
          onError?.call(e);
        },
        onDone: () {
          if (!done.isCompleted) done.complete();
        },
        cancelOnError: true,
      );

      await done.future;
      await sub.cancel();
    } finally {
      await channel.sink.close();
    }

    onDone();
  }

  Future<Uint8List> _readAudioBytes(String path) async {
    if (kIsWeb) {
      final response = await html.HttpRequest.request(
        path,
        method: "GET",
        responseType: "arraybuffer",
      );
      final buffer = response.response;
      if (buffer is ByteBuffer) {
        return Uint8List.view(buffer);
      }
      if (buffer is Uint8List) {
        return buffer;
      }
      throw Exception("Could not read web audio bytes from path: $path");
    }

    final file = File(path);
    return file.readAsBytes();
  }
}