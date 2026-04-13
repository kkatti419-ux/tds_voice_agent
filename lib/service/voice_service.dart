// import 'dart:io';
// import 'dart:convert';
// import 'dart:async';
// import 'dart:typed_data';
// import 'package:flutter/foundation.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:universal_html/html.dart' as html;

// class VoiceService {
//   static const String _wsUrl = String.fromEnvironment(
//     "VOICE_WS_URL",
//     defaultValue: "ws://axy41ylzzdg4uh-9001.proxy.runpod.net/new/ws",
//   );

//   void _log(String message) {
//     debugPrint('[VoiceService] $message');
//   }

//   /// Streaming mode (ChatGPT-like):
//   /// - server sends `text_delta` and chunked `audio_url`
//   Future<void> sendAudioStream(
//     String path, {
//     required void Function(String delta) onTextDelta,
//     required void Function(String audioUrl) onAudioUrl,
//     required void Function() onDone,
//     void Function(Object error)? onError,
//   }) async {
//     _log('sendAudioStream started: ws=$_wsUrl, path=$path');
//     final channel = WebSocketChannel.connect(Uri.parse(_wsUrl));

//     try {
//       final bytes = await _readAudioBytes(path);
//       _log('sendAudioStream bytes read: ${bytes.length}');
//       final audioBase64 = base64Encode(bytes);
//       _log('sendAudioStream payload base64 length: ${audioBase64.length}');

//       channel.sink.add(
//         jsonEncode({
//           "type": "audio",
//           "audio_base64": audioBase64,
//           "mime": "audio/wav",
//         }),
//       );
//       _log('sendAudioStream initial payload sent');

//       final done = Completer<void>();

//       late final StreamSubscription sub;
//       sub = channel.stream.listen(
//         (message) async {
//           final raw = message.toString();
//           _log('sendAudioStream raw message: $raw');
//           final data = jsonDecode(raw) as Map<String, dynamic>;
//           final type = data["type"];
//           _log('sendAudioStream message type: $type');

//           if (type == "text_delta") {
//             _log('sendAudioStream text_delta: ${data["delta"]}');
//             onTextDelta((data["delta"] ?? "").toString());
//           } else if (type == "audio_url") {
//             final url = (data["audio_url"] ?? "").toString();
//             _log('sendAudioStream audio_url: $url');
//             if (url.isNotEmpty) onAudioUrl(url);
//           } else if (type == "done") {
//             _log('sendAudioStream done received');
//             if (!done.isCompleted) done.complete();
//           } else if (type == "error") {
//             _log('sendAudioStream error message from server: ${data["error"]}');
//             if (!done.isCompleted) done.completeError(data["error"]);
//           }
//         },
//         onError: (e) {
//           _log('sendAudioStream channel error: $e');
//           if (!done.isCompleted) done.completeError(e);
//           onError?.call(e);
//         },
//         onDone: () {
//           _log('sendAudioStream channel closed by server');
//           if (!done.isCompleted) done.complete();
//         },
//         cancelOnError: true,
//       );

//       await done.future;
//       _log('sendAudioStream done future completed');
//       await sub.cancel();
//       _log('sendAudioStream subscription cancelled');
//     } catch (e, st) {
//       _log('sendAudioStream exception: $e');
//       _log('sendAudioStream stack: $st');
//       rethrow;
//     } finally {
//       await channel.sink.close();
//       _log('sendAudioStream sink closed');
//     }

//     _log('sendAudioStream onDone callback');
//     onDone();
//   }

//   Future<Uint8List> _readAudioBytes(String path) async {
//     _log('_readAudioBytes called. kIsWeb=$kIsWeb, path=$path');
//     if (kIsWeb) {
//       final response = await html.HttpRequest.request(
//         path,
//         method: "GET",
//         responseType: "arraybuffer",
//       );
//       _log('_readAudioBytes web request status: ${response.status}');
//       final buffer = response.response;
//       if (buffer is ByteBuffer) {
//         _log('_readAudioBytes ByteBuffer length: ${buffer.lengthInBytes}');
//         return Uint8List.view(buffer);
//       }
//       if (buffer is Uint8List) {
//         _log('_readAudioBytes Uint8List length: ${buffer.length}');
//         return buffer;
//       }
//       _log('_readAudioBytes unsupported web buffer type: ${buffer.runtimeType}');
//       throw Exception("Could not read web audio bytes from path: $path");
//     }

//     final file = File(path);
//     final bytes = await file.readAsBytes();
//     _log('_readAudioBytes native bytes length: ${bytes.length}');
//     return bytes;
//   }
// }

import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:universal_html/html.dart' as html;

class VoiceService {
  static const String _wsUrl = String.fromEnvironment(
    'VOICE_WS_URL',
    defaultValue: 'ws://004vrvubdcz0ge-9002.proxy.runpod.net/new/ws',
  );

  void _log(String message) {
    final now = DateTime.now().toIso8601String();
    debugPrint('[VoiceService][$now] $message');
  }

  /// Streaming mode
  Future<void> sendAudioStream(
    String path, {
    required void Function(String delta) onTextDelta,
    required void Function(String audioUrl) onAudioUrl,
    required void Function() onDone,
    void Function(Object error)? onError,
    void Function(Uint8List bytes)? onTtsBytes,
  }) async {
    _log('========== sendAudioStream START ==========');
    _log('WebSocket URL: $_wsUrl');
    _log('Audio path received: $path');

    final channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
    _log('WebSocket connection initialized');

    try {
      /// STEP 1 — READ AUDIO
      _log('Reading audio bytes...');
      final bytes = await _readAudioBytes(path);
      _log('Audio bytes read successfully');
      _log('Audio byte length: ${bytes.length}');

      /// STEP 2 — CONVERT BASE64
      _log('Encoding audio to base64...');
      final audioBase64 = base64Encode(bytes);
      _log('Base64 encoding completed');
      _log('Base64 size: ${audioBase64.length}');

      /// STEP 3 — SEND PAYLOAD
      final payload = {
        "type": "audio",
        "audio_base64": audioBase64,
        "mime": "audio/wav",
      };

      _log('Sending payload to server...');
      _log('Payload keys: ${payload.keys.toList()}');

      channel.sink.add(jsonEncode(payload));
      _log('Payload sent successfully');

      final done = Completer<void>();

      late final StreamSubscription sub;

      /// STEP 4 — LISTEN SERVER STREAM
      _log('Listening to server stream...');

      sub = channel.stream.listen(
        (dynamic message) async {
          _log('Message received from server');
          _log('Raw message: $message');

          if (message is Uint8List) {
            _log('Binary TTS chunk: ${message.length} bytes');
            onTtsBytes?.call(message);
            return;
          }
          if (message is ByteBuffer) {
            onTtsBytes?.call(Uint8List.view(message));
            return;
          }
          if (message is List<int>) {
            onTtsBytes?.call(Uint8List.fromList(message));
            return;
          }

          try {
            final raw = message is String ? message : message.toString();
            final data = jsonDecode(raw);
            _log('JSON parsed successfully');

            if (data is! Map<String, dynamic>) {
              _log('Message JSON is not Map, treating as text chunk');
              onTextDelta(raw);
              return;
            }

            final type = data["type"];
            _log('Message type detected: $type');

            if (type == "server_ping") {
              channel.sink.add(jsonEncode({"type": "pong"}));
              _log('Replied with pong');
              return;
            }
            if (type == "session_start") {
              _log('Session started');
              return;
            }
            if (type == "ai_stream") {
              final delta = (data["text"] ?? "").toString();
              if (delta.isNotEmpty) onTextDelta(delta);
              return;
            }
            if (type == "ai_done") {
              if (!done.isCompleted) {
                done.complete();
                _log('ai_done: completer completed');
              }
              return;
            }

            /// TEXT STREAM
            if (type == "text_delta") {
              final delta = (data["delta"] ?? "").toString();
              _log('Text delta received: $delta');

              _log('Calling onTextDelta callback...');
              onTextDelta(delta);
              _log('onTextDelta callback executed');
            }

            /// AUDIO STREAM
            else if (type == "audio_url") {
              final url = (data["audio_url"] ?? "").toString();
              _log('Audio URL received: $url');

              if (url.isNotEmpty) {
                _log('Calling onAudioUrl callback...');
                onAudioUrl(url);
                _log('onAudioUrl callback executed');
              }
            }

            /// DONE SIGNAL
            else if (type == "done") {
              _log('Server sent DONE signal');

              if (!done.isCompleted) {
                done.complete();
                _log('Done completer completed');
              }
            }

            /// ERROR SIGNAL
            else if (type == "error") {
              final err = data["error"];
              _log('Server error received: $err');

              if (!done.isCompleted) {
                done.completeError(err);
              }
            }

            else {
              _log('Unknown message type received, trying generic parser');

              // Generic text fields used by many websocket APIs.
              final textCandidates = <Object?>[
                data["text"],
                data["message"],
                data["content"],
                data["delta"],
                data["response"],
                data["transcript"],
              ];
              String? extractedText;
              for (final candidate in textCandidates) {
                final v = candidate?.toString().trim();
                if (v != null && v.isNotEmpty) {
                  extractedText = v;
                  break;
                }
              }

              if (extractedText != null) {
                _log('Generic text extracted: $extractedText');
                onTextDelta(extractedText);
              }

              // Generic audio URL fields.
              final audioCandidates = <Object?>[
                data["audio_url"],
                data["audioUrl"],
                data["audio"],
                data["url"],
              ];
              String? extractedAudioUrl;
              for (final candidate in audioCandidates) {
                final v = candidate?.toString().trim();
                if (v != null && v.startsWith("http")) {
                  extractedAudioUrl = v;
                  break;
                }
              }
              if (extractedAudioUrl != null) {
                _log('Generic audio URL extracted: $extractedAudioUrl');
                onAudioUrl(extractedAudioUrl);
              }

              // Generic done flags.
              final doneFlag = data["done"] == true ||
                  data["is_final"] == true ||
                  data["final"] == true ||
                  data["event"] == "done";
              if (doneFlag && !done.isCompleted) {
                _log('Generic done flag detected');
                done.complete();
              }
            }
          } catch (e) {
            final raw = message.toString();
            _log('JSON parsing error: $e');
            // If server sends plain text frames, still show them.
            if (raw.trim().isNotEmpty) {
              _log('Treating non-JSON message as text chunk');
              onTextDelta(raw);
            }
          }
        },

        /// SOCKET ERROR
        onError: (e) {
          _log('WebSocket stream ERROR: $e');

          if (!done.isCompleted) {
            done.completeError(e);
          }

          if (onError != null) {
            _log('Calling onError callback...');
            onError(e);
            _log('onError callback executed');
          }
        },

        /// SOCKET CLOSED
        onDone: () {
          _log('WebSocket stream CLOSED by server');

          if (!done.isCompleted) {
            done.complete();
          }
        },

        cancelOnError: true,
      );

      /// WAIT COMPLETION
      _log('Waiting for stream completion...');
      await done.future;
      _log('Stream completion received');

      /// CANCEL SUBSCRIPTION
      _log('Cancelling stream subscription...');
      await sub.cancel();
      _log('Subscription cancelled successfully');
    } catch (e, st) {
      _log('Exception occurred inside sendAudioStream');
      _log('Error: $e');
      _log('StackTrace: $st');

      rethrow;
    } finally {
      _log('Closing WebSocket sink...');
      await channel.sink.close();
      _log('WebSocket sink closed');
    }

    _log('Calling onDone callback...');
    onDone();

    _log('========== sendAudioStream END ==========');
  }

  Future<Uint8List> _readAudioBytes(String path) async {
    _log('Entering _readAudioBytes()');
    _log('Platform detected: ${kIsWeb ? "WEB" : "NATIVE"}');

    if (kIsWeb) {
      _log('Fetching audio via HTTP request...');

      final response = await html.HttpRequest.request(
        path,
        method: "GET",
        responseType: "arraybuffer",
      );

      _log('HTTP status: ${response.status}');

      final buffer = response.response;

      if (buffer is ByteBuffer) {
        _log('Received ByteBuffer');
        _log('Buffer size: ${buffer.lengthInBytes}');
        return Uint8List.view(buffer);
      }

      if (buffer is Uint8List) {
        _log('Received Uint8List');
        _log('Buffer size: ${buffer.length}');
        return buffer;
      }

      _log('Unsupported buffer type: ${buffer.runtimeType}');
      throw Exception("Could not read web audio bytes");
    }

    _log('Reading local file from native path...');
    final file = File(path);

    if (!await file.exists()) {
      _log('File does NOT exist at path: $path');
      throw Exception("Audio file not found");
    }

    final bytes = await file.readAsBytes();

    _log('File read successfully');
    _log('File byte size: ${bytes.length}');

    return bytes;
  }
}