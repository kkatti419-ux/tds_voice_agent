import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tds_voice_agent/service/audio_palyer_service.dart';
import '../model/voice_message.dart';
import '../service/audio_record_service.dart';
import '../service/voice_service.dart';

class VoiceViewModel extends ChangeNotifier {
  final AudioRecordService _recordService = AudioRecordService();
  final VoiceService _voiceService = VoiceService();
  final AudioPlayerService _playerService = AudioPlayerService();

  final List<VoiceMessage> messages = [];

  bool isListening = false;
  bool isAgentSpeaking = false;
  bool isProcessing = false;
  double amplitudeDb = -120;

  // Auto-send: when silence lasts for this duration, we stop recording and send.
  static const Duration _silenceDuration = Duration(seconds: 5);
  // If amplitude is above this threshold, we consider the user as speaking.
  // record() amplitude is in dBFS (typically negative numbers).
  static const double _speechThresholdDb = -35.0;

  DateTime _lastSpeechAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _hasDetectedSpeech = false;
  bool _autoSendTriggered = false;
  bool _isStopping = false;
  bool _isSending = false;
  DateTime _lastUiUpdateAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastTextUiUpdateAt = DateTime.fromMillisecondsSinceEpoch(0);

  String get statusText {
    if (isListening) return "Listening (auto-send on silence)";
    if (isProcessing) return "Agent is responding...";
    if (isAgentSpeaking) return "Agent speaking...";
    return "Tap the mic to talk";
  }

  Future<void> toggleListening() async {
    if (isListening) {
      await stopListening(manual: true);
    } else {
      await startListening();
    }
  }

  Future<void> startListening() async {
    if (isListening) return;
    if (_isSending) return;

    _autoSendTriggered = false;
    _hasDetectedSpeech = false;
    _lastSpeechAt = DateTime.now();
    amplitudeDb = -120;

    isListening = true;
    notifyListeners();

    await _recordService.startRecording(
      onAmplitude: (db) => _onAmplitude(db),
    );
  }

  void _onAmplitude(double db) {
    if (!isListening) return;

    amplitudeDb = db;

    final now = DateTime.now();
    // Avoid rebuilding UI too frequently; mic animation still looks smooth.
    if (now.difference(_lastUiUpdateAt) >= const Duration(milliseconds: 80)) {
      _lastUiUpdateAt = now;
      notifyListeners();
    }

    // Speech gate for silence detection.
    if (db >= _speechThresholdDb) {
      _hasDetectedSpeech = true;
      _lastSpeechAt = now;
      return;
    }

    if (_hasDetectedSpeech &&
        !_autoSendTriggered &&
        now.difference(_lastSpeechAt) >= _silenceDuration) {
      _autoSendTriggered = true;
      // Stop and send on silence. Microtask avoids re-entrancy issues.
      Future.microtask(() {
        stopListening(manual: false);
      });
    }
  }

  Future<void> stopListening({required bool manual}) async {
    if (!isListening) return;
    if (_isStopping) return;
    if (_isSending) return;

    _isStopping = true;

    isListening = false;
    notifyListeners();

    final path = await _recordService.stopRecording();
    _isStopping = false;

    if (path != null) {
      await sendAudio(path);
    }
  }

  Future<void> sendAudio(String path) async {
    if (_isSending) return;
    _isSending = true;
    isProcessing = true;
    isAgentSpeaking = false;
    await _playerService.stop();

    // Conversation UI: user message + agent placeholder.
    messages.add(
      VoiceMessage(text: "You (voice)", isUser: true),
    );
    messages.add(
      VoiceMessage(text: "", isUser: false),
    );
    final int agentMsgIndex = messages.length - 1;

    notifyListeners();

    Future<void>? lastAudioFuture;
    try {
      await _voiceService.sendAudioStream(
        path,
        onTextDelta: (delta) {
          messages[agentMsgIndex].text += delta;
          final now = DateTime.now();
          if (now.difference(_lastTextUiUpdateAt) >= const Duration(milliseconds: 60)) {
            _lastTextUiUpdateAt = now;
            notifyListeners();
          }
        },
        onAudioUrl: (audioUrl) {
          if (audioUrl.isEmpty) return;
          isAgentSpeaking = true;
          notifyListeners();
          lastAudioFuture = _playerService.play(audioUrl);
        },
        onDone: () {
          // We'll finalize after the sendAudioStream call returns.
        },
        onError: (error) {
          throw error;
        },
      );

      // Wait for the last played chunk so "speaking" animation stops at the right time.
      if (lastAudioFuture != null) {
        await lastAudioFuture;
      }
      isAgentSpeaking = false;
    } catch (_) {
      // Fallback to non-streaming endpoint.
      await _playerService.stop();
      Map<String, dynamic>? response;
      try {
        response = await _voiceService.sendAudio(path);
      } catch (_) {
        response = null;
      }

      final agentText = response?["text"]?.toString() ?? "(no response)";
      messages[agentMsgIndex].text = agentText;

      notifyListeners();

      final audioUrl = response?["audio_url"];
      if (audioUrl != null) {
        isAgentSpeaking = true;
        notifyListeners();
        await _playerService.play(audioUrl.toString());
      }
      isAgentSpeaking = false;
    } finally {
      isProcessing = false;
      _isSending = false;
      notifyListeners();
    }
  }
}