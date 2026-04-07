import 'package:flutter/material.dart';
import 'package:tds_voice_agent/service/audio_palyer_service.dart';
import '../model/voice_message.dart';
import '../service/audio_record_service.dart';
import '../service/voice_service.dart';

class VoiceViewModel extends ChangeNotifier {
  final AudioRecordService _recordService = AudioRecordService();
  final VoiceService _voiceService = VoiceService();
  final AudioPlayerService _playerService = AudioPlayerService();

  List<VoiceMessage> messages = [];

  bool isListening = false;

  Future<void> startListening() async {
    isListening = true;
    notifyListeners();

    await _recordService.startRecording();
  }

  Future<void> stopListening() async {
    isListening = false;
    notifyListeners();

    final path = await _recordService.stopRecording();

    if (path != null) {
      await sendAudio(path);
    }
  }

  Future<void> sendAudio(String path) async {
    messages.add(
      VoiceMessage(text: "Listening...", isUser: true),
    );

    notifyListeners();

    final response = await _voiceService.sendAudio(path);

    final text = response["text"];
    final audioUrl = response["audio_url"];

    messages.add(
      VoiceMessage(text: text, isUser: false),
    );

    notifyListeners();

    await _playerService.play(audioUrl);
  }
}