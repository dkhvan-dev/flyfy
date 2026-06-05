import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inflap/core/network/chat_api.dart';
import 'package:inflap/core/network/chat_ws_service.dart';
import 'package:inflap/features/chat/models/conversation_vm.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/providers/chat_provider.dart';
import 'package:inflap/providers/session_provider.dart';
import 'package:inflap/screens/chat/conversations_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('conversation list back button falls back to home route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/chats',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Home route')),
        ),
        GoRoute(path: '/chats', builder: (_, _) => const ConversationsScreen()),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => ChatProvider(
              chatApi: _FakeChatApi(),
              wsService: _FakeChatWsService(),
            ),
          ),
          ChangeNotifierProvider(create: (_) => SessionProvider()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Home route'), findsOneWidget);
  });
}

class _FakeChatApi extends ChatApi {
  @override
  Future<List<ConversationVm>> listConversations({
    int limit = 20,
    String? type,
    String? cursor,
  }) async {
    return const [];
  }
}

class _FakeChatWsService extends ChatWsService {
  final _controller = StreamController<ChatEvent>.broadcast();

  @override
  Stream<ChatEvent> get events => _controller.stream;

  @override
  bool get isConnected => false;

  @override
  Future<void> connect() async {}

  @override
  void disconnect() {}

  @override
  void dispose() {
    _controller.close();
  }
}
