import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/chat_api.dart';
import 'package:inflap/features/chat/models/conversation_vm.dart';
import 'package:inflap/features/chat/models/message_vm.dart';
import 'package:inflap/providers/chat_provider.dart';

void main() {
  test('loadConversations coalesces concurrent refreshes', () async {
    final api = _PerformanceChatApi();
    final provider = ChatProvider(chatApi: api);
    final completer = Completer<List<ConversationVm>>();
    api.listConversationsHandler = () => completer.future;

    final first = provider.loadConversations();
    final second = provider.loadConversations();

    expect(api.listConversationsCalls, 1);

    completer.complete([_conversation('conversation1')]);
    await Future.wait([first, second]);

    expect(provider.conversations.single.id, 'conversation1');
    expect(provider.conversationsLoading, isFalse);
  });

  test('loadConversations uses fresh cache unless refresh is forced', () async {
    final api = _PerformanceChatApi()
      ..listConversationsHandler = () async => [_conversation('conversation1')];
    final provider = ChatProvider(chatApi: api);

    await provider.loadConversations();
    await provider.loadConversations();

    expect(api.listConversationsCalls, 1);

    await provider.loadConversations(forceRefresh: true);

    expect(api.listConversationsCalls, 2);
  });

  test(
    'openConversation keeps cached messages visible while revalidating',
    () async {
      final api = _PerformanceChatApi();
      api.conversationHandler = (_) async => _detail('conversation1');
      api.listMessagesHandler = (_) async => [_message('message1')];
      final provider = ChatProvider(chatApi: api);

      await provider.openConversation('conversation1');
      expect(provider.messages.single.id, 'message1');

      final secondListCompleter = Completer<List<MessageVm>>();
      api.listMessagesHandler = (_) => secondListCompleter.future;

      final reopen = provider.openConversation('conversation1');
      await Future<void>.delayed(Duration.zero);

      expect(provider.activeConversation?.id, 'conversation1');
      expect(provider.messages.single.id, 'message1');
      expect(provider.messagesLoading, isFalse);

      secondListCompleter.complete([
        _message('message2'),
        _message('message1'),
      ]);
      await reopen;

      expect(provider.messages.map((message) => message.id), [
        'message2',
        'message1',
      ]);
    },
  );

  test(
    'openConversationByActivity ignores stale response after newer chat opens',
    () async {
      final api = _PerformanceChatApi();
      final activityDetailCompleter = Completer<ConversationDetail>();
      final activityMessagesCompleter = Completer<List<MessageVm>>();

      api.activityConversationHandler = (_) => activityDetailCompleter.future;
      api.conversationHandler = (conversationId) async =>
          _detail(conversationId);
      api.listMessagesHandler = (conversationId) {
        if (conversationId == 'activityConversation') {
          return activityMessagesCompleter.future;
        }
        return Future.value([_message('newerMessage')]);
      };

      final provider = ChatProvider(chatApi: api);

      final staleOpen = provider.openConversationByActivity('activity1');
      await Future<void>.delayed(Duration.zero);

      await provider.openConversation('conversation2');

      activityDetailCompleter.complete(_detail('activityConversation'));
      await Future<void>.delayed(Duration.zero);
      activityMessagesCompleter.complete([_message('staleMessage')]);
      await staleOpen;

      expect(provider.activeConversation?.id, 'conversation2');
      expect(provider.messages.map((message) => message.id), ['newerMessage']);
    },
  );
}

class _PerformanceChatApi extends ChatApi {
  Future<List<ConversationVm>> Function()? listConversationsHandler;
  Future<ConversationDetail> Function(String conversationId)?
  conversationHandler;
  Future<ConversationDetail> Function(String activityId)?
  activityConversationHandler;
  Future<List<MessageVm>> Function(String conversationId)? listMessagesHandler;

  int listConversationsCalls = 0;
  int getConversationCalls = 0;
  int getConversationByActivityCalls = 0;
  int listMessagesCalls = 0;

  @override
  Future<List<ConversationVm>> listConversations({
    int limit = 20,
    String? type,
    String? cursor,
  }) {
    listConversationsCalls++;
    return listConversationsHandler?.call() ?? Future.value(const []);
  }

  @override
  Future<ConversationDetail> getConversation(String conversationId) {
    getConversationCalls++;
    return conversationHandler?.call(conversationId) ??
        Future.value(_detail(conversationId));
  }

  @override
  Future<ConversationDetail> getConversationByActivity(String activityId) {
    getConversationByActivityCalls++;
    return activityConversationHandler?.call(activityId) ??
        Future.value(_detail(activityId));
  }

  @override
  Future<List<MessageVm>> listMessages(
    String conversationId, {
    int limit = 30,
    String? cursor,
  }) {
    listMessagesCalls++;
    return listMessagesHandler?.call(conversationId) ??
        Future.value(const <MessageVm>[]);
  }
}

ConversationVm _conversation(String id) {
  return ConversationVm(
    id: id,
    type: 'direct',
    lastActivityAt: DateTime.utc(2026, 6, 1),
  );
}

ConversationDetail _detail(String id) {
  return ConversationDetail(
    id: id,
    type: 'direct',
    createdAt: DateTime.utc(2026, 6, 1),
    lastActivityAt: DateTime.utc(2026, 6, 1),
  );
}

MessageVm _message(String id) {
  final minute = id.endsWith('2') ? 2 : 1;
  return MessageVm(
    id: id,
    senderUserId: 'user1',
    senderDisplayName: 'User',
    type: 'text',
    content: id,
    sentAt: DateTime.utc(2026, 6, 1, 12, minute),
  );
}
