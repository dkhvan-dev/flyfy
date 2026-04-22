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
    final response =
        await _apiClient.dio.get('/chat/conversations/$conversationId');
    return ConversationDetail.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<ConversationDetail> getConversationByActivity(
      String activityId) async {
    final response = await _apiClient.dio
        .get('/chat/conversations/by-activity/$activityId');
    return ConversationDetail.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<String> createActivityConversation({
    required String activityId,
    required String title,
  }) async {
    final response = await _apiClient.dio.post(
      '/chat/conversations',
      data: {
        'type': 'activity',
        'activityId': activityId,
        'title': title,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return data['id'] as String;
  }

  Future<ConversationDetail> createDirectConversation(
      String participantUserId) async {
    final response = await _apiClient.dio.post(
      '/chat/conversations',
      data: {
        'type': 'direct',
        'participantUserIds': [participantUserId],
      },
    );
    return ConversationDetail.fromJson(
        response.data as Map<String, dynamic>);
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
    String? replyToMessageId,
  }) async {
    final response = await _apiClient.dio.post(
      '/chat/conversations/$conversationId/messages',
      data: {
        'content': content,
        'type': type,
        if (fileIds != null && fileIds.isNotEmpty) 'fileIds': fileIds,
        if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      },
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

  Future<void> deleteMessage(
      String conversationId, String messageId) async {
    await _apiClient.dio
        .delete('/chat/conversations/$conversationId/messages/$messageId');
  }

  Future<void> markRead(
      String conversationId, String lastReadMessageId) async {
    await _apiClient.dio.post(
      '/chat/conversations/$conversationId/read',
      data: {'lastReadMessageId': lastReadMessageId},
    );
  }
}
