import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../../core/files/chat_file_cache.dart';
import '../../core/network/dio_error_mapper.dart';
import '../../core/network/file_api.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/error_dialog.dart';
import '../../features/chat/models/conversation_vm.dart';
import '../../features/chat/models/message_vm.dart';
import '../../features/chat/utils/chat_presence_status.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/chat_provider.dart';
import '../../providers/session_provider.dart';
import 'chat_image_viewer_screen.dart';
import 'chat_participants_screen.dart';
import 'chat_shared_content_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.conversationId, this.activityId})
    : assert(conversationId != null || activityId != null);

  final String? conversationId;
  final String? activityId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _maxChatAttachmentBytes = 25 * 1024 * 1024;

  final _fileApi = FileApi();
  final _voiceRecorder = AudioRecorder();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final Map<String, GlobalKey> _messageItemKeys = {};
  Timer? _typingDebounce;
  Timer? _messagingWindowTimer;
  Timer? _messageHighlightTimer;
  Timer? _voiceRecordingTimer;
  String? _messagingWindowTimerKey;
  final List<_PickedChatAttachment> _pendingAttachments = [];
  int _pendingAttachmentSeq = 0;
  bool _attachmentUploading = false;
  bool _voiceRecording = false;
  bool _voiceStopping = false;
  DateTime? _voiceRecordingStartedAt;
  Duration _voiceRecordingDuration = Duration.zero;
  MessageVm? _replyToMessage;
  String? _highlightedMessageId;
  int _pinnedMessageIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openConversation();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingDebounce?.cancel();
    _messagingWindowTimer?.cancel();
    _messageHighlightTimer?.cancel();
    _voiceRecordingTimer?.cancel();
    unawaited(_disposeVoiceRecorder());
    super.dispose();
  }

  Future<void> _disposeVoiceRecorder() async {
    try {
      if (await _voiceRecorder.isRecording()) {
        await _voiceRecorder.cancel();
      }
    } catch (_) {
      // Best-effort cleanup during widget disposal.
    }
    await _voiceRecorder.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ChatProvider>().loadMoreMessages();
    }
    _markVisibleMessagesAsRead();
  }

  Future<void> _openConversation() async {
    final provider = context.read<ChatProvider>();
    if (widget.activityId != null) {
      await provider.openConversationByActivity(widget.activityId!);
    } else {
      await provider.openConversation(widget.conversationId!);
    }
    if (!mounted) return;
    setState(() {
      _replyToMessage = null;
      _highlightedMessageId = null;
      _pinnedMessageIndex = 0;
      _messageItemKeys.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markVisibleMessagesAsRead();
    });
  }

  bool get _isAtLatestMessagesEdge {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return position.pixels <= position.minScrollExtent + 80;
  }

  void _markVisibleMessagesAsRead() {
    if (!_isAtLatestMessagesEdge) return;
    context.read<ChatProvider>().markAsRead();
  }

  Future<void> _handleSend() async {
    if (_attachmentUploading) return;
    if (!_canSendInActiveConversation()) {
      _showChatClosedMessage();
      return;
    }

    final text = _messageController.text.trim();
    final attachments = List<_PickedChatAttachment>.of(_pendingAttachments);
    final replyToMessageId = _replyToMessage?.id;
    if (text.isEmpty && attachments.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final fileIds = <String>[];

    try {
      if (attachments.isNotEmpty) {
        setState(() => _attachmentUploading = true);

        for (final attachment in attachments) {
          final upload = await _fileApi.createChatAttachmentUpload(
            originalName: attachment.name,
            contentType: attachment.contentType,
            sizeBytes: attachment.bytes.lengthInBytes,
          );
          await _fileApi.uploadBinary(
            upload: upload,
            bytes: attachment.bytes,
            contentType: attachment.contentType,
          );
          await _fileApi.completeUpload(upload.fileId);
          fileIds.add(upload.fileId);
        }
      }

      if (!mounted) return;

      final sent = await context.read<ChatProvider>().sendMessage(
        text,
        type: fileIds.isEmpty ? 'text' : 'file',
        fileIds: fileIds,
        replyToMessageId: replyToMessageId,
      );

      if (!mounted || !sent) return;

      _messageController.clear();
      setState(() {
        _pendingAttachments.clear();
        _replyToMessage = null;
      });
      context.read<ChatProvider>().markAsRead();
    } catch (e) {
      if (!mounted) return;
      final message = e is DioException
          ? DioErrorMapper.toMessage(e)
          : l10n.chatAttachmentUploadFailed;
      await _showAttachmentError(message);
    } finally {
      if (mounted) {
        setState(() => _attachmentUploading = false);
      }
    }
  }

  Future<void> _pickAttachments(_AttachmentPickType type) async {
    if (_attachmentUploading) return;
    if (!_canSendInActiveConversation()) {
      _showChatClosedMessage();
      return;
    }

    FocusScope.of(context).unfocus();
    final l10n = AppLocalizations.of(context)!;

    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        withData: true,
        type: switch (type) {
          _AttachmentPickType.media => FileType.media,
          _AttachmentPickType.file => FileType.any,
        },
      );
      if (!mounted || result == null || result.files.isEmpty) return;

      final attachments = <_PickedChatAttachment>[];
      for (final file in result.files) {
        final attachment = await _attachmentFromFile(
          file,
          ++_pendingAttachmentSeq,
        );
        if (!mounted) return;

        if (attachment == null) {
          await _showAttachmentError(l10n.chatAttachmentUnsupported);
          return;
        }
        if (attachment.bytes.lengthInBytes > _maxChatAttachmentBytes) {
          await _showAttachmentError(l10n.chatAttachmentTooLarge);
          return;
        }
        attachments.add(attachment);
      }

      if (attachments.isEmpty) return;
      setState(() => _pendingAttachments.addAll(attachments));
      _focusNode.requestFocus();
    } catch (e) {
      if (!mounted) return;
      final message = e is DioException
          ? DioErrorMapper.toMessage(e)
          : l10n.chatAttachmentUploadFailed;
      await _showAttachmentError(message);
    }
  }

  Future<_PickedChatAttachment?> _attachmentFromFile(
    PlatformFile file,
    int localId,
  ) async {
    final name = file.name.trim();
    final bytes =
        file.bytes ??
        (file.path == null ? null : await File(file.path!).readAsBytes());
    if (name.isEmpty || bytes == null || bytes.isEmpty) {
      return null;
    }

    final contentType = _contentTypeForFileName(name);
    if (contentType == null) {
      return null;
    }

    return _PickedChatAttachment(
      localId: localId,
      name: name,
      bytes: bytes,
      contentType: contentType,
    );
  }

  void _removePendingAttachment(int localId) {
    if (_attachmentUploading) return;
    setState(() {
      _pendingAttachments.removeWhere((item) => item.localId == localId);
    });
  }

  Future<void> _startVoiceRecording() async {
    if (_voiceRecording || _voiceStopping || _attachmentUploading) return;
    if (!_canSendInActiveConversation()) {
      _showChatClosedMessage();
      return;
    }

    FocusScope.of(context).unfocus();
    final l10n = AppLocalizations.of(context)!;

    try {
      final hasPermission = await _voiceRecorder.hasPermission();
      if (!mounted) return;
      if (!hasPermission) {
        await _showAttachmentError(l10n.chatVoiceRecordPermissionDenied);
        return;
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/flyfy_voice_${DateTime.now().microsecondsSinceEpoch}.m4a';
      await _voiceRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 44100,
          numChannels: 1,
          noiseSuppress: true,
          echoCancel: true,
        ),
        path: path,
      );

      if (!mounted) return;
      setState(() {
        _voiceRecording = true;
        _voiceStopping = false;
        _voiceRecordingStartedAt = DateTime.now();
        _voiceRecordingDuration = Duration.zero;
      });
      _voiceRecordingTimer?.cancel();
      _voiceRecordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _voiceRecordingStartedAt == null) return;
        setState(() {
          _voiceRecordingDuration = DateTime.now().difference(
            _voiceRecordingStartedAt!,
          );
        });
      });
    } catch (_) {
      if (!mounted) return;
      await _showAttachmentError(l10n.chatVoiceRecordFailed);
      await _resetVoiceRecording(cancelRecorder: true);
    }
  }

  Future<void> _cancelVoiceRecording() async {
    await _resetVoiceRecording(cancelRecorder: true);
  }

  Future<void> _sendVoiceRecording() async {
    if (!_voiceRecording || _voiceStopping) return;
    if (!_canSendInActiveConversation()) {
      _showChatClosedMessage();
      await _resetVoiceRecording(cancelRecorder: true);
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final replyToMessageId = _replyToMessage?.id;
    setState(() => _voiceStopping = true);
    _voiceRecordingTimer?.cancel();

    try {
      final path = await _voiceRecorder.stop();
      final recordedAt = _voiceRecordingStartedAt;
      final duration = recordedAt == null
          ? _voiceRecordingDuration
          : DateTime.now().difference(recordedAt);

      setState(() {
        _voiceRecording = false;
        _voiceRecordingStartedAt = null;
        _voiceRecordingDuration = Duration.zero;
      });

      if (path == null || path.trim().isEmpty) {
        await _showAttachmentError(l10n.chatVoiceRecordFailed);
        return;
      }

      final file = File(path);
      if (!await file.exists() || await file.length() == 0) {
        await _showAttachmentError(l10n.chatVoiceRecordFailed);
        return;
      }
      if (duration < const Duration(seconds: 1)) {
        await file.delete().catchError((_) => file);
        await _showAttachmentError(l10n.chatVoiceTooShort);
        return;
      }

      final bytes = await file.readAsBytes();
      unawaited(file.delete().catchError((_) => file));
      if (bytes.lengthInBytes > _maxChatAttachmentBytes) {
        await _showAttachmentError(l10n.chatAttachmentTooLarge);
        return;
      }

      setState(() => _attachmentUploading = true);
      final upload = await _fileApi.createChatAttachmentUpload(
        originalName:
            'voice_${DateTime.now().millisecondsSinceEpoch}_${duration.inSeconds}s.m4a',
        contentType: 'audio/mp4',
        sizeBytes: bytes.lengthInBytes,
      );
      await _fileApi.uploadBinary(
        upload: upload,
        bytes: bytes,
        contentType: 'audio/mp4',
      );
      await _fileApi.completeUpload(upload.fileId);

      if (!mounted) return;
      final sent = await context.read<ChatProvider>().sendMessage(
        '',
        type: 'file',
        fileIds: [upload.fileId],
        replyToMessageId: replyToMessageId,
      );
      if (sent && mounted) {
        setState(() => _replyToMessage = null);
        context.read<ChatProvider>().markAsRead();
      }
    } catch (_) {
      if (!mounted) return;
      await _showAttachmentError(l10n.chatVoiceRecordFailed);
    } finally {
      if (mounted) {
        setState(() {
          _voiceStopping = false;
          _attachmentUploading = false;
        });
      }
    }
  }

  Future<void> _resetVoiceRecording({required bool cancelRecorder}) async {
    _voiceRecordingTimer?.cancel();
    _voiceRecordingTimer = null;

    try {
      if (cancelRecorder && await _voiceRecorder.isRecording()) {
        await _voiceRecorder.cancel();
      }
    } catch (_) {
      // The recorder may already be stopped by the platform.
    }

    if (!mounted) return;
    setState(() {
      _voiceRecording = false;
      _voiceStopping = false;
      _voiceRecordingStartedAt = null;
      _voiceRecordingDuration = Duration.zero;
    });
  }

  Future<void> _showAttachmentError(String message) {
    return showErrorDialog(
      context,
      title: AppLocalizations.of(context)!.error,
      message: message,
    );
  }

  bool _canSendInActiveConversation() {
    return context.read<ChatProvider>().activeConversation?.canSendNow ?? true;
  }

  void _showChatClosedMessage() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.chatActivityChatClosed),
        backgroundColor: const Color(0xFF3a2415),
      ),
    );
  }

  void _scheduleMessagingWindowRefresh(ConversationDetail conversation) {
    final until = conversation.messagingAvailableUntil?.toUtc();
    final key = '${conversation.id}:${until?.toIso8601String() ?? 'open'}';
    if (_messagingWindowTimerKey == key) return;

    _messagingWindowTimerKey = key;
    _messagingWindowTimer?.cancel();
    _messagingWindowTimer = null;

    if (until == null || !DateTime.now().toUtc().isBefore(until)) {
      return;
    }

    final delay = until.difference(DateTime.now().toUtc());
    _messagingWindowTimer = Timer(delay + const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _handleTyping() {
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () {});
    context.read<ChatProvider>().sendTyping();
  }

  void _selectReplyMessage(MessageVm message) {
    if (message.isSystem || message.isDeleted) return;
    setState(() => _replyToMessage = message);
    _focusNode.requestFocus();
  }

  void _clearReplyMessage() {
    if (_replyToMessage == null) return;
    setState(() => _replyToMessage = null);
  }

  bool _canManagePins(ConversationDetail conversation, String currentUserId) {
    final participant = conversation.participants
        .where((p) => p.userId == currentUserId)
        .firstOrNull;
    if (participant == null) {
      return false;
    }
    if (conversation.isDirect) {
      return true;
    }
    return participant.role == 'admin';
  }

  bool _isMessagePinned(ConversationDetail conversation, String messageId) {
    return conversation.pinnedMessages.any((pin) => pin.id == messageId);
  }

  int _normalizedPinnedMessageIndex(int total) {
    if (total <= 0) return 0;
    return _pinnedMessageIndex % total;
  }

  Future<void> _handlePinnedBannerTap(
    List<PinnedMessageInfo> pinnedMessages,
  ) async {
    if (pinnedMessages.isEmpty) return;

    final currentIndex = _normalizedPinnedMessageIndex(pinnedMessages.length);
    final didScroll = await _scrollToMessage(pinnedMessages[currentIndex].id);
    if (!mounted || !didScroll || pinnedMessages.length < 2) {
      return;
    }

    setState(() {
      _pinnedMessageIndex = (currentIndex + 1) % pinnedMessages.length;
    });
  }

  Future<void> _showMessageActions(MessageVm message) async {
    if (message.isSystem || message.isDeleted) return;

    final chat = context.read<ChatProvider>();
    final conversation = chat.activeConversation;
    if (conversation == null) return;

    final currentUserId =
        context.read<SessionProvider>().profile?.userId.trim() ?? '';
    final canDelete = message.senderUserId == currentUserId;
    final canManagePins = _canManagePins(conversation, currentUserId);
    final isPinned = _isMessagePinned(conversation, message.id);
    if (!canDelete && !canManagePins) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1d120b),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canManagePins)
                ListTile(
                  leading: Icon(
                    isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                    color: AppColors.accent,
                  ),
                  title: Text(
                    isPinned ? l10n.chatUnpinAction : l10n.chatPinAction,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () =>
                      Navigator.pop(sheetContext, isPinned ? 'unpin' : 'pin'),
                ),
              if (canDelete)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFff6b5f),
                  ),
                  title: Text(
                    l10n.chatDeleteAction,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.pop(sheetContext, 'delete'),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: Text(
                  l10n.cancelButton,
                  style: const TextStyle(color: AppColors.accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || action == null) return;

    if (action == 'pin' || action == 'unpin') {
      try {
        if (action == 'pin') {
          await context.read<ChatProvider>().pinMessage(message.id);
        } else {
          await context.read<ChatProvider>().unpinMessage(message.id);
        }
      } catch (e) {
        if (!mounted) return;
        final messageText = e is DioException
            ? DioErrorMapper.toMessage(e)
            : action == 'pin'
            ? l10n.chatPinFailed
            : l10n.chatUnpinFailed;
        await showErrorDialog(context, title: l10n.error, message: messageText);
      }
      return;
    }

    if (action != 'delete') return;

    try {
      final result = await context.read<ChatProvider>().deleteMessage(
        message.id,
      );
      if (!mounted) return;
      setState(() {
        if (_replyToMessage?.id == message.id) {
          _replyToMessage = null;
        }
        if (result.hardDeleted) {
          _messageItemKeys.remove(message.id);
        }
      });
    } catch (e) {
      if (!mounted) return;
      final messageText = e is DioException
          ? DioErrorMapper.toMessage(e)
          : l10n.chatDeleteFailed;
      await showErrorDialog(context, title: l10n.error, message: messageText);
    }
  }

  GlobalKey _messageItemKey(String messageId) {
    return _messageItemKeys.putIfAbsent(
      messageId,
      () => GlobalKey(debugLabel: 'chat-message-$messageId'),
    );
  }

  Future<bool> _scrollToMessage(String messageId) async {
    final normalizedMessageId = messageId.trim();
    if (normalizedMessageId.isEmpty) return false;

    final chat = context.read<ChatProvider>();
    while (!chat.messages.any((message) => message.id == normalizedMessageId) &&
        chat.hasMoreMessages) {
      final beforeLength = chat.messages.length;
      await chat.loadMoreMessages();
      if (!mounted || chat.messages.length == beforeLength) {
        break;
      }
    }

    if (!mounted) return false;
    final targetExists = chat.messages.any(
      (message) => message.id == normalizedMessageId,
    );
    if (!targetExists) {
      return false;
    }

    _highlightMessage(normalizedMessageId);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return false;
    await _ensureMessageVisible(normalizedMessageId);
    return true;
  }

  void _highlightMessage(String messageId) {
    _messageHighlightTimer?.cancel();
    setState(() => _highlightedMessageId = messageId);
    _messageHighlightTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || _highlightedMessageId != messageId) return;
      setState(() => _highlightedMessageId = null);
    });
  }

  Future<void> _ensureMessageVisible(String messageId) async {
    if (_messageItemKeys[messageId]?.currentContext == null) {
      WidgetsBinding.instance.scheduleFrame();
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }

    final targetRenderObject = _messageItemKeys[messageId]?.currentContext
        ?.findRenderObject();
    if (targetRenderObject == null ||
        !mounted ||
        !_scrollController.hasClients) {
      return;
    }

    await _scrollController.position.ensureVisible(
      targetRenderObject,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: 0.45,
    );
  }

  void _openParticipants(
    ConversationDetail conversation,
    String currentUserId,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatParticipantsScreen(
          conversation: conversation,
          currentUserId: currentUserId,
        ),
      ),
    );
  }

  void _openSharedContent(
    ConversationDetail conversation,
    String currentUserId,
    List<MessageVm> messages,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatSharedContentScreen(
          conversation: conversation,
          currentUserId: currentUserId,
          initialMessages: messages,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.select<SessionProvider, String>(
      (session) => session.profile?.userId ?? '',
    );

    return Scaffold(
      backgroundColor: const Color(0xFF100802),
      resizeToAvoidBottomInset: true,
      body: Consumer<ChatProvider>(
        builder: (context, chat, _) {
          if (chat.messagesLoading && chat.messages.isEmpty) {
            return const _LoadingState();
          }

          if (chat.messagesError != null && chat.messages.isEmpty) {
            return _ErrorState(
              onRetry: () {
                if (widget.activityId != null) {
                  chat.openConversationByActivity(widget.activityId!);
                } else {
                  chat.openConversation(widget.conversationId!);
                }
              },
            );
          }

          final conv = chat.activeConversation;
          if (conv == null) return const _LoadingState();
          final messagingClosed = !conv.canSendNow;
          _scheduleMessagingWindowRefresh(conv);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _markVisibleMessagesAsRead();
            }
          });

          return Column(
            children: [
              _ChatTopBar(
                conversation: conv,
                currentUserId: currentUserId,
                onParticipantsTap: () => _openParticipants(conv, currentUserId),
                onSharedContentTap: () =>
                    _openSharedContent(conv, currentUserId, chat.messages),
              ),
              if (conv.pinnedMessages.isNotEmpty)
                _PinnedMessagesBar(
                  pinnedMessages: conv.pinnedMessages,
                  participants: conv.participants,
                  currentIndex: _normalizedPinnedMessageIndex(
                    conv.pinnedMessages.length,
                  ),
                  onTap: () =>
                      unawaited(_handlePinnedBannerTap(conv.pinnedMessages)),
                ),
              Expanded(
                child: _MessageList(
                  messages: chat.messages,
                  conversation: conv,
                  scrollController: _scrollController,
                  currentUserId: currentUserId,
                  messagingClosed: messagingClosed,
                  highlightedMessageId: _highlightedMessageId,
                  messageKeyForId: _messageItemKey,
                  onReplyMessage: _selectReplyMessage,
                  onMessageLongPress: (message) =>
                      unawaited(_showMessageActions(message)),
                  onReplyPreviewTap: (messageId) =>
                      unawaited(_scrollToMessage(messageId)),
                ),
              ),
              if (!messagingClosed)
                _ChatComposer(
                  controller: _messageController,
                  focusNode: _focusNode,
                  pendingAttachments: _pendingAttachments,
                  replyToMessage: _replyToMessage,
                  participants: conv.participants,
                  onSend: () => unawaited(_handleSend()),
                  onTyping: _handleTyping,
                  onPickMedia: () =>
                      _pickAttachments(_AttachmentPickType.media),
                  onPickFile: () => _pickAttachments(_AttachmentPickType.file),
                  onRemoveAttachment: _removePendingAttachment,
                  onCancelReply: _clearReplyMessage,
                  onVoiceStart: _startVoiceRecording,
                  onVoiceCancel: _cancelVoiceRecording,
                  onVoiceSend: _sendVoiceRecording,
                  sending: chat.sendingMessage,
                  attachmentUploading: _attachmentUploading,
                  voiceRecording: _voiceRecording,
                  voiceStopping: _voiceStopping,
                  voiceDuration: _voiceRecordingDuration,
                  messagingClosed: false,
                ),
            ],
          );
        },
      ),
    );
  }
}

enum _AttachmentPickType { media, file }

class _PickedChatAttachment {
  const _PickedChatAttachment({
    required this.localId,
    required this.name,
    required this.bytes,
    required this.contentType,
  });

  final int localId;
  final String name;
  final Uint8List bytes;
  final String contentType;

  bool get isImage => contentType.startsWith('image/');
  bool get isVideo => contentType.startsWith('video/');

  String get extensionLabel {
    final dot = name.lastIndexOf('.');
    if (dot >= 0 && dot < name.length - 1) {
      return name.substring(dot + 1).toUpperCase();
    }
    final subtype = contentType.split('/').lastOrNull ?? '';
    return subtype.isEmpty ? 'FILE' : subtype.toUpperCase();
  }
}

// ── Adaptive helpers ─────────────────────────────────────────────

double _sw(BuildContext context) => MediaQuery.sizeOf(context).width;

double _scale(BuildContext context, double base) => base * _sw(context) / 390;

String? _contentTypeForFileName(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot < 0 || dot == fileName.length - 1) return null;

  final ext = fileName.substring(dot + 1).toLowerCase();
  return switch (ext) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    'heif' => 'image/heif',
    'mp4' => 'video/mp4',
    'mov' => 'video/quicktime',
    'webm' => 'video/webm',
    'm4v' => 'video/x-m4v',
    'm4a' => 'audio/mp4',
    'aac' => 'audio/aac',
    'mp3' => 'audio/mpeg',
    'wav' => 'audio/wav',
    'ogg' => 'audio/ogg',
    'opus' => 'audio/opus',
    'pdf' => 'application/pdf',
    'zip' => 'application/zip',
    'txt' => 'text/plain',
    'csv' => 'text/csv',
    'xls' => 'application/vnd.ms-excel',
    'xlsx' =>
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'doc' => 'application/msword',
    'docx' =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    _ => null,
  };
}

// ── Top bar ──────────────────────────────────────────────────────

class _ChatTopBar extends StatelessWidget {
  const _ChatTopBar({
    required this.conversation,
    required this.currentUserId,
    required this.onParticipantsTap,
    required this.onSharedContentTap,
  });

  final ConversationDetail conversation;
  final String currentUserId;
  final VoidCallback onParticipantsTap;
  final VoidCallback onSharedContentTap;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final hz = _scale(context, 16);

    return Container(
      padding: EdgeInsets.only(
        top: mq.padding.top + _scale(context, 14),
        left: hz,
        right: hz,
        bottom: _scale(context, 14),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1d120b),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: _scale(context, 40),
              height: _scale(context, 40),
              child: Center(
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: _scale(context, 20),
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: _scale(context, 12)),
          if (conversation.isDirect)
            _DirectTopBarContent(
              conversation: conversation,
              currentUserId: currentUserId,
              onTap: onSharedContentTap,
            )
          else ...[
            _GroupTopBarContent(
              conversation: conversation,
              onTap: onSharedContentTap,
            ),
            SizedBox(width: _scale(context, 12)),
            _ParticipantsButton(onTap: onParticipantsTap),
          ],
        ],
      ),
    );
  }
}

class _ParticipantsButton extends StatelessWidget {
  const _ParticipantsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = _scale(context, 42);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x2EFF9D00)),
          color: const Color(0x0DFF9900),
        ),
        child: Center(
          child: Icon(
            Icons.group_outlined,
            size: _scale(context, 20),
            color: const Color(0xFFff9800),
          ),
        ),
      ),
    );
  }
}

class _DirectTopBarContent extends StatelessWidget {
  const _DirectTopBarContent({
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
  });

  final ConversationDetail conversation;
  final String currentUserId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final other = conversation.directPeer(currentUserId);
    final l10n = AppLocalizations.of(context)!;
    final isOnline = other?.isOnline ?? false;
    final statusLabel = chatPresenceStatusLabel(l10n, other);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            _ChatAvatar(
              size: _scale(context, 48),
              name: other?.displayName ?? '',
              avatarFileId: other?.avatarFileId,
            ),
            SizedBox(width: _scale(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    other?.displayName ??
                        conversation.title ??
                        l10n.chatFallbackTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: _scale(context, 20),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: const Color(0xFFffb11e),
                    ),
                  ),
                  SizedBox(height: _scale(context, 4)),
                  Row(
                    children: [
                      if (isOnline) ...[
                        Container(
                          width: _scale(context, 9),
                          height: _scale(context, 9),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.28),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: _scale(context, 6)),
                      ],
                      Flexible(
                        child: Text(
                          statusLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: _scale(context, 12),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: isOnline
                                ? AppColors.accent
                                : Colors.white.withValues(alpha: 0.56),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupTopBarContent extends StatelessWidget {
  const _GroupTopBarContent({required this.conversation, required this.onTap});

  final ConversationDetail conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Text(
              conversation.title ?? l10n.chatGroupFallbackTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _scale(context, 22),
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: _scale(context, 3)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: _scale(context, 9),
                  height: _scale(context, 9),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.45),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: _scale(context, 6)),
                Text(
                  l10n.chatParticipantsCount(conversation.participants.length),
                  style: TextStyle(
                    fontSize: _scale(context, 14),
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFf4a020),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pinned messages ──────────────────────────────────────────────

class _PinnedMessagesBar extends StatelessWidget {
  const _PinnedMessagesBar({
    required this.pinnedMessages,
    required this.participants,
    required this.currentIndex,
    required this.onTap,
  });

  final List<PinnedMessageInfo> pinnedMessages;
  final List<ParticipantInfo> participants;
  final int currentIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (pinnedMessages.isEmpty) {
      return const SizedBox.shrink();
    }

    final pinned = pinnedMessages[currentIndex];
    final l10n = AppLocalizations.of(context)!;
    final accentColor = _nameColorFor(pinned.senderUserId);
    final pinnedMessage = _pinnedMessageAsMessageVm(pinned);
    final senderName = _senderNameForMessage(pinnedMessage, participants, l10n);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        _scale(context, 14),
        _scale(context, 10),
        _scale(context, 14),
        _scale(context, 2),
      ),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: _scale(context, 16),
            vertical: _scale(context, 12),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_scale(context, 18)),
            color: const Color(0xFF201108),
            border: Border.all(color: const Color(0x3DFF9800)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: _scale(context, 4),
                height: _scale(context, 42),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: AppColors.accent,
                ),
              ),
              SizedBox(width: _scale(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.push_pin_rounded,
                          size: _scale(context, 15),
                          color: const Color(0xFFff9800),
                        ),
                        SizedBox(width: _scale(context, 6)),
                        Expanded(
                          child: Text(
                            l10n.chatPinnedMessageLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: _scale(context, 11),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.7,
                              color: const Color(0xFFff9800),
                            ),
                          ),
                        ),
                        if (pinnedMessages.length > 1)
                          Text(
                            '${currentIndex + 1}/${pinnedMessages.length}',
                            style: TextStyle(
                              fontSize: _scale(context, 11),
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withValues(alpha: 0.54),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: _scale(context, 6)),
                    Text(
                      senderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: _scale(context, 13),
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                    SizedBox(height: _scale(context, 2)),
                    _ReplyPreviewText(message: pinnedMessage),
                  ],
                ),
              ),
              SizedBox(width: _scale(context, 8)),
              Icon(
                Icons.chevron_right_rounded,
                size: _scale(context, 20),
                color: Colors.white.withValues(alpha: 0.56),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Message list ─────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.conversation,
    required this.scrollController,
    required this.currentUserId,
    required this.messagingClosed,
    required this.highlightedMessageId,
    required this.messageKeyForId,
    required this.onReplyMessage,
    required this.onMessageLongPress,
    required this.onReplyPreviewTap,
  });

  final List<MessageVm> messages;
  final ConversationDetail conversation;
  final ScrollController scrollController;
  final String currentUserId;
  final bool messagingClosed;
  final String? highlightedMessageId;
  final GlobalKey Function(String messageId) messageKeyForId;
  final ValueChanged<MessageVm> onReplyMessage;
  final ValueChanged<MessageVm> onMessageLongPress;
  final ValueChanged<String> onReplyPreviewTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = _buildItems(context, l10n);
    final displayItems = items.reversed.toList(growable: false);
    final gap = _scale(context, 28);

    return CustomScrollView(
      controller: scrollController,
      reverse: true,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: _scale(context, 14),
            vertical: _scale(context, 16),
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                for (var i = 0; i < displayItems.length; i++) ...[
                  displayItems[i],
                  if (i != displayItems.length - 1) SizedBox(height: gap),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildItems(BuildContext context, AppLocalizations l10n) {
    final items = <Widget>[];
    final messagesById = <String, MessageVm>{
      for (final message in messages) message.id: message,
    };

    if (messagingClosed) {
      items.add(
        _ChatClosedTailNotice(text: l10n.chatActivityChatClosedHistoryNotice),
      );
    }

    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final dateLabel = _dateLabelFor(msg.sentAt, l10n);

      items.add(
        _MessageBubble(
          messageKey: messageKeyForId(msg.id),
          message: msg,
          isGroup: conversation.isGroup,
          isMine: msg.senderUserId == currentUserId,
          isHighlighted: highlightedMessageId == msg.id,
          readByOthers: _isReadByAnotherParticipant(msg, i),
          showReadTicks: !conversation.isActivity,
          participants: conversation.participants,
          repliedMessage: msg.replyToMessageId == null
              ? null
              : messagesById[msg.replyToMessageId!],
          onReply: () => onReplyMessage(msg),
          onLongPress: msg.isSystem || msg.isDeleted
              ? null
              : () => onMessageLongPress(msg),
          onReplyPreviewTap: msg.replyToMessageId == null
              ? null
              : () => onReplyPreviewTap(msg.replyToMessageId!),
          l10n: l10n,
        ),
      );

      final nextMsg = i + 1 < messages.length ? messages[i + 1] : null;
      if (nextMsg != null && dateLabel != _dateLabelFor(nextMsg.sentAt, l10n)) {
        items.add(_DaySeparator(label: dateLabel));
      }
    }

    if (messages.isNotEmpty) {
      items.add(
        _DaySeparator(label: _dateLabelFor(messages.last.sentAt, l10n)),
      );
    }

    return items;
  }

  bool _isReadByAnotherParticipant(MessageVm message, int messageIndex) {
    if (currentUserId.trim().isEmpty ||
        message.senderUserId != currentUserId ||
        message.isSystem) {
      return false;
    }

    for (final participant in conversation.participants) {
      if (participant.userId == currentUserId) {
        continue;
      }
      final lastReadId = participant.lastReadMessageId?.trim() ?? '';
      if (lastReadId.isEmpty) {
        continue;
      }
      if (lastReadId == message.id) {
        return true;
      }

      final readIndex = messages.indexWhere((m) => m.id == lastReadId);
      if (readIndex >= 0 && readIndex <= messageIndex) {
        return true;
      }
    }

    return false;
  }

  String _dateLabelFor(DateTime dt, AppLocalizations l10n) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(local.year, local.month, local.day);
    final diff = today.difference(date).inDays;

    if (diff == 0) return l10n.chatDateToday.toUpperCase();
    if (diff == 1) return l10n.chatDateYesterday.toUpperCase();
    return DateFormat.yMd(l10n.localeName).format(local);
  }
}

// ── Day separator ────────────────────────────────────────────────

class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _line()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _scale(context, 12)),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _scale(context, 14),
              vertical: _scale(context, 6),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: const Color(0x734C2F15),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: _scale(context, 12),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: const Color(0xFFb9a48d),
              ),
            ),
          ),
        ),
        Expanded(child: _line()),
      ],
    );
  }

  Widget _line() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.08),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _ChatClosedTailNotice extends StatelessWidget {
  const _ChatClosedTailNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: _scale(context, 320)),
        padding: EdgeInsets.symmetric(
          horizontal: _scale(context, 16),
          vertical: _scale(context, 10),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_scale(context, 22)),
          color: AppColors.accent.withValues(alpha: 0.12),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_clock_rounded,
              size: _scale(context, 17),
              color: AppColors.accent,
            ),
            SizedBox(width: _scale(context, 8)),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _scale(context, 13),
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  color: const Color(0xFFf4bd74),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Message bubble ───────────────────────────────────────────────

const _nameColors = [
  Color(0xFF2d7dff),
  Color(0xFF00df85),
  Color(0xFFf4a020),
  Color(0xFFe040fb),
  Color(0xFF00bcd4),
  Color(0xFFff5252),
];

Color _nameColorFor(String userId) {
  var hash = 0;
  for (var i = 0; i < userId.length; i++) {
    hash = userId.codeUnitAt(i) + ((hash << 5) - hash);
  }
  return _nameColors[hash.abs() % _nameColors.length];
}

String _senderNameForMessage(
  MessageVm message,
  List<ParticipantInfo> participants,
  AppLocalizations l10n,
) {
  final participantName = participants
      .where((p) => p.userId == message.senderUserId)
      .firstOrNull
      ?.displayName
      .trim();
  if (participantName != null && participantName.isNotEmpty) {
    return participantName;
  }

  final messageName = message.senderDisplayName.trim();
  if (messageName.isNotEmpty) {
    return messageName;
  }

  return l10n.chatUserFallbackName;
}

String _messagePreviewText(MessageVm message, AppLocalizations l10n) {
  if (message.isDeleted) {
    return l10n.chatMessageDeleted;
  }

  final content = _singleLinePreview(message.content);
  if (content.isNotEmpty) {
    return content;
  }
  if (message.fileIds.isNotEmpty) return '';
  return l10n.chatReplyPreviewFallback;
}

MessageVm _pinnedMessageAsMessageVm(PinnedMessageInfo pinned) {
  return MessageVm(
    id: pinned.id,
    senderUserId: pinned.senderUserId,
    senderDisplayName: pinned.senderDisplayName,
    senderAvatarFileId: pinned.senderAvatarFileId,
    type: pinned.type,
    content: pinned.content,
    fileIds: pinned.fileIds,
    sentAt: pinned.sentAt,
  );
}

String _singleLinePreview(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}

class _ReplyPreviewCard extends StatelessWidget {
  const _ReplyPreviewCard({
    required this.senderName,
    required this.preview,
    required this.accentColor,
    this.onClose,
    this.onTap,
  });

  final String senderName;
  final Widget preview;
  final Color accentColor;
  final VoidCallback? onClose;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: _scale(context, 12),
        vertical: _scale(context, 10),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_scale(context, 16)),
        color: Colors.black.withValues(alpha: 0.16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: _scale(context, 4),
            height: _scale(context, 34),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: accentColor,
            ),
          ),
          SizedBox(width: _scale(context, 10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  senderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: _scale(context, 12),
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
                SizedBox(height: _scale(context, 2)),
                preview,
              ],
            ),
          ),
          if (onClose != null) ...[
            SizedBox(width: _scale(context, 8)),
            GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: _scale(context, 26),
                height: _scale(context, 26),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: _scale(context, 16),
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return child;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

class _ReplyPreviewText extends StatefulWidget {
  const _ReplyPreviewText({required this.message});

  final MessageVm message;

  @override
  State<_ReplyPreviewText> createState() => _ReplyPreviewTextState();
}

class _ReplyPreviewTextState extends State<_ReplyPreviewText> {
  late Future<FileMetadataVm?> _metadataFuture;

  @override
  void initState() {
    super.initState();
    _metadataFuture = _metadataFutureFor(widget.message);
  }

  @override
  void didUpdateWidget(covariant _ReplyPreviewText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_attachmentPreviewSignature(oldWidget.message) !=
        _attachmentPreviewSignature(widget.message)) {
      _metadataFuture = _metadataFutureFor(widget.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final syncPreview = _messagePreviewText(widget.message, l10n);
    final style = TextStyle(
      fontSize: _scale(context, 12),
      color: Colors.white.withValues(alpha: 0.74),
    );

    if (syncPreview.isNotEmpty) {
      return Text(
        syncPreview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    return FutureBuilder<FileMetadataVm?>(
      future: _metadataFuture,
      builder: (context, snapshot) {
        final preview = _attachmentReplyPreviewText(
          widget.message.fileIds.length,
          snapshot.data,
          l10n,
        );
        return Text(
          preview,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        );
      },
    );
  }

  Future<FileMetadataVm?> _metadataFutureFor(MessageVm message) {
    if (message.fileIds.isEmpty) {
      return Future<FileMetadataVm?>.value(null);
    }
    return _ReplyAttachmentPreviewCache.metadataFor(message.fileIds.first);
  }

  String _attachmentPreviewSignature(MessageVm message) {
    return message.fileIds.join(',');
  }
}

class _ReplyAttachmentPreviewCache {
  static final FileApi _fileApi = FileApi();
  static final Map<String, Future<FileMetadataVm?>> _metadataFutures = {};

  static Future<FileMetadataVm?> metadataFor(String fileId) {
    final normalizedId = fileId.trim();
    if (normalizedId.isEmpty) {
      return Future<FileMetadataVm?>.value(null);
    }

    return _metadataFutures.putIfAbsent(normalizedId, () async {
      try {
        return await _fileApi.getFileMetadata(normalizedId);
      } catch (_) {
        return null;
      }
    });
  }
}

String _attachmentReplyPreviewText(
  int filesCount,
  FileMetadataVm? metadata,
  AppLocalizations l10n,
) {
  String label;
  final originalName = metadata?.originalName.trim() ?? '';

  if (metadata?.isAudio ?? false) {
    label = l10n.chatVoiceMessage;
  } else if (originalName.isNotEmpty) {
    label = originalName;
  } else if ((metadata?.isImage ?? false) || (metadata?.isVideo ?? false)) {
    label = l10n.chatAttachmentPhotoVideo;
  } else {
    label = l10n.chatAttachmentFile;
  }

  if (filesCount > 1) {
    return '$label +${filesCount - 1}';
  }
  return label;
}

class _ReplySwipeBackground extends StatelessWidget {
  const _ReplySwipeBackground();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(left: _scale(context, 10)),
        child: Container(
          width: _scale(context, 38),
          height: _scale(context, 38),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent.withValues(alpha: 0.16),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.24)),
          ),
          child: Icon(
            Icons.reply_rounded,
            size: _scale(context, 20),
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.messageKey,
    required this.message,
    required this.isGroup,
    required this.isMine,
    required this.isHighlighted,
    required this.readByOthers,
    required this.showReadTicks,
    required this.participants,
    required this.repliedMessage,
    required this.onReply,
    required this.onLongPress,
    required this.onReplyPreviewTap,
    required this.l10n,
  });

  final GlobalKey messageKey;
  final MessageVm message;
  final bool isGroup;
  final bool isMine;
  final bool isHighlighted;
  final bool readByOthers;
  final bool showReadTicks;
  final List<ParticipantInfo> participants;
  final MessageVm? repliedMessage;
  final VoidCallback onReply;
  final VoidCallback? onLongPress;
  final VoidCallback? onReplyPreviewTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final senderParticipant = participants
        .where((p) => p.userId == message.senderUserId)
        .firstOrNull;
    final senderName = _senderNameForMessage(message, participants, l10n);
    final isDeleted = message.isDeleted;

    if (message.isSystem) {
      return _SystemMessageDivider(text: _systemMessageText(senderName, l10n));
    }

    final avatarSize = _scale(context, 44);
    final gap = _scale(context, 10);
    final content = KeyedSubtree(
      key: messageKey,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChatAvatar(
            size: avatarSize,
            name: senderName,
            avatarFileId:
                senderParticipant?.avatarFileId ?? message.senderAvatarFileId,
          ),
          SizedBox(width: gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meta: name + time + ticks
                Padding(
                  padding: EdgeInsets.only(
                    left: _scale(context, 4),
                    right: _scale(context, 4),
                    bottom: _scale(context, 8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          senderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: _scale(context, isGroup ? 20 : 16),
                            fontWeight: FontWeight.w800,
                            height: 1,
                            letterSpacing: -0.4,
                            color: _nameColorFor(message.senderUserId),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(message.sentAt),
                            style: TextStyle(
                              fontSize: _scale(context, 12),
                              color: Colors.white.withValues(alpha: 0.34),
                            ),
                          ),
                          if (isMine && showReadTicks && !isDeleted)
                            SizedBox(width: _scale(context, 6)),
                          if (isMine && showReadTicks && !isDeleted)
                            Text(
                              readByOthers ? '✓✓' : '✓',
                              style: TextStyle(
                                fontSize: _scale(context, 13),
                                fontWeight: FontWeight.w800,
                                color: readByOthers
                                    ? AppColors.accent
                                    : Colors.white.withValues(alpha: 0.35),
                                letterSpacing: -1,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Bubble
                AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  width: double.infinity,
                  padding: EdgeInsets.all(_scale(context, 20)),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_scale(context, 22)),
                    gradient: isDeleted
                        ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xA334271D),
                              const Color(0xD1261C15),
                            ],
                          )
                        : const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xA34D2D13), Color(0xD13C210D)],
                          ),
                    border: Border.all(
                      color: isHighlighted
                          ? AppColors.accent.withValues(alpha: 0.72)
                          : Colors.white.withValues(alpha: 0.05),
                      width: isHighlighted ? 1.4 : 1,
                    ),
                    boxShadow: isHighlighted
                        ? [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.22),
                              blurRadius: 24,
                              spreadRadius: 1,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isDeleted && message.replyToMessageId != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: _scale(context, 12)),
                          child: _ReplyPreviewCard(
                            senderName: repliedMessage == null
                                ? l10n.chatUserFallbackName
                                : _senderNameForMessage(
                                    repliedMessage!,
                                    participants,
                                    l10n,
                                  ),
                            preview: _ReplyPreviewText(
                              message:
                                  repliedMessage ??
                                  MessageVm(
                                    id: message.replyToMessageId!,
                                    senderUserId: '',
                                    senderDisplayName: '',
                                    type: 'text',
                                    content: '',
                                    sentAt: message.sentAt,
                                  ),
                            ),
                            accentColor: repliedMessage == null
                                ? AppColors.accent
                                : _nameColorFor(repliedMessage!.senderUserId),
                            onTap: onReplyPreviewTap,
                          ),
                        ),
                      if (!isDeleted && message.fileIds.isNotEmpty)
                        _MessageAttachments(fileIds: message.fileIds),
                      if (!isDeleted &&
                          message.fileIds.isNotEmpty &&
                          message.content.trim().isNotEmpty)
                        SizedBox(height: _scale(context, 12)),
                      if (isDeleted)
                        Text(
                          l10n.chatMessageDeleted,
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: _scale(context, 15),
                            height: 1.4,
                            color: Colors.white.withValues(alpha: 0.58),
                          ),
                        )
                      else if (message.content.trim().isNotEmpty)
                        Text(
                          message.content,
                          style: TextStyle(
                            fontSize: _scale(context, 16),
                            height: 1.5,
                            letterSpacing: -0.3,
                            color: Colors.white.withValues(alpha: 0.98),
                          ),
                        ),
                    ],
                  ),
                ),
                if (message.isEdited && !isDeleted)
                  Padding(
                    padding: EdgeInsets.only(
                      top: _scale(context, 3),
                      left: _scale(context, 4),
                    ),
                    child: Text(
                      l10n.chatEditedLabel,
                      style: TextStyle(
                        fontSize: _scale(context, 10),
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    return Dismissible(
      key: ValueKey('reply-${message.id}'),
      direction: DismissDirection.startToEnd,
      dismissThresholds: const {DismissDirection.startToEnd: 0.18},
      movementDuration: const Duration(milliseconds: 140),
      resizeDuration: null,
      confirmDismiss: (_) async {
        onReply();
        return false;
      },
      background: const _ReplySwipeBackground(),
      child: GestureDetector(
        onLongPress: isDeleted ? null : onLongPress,
        behavior: HitTestBehavior.opaque,
        child: content,
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return DateFormat.Hm(l10n.localeName).format(dt.toLocal());
  }

  String _systemMessageText(String senderName, AppLocalizations l10n) {
    final text = message.content.trim();

    if (text == 'User joined' || text == 'User joined the chat') {
      final name = _isConcreteSenderName(senderName)
          ? senderName
          : l10n.chatUserFallbackName;
      return l10n.chatSystemUserJoined(name);
    }
    if (text == 'User left' || text == 'User left the chat') {
      final name = _isConcreteSenderName(senderName)
          ? senderName
          : l10n.chatUserFallbackName;
      return l10n.chatSystemUserLeft(name);
    }

    if (text.endsWith(' joined')) {
      final name = text.substring(0, text.length - ' joined'.length).trim();
      if (name.isNotEmpty) {
        return l10n.chatSystemUserJoined(name);
      }
    }
    if (text.endsWith(' left')) {
      final name = text.substring(0, text.length - ' left'.length).trim();
      if (name.isNotEmpty) {
        return l10n.chatSystemUserLeft(name);
      }
    }

    return text;
  }

  bool _isConcreteSenderName(String senderName) {
    final normalized = senderName.trim().toLowerCase();
    return normalized.isNotEmpty &&
        normalized != 'user' &&
        normalized != 'system' &&
        message.senderUserId != '00000000-0000-0000-0000-000000000000';
  }
}

// ── System message ───────────────────────────────────────────────

class _SystemMessageDivider extends StatelessWidget {
  const _SystemMessageDivider({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = text.trim().isEmpty ? l10n.chatSystemUpdate : text.trim();

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: _scale(context, 300)),
        padding: EdgeInsets.symmetric(
          horizontal: _scale(context, 14),
          vertical: _scale(context, 7),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: const Color(0x8A4C2F15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: _scale(context, 12),
            fontWeight: FontWeight.w700,
            height: 1.15,
            letterSpacing: 0.2,
            color: const Color(0xFFc8b39a),
          ),
        ),
      ),
    );
  }
}

// ── Attachments ─────────────────────────────────────────────────

class _MessageAttachments extends StatefulWidget {
  const _MessageAttachments({required this.fileIds});

  final List<String> fileIds;

  @override
  State<_MessageAttachments> createState() => _MessageAttachmentsState();
}

class _MessageAttachmentsState extends State<_MessageAttachments> {
  final _fileApi = FileApi();
  final _fileCache = ChatFileCache();
  final Set<String> _busyFileIds = {};
  late Future<List<_ChatAttachmentViewData>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant _MessageAttachments oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileIds.join(',') != widget.fileIds.join(',')) {
      _future = _load();
    }
  }

  Future<List<_ChatAttachmentViewData>> _load() async {
    final ids = widget.fileIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);

    return Future.wait(ids.map(_loadOne));
  }

  Future<_ChatAttachmentViewData> _loadOne(String fileId) async {
    FileMetadataVm? metadata;
    Uint8List? imageBytes;
    var downloaded = false;

    try {
      metadata = await _fileApi.getFileMetadata(fileId);
      final localFile = await _fileCache.downloadedFile(
        fileId,
        metadata: metadata,
      );
      downloaded = localFile != null;

      if (metadata.isImage && localFile != null) {
        imageBytes = await localFile.file.readAsBytes();
      } else if (metadata.isImage) {
        final content = await _fileApi.downloadContent(fileId);
        imageBytes = content.bytes.isEmpty ? null : content.bytes;
      }
    } catch (_) {
      // Keep the message readable even if metadata is temporarily unavailable.
    }

    return _ChatAttachmentViewData(
      fileId: fileId,
      metadata: metadata,
      imageBytes: imageBytes,
      downloaded: downloaded,
    );
  }

  Future<void> _handleAttachmentTap(_ChatAttachmentViewData item) async {
    if (_busyFileIds.contains(item.fileId)) return;

    if (item.downloaded) {
      await _openDownloadedAttachment(item);
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    setState(() => _busyFileIds.add(item.fileId));

    try {
      if (item.imageBytes != null) {
        await _fileCache.saveBytes(
          item.fileId,
          bytes: item.imageBytes!,
          metadata: item.metadata,
        );
      } else {
        await _fileCache.download(item.fileId, metadata: item.metadata);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.chatAttachmentDownloaded),
          backgroundColor: const Color(0xFF3a2415),
        ),
      );
      setState(() {
        _future = _load();
      });
    } catch (e) {
      if (!mounted) return;
      final message = e is DioException
          ? DioErrorMapper.toMessage(e)
          : l10n.chatAttachmentDownloadFailed;
      await showErrorDialog(context, title: l10n.error, message: message);
    } finally {
      if (mounted) {
        setState(() => _busyFileIds.remove(item.fileId));
      }
    }
  }

  Future<void> _openDownloadedAttachment(_ChatAttachmentViewData item) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final downloaded = await _fileCache.downloadedFile(
        item.fileId,
        metadata: item.metadata,
      );
      if (!mounted) return;

      if (downloaded == null) {
        setState(() => _future = _load());
        return;
      }

      if (item.metadata?.isImage ?? false) {
        final bytes = await downloaded.file.readAsBytes();
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ChatImageViewerScreen(imageBytes: bytes),
          ),
        );
        return;
      }

      final result = await _fileCache.open(downloaded);
      if (!mounted || result.type == ResultType.done) return;

      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.chatAttachmentOpenFailed,
      );
    } catch (_) {
      if (!mounted) return;
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.chatAttachmentOpenFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_ChatAttachmentViewData>>(
      future: _future,
      builder: (context, snapshot) {
        final items =
            snapshot.data ??
            widget.fileIds
                .map(
                  (fileId) => _ChatAttachmentViewData(
                    fileId: fileId,
                    metadata: null,
                    imageBytes: null,
                    downloaded: false,
                  ),
                )
                .toList(growable: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              _AttachmentTile(
                item: items[i],
                busy: _busyFileIds.contains(items[i].fileId),
                onTap: () => _handleAttachmentTap(items[i]),
              ),
              if (i != items.length - 1) SizedBox(height: _scale(context, 10)),
            ],
          ],
        );
      },
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.item,
    required this.busy,
    required this.onTap,
  });

  final _ChatAttachmentViewData item;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metadata = item.metadata;
    final isImage = metadata?.isImage ?? false;
    final isAudio = metadata?.isAudio ?? false;
    final isVideo = metadata?.isVideo ?? false;

    if (isAudio) {
      return _VoiceAttachmentPlayer(item: item);
    }

    if (isImage && item.imageBytes != null) {
      return GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_scale(context, 18)),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(
                  item.imageBytes!,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
                Positioned(
                  right: _scale(context, 10),
                  bottom: _scale(context, 10),
                  child: _AttachmentDownloadBadge(
                    downloaded: item.downloaded,
                    busy: busy,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _AttachmentFileRow(
      item: item,
      showPlay: isVideo,
      busy: busy,
      onTap: onTap,
    );
  }
}

class _VoiceAttachmentPlayer extends StatefulWidget {
  const _VoiceAttachmentPlayer({required this.item});

  final _ChatAttachmentViewData item;

  @override
  State<_VoiceAttachmentPlayer> createState() => _VoiceAttachmentPlayerState();
}

class _VoiceAttachmentPlayerState extends State<_VoiceAttachmentPlayer> {
  final _fileCache = ChatFileCache();
  final _player = AudioPlayer();
  bool _preparing = false;
  int _prepareGeneration = 0;
  String? _preparedFileId;

  @override
  void dispose() {
    _prepareGeneration++;
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_preparing) {
      await _stopLoading();
      return;
    }

    int? prepareGeneration;
    try {
      final completed = _player.processingState == ProcessingState.completed;
      if (_player.playing && !completed) {
        await _player.pause();
        return;
      }

      if (_preparedFileId != widget.item.fileId) {
        prepareGeneration = ++_prepareGeneration;
        setState(() => _preparing = true);
        final downloaded = await _fileCache.download(
          widget.item.fileId,
          metadata: widget.item.metadata,
        );
        if (!mounted || prepareGeneration != _prepareGeneration) return;
        await _player.setFilePath(downloaded.file.path);
        if (!mounted || prepareGeneration != _prepareGeneration) return;
        _preparedFileId = widget.item.fileId;
        setState(() => _preparing = false);
      }
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }

      if (!mounted || _preparing) return;
      unawaited(_playPrepared(_prepareGeneration));
    } catch (_) {
      if (!mounted) return;
      await showErrorDialog(
        context,
        title: AppLocalizations.of(context)!.error,
        message: AppLocalizations.of(context)!.chatVoicePlaybackFailed,
      );
    } finally {
      if (mounted &&
          prepareGeneration != null &&
          prepareGeneration == _prepareGeneration &&
          _preparing) {
        setState(() => _preparing = false);
      }
    }
  }

  Future<void> _stopLoading() async {
    _prepareGeneration++;
    if (mounted) {
      setState(() => _preparing = false);
    }
    _preparedFileId = null;
    try {
      await _player.stop();
    } catch (_) {
      // The player may not have an active source yet.
    }
  }

  Future<void> _playPrepared(int generation) async {
    try {
      await _player.play();
    } catch (_) {
      if (!mounted || generation != _prepareGeneration) return;
      await showErrorDialog(
        context,
        title: AppLocalizations.of(context)!.error,
        message: AppLocalizations.of(context)!.chatVoicePlaybackFailed,
      );
    }
  }

  Future<void> _seekToFraction(double fraction, Duration duration) async {
    if (duration.inMilliseconds <= 0 || _preparing) return;
    final target = Duration(
      milliseconds: (duration.inMilliseconds * fraction.clamp(0.0, 1.0))
          .round(),
    );
    await _player.seek(target);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(_scale(context, 12)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_scale(context, 22)),
        color: Colors.black.withValues(alpha: 0.14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snapshot) {
              final processing = snapshot.data?.processingState;
              final busy =
                  _preparing ||
                  processing == ProcessingState.loading ||
                  processing == ProcessingState.buffering;
              final playing =
                  (snapshot.data?.playing ?? false) &&
                  processing != ProcessingState.completed;

              return GestureDetector(
                onTap: busy ? _stopLoading : _toggle,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: _scale(context, 48),
                  height: _scale(context, 48),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                  ),
                  child: Center(
                    child: busy
                        ? SizedBox(
                            width: _scale(context, 18),
                            height: _scale(context, 18),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: _scale(context, 30),
                            color: Colors.white,
                          ),
                  ),
                ),
              );
            },
          ),
          SizedBox(width: _scale(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.chatVoiceMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: _scale(context, 15),
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFf5ede6),
                  ),
                ),
                SizedBox(height: _scale(context, 8)),
                StreamBuilder<Duration>(
                  stream: _player.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration = _player.duration ?? Duration.zero;
                    final progress = duration.inMilliseconds <= 0
                        ? 0.0
                        : (position.inMilliseconds / duration.inMilliseconds)
                              .clamp(0.0, 1.0);

                    return Row(
                      children: [
                        Expanded(
                          child: _VoiceWaveform(
                            progress: progress,
                            enabled: duration.inMilliseconds > 0 && !_preparing,
                            onSeekFraction: (fraction) =>
                                _seekToFraction(fraction, duration),
                          ),
                        ),
                        if (duration.inMilliseconds > 0) ...[
                          SizedBox(width: _scale(context, 10)),
                          Text(
                            _formatVoiceDuration(
                              position == Duration.zero ? duration : position,
                            ),
                            style: TextStyle(
                              fontSize: _scale(context, 12),
                              fontWeight: FontWeight.w700,
                              color: const Color(
                                0xFFc8b39a,
                              ).withValues(alpha: 0.82),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceWaveform extends StatelessWidget {
  const _VoiceWaveform({
    required this.progress,
    this.enabled = false,
    this.onSeekFraction,
  });

  final double progress;
  final bool enabled;
  final ValueChanged<double>? onSeekFraction;

  @override
  Widget build(BuildContext context) {
    const bars = [0.25, 0.45, 0.72, 0.38, 0.9, 0.56, 0.34, 0.68, 0.48, 0.8];
    final activeBars = (bars.length * progress).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        void seekAt(Offset localPosition) {
          final width = constraints.maxWidth;
          if (!enabled || onSeekFraction == null || width <= 0) return;
          onSeekFraction!((localPosition.dx / width).clamp(0.0, 1.0));
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled
              ? (details) => seekAt(details.localPosition)
              : null,
          onHorizontalDragStart: enabled
              ? (details) => seekAt(details.localPosition)
              : null,
          onHorizontalDragUpdate: enabled
              ? (details) => seekAt(details.localPosition)
              : null,
          child: SizedBox(
            height: _scale(context, 28),
            child: Row(
              children: [
                for (var i = 0; i < bars.length; i++) ...[
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: FractionallySizedBox(
                        heightFactor: bars[i],
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: i < activeBars
                                ? AppColors.accent
                                : Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (i != bars.length - 1) SizedBox(width: _scale(context, 4)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AttachmentFileRow extends StatelessWidget {
  const _AttachmentFileRow({
    required this.item,
    required this.busy,
    required this.onTap,
    this.showPlay = false,
  });

  final _ChatAttachmentViewData item;
  final bool busy;
  final VoidCallback onTap;
  final bool showPlay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final metadata = item.metadata;
    final name = (metadata?.originalName.trim().isNotEmpty ?? false)
        ? metadata!.originalName.trim()
        : l10n.chatSharedFileFallback(_shortFileId(item.fileId));
    final meta = metadata == null
        ? l10n.chatSharedUnknownFile
        : '${_formatAttachmentSize(metadata.sizeBytes)} | ${metadata.extensionLabel}';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(_scale(context, 12)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_scale(context, 18)),
          color: Colors.black.withValues(alpha: 0.14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: _scale(context, 46),
              height: _scale(context, 46),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_scale(context, 14)),
                color: const Color(0xFF3a2415),
              ),
              child: Icon(
                showPlay ? Icons.play_arrow_rounded : _attachmentIcon(metadata),
                color: _attachmentIconColor(metadata),
                size: _scale(context, 26),
              ),
            ),
            SizedBox(width: _scale(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: _scale(context, 15),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFf5ede6),
                    ),
                  ),
                  SizedBox(height: _scale(context, 4)),
                  Text(
                    '${_downloadStatusLabel(context, item.downloaded, busy)} | $meta',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: _scale(context, 12),
                      color: const Color(0xFFc8b39a).withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: _scale(context, 10)),
            _AttachmentDownloadBadge(downloaded: item.downloaded, busy: busy),
          ],
        ),
      ),
    );
  }
}

class _AttachmentDownloadBadge extends StatelessWidget {
  const _AttachmentDownloadBadge({
    required this.downloaded,
    required this.busy,
  });

  final bool downloaded;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _scale(context, 34),
      height: _scale(context, 34),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: downloaded ? AppColors.accent : const Color(0xE62D1A0D),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Center(
        child: busy
            ? SizedBox(
                width: _scale(context, 16),
                height: _scale(context, 16),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                downloaded
                    ? Icons.open_in_full_rounded
                    : Icons.download_rounded,
                size: _scale(context, 17),
                color: Colors.white,
              ),
      ),
    );
  }
}

class _ChatAttachmentViewData {
  const _ChatAttachmentViewData({
    required this.fileId,
    required this.metadata,
    required this.imageBytes,
    required this.downloaded,
  });

  final String fileId;
  final FileMetadataVm? metadata;
  final Uint8List? imageBytes;
  final bool downloaded;
}

IconData _attachmentIcon(FileMetadataVm? metadata) {
  final extension = metadata?.extensionLabel.toLowerCase() ?? '';
  if (extension == 'pdf') return Icons.picture_as_pdf_rounded;
  if (extension == 'zip' || extension == 'rar' || extension == '7z') {
    return Icons.archive_rounded;
  }
  if (extension == 'xls' || extension == 'xlsx' || extension == 'csv') {
    return Icons.table_chart_rounded;
  }
  if (extension == 'doc' || extension == 'docx' || extension == 'txt') {
    return Icons.article_rounded;
  }
  if (metadata?.isAudio ?? false) return Icons.mic_rounded;
  if (metadata?.isVideo ?? false) return Icons.movie_rounded;
  if (metadata?.isImage ?? false) return Icons.image_rounded;
  return Icons.description_rounded;
}

Color _attachmentIconColor(FileMetadataVm? metadata) {
  final extension = metadata?.extensionLabel.toLowerCase() ?? '';
  if (extension == 'zip' || extension == 'rar' || extension == '7z') {
    return const Color(0xFF9fd0ff);
  }
  if (extension == 'xls' || extension == 'xlsx' || extension == 'csv') {
    return const Color(0xFFf0b983);
  }
  return AppColors.accent;
}

String _formatAttachmentSize(int bytes) {
  if (bytes <= 0) return '0 KB';
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }
  final fractionDigits = value >= 10 || unitIndex == 0 ? 0 : 1;
  return '${value.toStringAsFixed(fractionDigits)} ${units[unitIndex]}';
}

String _formatVoiceDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

String _downloadStatusLabel(BuildContext context, bool downloaded, bool busy) {
  final l10n = AppLocalizations.of(context)!;
  if (busy) return l10n.chatAttachmentDownloading;
  return downloaded
      ? l10n.chatAttachmentDownloadedStatus
      : l10n.chatAttachmentNotDownloadedStatus;
}

String _shortFileId(String id) {
  final value = id.trim();
  if (value.length <= 8) return value;
  return value.substring(0, 8);
}

// ── Avatar ────────────────────────────────────────────────────────

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({
    required this.size,
    required this.name,
    this.avatarFileId,
  });

  final double size;
  final String name;
  final String? avatarFileId;

  @override
  Widget build(BuildContext context) {
    final url = resolvePublicFileContentUrl(avatarFileId?.trim() ?? '');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: url == null
            ? const LinearGradient(
                begin: Alignment(-0.3, -0.4),
                end: Alignment(0.8, 1),
                colors: [
                  Color(0xFFf3d7b3),
                  Color(0xFFca9a6d),
                  Color(0xFF6f3f22),
                ],
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: url == null
            ? Center(
                child: Text(
                  _initial,
                  style: TextStyle(
                    fontSize: size * 0.38,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2b1606),
                  ),
                ),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    _initial,
                    style: TextStyle(
                      fontSize: size * 0.38,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2b1606),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  String get _initial {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }
}

// ── Composer ──────────────────────────────────────────────────────

class _ClosedComposerNotice extends StatelessWidget {
  const _ClosedComposerNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: _scale(context, 14),
        vertical: _scale(context, 10),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_scale(context, 18)),
        color: AppColors.accent.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: _scale(context, 13),
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: const Color(0xFFf4bd74),
        ),
      ),
    );
  }
}

class _PendingAttachmentsStrip extends StatelessWidget {
  const _PendingAttachmentsStrip({
    required this.attachments,
    required this.uploading,
    required this.onRemove,
  });

  final List<_PickedChatAttachment> attachments;
  final bool uploading;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _scale(context, 88),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: attachments.length,
        separatorBuilder: (_, __) => SizedBox(width: _scale(context, 10)),
        itemBuilder: (context, index) {
          final item = attachments[index];
          return _PendingAttachmentChip(
            attachment: item,
            uploading: uploading,
            onRemove: () => onRemove(item.localId),
          );
        },
      ),
    );
  }
}

class _PendingAttachmentChip extends StatelessWidget {
  const _PendingAttachmentChip({
    required this.attachment,
    required this.uploading,
    required this.onRemove,
  });

  final _PickedChatAttachment attachment;
  final bool uploading;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final width = _scale(context, attachment.isImage ? 118 : 184);

    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_scale(context, 20)),
        color: const Color(0xD12D1A0D),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: _PendingAttachmentPreview(attachment)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.02),
                    Colors.black.withValues(alpha: 0.64),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: _scale(context, 10),
            right: _scale(context, 34),
            bottom: _scale(context, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: _scale(context, 12),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: _scale(context, 2)),
                Text(
                  '${_formatAttachmentSize(attachment.bytes.lengthInBytes)} | ${attachment.extensionLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: _scale(context, 10),
                    color: Colors.white.withValues(alpha: 0.76),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: _scale(context, 7),
            right: _scale(context, 7),
            child: GestureDetector(
              onTap: uploading ? null : onRemove,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: _scale(context, 26),
                height: _scale(context, 26),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.58),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: _scale(context, 17),
                ),
              ),
            ),
          ),
          if (uploading)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.34),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PendingAttachmentPreview extends StatelessWidget {
  const _PendingAttachmentPreview(this.attachment);

  final _PickedChatAttachment attachment;

  @override
  Widget build(BuildContext context) {
    if (attachment.isImage) {
      return Image.memory(
        attachment.bytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4b2d13), Color(0xFF1c0f08)],
        ),
      ),
      child: Center(
        child: Icon(
          attachment.isVideo
              ? Icons.movie_rounded
              : Icons.insert_drive_file_rounded,
          size: _scale(context, 34),
          color: AppColors.accent,
        ),
      ),
    );
  }
}

class _VoiceRecordingBar extends StatelessWidget {
  const _VoiceRecordingBar({
    required this.duration,
    required this.stopping,
    required this.onCancel,
    required this.onSend,
  });

  final Duration duration;
  final bool stopping;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final btnSize = _scale(context, 50);

    return Row(
      children: [
        GestureDetector(
          onTap: stopping ? null : onCancel,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: btnSize,
            height: btnSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xD136230F),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              color: Colors.white.withValues(alpha: stopping ? 0.34 : 0.9),
              size: _scale(context, 22),
            ),
          ),
        ),
        SizedBox(width: _scale(context, 10)),
        Expanded(
          child: Container(
            height: btnSize,
            padding: EdgeInsets.symmetric(horizontal: _scale(context, 16)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: const Color(0xB8412A18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
            ),
            child: Row(
              children: [
                _RecordingPulse(stopping: stopping),
                SizedBox(width: _scale(context, 10)),
                Expanded(
                  child: Text(
                    stopping
                        ? l10n.chatAttachmentUploading
                        : l10n.chatVoiceRecording,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: _scale(context, 15),
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFf5ede6),
                    ),
                  ),
                ),
                SizedBox(width: _scale(context, 10)),
                Text(
                  _formatVoiceDuration(duration),
                  style: TextStyle(
                    fontSize: _scale(context, 15),
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: _scale(context, 10)),
        GestureDetector(
          onTap: stopping ? null : onSend,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: btnSize,
            height: btnSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent,
            ),
            child: Center(
              child: stopping
                  ? SizedBox(
                      width: _scale(context, 20),
                      height: _scale(context, 20),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: _scale(context, 22),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecordingPulse extends StatelessWidget {
  const _RecordingPulse({required this.stopping});

  final bool stopping;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _scale(context, 12),
      height: _scale(context, 12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: stopping ? Colors.white.withValues(alpha: 0.4) : Colors.red,
        boxShadow: stopping
            ? null
            : [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.35),
                  blurRadius: 12,
                  spreadRadius: 4,
                ),
              ],
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.focusNode,
    required this.pendingAttachments,
    required this.replyToMessage,
    required this.participants,
    required this.onSend,
    required this.onTyping,
    required this.onPickMedia,
    required this.onPickFile,
    required this.onRemoveAttachment,
    required this.onCancelReply,
    required this.onVoiceStart,
    required this.onVoiceCancel,
    required this.onVoiceSend,
    required this.sending,
    required this.attachmentUploading,
    required this.voiceRecording,
    required this.voiceStopping,
    required this.voiceDuration,
    required this.messagingClosed,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<_PickedChatAttachment> pendingAttachments;
  final MessageVm? replyToMessage;
  final List<ParticipantInfo> participants;
  final VoidCallback onSend;
  final VoidCallback onTyping;
  final VoidCallback onPickMedia;
  final VoidCallback onPickFile;
  final ValueChanged<int> onRemoveAttachment;
  final VoidCallback onCancelReply;
  final VoidCallback onVoiceStart;
  final VoidCallback onVoiceCancel;
  final VoidCallback onVoiceSend;
  final bool sending;
  final bool attachmentUploading;
  final bool voiceRecording;
  final bool voiceStopping;
  final Duration voiceDuration;
  final bool messagingClosed;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final hz = _scale(context, 12);
    final btnSize = _scale(context, 50);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.fromLTRB(
        hz,
        _scale(context, 12),
        hz,
        _scale(context, 14) + mq.padding.bottom,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        color: const Color(0xB8140B06),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (messagingClosed) ...[
            _ClosedComposerNotice(text: l10n.chatActivityChatClosed),
            SizedBox(height: _scale(context, 10)),
          ],
          if (replyToMessage != null) ...[
            _ReplyPreviewCard(
              senderName: _senderNameForMessage(
                replyToMessage!,
                participants,
                l10n,
              ),
              preview: _ReplyPreviewText(message: replyToMessage!),
              accentColor: _nameColorFor(replyToMessage!.senderUserId),
              onClose: onCancelReply,
            ),
            SizedBox(height: _scale(context, 10)),
          ],
          if (pendingAttachments.isNotEmpty) ...[
            _PendingAttachmentsStrip(
              attachments: pendingAttachments,
              uploading: attachmentUploading,
              onRemove: onRemoveAttachment,
            ),
            SizedBox(height: _scale(context, 10)),
          ],
          if (voiceRecording) ...[
            _VoiceRecordingBar(
              duration: voiceDuration,
              stopping: voiceStopping,
              onCancel: onVoiceCancel,
              onSend: onVoiceSend,
            ),
          ] else
            Row(
              children: [
                GestureDetector(
                  onTap: attachmentUploading || messagingClosed
                      ? null
                      : () => _showAttachmentPicker(context, l10n),
                  child: Container(
                    width: btnSize,
                    height: btnSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xD136230F),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: attachmentUploading
                          ? SizedBox(
                              width: _scale(context, 20),
                              height: _scale(context, 20),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.accent,
                              ),
                            )
                          : Text(
                              '+',
                              style: TextStyle(
                                fontSize: _scale(context, 24),
                                fontWeight: FontWeight.w300,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                    ),
                  ),
                ),
                SizedBox(width: _scale(context, 10)),
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(minHeight: btnSize),
                    padding: EdgeInsets.symmetric(
                      horizontal: _scale(context, 18),
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: const Color(0xB8412A18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.03),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            onChanged: (_) => onTyping(),
                            onSubmitted: (_) => onSend(),
                            textInputAction: TextInputAction.send,
                            maxLines: 4,
                            minLines: 1,
                            textAlignVertical: TextAlignVertical.center,
                            enabled: !attachmentUploading && !messagingClosed,
                            style: TextStyle(
                              fontSize: _scale(context, 15),
                              color: const Color(0xFFf5f3ef),
                              letterSpacing: -0.3,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: _scale(context, 14),
                              ),
                              hintText: messagingClosed
                                  ? l10n.chatComposerClosedHint
                                  : attachmentUploading
                                  ? l10n.chatAttachmentUploading
                                  : l10n.chatComposerHint,
                              hintStyle: TextStyle(
                                fontSize: _scale(context, 15),
                                color: Colors.white.withValues(alpha: 0.48),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: messagingClosed
                              ? null
                              : () => focusNode.requestFocus(),
                          child: Text(
                            '☺',
                            style: TextStyle(
                              fontSize: _scale(context, 22),
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: _scale(context, 10)),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    final hasDraft =
                        value.text.trim().isNotEmpty ||
                        pendingAttachments.isNotEmpty;
                    final disabled =
                        sending || attachmentUploading || messagingClosed;
                    final showMic = !hasDraft;

                    return GestureDetector(
                      onTap: disabled
                          ? null
                          : showMic
                          ? onVoiceStart
                          : onSend,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: btnSize,
                        height: btnSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: showMic
                              ? AppColors.accent
                              : const Color(0xFFff9d00),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.28),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: sending || attachmentUploading
                              ? SizedBox(
                                  width: _scale(context, 20),
                                  height: _scale(context, 20),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  showMic
                                      ? Icons.mic_rounded
                                      : Icons.send_rounded,
                                  color: Colors.white.withValues(
                                    alpha: disabled ? 0.36 : 1,
                                  ),
                                  size: _scale(context, showMic ? 24 : 22),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showAttachmentPicker(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1d120b),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: Color(0xFFff9800),
                ),
                title: Text(
                  l10n.chatAttachmentPhotoVideo,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onPickMedia();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.insert_drive_file_rounded,
                  color: Color(0xFFff9800),
                ),
                title: Text(
                  l10n.chatAttachmentFile,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onPickFile();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Loading / Error states ───────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF100802),
      body: Center(child: CircularProgressIndicator(color: Color(0xFFff9800))),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF100802),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: _scale(context, 42),
              color: const Color(0xFF94A3B8),
            ),
            SizedBox(height: _scale(context, 14)),
            Text(
              l10n.chatLoadFailed,
              style: TextStyle(
                color: const Color(0xFF94A3B8),
                fontSize: _scale(context, 15),
              ),
            ),
            SizedBox(height: _scale(context, 14)),
            TextButton(
              onPressed: onRetry,
              child: Text(
                l10n.retryButton,
                style: TextStyle(
                  color: const Color(0xFFff9800),
                  fontSize: _scale(context, 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
