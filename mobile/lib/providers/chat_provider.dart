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

  ConversationDetail? get activeConversation => _activeConversation;
  List<MessageVm> get messages => _messages;
  bool get messagesLoading => _messagesLoading;
  String? get messagesError => _messagesError;
  bool get sendingMessage => _sendingMessage;

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
    _activeConversation = null;
    notifyListeners();

    try {
      _activeConversation = await _chatApi.getConversation(conversationId);
      _messages = await _chatApi.listMessages(conversationId);
      _messagesError = null;
    } catch (e) {
      _messagesError = e.toString();
    } finally {
      _messagesLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreMessages() async {
    if (_activeConversation == null || _messages.isEmpty) return;

    final cursor = _messages.last.sentAt.toIso8601String();
    try {
      final older = await _chatApi.listMessages(
        _activeConversation!.id,
        cursor: cursor,
      );
      if (older.isNotEmpty) {
        _messages = [..._messages, ...older];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('loadMoreMessages error: $e');
    }
  }

  Future<void> sendMessage(String content) async {
    if (_activeConversation == null || content.trim().isEmpty) return;

    _sendingMessage = true;
    notifyListeners();

    try {
      final msg = await _chatApi.sendMessage(
        _activeConversation!.id,
        content: content.trim(),
      );
      _messages = [msg, ..._messages];
    } catch (e) {
      debugPrint('sendMessage error: $e');
    } finally {
      _sendingMessage = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead() async {
    if (_activeConversation == null || _messages.isEmpty) return;
    try {
      await _chatApi.markRead(_activeConversation!.id, _messages.first.id);
    } catch (e) {
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
      case 'message.sent':
        _onMessageSent(event);
      case 'message.edited':
        _onMessageEdited(event);
      case 'message.deleted':
        _onMessageDeleted(event);
      default:
        break;
    }
    notifyListeners();
  }

  void _onMessageSent(ChatEvent event) {
    final msg = MessageVm.fromJson(event.payload);

    if (_activeConversation?.id == event.conversationId) {
      final exists = _messages.any((m) => m.id == msg.id);
      if (!exists) {
        _messages = [msg, ..._messages];
      }
    }

    // Update conversation list preview
    final idx =
        _conversations.indexWhere((c) => c.id == event.conversationId);
    if (idx >= 0) {
      loadConversations();
    }
  }

  void _onMessageEdited(ChatEvent event) {
    final messageId = event.payload['messageId'] as String;
    final newContent = event.payload['content'] as String;

    _messages = _messages.map((m) {
      if (m.id == messageId) {
        return MessageVm(
          id: m.id,
          senderUserId: m.senderUserId,
          senderDisplayName: m.senderDisplayName,
          type: m.type,
          content: newContent,
          fileIds: m.fileIds,
          replyToMessageId: m.replyToMessageId,
          editedAt: DateTime.tryParse(
              event.payload['editedAt'] as String? ?? ''),
          deletedAt: m.deletedAt,
          sentAt: m.sentAt,
        );
      }
      return m;
    }).toList();
  }

  void _onMessageDeleted(ChatEvent event) {
    final messageId = event.payload['messageId'] as String;
    _messages = _messages.where((m) => m.id != messageId).toList();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _wsService.dispose();
    super.dispose();
  }
}
