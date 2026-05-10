import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/core/network/chat_api.dart';
import 'package:superapp/features/chat/models/conversation_vm.dart';
import 'package:superapp/features/chat/models/message_vm.dart';
import 'package:superapp/features/chat/models/sticker_pack_vm.dart';
import 'package:superapp/providers/chat_provider.dart';

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
    expect(provider.messages.single.stickerId, 'sticker1');
  });
}

class _FakeChatApi extends ChatApi {
  String? sentConversationId;
  String? sentType;
  String? sentStickerId;

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
  }) async {
    sentConversationId = conversationId;
    sentType = type;
    sentStickerId = stickerId;

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
