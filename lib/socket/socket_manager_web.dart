import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:html';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

class SocketManager {
  static final SocketManager _instance = SocketManager._internal();
  factory SocketManager() => _instance;

  SocketManager._internal();

  WebSocket? _socket;

  static const String _defaultWsUrl = 'ws://192.168.0.20:9876/new/ws';
  static const String _wsUrl = String.fromEnvironment(
    'VOICE_WS_URL',
    defaultValue: _defaultWsUrl,
  );

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
  int _textOutCount = 0;
  int _binaryOutCount = 0;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[SocketManager] $message');
      developer.log(message, name: 'SocketManager');
    }
  }

  String _preview(String s, [int max = 400]) {
    if (s.length <= max) return s;
    return '${s.substring(0, max)}…(${s.length} chars)';
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

  void connect() {
    if (_socket != null) {
      final state = _socket!.readyState;
      if (state == WebSocket.OPEN || state == WebSocket.CONNECTING) {
        _log(
          'connect skipped (already ${state == WebSocket.OPEN ? "OPEN" : "CONNECTING"}) url=$_wsUrl',
        );
        return;
      }
    }

    _log('connect → new WebSocket url=$_wsUrl');
    _socket?.close();
    _socket = WebSocket(_wsUrl);
    _socket!.binaryType = 'arraybuffer';

    _socket!.onOpen.listen((_) {
      _log('onOpen READY state=${_socket?.readyState}');
      _flushPending();
    });

    _socket!.onError.listen((Object e) {
      _log('onError: $e');
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
          _log('← JSON preview #$_jsonInCount type=$t ${_preview(raw)}');
          _handleJson(map);
        } catch (e, st) {
          _log('jsonDecode failed: $e raw=${_preview(raw)} $st');
        }
      } else if (event.data is ByteBuffer) {
        final buf = event.data as ByteBuffer;
        final len = buf.lengthInBytes;
        _binaryInCount++;
        _log('← BIN #$_binaryInCount ${len}B');
        _audioController.add(Uint8List.view(buf));
      } else {
        _log('← unknown frame type=${event.data.runtimeType}');
      }
    });

    _socket!.onClose.listen((CloseEvent e) {
      _log(
        '########onClose code=${e.code} reason=${e.reason} wasClean=${e.wasClean} → reconnect in 2s',
      );
      Future.delayed(const Duration(seconds: 2), connect);
    });
  }

  /// Keepalive: many voice backends send periodic JSON `server_ping`; we must reply with `pong`
  /// or the server may close the socket. Handled here so all listeners still see the frame if needed.
  void _handleJson(Map<String, dynamic> data) {
    final t = data['type']?.toString();
    if (t == 'server_ping' || t == 'ping') {
      _log('[Keepalive] server JSON ping (type=$t) → sending {"type":"pong"}');
      send({'type': 'pong'});
    }
    _jsonController.add(data);
  }

  void send(Map<String, dynamic> data) {
    final encoded = jsonEncode(data);
    final s = _socket;
    if (s != null && s.readyState == WebSocket.OPEN) {
      _textOutCount++;
      _log('→ JSON #$_textOutCount ${_preview(encoded)}');
      s.send(encoded);
    } else {
      while (_pendingText.length >= _maxPendingText) {
        _pendingText.removeAt(0);
      }
      _pendingText.add(encoded);
      _log(
        '→ JSON (queued ${_pendingText.length}) socket=${s == null ? "null" : s.readyState} ${_preview(encoded)}',
      );
    }
  }

  void sendAudio(Uint8List bytes) {
    if (bytes.isEmpty) return;
    final s = _socket;
    if (s != null && s.readyState == WebSocket.OPEN) {
      _binaryOutCount++;
      if (_binaryOutCount <= 3 || _binaryOutCount % 100 == 0) {
        _log(
          '→ PCM #$_binaryOutCount ${bytes.length}B (total binary frames sent)',
        );
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
