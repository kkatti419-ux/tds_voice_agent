import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:js/js.dart';
import 'package:tds_voice_agent/socket/socket_manager.dart';

@JS('startAudioCapture')
external void _startAudioCapture(
  JSExportedDartFunction onPcm,
  JSExportedDartFunction? onLevel,
);

@JS('stopAudioCapture')
external void _stopAudioCapture();

class AudioWeb {
  int _chunkIndex = 0;
  int _totalPcmBytes = 0;
  int _decodeErrors = 0;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[AudioWeb] $message');
      developer.log(message, name: 'AudioWeb');
    }
  }

  void start({void Function(double levelDb)? onLevel}) {
    _chunkIndex = 0;
    _totalPcmBytes = 0;
    _decodeErrors = 0;
    _log('start() — JS capture will call SocketManager.sendAudio with int16 PCM chunks');

    final onPcmJs = ((String dataJson) {
      if (dataJson.isEmpty) return;
      try {
        final decoded = jsonDecode(dataJson);
        if (decoded is! List) {
          _decodeErrors++;
          _log('decode: expected JSON array, got ${decoded.runtimeType}');
          return;
        }
        final bytes = Uint8List.fromList(
          decoded.map((e) => (e as num).toInt()).toList(),
        );
        if (bytes.isEmpty) return;
        _chunkIndex++;
        _totalPcmBytes += bytes.length;
        if (_chunkIndex <= 3 || _chunkIndex % 50 == 0) {
          _log(
            'PCM chunk #$_chunkIndex: ${bytes.length}B (cumulative $_totalPcmBytes B) → sendAudio',
          );
        }
        SocketManager().sendAudio(bytes);
      } catch (e, st) {
        _decodeErrors++;
        _log('PCM JSON decode error: $e $st');
      }
    }).toJS;

    final onLevelJs = onLevel == null
        ? null
        : ((num level) {
            onLevel(level.toDouble());
          }).toJS;

    _startAudioCapture(onPcmJs, onLevelJs);
  }

  void stop() {
    _log(
      'stop() — chunks=$_chunkIndex totalBytes=$_totalPcmBytes decodeErrors=$_decodeErrors',
    );
    _stopAudioCapture();
  }
}
