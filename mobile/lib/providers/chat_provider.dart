import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/network/chat_api.dart';
import '../core/network/chat_ws_service.dart';
import '../features/chat/models/conversation_vm.dart';
import '../features/chat/models/message_vm.dart';
import '../features/chat/models/sticker_pack_vm.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider({ChatApi? chatApi, ChatWsService? wsService})
      : _chatApi = chatApi ?? ChatApi(),
        _wsService = wsService ?? ChatWsService();

  final ChatApi _chatApi;
  final ChatWsService _wsService;

  // ── Conversation list state ────────────────────────────────────
  List<ConversationVm> _conversations = [];
  bool _conversationsLoading = false;
  String? _conversationsError;

  List<ConversationVm> get conversations => _conversations;
  bool get conversationsLoading => _conversationsLoading;
  String? get conversationsError => _conversationsError;

  // ── Active chat state ──────────────────────────────────────────
  ConversationDetail? _activeConversation;
  List<MessageVm> _messages = [];
  bool _messagesLoading = false;
  String? _messagesError;
  bool _sendingMessage = false;
  bool _loadingMoreMessages = false;
  bool _hasMoreMessages = true;
  final Map<String, String> _lastMarkedReadMessageIds = {};

  ConversationDetail? get activeConversation => _activeConversation;
  List<MessageVm> get messages => _messages;
  bool get messagesLoading => _messagesLoading;
  String? get messagesError => _messagesError;
  bool get sendingMessage => _sendingMessage;
  bool get hasMoreMessages => _hasMoreMessages;
  bool get loadingMoreMessages => _loadingMoreMessages;

  // ── WebSocket ──────────────────────────────────────────────────
  StreamSubscription<ChatEvent>? _eventSubscription;
  bool get wsConnected => _wsService.isConnected;

  void connectWebSocket() {
    _eventSubscription?.cancel();
    _eventSubscription = _wsService.events.listen(_handleEvent);
    _wsService.connect();
  }

  void disconnectWebSocket() {
    _eventSubscription?.cancel();
    _wsService.disconnect();
  }

  // ── Conversations ──────────────────────────────────────────────

  Future<void> loadConversations() async {
    _conversationsLoading = true;
    _conversationsError = null;
    notifyListeners();

    try {
      _conversations = await _chatApi.listConversations();
      _conversationsError = null;
    } catch (e) {
      _conversationsError = e.toString();
    } finally {
      _conversationsLoading = false;
      notifyListeners();
    }
  }

  // ── Active chat ────────────────────────────────────────────────

  Future<void> openConversation(String conversationId) async {
    _messagesLoading = true;
    _messagesError = null;
    _messages = [];
    _hasMoreMessages = true;
    _activeConversation = null;
    notifyListeners();

    try {
      _activeConversation = await _chatApi.getConversation(conversationId);
      _messages = _uniqueMessages(await _chatApi.listMessages(conversationId));
      _hasMoreMessages = _messages.length >= 30;
      _lastMarkedReadMessageIds.remove(conversationId);
      _messagesError = null;
    } catch (e) {
      _messagesError = e.toString();
    } finally {
      _messagesLoading = false;
      notifyListeners();
    }
  }

  Future<void> openConversationByActivity(String activityId) async {
    _messagesLoading = true;
    _messagesError = null;
    _messages = [];
    _hasMoreMessages = true;
    _activeConversation = null;
    notifyListeners();

    try {
      _activeConversation = await _chatApi.getConversationByActivity(
        activityId,
      );
      _messages = _uniqueMessages(
        await _chatApi.listMessages(_activeConversation!.id),
      );
      _hasMoreMessages = _messages.length >= 30;
      _lastMarkedReadMessageIds.remove(_activeConversation!.id);
      _messagesError = null;
    } catch (e) {
      _messagesError = e.toString();
    } finally {
      _messagesLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreMessages() async {
    if (_activeConversation == null ||
        _messages.isEmpty ||
        _loadingMoreMessages ||
        !_hasMoreMessages) {
      return;
    }

    _loadingMoreMessages = true;
    final cursor = _messages.last.id;
    try {
      final older = await _chatApi.listMessages(
        _activeConversation!.id,
        cursor: cursor,
      );
      if (older.isNotEmpty) {
        _messages = _uniqueMessages([..._messages, ...older]);
        notifyListeners();
      }
      _hasMoreMessages = older.length >= 30;
    } catch (e) {
      debugPrint('loadMoreMessages error: $e');
    } finally {
      _loadingMoreMessages = false;
    }
  }

  Future<bool> sendMessage(
    String content, {
    String type = 'text',
    List<String>? fileIds,
    String? stickerId,
    String? replyToMessageId,
  }) async {
    final normalizedFileIds = fileIds
            ?.map((id) => id.trim())
            .where((id) => id.isNotEmpty)
            .toList(growable: false) ??
        const <String>[];
    final normalizedType = type.trim().isEmpty ? 'text' : type.trim();
    final normalizedStickerId = stickerId?.trim() ?? '';
    final effectiveType = normalizedFileIds.isEmpty
        ? normalizedStickerId.isNotEmpty
            ? 'sticker'
            : normalizedType
        : normalizedType == 'text'
            ? 'file'
            : normalizedType;
    if (_activeConversation == null ||
        (content.trim().isEmpty &&
            normalizedFileIds.isEmpty &&
            normalizedStickerId.isEmpty)) {
      return false;
    }
    if (!_activeConversation!.canSendNow) {
      return false;
    }

    _sendingMessage = true;
    notifyListeners();

    try {
      final msg = await _chatApi.sendMessage(
        _activeConversation!.id,
        content: content.trim(),
        type: effectiveType,
        fileIds: normalizedFileIds,
        stickerId: normalizedStickerId.isEmpty ? null : normalizedStickerId,
        replyToMessageId: replyToMessageId,
      );
      _messages = _uniqueMessages([msg, ..._messages]);
      return true;
    } catch (e) {
      debugPrint('sendMessage error: $e');
      return false;
    } finally {
      _sendingMessage = false;
      notifyListeners();
    }
  }

  Future<bool> sendSticker({
    required StickerVm sticker,
    String? replyToMessageId,
  }) {
    return sendMessage(
      '',
      type: 'sticker',
      stickerId: sticker.id,
      replyToMessageId: replyToMessageId,
    );
  }

  Future<bool> forwardMessageToConversation({
    required MessageVm message,
    required String targetConversationId,
  }) async {
    final sourceConversation = _activeConversation;
    final normalizedTargetId = targetConversationId.trim();
    if (sourceConversation == null || normalizedTargetId.isEmpty) {
      return false;
    }

    try {
      final forwarded = await _chatApi.forwardMessage(
        sourceConversationId: sourceConversation.id,
        messageId: message.id,
        targetConversationId: normalizedTargetId,
      );
      if (normalizedTargetId == sourceConversation.id) {
        _messages = _uniqueMessages([forwarded, ..._messages]);
      }
      _messages = _messages
          .map(
            (item) => item.id == message.id
                ? item.copyWith(forwardCount: item.forwardCount + 1)
                : item,
          )
          .toList(growable: false);
      notifyListeners();
      unawaited(loadConversations());
      return true;
    } catch (e) {
      debugPrint('forwardMessageToConversation error: $e');
      return false;
    }
  }

  Future<DeleteMessageResultVm> deleteMessage(String messageId) async {
    if (_activeConversation == null) {
      throw StateError('No active conversation');
    }

    final result = await _chatApi.deleteMessage(
      _activeConversation!.id,
      messageId,
    );
    if (result.hardDeleted) {
      _messages =
          _messages.where((message) => message.id != messageId).toList();
    } else {
      final deletedAt = result.deletedAt ?? DateTime.now().toUtc();
      _messages = _messages
          .map(
            (message) => message.id == messageId
                ? message.copyWith(deletedAt: deletedAt)
                : message,
          )
          .toList();
    }
    _activeConversation = _activeConversation?.copyWith(
      pinnedMessages: _activeConversation!.pinnedMessages
          .where((pin) => pin.id != messageId)
          .toList(growable: false),
    );
    notifyListeners();
    unawaited(loadConversations());
    return result;
  }

  Future<void> toggleMessageReaction(String messageId, String emoji) async {
    if (_activeConversation == null) {
      throw StateError('No active conversation');
    }

    final reactions = await _chatApi.toggleMessageReaction(
      _activeConversation!.id,
      messageId,
      emoji,
    );
    _updateMessageReactions(messageId, reactions);
    notifyListeners();
  }

  Future<void> pinMessage(String messageId) async {
    if (_activeConversation == null) {
      throw StateError('No active conversation');
    }

    final pinnedMessages = await _chatApi.pinMessage(
      _activeConversation!.id,
      messageId,
    );
    _activeConversation = _activeConversation!.copyWith(
      pinnedMessages: pinnedMessages,
    );
    notifyListeners();
  }

  Future<void> unpinMessage(String messageId) async {
    if (_activeConversation == null) {
      throw StateError('No active conversation');
    }

    final pinnedMessages = await _chatApi.unpinMessage(
      _activeConversation!.id,
      messageId,
    );
    _activeConversation = _activeConversation!.copyWith(
      pinnedMessages: pinnedMessages,
    );
    notifyListeners();
  }

  Future<void> markAsRead() async {
    if (_activeConversation == null || _messages.isEmpty) return;

    final conversationId = _activeConversation!.id;
    final latestMessageId = _messages.first.id;
    if (_lastMarkedReadMessageIds[conversationId] == latestMessageId) {
      return;
    }

    _lastMarkedReadMessageIds[conversationId] = latestMessageId;
    _activeConversation = _activeConversation!.copyWith(unreadCount: 0);
    _conversations = _conversations
        .map((c) => c.id == conversationId ? c.copyWith(unreadCount: 0) : c)
        .toList();
    notifyListeners();

    try {
      await _chatApi.markRead(conversationId, latestMessageId);
    } catch (e) {
      _lastMarkedReadMessageIds.remove(conversationId);
      debugPrint('markAsRead error: $e');
    }
  }

  void sendTyping() {
    if (_activeConversation == null) return;
    _wsService.sendTyping(_activeConversation!.id);
  }

  void closeConversation() {
    _activeConversation = null;
    _messages = [];
    _messagesError = null;
  }

  // ── WebSocket events ───────────────────────────────────────────

  void _handleEvent(ChatEvent event) {
    switch (event.type) {
      case 'message_sent':
        _onMessageSent(event);
      case 'message_edited':
        _onMessageEdited(event);
      case 'message_deleted':
        _onMessageDeleted(event);
      case 'message_reaction_updated':
        _onMessageReactionUpdated(event);
      case 'read_updated':
        _onReadUpdated(event);
      case 'message_forwarded':
        _onMessageForwarded(event);
      case 'message_pinned':
        _onMessagePinned(event);
      default:
        break;
    }
    notifyListeners();
  }

  void _onMessageSent(ChatEvent event) {
    final msg = MessageVm.fromJson(event.payload);

    if (_activeConversation?.id == event.conversationId) {
      final exists = _messages.any((m) => m.id == msg.id);
      _messages = exists
          ? _uniqueMessages(
              _messages
                  .map((message) => message.id == msg.id ? msg : message)
                  .toList(),
            )
          : _uniqueMessages([msg, ..._messages]);
    }

    // Update conversation list preview
    final idx = _conversations.indexWhere((c) => c.id == event.conversationId);
    if (idx >= 0) {
      loadConversations();
    }
  }

  void _onMessageEdited(ChatEvent event) {
    final messageId = event.payload['messageId'] as String;
    final newContent = event.payload['content'] as String;

    _messages = _messages.map((m) {
      if (m.id == messageId) {
        return m.copyWith(
          content: newContent,
          editedAt: DateTime.tryParse(
            event.payload['editedAt'] as String? ?? '',
          ),
        );
      }
      return m;
    }).toList();
  }

  void _onMessageDeleted(ChatEvent event) {
    final messageId = event.payload['messageId'] as String;
    final hardDeleted = event.payload['hardDeleted'] == true;

    if (hardDeleted) {
      _messages = _messages.where((m) => m.id != messageId).toList();
    } else {
      final deletedAt = DateTime.tryParse(
        event.payload['deletedAt'] as String? ?? '',
      );
      final moderationStatus = event.payload['moderationStatus']?.toString();
      final moderationPublicComment =
          event.payload['moderationPublicComment']?.toString();
      _messages = _messages
          .map(
            (message) => message.id == messageId
                ? message.copyWith(
                    deletedAt: deletedAt ?? DateTime.now().toUtc(),
                    moderationStatus: moderationStatus,
                    moderationPublicComment: moderationPublicComment,
                  )
                : message,
          )
          .toList();
    }

    if (_activeConversation?.id == event.conversationId) {
      _activeConversation = _activeConversation!.copyWith(
        pinnedMessages: _activeConversation!.pinnedMessages
            .where((pin) => pin.id != messageId)
            .toList(growable: false),
      );
    }

    unawaited(loadConversations());
  }

  void _onMessageReactionUpdated(ChatEvent event) {
    final messageId = event.payload['messageId'] as String?;
    if (messageId == null || messageId.trim().isEmpty) {
      return;
    }

    final existingReactions = _messages
        .where((message) => message.id == messageId)
        .firstOrNull
        ?.reactions;
    final reactedByMeByEmoji = <String, bool>{
      for (final reaction in existingReactions ?? const <MessageReactionVm>[])
        reaction.emoji: reaction.reactedByMe,
    };

    final items = (event.payload['reactions'] as List<dynamic>?) ?? const [];
    final reactions = items
        .whereType<Map<String, dynamic>>()
        .map(MessageReactionVm.fromJson)
        .where((reaction) => reaction.emoji.trim().isNotEmpty)
        .map(
          (reaction) => reaction.copyWith(
            reactedByMe: reactedByMeByEmoji[reaction.emoji] ?? false,
          ),
        )
        .toList(growable: false);

    _updateMessageReactions(messageId, reactions);
  }

  void _onReadUpdated(ChatEvent event) {
    final userId = event.payload['userId'] as String?;
    final lastReadMessageId = (event.payload['lastReadMsgId'] ??
        event.payload['lastReadMessageId']) as String?;
    final readAt =
        DateTime.tryParse(event.payload['readAt']?.toString() ?? '') ??
            DateTime.now().toUtc();
    if (userId == null || lastReadMessageId == null) {
      return;
    }

    if (_activeConversation?.id == event.conversationId) {
      _activeConversation = _activeConversation!.copyWith(
        participants: _activeConversation!.participants
            .map(
              (p) => p.userId == userId
                  ? p.copyWith(lastReadMessageId: lastReadMessageId)
                  : p,
            )
            .toList(),
      );
    }

    _conversations = _conversations
        .map(
          (c) => c.id == event.conversationId
              ? c.copyWith(
                  participants: c.participants
                      .map(
                        (p) => p.userId == userId
                            ? p.copyWith(lastReadMessageId: lastReadMessageId)
                            : p,
                      )
                      .toList(),
                )
              : c,
        )
        .toList();

    _updateMessageReadReceipts(
      readerUserId: userId,
      lastReadMessageId: lastReadMessageId,
      readAt: readAt,
    );
  }

  void _updateMessageReadReceipts({
    required String readerUserId,
    required String lastReadMessageId,
    required DateTime readAt,
  }) {
    if (_activeConversation == null || _messages.isEmpty) return;

    final readIndex = _messages.indexWhere(
      (message) => message.id == lastReadMessageId,
    );
    if (readIndex < 0) return;

    _messages = [
      for (var index = 0; index < _messages.length; index++)
        _messageWithReadReceipt(
          message: _messages[index],
          readerUserId: readerUserId,
          readAt: readAt,
          shouldAdd: readIndex <= index &&
              _messages[index].senderUserId != readerUserId,
        ),
    ];
  }

  MessageVm _messageWithReadReceipt({
    required MessageVm message,
    required String readerUserId,
    required DateTime readAt,
    required bool shouldAdd,
  }) {
    if (!shouldAdd ||
        message.isSystem ||
        message.readReceipts.any((receipt) => receipt.userId == readerUserId)) {
      return message;
    }

    final receipts = [
      MessageReadReceiptVm(userId: readerUserId, readAt: readAt),
      ...message.readReceipts,
    ]..sort((a, b) => b.readAt.compareTo(a.readAt));

    return message.copyWith(readReceipts: receipts);
  }

  void _onMessageForwarded(ChatEvent event) {
    final messageId = event.payload['messageId'] as String?;
    final forwardCount = (event.payload['forwardCount'] as num?)?.toInt();
    if (messageId == null || messageId.trim().isEmpty || forwardCount == null) {
      return;
    }

    _messages = _messages
        .map(
          (message) => message.id == messageId
              ? message.copyWith(forwardCount: forwardCount)
              : message,
        )
        .toList(growable: false);
  }

  void _onMessagePinned(ChatEvent event) {
    if (_activeConversation?.id != event.conversationId) {
      return;
    }

    final items =
        (event.payload['pinnedMessages'] as List<dynamic>?) ?? const [];
    final pinnedMessages = items
        .whereType<Map<String, dynamic>>()
        .map(PinnedMessageInfo.fromJson)
        .toList(growable: false);

    _activeConversation = _activeConversation!.copyWith(
      pinnedMessages: pinnedMessages,
    );
  }

  void _updateMessageReactions(
    String messageId,
    List<MessageReactionVm> reactions,
  ) {
    _messages = _messages
        .map(
          (message) => message.id == messageId
              ? message.copyWith(reactions: reactions)
              : message,
        )
        .toList();
  }

  List<MessageVm> _uniqueMessages(List<MessageVm> items) {
    final seen = <String>{};
    final result = <MessageVm>[];
    for (final item in items) {
      if (seen.add(item.id)) {
        result.add(item);
      }
    }
    result.sort((a, b) {
      final bySentAt = b.sentAt.compareTo(a.sentAt);
      if (bySentAt != 0) return bySentAt;
      return b.id.compareTo(a.id);
    });
    return result;
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _wsService.dispose();
    super.dispose();
  }
}
