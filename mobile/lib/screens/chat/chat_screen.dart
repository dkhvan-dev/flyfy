import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../core/files/chat_file_cache.dart';
import '../../core/network/dio_error_mapper.dart';
import '../../core/network/file_api.dart';
import '../../core/network/sticker_api.dart';
import '../../core/platform/clipboard_media_service.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/error_dialog.dart';
import '../../features/chat/models/conversation_vm.dart';
import '../../features/chat/models/message_vm.dart';
import '../../features/chat/models/sticker_pack_vm.dart';
import '../../features/chat/utils/chat_link_utils.dart';
import '../../features/chat/utils/chat_presence_status.dart';
import '../../features/chat/utils/sticker_asset_format.dart';
import '../../features/chat/utils/sticker_pack_ordering.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/chat_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/sticker_catalog_provider.dart';
import 'chat_camera_screen.dart';
import 'chat_image_viewer_screen.dart';
import 'chat_participants_screen.dart';
import 'chat_shared_content_screen.dart';
import 'chat_video_viewer_screen.dart';
import 'widgets/chat_video_preview.dart';
import 'widgets/chat_voice_attachment_player.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    this.conversationId,
    this.activityId,
    this.initialMessageId,
  }) : assert(conversationId != null || activityId != null);

  final String? conversationId;
  final String? activityId;
  final String? initialMessageId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _maxChatAttachmentBytes = 25 * 1024 * 1024;
  static const _stickerImageWarmupLimit = 180;
  static const _stickerImageWarmupConcurrency = 6;
  static const _messageActionSheetMaxHeightFactor = 0.82;
  static const _audioFileTypeGroups = [
    file_selector.XTypeGroup(
      label: 'Audio',
      extensions: ['aac', 'flac', 'm4a', 'mp3', 'ogg', 'wav'],
      mimeTypes: ['audio/*'],
      uniformTypeIdentifiers: ['public.audio'],
    ),
  ];

  final _fileApi = FileApi();
  final _stickerApi = StickerApi();
  final _clipboardMediaService = ClipboardMediaService();
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
  bool _voiceRecordingLocked = false;
  bool _voicePressActive = false;
  bool _voiceStopping = false;
  DateTime? _voiceRecordingStartedAt;
  Duration _voiceRecordingDuration = Duration.zero;
  MessageVm? _replyToMessage;
  String? _highlightedMessageId;
  int _pinnedMessageIndex = 0;
  _ComposerPanel _activeComposerPanel = _ComposerPanel.none;
  List<StickerPackVm> _stickerPacks = const [];
  bool _stickersLoading = false;
  bool _stickersLoadFailed = false;
  int _activeStickerPackIndex = 0;
  String? _stickerWarmLocale;
  bool _initialMessageScrollHandled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openConversation();
    });
    _scrollController.addListener(_onScroll);
    _focusNode.addListener(_handleComposerFocusChanged);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.removeListener(_handleComposerFocusChanged);
    _focusNode.dispose();
    _typingDebounce?.cancel();
    _messagingWindowTimer?.cancel();
    _messageHighlightTimer?.cancel();
    _voiceRecordingTimer?.cancel();
    unawaited(_disposeVoiceRecorder());
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode;
    if (_stickerWarmLocale == locale) return;
    _stickerWarmLocale = locale;
    unawaited(_warmUpStickerPicker(locale));
  }

  void _handleComposerFocusChanged() {
    if (!_focusNode.hasFocus || _activeComposerPanel == _ComposerPanel.none) {
      return;
    }
    setState(() => _activeComposerPanel = _ComposerPanel.none);
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
      _scheduleInitialMessageScroll();
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
    final chatProvider = context.read<ChatProvider>();

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

      final sent = await chatProvider.sendMessage(
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
      for (final attachment in attachments) {
        unawaited(_deleteLocalAttachmentFile(attachment));
      }
      chatProvider.markAsRead();
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

  // _pickAttachments dispatches to the right native picker based on `type`.
  // The collected attachments are pushed onto _pendingAttachments and shown
  // in the strip above the composer until the user hits send (or removes them).
  Future<void> _pickAttachments(_AttachmentPickType type) async {
    if (_attachmentUploading) return;
    if (!_canSendInActiveConversation()) {
      _showChatClosedMessage();
      return;
    }

    FocusScope.of(context).unfocus();
    _hideComposerPanel();
    final l10n = AppLocalizations.of(context)!;

    try {
      final attachments = <_PickedChatAttachment>[];

      switch (type) {
        case _AttachmentPickType.gallery:
          // pickMultipleMedia uses the system PHPicker (iOS) / PhotoPicker
          // (Android 13+) — no runtime permission needed.
          final picker = ImagePicker();
          final picked = await picker.pickMultipleMedia();
          if (!mounted || picked.isEmpty) return;
          for (final x in picked) {
            final att = await _attachmentFromXFile(x, ++_pendingAttachmentSeq);
            if (!mounted) return;
            if (att == null) {
              await _showAttachmentError(l10n.chatAttachmentUnsupported);
              return;
            }
            if (att.bytes.lengthInBytes > _maxChatAttachmentBytes) {
              await _showAttachmentError(l10n.chatAttachmentTooLarge);
              return;
            }
            attachments.add(att);
          }

        case _AttachmentPickType.file:
        case _AttachmentPickType.audio:
          final picked = await file_selector.openFiles(
            acceptedTypeGroups: type == _AttachmentPickType.audio
                ? _audioFileTypeGroups
                : const <file_selector.XTypeGroup>[],
          );
          if (!mounted || picked.isEmpty) return;
          for (final file in picked) {
            final att = await _attachmentFromXFile(
              file,
              ++_pendingAttachmentSeq,
            );
            if (!mounted) return;
            if (att == null) {
              await _showAttachmentError(l10n.chatAttachmentUnsupported);
              return;
            }
            if (att.bytes.lengthInBytes > _maxChatAttachmentBytes) {
              await _showAttachmentError(l10n.chatAttachmentTooLarge);
              return;
            }
            attachments.add(att);
          }
      }

      if (!mounted || attachments.isEmpty) return;

      // Final guard in case a picker implementation skips earlier checks.
      for (final att in attachments) {
        if (att.bytes.lengthInBytes > _maxChatAttachmentBytes) {
          await _showAttachmentError(l10n.chatAttachmentTooLarge);
          return;
        }
      }

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

  Future<void> _captureCameraAttachment() async {
    if (_attachmentUploading) return;
    if (!_canSendInActiveConversation()) {
      _showChatClosedMessage();
      return;
    }

    FocusScope.of(context).unfocus();
    _hideComposerPanel();
    final l10n = AppLocalizations.of(context)!;

    try {
      final captured = await Navigator.of(context).push<XFile>(
        MaterialPageRoute(
          builder: (_) =>
              const ChatCameraScreen(maxVideoDuration: Duration(minutes: 5)),
        ),
      );

      if (!mounted || captured == null) return;

      final attachment = await _attachmentFromXFile(
        captured,
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

      setState(() => _pendingAttachments.add(attachment));
      _focusNode.requestFocus();
    } catch (_) {
      if (!mounted) return;
      await _showAttachmentError(l10n.chatCameraCaptureFailed);
    }
  }

  // _attachmentFromXFile handles XFile from gallery and the chat camera.
  // It falls back to the file's MIME type when the extension isn't in our
  // allowlist (e.g. iOS may hand us a video file with no extension at all).
  Future<_PickedChatAttachment?> _attachmentFromXFile(
    XFile file,
    int localId,
  ) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return null;

    var name = file.name.trim();
    if (name.isEmpty || !name.contains('.')) {
      // Synthesize a sensible filename for captured media so the server can
      // detect the type even when the platform returns a bare temp path.
      final mime = file.mimeType ?? '';
      final ext = _extensionForMime(mime) ?? 'bin';
      name = 'media_${DateTime.now().millisecondsSinceEpoch}.$ext';
    }

    final contentType =
        _contentTypeForFileName(name) ??
        file.mimeType ??
        'application/octet-stream';

    return _PickedChatAttachment(
      localId: localId,
      name: name,
      bytes: bytes,
      contentType: contentType,
      localPath: file.path,
    );
  }

  _PickedChatAttachment? _attachmentFromClipboardImage(
    ClipboardMediaItem item,
    int localId,
  ) {
    if (!item.isImage || item.bytes.isEmpty) {
      return null;
    }
    final contentType = item.contentType.trim().toLowerCase();
    final ext = _extensionForMime(contentType) ?? 'png';
    var name = item.name.trim();
    if (name.isEmpty || !name.contains('.')) {
      name = 'clipboard_${DateTime.now().millisecondsSinceEpoch}.$ext';
    }

    return _PickedChatAttachment(
      localId: localId,
      name: name,
      bytes: item.bytes,
      contentType: contentType,
    );
  }

  Future<void> _handlePasteRequested() async {
    if (_attachmentUploading || !_canSendInActiveConversation()) {
      if (!_canSendInActiveConversation()) {
        _showChatClosedMessage();
      }
      return;
    }

    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    if ((text ?? '').isNotEmpty) {
      _insertComposerToken(_messageController, text!);
      _handleTyping();
      return;
    }

    await _handlePasteImageRequested();
  }

  Future<void> _handlePasteImageRequested() async {
    if (_attachmentUploading) return;
    if (!_canSendInActiveConversation()) {
      _showChatClosedMessage();
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    try {
      final item = await _clipboardMediaService.readImage();
      if (!mounted) return;
      if (item == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.chatClipboardEmpty),
            backgroundColor: const Color(0xFF3a2415),
          ),
        );
        return;
      }

      final attachment = _attachmentFromClipboardImage(
        item,
        ++_pendingAttachmentSeq,
      );
      if (attachment == null) {
        await _showAttachmentError(l10n.chatAttachmentUnsupported);
        return;
      }
      if (attachment.bytes.lengthInBytes > _maxChatAttachmentBytes) {
        await _showAttachmentError(l10n.chatAttachmentTooLarge);
        return;
      }

      await _showPastedImageConfirmation(attachment);
    } catch (_) {
      if (!mounted) return;
      await _showAttachmentError(l10n.chatAttachmentUploadFailed);
    }
  }

  Future<void> _showPastedImageConfirmation(
    _PickedChatAttachment attachment,
  ) async {
    if (!mounted) return;
    final shouldSend = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (sheetContext) {
        return _PastedImagePreviewSheet(attachment: attachment);
      },
    );
    if (!mounted || shouldSend != true) return;

    setState(() => _pendingAttachments.add(attachment));
    await _handleSend();
  }

  void _removePendingAttachment(int localId) {
    if (_attachmentUploading) return;
    final attachmentsToDelete = _pendingAttachments
        .where(
          (item) =>
              item.localId == localId &&
              item.deleteLocalFileOnRemove &&
              (item.localPath?.trim().isNotEmpty ?? false),
        )
        .toList(growable: false);
    setState(() {
      _pendingAttachments.removeWhere((item) => item.localId == localId);
    });
    for (final attachment in attachmentsToDelete) {
      unawaited(_deleteLocalAttachmentFile(attachment));
    }
  }

  Future<void> _deleteLocalAttachmentFile(
    _PickedChatAttachment attachment,
  ) async {
    final path = attachment.localPath?.trim() ?? '';
    if (!attachment.deleteLocalFileOnRemove || path.isEmpty) return;
    try {
      await File(path).delete();
    } catch (_) {
      // Temp file may already be gone; cleanup is best-effort.
    }
  }

  Future<void> _startVoiceRecording({
    bool locked = false,
    bool pressActive = false,
  }) async {
    if (_voiceRecording || _voiceStopping || _attachmentUploading) return;
    if (!_canSendInActiveConversation()) {
      _showChatClosedMessage();
      return;
    }

    FocusScope.of(context).unfocus();
    _hideComposerPanel();
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
          '${dir.path}/inflap_voice_${DateTime.now().microsecondsSinceEpoch}.m4a';
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
        _voiceRecordingLocked = locked;
        _voicePressActive = pressActive && !locked;
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

  void _lockVoiceRecording() {
    if (!_voiceRecording || _voiceStopping || _voiceRecordingLocked) return;
    setState(() {
      _voiceRecordingLocked = true;
      _voicePressActive = false;
    });
  }

  Future<void> _cancelVoiceRecording() async {
    await _resetVoiceRecording(cancelRecorder: true);
  }

  Future<void> _stopVoiceRecordingForPreview() async {
    if (!_voiceRecording || _voiceStopping) return;
    if (!_canSendInActiveConversation()) {
      _showChatClosedMessage();
      await _resetVoiceRecording(cancelRecorder: true);
      return;
    }

    final l10n = AppLocalizations.of(context)!;
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
        _voiceRecordingLocked = false;
        _voicePressActive = false;
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
      if (bytes.lengthInBytes > _maxChatAttachmentBytes) {
        unawaited(file.delete().catchError((_) => file));
        await _showAttachmentError(l10n.chatAttachmentTooLarge);
        return;
      }

      if (!mounted) return;
      final attachment = _PickedChatAttachment(
        localId: ++_pendingAttachmentSeq,
        name:
            'voice_${DateTime.now().millisecondsSinceEpoch}_${duration.inSeconds}s.m4a',
        bytes: bytes,
        contentType: 'audio/mp4',
        localPath: path,
        duration: duration,
        deleteLocalFileOnRemove: true,
      );
      setState(() => _pendingAttachments.add(attachment));
      _focusNode.requestFocus();
    } catch (_) {
      if (!mounted) return;
      await _showAttachmentError(l10n.chatVoiceRecordFailed);
    } finally {
      if (mounted) {
        setState(() => _voiceStopping = false);
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
      _voiceRecordingLocked = false;
      _voicePressActive = false;
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

  Future<void> _showDirectChatActions(
    ConversationDetail conversation,
    String currentUserId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final peerUserId = conversation.directPeer(currentUserId)?.userId.trim();
    if (peerUserId == null || peerUserId.isEmpty) return;

    final isBlocked = conversation.isBlockedByMe;
    final shouldBlock = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: true,
      backgroundColor: const Color(0xFF1d120b),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: _scale(context, 8)),
            child: ListTile(
              leading: Icon(
                isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                color: isBlocked ? AppColors.accent : AppColors.destruct,
              ),
              title: Text(
                isBlocked
                    ? l10n.chatUnblockUserAction
                    : l10n.chatBlockUserAction,
                style: TextStyle(
                  color: isBlocked ? AppColors.textPrimary : AppColors.destruct,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onTap: () => Navigator.of(sheetContext).pop(!isBlocked),
            ),
          ),
        );
      },
    );
    if (shouldBlock == null || !mounted) return;

    final provider = context.read<ChatProvider>();
    final status = shouldBlock
        ? await provider.blockUser(peerUserId)
        : await provider.unblockUser(peerUserId);
    if (status == null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.chatUserBlockUpdateFailed)));
    }
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
    _hideComposerPanel();
    setState(() => _replyToMessage = message);
    _focusNode.requestFocus();
  }

  void _clearReplyMessage() {
    if (_replyToMessage == null) return;
    setState(() => _replyToMessage = null);
  }

  void _setComposerPanel(_ComposerPanel panel) {
    if (_activeComposerPanel == panel) return;

    if (panel != _ComposerPanel.none) {
      FocusScope.of(context).unfocus();
      unawaited(
        _warmUpStickerPicker(Localizations.localeOf(context).languageCode),
      );
    }

    setState(() => _activeComposerPanel = panel);
  }

  void _hideComposerPanel() {
    if (_activeComposerPanel == _ComposerPanel.none) return;
    setState(() => _activeComposerPanel = _ComposerPanel.none);
  }

  void _handleEmojiSelected(String emoji) {
    _insertComposerToken(_messageController, emoji);
    _handleTyping();
  }

  Future<void> _warmUpStickerPicker(String locale) async {
    await _loadStickerPacks(locale: locale, force: false, silent: true);
    if (!mounted) return;
    await _precacheStickerImages(_prioritizedStickerWarmupList(_stickerPacks));
  }

  Future<void> _precacheStickerImages(
    List<StickerVm> stickers, {
    int limit = _stickerImageWarmupLimit,
  }) async {
    if (stickers.isEmpty) return;
    await _StickerImageCache.preload(
      stickers.map((sticker) => sticker.fileId),
      limit: limit,
      concurrency: _stickerImageWarmupConcurrency,
    );
  }

  List<StickerVm> _prioritizedStickerWarmupList(List<StickerPackVm> packs) {
    if (packs.isEmpty) return const [];

    final safeIndex = _activeStickerPackIndex
        .clamp(0, packs.length - 1)
        .toInt();
    final orderedPacks = [
      packs[safeIndex],
      for (var index = 0; index < packs.length; index += 1)
        if (index != safeIndex) packs[index],
    ];

    return orderedPacks
        .expand((pack) => pack.stickers)
        .where((sticker) => sticker.fileId.trim().isNotEmpty)
        .toList(growable: false);
  }

  void _handleStickerPackSelected(int index) {
    if (index < 0 || index >= _stickerPacks.length) return;
    setState(() => _activeStickerPackIndex = index);

    final selected = _stickerPacks[index];
    final next = index + 1 < _stickerPacks.length
        ? _stickerPacks[index + 1]
        : null;
    unawaited(
      _precacheStickerImages([
        ...selected.stickers,
        if (next != null) ...next.stickers,
      ], limit: 80),
    );
  }

  Future<void> _loadStickerPacks({
    String? locale,
    bool force = false,
    bool silent = false,
  }) async {
    if (_stickersLoading) return;
    if (!force && _stickerPacks.isNotEmpty) return;

    if (!silent) {
      setState(() {
        _stickersLoading = true;
        _stickersLoadFailed = false;
      });
    } else {
      _stickersLoading = true;
      _stickersLoadFailed = false;
    }

    try {
      final catalogProvider = context.read<StickerCatalogProvider>();
      final activeLocale =
          locale ?? Localizations.localeOf(context).languageCode;
      final catalogLoad = catalogProvider.loadCatalog(
        locale: activeLocale,
        preloadAllPacks: true,
      );
      final myPacksLoad = _stickerApi.listMyPacks().catchError(
        (_) => const <StickerPackVm>[],
      );

      await catalogLoad;

      final officialPacks = catalogProvider.groups
          .expand((group) => group.packs)
          .toList(growable: false);
      final myPacks = await myPacksLoad;
      final packs = _mergeStickerPacks(myPacks, officialPacks);

      if (!mounted) return;
      setState(() {
        _stickerPacks = packs;
        if (_activeStickerPackIndex >= _stickerPacks.length) {
          _activeStickerPackIndex = 0;
        }
        _stickersLoadFailed = false;
      });
      unawaited(_precacheStickerImages(_prioritizedStickerWarmupList(packs)));
    } catch (_) {
      if (!mounted) return;
      if (!silent) {
        setState(() => _stickersLoadFailed = true);
      } else {
        _stickersLoadFailed = true;
      }
    } finally {
      if (mounted) {
        if (!silent) {
          setState(() => _stickersLoading = false);
        } else {
          _stickersLoading = false;
        }
      }
    }
  }

  List<StickerPackVm> _mergeStickerPacks(
    List<StickerPackVm> myPacks,
    List<StickerPackVm> officialPacks,
  ) {
    return orderStickerPacksForComposer(
      myPacks: myPacks,
      officialPacks: officialPacks,
    );
  }

  Future<bool> _sendSticker(StickerVm sticker) async {
    final l10n = AppLocalizations.of(context)!;
    final stickerId = sticker.id.trim();
    if (stickerId.isEmpty || _attachmentUploading) return false;
    if (!_canSendInActiveConversation()) {
      _showChatClosedMessage();
      return false;
    }

    final sent = await context.read<ChatProvider>().sendSticker(
      sticker: sticker,
      replyToMessageId: _replyToMessage?.id,
    );
    if (!mounted) return false;
    if (sent) {
      setState(() => _replyToMessage = null);
      context.read<ChatProvider>().markAsRead();
      return true;
    }

    await showErrorDialog(
      context,
      title: l10n.error,
      message: l10n.chatStickerSendFailed,
    );
    return false;
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

  Future<void> _handleMessageLinkTap(String rawUrl) async {
    final internalRoute = internalAppRouteForChatUrl(rawUrl);
    if (internalRoute != null) {
      context.push(internalRoute);
      return;
    }

    final uri = externalUriForChatUrl(rawUrl);
    if (uri == null) return;

    final confirmed = await _confirmExternalLinkOpen(uri);
    if (!mounted || !confirmed) return;

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted || opened) return;

    await showErrorDialog(
      context,
      title: AppLocalizations.of(context)!.error,
      message: AppLocalizations.of(context)!.chatExternalLinkOpenFailed,
    );
  }

  Future<bool> _confirmExternalLinkOpen(Uri uri) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1d120b),
        title: Text(
          l10n.chatExternalLinkTitle,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          l10n.chatExternalLinkMessage(uri.toString()),
          style: const TextStyle(color: Color(0xFFf5ede6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.chatExternalLinkOpenAction),
          ),
        ],
      ),
    );
    return confirmed ?? false;
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
    final canReact = conversation.canSendNow;
    final canCopy = message.content.trim().isNotEmpty;
    const canForward = true;
    final isPinned = _isMessagePinned(conversation, message.id);
    final reactionInfos = _reactionInfosForMessage(message, conversation);
    final readReceipts = _readReceiptsForMessage(
      message,
      conversation,
      currentUserId,
    );
    final hasStatusPreview =
        message.isForwarded ||
        message.forwardCount > 0 ||
        reactionInfos.isNotEmpty ||
        readReceipts.isNotEmpty;

    final l10n = AppLocalizations.of(context)!;
    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: const Color(0xFF1d120b),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final maxHeight =
            MediaQuery.sizeOf(sheetContext).height *
            _messageActionSheetMaxHeightFactor;

        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasStatusPreview) ...[
                      _MessageStatusPreview(
                        message: message,
                        reactionInfos: reactionInfos,
                        readReceipts: readReceipts,
                        onReactionSummaryTap: reactionInfos.isEmpty
                            ? null
                            : () =>
                                  Navigator.pop(sheetContext, 'reaction_users'),
                        onReadReceiptsTap: readReceipts.isEmpty
                            ? null
                            : () =>
                                  Navigator.pop(sheetContext, 'read_receipts'),
                      ),
                      SizedBox(height: _scale(context, 12)),
                      Divider(color: Colors.white.withValues(alpha: 0.08)),
                      SizedBox(height: _scale(context, 4)),
                    ],
                    if (canReact) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.chatReactionSheetTitle,
                          style: TextStyle(
                            fontSize: _scale(context, 13),
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withValues(alpha: 0.58),
                          ),
                        ),
                      ),
                      SizedBox(height: _scale(context, 12)),
                      _ReactionPickerRow(
                        selectedEmoji: message.reactions
                            .where((reaction) => reaction.reactedByMe)
                            .firstOrNull
                            ?.emoji,
                        onSelected: (emoji) =>
                            Navigator.pop(sheetContext, 'reaction:$emoji'),
                      ),
                      SizedBox(height: _scale(context, 12)),
                      Divider(color: Colors.white.withValues(alpha: 0.08)),
                      SizedBox(height: _scale(context, 4)),
                    ],
                    if (canCopy)
                      ListTile(
                        leading: const Icon(
                          Icons.copy_rounded,
                          color: AppColors.accent,
                        ),
                        title: Text(
                          l10n.chatCopyAction,
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () => Navigator.pop(sheetContext, 'copy'),
                      ),
                    if (canForward)
                      ListTile(
                        leading: const Icon(
                          Icons.forward_rounded,
                          color: AppColors.accent,
                        ),
                        title: Text(
                          l10n.chatForwardAction,
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () => Navigator.pop(sheetContext, 'forward'),
                      ),
                    if (canManagePins)
                      ListTile(
                        leading: Icon(
                          isPinned
                              ? Icons.push_pin_outlined
                              : Icons.push_pin_rounded,
                          color: AppColors.accent,
                        ),
                        title: Text(
                          isPinned ? l10n.chatUnpinAction : l10n.chatPinAction,
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () => Navigator.pop(
                          sheetContext,
                          isPinned ? 'unpin' : 'pin',
                        ),
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
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    if (action == 'copy') {
      await _copyMessageText(message);
      return;
    }

    if (action == 'forward') {
      await _showForwardMessageSheet(message);
      return;
    }

    if (action == 'read_receipts') {
      await _showReadReceiptsSheet(readReceipts);
      return;
    }

    if (action == 'reaction_users') {
      await _showReactionUsersSheet(reactionInfos);
      return;
    }

    if (action.startsWith('reaction:')) {
      final emoji = action.substring('reaction:'.length);
      await _toggleMessageReaction(message.id, emoji);
      return;
    }

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

  Future<void> _copyMessageText(MessageVm message) async {
    final text = message.content.trim();
    if (text.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.chatMessageCopied),
        backgroundColor: const Color(0xFF3a2415),
      ),
    );
  }

  Future<void> _showForwardMessageSheet(MessageVm message) async {
    final chat = context.read<ChatProvider>();
    final l10n = AppLocalizations.of(context)!;

    if (chat.conversations.isEmpty && !chat.conversationsLoading) {
      await chat.loadConversations();
    }
    if (!mounted) return;

    final currentUserId =
        context.read<SessionProvider>().profile?.userId.trim() ?? '';
    final selected = await showModalBottomSheet<ConversationVm>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: const Color(0xFF1d120b),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _ForwardMessageSheet(
        conversations: chat.conversations
            .where((conversation) => conversation.canSendNow)
            .toList(growable: false),
        currentUserId: currentUserId,
        activeConversationId: chat.activeConversation?.id ?? '',
      ),
    );
    if (!mounted || selected == null) return;

    final forwarded = await context
        .read<ChatProvider>()
        .forwardMessageToConversation(
          message: message,
          targetConversationId: selected.id,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          forwarded ? l10n.chatForwardSuccess : l10n.chatForwardFailed,
        ),
        backgroundColor: const Color(0xFF3a2415),
      ),
    );
  }

  Future<void> _showReadReceiptsSheet(List<_ReadReceiptInfo> receipts) async {
    if (receipts.isEmpty) return;

    final selectedUserId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: const Color(0xFF1d120b),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _ReadReceiptsSheet(receipts: receipts),
    );
    if (!mounted || selectedUserId == null) return;
    _openUserProfile(selectedUserId);
  }

  Future<void> _showReactionUsersSheet(
    List<_ReactionInfo> reactionInfos,
  ) async {
    if (reactionInfos.isEmpty) return;

    final selectedUserId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: const Color(0xFF1d120b),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) =>
          _ReactionUsersSheet(reactionInfos: reactionInfos),
    );
    if (!mounted || selectedUserId == null) return;
    _openUserProfile(selectedUserId);
  }

  List<_ReactionInfo> _reactionInfosForMessage(
    MessageVm message,
    ConversationDetail conversation,
  ) {
    if (message.id.trim().isEmpty || message.reactions.isEmpty) {
      return const [];
    }

    final participantsByUserId = {
      for (final participant in conversation.participants)
        participant.userId.trim(): participant,
    };
    final seenUserIds = <String>{};
    final infos = <_ReactionInfo>[];
    for (final reaction in message.reactions) {
      final emoji = reaction.emoji.trim();
      if (emoji.isEmpty || reaction.count <= 0) continue;
      for (final reactionUser in reaction.users) {
        final userId = reactionUser.userId.trim();
        if (userId.isEmpty || !seenUserIds.add(userId)) continue;
        final participant = participantsByUserId[userId];
        if (participant == null) continue;
        infos.add(
          _ReactionInfo(
            participant: participant,
            emoji: emoji,
            reactedAt: reactionUser.reactedAt,
          ),
        );
      }
    }
    if (infos.isNotEmpty) {
      infos.sort((a, b) => b.reactedAt.compareTo(a.reactedAt));
      return infos;
    }

    seenUserIds.clear();
    for (final reaction in message.reactions) {
      final emoji = reaction.emoji.trim();
      if (emoji.isEmpty || reaction.count <= 0) continue;
      for (final rawUserId in reaction.userIds) {
        final userId = rawUserId.trim();
        if (userId.isEmpty || !seenUserIds.add(userId)) continue;
        final participant = participantsByUserId[userId];
        if (participant == null) continue;
        infos.add(
          _ReactionInfo(
            participant: participant,
            emoji: emoji,
            reactedAt: message.sentAt,
          ),
        );
      }
    }
    return infos;
  }

  List<_ReadReceiptInfo> _readReceiptsForMessage(
    MessageVm message,
    ConversationDetail conversation,
    String currentUserId,
  ) {
    if (currentUserId.trim().isEmpty ||
        message.senderUserId != currentUserId ||
        message.readReceipts.isEmpty) {
      return const [];
    }

    final participantsByUserId = {
      for (final participant in conversation.participants)
        participant.userId.trim(): participant,
    };
    final reactionEmojiByUserId = _reactionEmojiByUserIdForMessage(message);
    final receipts = <_ReadReceiptInfo>[];
    for (final receipt in message.readReceipts) {
      final userId = receipt.userId.trim();
      if (userId.isEmpty || userId == currentUserId) continue;
      final participant = participantsByUserId[userId];
      if (participant == null) continue;
      receipts.add(
        _ReadReceiptInfo(
          participant: participant,
          readAt: receipt.readAt,
          reactionEmoji: _reactionEmojiForUserId(reactionEmojiByUserId, userId),
        ),
      );
    }
    receipts.sort((a, b) {
      final reactionPriority = _readReceiptReactionPriority(
        a,
      ).compareTo(_readReceiptReactionPriority(b));
      if (reactionPriority != 0) return reactionPriority;
      return b.readAt.compareTo(a.readAt);
    });
    return receipts;
  }

  Map<String, String> _reactionEmojiByUserIdForMessage(MessageVm message) {
    final reactionEmojiByUserId = <String, String>{};
    for (final reaction in message.reactions) {
      final emoji = reaction.emoji.trim();
      if (emoji.isEmpty || reaction.count <= 0) continue;
      for (final userId in reaction.userIds) {
        final normalizedUserId = userId.trim();
        if (normalizedUserId.isEmpty) continue;
        reactionEmojiByUserId.putIfAbsent(normalizedUserId, () => emoji);
      }
    }
    return reactionEmojiByUserId;
  }

  String? _reactionEmojiForUserId(
    Map<String, String> reactionEmojiByUserId,
    String userId,
  ) {
    final emoji = reactionEmojiByUserId[userId.trim()]?.trim();
    return emoji == null || emoji.isEmpty ? null : emoji;
  }

  int _readReceiptReactionPriority(_ReadReceiptInfo receipt) {
    return receipt.reactionEmoji?.trim().isNotEmpty == true ? 0 : 1;
  }

  Future<void> _toggleMessageReaction(String messageId, String emoji) async {
    if (!_canSendInActiveConversation()) {
      _showChatClosedMessage();
      return;
    }

    try {
      await context.read<ChatProvider>().toggleMessageReaction(
        messageId,
        emoji,
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final messageText = e is DioException
          ? DioErrorMapper.toMessage(e)
          : l10n.chatReactionFailed;
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

  void _scheduleInitialMessageScroll() {
    if (_initialMessageScrollHandled) return;
    final messageId = widget.initialMessageId?.trim() ?? '';
    if (messageId.isEmpty) return;
    _initialMessageScrollHandled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_scrollToMessage(messageId));
    });
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

  Future<void> _openSharedContent(
    ConversationDetail conversation,
    String currentUserId,
    List<MessageVm> messages,
  ) async {
    final result = await Navigator.of(context).push<ChatSharedContentResult>(
      MaterialPageRoute<ChatSharedContentResult>(
        builder: (_) => ChatSharedContentScreen(
          conversation: conversation,
          currentUserId: currentUserId,
          initialMessages: messages,
        ),
      ),
    );
    if (!mounted || result == null) return;
    await _scrollToMessage(result.messageId);
  }

  void _openUserProfile(String rawUserId) {
    final userId = rawUserId.trim();
    if (userId.isEmpty) return;

    final currentUserId =
        context.read<SessionProvider>().profile?.userId.trim() ?? '';
    if (currentUserId.isNotEmpty && userId == currentUserId) {
      context.push('/profile');
      return;
    }

    final encodedUserId = Uri.encodeComponent(userId);
    context.push('/users/$encodedUserId/profile');
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
                onDirectPeerAvatarTap: (userId) => _openUserProfile(userId),
                onDirectActionsTap: () =>
                    _showDirectChatActions(conv, currentUserId),
                onSharedContentTap: () => unawaited(
                  _openSharedContent(conv, currentUserId, chat.messages),
                ),
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
                  onReactionSelected: (message, emoji) =>
                      unawaited(_toggleMessageReaction(message.id, emoji)),
                  onReplyPreviewTap: (messageId) =>
                      unawaited(_scrollToMessage(messageId)),
                  onAvatarTap: (userId) => _openUserProfile(userId),
                  onMessageLinkTap: (url) =>
                      unawaited(_handleMessageLinkTap(url)),
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
                  onPickGallery: () =>
                      _pickAttachments(_AttachmentPickType.gallery),
                  onPickFile: () => _pickAttachments(_AttachmentPickType.file),
                  onPickAudio: () =>
                      _pickAttachments(_AttachmentPickType.audio),
                  onCameraCapture: () => unawaited(_captureCameraAttachment()),
                  onRemoveAttachment: _removePendingAttachment,
                  onCancelReply: _clearReplyMessage,
                  onVoiceStart: () => _startVoiceRecording(pressActive: true),
                  onVoiceStartLocked: () => _startVoiceRecording(locked: true),
                  onVoiceLock: _lockVoiceRecording,
                  onVoiceCancel: _cancelVoiceRecording,
                  onVoiceStop: _stopVoiceRecordingForPreview,
                  activePanel: _activeComposerPanel,
                  stickerPacks: _stickerPacks,
                  activeStickerPackIndex: _activeStickerPackIndex,
                  stickersLoading: _stickersLoading,
                  stickersLoadFailed: _stickersLoadFailed,
                  onPanelChanged: _setComposerPanel,
                  onEmojiSelected: _handleEmojiSelected,
                  onPasteRequested: () => unawaited(_handlePasteRequested()),
                  onPasteImageRequested: () =>
                      unawaited(_handlePasteImageRequested()),
                  onStickerPackSelected: _handleStickerPackSelected,
                  onStickerSelected: (sticker) =>
                      unawaited(_sendSticker(sticker)),
                  onRetryStickers: () =>
                      unawaited(_loadStickerPacks(force: true)),
                  sending: chat.sendingMessage,
                  attachmentUploading: _attachmentUploading,
                  voiceRecording: _voiceRecording,
                  voiceRecordingLocked: _voiceRecordingLocked,
                  voicePressActive: _voicePressActive,
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

// _AttachmentPickType drives _pickAttachments dispatch.
//   - gallery: native multi-media picker (photos+videos), no runtime permission needed.
//   - file: arbitrary file via the platform file selector.
//   - audio: audio file via the platform file selector.
enum _AttachmentPickType { gallery, file, audio }

enum _ComposerPanel { none, emoji, stickers }

class _PickedChatAttachment {
  const _PickedChatAttachment({
    required this.localId,
    required this.name,
    required this.bytes,
    required this.contentType,
    this.localPath,
    this.duration,
    this.deleteLocalFileOnRemove = false,
  });

  final int localId;
  final String name;
  final Uint8List bytes;
  final String contentType;
  final String? localPath;
  final Duration? duration;
  final bool deleteLocalFileOnRemove;

  bool get isImage => contentType.startsWith('image/');
  bool get isVideo => contentType.startsWith('video/');
  bool get isAudio => contentType.startsWith('audio/');

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

// _extensionForMime gives a sensible filename suffix when a picker returns a
// file without an extension. Only types accepted in _contentTypeForFileName are
// listed.
String? _extensionForMime(String mime) {
  return switch (mime.toLowerCase()) {
    'image/gif' => 'gif',
    'image/jpeg' => 'jpg',
    'image/png' => 'png',
    'image/heic' => 'heic',
    'image/heif' => 'heif',
    'image/webp' => 'webp',
    'video/mp4' => 'mp4',
    'video/quicktime' => 'mov',
    'video/webm' => 'webm',
    'audio/mp4' || 'audio/aac' => 'm4a',
    'audio/mpeg' => 'mp3',
    'audio/wav' => 'wav',
    'audio/ogg' => 'ogg',
    'audio/opus' => 'opus',
    _ => null,
  };
}

String? _contentTypeForFileName(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot < 0 || dot == fileName.length - 1) return null;

  final ext = fileName.substring(dot + 1).toLowerCase();
  return switch (ext) {
    'gif' => 'image/gif',
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
    required this.onDirectPeerAvatarTap,
    required this.onDirectActionsTap,
    required this.onSharedContentTap,
  });

  final ConversationDetail conversation;
  final String currentUserId;
  final VoidCallback onParticipantsTap;
  final ValueChanged<String> onDirectPeerAvatarTap;
  final VoidCallback onDirectActionsTap;
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
          if (conversation.isDirect) ...[
            _DirectTopBarContent(
              conversation: conversation,
              currentUserId: currentUserId,
              onTap: onSharedContentTap,
              onDirectPeerAvatarTap: onDirectPeerAvatarTap,
            ),
            SizedBox(width: _scale(context, 10)),
            _DirectActionsButton(onTap: onDirectActionsTap),
          ] else ...[
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

class _DirectActionsButton extends StatelessWidget {
  const _DirectActionsButton({required this.onTap});

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
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          color: Colors.white.withValues(alpha: 0.05),
        ),
        child: Center(
          child: Icon(
            Icons.more_vert_rounded,
            size: _scale(context, 22),
            color: AppColors.textPrimary,
          ),
        ),
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
    required this.onDirectPeerAvatarTap,
  });

  final ConversationDetail conversation;
  final String currentUserId;
  final VoidCallback onTap;
  final ValueChanged<String> onDirectPeerAvatarTap;

  @override
  Widget build(BuildContext context) {
    final other = conversation.directPeer(currentUserId);
    final l10n = AppLocalizations.of(context)!;
    final isOnline = other?.isOnline ?? false;
    final statusLabel = chatPresenceStatusLabel(l10n, other);
    final peerUserId = other?.userId.trim() ?? '';
    final avatar = _ChatAvatar(
      size: _scale(context, 48),
      name: other?.displayName ?? '',
      avatarFileId: other?.avatarFileId,
    );

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            if (peerUserId.isEmpty)
              avatar
            else
              GestureDetector(
                onTap: () => onDirectPeerAvatarTap(peerUserId),
                behavior: HitTestBehavior.opaque,
                child: avatar,
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
    required this.onReactionSelected,
    required this.onReplyPreviewTap,
    required this.onAvatarTap,
    required this.onMessageLinkTap,
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
  final void Function(MessageVm message, String emoji) onReactionSelected;
  final ValueChanged<String> onReplyPreviewTap;
  final ValueChanged<String> onAvatarTap;
  final ValueChanged<String> onMessageLinkTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayItems = _buildItems(context, l10n);
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
    DateTime? currentDate;

    for (var i = messages.length - 1; i >= 0; i--) {
      final msg = messages[i];
      final msgDate = _dateOnly(msg.sentAt);

      if (currentDate == null || currentDate != msgDate) {
        currentDate = msgDate;
        items.add(_DaySeparator(label: _dateLabelFor(msg.sentAt, l10n)));
      }

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
          onReactionTap: (emoji) => onReactionSelected(msg, emoji),
          onReplyPreviewTap: msg.replyToMessageId == null
              ? null
              : () => onReplyPreviewTap(msg.replyToMessageId!),
          onAvatarTap: onAvatarTap,
          onLinkTap: onMessageLinkTap,
          l10n: l10n,
        ),
      );
    }

    if (messagingClosed) {
      items.add(
        _ChatClosedTailNotice(text: l10n.chatActivityChatClosedHistoryNotice),
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

  DateTime _dateOnly(DateTime dt) {
    final local = dt.toLocal();
    return DateTime(local.year, local.month, local.day);
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
    return message.isHiddenByModerator
        ? l10n.chatMessageRemovedByModerator
        : l10n.chatMessageDeleted;
  }
  if (message.isSticker) {
    return l10n.chatStickerMessage;
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
    stickerId: pinned.stickerId,
    stickerFileId: pinned.stickerFileId,
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

const _chatReactionChoices = <String>['👍', '❤️', '😂', '😮', '😢', '🙏', '🔥'];

class _ReactionPickerRow extends StatelessWidget {
  const _ReactionPickerRow({
    required this.selectedEmoji,
    required this.onSelected,
  });

  final String? selectedEmoji;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final emoji in _chatReactionChoices) ...[
            _ReactionChoiceButton(
              emoji: emoji,
              selected: emoji == selectedEmoji,
              onTap: () => onSelected(emoji),
            ),
            SizedBox(width: _scale(context, 8)),
          ],
        ],
      ),
    );
  }
}

class _ReactionChoiceButton extends StatelessWidget {
  const _ReactionChoiceButton({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: AppLocalizations.of(context)!.chatReactionSheetTitle,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: _scale(context, 46),
          height: _scale(context, 46),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected
                ? AppColors.accent.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.07),
            border: Border.all(
              color: selected
                  ? AppColors.accent.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Center(
            child: Text(emoji, style: TextStyle(fontSize: _scale(context, 24))),
          ),
        ),
      ),
    );
  }
}

class _MessageStatusPreview extends StatelessWidget {
  const _MessageStatusPreview({
    required this.message,
    required this.reactionInfos,
    required this.readReceipts,
    required this.onReactionSummaryTap,
    required this.onReadReceiptsTap,
  });

  final MessageVm message;
  final List<_ReactionInfo> reactionInfos;
  final List<_ReadReceiptInfo> readReceipts;
  final VoidCallback? onReactionSummaryTap;
  final VoidCallback? onReadReceiptsTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasForwardInfo = message.isForwarded || message.forwardCount > 0;
    final hasDetails =
        hasForwardInfo || reactionInfos.isNotEmpty || readReceipts.isNotEmpty;

    if (!hasDetails) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasForwardInfo)
          _StatusDetailCard(
            child: Column(
              children: [
                if (message.isForwarded)
                  _StatusMetricCard(
                    icon: Icons.forward_rounded,
                    text: l10n.chatForwardedFrom(
                      message.forwardedFromSenderName?.trim().isNotEmpty == true
                          ? message.forwardedFromSenderName!.trim()
                          : l10n.chatForwardedLabel,
                    ),
                  ),
                if (message.isForwarded && message.forwardCount > 0)
                  SizedBox(height: _scale(context, 8)),
                if (message.forwardCount > 0)
                  _StatusMetricCard(
                    icon: Icons.repeat_rounded,
                    text: l10n.chatForwardCount(message.forwardCount),
                  ),
              ],
            ),
          ),
        if (reactionInfos.isNotEmpty) ...[
          if (hasForwardInfo) SizedBox(height: _scale(context, 10)),
          _ReactionSummary(
            reactionInfos: reactionInfos,
            onTap: onReactionSummaryTap,
          ),
        ],
        if (reactionInfos.isEmpty && readReceipts.isNotEmpty) ...[
          if (hasForwardInfo) SizedBox(height: _scale(context, 10)),
          _ReadReceiptSummary(receipts: readReceipts, onTap: onReadReceiptsTap),
        ],
      ],
    );
  }
}

class _ReactionInfo {
  const _ReactionInfo({
    required this.participant,
    required this.emoji,
    required this.reactedAt,
  });

  final ParticipantInfo participant;
  final String emoji;
  final DateTime reactedAt;
}

class _ReadReceiptInfo {
  const _ReadReceiptInfo({
    required this.participant,
    required this.readAt,
    this.reactionEmoji,
  });

  final ParticipantInfo participant;
  final DateTime readAt;
  final String? reactionEmoji;
}

class _StatusDetailCard extends StatelessWidget {
  const _StatusDetailCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_scale(context, 12)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_scale(context, 18)),
        color: Colors.white.withValues(alpha: 0.055),
        border: Border.all(color: Colors.white.withValues(alpha: 0.075)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: _scale(context, 18),
            offset: Offset(0, _scale(context, 8)),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatusMetricCard extends StatelessWidget {
  const _StatusMetricCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: _scale(context, 30),
          height: _scale(context, 30),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent.withValues(alpha: 0.16),
          ),
          child: Icon(icon, size: _scale(context, 16), color: AppColors.accent),
        ),
        SizedBox(width: _scale(context, 10)),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: _scale(context, 13),
              fontWeight: FontWeight.w800,
              color: const Color(0xFFf3dfc8),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReactionSummary extends StatelessWidget {
  const _ReactionSummary({required this.reactionInfos, required this.onTap});

  final List<_ReactionInfo> reactionInfos;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final recent = reactionInfos.take(3).toList(growable: false);
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _scale(context, 12),
          vertical: _scale(context, 10),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_scale(context, 16)),
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.add_reaction_rounded,
              size: _scale(context, 17),
              color: AppColors.accent,
            ),
            SizedBox(width: _scale(context, 8)),
            Expanded(
              child: Text(
                l10n.chatReactionCount(reactionInfos.length),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: _scale(context, 13),
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFf3dfc8),
                ),
              ),
            ),
            if (recent.isNotEmpty) ...[
              SizedBox(width: _scale(context, 10)),
              SizedBox(
                width: _scale(context, 26 + (recent.length - 1) * 18),
                height: _scale(context, 28),
                child: Stack(
                  children: [
                    for (var i = 0; i < recent.length; i++)
                      Positioned(
                        right: _scale(context, i * 18),
                        child: _ChatAvatar(
                          size: _scale(context, 28),
                          name: recent[i].participant.displayName,
                          avatarFileId: recent[i].participant.avatarFileId,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            SizedBox(width: _scale(context, 8)),
            Icon(
              Icons.keyboard_arrow_right_rounded,
              size: _scale(context, 20),
              color: Colors.white.withValues(alpha: 0.48),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadReceiptSummary extends StatelessWidget {
  const _ReadReceiptSummary({required this.receipts, required this.onTap});

  final List<_ReadReceiptInfo> receipts;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final recent = receipts.take(3).toList(growable: false);
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _scale(context, 12),
          vertical: _scale(context, 10),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_scale(context, 16)),
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.done_all_rounded,
              size: _scale(context, 17),
              color: AppColors.accent,
            ),
            SizedBox(width: _scale(context, 8)),
            Expanded(
              child: Text(
                l10n.chatReadByCount(receipts.length),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: _scale(context, 13),
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFf3dfc8),
                ),
              ),
            ),
            if (recent.isNotEmpty) ...[
              SizedBox(width: _scale(context, 10)),
              SizedBox(
                width: _scale(context, 26 + (recent.length - 1) * 18),
                height: _scale(context, 28),
                child: Stack(
                  children: [
                    for (var i = 0; i < recent.length; i++)
                      Positioned(
                        right: _scale(context, i * 18),
                        child: _ChatAvatar(
                          size: _scale(context, 28),
                          name: recent[i].participant.displayName,
                          avatarFileId: recent[i].participant.avatarFileId,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            SizedBox(width: _scale(context, 8)),
            Icon(
              Icons.keyboard_arrow_right_rounded,
              size: _scale(context, 20),
              color: Colors.white.withValues(alpha: 0.48),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionUsersSheet extends StatelessWidget {
  const _ReactionUsersSheet({required this.reactionInfos});

  final List<_ReactionInfo> reactionInfos;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            _scale(context, 20),
            _scale(context, 12),
            _scale(context, 20),
            _scale(context, 16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: _scale(context, 38),
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
              ),
              SizedBox(height: _scale(context, 18)),
              Text(
                l10n.chatReactionsByTitle,
                style: TextStyle(
                  fontSize: _scale(context, 20),
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFf5ede6),
                ),
              ),
              SizedBox(height: _scale(context, 14)),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: reactionInfos.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  itemBuilder: (context, index) {
                    final reactionInfo = reactionInfos[index];
                    return _ReactionUserTile(reactionInfo: reactionInfo);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReactionUserTile extends StatelessWidget {
  const _ReactionUserTile({required this.reactionInfo});

  final _ReactionInfo reactionInfo;

  @override
  Widget build(BuildContext context) {
    final participant = reactionInfo.participant;
    final title = participant.displayName.trim().isEmpty
        ? participant.userId
        : participant.displayName.trim();

    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: _scale(context, 8)),
      leading: _ChatAvatar(
        size: _scale(context, 46),
        name: title,
        avatarFileId: participant.avatarFileId,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: _scale(context, 15),
                fontWeight: FontWeight.w800,
                color: const Color(0xFFf5ede6),
              ),
            ),
          ),
          SizedBox(width: _scale(context, 8)),
          _ReadReceiptReactionBadge(emoji: reactionInfo.emoji),
        ],
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: _scale(context, 3)),
        child: Text(
          _formatReactionAt(context, reactionInfo.reactedAt),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: _scale(context, 12),
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.52),
          ),
        ),
      ),
      onTap: () => Navigator.of(context).pop(participant.userId),
    );
  }
}

class _ReadReceiptsSheet extends StatelessWidget {
  const _ReadReceiptsSheet({required this.receipts});

  final List<_ReadReceiptInfo> receipts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            _scale(context, 20),
            _scale(context, 12),
            _scale(context, 20),
            _scale(context, 16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: _scale(context, 38),
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
              ),
              SizedBox(height: _scale(context, 18)),
              Text(
                l10n.chatReadByTitle,
                style: TextStyle(
                  fontSize: _scale(context, 20),
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFf5ede6),
                ),
              ),
              SizedBox(height: _scale(context, 14)),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: receipts.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  itemBuilder: (context, index) {
                    final receipt = receipts[index];
                    return _ReadReceiptTile(receipt: receipt);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadReceiptTile extends StatelessWidget {
  const _ReadReceiptTile({required this.receipt});

  final _ReadReceiptInfo receipt;

  @override
  Widget build(BuildContext context) {
    final participant = receipt.participant;
    final title = participant.displayName.trim().isEmpty
        ? participant.userId
        : participant.displayName.trim();

    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: _scale(context, 8)),
      leading: _ChatAvatar(
        size: _scale(context, 46),
        name: title,
        avatarFileId: participant.avatarFileId,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: _scale(context, 15),
                fontWeight: FontWeight.w800,
                color: const Color(0xFFf5ede6),
              ),
            ),
          ),
          if (receipt.reactionEmoji != null) ...[
            SizedBox(width: _scale(context, 8)),
            _ReadReceiptReactionBadge(emoji: receipt.reactionEmoji!),
          ],
        ],
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: _scale(context, 3)),
        child: Text(
          _formatReadReceiptAt(context, receipt.readAt),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: _scale(context, 12),
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.52),
          ),
        ),
      ),
      onTap: () => Navigator.of(context).pop(participant.userId),
    );
  }
}

class _ReadReceiptReactionBadge extends StatelessWidget {
  const _ReadReceiptReactionBadge({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: _scale(context, 32)),
      padding: EdgeInsets.symmetric(
        horizontal: _scale(context, 8),
        vertical: _scale(context, 4),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.accent.withValues(alpha: 0.14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.28)),
      ),
      child: Text(
        emoji,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: TextStyle(fontSize: _scale(context, 14), height: 1),
      ),
    );
  }
}

class _ForwardMessageSheet extends StatelessWidget {
  const _ForwardMessageSheet({
    required this.conversations,
    required this.currentUserId,
    required this.activeConversationId,
  });

  final List<ConversationVm> conversations;
  final String currentUserId;
  final String activeConversationId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 12, 18, 18 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
              ),
              SizedBox(height: _scale(context, 16)),
              Text(
                l10n.chatForwardSheetTitle,
                style: TextStyle(
                  fontSize: _scale(context, 20),
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFf5ede6),
                ),
              ),
              SizedBox(height: _scale(context, 14)),
              if (conversations.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: _scale(context, 24)),
                  child: Center(
                    child: Text(
                      l10n.chatNoForwardTargets,
                      style: TextStyle(
                        fontSize: _scale(context, 14),
                        color: Colors.white.withValues(alpha: 0.58),
                      ),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: conversations.length,
                    separatorBuilder: (_, _) =>
                        SizedBox(height: _scale(context, 8)),
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      final title = conversation.displayTitle(currentUserId);
                      final isCurrent = conversation.id == activeConversationId;
                      return _ForwardConversationTile(
                        conversation: conversation,
                        title: title,
                        currentUserId: currentUserId,
                        isCurrent: isCurrent,
                        onTap: () => Navigator.of(context).pop(conversation),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ForwardConversationTile extends StatelessWidget {
  const _ForwardConversationTile({
    required this.conversation,
    required this.title,
    required this.currentUserId,
    required this.isCurrent,
    required this.onTap,
  });

  final ConversationVm conversation;
  final String title;
  final String currentUserId;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(_scale(context, 12)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_scale(context, 18)),
          color: isCurrent
              ? AppColors.accent.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.045),
          border: Border.all(
            color: isCurrent
                ? AppColors.accent.withValues(alpha: 0.28)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            _ChatAvatar(
              size: _scale(context, 42),
              name: title,
              avatarFileId: conversation.displayAvatarFileId(currentUserId),
            ),
            SizedBox(width: _scale(context, 12)),
            Expanded(
              child: Text(
                title,
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
            Icon(
              Icons.send_rounded,
              size: _scale(context, 18),
              color: AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }
}

class _ForwardedMessageLabel extends StatelessWidget {
  const _ForwardedMessageLabel({required this.message});

  final MessageVm message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sourceName = message.forwardedFromSenderName?.trim();
    final text = sourceName == null || sourceName.isEmpty
        ? l10n.chatForwardedLabel
        : l10n.chatForwardedFrom(sourceName);

    return Row(
      children: [
        Icon(
          Icons.forward_rounded,
          size: _scale(context, 15),
          color: AppColors.accent,
        ),
        SizedBox(width: _scale(context, 6)),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: _scale(context, 12),
              fontWeight: FontWeight.w800,
              color: const Color(0xFFffd08a),
            ),
          ),
        ),
      ],
    );
  }
}

class _HyperlinkedMessageText extends StatefulWidget {
  const _HyperlinkedMessageText({
    required this.text,
    required this.style,
    required this.linkStyle,
    required this.onLinkTap,
  });

  final String text;
  final TextStyle style;
  final TextStyle linkStyle;
  final ValueChanged<String> onLinkTap;

  @override
  State<_HyperlinkedMessageText> createState() =>
      _HyperlinkedMessageTextState();
}

class _HyperlinkedMessageTextState extends State<_HyperlinkedMessageText> {
  List<ChatLinkMatch> _links = const [];
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void initState() {
    super.initState();
    _rebuildRecognizers();
  }

  @override
  void didUpdateWidget(covariant _HyperlinkedMessageText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _rebuildRecognizers();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _rebuildRecognizers() {
    _disposeRecognizers();
    _links = extractChatLinks(widget.text);
    for (var index = 0; index < _links.length; index++) {
      final linkIndex = index;
      _recognizers.add(
        TapGestureRecognizer()
          ..onTap = () => widget.onLinkTap(_links[linkIndex].url),
      );
    }
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_links.isEmpty) {
      return Text(widget.text, style: widget.style);
    }

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (var index = 0; index < _links.length; index++) {
      final link = _links[index];
      if (link.start > cursor) {
        spans.add(TextSpan(text: widget.text.substring(cursor, link.start)));
      }
      spans.add(
        TextSpan(
          text: widget.text.substring(link.start, link.end),
          style: widget.linkStyle,
          recognizer: _recognizers[index],
        ),
      );
      cursor = link.end;
    }
    if (cursor < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(cursor)));
    }

    return Text.rich(TextSpan(style: widget.style, children: spans));
  }
}

class _ForwardCountBadge extends StatelessWidget {
  const _ForwardCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.repeat_rounded,
          size: _scale(context, 13),
          color: Colors.white.withValues(alpha: 0.38),
        ),
        SizedBox(width: _scale(context, 4)),
        Text(
          l10n.chatForwardCount(count),
          style: TextStyle(
            fontSize: _scale(context, 11),
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.38),
          ),
        ),
      ],
    );
  }
}

class _MessageReactionStrip extends StatelessWidget {
  const _MessageReactionStrip({
    required this.reactions,
    required this.onReactionTap,
  });

  final List<MessageReactionVm> reactions;
  final ValueChanged<String> onReactionTap;

  @override
  Widget build(BuildContext context) {
    final visibleReactions = reactions
        .where(
          (reaction) => reaction.count > 0 && reaction.emoji.trim().isNotEmpty,
        )
        .toList(growable: false);
    if (visibleReactions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: _scale(context, 6),
      runSpacing: _scale(context, 6),
      children: [
        for (final reaction in visibleReactions)
          GestureDetector(
            onTap: () => onReactionTap(reaction.emoji),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: EdgeInsets.symmetric(
                horizontal: _scale(context, 9),
                vertical: _scale(context, 5),
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: reaction.reactedByMe
                    ? AppColors.accent.withValues(alpha: 0.18)
                    : const Color(0xB8412A18),
                border: Border.all(
                  color: reaction.reactedByMe
                      ? AppColors.accent.withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    reaction.emoji,
                    style: TextStyle(fontSize: _scale(context, 13)),
                  ),
                  SizedBox(width: _scale(context, 4)),
                  Text(
                    reaction.count.toString(),
                    style: TextStyle(
                      fontSize: _scale(context, 12),
                      fontWeight: FontWeight.w800,
                      color: reaction.reactedByMe
                          ? AppColors.accent
                          : Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
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
    required this.onReactionTap,
    required this.onReplyPreviewTap,
    required this.onAvatarTap,
    required this.onLinkTap,
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
  final ValueChanged<String> onReactionTap;
  final VoidCallback? onReplyPreviewTap;
  final ValueChanged<String> onAvatarTap;
  final ValueChanged<String> onLinkTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final senderParticipant = participants
        .where((p) => p.userId == message.senderUserId)
        .firstOrNull;
    final senderName = _senderNameForMessage(message, participants, l10n);
    final isDeleted = message.isDeleted;
    final isSticker = message.isSticker;
    final moderationPublicComment =
        message.moderationPublicComment?.trim() ?? '';

    if (message.isSystem) {
      return _SystemMessageDivider(text: _systemMessageText(senderName, l10n));
    }

    final avatarSize = _scale(context, 44);
    final gap = _scale(context, 10);
    final senderUserId = message.senderUserId.trim();
    final avatar = _ChatAvatar(
      size: avatarSize,
      name: senderName,
      avatarFileId:
          senderParticipant?.avatarFileId ?? message.senderAvatarFileId,
    );
    final content = KeyedSubtree(
      key: messageKey,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (senderUserId.isEmpty)
            avatar
          else
            GestureDetector(
              onTap: () => onAvatarTap(senderUserId),
              behavior: HitTestBehavior.opaque,
              child: avatar,
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
                  width: isSticker
                      ? _scale(context, 184).clamp(156.0, 216.0).toDouble()
                      : double.infinity,
                  padding: EdgeInsets.all(isSticker ? 0 : _scale(context, 20)),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      _scale(context, isSticker ? 24 : 22),
                    ),
                    color: isSticker ? Colors.transparent : null,
                    gradient: isSticker
                        ? null
                        : isDeleted
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
                          : isSticker
                          ? Colors.transparent
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
                      if (!isDeleted && message.isForwarded)
                        Padding(
                          padding: EdgeInsets.only(bottom: _scale(context, 10)),
                          child: _ForwardedMessageLabel(message: message),
                        ),
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
                      if (!isDeleted && isSticker)
                        _StickerMessageAttachment(
                          fileId: message.stickerImageFileId!,
                        )
                      else if (!isDeleted && message.fileIds.isNotEmpty)
                        _MessageAttachments(fileIds: message.fileIds),
                      if (!isDeleted &&
                          message.fileIds.isNotEmpty &&
                          message.content.trim().isNotEmpty)
                        SizedBox(height: _scale(context, 12)),
                      if (isDeleted)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message.isHiddenByModerator
                                  ? l10n.chatMessageRemovedByModerator
                                  : l10n.chatMessageDeleted,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: _scale(context, 15),
                                height: 1.4,
                                color: Colors.white.withValues(alpha: 0.58),
                              ),
                            ),
                            if (message.isHiddenByModerator &&
                                moderationPublicComment.isNotEmpty) ...[
                              SizedBox(height: _scale(context, 8)),
                              Text(
                                l10n.chatModeratorComment(
                                  moderationPublicComment,
                                ),
                                style: TextStyle(
                                  fontSize: _scale(context, 14),
                                  height: 1.45,
                                  color: Colors.white.withValues(alpha: 0.72),
                                ),
                              ),
                            ],
                          ],
                        )
                      else if (message.content.trim().isNotEmpty)
                        _HyperlinkedMessageText(
                          text: message.content,
                          onLinkTap: onLinkTap,
                          style: TextStyle(
                            fontSize: _scale(context, 16),
                            height: 1.5,
                            color: Colors.white.withValues(alpha: 0.98),
                          ),
                          linkStyle: TextStyle(
                            fontSize: _scale(context, 16),
                            height: 1.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFffd08a),
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(0xFFffd08a),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isDeleted && message.reactions.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      top: _scale(context, 7),
                      left: _scale(context, 4),
                    ),
                    child: _MessageReactionStrip(
                      reactions: message.reactions,
                      onReactionTap: onReactionTap,
                    ),
                  ),
                if (!isDeleted && message.forwardCount > 0)
                  Padding(
                    padding: EdgeInsets.only(
                      top: _scale(context, 7),
                      left: _scale(context, 4),
                    ),
                    child: _ForwardCountBadge(count: message.forwardCount),
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

class _StickerMessageAttachment extends StatefulWidget {
  const _StickerMessageAttachment({required this.fileId});

  final String fileId;

  @override
  State<_StickerMessageAttachment> createState() =>
      _StickerMessageAttachmentState();
}

class _StickerMessageAttachmentState extends State<_StickerMessageAttachment> {
  Future<void> _openSticker() async {
    final asset = await _StickerImageCache.assetFor(widget.fileId);
    if (!mounted || asset == null || asset.bytes.isEmpty) return;

    if (asset.isLottieSticker) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _StickerViewerScreen(fileId: widget.fileId),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatImageViewerScreen(imageBytes: asset.bytes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => unawaited(_openSticker()),
      behavior: HitTestBehavior.opaque,
      child: AspectRatio(
        aspectRatio: 1,
        child: _StickerImage(fileId: widget.fileId, fit: BoxFit.contain),
      ),
    );
  }
}

class _StickerViewerScreen extends StatelessWidget {
  const _StickerViewerScreen({required this.fileId});

  final String fileId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF100802),
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final maxSide = math.min(
                  math.min(constraints.maxWidth, constraints.maxHeight) * 0.82,
                  420.0,
                );
                return Center(
                  child: SizedBox.square(
                    dimension: maxSide,
                    child: _StickerImage(fileId: fileId, fit: BoxFit.contain),
                  ),
                );
              },
            ),
            PositionedDirectional(
              top: _scale(context, 10),
              start: _scale(context, 10),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                color: Colors.white.withValues(alpha: 0.86),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickerAsset {
  const _StickerAsset({
    required this.bytes,
    required this.responseContentType,
    this.declaredContentType = '',
  });

  final Uint8List bytes;
  final String responseContentType;
  final String declaredContentType;

  _StickerAsset withDeclaredContentType(String contentType) {
    return _StickerAsset(
      bytes: bytes,
      responseContentType: responseContentType,
      declaredContentType: contentType,
    );
  }

  StickerAssetContentFormat get format {
    return resolveStickerAssetContentFormat(
      bytes,
      responseContentType: responseContentType,
      declaredContentType: declaredContentType,
    );
  }

  bool get isLottieSticker {
    return format == StickerAssetContentFormat.tgsGzip ||
        format == StickerAssetContentFormat.lottieJson;
  }

  LottieDecoder? get lottieDecoder {
    return format == StickerAssetContentFormat.tgsGzip
        ? LottieComposition.decodeGZip
        : null;
  }
}

class _StickerImage extends StatelessWidget {
  const _StickerImage({
    required this.fileId,
    required this.fit,
    this.declaredContentType = '',
  });

  final String fileId;
  final BoxFit fit;
  final String declaredContentType;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StickerAsset?>(
      future: _StickerImageCache.assetFor(fileId),
      builder: (context, snapshot) {
        final asset = snapshot.data?.withDeclaredContentType(
          declaredContentType,
        );
        if (asset == null || asset.bytes.isEmpty) {
          return _StickerPlaceholder(
            loading: snapshot.connectionState == ConnectionState.waiting,
          );
        }

        if (asset.isLottieSticker) {
          return Lottie.memory(
            asset.bytes,
            decoder: asset.lottieDecoder,
            errorBuilder: (context, error, stackTrace) =>
                const _StickerPlaceholder(),
            fit: fit,
            frameRate: const FrameRate(60),
            repeat: true,
            renderCache: RenderCache.drawingCommands,
          );
        }

        if (asset.format == StickerAssetContentFormat.rasterImage) {
          return Image.memory(asset.bytes, fit: fit, gaplessPlayback: true);
        }

        return const _StickerPlaceholder();
      },
    );
  }
}

class _StickerPlaceholder extends StatelessWidget {
  const _StickerPlaceholder({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_scale(context, 18)),
        color: Colors.white.withValues(alpha: 0.06),
      ),
      child: Center(
        child: loading
            ? SizedBox(
                width: _scale(context, 22),
                height: _scale(context, 22),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              )
            : Icon(
                Icons.image_not_supported_outlined,
                size: _scale(context, 26),
                color: Colors.white.withValues(alpha: 0.42),
              ),
      ),
    );
  }
}

class _StickerImageCache {
  static final FileApi _fileApi = FileApi();
  static final Map<String, Future<_StickerAsset?>> _assetFutures = {};

  static Future<_StickerAsset?> assetFor(String fileId) {
    final normalizedFileId = fileId.trim();
    if (normalizedFileId.isEmpty) {
      return Future<_StickerAsset?>.value(null);
    }

    final cached = _assetFutures[normalizedFileId];
    if (cached != null) return cached;

    final load = () async {
      try {
        final content = await _fileApi.downloadContent(normalizedFileId);
        if (content.bytes.isEmpty) {
          _assetFutures.remove(normalizedFileId);
          return null;
        }
        return _StickerAsset(
          bytes: content.bytes,
          responseContentType: content.contentType,
        );
      } catch (_) {
        _assetFutures.remove(normalizedFileId);
        return null;
      }
    }();
    _assetFutures[normalizedFileId] = load;
    return load;
  }

  static Future<void> preload(
    Iterable<String> fileIds, {
    required int limit,
    required int concurrency,
  }) async {
    final normalized = <String>[];
    final seen = <String>{};
    for (final fileId in fileIds) {
      final id = fileId.trim();
      if (id.isEmpty || !seen.add(id)) continue;
      normalized.add(id);
      if (normalized.length >= limit) break;
    }
    if (normalized.isEmpty) return;

    var nextIndex = 0;
    final safeConcurrency = concurrency < 1 ? 1 : concurrency;
    final workerCount = normalized.length < safeConcurrency
        ? normalized.length
        : safeConcurrency;

    await Future.wait(
      List.generate(workerCount, (_) async {
        while (nextIndex < normalized.length) {
          final fileId = normalized[nextIndex];
          nextIndex += 1;
          await assetFor(fileId);
        }
      }),
    );
  }
}

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
      if (!mounted || result.isDone) return;

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

    if (isVideo) {
      return ChatVideoPreview(
        fileId: item.fileId,
        borderRadius: _scale(context, 18),
        aspectRatio: 4 / 3,
      );
    }

    return _AttachmentFileRow(item: item, busy: busy, onTap: onTap);
  }
}

class _VoiceAttachmentPlayer extends StatelessWidget {
  const _VoiceAttachmentPlayer({required this.item});

  final _ChatAttachmentViewData item;

  @override
  Widget build(BuildContext context) {
    return ChatVoiceAttachmentPlayer(
      fileId: item.fileId,
      metadata: item.metadata,
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
  });

  final _ChatAttachmentViewData item;
  final bool busy;
  final VoidCallback onTap;

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
                _attachmentIcon(metadata),
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

String _formatReadReceiptAt(BuildContext context, DateTime readAt) {
  return _formatChatEventAt(context, readAt);
}

String _formatReactionAt(BuildContext context, DateTime reactedAt) {
  return _formatChatEventAt(context, reactedAt);
}

String _formatChatEventAt(BuildContext context, DateTime happenedAt) {
  final l10n = AppLocalizations.of(context)!;
  final local = happenedAt.toLocal();
  final date = DateFormat('dd.MM.yyyy', l10n.localeName).format(local);
  final time = MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  return '$date ${l10n.chatReadAtSeparator} $time';
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
                errorBuilder: (_, _, _) => Center(
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
        separatorBuilder: (_, _) => SizedBox(width: _scale(context, 10)),
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

class _PastedImagePreviewSheet extends StatelessWidget {
  const _PastedImagePreviewSheet({required this.attachment});

  final _PickedChatAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          _scale(context, 18),
          _scale(context, 12),
          _scale(context, 18),
          _scale(context, 18) + bottom,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF1d120b),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            SizedBox(height: _scale(context, 16)),
            Text(
              l10n.chatPasteImagePreviewTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFFf5f3ef),
                fontSize: _scale(context, 18),
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: _scale(context, 12)),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.42,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_scale(context, 20)),
                color: const Color(0xFF2a1a10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.memory(
                attachment.bytes,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
            SizedBox(height: _scale(context, 10)),
            Text(
              '${attachment.name} · ${_formatAttachmentSize(attachment.bytes.lengthInBytes)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: _scale(context, 12),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: _scale(context, 16)),
            _PastePreviewActionButton(
              icon: Icons.image_rounded,
              label: l10n.chatPasteSendImage,
              emphasized: true,
              onTap: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }
}

class _PastePreviewActionButton extends StatelessWidget {
  const _PastePreviewActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final bg = emphasized
        ? AppColors.accent
        : Colors.white.withValues(alpha: 0.08);
    final fg = emphasized ? Colors.white : const Color(0xFFf5f3ef);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: _scale(context, 48),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_scale(context, 16)),
          color: bg,
          border: emphasized
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: _scale(context, 19), color: fg),
            SizedBox(width: _scale(context, 7)),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg,
                  fontSize: _scale(context, 13),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
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
    if (attachment.isAudio) {
      return _PendingVoiceAttachmentChip(
        attachment: attachment,
        uploading: uploading,
        onRemove: onRemove,
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final compactMedia = attachment.isImage || attachment.isVideo;
    final width = _scale(context, compactMedia ? 118 : 184);
    final subtitle = attachment.isVideo
        ? _formatAttachmentSize(attachment.bytes.lengthInBytes)
        : '${_formatAttachmentSize(attachment.bytes.lengthInBytes)} | ${attachment.extensionLabel}';

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
                  attachment.isVideo
                      ? l10n.chatLastMessageVideo
                      : attachment.name,
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
                  subtitle,
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

class _PendingVoiceAttachmentChip extends StatefulWidget {
  const _PendingVoiceAttachmentChip({
    required this.attachment,
    required this.uploading,
    required this.onRemove,
  });

  final _PickedChatAttachment attachment;
  final bool uploading;
  final VoidCallback onRemove;

  @override
  State<_PendingVoiceAttachmentChip> createState() =>
      _PendingVoiceAttachmentChipState();
}

class _PendingVoiceAttachmentChipState
    extends State<_PendingVoiceAttachmentChip> {
  final _player = AudioPlayer();
  bool _preparing = false;
  bool _ownsPreviewFile = false;
  int _generation = 0;
  String? _preparedPath;

  @override
  void dispose() {
    _generation++;
    unawaited(_player.dispose());
    _deleteOwnedPreviewFile();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (widget.uploading) return;

    int? generation;
    try {
      final completed = _player.processingState == ProcessingState.completed;
      if (_player.playing && !completed) {
        await _player.pause();
        return;
      }

      final path = await _previewPath();
      if (path == null) return;

      if (_preparedPath != path) {
        generation = ++_generation;
        setState(() => _preparing = true);
        await _player.setFilePath(path);
        if (!mounted || generation != _generation) return;
        _preparedPath = path;
        setState(() => _preparing = false);
      }

      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      if (!mounted) return;
      unawaited(_player.play());
    } catch (_) {
      if (!mounted) return;
      await showErrorDialog(
        context,
        title: AppLocalizations.of(context)!.error,
        message: AppLocalizations.of(context)!.chatVoicePlaybackFailed,
      );
    } finally {
      if (mounted &&
          generation != null &&
          generation == _generation &&
          _preparing) {
        setState(() => _preparing = false);
      }
    }
  }

  Future<String?> _previewPath() async {
    final localPath = widget.attachment.localPath?.trim() ?? '';
    if (localPath.isNotEmpty && await File(localPath).exists()) {
      return localPath;
    }

    if (_preparedPath != null && await File(_preparedPath!).exists()) {
      return _preparedPath;
    }

    final dir = await getTemporaryDirectory();
    final dot = widget.attachment.name.lastIndexOf('.');
    final ext = dot >= 0 ? widget.attachment.name.substring(dot + 1) : 'm4a';
    final path =
        '${dir.path}/inflap_voice_preview_${widget.attachment.localId}.$ext';
    await File(path).writeAsBytes(widget.attachment.bytes, flush: true);
    _ownsPreviewFile = true;
    return path;
  }

  void _deleteOwnedPreviewFile() {
    final path = _preparedPath;
    if (!_ownsPreviewFile || path == null) return;
    unawaited(_deletePreviewFile(path));
  }

  Future<void> _deletePreviewFile(String path) async {
    try {
      await File(path).delete();
    } catch (_) {
      // Temp preview file may already be removed.
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
    final width = _scale(context, 244);
    final fallbackDuration = widget.attachment.duration ?? Duration.zero;

    return Container(
      width: width,
      padding: EdgeInsets.all(_scale(context, 10)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_scale(context, 20)),
        color: const Color(0xD12D1A0D),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snapshot) {
              final processing = snapshot.data?.processingState;
              final busy =
                  _preparing ||
                  widget.uploading ||
                  processing == ProcessingState.loading ||
                  processing == ProcessingState.buffering;
              final playing =
                  (snapshot.data?.playing ?? false) &&
                  processing != ProcessingState.completed;

              return GestureDetector(
                onTap: busy ? null : _toggle,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: _scale(context, 42),
                  height: _scale(context, 42),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                  ),
                  child: Center(
                    child: busy
                        ? SizedBox(
                            width: _scale(context, 17),
                            height: _scale(context, 17),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.1,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: _scale(context, 27),
                            color: Colors.white,
                          ),
                  ),
                ),
              );
            },
          ),
          SizedBox(width: _scale(context, 10)),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.chatVoicePreview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: _scale(context, 12),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: _scale(context, 8)),
                StreamBuilder<Duration>(
                  stream: _player.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration = _player.duration ?? fallbackDuration;
                    final progress = duration.inMilliseconds <= 0
                        ? 0.0
                        : (position.inMilliseconds / duration.inMilliseconds)
                              .clamp(0.0, 1.0);

                    return Row(
                      children: [
                        Expanded(
                          child: _VoiceWaveform(
                            progress: progress,
                            enabled:
                                duration.inMilliseconds > 0 &&
                                !_preparing &&
                                !widget.uploading,
                            onSeekFraction: (fraction) =>
                                _seekToFraction(fraction, duration),
                          ),
                        ),
                        SizedBox(width: _scale(context, 8)),
                        Text(
                          _formatVoiceDuration(
                            position == Duration.zero ? duration : position,
                          ),
                          style: TextStyle(
                            fontSize: _scale(context, 11),
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(width: _scale(context, 8)),
          GestureDetector(
            onTap: widget.uploading ? null : widget.onRemove,
            behavior: HitTestBehavior.opaque,
            child: Icon(
              Icons.close_rounded,
              color: Colors.white.withValues(
                alpha: widget.uploading ? 0.34 : 0.86,
              ),
              size: _scale(context, 21),
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

    if (attachment.isVideo) {
      return _PendingVideoAttachmentPreview(attachment: attachment);
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
          Icons.insert_drive_file_rounded,
          size: _scale(context, 34),
          color: AppColors.accent,
        ),
      ),
    );
  }
}

class _PendingVideoAttachmentPreview extends StatefulWidget {
  const _PendingVideoAttachmentPreview({required this.attachment});

  final _PickedChatAttachment attachment;

  @override
  State<_PendingVideoAttachmentPreview> createState() =>
      _PendingVideoAttachmentPreviewState();
}

class _PendingVideoAttachmentPreviewState
    extends State<_PendingVideoAttachmentPreview> {
  VideoPlayerController? _controller;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  @override
  void didUpdateWidget(covariant _PendingVideoAttachmentPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attachment.localPath == widget.attachment.localPath) return;
    unawaited(_resetController());
    unawaited(_initialize());
  }

  @override
  void dispose() {
    unawaited(_resetController());
    super.dispose();
  }

  Future<void> _initialize() async {
    final path = widget.attachment.localPath?.trim();
    if (path == null || path.isEmpty) {
      if (mounted) setState(() => _loadFailed = true);
      return;
    }

    try {
      final file = File(path);
      if (!await file.exists()) {
        throw StateError('Pending video file does not exist');
      }
      final controller = VideoPlayerController.file(file);
      try {
        await controller.initialize();
      } catch (_) {
        await controller.dispose();
        rethrow;
      }
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await _resetController();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loadFailed = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  Future<void> _resetController() async {
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }

  Future<void> _openViewer() async {
    final path = widget.attachment.localPath?.trim();
    if (path == null || path.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatVideoViewerScreen.localFile(path: path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final initialized = controller?.value.isInitialized ?? false;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => unawaited(_openViewer()),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (initialized)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: controller!.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            )
          else
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4b2d13), Color(0xFF1c0f08)],
                ),
              ),
            ),
          Center(
            child: Container(
              width: _scale(context, 34),
              height: _scale(context, 34),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.46),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: Icon(
                _loadFailed ? Icons.movie_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: _scale(context, 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceRecordingBar extends StatelessWidget {
  const _VoiceRecordingBar({
    required this.duration,
    required this.locked,
    required this.stopping,
    required this.onCancel,
    required this.onStop,
  });

  final Duration duration;
  final bool locked;
  final bool stopping;
  final VoidCallback onCancel;
  final VoidCallback onStop;

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
                        ? l10n.chatVoicePreparingPreview
                        : locked
                        ? l10n.chatVoiceRecordingLocked
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
          onTap: stopping ? null : onStop,
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
                      Icons.stop_rounded,
                      color: Colors.white,
                      size: _scale(context, 24),
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

class _ComposerActionButtonSurface extends StatelessWidget {
  const _ComposerActionButtonSurface({
    required this.size,
    required this.color,
    required this.disabled,
    required this.busy,
    required this.icon,
    required this.iconSize,
  });

  final double size;
  final Color color;
  final bool disabled;
  final bool busy;
  final IconData icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: busy
            ? SizedBox(
                width: _scale(context, 20),
                height: _scale(context, 20),
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Icon(
                icon,
                color: Colors.white.withValues(alpha: disabled ? 0.36 : 1),
                size: iconSize,
              ),
      ),
    );
  }
}

class _VoiceGestureButton extends StatefulWidget {
  const _VoiceGestureButton({
    required this.size,
    required this.disabled,
    required this.busy,
    required this.recording,
    required this.onStart,
    required this.onStartLocked,
    required this.onLock,
    required this.onStopForPreview,
    required this.onCancel,
  });

  final double size;
  final bool disabled;
  final bool busy;
  final bool recording;
  final Future<void> Function() onStart;
  final Future<void> Function() onStartLocked;
  final VoidCallback onLock;
  final VoidCallback onStopForPreview;
  final VoidCallback onCancel;

  @override
  State<_VoiceGestureButton> createState() => _VoiceGestureButtonState();
}

class _VoiceGestureButtonState extends State<_VoiceGestureButton> {
  static const _lockDistance = 74.0;

  bool _pressing = false;
  bool _locked = false;
  bool _lockRequested = false;
  bool _stopRequested = false;
  bool _cancelRequested = false;
  Future<void>? _startFuture;

  @override
  void didUpdateWidget(covariant _VoiceGestureButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recording && !widget.recording && !_pressing) {
      _resetPendingGestureState();
    }
  }

  void _startHold() {
    if (widget.disabled || widget.busy || _pressing) return;
    setState(() {
      _pressing = true;
      _locked = false;
      _lockRequested = false;
      _stopRequested = false;
      _cancelRequested = false;
    });
    _startFuture = widget.onStart();
  }

  void _lockHold() {
    if (!_pressing || _lockRequested) return;
    setState(() {
      _locked = true;
      _lockRequested = true;
      _stopRequested = false;
      _cancelRequested = false;
    });
    _runAfterStart(widget.onLock, shouldRun: () => _lockRequested);
  }

  void _finishHold() {
    if (!_pressing) return;
    setState(() {
      _pressing = false;
      _locked = false;
      _stopRequested = !_lockRequested;
    });
    if (!_lockRequested) {
      _runAfterStart(
        widget.onStopForPreview,
        shouldRun: () => _stopRequested && !_lockRequested,
      );
    }
  }

  void _cancelHold() {
    if (!_pressing) return;
    setState(() {
      _pressing = false;
      _locked = false;
      _cancelRequested = !_lockRequested;
    });
    if (!_lockRequested) {
      _runAfterStart(
        widget.onCancel,
        shouldRun: () => _cancelRequested && !_lockRequested,
      );
    }
  }

  void _runAfterStart(
    VoidCallback action, {
    required bool Function() shouldRun,
  }) {
    final startFuture = _startFuture;
    if (startFuture == null) {
      if (shouldRun()) action();
      return;
    }

    unawaited(
      startFuture.whenComplete(() {
        if (!mounted || !shouldRun()) return;
        action();
      }),
    );
  }

  void _resetPendingGestureState() {
    _locked = false;
    _lockRequested = false;
    _stopRequested = false;
    _cancelRequested = false;
    _startFuture = null;
    if (_pressing) {
      _pressing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _pressing || widget.recording;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        if (_pressing && !_locked)
          Positioned(
            right: 0,
            bottom: widget.size + _scale(context, 10),
            child: _VoiceLockHint(),
          ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.disabled || widget.busy
              ? null
              : () => unawaited(widget.onStartLocked()),
          onLongPressStart: (_) => _startHold(),
          onLongPressMoveUpdate: (details) {
            if (details.offsetFromOrigin.dy <= -_lockDistance) {
              _lockHold();
            }
          },
          onLongPressEnd: (_) => _finishHold(),
          onLongPressCancel: _cancelHold,
          child: _ComposerActionButtonSurface(
            size: widget.size,
            color: active ? Colors.red : AppColors.accent,
            disabled: widget.disabled,
            busy: widget.busy,
            icon: Icons.mic_rounded,
            iconSize: active ? 24 : 22,
          ),
        ),
      ],
    );
  }
}

class _VoiceLockHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: l10n.chatVoiceSlideUpToLock,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _scale(context, 9),
            vertical: _scale(context, 8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.white.withValues(alpha: 0.86),
                size: _scale(context, 18),
              ),
              Icon(
                Icons.lock_open_rounded,
                color: AppColors.accent,
                size: _scale(context, 18),
              ),
            ],
          ),
        ),
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
    required this.onPickGallery,
    required this.onPickFile,
    required this.onPickAudio,
    required this.onCameraCapture,
    required this.onRemoveAttachment,
    required this.onCancelReply,
    required this.onVoiceStart,
    required this.onVoiceStartLocked,
    required this.onVoiceLock,
    required this.onVoiceCancel,
    required this.onVoiceStop,
    required this.activePanel,
    required this.stickerPacks,
    required this.activeStickerPackIndex,
    required this.stickersLoading,
    required this.stickersLoadFailed,
    required this.onPanelChanged,
    required this.onEmojiSelected,
    required this.onPasteRequested,
    required this.onPasteImageRequested,
    required this.onStickerPackSelected,
    required this.onStickerSelected,
    required this.onRetryStickers,
    required this.sending,
    required this.attachmentUploading,
    required this.voiceRecording,
    required this.voiceRecordingLocked,
    required this.voicePressActive,
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
  final VoidCallback onPickGallery;
  final VoidCallback onPickFile;
  final VoidCallback onPickAudio;
  final VoidCallback onCameraCapture;
  final ValueChanged<int> onRemoveAttachment;
  final VoidCallback onCancelReply;
  final Future<void> Function() onVoiceStart;
  final Future<void> Function() onVoiceStartLocked;
  final VoidCallback onVoiceLock;
  final VoidCallback onVoiceCancel;
  final VoidCallback onVoiceStop;
  final _ComposerPanel activePanel;
  final List<StickerPackVm> stickerPacks;
  final int activeStickerPackIndex;
  final bool stickersLoading;
  final bool stickersLoadFailed;
  final ValueChanged<_ComposerPanel> onPanelChanged;
  final ValueChanged<String> onEmojiSelected;
  final VoidCallback onPasteRequested;
  final VoidCallback onPasteImageRequested;
  final ValueChanged<int> onStickerPackSelected;
  final ValueChanged<StickerVm> onStickerSelected;
  final VoidCallback onRetryStickers;
  final bool sending;
  final bool attachmentUploading;
  final bool voiceRecording;
  final bool voiceRecordingLocked;
  final bool voicePressActive;
  final bool voiceStopping;
  final Duration voiceDuration;
  final bool messagingClosed;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final hz = _scale(context, 8);
    final btnSize = _scale(context, 42).clamp(40.0, 44.0).toDouble();
    final itemGap = _scale(context, 6);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.fromLTRB(
        hz,
        _scale(context, 8),
        hz,
        _scale(context, 10) + mq.padding.bottom,
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
          if (voiceRecording && !voicePressActive) ...[
            _VoiceRecordingBar(
              duration: voiceDuration,
              locked: voiceRecordingLocked,
              stopping: voiceStopping,
              onCancel: onVoiceCancel,
              onStop: onVoiceStop,
            ),
          ] else
            Row(
              children: [
                _ComposerCircleButton(
                  size: btnSize,
                  // Show the upload spinner on the paperclip — that is the
                  // button users associate with file/gallery uploads.
                  loading: attachmentUploading,
                  icon: Icons.attach_file_rounded,
                  semanticLabel: l10n.chatComposerAttachButtonLabel,
                  onTap: attachmentUploading || messagingClosed
                      ? null
                      : () {
                          onPanelChanged(_ComposerPanel.none);
                          _showAttachSheet(context, l10n);
                        },
                ),
                SizedBox(width: itemGap),
                Expanded(
                  child: Container(
                    height: btnSize,
                    padding: EdgeInsets.symmetric(
                      horizontal: _scale(context, 12),
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
                            onTap: () => onPanelChanged(_ComposerPanel.none),
                            onChanged: (_) => onTyping(),
                            onSubmitted: (_) => onSend(),
                            contextMenuBuilder: (context, editableTextState) {
                              final items = editableTextState
                                  .contextMenuButtonItems
                                  .where(
                                    (item) =>
                                        item.type !=
                                        ContextMenuButtonType.paste,
                                  )
                                  .toList(growable: true);
                              items.insert(
                                0,
                                ContextMenuButtonItem(
                                  label: l10n.chatComposerPaste,
                                  onPressed: () {
                                    ContextMenuController.removeAny();
                                    onPasteRequested();
                                  },
                                ),
                              );
                              items.add(
                                ContextMenuButtonItem(
                                  label: l10n.chatComposerPasteImage,
                                  onPressed: () {
                                    ContextMenuController.removeAny();
                                    onPasteImageRequested();
                                  },
                                ),
                              );
                              return AdaptiveTextSelectionToolbar.buttonItems(
                                anchors: editableTextState.contextMenuAnchors,
                                buttonItems: items,
                              );
                            },
                            textInputAction: TextInputAction.send,
                            maxLines: 1,
                            textAlignVertical: TextAlignVertical.center,
                            enabled: !attachmentUploading && !messagingClosed,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFFf5f3ef),
                              letterSpacing: 0,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              hintText: messagingClosed
                                  ? l10n.chatComposerClosedHint
                                  : attachmentUploading
                                  ? l10n.chatAttachmentUploading
                                  : l10n.chatComposerHint,
                              hintStyle: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withValues(alpha: 0.48),
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: l10n.chatComposerEmojiButtonLabel,
                          enabled: !messagingClosed && !attachmentUploading,
                          child: GestureDetector(
                            onTap: messagingClosed || attachmentUploading
                                ? null
                                : () {
                                    final nextPanel =
                                        activePanel == _ComposerPanel.none
                                        ? _ComposerPanel.emoji
                                        : _ComposerPanel.none;
                                    onPanelChanged(nextPanel);
                                  },
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: Icon(
                                Icons.emoji_emotions_outlined,
                                size: 22,
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Camera button stays one tap away when there is no draft,
                // matching the compact WhatsApp composer rhythm.
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    final hasDraft =
                        value.text.trim().isNotEmpty ||
                        pendingAttachments.isNotEmpty;
                    if (hasDraft) return const SizedBox.shrink();
                    return Padding(
                      padding: EdgeInsets.only(left: itemGap),
                      child: _ComposerCircleButton(
                        size: btnSize,
                        icon: Icons.camera_alt_rounded,
                        semanticLabel: l10n.chatComposerCameraButtonLabel,
                        onTap: attachmentUploading || messagingClosed
                            ? null
                            : onCameraCapture,
                      ),
                    );
                  },
                ),
                SizedBox(width: itemGap),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    final hasDraft =
                        value.text.trim().isNotEmpty ||
                        pendingAttachments.isNotEmpty;
                    final disabled =
                        sending || attachmentUploading || messagingClosed;
                    final showMic = !hasDraft;

                    if (showMic) {
                      return _VoiceGestureButton(
                        size: btnSize,
                        disabled: disabled,
                        busy: sending || attachmentUploading,
                        recording: voiceRecording && voicePressActive,
                        onStart: onVoiceStart,
                        onStartLocked: onVoiceStartLocked,
                        onLock: onVoiceLock,
                        onStopForPreview: onVoiceStop,
                        onCancel: onVoiceCancel,
                      );
                    }

                    return GestureDetector(
                      onTap: disabled ? null : onSend,
                      child: _ComposerActionButtonSurface(
                        size: btnSize,
                        color: const Color(0xFFff9d00),
                        disabled: disabled,
                        busy: sending || attachmentUploading,
                        icon: Icons.send_rounded,
                        iconSize: 20,
                      ),
                    );
                  },
                ),
              ],
            ),
          if (activePanel != _ComposerPanel.none) ...[
            SizedBox(height: _scale(context, 10)),
            _InlineEmojiStickerPanel(
              activePanel: activePanel,
              stickerPacks: stickerPacks,
              activeStickerPackIndex: activeStickerPackIndex,
              stickersLoading: stickersLoading,
              stickersLoadFailed: stickersLoadFailed,
              onPanelChanged: onPanelChanged,
              onEmojiSelected: onEmojiSelected,
              onStickerPackSelected: onStickerPackSelected,
              onStickerSelected: onStickerSelected,
              onRetryStickers: onRetryStickers,
            ),
          ],
        ],
      ),
    );
  }

  // Paperclip sheet — gallery, file, audio.
  void _showAttachSheet(BuildContext context, AppLocalizations l10n) {
    final actions = <_ComposerSheetAction>[
      _ComposerSheetAction(
        icon: Icons.photo_library_rounded,
        label: l10n.chatAttachmentPhotoVideo,
        onSelected: onPickGallery,
      ),
      _ComposerSheetAction(
        icon: Icons.insert_drive_file_rounded,
        label: l10n.chatAttachmentFile,
        onSelected: onPickFile,
      ),
      _ComposerSheetAction(
        icon: Icons.audiotrack_rounded,
        label: l10n.chatAttachmentAudio,
        onSelected: onPickAudio,
      ),
    ];
    _showAdaptiveAttachmentSheet(
      context: context,
      title: l10n.chatAttachmentAttachTitle,
      cancelLabel: l10n.chatAttachmentCancel,
      actions: actions,
    );
  }
}

// ── Composer sub-widgets / sheet helpers ─────────────────────────

const _chatEmojiChoices = <String>[
  '😀',
  '😄',
  '😂',
  '😊',
  '😍',
  '😘',
  '😎',
  '🥳',
  '😇',
  '🙂',
  '😉',
  '🤔',
  '😅',
  '😭',
  '😤',
  '👍',
  '🙏',
  '👏',
  '🔥',
  '❤️',
  '💛',
  '✨',
  '🎉',
  '✅',
  '👀',
  '📍',
  '🧭',
  '✈️',
  '🏔️',
  '🏝️',
  '🌅',
  '🧳',
];

void _insertComposerToken(TextEditingController controller, String value) {
  final current = controller.value;
  final text = current.text;
  final selection = current.selection;
  final start = selection.isValid
      ? selection.start.clamp(0, text.length).toInt()
      : text.length;
  final end = selection.isValid
      ? selection.end.clamp(0, text.length).toInt()
      : text.length;
  final normalizedStart = start <= end ? start : end;
  final normalizedEnd = start <= end ? end : start;
  final nextText = text.replaceRange(normalizedStart, normalizedEnd, value);
  final nextOffset = normalizedStart + value.length;

  controller.value = current.copyWith(
    text: nextText,
    selection: TextSelection.collapsed(offset: nextOffset),
    composing: TextRange.empty,
  );
}

class _InlineEmojiStickerPanel extends StatelessWidget {
  const _InlineEmojiStickerPanel({
    required this.activePanel,
    required this.stickerPacks,
    required this.activeStickerPackIndex,
    required this.stickersLoading,
    required this.stickersLoadFailed,
    required this.onPanelChanged,
    required this.onEmojiSelected,
    required this.onStickerPackSelected,
    required this.onStickerSelected,
    required this.onRetryStickers,
  });

  final _ComposerPanel activePanel;
  final List<StickerPackVm> stickerPacks;
  final int activeStickerPackIndex;
  final bool stickersLoading;
  final bool stickersLoadFailed;
  final ValueChanged<_ComposerPanel> onPanelChanged;
  final ValueChanged<String> onEmojiSelected;
  final ValueChanged<int> onStickerPackSelected;
  final ValueChanged<StickerVm> onStickerSelected;
  final VoidCallback onRetryStickers;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final panelHeight = _scale(context, 286).clamp(250.0, 318.0).toDouble();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      height: panelHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_scale(context, 18)),
        color: const Color(0xFF1d120b),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              _scale(context, 12),
              _scale(context, 10),
              _scale(context, 12),
              _scale(context, 8),
            ),
            child: Row(
              children: [
                _ComposerPanelTabButton(
                  label: l10n.chatComposerEmojiTab,
                  selected: activePanel == _ComposerPanel.emoji,
                  onTap: () => onPanelChanged(_ComposerPanel.emoji),
                ),
                SizedBox(width: _scale(context, 8)),
                _ComposerPanelTabButton(
                  label: l10n.chatComposerStickerTab,
                  selected: activePanel == _ComposerPanel.stickers,
                  onTap: () => onPanelChanged(_ComposerPanel.stickers),
                ),
              ],
            ),
          ),
          Expanded(
            child: activePanel == _ComposerPanel.emoji
                ? _EmojiGrid(onSelected: onEmojiSelected)
                : _StickerGrid(
                    packs: stickerPacks,
                    activePackIndex: activeStickerPackIndex,
                    loading: stickersLoading,
                    loadFailed: stickersLoadFailed,
                    onRetry: onRetryStickers,
                    onPackSelected: onStickerPackSelected,
                    onStickerSelected: onStickerSelected,
                  ),
          ),
        ],
      ),
    );
  }
}

class _ComposerPanelTabButton extends StatelessWidget {
  const _ComposerPanelTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: _scale(context, 38),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected
                ? AppColors.accent.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: selected
                  ? AppColors.accent.withValues(alpha: 0.42)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: _scale(context, 13),
              fontWeight: FontWeight.w800,
              color: selected
                  ? const Color(0xFFffd08a)
                  : Colors.white.withValues(alpha: 0.64),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmojiGrid extends StatelessWidget {
  const _EmojiGrid({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rawColumns = (constraints.maxWidth / 44).floor();
        final columns = rawColumns.clamp(6, 9).toInt();

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
            _scale(context, 12),
            _scale(context, 6),
            _scale(context, 12),
            _scale(context, 16),
          ),
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: _scale(context, 6),
            crossAxisSpacing: _scale(context, 4),
          ),
          itemCount: _chatEmojiChoices.length,
          itemBuilder: (context, index) {
            final value = _chatEmojiChoices[index];
            return Semantics(
              button: true,
              label: value,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onSelected(value),
                child: Center(
                  child: Text(
                    value,
                    style: TextStyle(fontSize: _scale(context, 26), height: 1),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StickerGrid extends StatelessWidget {
  const _StickerGrid({
    required this.packs,
    required this.activePackIndex,
    required this.loading,
    required this.loadFailed,
    required this.onRetry,
    required this.onPackSelected,
    required this.onStickerSelected,
  });

  final List<StickerPackVm> packs;
  final int activePackIndex;
  final bool loading;
  final bool loadFailed;
  final VoidCallback onRetry;
  final ValueChanged<int> onPackSelected;
  final ValueChanged<StickerVm> onStickerSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (loading && packs.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (loadFailed && packs.isEmpty) {
      return _StickerPanelMessage(
        icon: Icons.cloud_off_rounded,
        title: l10n.chatStickerLoadFailed,
        actionLabel: l10n.retryButton,
        onAction: onRetry,
      );
    }

    final safeIndex = packs.isEmpty
        ? 0
        : activePackIndex.clamp(0, packs.length - 1).toInt();
    final activePack = packs.isEmpty ? null : packs[safeIndex];
    final stickers = activePack?.stickers ?? const <StickerVm>[];

    return Column(
      children: [
        if (packs.isNotEmpty)
          SizedBox(
            height: _scale(context, 42),
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: _scale(context, 12)),
              scrollDirection: Axis.horizontal,
              itemCount: packs.length,
              separatorBuilder: (_, _) => SizedBox(width: _scale(context, 8)),
              itemBuilder: (context, index) {
                final pack = packs[index];
                final selected = index == safeIndex;
                return _StickerPackChip(
                  title: pack.titleFor(
                    Localizations.localeOf(context).languageCode,
                  ),
                  selected: selected,
                  onTap: () => onPackSelected(index),
                );
              },
            ),
          ),
        Expanded(
          child: stickers.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: _scale(context, 24),
                    ),
                    child: Text(
                      l10n.stickersEmptySearch,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: _scale(context, 13),
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.68),
                      ),
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final rawColumns = (constraints.maxWidth / 82).floor();
                    final columns = rawColumns.clamp(4, 6).toInt();

                    return GridView.builder(
                      padding: EdgeInsets.fromLTRB(
                        _scale(context, 12),
                        _scale(context, 8),
                        _scale(context, 12),
                        _scale(context, 16),
                      ),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: _scale(context, 10),
                        crossAxisSpacing: _scale(context, 10),
                      ),
                      itemCount: stickers.length,
                      itemBuilder: (context, index) {
                        final sticker = stickers[index];
                        return _StickerPickerButton(
                          sticker: sticker,
                          onTap: () => onStickerSelected(sticker),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _StickerPackChip extends StatelessWidget {
  const _StickerPackChip({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: _scale(context, 12)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected
                ? AppColors.accent.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: selected
                  ? AppColors.accent.withValues(alpha: 0.42)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: _scale(context, 12),
              fontWeight: FontWeight.w800,
              color: selected
                  ? const Color(0xFFffd08a)
                  : Colors.white.withValues(alpha: 0.68),
            ),
          ),
        ),
      ),
    );
  }
}

class _StickerPickerButton extends StatelessWidget {
  const _StickerPickerButton({required this.sticker, required this.onTap});

  final StickerVm sticker;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppLocalizations.of(context)!.chatStickerMessage,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_scale(context, 16)),
            color: Colors.white.withValues(alpha: 0.07),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: EdgeInsets.all(_scale(context, 8)),
            child: _StickerImage(
              fileId: sticker.fileId,
              fit: BoxFit.contain,
              declaredContentType: sticker.contentType,
            ),
          ),
        ),
      ),
    );
  }
}

class _StickerPanelMessage extends StatelessWidget {
  const _StickerPanelMessage({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: _scale(context, 24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: _scale(context, 30),
              color: Colors.white.withValues(alpha: 0.42),
            ),
            SizedBox(height: _scale(context, 10)),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _scale(context, 13),
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.68),
              ),
            ),
            SizedBox(height: _scale(context, 12)),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel,
                style: const TextStyle(color: AppColors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerSheetAction {
  const _ComposerSheetAction({
    required this.icon,
    required this.label,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final VoidCallback onSelected;
}

// _showAdaptiveAttachmentSheet picks the platform-native presentation:
// Cupertino action sheet on iOS/macOS, custom Material bottom sheet (matching
// the chat dark theme) on Android and other platforms.
void _showAdaptiveAttachmentSheet({
  required BuildContext context,
  required String title,
  required String cancelLabel,
  required List<_ComposerSheetAction> actions,
}) {
  final platform = Theme.of(context).platform;
  if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: Text(title),
        actions: [
          for (final a in actions)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(sheetContext);
                a.onSelected();
              },
              child: Text(a.label),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(sheetContext),
          child: Text(cancelLabel),
        ),
      ),
    );
    return;
  }

  showModalBottomSheet<void>(
    context: context,
    isDismissible: true,
    backgroundColor: const Color(0xFF1d120b),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
            for (final a in actions)
              ListTile(
                leading: Icon(a.icon, color: const Color(0xFFff9800)),
                title: Text(
                  a.label,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  a.onSelected();
                },
              ),
          ],
        ),
      ),
    ),
  );
}

class _ComposerCircleButton extends StatelessWidget {
  const _ComposerCircleButton({
    required this.size,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.loading = false,
  });

  final double size;
  final IconData icon;
  final VoidCallback? onTap;
  final String semanticLabel;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Semantics(
      button: true,
      label: semanticLabel,
      enabled: !disabled,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
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
            child: loading
                ? SizedBox(
                    width: size * 0.4,
                    height: size * 0.4,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.accent,
                    ),
                  )
                : Icon(
                    icon,
                    size: size * 0.45,
                    color: Colors.white.withValues(
                      alpha: disabled ? 0.36 : 0.9,
                    ),
                  ),
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
