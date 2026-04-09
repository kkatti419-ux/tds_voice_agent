// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer' as developer;
// import 'dart:typed_data';

// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:tds_voice_agent/service/audio_palyer_service.dart';

// import '../audio/audio_web.dart';
// import '../model/voice_message.dart';
// import '../service/audio_record_service.dart';
// import '../service/voice_service.dart';
// import '../socket/socket_manager.dart';

// class VoiceViewModel extends ChangeNotifier {
//   void _vmLog(String message) {
//     if (kDebugMode) {
//       debugPrint('[VoiceVM] $message');
//       developer.log(message, name: 'VoiceVM');
//     }
//   }

//   String _previewJson(Map<String, dynamic> data) {
//     try {
//       final s = jsonEncode(data);
//       if (s.length <= 600) return s;
//       return '${s.substring(0, 600)}…(${s.length} chars)';
//     } catch (_) {
//       return data.toString();
//     }
//   }

//   final AudioRecordService _recordService = AudioRecordService();
//   final VoiceService _voiceService = VoiceService();
//   final AudioPlayerService _playerService = AudioPlayerService();
//   final AudioWeb _audioWeb = AudioWeb();

//   final SocketManager _socket = SocketManager();
//   StreamSubscription<Map<String, dynamic>>? _jsonSub;
//   StreamSubscription<Uint8List>? _audioSub;
//   Completer<void>? _webTurnCompleter;

//   int? _userMsgIndex;
//   int? _agentMsgIndex;
//   String? _serverStatus;

//   final List<VoiceMessage> messages = [];

//   bool isListening = false;
//   bool isAgentSpeaking = false;
//   bool isProcessing = false;
//   double amplitudeDb = -120;

//   static const Duration _silenceDuration = Duration(seconds: 5);
//   static const double _speechThresholdDb = -35.0;

//   DateTime _lastSpeechAt = DateTime.fromMillisecondsSinceEpoch(0);
//   bool _hasDetectedSpeech = false;
//   bool _autoSendTriggered = false;
//   bool _isStopping = false;
//   bool _isSending = false;
//   DateTime _lastUiUpdateAt = DateTime.fromMillisecondsSinceEpoch(0);
//   DateTime _lastTextUiUpdateAt = DateTime.fromMillisecondsSinceEpoch(0);

//   VoiceViewModel() {
//     if (kIsWeb) {
//       _vmLog('init: connect WebSocket + subscribe jsonStream/audioStream');
//       _socket.connect();
//       _jsonSub = _socket.jsonStream.listen(_onWebJson);
//       _audioSub = _socket.audioStream.listen(_onWebAudio);
//     }
//   }

//   @override
//   void dispose() {
//     _jsonSub?.cancel();
//     _audioSub?.cancel();
//     super.dispose();
//   }

//   String get statusText {
//     if (kIsWeb && _serverStatus != null && _serverStatus!.isNotEmpty) {
//       return _serverStatus!;
//     }
//     if (isListening) return 'Listening (auto-send on silence)';
//     if (isProcessing) return 'Agent is responding...';
//     if (isAgentSpeaking) return 'Agent speaking...';
//     return 'Tap the mic to talk';
//   }

//   Future<void> toggleListening() async {
//     if (isListening) {
//       await stopListening(manual: true);
//     } else {
//       await startListening();
//     }
//   }

//   // START LISTENING
//   Future<void> startListening() async {
//     if (isListening) return;
//     if (_isSending) return;

//     if (kIsWeb) {
//       _vmLog(
//         'startListening(web): mic + PCM stream (check SocketManager logs for → PCM)',
//       );
//       _autoSendTriggered = false;
//       _hasDetectedSpeech = false;
//       _lastSpeechAt = DateTime.now();
//       amplitudeDb = -120;

//       isListening = true;
//       notifyListeners();

//       _audioWeb.start(onLevel: _onAmplitude);
//       return;
//     }

//     _autoSendTriggered = false;
//     _hasDetectedSpeech = false;
//     _lastSpeechAt = DateTime.now();
//     amplitudeDb = -120;

//     isListening = true;
//     notifyListeners();

//     await _recordService.startRecording(onAmplitude: _onAmplitude);
//   }

//   void _onAmplitude(double db) {
//     if (!isListening) return;

//     amplitudeDb = db;

//     final now = DateTime.now();
//     if (now.difference(_lastUiUpdateAt) >= const Duration(milliseconds: 80)) {
//       _lastUiUpdateAt = now;
//       notifyListeners();
//     }

//     if (db >= _speechThresholdDb) {
//       _hasDetectedSpeech = true;
//       _lastSpeechAt = now;
//       return;
//     }

//     if (_hasDetectedSpeech &&
//         !_autoSendTriggered &&
//         now.difference(_lastSpeechAt) >= _silenceDuration) {
//       _autoSendTriggered = true;
//       Future.microtask(() {
//         stopListening(manual: false);
//       });
//     }
//   }

//   void _notifyTextDebounced() {
//     final now = DateTime.now();
//     if (now.difference(_lastTextUiUpdateAt) >=
//         const Duration(milliseconds: 60)) {
//       _lastTextUiUpdateAt = now;
//       notifyListeners();
//     }
//   }

//   void _onWebJson(Map<String, dynamic> data) {
//     final type = data['type'] as String?;
//     _vmLog('json ← type=$type ${_previewJson(data)}');

//     switch (type) {
//       case 'session_start':
//         _vmLog('session_start (session ready on server)');
//         break;
//       case 'partial':
//       case 'transcript':
//         final text = (data['text'] ?? '').toString();
//         if (_userMsgIndex != null && text.isNotEmpty) {
//           messages[_userMsgIndex!].text = text;
//           _notifyTextDebounced();
//         }
//         break;
//       case 'status':
//         _serverStatus = (data['text'] ?? '').toString();
//         notifyListeners();
//         break;
//       case 'ai_stream':
//         final delta = (data['text'] ?? '').toString();
//         if (_agentMsgIndex != null) {
//           messages[_agentMsgIndex!].text += delta;
//           _notifyTextDebounced();
//         }
//         isProcessing = true;
//         break;
//       case 'ai_done':
//         isProcessing = false;
//         _serverStatus = null;
//         _completeWebTurnIfPending();
//         notifyListeners();
//         break;
//       case 'error':
//         final msg = (data['text'] ?? data['error'] ?? 'Error').toString();
//         if (_agentMsgIndex != null) {
//           messages[_agentMsgIndex!].text = msg;
//         }
//         isProcessing = false;
//         _serverStatus = null;
//         _completeWebTurnIfPending();
//         notifyListeners();
//         break;
//       case 'interrupt':
//         _vmLog('interrupt: stop playback');
//         _playerService.stop();
//         isAgentSpeaking = false;
//         notifyListeners();
//         break;
//       default:
//         _vmLog(
//           'unhandled JSON type=$type (if this is your main payload, extend VoiceViewModel)',
//         );
//         break;
//     }
//   }

//   void _completeWebTurnIfPending() {
//     final c = _webTurnCompleter;
//     if (c != null && !c.isCompleted) {
//       c.complete();
//     }
//     _webTurnCompleter = null;
//   }

//   void _onWebAudio(Uint8List chunk) {
//     if (chunk.isEmpty) return;
//     _vmLog('audio ← TTS binary ${chunk.length}B (queued to playBytes)');
//     isAgentSpeaking = true;
//     notifyListeners();
//     _playerService.playBytes(chunk).catchError((e) {
//       _vmLog('playBytes error: $e');
//     });
//   }

//   Future<void> stopListening({required bool manual}) async {
//     if (!isListening) return;
//     if (_isStopping) return;
//     if (_isSending) return;

//     _isStopping = true;

//     isListening = false;
//     notifyListeners();

//     if (kIsWeb) {
//       _vmLog(
//         'stopListening(web): end utterance; waiting for ai_done (or error) to finish turn',
//       );
//       _audioWeb.stop();
//       _isStopping = false;

//       messages.add(VoiceMessage(text: '…', isUser: true));
//       messages.add(VoiceMessage(text: '', isUser: false));
//       _userMsgIndex = messages.length - 2;
//       _agentMsgIndex = messages.length - 1;

//       _isSending = true;
//       isProcessing = true;
//       isAgentSpeaking = false;
//       // Register completer before any await so a fast ai_done cannot be missed.
//       _webTurnCompleter = Completer<void>();

//       await _playerService.stop();

//       notifyListeners();

//       await _webTurnCompleter!.future.timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           final c = _webTurnCompleter;
//           if (c != null && !c.isCompleted) {
//             c.complete();
//           }
//           _webTurnCompleter = null;
//         },
//       );
//       await _playerService.waitUntilPlaybackIdle();

//       isAgentSpeaking = false;
//       isProcessing = false;
//       _isSending = false;
//       _userMsgIndex = null;
//       _agentMsgIndex = null;
//       notifyListeners();
//       return;
//     }

//     final path = await _recordService.stopRecording();
//     _isStopping = false;

//     if (path != null) {
//       await sendAudio(path);
//     }
//   }

//   Future<void> sendAudio(String path) async {
//     if (_isSending) return;
//     _isSending = true;
//     isProcessing = true;
//     isAgentSpeaking = false;
//     await _playerService.stop();

//     messages.add(VoiceMessage(text: 'You (voice)', isUser: true));
//     messages.add(VoiceMessage(text: '', isUser: false));
//     final int agentMsgIndex = messages.length - 1;

//     notifyListeners();

//     Future<void>? lastAudioFuture;
//     try {
//       await _voiceService.sendAudioStream(
//         path,
//         onTextDelta: (delta) {
//           messages[agentMsgIndex].text += delta;
//           final now = DateTime.now();
//           if (now.difference(_lastTextUiUpdateAt) >=
//               const Duration(milliseconds: 60)) {
//             _lastTextUiUpdateAt = now;
//             notifyListeners();
//           }
//         },
//         onAudioUrl: (audioUrl) {
//           if (audioUrl.isEmpty) return;
//           isAgentSpeaking = true;
//           notifyListeners();
//           lastAudioFuture = _playerService.play(audioUrl);
//         },
//         onDone: () {},
//         onError: (error) {
//           throw error;
//         },
//         onTtsBytes: (bytes) {
//           isAgentSpeaking = true;
//           notifyListeners();
//           unawaited(_playerService.playBytes(bytes));
//         },
//       );

//       if (lastAudioFuture != null) {
//         await lastAudioFuture;
//       }
//       await _playerService.waitUntilPlaybackIdle();
//       isAgentSpeaking = false;
//     } catch (_) {
//       await _playerService.stop();
//       messages[agentMsgIndex].text = '(stream failed)';
//       isAgentSpeaking = false;
//     } finally {
//       isProcessing = false;
//       _isSending = false;
//       notifyListeners();
//     }
//   }
// }

import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../audio/audio_web.dart';
import '../model/voice_message.dart';
import '../service/audio_palyer_service.dart';
import '../service/audio_record_service.dart';
import '../service/voice_service.dart';
import '../socket/socket_manager.dart';

class VoiceViewModel extends ChangeNotifier {
  /// ================== SERVICES ==================
  final AudioRecordService _recordService = AudioRecordService();
  final VoiceService _voiceService = VoiceService();
  final AudioPlayerService _playerService = AudioPlayerService();
  final AudioWeb _audioWeb = AudioWeb();
  final SocketManager _socket = SocketManager();

  StreamSubscription<Map<String, dynamic>>? _jsonSub;
  StreamSubscription<Uint8List>? _audioSub;

  /// ================== STATE ==================
  final List<VoiceMessage> messages = [];

  bool isListening = false;
  bool isAgentSpeaking = false;
  bool isProcessing = false;
  double amplitudeDb = -120;

  String? _serverStatus;

  int? _userMsgIndex;
  int? _agentMsgIndex;

  bool _isStopping = false;
  bool _isSending = false;
  bool _disposed = false;
  bool _sessionActive = false;
  bool get isSessionActive => _sessionActive;

  bool _hasDetectedSpeech = false;
  bool _autoSendTriggered = false;

  DateTime _lastSpeechAt = DateTime.now();
  DateTime _lastUiUpdateAt = DateTime.now();
  DateTime _lastTextUiUpdateAt = DateTime.now();

  static const Duration _silenceDuration = Duration(seconds: 5);
  static const double _speechThresholdDb = -35.0;

  /// ================== AUDIO QUEUE ==================
  final Queue<Uint8List> _audioQueue = Queue();
  bool _isPlayingAudio = false;

  /// ================== INIT ==================
  VoiceViewModel() {
    if (kIsWeb) {
      _socket.connect();
      _jsonSub = _socket.jsonStream.listen(_onWebJson);
      _audioSub = _socket.audioStream.listen(_onWebAudio);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _jsonSub?.cancel();
    _audioSub?.cancel();
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// ================== STATUS ==================
  String get statusText {
    if (_sessionActive && isListening) {
      return 'Listening... (tap mic to stop)';
    }
    if (_sessionActive && (isProcessing || isAgentSpeaking)) {
      return 'Assistant active... speak to interrupt or tap mic to stop';
    }
    if (_serverStatus?.isNotEmpty == true) return _serverStatus!;

    if (isListening && !_hasDetectedSpeech) return 'Listening... Speak now';
    if (isListening) return 'Listening...';

    if (isProcessing) return 'Thinking...';
    if (isAgentSpeaking) return 'Speaking...';

    return 'Tap to speak';
  }

  /// ================== MESSAGE HELPERS ==================
  void _addUserMessage(String text) {
    messages.add(VoiceMessage(text: text, isUser: true));
    _userMsgIndex = messages.length - 1;
  }

  void _addAgentMessage() {
    messages.add(VoiceMessage(text: '', isUser: false));
    _agentMsgIndex = messages.length - 1;
  }

  void _updateUserText(String text) {
    if (_userMsgIndex != null) {
      messages[_userMsgIndex!].text = text;
      _debounceTextNotify();
    }
  }

  void _appendAgentText(String delta) {
    if (_agentMsgIndex != null) {
      messages[_agentMsgIndex!].text += delta;
      _debounceTextNotify();
    }
  }

  Future<void> _playAgentAudioUrl(String url) async {
    if (url.isEmpty) return;
    isAgentSpeaking = true;
    _notify();
    try {
      await _playerService.play(url);
    } catch (_) {
      // Keep conversation alive even if one audio segment fails.
    } finally {
      isAgentSpeaking = false;
      _notify();
    }
  }

  void _debounceTextNotify() {
    final now = DateTime.now();
    if (now.difference(_lastTextUiUpdateAt) >
        const Duration(milliseconds: 60)) {
      _lastTextUiUpdateAt = now;
      _notify();
    }
  }

  /// ================== LISTENING ==================
  Future<void> toggleListening() async {
    if (_sessionActive) {
      await stopSession();
    } else {
      await startSession();
    }
  }

  Future<void> startSession() async {
    if (_sessionActive) return;
    _sessionActive = true;
    await startListening();
  }

  Future<void> stopSession() async {
    _sessionActive = false;
    _hasDetectedSpeech = false;
    _autoSendTriggered = false;
    _serverStatus = null;

    if (isListening) {
      _audioWeb.stop();
      try {
        await _recordService.stopRecording();
      } catch (_) {}
      isListening = false;
    }

    _audioQueue.clear();
    await _playerService.stop();
    _socket.interrupt();
    isAgentSpeaking = false;
    isProcessing = false;
    _isSending = false;
    _isStopping = false;
    _notify();
  }

  Future<void> startListening() async {
    if (isListening || !_sessionActive) return;

    _autoSendTriggered = false;
    _hasDetectedSpeech = false;
    _lastSpeechAt = DateTime.now();
    amplitudeDb = -120;

    isListening = true;
    _notify();

    if (kIsWeb) {
      _audioWeb.start(onLevel: _onAmplitude);
    } else {
      await _recordService.startRecording(onAmplitude: _onAmplitude);
    }
  }

  Future<void> stopListening({required bool manual}) async {
    if (!isListening || _isStopping) return;

    _isStopping = true;
    isListening = false;
    _notify();

    if (kIsWeb) {
      _audioWeb.stop();

      if (_isSending) {
        await interrupt();
      }

      _addUserMessage('…');
      _addAgentMessage();

      isProcessing = true;
      _isSending = true;
      _notify();

      await _playerService.stop();

      _isStopping = false;
      return;
    }

    final path = await _recordService.stopRecording();
    _isStopping = false;

    if (path != null) {
      await sendAudio(path);
    }
  }

  /// ================== AMPLITUDE ==================
  void _onAmplitude(double db) {
    if (!isListening) return;

    amplitudeDb = db;

    final now = DateTime.now();

    if (now.difference(_lastUiUpdateAt) > const Duration(milliseconds: 80)) {
      _lastUiUpdateAt = now;
      _notify();
    }

    if (db >= _speechThresholdDb) {
      if (isAgentSpeaking || isProcessing) {
        interrupt();
      }
      _hasDetectedSpeech = true;
      _lastSpeechAt = now;
      return;
    }

    if (_hasDetectedSpeech &&
        !_autoSendTriggered &&
        now.difference(_lastSpeechAt) > _silenceDuration) {
      _autoSendTriggered = true;
      stopListening(manual: false);
    }
  }

  /// ================== SOCKET JSON ==================
  void _onWebJson(Map<String, dynamic> data) {
    final type = data['type'];

    switch (type) {
      case 'partial':
      case 'transcript':
        _updateUserText(data['text'] ?? '');
        break;

      case 'ai_stream':
        _appendAgentText(data['text'] ?? '');
        isProcessing = true;
        break;

      case 'ai_done':
        isProcessing = false;
        _serverStatus = null;
        _isSending = false;
        _notify();
        if (_sessionActive && !isListening) {
          unawaited(startListening());
        }
        break;

      case 'status':
        _serverStatus = data['text'];
        _notify();
        break;

      case 'audio_url':
        final url = (data['audio_url'] ?? data['url'] ?? '').toString();
        if (url.isNotEmpty) {
          unawaited(_playAgentAudioUrl(url));
        }
        break;

      case 'error':
        _appendAgentText(data['text'] ?? 'Error');
        isProcessing = false;
        _isSending = false;
        _notify();
        if (_sessionActive && !isListening) {
          unawaited(startListening());
        }
        break;

      case 'interrupt':
        interrupt();
        break;
    }
  }

  /// ================== AUDIO STREAM ==================
  void _onWebAudio(Uint8List chunk) {
    if (chunk.isEmpty) return;

    if (_sessionActive && !isListening) {
      unawaited(startListening());
    }

    _audioQueue.add(chunk);
    _processAudioQueue();
  }

  Future<void> _processAudioQueue() async {
    if (_isPlayingAudio) return;

    _isPlayingAudio = true;
    try {
      while (_audioQueue.isNotEmpty) {
        final chunk = _audioQueue.removeFirst();

        isAgentSpeaking = true;
        _notify();

        try {
          await _playerService.playBytes(chunk);
        } catch (_) {
          // Ignore malformed/unsupported chunk and continue queue playback.
        }
      }
    } finally {
      isAgentSpeaking = false;
      _isPlayingAudio = false;
      _notify();
    }

    if (_sessionActive && !isListening && !_isSending) {
      unawaited(startListening());
    }
  }

  /// ================== MOBILE AUDIO ==================
  Future<void> sendAudio(String path) async {
    if (_isSending) return;

    _isSending = true;
    isProcessing = true;
    isAgentSpeaking = false;

    await _playerService.stop();

    _addUserMessage('You (voice)');
    _addAgentMessage();

    _notify();

    try {
      await _voiceService.sendAudioStream(
        path,
        onTextDelta: _appendAgentText,
        onAudioUrl: (url) async {
          if (url.isEmpty) return;

          isAgentSpeaking = true;
          _notify();

          await _playerService.play(url);
        },
        onTtsBytes: (bytes) {
          _audioQueue.add(bytes);
          _processAudioQueue();
        },
        onDone: () {},
        onError: (e) => throw e,
      );

      await _playerService.waitUntilPlaybackIdle();
    } catch (_) {
      _appendAgentText('(failed)');
    } finally {
      isProcessing = false;
      isAgentSpeaking = false;
      _isSending = false;
      _notify();
    }
  }

  /// ================== INTERRUPT ==================
  Future<void> interrupt() async {
    _socket.interrupt();
    _audioQueue.clear();
    await _playerService.stop();
    isAgentSpeaking = false;
    isProcessing = false;
    _isSending = false;
    _notify();
  }
}
