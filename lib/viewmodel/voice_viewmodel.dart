import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tds_voice_agent/service/audio_palyer_service.dart'
    show AudioPlayerService;

import '../audio/audio_web.dart';
import '../model/voice_message.dart';
import '../service/audio_record_service.dart';
import '../service/voice_service.dart';
import '../core/wire_logs.dart';
import '../socket/socket_manager.dart';
import '../voice/listening_idle_policy.dart';
import '../voice/voice_session_protocol.dart';

class VoiceViewModel extends ChangeNotifier {
  void _vmLog(String message, {bool verbose = false}) {
    if (!kDebugMode) return;
    if (verbose && !_verboseLogs) return;
    debugPrint('[VoiceVM] $message');
    developer.log(message, name: 'VoiceVM');
  }

  void _wireLog(String message) {
    if (!agniWireLogsEnabled) return;
    debugPrint(message);
    developer.log(message, name: 'VoiceVM');
    print(message);
  }

  /// When false, only important logs (barge-in, mute, errors, session).
  static const bool _verboseLogs = false;

  final AudioRecordService _recordService = AudioRecordService();
  final VoiceService _voiceService = VoiceService();
  final AudioPlayerService _playerService = AudioPlayerService();
  final AudioWeb _audioWeb = AudioWeb();

  final SocketManager _socket = SocketManager();
  StreamSubscription<Map<String, dynamic>>? _jsonSub;
  StreamSubscription<Uint8List>? _audioSub;
  Completer<void>? _webTurnCompleter;

  int? _userMsgIndex;
  int? _agentMsgIndex;
  String? _serverStatus;

  final List<VoiceMessage> messages = [];

  bool isListening = false;
  bool isAgentSpeaking = false;
  bool isProcessing = false;
  double amplitudeDb = -120;

  /// User tapped mic off — do not auto-start until they unmute.
  bool _userMutedMic = false;

  /// When true, binary TTS from the socket is not played (chat text still updates).
  bool agentTtsMuted = false;

  /// Web: waiting for `ai_done` + playback for the current utterance turn.
  bool _awaitingWebTurn = false;

  /// Legacy fallback: accept binary before [_awaitingWebTurn] is set (same microtask as first JSON).
  bool _expectingAssistantBinary = false;

  /// After [ai_done], accept trailing binary frames for a short window (ordering race with server).
  DateTime? _ttsGraceUntil;
  static const Duration _ttsGraceAfterDone = Duration(milliseconds: 600);

  VoiceSessionPhase _sessionPhase = VoiceSessionPhase.listening;
  Timer? _idleNoSpeechTimer;
  Timer? _continuePromptTimer;
  Timer? _presencePromptTimer;

  /// After sending [VoiceSessionProtocol.clientPresenceCheck]; cleared when user speaks or assistant streams.
  bool _presenceCheckSent = false;

  bool _isOffline = false;
  String? _micBlockedMessage;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  /// Brief wait after [ai_done] so late binary chunks arrive before [waitUntilPlaybackIdle].
  static const Duration _ttsPostDoneDrain = Duration(milliseconds: 220);
  static const double _speechThresholdDb = -35.0;
  static const Duration _bargeInHold = Duration(milliseconds: 280);

  bool _isStopping = false;
  bool _isSending = false;
  DateTime? _bargeInSpeechStart;
  DateTime _lastUiUpdateAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastTextUiUpdateAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Throttle logs when binary TTS arrives outside an active turn.
  DateTime? _lastVoiceAudioDropLogAt;

  /// AgniApp-style wire diagnostics (debug only).
  int _rxMsgCount = 0;
  int _rxChunkCount = 0;
  int _rxChunkBytes = 0;

  VoiceViewModel() {
    _initConnectivity();
    if (kIsWeb) {
      _vmLog('init: WebSocket + streams (listen before connect)');
      _jsonSub = _socket.jsonStream.listen(_onWebJson);
      _audioSub = _socket.audioStream.listen(_onWebAudio);
      unawaited(
        _socket.connectAsync().then((_) {
          if (agniWireLogsEnabled) {
            _wireLog(
              '[VoiceVM] connect() resolved — url=${SocketManager.currentWsUrl} '
              'isConnected=${_socket.isConnected} '
              'isConnecting=${_socket.isConnecting}',
            );
          }
          unawaited(AudioPlayerService.ensurePlaybackAudioContext());
          notifyListeners();
        }).catchError((Object e, StackTrace st) {
          if (agniWireLogsEnabled) {
            _wireLog('[VoiceVM] connect() failed: $e');
          }
          developer.log(
            'connectAsync failed',
            name: 'VoiceVM',
            error: e,
            stackTrace: st,
          );
          notifyListeners();
        }),
      );
    }
  }

  void _initConnectivity() {
    _connectivitySub = _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    unawaited(_refreshConnectivityOnce());
  }

  Future<void> _refreshConnectivityOnce() async {
    try {
      final r = await _connectivity.checkConnectivity();
      _applyConnectivity(r);
      notifyListeners();
    } catch (_) {}
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    _applyConnectivity(results);
    notifyListeners();
  }

  void _applyConnectivity(List<ConnectivityResult> results) {
    _isOffline =
        results.isEmpty || results.every((e) => e == ConnectivityResult.none);
  }

  /// True when no usable network interface (informational only).
  bool get isOffline => _isOffline;

  /// Web: voice WebSocket is OPEN (AgniApp-style connection state).
  bool get webSocketConnected => kIsWeb && _socket.isConnected;

  /// Web: voice WebSocket is CONNECTING.
  bool get webSocketConnecting => kIsWeb && _socket.isConnecting;

  /// Shown when [getUserMedia] fails in the browser (see [web/audio_processor.js]).
  String? get micBlockedMessage => _micBlockedMessage;

  /// True briefly after idle check-in was sent to the server (see [dismissPresenceCheckIn]).
  bool get presenceCheckSent => _presenceCheckSent;

  void clearMicBlockedMessage() {
    if (_micBlockedMessage == null) return;
    _micBlockedMessage = null;
    notifyListeners();
  }

  void dismissPresenceCheckIn() {
    if (!_presenceCheckSent) return;
    _presenceCheckSent = false;
    notifyListeners();
  }

  void _cancelPresencePromptTimer() {
    _presencePromptTimer?.cancel();
    _presencePromptTimer = null;
  }

  void _schedulePresencePromptTimer() {
    _cancelPresencePromptTimer();
    if (!kIsWeb || !isListening) return;
    if (_sessionPhase != VoiceSessionPhase.listening) return;
    if (_awaitingWebTurn || isAgentSpeaking || isProcessing) return;

    _presencePromptTimer = Timer(
      ListeningIdlePolicy.userPresencePromptIdle,
      _onPresencePromptFired,
    );
  }

  void _onPresencePromptFired() {
    _presencePromptTimer = null;
    if (!kIsWeb || !isListening) return;
    if (_sessionPhase != VoiceSessionPhase.listening) return;
    if (_awaitingWebTurn || isAgentSpeaking || isProcessing) return;

    _socket.send({
      'type': VoiceSessionProtocol.clientPresenceCheck,
      'text': VoiceSessionProtocol.clientPresenceCheckDefaultText,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
    _vmLog('*******************************************');
    _vmLog('sent ${VoiceSessionProtocol.clientPresenceCheck}', verbose: true);
    _vmLog('*******************************************');
    _presenceCheckSent = true;
    notifyListeners();
    _schedulePresencePromptTimer();
  }

  void _onUserSpeechResetsPresencePrompt() {
    if (_presenceCheckSent) {
      _presenceCheckSent = false;
    }
    _schedulePresencePromptTimer();
  }

  void _onMicCaptureError(String message) {
    if (!kIsWeb) return;
    _micBlockedMessage =
        'Microphone access blocked (${message.trim()}). In Chrome: click the lock or tune icon left of the address bar → Site settings → Microphone → Allow. Or Chrome menu (⋮) → Settings → Privacy and security → Site settings → Microphone.';
    notifyListeners();
  }

  /// Mic is muted by user (tap). Unmute with [startListening].
  bool get micMutedByUser => _userMutedMic;

  @override
  void dispose() {
    _cancelIdleTimers();
    _connectivitySub?.cancel();
    _jsonSub?.cancel();
    _audioSub?.cancel();
    if (kIsWeb) {
      _socket.close();
    }
    super.dispose();
  }

  /// Idle / continue-session phase (web). See [ListeningIdlePolicy].
  VoiceSessionPhase get sessionPhase => _sessionPhase;

  /// Show Yes/No when server asked for explicit continue ([session_policy] `ask_user`).
  bool get showContinueButtons =>
      kIsWeb && _sessionPhase == VoiceSessionPhase.awaitingContinueAnswer;

  String get statusText {
    if (kIsWeb && _userMutedMic) {
      return 'Mic off — tap the mic to speak';
    }
    if (kIsWeb && _sessionPhase == VoiceSessionPhase.awaitingPolicy) {
      return _serverStatus != null && _serverStatus!.isNotEmpty
          ? _serverStatus!
          : 'Waiting for session…';
    }
    if (kIsWeb && _sessionPhase == VoiceSessionPhase.awaitingContinueAnswer) {
      return _serverStatus != null && _serverStatus!.isNotEmpty
          ? _serverStatus!
          : 'Continue? Tap Yes or No';
    }
    if (kIsWeb && _serverStatus != null && _serverStatus!.isNotEmpty) {
      return _serverStatus!;
    }
    if (isListening) {
      final idleHint = kIsWeb
          ? ' · idle ${ListeningIdlePolicy.idleNoSpeech.inSeconds}s → ping server'
          : '';
      return 'Listening…';
    }
    if (isProcessing) return 'Agent is responding…';
    if (isAgentSpeaking) return 'Agent speaking… (speak to interrupt)';
    return 'Tap the mic to unmute';
  }

  /// Toggle agent voice output (web TTS chunks). Stops current playback when muting.
  void toggleAgentTtsMuted() {
    agentTtsMuted = !agentTtsMuted;
    if (agentTtsMuted) {
      unawaited(_playerService.stop());
      isAgentSpeaking = false;
    }
    notifyListeners();
  }

  /// Stops assistant TTS/playback before overlays (e.g. demo video). Does not change mic state.
  void stopAgentForDemoVideo() {
    _vmLog('stopAgentForDemoVideo');
    if (kIsWeb) {
      _socket.interrupt();
      _cancelWebTurnForInterrupt('demo_video');
      isAgentSpeaking = false;
      notifyListeners();
      return;
    }
    unawaited(_playerService.stop());
    isAgentSpeaking = false;
    notifyListeners();
  }

  /// Mic button: mute capture if live, else unmute and start capture.
  Future<void> toggleListening() async {
    if (kIsWeb) {
      if (isListening) {
        await muteMic();
      } else {
        _userMutedMic = false;
        await startListening();
      }
      return;
    }
    if (isListening) {
      await stopListeningNative();
    } else {
      await startListening();
    }
  }

  /// Auto-start from VoiceScreen (option B). Safe to call once.
  Future<void> requestAutostartMic() async {
    if (!kIsWeb) return;
    if (_userMutedMic) return;
    if (isListening) return;
    _vmLog('autostart: startListening');
    await startListening();
  }

  Future<void> startListening() async {
    if (isListening) return;
    if (!kIsWeb && _isSending) return;

    _userMutedMic = false;

    if (kIsWeb) {
      _vmLog('startListening(web): mic streaming', verbose: true);
      _presenceCheckSent = false;
      _bargeInSpeechStart = null;
      amplitudeDb = -120;
      _sessionPhase = VoiceSessionPhase.listening;
      _micBlockedMessage = null;

      isListening = true;
      notifyListeners();

      _audioWeb.start(
        onLevel: _onAmplitude,
        onMicError: _onMicCaptureError,
      );
      _scheduleIdleNoSpeechTimer();
      _schedulePresencePromptTimer();
      unawaited(AudioPlayerService.ensurePlaybackAudioContext());
      return;
    }

    amplitudeDb = -120;

    isListening = true;
    notifyListeners();

    await _recordService.startRecording(
      onAmplitude: _onAmplitude,
    );
  }

  /// Stop capture only (web). Does not commit an utterance.
  Future<void> muteMic() async {
    if (!isListening) return;
    _vmLog('muteMic: user stopped capture');
    _cancelIdleTimers();
    _sessionPhase = VoiceSessionPhase.listening;
    _userMutedMic = true;
    isListening = false;
    _bargeInSpeechStart = null;
    if (kIsWeb) {
      _cancelWebTurnForInterrupt('mute_mic');
      _audioWeb.stop();
    }
    notifyListeners();
  }

  /// Unblocks [_runWebTurnCompletion] and stops playback after interrupt / mute.
  void _cancelWebTurnForInterrupt(String reason) {
    if (!kIsWeb) return;
    debugPrint('[VoiceAudio] cancel web turn: $reason');
    _expectingAssistantBinary = false;
    _ttsGraceUntil = null;
    unawaited(_playerService.stop());
    _completeWebTurnIfPending();
  }

  void _cancelIdleTimers() {
    _idleNoSpeechTimer?.cancel();
    _idleNoSpeechTimer = null;
    _continuePromptTimer?.cancel();
    _continuePromptTimer = null;
    _cancelPresencePromptTimer();
    _presenceCheckSent = false;
  }

  void _cancelIdleNoSpeechTimer() {
    _idleNoSpeechTimer?.cancel();
    _idleNoSpeechTimer = null;
  }

  /// After [ListeningIdlePolicy.idleNoSpeech] with no speech — sends [VoiceSessionProtocol.clientIdle].
  void _scheduleIdleNoSpeechTimer() {
    _cancelIdleNoSpeechTimer();
    if (!kIsWeb || !isListening || _awaitingWebTurn) return;
    if (_sessionPhase != VoiceSessionPhase.listening) return;

    _idleNoSpeechTimer = Timer(ListeningIdlePolicy.idleNoSpeech, _onIdleNoSpeechFired);
    _vmLog(
      'idle no-speech timer ${ListeningIdlePolicy.idleNoSpeech.inSeconds}s',
      verbose: true,
    );
  }

  void _onIdleNoSpeechFired() {
    _idleNoSpeechTimer = null;
    if (!kIsWeb || !isListening || _awaitingWebTurn) return;
    if (_sessionPhase != VoiceSessionPhase.listening) return;

    _cancelPresencePromptTimer();
    _presenceCheckSent = false;

    _socket.send({
      'type': VoiceSessionProtocol.clientIdle,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
    _sessionPhase = VoiceSessionPhase.awaitingPolicy;
    _vmLog('sent ${VoiceSessionProtocol.clientIdle}', verbose: true);
    notifyListeners();
  }

  void _startContinuePromptTimer() {
    _continuePromptTimer?.cancel();
    _continuePromptTimer = Timer(
      ListeningIdlePolicy.continuePromptTimeout,
      () {
        if (_sessionPhase != VoiceSessionPhase.awaitingContinueAnswer) return;
        _vmLog('continue prompt timeout → muteMic', verbose: true);
        unawaited(muteMic());
      },
    );
  }

  /// UI / voice yes-no: sends [VoiceSessionProtocol.continueIntent].
  void submitContinueIntent(bool continueListening) {
    if (!kIsWeb) return;
    _continuePromptTimer?.cancel();
    _continuePromptTimer = null;

    _socket.send({
      'type': VoiceSessionProtocol.continueIntent,
      'intent':
          continueListening ? VoiceSessionProtocol.intentYes : VoiceSessionProtocol.intentNo,
    });

    if (continueListening) {
      _sessionPhase = VoiceSessionPhase.listening;
      _serverStatus = null;
      if (isListening) {
        _scheduleIdleNoSpeechTimer();
        _schedulePresencePromptTimer();
      }
      notifyListeners();
    } else {
      unawaited(muteMic());
    }
  }

  void _onSessionPolicy(Map<String, dynamic> data) {
    final action = data['action'] as String?;
    final continueSession = data['continueSession'];
    final prompt = (data['prompt'] ?? data['text'] ?? '').toString();

    if (continueSession == false || action == 'stop') {
      unawaited(muteMic());
      return;
    }

    if (continueSession == true || action == 'continue') {
      _sessionPhase = VoiceSessionPhase.listening;
      _serverStatus = prompt.isNotEmpty ? prompt : null;
      if (isListening) {
        _scheduleIdleNoSpeechTimer();
        _schedulePresencePromptTimer();
      }
      notifyListeners();
      return;
    }

    if (action == 'ask_user') {
      _cancelPresencePromptTimer();
      _presenceCheckSent = false;
      _sessionPhase = VoiceSessionPhase.awaitingContinueAnswer;
      _serverStatus = prompt.isNotEmpty ? prompt : 'Continue? Tap Yes or No';
      _startContinuePromptTimer();
      notifyListeners();
      return;
    }

    if (continueSession == null && action == null) {
      _vmLog('session_policy: no action; ignoring', verbose: true);
      return;
    }

    _sessionPhase = VoiceSessionPhase.listening;
    if (isListening) {
      _scheduleIdleNoSpeechTimer();
      _schedulePresencePromptTimer();
    }
    notifyListeners();
  }

  void _onAmplitude(double db) {
    if (!isListening) return;

    amplitudeDb = db;

    final now = DateTime.now();
    if (now.difference(_lastUiUpdateAt) >= const Duration(milliseconds: 80)) {
      _lastUiUpdateAt = now;
      notifyListeners();
    }

    if (kIsWeb) {
      _maybeBargeIn(now, db);
    }

    if (db >= _speechThresholdDb) {
      if (kIsWeb) {
        if (_sessionPhase == VoiceSessionPhase.awaitingPolicy) {
          _sessionPhase = VoiceSessionPhase.listening;
          _serverStatus = null;
          notifyListeners();
        }
        _scheduleIdleNoSpeechTimer();
        _onUserSpeechResetsPresencePrompt();
      }
      return;
    }

    if (_awaitingWebTurn) {
      return;
    }

    if (kIsWeb && _sessionPhase != VoiceSessionPhase.listening) {
      return;
    }
  }

  void _maybeBargeIn(DateTime now, double db) {
    if (db < _speechThresholdDb) {
      _bargeInSpeechStart = null;
      return;
    }
    // Interrupt while assistant is streaming text/TTS or playing audio (not when idle).
    if (!isAgentSpeaking && !isProcessing) {
      _bargeInSpeechStart = null;
      return;
    }

    _bargeInSpeechStart ??= now;
    if (now.difference(_bargeInSpeechStart!) < _bargeInHold) {
      return;
    }

    _vmLog('barge-in: interrupt + stop playback');
    _bargeInSpeechStart = null;
    _socket.interrupt();
    _cancelWebTurnForInterrupt('barge_in');
    isAgentSpeaking = false;
    notifyListeners();
    if (kIsWeb) {
      _schedulePresencePromptTimer();
    }
  }

  /// After [client_idle], [_sessionPhase] is [awaitingPolicy]. Server may still stream reply + TTS.
  void _exitAwaitingPolicyForAssistantSignal() {
    if (_sessionPhase != VoiceSessionPhase.awaitingPolicy) return;
    _sessionPhase = VoiceSessionPhase.listening;
    _serverStatus = null;
    if (isListening) {
      _scheduleIdleNoSpeechTimer();
      _schedulePresencePromptTimer();
    }
  }

  /// Opens a web assistant turn when the backend signals a response (transcript, [status] speaking, or [ai_stream]).
  /// Idempotent: safe to call on every matching JSON frame while already in a turn.
  ///
  /// Does not require [isListening]: the server may stream TTS before or without the local mic
  /// (same idea as AgniApp always wiring `audioChunks` while connected).
  void _beginWebAssistantTurn() {
    if (!kIsWeb) return;
    _exitAwaitingPolicyForAssistantSignal();
    if (_sessionPhase != VoiceSessionPhase.listening) return;
    if (_awaitingWebTurn) {
      return;
    }
    if (_isStopping) return;

    _vmLog('begin assistant turn (backend signal)', verbose: true);

    _cancelIdleNoSpeechTimer();
    _cancelPresencePromptTimer();
    _presenceCheckSent = false;

    _awaitingWebTurn = true;
    _expectingAssistantBinary = false;
    isProcessing = true;
    isAgentSpeaking = false;

    messages.add(VoiceMessage(text: '…', isUser: true));
    messages.add(VoiceMessage(text: '', isUser: false));
    _userMsgIndex = messages.length - 2;
    _agentMsgIndex = messages.length - 1;

    _webTurnCompleter = Completer<void>();
    notifyListeners();

    unawaited(_runWebTurnCompletion());
  }

  Future<void> _runWebTurnCompletion() async {
    final turn = _webTurnCompleter;
    try {
      await _playerService.stop();
      if (turn != null) {
        await turn.future.timeout(
          const Duration(minutes: 2),
          onTimeout: () {
            if (!turn.isCompleted) {
              turn.complete();
            }
          },
        );
      }
      await Future<void>.delayed(_ttsPostDoneDrain);
      await _playerService.waitUntilPlaybackIdle();
    } finally {
      isAgentSpeaking = false;
      isProcessing = false;
      _awaitingWebTurn = false;
      _expectingAssistantBinary = false;
      _ttsGraceUntil = null;
      _isSending = false;
      _userMsgIndex = null;
      _agentMsgIndex = null;
      _webTurnCompleter = null;
      _serverStatus = null;
      notifyListeners();
      if (kIsWeb && isListening && !_awaitingWebTurn) {
        _scheduleIdleNoSpeechTimer();
        _schedulePresencePromptTimer();
      }
    }
  }

  void _notifyTextDebounced() {
    final now = DateTime.now();
    if (now.difference(_lastTextUiUpdateAt) >= const Duration(milliseconds: 60)) {
      _lastTextUiUpdateAt = now;
      notifyListeners();
    }
  }

  void _onWebJson(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (agniWireLogsEnabled) {
      _rxMsgCount++;
      final latency = data['latency'];
      print('[VoiceVM] Received message: $data');
      _wireLog(
        '[VoiceVM] ✅ message[$_rxMsgCount] type=${type ?? "unknown"} '
        'keys=${data.keys.join(",")} '
        'latency=${latency is Map ? latency : "n/a"}',
      );
      try {
        final full = jsonEncode(data);
        _wireLog('[VoiceVM] json ← FULL type=$type $full');
      } catch (_) {
        _wireLog('[VoiceVM] json ← FULL (non-encodable) type=$type $data');
      }
    }

    switch (type) {
      case 'session_start':
        _vmLog('session_start');
        break;
      case 'server_ping':
        break;
      case 'partial':
      case 'transcript':
        final text = (data['text'] ?? '').toString();
        if (kIsWeb && isListening && text.isNotEmpty) {
          unawaited(_playerService.stop());
        }
        if (kIsWeb && text.isNotEmpty) {
          _beginWebAssistantTurn();
        }
        if (_userMsgIndex != null && text.isNotEmpty) {
          messages[_userMsgIndex!].text = text;
          _notifyTextDebounced();
        }
        if (kIsWeb && text.isNotEmpty) {
          _scheduleIdleNoSpeechTimer();
        }
        break;
      case VoiceSessionProtocol.sessionPolicy:
        if (kIsWeb) {
          _onSessionPolicy(data);
        }
        break;
      case 'status':
        _serverStatus = (data['text'] ?? '').toString();
        final statusLower = _serverStatus?.toLowerCase() ?? '';
        if (kIsWeb && statusLower == 'speaking') {
          _beginWebAssistantTurn();
        }
        notifyListeners();
        break;
      case 'ai_stream':
        if (kIsWeb) {
          _beginWebAssistantTurn();
        }
        final delta = (data['text'] ?? '').toString();
        if (_agentMsgIndex != null) {
          messages[_agentMsgIndex!].text += delta;
          _notifyTextDebounced();
        }
        isProcessing = true;
        _cancelPresencePromptTimer();
        break;
      case 'ai_done':
        isProcessing = false;
        _serverStatus = null;
        _ttsGraceUntil = DateTime.now().add(_ttsGraceAfterDone);
        _completeWebTurnIfPending();
        notifyListeners();
        if (kIsWeb) {
          _schedulePresencePromptTimer();
        }
        break;
      case 'error':
        final msg = (data['text'] ?? data['error'] ?? 'Error').toString();
        if (_agentMsgIndex != null) {
          messages[_agentMsgIndex!].text = msg;
        }
        isProcessing = false;
        _serverStatus = null;
        _ttsGraceUntil = DateTime.now().add(_ttsGraceAfterDone);
        _completeWebTurnIfPending();
        notifyListeners();
        if (kIsWeb) {
          _schedulePresencePromptTimer();
        }
        break;
      case 'interrupt':
        _vmLog('interrupt (server)');
        _cancelWebTurnForInterrupt('server_interrupt');
        isAgentSpeaking = false;
        notifyListeners();
        if (kIsWeb) {
          _schedulePresencePromptTimer();
        }
        break;
      case 'session_update':
        if (data['session'] is Map) {
          notifyListeners();
        }
        break;
      case 'speaker':
        break;
      case 'backchannel':
        _vmLog('backchannel: ${data['text']}', verbose: true);
        break;
      case 'set_voice':
      case 'voice_changed':
      case 'reset_ack':
        break;
      default:
        _vmLog('unhandled type=$type');
        break;
    }
  }

  void _completeWebTurnIfPending() {
    final c = _webTurnCompleter;
    if (c != null && !c.isCompleted) {
      c.complete();
    }
    _webTurnCompleter = null;
  }

  void _onWebAudio(Uint8List chunk) {
    if (chunk.isEmpty) return;
    if (agniWireLogsEnabled) {
      _rxChunkCount++;
      _rxChunkBytes += chunk.length;
      _wireLog(
        '[VoiceVM] 🔊 audio chunk[$_rxChunkCount] '
        'bytes=${chunk.length} total=$_rxChunkBytes',
      );
    }
    final inGrace = _ttsGraceUntil != null &&
        DateTime.now().isBefore(_ttsGraceUntil!);
    final acceptTts =
        _awaitingWebTurn || inGrace || _expectingAssistantBinary;
    if (kIsWeb && !acceptTts) {
      final now = DateTime.now();
      if (_lastVoiceAudioDropLogAt == null ||
          now.difference(_lastVoiceAudioDropLogAt!) >= const Duration(milliseconds: 800)) {
        _lastVoiceAudioDropLogAt = now;
        debugPrint(
          '[VoiceAudio] dropped binary ${chunk.length}B: not accepting TTS (no turn, grace, or pre-commit expectation)',
        );
      }
      _vmLog('TTS chunk ignored (no active turn) ${chunk.length}B', verbose: true);
      return;
    }
    if (agentTtsMuted) {
      _vmLog('TTS skipped (agent audio muted)', verbose: true);
      return;
    }
    _vmLog('TTS chunk → playBytes queue +${chunk.length}B', verbose: true);
    _cancelPresencePromptTimer();
    isAgentSpeaking = true;
    notifyListeners();
    final bytes = Uint8List.fromList(chunk);
    unawaited(
      _playerService.playBytes(bytes).catchError((Object e, StackTrace st) {
        debugPrint('[VoiceAudio] playBytes chunk failed: $e');
        developer.log('playBytes chunk failed', name: 'VoiceVM', error: e, stackTrace: st);
      }),
    );
  }

  /// Native: stop recording and upload. Web: use [muteMic].
  Future<void> stopListeningNative() async {
    if (!isListening) return;
    if (_isStopping) return;

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

    messages.add(
      VoiceMessage(text: 'You (voice)', isUser: true),
    );
    messages.add(
      VoiceMessage(text: '', isUser: false),
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
        onDone: () {},
        onError: (error) {
          throw error;
        },
        onTtsBytes: (bytes) {
          isAgentSpeaking = true;
          notifyListeners();
          unawaited(_playerService.playBytes(Uint8List.fromList(bytes)));
        },
      );

      if (lastAudioFuture != null) {
        await lastAudioFuture;
      }
      await _playerService.waitUntilPlaybackIdle();
      isAgentSpeaking = false;
    } catch (_) {
      await _playerService.stop();
      messages[agentMsgIndex].text = '(stream failed)';
      isAgentSpeaking = false;
    } finally {
      isProcessing = false;
      _isSending = false;
      notifyListeners();
    }
  }
}
