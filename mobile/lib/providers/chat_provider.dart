import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/network/chat_api.dart';
import '../core/network/chat_ws_service.dart';
import '../features/chat/models/conversation_vm.dart';
import '../features/chat/models/message_vm.dart';
import '../features/chat/models/sticker_pack_vm.dart';
import '../features/chat/models/user_block_status_vm.dart';

const _conversationMuteDuration = Duration(days: 3650);
const _conversationListCacheTtl = Duration(seconds: 15);

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
  Future<void>? _conversationsLoadFuture;
  DateTime? _conversationsLoadedAt;

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
  final Map<String, _CachedConversationState> _conversationStateCache = {};
  int _openConversationRequestSeq = 0;

  ConversationDetail? get activeConversation => _activeConversation;
  List<MessageVm> get messages => _messages;
  bool get messagesLoading => _messagesLoading;
  String? get messagesError => _messagesError;
  bool get sendingMessage => _sendingMessage;
  bool get hasMoreMessages => _hasMoreMessages;
  bool get loadingMoreMessages => _loadingMoreMessages;

  // ── WebSocket ──────────────────────────────────────────────────
  StreamSubscription<ChatEvent>? _eventSubscription;
  Timer? _conversationsRefreshTimer;
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

  Future<void> loadConversations({bool forceRefresh = false}) {
    final inFlight = _conversationsLoadFuture;
    if (inFlight != null) {
      return inFlight;
    }
    if (!forceRefresh && _hasFreshConversationListCache) {
      return Future<void>.value();
    }

    late final Future<void> future;
    future = _loadConversationsFromApi().whenComplete(() {
      if (identical(_conversationsLoadFuture, future)) {
        _conversationsLoadFuture = null;
      }
    });
    _conversationsLoadFuture = future;
    return future;
  }

  bool get _hasFreshConversationListCache {
    final loadedAt = _conversationsLoadedAt;
    if (_conversations.isEmpty || loadedAt == null) return false;
    return DateTime.now().toUtc().difference(loadedAt) <
        _conversationListCacheTtl;
  }

  Future<void> _loadConversationsFromApi() async {
    _conversationsLoading = true;
    _conversationsError = null;
    notifyListeners();

    try {
      _conversations = await _chatApi.listConversations();
      _conversationsLoadedAt = DateTime.now().toUtc();
      _conversationsError = null;
    } catch (e) {
      _conversationsError = e.toString();
    } finally {
      _conversationsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setConversationMuted(
    String conversationId, {
    required bool muted,
  }) async {
    final normalizedId = conversationId.trim();
    if (normalizedId.isEmpty) return false;

    final previousConversations = _conversations;
    final previousActiveConversation = _activeConversation;
    final mutedUntil = muted
        ? DateTime.now().toUtc().add(_conversationMuteDuration)
        : null;
    final mutedUntilWire = mutedUntil?.toIso8601String();

    _conversations = _conversations
        .map(
          (conversation) => conversation.id == normalizedId
              ? conversation.copyWith(mutedUntil: mutedUntilWire)
              : conversation,
        )
        .toList(growable: false);
    if (_activeConversation?.id == normalizedId) {
      _activeConversation = _activeConversation!.copyWith(
        mutedUntil: mutedUntilWire,
      );
      _cacheActiveConversationState();
    }
    notifyListeners();

    try {
      await _chatApi.muteConversation(normalizedId, until: mutedUntil);
      return true;
    } catch (e) {
      debugPrint('setConversationMuted error: $e');
      _conversations = previousConversations;
      _activeConversation = previousActiveConversation;
      notifyListeners();
      return false;
    }
  }

  Future<UserBlockStatusVm?> blockUser(String userId) async {
    return _setUserBlocked(userId, blocked: true);
  }

  Future<UserBlockStatusVm?> unblockUser(String userId) async {
    return _setUserBlocked(userId, blocked: false);
  }

  Future<UserBlockStatusVm?> _setUserBlocked(
    String userId, {
    required bool blocked,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return null;

    try {
      final status = blocked
          ? await _chatApi.blockUser(normalizedUserId)
          : await _chatApi.unblockUser(normalizedUserId);
      final active = _activeConversation;
      final matchesActiveDirectChat =
          active != null &&
          active.isDirect &&
          active.participants.any(
            (participant) => participant.userId.trim() == normalizedUserId,
          );
      if (matchesActiveDirectChat) {
        _activeConversation = active.copyWith(
          isBlockedByMe: status.isBlockedByMe,
          hasBlockedMe: status.hasBlockedMe,
          canSendMessages: !status.hasBlockedMe,
        );
        _cacheActiveConversationState();
        notifyListeners();
      }
      return status;
    } catch (e) {
      debugPrint('setUserBlocked error: $e');
      return null;
    }
  }

  // ── Active chat ────────────────────────────────────────────────

  Future<void> openConversation(String conversationId) async {
    final normalizedId = conversationId.trim();
    if (normalizedId.isEmpty) return;

    final requestSeq = ++_openConversationRequestSeq;
    final cached = _conversationStateCache[normalizedId];
    if (cached != null) {
      _activeConversation = cached.detail;
      _messages = cached.messages;
      _hasMoreMessages = cached.hasMoreMessages;
      _messagesLoading = false;
    } else {
      _messagesLoading = true;
      _messages = [];
      _hasMoreMessages = true;
      _activeConversation = null;
    }
    _messagesError = null;
    notifyListeners();

    try {
      final detailFuture = _chatApi.getConversation(normalizedId);
      final messagesFuture = _chatApi.listMessages(normalizedId);
      final detail = await detailFuture;
      final messages = _uniqueMessages(await messagesFuture);
      final hasMoreMessages = messages.length >= 30;
      _cacheConversationState(
        detail: detail,
        messages: messages,
        hasMoreMessages: hasMoreMessages,
      );
      if (requestSeq != _openConversationRequestSeq) return;

      _activeConversation = detail;
      _messages = messages;
      _hasMoreMessages = hasMoreMessages;
      _lastMarkedReadMessageIds.remove(normalizedId);
      _messagesError = null;
    } catch (e) {
      if (requestSeq == _openConversationRequestSeq) {
        _messagesError = e.toString();
      }
    } finally {
      if (requestSeq == _openConversationRequestSeq) {
        _messagesLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> openConversationByActivity(String activityId) async {
    final requestSeq = ++_openConversationRequestSeq;
    _messagesLoading = true;
    _messagesError = null;
    _messages = [];
    _hasMoreMessages = true;
    _activeConversation = null;
    notifyListeners();

    try {
      final detail = await _chatApi.getConversationByActivity(activityId);
      final messages = _uniqueMessages(await _chatApi.listMessages(detail.id));
      final hasMoreMessages = messages.length >= 30;
      _cacheConversationState(
        detail: detail,
        messages: messages,
        hasMoreMessages: hasMoreMessages,
      );
      if (requestSeq != _openConversationRequestSeq) return;

      _activeConversation = detail;
      _messages = messages;
      _hasMoreMessages = hasMoreMessages;
      _lastMarkedReadMessageIds.remove(detail.id);
      _messagesError = null;
    } catch (e) {
      if (requestSeq == _openConversationRequestSeq) {
        _messagesError = e.toString();
      }
    } finally {
      if (requestSeq == _openConversationRequestSeq) {
        _messagesLoading = false;
        notifyListeners();
      }
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
    notifyListeners();
    final cursor = _messages.last.id;
    try {
      final older = await _chatApi.listMessages(
        _activeConversation!.id,
        cursor: cursor,
      );
      if (older.isNotEmpty) {
        _messages = _uniqueMessages([..._messages, ...older]);
      }
      _hasMoreMessages = older.length >= 30;
      _cacheActiveConversationState();
    } catch (e) {
      debugPrint('loadMoreMessages error: $e');
    } finally {
      _loadingMoreMessages = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage(
    String content, {
    String type = 'text',
    List<String>? fileIds,
    String? stickerId,
    String? replyToMessageId,
  }) async {
    final normalizedFileIds =
        fileIds
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
        clientMessageId: _newClientMessageId(),
      );
      _messages = _uniqueMessages([msg, ..._messages]);
      _upsertConversationPreviewFromMessage(_activeConversation!.id, msg);
      _cacheActiveConversationState();
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
        _upsertConversationPreviewFromMessage(sourceConversation.id, forwarded);
      }
      _messages = _messages
          .map(
            (item) => item.id == message.id
                ? item.copyWith(forwardCount: item.forwardCount + 1)
                : item,
          )
          .toList(growable: false);
      _cacheActiveConversationState();
      notifyListeners();
      _scheduleConversationsRefresh();
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
      _messages = _messages
          .where((message) => message.id != messageId)
          .toList();
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
    _cacheActiveConversationState();
    notifyListeners();
    _scheduleConversationsRefresh();
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
    _cacheActiveConversationState();
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
    _cacheActiveConversationState();
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
    _cacheActiveConversationState();
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
    _cacheActiveConversationState();
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
    _cacheActiveConversationState();
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

    final updated = _upsertConversationPreviewFromMessage(
      event.conversationId,
      msg,
    );
    if (!updated) {
      _scheduleConversationsRefresh();
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
      final moderationPublicComment = event.payload['moderationPublicComment']
          ?.toString();
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

    _scheduleConversationsRefresh();
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
    final lastReadMessageId =
        (event.payload['lastReadMsgId'] ?? event.payload['lastReadMessageId'])
            as String?;
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
          shouldAdd:
              readIndex <= index &&
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

  bool _upsertConversationPreviewFromMessage(
    String conversationId,
    MessageVm message,
  ) {
    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx < 0) return false;

    final preview = LastMessagePreview(
      id: message.id,
      senderUserId: message.senderUserId,
      senderDisplayName: message.senderDisplayName,
      type: message.type,
      contentPreview: message.content,
      fileIds: message.fileIds,
      stickerId: message.stickerId,
      stickerFileId: message.stickerFileId,
      deletedAt: message.deletedAt,
      moderationStatus: message.moderationStatus,
      moderationPublicComment: message.moderationPublicComment,
      sentAt: message.sentAt,
    );
    final updated = _conversations[idx].copyWith(
      lastMessage: preview,
      lastActivityAt: message.sentAt,
    );
    _conversations =
        [
          for (var index = 0; index < _conversations.length; index++)
            if (index == idx) updated else _conversations[index],
        ]..sort((a, b) {
          final byActivity = b.lastActivityAt.compareTo(a.lastActivityAt);
          if (byActivity != 0) return byActivity;
          return b.id.compareTo(a.id);
        });
    return true;
  }

  void _scheduleConversationsRefresh() {
    if (_conversationsRefreshTimer?.isActive ?? false) return;
    _conversationsRefreshTimer = Timer(const Duration(seconds: 2), () {
      unawaited(loadConversations(forceRefresh: true));
    });
  }

  void _cacheActiveConversationState() {
    final active = _activeConversation;
    if (active == null) return;
    _cacheConversationState(
      detail: active,
      messages: _messages,
      hasMoreMessages: _hasMoreMessages,
    );
  }

  void _cacheConversationState({
    required ConversationDetail detail,
    required List<MessageVm> messages,
    required bool hasMoreMessages,
  }) {
    _conversationStateCache[detail.id] = _CachedConversationState(
      detail: detail,
      messages: List<MessageVm>.unmodifiable(messages),
      hasMoreMessages: hasMoreMessages,
    );
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

  String _newClientMessageId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final value = bytes.map(hex).join();
    return '${value.substring(0, 8)}-'
        '${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-'
        '${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _conversationsRefreshTimer?.cancel();
    _wsService.dispose();
    super.dispose();
  }
}

class _CachedConversationState {
  const _CachedConversationState({
    required this.detail,
    required this.messages,
    required this.hasMoreMessages,
  });

  final ConversationDetail detail;
  final List<MessageVm> messages;
  final bool hasMoreMessages;
}
