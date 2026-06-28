import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/chat_ws_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  group('ChatWsService.webSocketUriForApiBaseUrl', () {
    test('builds production wss endpoint without synthetic port', () {
      final uri = ChatWsService.webSocketUriForApiBaseUrl(
        'https://api-dev.inflap.app/api/v1',
      );

      expect(uri.toString(), 'wss://api-dev.inflap.app/api/v1/chat/ws');
      expect(uri.hasPort, isFalse);
    });

    test('drops invalid zero port from configured production endpoint', () {
      final uri = ChatWsService.webSocketUriForApiBaseUrl(
        'https://api-dev.inflap.app:0/api/v1',
      );

      expect(uri.toString(), 'wss://api-dev.inflap.app/api/v1/chat/ws');
      expect(uri.hasPort, isFalse);
    });

    test('keeps explicit non-default local development port', () {
      final uri = ChatWsService.webSocketUriForApiBaseUrl(
        'http://127.0.0.1:8080/api/v1',
      );

      expect(uri.toString(), 'ws://127.0.0.1:8080/api/v1/chat/ws');
      expect(uri.hasPort, isTrue);
    });
  });

  test('connect authenticates websocket with Authorization header', () async {
    Uri? connectedUri;
    Map<String, dynamic>? connectedHeaders;
    final channel = _FakeWebSocketChannel();
    final service = ChatWsService(
      accessTokenReader: () async => 'access-token',
      apiBaseUrlReader: () => 'https://api-dev.inflap.app/api/v1',
      connector: (uri, {headers}) {
        connectedUri = uri;
        connectedHeaders = headers;
        return channel;
      },
    );
    addTearDown(service.dispose);

    await service.connect();

    expect(connectedUri.toString(), 'wss://api-dev.inflap.app/api/v1/chat/ws');
    expect(
      connectedHeaders,
      containsPair('Authorization', 'Bearer access-token'),
    );
    expect(service.isConnected, isTrue);
  });
}

class _FakeWebSocketChannel implements WebSocketChannel {
  final StreamController<dynamic> _controller =
      StreamController<dynamic>.broadcast();
  final _FakeWebSocketSink _sink = _FakeWebSocketSink();

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  String? get protocol => null;

  @override
  Future<void> get ready => Future<void>.value();

  @override
  WebSocketSink get sink => _sink;

  @override
  Stream<dynamic> get stream => _controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWebSocketSink implements WebSocketSink {
  @override
  Future<void> get done => Future<void>.value();

  @override
  void add(dynamic data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) async {
    await stream.drain<void>();
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {}
}
