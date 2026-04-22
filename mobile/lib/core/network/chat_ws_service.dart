import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import '../storage/secure_storage.dart';

class ChatEvent {
  final String eventId;
  final String type;
  final String conversationId;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  const ChatEvent({
    required this.eventId,
    required this.type,
    required this.conversationId,
    required this.payload,
    required this.timestamp,
  });

  factory ChatEvent.fromJson(Map<String, dynamic> json) {
    final eventJson = (json['data'] as Map<String, dynamic>?) ?? json;
    final rawType = eventJson['type']?.toString() ?? json['type'] as String;

    return ChatEvent(
      eventId: eventJson['eventId'] as String,
      type: rawType.replaceAll('.', '_'),
      conversationId: eventJson['conversationId'] as String,
      payload: eventJson['payload'] as Map<String, dynamic>,
      timestamp: DateTime.parse(eventJson['timestamp'] as String),
    );
  }
}

class ChatWsService {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  final _eventController = StreamController<ChatEvent>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  bool _disposed = false;
  bool _connected = false;

  Stream<ChatEvent> get events => _eventController.stream;
  Stream<bool> get connectionState => _connectionController.stream;
  bool get isConnected => _connected;

  Future<void> connect() async {
    if (_disposed) return;

    final storage = SecureStorage();
    final accessToken = await storage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) return;

    final apiUri = Uri.parse(AppConfig.apiBaseUrl);
    final path = '${apiUri.path.replaceFirst(RegExp(r'/$'), '')}/chat/ws';
    final uri = Uri(
      scheme: apiUri.scheme == 'https' ? 'wss' : 'ws',
      userInfo: apiUri.userInfo,
      host: apiUri.host,
      port: apiUri.hasPort ? apiUri.port : null,
      path: path,
    );

    try {
      _channel = WebSocketChannel.connect(
        uri,
        protocols: ['Bearer-$accessToken'],
      );

      await _channel!.ready;
      _connected = true;
      _connectionController.add(true);

      _channel!.stream.listen(_onMessage, onError: _onError, onDone: _onDone);
    } catch (e) {
      debugPrint('ChatWS connect error: $e');
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final event = ChatEvent.fromJson(json);
      _eventController.add(event);
    } catch (e) {
      debugPrint('ChatWS parse error: $e');
    }
  }

  void _onError(Object error) {
    debugPrint('ChatWS error: $error');
    _connected = false;
    _connectionController.add(false);
    _scheduleReconnect();
  }

  void _onDone() {
    _connected = false;
    _connectionController.add(false);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), connect);
  }

  void sendTyping(String conversationId) {
    _send({'type': 'typing', 'conversationId': conversationId});
  }

  void _send(Map<String, dynamic> data) {
    if (_channel != null && _connected) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _connected = false;
    _connectionController.add(false);
  }

  void dispose() {
    _disposed = true;
    disconnect();
    _eventController.close();
    _connectionController.close();
  }
}
