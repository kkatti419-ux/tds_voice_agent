import 'dart:async';
import 'dart:typed_data';

/// Non-web platforms: mic streaming is not implemented; [VoiceViewModel]
/// uses [VoiceService] instead.
class SocketManager {
  static final SocketManager _instance = SocketManager._internal();
  factory SocketManager() => _instance;

  SocketManager._internal();

  final _jsonController = StreamController<Map<String, dynamic>>.broadcast();
  final _audioController = StreamController<Uint8List>.broadcast();

  Stream<Map<String, dynamic>> get jsonStream => _jsonController.stream;
  Stream<Uint8List> get audioStream => _audioController.stream;

  void connect() {}

  void send(Map<String, dynamic> data) {}

  void sendAudio(Uint8List bytes) {}

  void interrupt() {}
}

