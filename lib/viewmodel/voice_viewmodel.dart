import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tds_voice_agent/service/audio_palyer_service.dart';

import '../audio/audio_web.dart';
import '../model/voice_message.dart';
import '../service/audio_record_service.dart';
import '../service/voice_service.dart';
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

  /// When false, only important logs (barge-in, mute, errors, session).
  static const bool _verboseLogs = false;

  String _previewJson(Map<String, dynamic> data) {
    try {
      final s = jsonEncode(data);
      if (s.length <= 600) return s;
      return '${s.substring(0, 600)}…(${s.length} chars)';
    } catch (_) {
      return data.toString();
    }
  }

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

  /// Accumulates binary TTS for one web turn — many servers send MPEG chunks that are not valid alone in [AudioElement].
  BytesBuilder? _ttsBuffer;

  VoiceSessionPhase _sessionPhase = VoiceSessionPhase.listening;
  Timer? _idleNoSpeechTimer;
  Timer? _continuePromptTimer;

  static const Duration _silenceDuration = Duration(seconds: 3);
  /// Brief wait after [ai_done] so trailing TTS frames are merged before decode/play.
  static const Duration _ttsPostDoneDrain = Duration(milliseconds: 220);
  static const double _speechThresholdDb = -35.0;
  static const Duration _bargeInHold = Duration(milliseconds: 280);

  DateTime _lastSpeechAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _autoSendTriggered = false;
  bool _isStopping = false;
  bool _isSending = false;
  DateTime? _bargeInSpeechStart;
  DateTime _lastUiUpdateAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastTextUiUpdateAt = DateTime.fromMillisecondsSinceEpoch(0);

  VoiceViewModel() {
    if (kIsWeb) {
      _vmLog('init: WebSocket + streams');
      _socket.connect();
      _jsonSub = _socket.jsonStream.listen(_onWebJson);
      _audioSub = _socket.audioStream.listen(_onWebAudio);
    }
  }

  /// Mic is muted by user (tap). Unmute with [startListening].
  bool get micMutedByUser => _userMutedMic;

  @override
  void dispose() {
    _cancelIdleTimers();
    _jsonSub?.cancel();
    _audioSub?.cancel();
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
      return 'Listening… (silence ${_silenceDuration.inSeconds}s sends turn)$idleHint';
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
      _autoSendTriggered = false;
      _lastSpeechAt = DateTime.now();
      _bargeInSpeechStart = null;
      amplitudeDb = -120;
      _sessionPhase = VoiceSessionPhase.listening;

      isListening = true;
      notifyListeners();

      _audioWeb.start(onLevel: _onAmplitude);
      _scheduleIdleNoSpeechTimer();
      return;
    }

    _autoSendTriggered = false;
    _lastSpeechAt = DateTime.now();
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
      _audioWeb.stop();
    }
    notifyListeners();
  }

  void _cancelIdleTimers() {
    _idleNoSpeechTimer?.cancel();
    _idleNoSpeechTimer = null;
    _continuePromptTimer?.cancel();
    _continuePromptTimer = null;
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
      }
      notifyListeners();
      return;
    }

    if (action == 'ask_user') {
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
      _lastSpeechAt = now;
      if (kIsWeb) {
        if (_sessionPhase == VoiceSessionPhase.awaitingPolicy) {
          _sessionPhase = VoiceSessionPhase.listening;
          _serverStatus = null;
          notifyListeners();
        }
        _scheduleIdleNoSpeechTimer();
      }
      return;
    }

    if (_awaitingWebTurn) {
      return;
    }

    if (kIsWeb && _sessionPhase != VoiceSessionPhase.listening) {
      return;
    }

    if (!_autoSendTriggered &&
        now.difference(_lastSpeechAt) >= _silenceDuration) {
      _autoSendTriggered = true;
      _vmLog('silence ${_silenceDuration.inSeconds}s → commit utterance (mic stays on)');
      Future.microtask(() {
        if (kIsWeb) {
          unawaited(_commitWebUtteranceFromSilence());
        }
      });
    }
  }

  void _maybeBargeIn(DateTime now, double db) {
    if (db < _speechThresholdDb) {
      _bargeInSpeechStart = null;
      return;
    }
    if (!isAgentSpeaking && !isProcessing && !_awaitingWebTurn) {
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
    unawaited(_playerService.stop());
    isAgentSpeaking = false;
    notifyListeners();
  }

  Future<void> _commitWebUtteranceFromSilence() async {
    if (!kIsWeb) return;
    if (!isListening) return;
    if (_sessionPhase != VoiceSessionPhase.listening) {
      _autoSendTriggered = false;
      return;
    }
    if (_awaitingWebTurn) {
      _vmLog('commit skipped: already awaiting turn');
      _autoSendTriggered = false;
      return;
    }
    if (_isStopping) return;

    _cancelIdleNoSpeechTimer();
    _ttsBuffer = BytesBuilder();

    _awaitingWebTurn = true;
    isProcessing = true;
    isAgentSpeaking = false;

    messages.add(VoiceMessage(text: '…', isUser: true));
    messages.add(VoiceMessage(text: '', isUser: false));
    _userMsgIndex = messages.length - 2;
    _agentMsgIndex = messages.length - 1;

    _webTurnCompleter = Completer<void>();
    notifyListeners();

    await _runWebTurnCompletion();
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
      await _playAccumulatedTtsIfAny();
      await _playerService.waitUntilPlaybackIdle();
    } finally {
      isAgentSpeaking = false;
      isProcessing = false;
      _awaitingWebTurn = false;
      _ttsBuffer = null;
      _isSending = false;
      _userMsgIndex = null;
      _agentMsgIndex = null;
      _webTurnCompleter = null;
      _serverStatus = null;
      _autoSendTriggered = false;
      _lastSpeechAt = DateTime.now();
      notifyListeners();
      if (kIsWeb && isListening && !_awaitingWebTurn) {
        _scheduleIdleNoSpeechTimer();
      }
    }
  }

  Future<void> _playAccumulatedTtsIfAny() async {
    if (agentTtsMuted) return;
    final buf = _ttsBuffer;
    if (buf == null || buf.length == 0) return;
    final bytes = buf.toBytes();
    if (bytes.isEmpty) return;
    isAgentSpeaking = true;
    notifyListeners();
    try {
      await _playerService.playBytes(bytes);
    } catch (e) {
      _vmLog('play accumulated TTS failed: $e');
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
    _vmLog('json ← type=$type ${_previewJson(data)}', verbose: true);

    switch (type) {
      case 'session_start':
        _vmLog('session_start');
        break;
      case 'server_ping':
        break;
      case 'partial':
      case 'transcript':
        final text = (data['text'] ?? '').toString();
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
        notifyListeners();
        break;
      case 'ai_stream':
        final delta = (data['text'] ?? '').toString();
        if (_agentMsgIndex != null) {
          messages[_agentMsgIndex!].text += delta;
          _notifyTextDebounced();
        }
        isProcessing = true;
        break;
      case 'ai_done':
        isProcessing = false;
        _serverStatus = null;
        _completeWebTurnIfPending();
        notifyListeners();
        break;
      case 'error':
        final msg = (data['text'] ?? data['error'] ?? 'Error').toString();
        if (_agentMsgIndex != null) {
          messages[_agentMsgIndex!].text = msg;
        }
        isProcessing = false;
        _serverStatus = null;
        _completeWebTurnIfPending();
        notifyListeners();
        break;
      case 'interrupt':
        _vmLog('interrupt (server)');
        unawaited(_playerService.stop());
        isAgentSpeaking = false;
        notifyListeners();
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
    if (kIsWeb && !_awaitingWebTurn) {
      _vmLog('TTS chunk ignored (no active turn) ${chunk.length}B', verbose: true);
      return;
    }
    if (agentTtsMuted) {
      _vmLog('TTS skipped (agent audio muted)', verbose: true);
      return;
    }
    _vmLog('TTS +${chunk.length}B (buffered)', verbose: true);
    _ttsBuffer ??= BytesBuilder();
    _ttsBuffer!.add(chunk);
  }

  /// Native: stop recording and upload. Web: use [muteMic] or silence commit.
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
          unawaited(_playerService.playBytes(bytes));
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
