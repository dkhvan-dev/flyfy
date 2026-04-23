import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/network/chat_api.dart';
import '../core/network/chat_ws_service.dart';
import '../features/chat/models/conversation_vm.dart';
import '../features/chat/models/message_vm.dart';

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
    String? replyToMessageId,
  }) async {
    final normalizedFileIds = fileIds
            ?.map((id) => id.trim())
            .where((id) => id.isNotEmpty)
            .toList(growable: false) ??
        const <String>[];
    if (_activeConversation == null ||
        (content.trim().isEmpty && normalizedFileIds.isEmpty)) {
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
        type: normalizedFileIds.isEmpty ? type : 'file',
        fileIds: normalizedFileIds,
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

  Future<DeleteMessageResultVm> deleteMessage(String messageId) async {
    if (_activeConversation == null) {
      throw StateError('No active conversation');
    }

    final result =
        await _chatApi.deleteMessage(_activeConversation!.id, messageId);
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
    notifyListeners();
    unawaited(loadConversations());
    return result;
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
      case 'read_updated':
        _onReadUpdated(event);
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
      _messages = _messages
          .map(
            (message) => message.id == messageId
                ? message.copyWith(
                    deletedAt: deletedAt ?? DateTime.now().toUtc(),
                  )
                : message,
          )
          .toList();
    }

    unawaited(loadConversations());
  }

  void _onReadUpdated(ChatEvent event) {
    final userId = event.payload['userId'] as String?;
    final lastReadMessageId = (event.payload['lastReadMsgId'] ??
        event.payload['lastReadMessageId']) as String?;
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
