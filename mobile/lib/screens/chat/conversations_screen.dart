import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/files/chat_file_cache.dart';
import '../../core/network/file_api.dart';
import '../../core/ui/app_colors.dart';
import '../../features/chat/models/conversation_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/chat_provider.dart';
import '../../providers/session_provider.dart';
import 'widgets/chat_video_preview.dart';

const _videoPreviewDownloadLimitBytes = 25 * 1024 * 1024;

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ChatProvider>();
      provider.loadConversations();
      provider.connectWebSocket();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.select<SessionProvider, String>(
      (session) => session.profile?.userId ?? '',
    );

    return Scaffold(
      backgroundColor: const Color(0xFF100802),
      appBar: _buildAppBar(context),
      body: Consumer<ChatProvider>(
        builder: (context, chat, _) {
          if (chat.conversationsLoading && chat.conversations.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          if (chat.conversationsError != null && chat.conversations.isEmpty) {
            return _buildError(chat);
          }

          if (chat.conversations.isEmpty) {
            return _buildEmpty(context);
          }

          return RefreshIndicator(
            color: AppColors.accent,
            backgroundColor: const Color(0xFF1a0d03),
            onRefresh: () => chat.loadConversations(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: chat.conversations.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 86,
                color: Colors.white.withValues(alpha: 0.06),
              ),
              itemBuilder: (context, index) {
                return _ConversationTile(
                  conversation: chat.conversations[index],
                  currentUserId: currentUserId,
                  onTap: () => _openChat(chat.conversations[index]),
                );
              },
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppBar(
      backgroundColor: const Color(0xFF1a0d03),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        color: AppColors.textPrimary,
        onPressed: () => context.pop(),
      ),
      title: Text(
        l10n.chatListTitle,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.03 * 24,
          color: AppColors.textPrimary,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildError(ChatProvider chat) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.chatListLoadFailed,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => chat.loadConversations(),
              child: Text(
                l10n.retryButton,
                style: const TextStyle(color: AppColors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 56,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.chatListEmpty,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _openChat(ConversationVm conversation) {
    context.push('/chats/${conversation.id}');
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
  });

  final ConversationVm conversation;
  final String currentUserId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _buildAvatar(l10n),
            const SizedBox(width: 14),
            Expanded(child: _buildContent(context, l10n)),
            if (conversation.unreadCount > 0) ...[
              const SizedBox(width: 10),
              _buildUnreadBadge(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(AppLocalizations l10n) {
    final title = _displayTitle(l10n);
    final imageUrl = _avatarUrl;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: conversation.isGroup
              ? [const Color(0xFF4a2d14), const Color(0xFF2a1608)]
              : [const Color(0xFFf3d7b3), const Color(0xFF6f3f22)],
        ),
      ),
      foregroundDecoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(child: _fallbackInitial(title)),
            if (imageUrl != null)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Center(child: _fallbackInitial(title)),
              ),
          ],
        ),
      ),
    );
  }

  String? get _avatarUrl {
    if (conversation.isActivity) {
      final activityId = (conversation.activityId ?? '').trim();
      if (activityId.isNotEmpty) {
        return '${AppConfig.apiBaseUrl}/activities/$activityId/cover';
      }
      return null;
    }

    return resolvePublicFileContentUrl(
      conversation.displayAvatarFileId(currentUserId) ?? '',
    );
  }

  Widget _fallbackInitial(String name) {
    return Text(
      _initials(name),
      style: TextStyle(
        fontSize: conversation.isActivity ? 22 : 18,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
      ),
    );
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    if (conversation.isActivity) {
      return trimmed[0].toUpperCase();
    }
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed[0].toUpperCase();
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    final title = _displayTitle(l10n);
    final lastMessage = conversation.lastMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.02 * 17,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTime(conversation.lastActivityAt, l10n),
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
        if (lastMessage != null) ...[
          const SizedBox(height: 5),
          _LastMessagePreviewLine(
            message: lastMessage,
            textStyle: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.46),
              letterSpacing: -0.02 * 14,
            ),
          ),
        ],
      ],
    );
  }

  String _displayTitle(AppLocalizations l10n) {
    if (conversation.isDirect) {
      final peerName =
          conversation.directPeer(currentUserId)?.displayName.trim() ?? '';
      if (peerName.isNotEmpty) return peerName;
    }

    final title = conversation.title?.trim() ?? '';
    return title.isEmpty ? l10n.chatFallbackTitle : title;
  }

  Widget _buildUnreadBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        conversation.unreadCount > 99 ? '99+' : '${conversation.unreadCount}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  String _formatTime(DateTime dt, AppLocalizations l10n) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inDays == 0) {
      return DateFormat.Hm(l10n.localeName).format(local);
    }
    if (diff.inDays == 1) return l10n.chatDateYesterday;
    if (diff.inDays < 7) {
      return DateFormat.E(l10n.localeName).format(local);
    }
    return DateFormat.MMMd(l10n.localeName).format(local);
  }
}

class _LastMessagePreviewLine extends StatefulWidget {
  const _LastMessagePreviewLine({
    required this.message,
    required this.textStyle,
  });

  final LastMessagePreview message;
  final TextStyle textStyle;

  @override
  State<_LastMessagePreviewLine> createState() =>
      _LastMessagePreviewLineState();
}

class _LastMessagePreviewLineState extends State<_LastMessagePreviewLine> {
  final _fileApi = FileApi();
  final _fileCache = ChatFileCache();
  Future<_LastAttachmentPreviewData?>? _attachmentFuture;

  @override
  void initState() {
    super.initState();
    _attachmentFuture = _loadAttachmentPreview(widget.message);
  }

  @override
  void didUpdateWidget(covariant _LastMessagePreviewLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.id != widget.message.id ||
        oldWidget.message.fileIds.join(',') !=
            widget.message.fileIds.join(',')) {
      _attachmentFuture = _loadAttachmentPreview(widget.message);
    }
  }

  Future<_LastAttachmentPreviewData?> _loadAttachmentPreview(
    LastMessagePreview message,
  ) async {
    if (message.isDeleted || message.isSticker || !message.hasFiles) {
      return null;
    }

    final fileId = message.fileIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .firstOrNull;
    if (fileId == null) return null;

    FileMetadataVm? metadata;
    Uint8List? imageBytes;

    try {
      metadata = await _fileApi.getFileMetadata(fileId);
      if (metadata.isImage) {
        final downloaded = await _fileCache.downloadedFile(
          fileId,
          metadata: metadata,
        );
        if (downloaded != null) {
          imageBytes = await downloaded.file.readAsBytes();
        } else {
          final content = await _fileApi.downloadContent(fileId);
          imageBytes = content.bytes.isEmpty ? null : content.bytes;
        }
      }
    } catch (_) {
      // Keep the list readable while metadata catches up or the network is slow.
    }

    return _LastAttachmentPreviewData(
      fileId: fileId,
      metadata: metadata,
      imageBytes: imageBytes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<_LastAttachmentPreviewData?>(
      future: _attachmentFuture,
      builder: (context, snapshot) {
        final attachment = snapshot.data;
        return _buildPreviewRow(
          text: _previewText(l10n, attachment),
          attachment: attachment,
        );
      },
    );
  }

  Widget _buildPreviewRow({
    required String text,
    required _LastAttachmentPreviewData? attachment,
  }) {
    return Row(
      children: [
        if (attachment?.hasThumbnail ?? false) ...[
          _AttachmentPreviewThumb(attachment: attachment!),
          const SizedBox(width: 7),
        ],
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: widget.textStyle,
          ),
        ),
      ],
    );
  }

  String _previewText(
    AppLocalizations l10n,
    _LastAttachmentPreviewData? attachment,
  ) {
    final message = widget.message;
    if (message.isDeleted) return l10n.chatMessageDeleted;
    if (message.senderDisplayName.trim().toLowerCase() == 'system') {
      return message.contentPreview;
    }

    final preview = _previewBody(l10n, attachment);
    final sender = message.senderDisplayName.trim();
    if (sender.isEmpty) return preview;
    return '$sender: $preview';
  }

  String _previewBody(
    AppLocalizations l10n,
    _LastAttachmentPreviewData? attachment,
  ) {
    final message = widget.message;
    if (message.isSticker) return l10n.chatStickerMessage;

    final metadata = attachment?.metadata;
    if (metadata?.isImage ?? false) return l10n.chatLastMessagePhoto;
    if (metadata?.isVideo ?? false) return l10n.chatLastMessageVideo;
    if (metadata != null && message.hasFiles) {
      final name = _displayFileName(metadata);
      return name.isEmpty
          ? l10n.chatSharedFileFallback(_shortId(attachment!.fileId))
          : name;
    }

    final contentPreview = message.contentPreview.trim();
    if (contentPreview.isNotEmpty) return contentPreview;
    if (message.hasFiles) return l10n.chatAttachmentFile;
    return message.contentPreview;
  }
}

class _AttachmentPreviewThumb extends StatelessWidget {
  const _AttachmentPreviewThumb({required this.attachment});

  final _LastAttachmentPreviewData attachment;

  @override
  Widget build(BuildContext context) {
    const size = 32.0;
    final metadata = attachment.metadata;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: size,
        height: size,
        child: metadata?.isVideo ?? false
            ? ChatVideoPreview(
                fileId: attachment.fileId,
                aspectRatio: 1,
                borderRadius: 8,
                enablePlayback: false,
                loadLocalPreview: true,
                maxLocalPreviewBytes: _videoPreviewDownloadLimitBytes,
                playBadgeSize: 18,
              )
            : Image.memory(
                attachment.imageBytes!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
      ),
    );
  }
}

class _LastAttachmentPreviewData {
  const _LastAttachmentPreviewData({
    required this.fileId,
    required this.metadata,
    required this.imageBytes,
  });

  final String fileId;
  final FileMetadataVm? metadata;
  final Uint8List? imageBytes;

  bool get hasThumbnail =>
      (metadata?.isImage ?? false) && imageBytes != null ||
      (metadata?.isVideo ?? false);
}

String _shortId(String id) {
  final value = id.trim();
  if (value.length <= 8) return value;
  return value.substring(0, 8);
}

String _displayFileName(FileMetadataVm metadata) {
  final name = metadata.originalName.trim();
  if (name.isEmpty) return '';

  final extension = metadata.extensionLabel.trim().toLowerCase();
  if (extension.isEmpty || extension == 'file') return name;

  final lowerName = name.toLowerCase();
  if (lowerName.endsWith('.$extension')) return name;

  final lastSegment = name.split(RegExp(r'[/\\]')).last;
  if (lastSegment.contains('.')) return name;

  return '$name.$extension';
}
