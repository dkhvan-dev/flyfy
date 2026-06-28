import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/files/chat_file_cache.dart';
import '../../core/network/file_api.dart';
import '../../core/ui/error_dialog.dart';
import '../../features/chat/models/conversation_vm.dart';
import '../../features/chat/utils/chat_message_display_text.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/chat_provider.dart';
import '../../providers/session_provider.dart';
import 'widgets/chat_video_preview.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

const _videoPreviewDownloadLimitBytes = 25 * 1024 * 1024;

enum _ConversationListTab { personal, activities, excursions }

enum _ConversationAction { toggleMute }

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  _ConversationListTab _selectedTab = _ConversationListTab.personal;
  String _searchQuery = '';

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
      backgroundColor: AppPalette.warmInk05,
      appBar: _buildAppBar(context),
      body: Consumer<ChatProvider>(
        builder: (context, chat, _) {
          if (chat.conversationsLoading && chat.conversations.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppPalette.primary),
            );
          }

          if (chat.conversationsError != null && chat.conversations.isEmpty) {
            return _buildError(chat);
          }

          if (chat.conversations.isEmpty) {
            return _buildEmpty(context);
          }

          final conversations = _filterConversations(
            chat.conversations,
            currentUserId,
          );

          return DefaultTabController(
            length: _ConversationListTab.values.length,
            initialIndex: _selectedTab.index,
            child: Column(
              children: [
                _buildSearchField(context),
                _buildTabs(context),
                Expanded(
                  child: RefreshIndicator(
                    color: AppPalette.primary,
                    backgroundColor: AppPalette.warmInk32,
                    onRefresh: () => chat.loadConversations(forceRefresh: true),
                    child: conversations.isEmpty
                        ? _buildFilteredEmptyList(context)
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const AppEdgeInsets.symmetric(vertical: 8),
                            itemCount: conversations.length,
                            separatorBuilder: (_, _) => Divider(
                              height: 1,
                              indent: 86,
                              color: AppPalette.white.withValues(alpha: 0.06),
                            ),
                            itemBuilder: (context, index) {
                              final conversation = conversations[index];
                              return _ConversationTile(
                                conversation: conversation,
                                currentUserId: currentUserId,
                                onTap: () => _openChat(conversation),
                                onLongPress: () =>
                                    _showConversationActions(conversation),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppBar(
      backgroundColor: AppPalette.warmInk32,
      surfaceTintColor: AppPalette.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        color: AppPalette.textPrimary,
        onPressed: () => _handleBack(context),
      ),
      title: Text(
        l10n.chatListTitle,
        style: const AppTextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.03 * 24,
          color: AppPalette.textPrimary,
        ),
      ),
      centerTitle: true,
    );
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/');
  }

  Widget _buildSearchField(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const AppEdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        textInputAction: TextInputAction.search,
        style: const AppTextStyle(color: AppPalette.textPrimary, fontSize: 16),
        cursorColor: AppPalette.primary,
        onChanged: (value) => setState(() {
          _searchQuery = value;
        }),
        decoration: AppInputDecoration(
          hintText: l10n.chatListSearchHint,
          hintStyle: AppTextStyle(
            color: AppPalette.white.withValues(alpha: 0.38),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppPalette.white.withValues(alpha: 0.42),
          ),
          filled: true,
          fillColor: AppPalette.white.withValues(alpha: 0.07),
          contentPadding: const AppEdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: AppBorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppBorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppPalette.white.withValues(alpha: 0.06),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppBorderRadius.circular(16),
            borderSide: const BorderSide(color: AppPalette.primary, width: 1.2),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Align(
      alignment: Alignment.centerLeft,
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: AppPalette.transparent,
        indicatorColor: AppPalette.primary,
        indicatorWeight: 3,
        labelColor: AppPalette.textPrimary,
        unselectedLabelColor: AppPalette.white.withValues(alpha: 0.48),
        labelStyle: const AppTextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const AppTextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        padding: const AppEdgeInsets.symmetric(horizontal: 8),
        labelPadding: const AppEdgeInsets.symmetric(horizontal: 12),
        onTap: (index) => setState(() {
          _selectedTab = _ConversationListTab.values[index];
        }),
        tabs: [
          Tab(text: l10n.chatListPersonalTab),
          Tab(text: l10n.chatListActivitiesTab),
          Tab(text: l10n.chatListExcursionsTab),
        ],
      ),
    );
  }

  Widget _buildFilteredEmptyList(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const AppEdgeInsets.symmetric(horizontal: 32),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
        _buildEmpty(
          context,
          message: _searchQuery.trim().isEmpty
              ? AppLocalizations.of(context)!.chatListEmpty
              : AppLocalizations.of(context)!.chatListSearchEmpty,
        ),
      ],
    );
  }

  Widget _buildError(ChatProvider chat) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const AppEdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppPalette.textCoolSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.chatListLoadFailed,
              style: const AppTextStyle(
                color: AppPalette.textCoolSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => chat.loadConversations(),
              child: Text(
                l10n.retryButton,
                style: const AppTextStyle(color: AppPalette.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, {String? message}) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 56,
            color: AppPalette.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            message ?? l10n.chatListEmpty,
            textAlign: TextAlign.center,
            style: AppTextStyle(
              color: AppPalette.white.withValues(alpha: 0.4),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<ConversationVm> _filterConversations(
    List<ConversationVm> conversations,
    String currentUserId,
  ) {
    return conversations
        .where(_matchesSelectedTab)
        .where(
          (conversation) => _matchesSearchQuery(conversation, currentUserId),
        )
        .toList(growable: false);
  }

  bool _matchesSelectedTab(ConversationVm conversation) {
    return switch (_selectedTab) {
      _ConversationListTab.personal =>
        !conversation.isActivity && !conversation.isExcursion,
      _ConversationListTab.activities =>
        conversation.isActivity && !conversation.isExcursion,
      _ConversationListTab.excursions => conversation.isExcursion,
    };
  }

  bool _matchesSearchQuery(ConversationVm conversation, String currentUserId) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;

    final values = <String>[
      conversation.displayTitle(currentUserId),
      conversation.title ?? '',
      conversation.lastMessage?.contentPreview ?? '',
      conversation.lastMessage?.senderDisplayName ?? '',
      for (final participant in conversation.participants)
        participant.displayName,
    ];

    return values.any((value) => value.toLowerCase().contains(query));
  }

  void _openChat(ConversationVm conversation) {
    context.push('/chats/${conversation.id}');
  }

  Future<void> _showConversationActions(ConversationVm conversation) async {
    final l10n = AppLocalizations.of(context)!;
    final isMuted = conversation.isMutedNow;
    final action = await showAppModalBottomSheet<_ConversationAction>(
      context: context,
      isDismissible: true,
      backgroundColor: AppPalette.warmInk55,
      shape: const RoundedRectangleBorder(
        borderRadius: AppBorderRadius.vertical(
          top: AppRadiusValue.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const AppEdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Icon(
                isMuted
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_rounded,
                color: AppPalette.primary,
              ),
              title: Text(
                isMuted
                    ? l10n.chatUnmuteNotificationsAction
                    : l10n.chatMuteNotificationsAction,
                style: const AppTextStyle(
                  color: AppPalette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () => Navigator.of(
                sheetContext,
              ).pop(_ConversationAction.toggleMute),
            ),
          ),
        );
      },
    );
    if (action != _ConversationAction.toggleMute || !mounted) return;

    final ok = await context.read<ChatProvider>().setConversationMuted(
      conversation.id,
      muted: !isMuted,
    );
    if (!ok && mounted) {
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.chatMuteUpdateFailed,
      );
    }
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
    required this.onLongPress,
  });

  final ConversationVm conversation;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const AppEdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      decoration: AppBoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: conversation.isGroup
              ? [AppPalette.warmSurface84, AppPalette.warmInk112]
              : [AppPalette.orangeLight34, AppPalette.warmSurfaceHigh18],
        ),
      ),
      foregroundDecoration: AppBoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppPalette.white.withValues(alpha: 0.12),
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
                errorBuilder: (_, _, _) =>
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
      style: AppTextStyle(
        fontSize: conversation.isActivity ? 22 : 18,
        fontWeight: FontWeight.w900,
        color: AppPalette.textPrimary,
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
                style: const AppTextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.02 * 17,
                  color: AppPalette.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (conversation.isMutedNow) ...[
              Icon(
                Icons.notifications_off_rounded,
                size: 16,
                color: AppPalette.white.withValues(alpha: 0.32),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              _formatTime(conversation.lastActivityAt, l10n),
              style: AppTextStyle(
                fontSize: 13,
                color: AppPalette.white.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
        if (lastMessage != null) ...[
          const SizedBox(height: 5),
          _LastMessagePreviewLine(
            message: lastMessage,
            textStyle: AppTextStyle(
              fontSize: 14,
              color: AppPalette.white.withValues(alpha: 0.46),
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
      padding: const AppEdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: AppBoxDecoration(
        color: AppPalette.primary,
        borderRadius: AppBorderRadius.circular(12),
      ),
      child: Text(
        conversation.unreadCount > 99 ? '99+' : '${conversation.unreadCount}',
        style: const AppTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppPalette.white,
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
          text: chatLastMessagePreviewText(
            message: widget.message,
            l10n: l10n,
            attachmentMetadata: attachment?.metadata,
            attachmentFileId: attachment?.fileId,
          ),
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
}

class _AttachmentPreviewThumb extends StatelessWidget {
  const _AttachmentPreviewThumb({required this.attachment});

  final _LastAttachmentPreviewData attachment;

  @override
  Widget build(BuildContext context) {
    const size = 32.0;
    final metadata = attachment.metadata;

    return ClipRRect(
      borderRadius: AppBorderRadius.circular(8),
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
