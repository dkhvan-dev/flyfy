import '../../features/chat/models/conversation_vm.dart';
import '../../features/chat/models/message_vm.dart';
import 'api_client.dart';

class ChatApi {
  ChatApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  // ── Conversations ──────────────────────────────────────────────

  Future<List<ConversationVm>> listConversations({
    int limit = 20,
    String? type,
    String? cursor,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    if (type != null) params['type'] = type;
    if (cursor != null) params['cursor'] = cursor;

    final response = await _apiClient.dio.get(
      '/chat/conversations',
      queryParameters: params,
    );

    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>?) ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(ConversationVm.fromJson)
        .toList();
  }

  Future<ConversationDetail> getConversation(String conversationId) async {
    final response = await _apiClient.dio.get(
      '/chat/conversations/$conversationId',
    );
    return ConversationDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ConversationDetail> getConversationByActivity(
    String activityId,
  ) async {
    final response = await _apiClient.dio.get(
      '/chat/conversations/by-activity/$activityId',
    );
    return ConversationDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> createActivityConversation({
    required String activityId,
    required String title,
  }) async {
    final response = await _apiClient.dio.post(
      '/chat/conversations',
      data: {'type': 'activity', 'activityId': activityId, 'title': title},
    );
    final data = response.data as Map<String, dynamic>;
    return data['id'] as String;
  }

  Future<String> createDirectConversation(String participantUserId) async {
    final response = await _apiClient.dio.post(
      '/chat/conversations',
      data: {
        'type': 'direct',
        'participantUserIds': [participantUserId],
      },
    );
    final data = response.data as Map<String, dynamic>;
    return data['id'] as String;
  }

  // ── Messages ───────────────────────────────────────────────────

  Future<List<MessageVm>> listMessages(
    String conversationId, {
    int limit = 30,
    String? cursor,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    if (cursor != null) params['cursor'] = cursor;

    final response = await _apiClient.dio.get(
      '/chat/conversations/$conversationId/messages',
      queryParameters: params,
    );

    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>?) ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(MessageVm.fromJson)
        .toList();
  }

  Future<MessageVm> sendMessage(
    String conversationId, {
    required String content,
    String type = 'text',
    List<String>? fileIds,
    String? stickerId,
    String? replyToMessageId,
  }) async {
    final response = await _apiClient.dio.post(
      '/chat/conversations/$conversationId/messages',
      data: {
        'content': content,
        'type': type,
        if (fileIds != null && fileIds.isNotEmpty) 'fileIds': fileIds,
        if ((stickerId ?? '').trim().isNotEmpty) 'stickerId': stickerId!.trim(),
        'replyToMessageId': ?replyToMessageId,
      },
    );
    return MessageVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MessageVm> forwardMessage({
    required String sourceConversationId,
    required String messageId,
    required String targetConversationId,
  }) async {
    final response = await _apiClient.dio.post(
      '/chat/conversations/$sourceConversationId/messages/$messageId/forward',
      data: {'targetConversationId': targetConversationId},
    );
    return MessageVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> editMessage(
    String conversationId,
    String messageId, {
    required String content,
  }) async {
    await _apiClient.dio.patch(
      '/chat/conversations/$conversationId/messages/$messageId',
      data: {'content': content},
    );
  }

  Future<DeleteMessageResultVm> deleteMessage(
    String conversationId,
    String messageId,
  ) async {
    final response = await _apiClient.dio.delete(
      '/chat/conversations/$conversationId/messages/$messageId',
    );
    return DeleteMessageResultVm.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<List<MessageReactionVm>> toggleMessageReaction(
    String conversationId,
    String messageId,
    String emoji,
  ) async {
    final response = await _apiClient.dio.post(
      '/chat/conversations/$conversationId/messages/$messageId/reaction',
      data: {'emoji': emoji},
    );
    final data = response.data as Map<String, dynamic>;
    return _parseMessageReactions(data);
  }

  Future<void> markRead(String conversationId, String lastReadMessageId) async {
    await _apiClient.dio.post(
      '/chat/conversations/$conversationId/read',
      data: {'lastReadMessageId': lastReadMessageId},
    );
  }

  Future<List<PinnedMessageInfo>> pinMessage(
    String conversationId,
    String messageId,
  ) async {
    final response = await _apiClient.dio.post(
      '/chat/conversations/$conversationId/pin',
      data: {'messageId': messageId},
    );
    return _parsePinnedMessages(response.data as Map<String, dynamic>);
  }

  Future<List<PinnedMessageInfo>> unpinMessage(
    String conversationId,
    String messageId,
  ) async {
    final response = await _apiClient.dio.delete(
      '/chat/conversations/$conversationId/pin/$messageId',
    );
    return _parsePinnedMessages(response.data as Map<String, dynamic>);
  }

  List<PinnedMessageInfo> _parsePinnedMessages(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>?) ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(PinnedMessageInfo.fromJson)
        .toList(growable: false);
  }

  List<MessageReactionVm> _parseMessageReactions(Map<String, dynamic> json) {
    final items = (json['reactions'] as List<dynamic>?) ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(MessageReactionVm.fromJson)
        .where((reaction) => reaction.emoji.trim().isNotEmpty)
        .toList(growable: false);
  }
}

class DeleteMessageResultVm {
  const DeleteMessageResultVm({required this.hardDeleted, this.deletedAt});

  final bool hardDeleted;
  final DateTime? deletedAt;

  factory DeleteMessageResultVm.fromJson(Map<String, dynamic> json) {
    return DeleteMessageResultVm(
      hardDeleted: json['hardDeleted'] == true,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.tryParse(json['deletedAt'].toString()),
    );
  }
}
