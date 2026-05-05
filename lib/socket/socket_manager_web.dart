import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:html';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:tds_voice_agent/core/wire_logs.dart';

class SocketManager {
  static final SocketManager _instance = SocketManager._internal();
  factory SocketManager() => _instance;

  SocketManager._internal();

  WebSocket? _socket;

  static const String _defaultWsUrl = 'wss://demo.nitya.ai/new/ws';
  static const String _agniWsEnv =
      String.fromEnvironment('AGNI_WS_URL', defaultValue: '');
  static const String _voiceWsEnv =
      String.fromEnvironment('VOICE_WS_URL', defaultValue: '');

  /// Prefer [AGNI_WS_URL] when set (AgniApp parity), else [VOICE_WS_URL], else default.
  static String get _wsUrl {
    if (_agniWsEnv.isNotEmpty) return _agniWsEnv;
    if (_voiceWsEnv.isNotEmpty) return _voiceWsEnv;
    return _defaultWsUrl;
  }

  static String get currentWsUrl => _wsUrl;

  final _jsonController = StreamController<Map<String, dynamic>>.broadcast();
  final _audioController = StreamController<Uint8List>.broadcast();

  Stream<Map<String, dynamic>> get jsonStream => _jsonController.stream;
  Stream<Uint8List> get audioStream => _audioController.stream;

  static const int _maxPendingText = 32;
  static const int _maxPendingBinary = 64;

  final List<String> _pendingText = [];
  final List<Uint8List> _pendingBinary = [];

  int _jsonInCount = 0;
  int _binaryInCount = 0; 
  int _binaryRxBytesTotal = 0;
  int _textOutCount = 0;
  int _binaryOutCount = 0;

  Timer? _reconnectTimer;
  Completer<void>? _openCompleter;

  /// After [close], [onClose] will not schedule reconnect until the next [connect]/[connectAsync].
  bool _userClosed = false;

  bool get isConnected =>
      _socket != null && _socket!.readyState == WebSocket.OPEN;

  bool get isConnecting =>
      _socket != null && _socket!.readyState == WebSocket.CONNECTING;

  void _log(String message) {
    if (!agniWireLogsEnabled) return;
    debugPrint('[SocketManager] $message');
    developer.log(message, name: 'SocketManager');
    // Browser console parity with HTML `console.log` (debugPrint can throttle).
    print('[SocketManager] $message');
  }

  static const int _binHeaderHexBytes = 16;

  String _hexPrefix(ByteBuffer buf) {
    final view = Uint8List.view(buf);
    final n = view.length < _binHeaderHexBytes ? view.length : _binHeaderHexBytes;
    if (n == 0) return '(empty)';
    final parts = <String>[];
    for (var i = 0; i < n; i++) {
      parts.add(view[i].toRadixString(16).padLeft(2, '0'));
    }
    return parts.join(' ');
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _completeOpenSuccess() {
    final c = _openCompleter;
    if (c != null && !c.isCompleted) {
      c.complete();
    }
  }

  void _completeOpenError(Object error) {
    final c = _openCompleter;
    if (c != null && !c.isCompleted) {
      c.completeError(error);
    }
  }

  void _flushPending() {
    final s = _socket;
    if (s == null || s.readyState != WebSocket.OPEN) return;

    if (_pendingText.isNotEmpty || _pendingBinary.isNotEmpty) {
      _log(
        'flushPending: text=${_pendingText.length} binary=${_pendingBinary.length}',
      );
    }

    for (final msg in _pendingText) {
      s.send(msg);
    }
    _pendingText.clear();

    for (final chunk in _pendingBinary) {
      s.send(chunk);
    }
    _pendingBinary.clear();
  }

  /// Opens the WebSocket unless already OPEN or CONNECTING (AgniApp-style).
  void connect() {
    _userClosed = false;
    _connectSocket();
  }

  /// Resolves when the socket reaches OPEN for this attempt (or immediately if already OPEN).
  Future<void> connectAsync() async {
    connect();
    if (isConnected) return;
    final c = _openCompleter;
    if (c != null && !c.isCompleted) {
      return c.future;
    }
  }

  void _connectSocket() {
    if (_socket != null) {
      final state = _socket!.readyState;
      if (state == WebSocket.OPEN || state == WebSocket.CONNECTING) {
        _log(
          'connect skipped (already ${state == WebSocket.OPEN ? "OPEN" : "CONNECTING"}) url=$_wsUrl',
        );
        return;
      }
    }

    _cancelReconnect();
    _openCompleter = Completer<void>();
    _log('connect → new WebSocket url=$_wsUrl');
    _socket?.close();
    _socket = WebSocket(_wsUrl);
    _socket!.binaryType = 'arraybuffer';

    _socket!.onOpen.listen((_) {
      _log('onOpen READY state=${_socket?.readyState}');
      _flushPending();
      _completeOpenSuccess();
    });

    _socket!.onError.listen((Object e) {
      _log('onError: $e');
      _completeOpenError(e);
    });

    _socket!.onMessage.listen((event) {
      if (event.data is String) {
        final raw = event.data as String;
        try {
          final decoded = jsonDecode(raw);
          final map = decoded is Map<String, dynamic>
              ? decoded
              : Map<String, dynamic>.from(decoded as Map);
          _jsonInCount++;
          final t = map['type'];
          _log('← JSON_IN #$_jsonInCount type=$t FULL:\n$raw');
          _handleJson(map);
        } catch (e, st) {
          _log('jsonDecode failed: $e\nFULL raw:\n$raw\n$st');
        }
      } else if (event.data is ByteBuffer) {
        final buf = event.data as ByteBuffer;
        final len = buf.lengthInBytes;
        _binaryInCount++;
        _binaryRxBytesTotal += len;
        _log(
          '← BIN #$_binaryInCount ${len}B totalRx=$_binaryRxBytesTotal B '
          'header($_binHeaderHexBytes B hex)=${_hexPrefix(buf)}',
        );
        _audioController.add(Uint8List.view(buf));
      } else {
        _log('← unknown frame type=${event.data.runtimeType}');
      }
    });

    _socket!.onClose.listen((CloseEvent e) {
      _log(
        '########onClose code=${e.code} reason=${e.reason} wasClean=${e.wasClean}',
      );
      final openWait = _openCompleter;
      if (openWait != null && !openWait.isCompleted) {
        _completeOpenError(
          StateError('WebSocket closed before open (code=${e.code})'),
        );
      }
      if (_userClosed) {
        _log('onClose: user closed — no reconnect');
        return;
      }
      _log('→ reconnect in 2s');
      _reconnectTimer = Timer(const Duration(seconds: 2), () {
        if (_userClosed) return;
        _connectSocket();
      });
    });
  }

  /// Stops auto-reconnect and closes the socket (e.g. when [VoiceViewModel] is disposed).
  void close() {
    _userClosed = true;
    _cancelReconnect();
    _socket?.close();
    _socket = null;
    _completeOpenError(StateError('SocketManager closed'));
    _openCompleter = null;
  }

  /// Keepalive: many voice backends send periodic JSON `server_ping`; we must reply with `pong`
  /// or the server may close the socket. Handled here so all listeners still see the frame if needed.
  void _handleJson(Map<String, dynamic> data) {
    final t = data['type']?.toString();
    if (t == 'server_ping' || t == 'ping') {
      _log(
        '[Keepalive] server JSON ping (type=$t) → sending {"type":"pong"}',
      );
      send({'type': 'pong'});
    }
    _jsonController.add(data);
  }

  void send(Map<String, dynamic> data) {
    final encoded = jsonEncode(data);
    final s = _socket;
    if (s != null && s.readyState == WebSocket.OPEN) {
      _textOutCount++;
      _log('→ JSON_OUT #$_textOutCount FULL:\n$encoded');
      s.send(encoded);
    } else {
      while (_pendingText.length >= _maxPendingText) {
        _pendingText.removeAt(0);
      }
      _pendingText.add(encoded);
      _log(
        '→ JSON_OUT (queued ${_pendingText.length}) socket=${s == null ? "null" : s.readyState} FULL:\n$encoded',
      );
    }
  }

  void sendAudio(Uint8List bytes) {
    if (bytes.isEmpty) return;
    final s = _socket;
    if (s != null && s.readyState == WebSocket.OPEN) {
      _binaryOutCount++;
      if (_binaryOutCount <= 3 || _binaryOutCount % 100 == 0) {
        _log('→ PCM #$_binaryOutCount ${bytes.length}B (total binary frames sent)');
      }
      s.send(bytes);
    } else {
      while (_pendingBinary.length >= _maxPendingBinary) {
        _pendingBinary.removeAt(0);
      }
      _pendingBinary.add(Uint8List.fromList(bytes));
      if (_pendingBinary.length == 1 || _pendingBinary.length % 50 == 0) {
        _log(
          '→ PCM (queued ${_pendingBinary.length}) socket=${s == null ? "null" : s.readyState} lastChunk=${bytes.length}B',
        );
      }
    }
  }

  void interrupt() {
    send({'type': 'interrupt'});
  }
}
