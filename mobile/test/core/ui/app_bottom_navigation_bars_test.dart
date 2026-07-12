import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/chat_api.dart';
import 'package:inflap/core/network/chat_ws_service.dart';
import 'package:inflap/core/ui/app_bottom_navigation_bars.dart';
import 'package:inflap/features/chat/models/conversation_vm.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/providers/chat_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('chat nav badge counts unread conversations, not messages', (
    tester,
  ) async {
    final chatProvider = ChatProvider(
      chatApi: _FakeChatApi(
        conversations: [
          _conversation('chat-1', unreadCount: 7),
          _conversation('chat-2', unreadCount: 3),
          _conversation('chat-3', unreadCount: 0),
        ],
      ),
      wsService: _FakeChatWsService(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<ChatProvider>.value(
        value: chatProvider,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            bottomNavigationBar: CommonBottomNavigationBar(
              onHomeTap: () {},
              onQrTap: () {},
              onMapTap: () {},
              onServicesTap: () {},
              onChatsTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('bottom-nav-chats-badge')),
      findsOneWidget,
    );
    expect(find.text('2'), findsOneWidget);
    expect(find.text('10'), findsNothing);
  });

  testWidgets('create action bar omits the plus when creation is unavailable', (
    tester,
  ) async {
    final chatProvider = ChatProvider(
      chatApi: _FakeChatApi(conversations: const []),
      wsService: _FakeChatWsService(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<ChatProvider>.value(
        value: chatProvider,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            bottomNavigationBar: CreateActionBottomNavigationBar(
              onHomeTap: () {},
              onQrTap: () {},
              onServicesTap: () {},
              onChatsTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('bottom-nav-create-action')),
      findsNothing,
    );
    expect(find.byIcon(Icons.add_rounded), findsNothing);
  });
}

ConversationVm _conversation(String id, {required int unreadCount}) {
  return ConversationVm(
    id: id,
    type: 'direct',
    unreadCount: unreadCount,
    lastActivityAt: DateTime.utc(2026, 6, 27),
  );
}

class _FakeChatApi extends ChatApi {
  _FakeChatApi({required this.conversations});

  final List<ConversationVm> conversations;

  @override
  Future<List<ConversationVm>> listConversations({
    int limit = 20,
    String? type,
    String? cursor,
  }) async {
    return conversations;
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
