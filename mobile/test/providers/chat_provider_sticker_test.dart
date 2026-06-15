import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/chat_api.dart';
import 'package:inflap/core/network/chat_ws_service.dart';
import 'package:inflap/features/chat/models/conversation_vm.dart';
import 'package:inflap/features/chat/models/message_vm.dart';
import 'package:inflap/features/chat/models/sticker_pack_vm.dart';
import 'package:inflap/providers/chat_provider.dart';

void main() {
  test('sendSticker delegates to sticker message flow', () async {
    final api = _FakeChatApi();
    final provider = ChatProvider(chatApi: api);
    await provider.openConversation('conversation1');

    final sent = await provider.sendSticker(
      sticker: const StickerVm(
        id: 'sticker1',
        packId: 'pack1',
        fileId: 'file1',
        fallbackFileId: 'file1',
        status: 'active',
      ),
    );

    expect(sent, isTrue);
    expect(api.sentConversationId, 'conversation1');
    expect(api.sentType, 'sticker');
    expect(api.sentStickerId, 'sticker1');
    expect(api.sentClientMessageId, isNotNull);
    expect(api.sentClientMessageId, matches(RegExp(r'^[0-9a-fA-F-]{36}$')));
    expect(provider.messages.single.stickerId, 'sticker1');
  });

  test(
    'message websocket event updates conversation preview without reload storm',
    () async {
      final api = _FakeChatApi(
        conversations: [
          ConversationVm(
            id: 'conversation1',
            type: 'direct',
            lastActivityAt: DateTime.utc(2026, 5, 10),
          ),
        ],
      );
      final ws = _FakeChatWsService();
      final provider = ChatProvider(chatApi: api, wsService: ws);

      await provider.loadConversations();
      provider.connectWebSocket();
      ws.addEvent(
        ChatEvent(
          eventId: 'event1',
          type: 'message_sent',
          conversationId: 'conversation1',
          payload: {
            'id': 'message2',
            'senderUserId': 'user2',
            'senderDisplayName': 'User 2',
            'type': 'text',
            'content': 'hello through ws',
            'sentAt': DateTime.utc(2026, 5, 10, 12).toIso8601String(),
          },
          timestamp: DateTime.utc(2026, 5, 10, 12),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(api.listConversationsCalls, 1);
      expect(provider.conversations.single.lastMessage?.id, 'message2');
      expect(
        provider.conversations.single.lastMessage?.contentPreview,
        'hello through ws',
      );
    },
  );
}

class _FakeChatApi extends ChatApi {
  _FakeChatApi({List<ConversationVm>? conversations})
    : _conversations = conversations ?? const [];

  final List<ConversationVm> _conversations;
  String? sentConversationId;
  String? sentType;
  String? sentStickerId;
  String? sentClientMessageId;
  int listConversationsCalls = 0;

  @override
  Future<List<ConversationVm>> listConversations({
    int limit = 20,
    String? type,
    String? cursor,
  }) async {
    listConversationsCalls++;
    return _conversations;
  }

  @override
  Future<ConversationDetail> getConversation(String conversationId) async {
    return ConversationDetail(
      id: conversationId,
      type: 'direct',
      createdAt: DateTime.utc(2026, 5, 10),
      lastActivityAt: DateTime.utc(2026, 5, 10),
    );
  }

  @override
  Future<List<MessageVm>> listMessages(
    String conversationId, {
    int limit = 30,
    String? cursor,
  }) async {
    return const [];
  }

  @override
  Future<MessageVm> sendMessage(
    String conversationId, {
    required String content,
    String type = 'text',
    List<String>? fileIds,
    String? stickerId,
    String? replyToMessageId,
    String? clientMessageId,
    StoryReplyContextVm? storyReply,
  }) async {
    sentConversationId = conversationId;
    sentType = type;
    sentStickerId = stickerId;
    sentClientMessageId = clientMessageId;

    return MessageVm(
      id: 'message1',
      senderUserId: 'user1',
      senderDisplayName: 'User',
      type: type,
      content: content,
      stickerId: stickerId,
      stickerFileId: 'file1',
      sentAt: DateTime.utc(2026, 5, 10),
    );
  }
}

class _FakeChatWsService extends ChatWsService {
  final _controller = StreamController<ChatEvent>.broadcast();
  bool connected = false;

  @override
  Stream<ChatEvent> get events => _controller.stream;

  @override
  bool get isConnected => connected;

  @override
  Future<void> connect() async {
    connected = true;
  }

  @override
  void disconnect() {
    connected = false;
  }

  @override
  void dispose() {
    connected = false;
    _controller.close();
  }

  void addEvent(ChatEvent event) {
    _controller.add(event);
  }
}
