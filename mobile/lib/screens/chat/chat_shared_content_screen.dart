import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';
import 'package:inflap/core/ui/error_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/files/chat_file_cache.dart';
import '../../core/network/chat_api.dart';
import '../../core/network/file_api.dart';
import '../../features/chat/models/conversation_vm.dart';
import '../../features/chat/models/message_vm.dart';
import '../../features/chat/utils/chat_link_utils.dart';
import '../../l10n/generated/app_localizations.dart';
import 'chat_image_viewer_screen.dart';
import 'widgets/chat_video_preview.dart';
import 'widgets/chat_voice_attachment_player.dart';

enum _SharedTab { media, links, files, voice }

class ChatSharedContentResult {
  const ChatSharedContentResult.goToMessage(this.messageId);

  final String messageId;
}

class ChatSharedContentScreen extends StatefulWidget {
  const ChatSharedContentScreen({
    super.key,
    required this.conversation,
    required this.currentUserId,
    required this.initialMessages,
  });

  final ConversationDetail conversation;
  final String currentUserId;
  final List<MessageVm> initialMessages;

  @override
  State<ChatSharedContentScreen> createState() =>
      _ChatSharedContentScreenState();
}

class _ChatSharedContentScreenState extends State<ChatSharedContentScreen> {
  final _chatApi = ChatApi();
  final _fileApi = FileApi();
  final _fileCache = ChatFileCache();

  _SharedTab _selectedTab = _SharedTab.media;
  List<MessageVm> _messages = const [];
  Map<String, FileMetadataVm?> _fileMetaById = const {};
  Map<String, Uint8List> _fileImageBytesById = const {};
  Map<String, bool> _fileDownloadedById = const {};
  final Set<String> _busyFileIds = {};
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _messages = _uniqueMessages(widget.initialMessages);
    unawaited(_loadSharedContent());
  }

  Future<void> _loadSharedContent() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      var collected = _uniqueMessages(_messages);
      var cursor = collected.isNotEmpty ? collected.last.id : null;

      while (mounted) {
        final page = await _chatApi.listMessages(
          widget.conversation.id,
          limit: 100,
          cursor: cursor,
        );
        if (page.isEmpty) {
          break;
        }

        collected = _uniqueMessages([...collected, ...page]);
        if (mounted) {
          setState(() => _messages = collected);
        }
        await _loadFileMetadata(collected);

        if (page.length < 100) {
          break;
        }
        cursor = page.last.id;
      }

      await _loadFileMetadata(collected);
      if (!mounted) return;
      setState(() {
        _messages = collected;
        _loading = false;
      });
    } catch (e) {
      await _loadFileMetadata(_messages);
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadFileMetadata(List<MessageVm> messages) async {
    final fileIds = messages
        .where((message) => !message.isDeleted && !message.isSystem)
        .expand((message) => message.fileIds)
        .map((fileId) => fileId.trim())
        .where((fileId) => fileId.isNotEmpty)
        .toSet()
        .where((fileId) => !_fileMetaById.containsKey(fileId))
        .toList(growable: false);

    if (fileIds.isEmpty) return;

    final fetched = await Future.wait(fileIds.map(_fetchFile));
    if (!mounted) return;

    final nextMeta = Map<String, FileMetadataVm?>.of(_fileMetaById);
    final nextImageBytes = Map<String, Uint8List>.of(_fileImageBytesById);
    final nextDownloaded = Map<String, bool>.of(_fileDownloadedById);
    for (final item in fetched) {
      nextMeta[item.fileId] = item.metadata;
      nextDownloaded[item.fileId] = item.downloaded;
      if (item.imageBytes != null) {
        nextImageBytes[item.fileId] = item.imageBytes!;
      }
    }

    setState(() {
      _fileMetaById = nextMeta;
      _fileImageBytesById = nextImageBytes;
      _fileDownloadedById = nextDownloaded;
    });
  }

  Future<_FetchedFile> _fetchFile(String fileId) async {
    FileMetadataVm? metadata;
    try {
      metadata = await _fileApi.getFileMetadata(fileId);
    } catch (_) {
      return _FetchedFile(fileId: fileId);
    }

    Uint8List? imageBytes;
    final downloaded = await _fileCache.downloadedFile(
      fileId,
      metadata: metadata,
    );

    if (metadata.isImage && downloaded != null) {
      try {
        imageBytes = await downloaded.file.readAsBytes();
      } catch (_) {
        imageBytes = null;
      }
    } else if (metadata.isImage) {
      try {
        final content = await _fileApi.downloadContent(fileId);
        imageBytes = content.bytes.isEmpty ? null : content.bytes;
      } catch (_) {
        imageBytes = null;
      }
    }

    return _FetchedFile(
      fileId: fileId,
      metadata: metadata,
      imageBytes: imageBytes,
      downloaded: downloaded != null,
    );
  }

  Future<void> _handleSharedFileTap(_SharedFileRef item) async {
    if (_busyFileIds.contains(item.fileId)) return;

    if (item.downloaded) {
      await _openDownloadedFile(item);
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
      setState(() {
        _fileDownloadedById = {..._fileDownloadedById, item.fileId: true};
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.chatAttachmentDownloaded),
          backgroundColor: AppPalette.warmSurface56,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.chatAttachmentDownloadFailed,
      );
    } finally {
      if (mounted) {
        setState(() => _busyFileIds.remove(item.fileId));
      }
    }
  }

  Future<void> _openDownloadedFile(_SharedFileRef item) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final downloaded = await _fileCache.downloadedFile(
        item.fileId,
        metadata: item.metadata,
      );
      if (!mounted) return;

      if (downloaded == null) {
        setState(() {
          _fileDownloadedById = {..._fileDownloadedById, item.fileId: false};
        });
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

  Future<void> _showGoToMessageAction(String messageId) async {
    final normalizedMessageId = messageId.trim();
    if (normalizedMessageId.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final action = await showAppModalBottomSheet<String>(
      context: context,
      isDismissible: true,
      backgroundColor: AppPalette.warmInk55,
      shape: const RoundedRectangleBorder(
        borderRadius: AppBorderRadius.vertical(
          top: AppRadiusValue.circular(20),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const AppEdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.subdirectory_arrow_left_rounded,
                  color: AppPalette.primary,
                ),
                title: Text(
                  l10n.chatSharedGoToMessageAction,
                  style: const AppTextStyle(
                    color: AppPalette.orangeWash10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => Navigator.of(sheetContext).pop('go_to_message'),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text(l10n.cancelButton),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || action != 'go_to_message') return;
    Navigator.of(
      context,
    ).pop(ChatSharedContentResult.goToMessage(normalizedMessageId));
  }

  Future<void> _handleSharedLinkTap(_SharedLinkRef item) async {
    final internalRoute = _internalAppRouteForUrl(item.url);
    if (internalRoute != null) {
      context.push(internalRoute);
      return;
    }

    final uri = _externalUriForUrl(item.url);
    if (uri == null) return;

    final confirmed = await _confirmExternalLinkOpen(uri);
    if (!mounted || !confirmed) return;

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (mounted && !opened) {
      final l10n = AppLocalizations.of(context)!;
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.chatExternalLinkOpenFailed,
      );
    }
  }

  Future<bool> _confirmExternalLinkOpen(Uri uri) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAppModalDialog<bool>(
      context: context,
      builder: (dialogContext) => AppModalDialogCard(
        backgroundColor: AppPalette.warmInk55,
        title: Text(
          l10n.chatExternalLinkTitle,
          style: const AppTextStyle(color: AppPalette.white),
        ),
        content: Text(
          l10n.chatExternalLinkMessage(uri.toString()),
          style: const AppTextStyle(color: AppPalette.orangeWash10),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final media = _sharedFiles
        .where((item) => item.metadata?.isMedia ?? false)
        .toList(growable: false);
    final voiceMessages = _sharedFiles
        .where((item) {
          final metadataKnown = _fileMetaById.containsKey(item.fileId);
          return metadataKnown && (item.metadata?.isAudio ?? false);
        })
        .toList(growable: false);
    final files = _sharedFiles
        .where((item) {
          final metadataKnown = _fileMetaById.containsKey(item.fileId);
          return metadataKnown && !_isSharedMediaOrAudio(item.metadata);
        })
        .toList(growable: false);
    final links = _sharedLinks(l10n);
    final contentWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = contentWidth < 360 ? 14.0 : 16.0;
    final profileUserId = widget.conversation.isDirect
        ? widget.conversation.directPeer(widget.currentUserId)?.userId.trim() ??
              ''
        : '';

    return Scaffold(
      backgroundColor: AppPalette.warmInk14,
      body: Container(
        decoration: const AppBoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -1),
            radius: 0.92,
            colors: [AppPalette.warmOverlayMuted02, AppPalette.clearWarmInk01],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth.clamp(320.0, 430.0);

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _SharedHeader(
                        title: _sharedTitle(l10n),
                        participantCount:
                            widget.conversation.participants.length,
                        showParticipantCount: !widget.conversation.isDirect,
                        horizontalPadding: horizontalPadding,
                        onTitleTap: profileUserId.isEmpty
                            ? null
                            : () {
                                context.push('/users/$profileUserId/profile');
                              },
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: AppEdgeInsets.fromLTRB(
                          horizontalPadding,
                          22,
                          horizontalPadding,
                          0,
                        ),
                        child: _SharedTabs(
                          selected: _selectedTab,
                          onChanged: (tab) {
                            setState(() => _selectedTab = tab);
                          },
                        ),
                      ),
                    ),
                    if (_error != null &&
                        (media.isNotEmpty ||
                            links.isNotEmpty ||
                            files.isNotEmpty ||
                            voiceMessages.isNotEmpty))
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: AppEdgeInsets.fromLTRB(
                            horizontalPadding,
                            18,
                            horizontalPadding,
                            0,
                          ),
                          child: const _PartialLoadWarning(),
                        ),
                      ),
                    ..._buildSelectedSlivers(
                      media: media,
                      links: links,
                      files: files,
                      voiceMessages: voiceMessages,
                      horizontalPadding: horizontalPadding,
                      l10n: l10n,
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.paddingOf(context).bottom + 28,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildSelectedSlivers({
    required List<_SharedFileRef> media,
    required List<_SharedLinkRef> links,
    required List<_SharedFileRef> files,
    required List<_SharedFileRef> voiceMessages,
    required double horizontalPadding,
    required AppLocalizations l10n,
  }) {
    switch (_selectedTab) {
      case _SharedTab.media:
        return _buildMediaSlivers(media, horizontalPadding, l10n);
      case _SharedTab.links:
        return _buildLinksSlivers(links, horizontalPadding, l10n);
      case _SharedTab.files:
        return _buildFilesSlivers(files, horizontalPadding, l10n);
      case _SharedTab.voice:
        return _buildVoiceSlivers(voiceMessages, horizontalPadding, l10n);
    }
  }

  List<Widget> _buildMediaSlivers(
    List<_SharedFileRef> media,
    double horizontalPadding,
    AppLocalizations l10n,
  ) {
    if (media.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _EmptyOrLoadingState(
            loading: _loading,
            error: _error,
            title: l10n.chatSharedNoMediaTitle,
            subtitle: l10n.chatSharedNoMediaSubtitle,
            onRetry: _loadSharedContent,
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: AppEdgeInsets.fromLTRB(
          horizontalPadding,
          24,
          horizontalPadding,
          0,
        ),
        sliver: SliverList.list(
          children: _groupByDate(media, (item) => item.message.sentAt, l10n)
              .map(
                (group) => _MediaGroup(
                  group: group,
                  busyFileIds: _busyFileIds,
                  onFileTap: _handleSharedFileTap,
                  onGoToMessage: _showGoToMessageAction,
                ),
              )
              .toList(growable: false),
        ),
      ),
    ];
  }

  List<Widget> _buildLinksSlivers(
    List<_SharedLinkRef> links,
    double horizontalPadding,
    AppLocalizations l10n,
  ) {
    if (links.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _EmptyOrLoadingState(
            loading: _loading,
            error: _error,
            title: l10n.chatSharedNoLinksTitle,
            subtitle: l10n.chatSharedNoLinksSubtitle,
            onRetry: _loadSharedContent,
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: AppEdgeInsets.fromLTRB(
          horizontalPadding,
          34,
          horizontalPadding,
          0,
        ),
        sliver: SliverList.list(
          children: _groupByDate(links, (item) => item.message.sentAt, l10n)
              .map(
                (group) => _LinksGroup(
                  group: group,
                  onLinkTap: _handleSharedLinkTap,
                  onGoToMessage: _showGoToMessageAction,
                ),
              )
              .toList(growable: false),
        ),
      ),
    ];
  }

  List<Widget> _buildFilesSlivers(
    List<_SharedFileRef> files,
    double horizontalPadding,
    AppLocalizations l10n,
  ) {
    if (files.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _EmptyOrLoadingState(
            loading: _loading,
            error: _error,
            title: l10n.chatSharedNoFilesTitle,
            subtitle: l10n.chatSharedNoFilesSubtitle,
            onRetry: _loadSharedContent,
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: AppEdgeInsets.fromLTRB(
          horizontalPadding,
          28,
          horizontalPadding,
          0,
        ),
        sliver: SliverList.list(
          children: _groupByDate(files, (item) => item.message.sentAt, l10n)
              .map(
                (group) => _FilesGroup(
                  group: group,
                  busyFileIds: _busyFileIds,
                  onFileTap: _handleSharedFileTap,
                  onGoToMessage: _showGoToMessageAction,
                ),
              )
              .toList(growable: false),
        ),
      ),
    ];
  }

  List<Widget> _buildVoiceSlivers(
    List<_SharedFileRef> voiceMessages,
    double horizontalPadding,
    AppLocalizations l10n,
  ) {
    if (voiceMessages.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _EmptyOrLoadingState(
            loading: _loading,
            error: _error,
            title: l10n.chatSharedNoVoiceTitle,
            subtitle: l10n.chatSharedNoVoiceSubtitle,
            onRetry: _loadSharedContent,
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: AppEdgeInsets.fromLTRB(
          horizontalPadding,
          28,
          horizontalPadding,
          0,
        ),
        sliver: SliverList.list(
          children:
              _groupByDate(voiceMessages, (item) => item.message.sentAt, l10n)
                  .map(
                    (group) => _VoiceMessagesGroup(
                      group: group,
                      onGoToMessage: _showGoToMessageAction,
                    ),
                  )
                  .toList(growable: false),
        ),
      ),
    ];
  }

  List<_SharedFileRef> get _sharedFiles {
    final items = <_SharedFileRef>[];
    for (final message in _messages) {
      if (message.isDeleted || message.isSystem) continue;
      for (final rawFileId in message.fileIds) {
        final fileId = rawFileId.trim();
        if (fileId.isEmpty) continue;
        items.add(
          _SharedFileRef(
            message: message,
            fileId: fileId,
            metadata: _fileMetaById[fileId],
            imageBytes: _fileImageBytesById[fileId],
            downloaded: _fileDownloadedById[fileId] ?? false,
          ),
        );
      }
    }
    return items;
  }

  List<_SharedLinkRef> _sharedLinks(AppLocalizations l10n) {
    final items = <_SharedLinkRef>[];
    for (final message in _messages) {
      if (message.isDeleted || message.isSystem) continue;
      final content = message.content.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (content.isEmpty) continue;

      for (final match in _urlRegex.allMatches(content)) {
        final rawUrl = match.group(0) ?? '';
        final url = _cleanUrl(rawUrl);
        if (url.isEmpty) continue;

        final participant = _participantFor(message.senderUserId);
        items.add(
          _SharedLinkRef(
            message: message,
            url: url,
            snippet: _snippetAroundUrl(
              content: content,
              matchStart: match.start,
              matchEnd: match.start + url.length,
            ),
            senderName: _senderName(message, participant, l10n),
            senderAvatarFileId:
                participant?.avatarFileId ?? message.senderAvatarFileId,
          ),
        );
      }
    }
    return items;
  }

  ParticipantInfo? _participantFor(String userId) {
    for (final participant in widget.conversation.participants) {
      if (participant.userId == userId) return participant;
    }
    return null;
  }

  String _senderName(
    MessageVm message,
    ParticipantInfo? participant,
    AppLocalizations l10n,
  ) {
    final participantName = participant?.displayName.trim();
    if (participantName != null && participantName.isNotEmpty) {
      return participantName;
    }

    final messageName = message.senderDisplayName.trim();
    if (messageName.isNotEmpty) return messageName;
    return l10n.chatUserFallbackName;
  }

  String _sharedTitle(AppLocalizations l10n) {
    if (widget.conversation.isDirect) {
      final peerName =
          widget.conversation
              .directPeer(widget.currentUserId)
              ?.displayName
              .trim() ??
          '';
      if (peerName.isNotEmpty) return peerName;
    }

    final title = widget.conversation.title?.trim() ?? '';
    return title.isEmpty ? l10n.chatFallbackTitle : title;
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
      final byDate = b.sentAt.compareTo(a.sentAt);
      if (byDate != 0) return byDate;
      return b.id.compareTo(a.id);
    });
    return result;
  }
}

class _SharedHeader extends StatelessWidget {
  const _SharedHeader({
    required this.title,
    required this.participantCount,
    required this.showParticipantCount,
    required this.horizontalPadding,
    required this.onTitleTap,
  });

  final String title;
  final int participantCount;
  final bool showParticipantCount;
  final double horizontalPadding;
  final VoidCallback? onTitleTap;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: AppEdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding + 18,
        horizontalPadding,
        18,
      ),
      decoration: AppBoxDecoration(
        color: AppPalette.warmOverlayInk03,
        border: Border(
          bottom: BorderSide(color: AppPalette.white.withValues(alpha: 0.07)),
        ),
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: _SharedBackButton(onTap: () => Navigator.of(context).pop()),
          ),
          Padding(
            padding: const AppEdgeInsets.symmetric(horizontal: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onTitleTap,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    title.trim().isEmpty
                        ? l10n.chatFallbackTitle
                        : title.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyle(
                      fontSize: MediaQuery.sizeOf(context).width < 360
                          ? 22
                          : 24,
                      height: 1.12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.9,
                      color: AppPalette.orangeWash16,
                    ),
                  ),
                ),
                if (showParticipantCount) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: AppBoxDecoration(
                          shape: BoxShape.circle,
                          color: AppPalette.primary,
                          boxShadow: [
                            BoxShadow(
                              color: AppPalette.primary.withValues(alpha: 0.08),
                              blurRadius: 0,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.chatParticipantsCount(participantCount),
                        style: const AppTextStyle(
                          fontSize: 16,
                          height: 1,
                          fontWeight: FontWeight.w500,
                          color: AppPalette.orangeSoft36,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SharedBackButton extends StatelessWidget {
  const _SharedBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: const SizedBox(
        width: 40,
        height: 40,
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 24,
          color: AppPalette.orangeWash16,
        ),
      ),
    );
  }
}

class _SharedTabs extends StatelessWidget {
  const _SharedTabs({required this.selected, required this.onChanged});

  final _SharedTab selected;
  final ValueChanged<_SharedTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: AppEdgeInsets.all(compact ? 8 : 10),
      decoration: AppBoxDecoration(
        color: AppPalette.warmOverlaySurface07,
        borderRadius: AppBorderRadius.circular(999),
        border: Border.all(color: AppPalette.white.withValues(alpha: 0.02)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SharedTabButton(
              label: l10n.chatSharedMediaTab,
              active: selected == _SharedTab.media,
              compact: compact,
              onTap: () => onChanged(_SharedTab.media),
            ),
            SizedBox(width: compact ? 6 : 8),
            _SharedTabButton(
              label: l10n.chatSharedLinksTab,
              active: selected == _SharedTab.links,
              compact: compact,
              onTap: () => onChanged(_SharedTab.links),
            ),
            SizedBox(width: compact ? 6 : 8),
            _SharedTabButton(
              label: l10n.chatSharedFilesTab,
              active: selected == _SharedTab.files,
              compact: compact,
              onTap: () => onChanged(_SharedTab.files),
            ),
            SizedBox(width: compact ? 6 : 8),
            _SharedTabButton(
              label: l10n.chatSharedVoiceTab,
              active: selected == _SharedTab.voice,
              compact: compact,
              onTap: () => onChanged(_SharedTab.voice),
            ),
          ],
        ),
      ),
    );
  }
}

class _SharedTabButton extends StatelessWidget {
  const _SharedTabButton({
    required this.label,
    required this.active,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: compact ? 58 : 66,
        constraints: BoxConstraints(minWidth: compact ? 92 : 104),
        padding: AppEdgeInsets.symmetric(horizontal: compact ? 16 : 20),
        alignment: Alignment.center,
        decoration: AppBoxDecoration(
          color: active ? AppPalette.primary : AppPalette.transparent,
          borderRadius: AppBorderRadius.circular(999),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppPalette.primary.withValues(alpha: 0.22),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: AppTextStyle(
            fontSize: compact ? 14 : 16,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: compact ? 0.2 : 0.6,
            color: active ? AppPalette.textWarm : AppPalette.orangeLight12,
          ),
        ),
      ),
    );
  }
}

class _MediaGroup extends StatelessWidget {
  const _MediaGroup({
    required this.group,
    required this.busyFileIds,
    required this.onFileTap,
    required this.onGoToMessage,
  });

  final _DateGroup<_SharedFileRef> group;
  final Set<String> busyFileIds;
  final ValueChanged<_SharedFileRef> onFileTap;
  final ValueChanged<String> onGoToMessage;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final gap = width < 360 ? 10.0 : 14.0;
    final radius = width < 360 ? 22.0 : 28.0;

    return Padding(
      padding: const AppEdgeInsets.only(bottom: 38),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(group.label),
          const SizedBox(height: 18),
          GridView.builder(
            itemCount: group.items.length,
            shrinkWrap: true,
            padding: AppEdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: gap,
              mainAxisSpacing: gap,
            ),
            itemBuilder: (context, index) {
              final item = group.items[index];
              return _MediaTile(
                item: item,
                radius: radius,
                busy: busyFileIds.contains(item.fileId),
                onTap: () => onFileTap(item),
                onLongPress: () => onGoToMessage(item.message.id),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.item,
    required this.radius,
    required this.busy,
    required this.onTap,
    required this.onLongPress,
  });

  final _SharedFileRef item;
  final double radius;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final isVideo = item.metadata?.isVideo ?? false;
    final isImage = item.metadata?.isImage ?? false;

    if (isVideo) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: onLongPress,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ChatVideoPreview(
              fileId: item.fileId,
              aspectRatio: 1,
              borderRadius: radius,
              loadLocalPreview: true,
              playBadgeSize: 44,
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: _SharedDownloadBadge(
                downloaded: item.downloaded,
                busy: busy,
              ),
            ),
          ],
        ),
      );
    }

    final tile = ClipRRect(
      borderRadius: AppBorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: AppBoxDecoration(
          gradient: _fallbackGradient(item.fileId),
          boxShadow: [
            BoxShadow(
              color: AppPalette.black.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isImage && item.imageBytes != null)
              Image.memory(
                item.imageBytes!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            DecoratedBox(
              decoration: AppBoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppPalette.white.withValues(alpha: 0.03),
                    AppPalette.black.withValues(alpha: 0.08),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: _SharedDownloadBadge(
                downloaded: item.downloaded,
                busy: busy,
              ),
            ),
          ],
        ),
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: tile,
    );
  }
}

class _LinksGroup extends StatelessWidget {
  const _LinksGroup({
    required this.group,
    required this.onLinkTap,
    required this.onGoToMessage,
  });

  final _DateGroup<_SharedLinkRef> group;
  final ValueChanged<_SharedLinkRef> onLinkTap;
  final ValueChanged<String> onGoToMessage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const AppEdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const AppEdgeInsets.symmetric(horizontal: 4),
            child: _SectionTitle(group.label),
          ),
          const SizedBox(height: 14),
          ...group.items.map(
            (item) => Padding(
              padding: const AppEdgeInsets.only(bottom: 12),
              child: _LinkItem(
                item: item,
                onTap: () => onLinkTap(item),
                onLongPress: () => onGoToMessage(item.message.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkItem extends StatelessWidget {
  const _LinkItem({
    required this.item,
    required this.onTap,
    required this.onLongPress,
  });

  final _SharedLinkRef item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return _CompactLinkCard(
      item: item,
      hostLabel: _linkHostLabel(item.url),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

class _CompactLinkCard extends StatelessWidget {
  const _CompactLinkCard({
    required this.item,
    required this.hostLabel,
    required this.onTap,
    required this.onLongPress,
  });

  final _SharedLinkRef item;
  final String hostLabel;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: AppEdgeInsets.fromLTRB(
          compact ? 12 : 14,
          compact ? 11 : 12,
          compact ? 12 : 14,
          compact ? 11 : 12,
        ),
        decoration: AppBoxDecoration(
          color: AppPalette.warmInk75,
          borderRadius: AppBorderRadius.circular(18),
          border: Border.all(color: AppPalette.white.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: AppPalette.black.withValues(alpha: 0.14),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _SharedAvatar(
              size: 40,
              name: item.senderName,
              avatarFileId: item.senderAvatarFileId,
            ),
            SizedBox(width: compact ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.link_rounded,
                        size: compact ? 15 : 16,
                        color: AppPalette.primary,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          hostLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle(
                            fontSize: compact ? 13 : 14,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            color: AppPalette.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.snippet,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle(
                      fontSize: compact ? 14 : 15,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.orangeWash02,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.senderName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle(
                      fontSize: compact ? 12 : 13,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.white.withValues(alpha: 0.48),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.open_in_new_rounded,
              size: compact ? 18 : 20,
              color: AppPalette.white.withValues(alpha: 0.44),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilesGroup extends StatelessWidget {
  const _FilesGroup({
    required this.group,
    required this.busyFileIds,
    required this.onFileTap,
    required this.onGoToMessage,
  });

  final _DateGroup<_SharedFileRef> group;
  final Set<String> busyFileIds;
  final ValueChanged<_SharedFileRef> onFileTap;
  final ValueChanged<String> onGoToMessage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const AppEdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const AppEdgeInsets.symmetric(horizontal: 14),
            child: _SectionTitle(group.label),
          ),
          const SizedBox(height: 16),
          ...group.items.map(
            (item) => Padding(
              padding: const AppEdgeInsets.only(bottom: 18),
              child: _FileCard(
                item: item,
                busy: busyFileIds.contains(item.fileId),
                onTap: () => onFileTap(item),
                onLongPress: () => onGoToMessage(item.message.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({
    required this.item,
    required this.busy,
    required this.onTap,
    required this.onLongPress,
  });

  final _SharedFileRef item;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 380;
    final l10n = AppLocalizations.of(context)!;
    final metadata = item.metadata;
    final name = (metadata?.originalName.trim().isNotEmpty ?? false)
        ? metadata!.originalName.trim()
        : l10n.chatSharedFileFallback(_shortId(item.fileId));
    final label = metadata == null
        ? l10n.chatSharedUnknownFile
        : '${_formatSize(metadata.sizeBytes)} | ${metadata.extensionLabel}';
    final icon = _fileIcon(metadata);
    final iconColor = _fileIconColor(metadata);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: BoxConstraints(minHeight: compact ? 136 : 148),
        padding: AppEdgeInsets.fromLTRB(16, 18, compact ? 14 : 18, 18),
        decoration: AppBoxDecoration(
          color: AppPalette.warmSurface11,
          borderRadius: AppBorderRadius.circular(30),
          border: Border.all(color: AppPalette.white.withValues(alpha: 0.025)),
          boxShadow: [
            BoxShadow(
              color: AppPalette.black.withValues(alpha: 0.12),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: compact ? 72 : 78,
              height: compact ? 72 : 78,
              decoration: AppBoxDecoration(
                color: AppPalette.warmSurface56,
                borderRadius: AppBorderRadius.circular(24),
              ),
              child: Icon(icon, size: 38, color: iconColor),
            ),
            SizedBox(width: compact ? 14 : 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle(
                      fontSize: compact ? 21 : 23,
                      height: 1.18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.7,
                      color: AppPalette.orangeWash04,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${_downloadStatusLabel(context, item.downloaded, busy)} | $label',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle(
                      fontSize: compact ? 16 : 17,
                      height: 1.2,
                      color: AppPalette.orangeSoft04,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _SharedDownloadBadge(
              downloaded: item.downloaded,
              busy: busy,
              size: compact ? 42 : 46,
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceMessagesGroup extends StatelessWidget {
  const _VoiceMessagesGroup({required this.group, required this.onGoToMessage});

  final _DateGroup<_SharedFileRef> group;
  final ValueChanged<String> onGoToMessage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const AppEdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const AppEdgeInsets.symmetric(horizontal: 14),
            child: _SectionTitle(group.label),
          ),
          const SizedBox(height: 14),
          ...group.items.map(
            (item) => Padding(
              padding: const AppEdgeInsets.only(bottom: 14),
              child: _VoiceMessageCard(
                item: item,
                onLongPress: () => onGoToMessage(item.message.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceMessageCard extends StatelessWidget {
  const _VoiceMessageCard({required this.item, required this.onLongPress});

  final _SharedFileRef item;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: AppBoxDecoration(
          color: AppPalette.warmSurface11,
          borderRadius: AppBorderRadius.circular(24),
          border: Border.all(color: AppPalette.white.withValues(alpha: 0.025)),
          boxShadow: [
            BoxShadow(
              color: AppPalette.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const AppEdgeInsets.all(12),
          child: ChatVoiceAttachmentPlayer(
            fileId: item.fileId,
            metadata: item.metadata,
            dense: true,
            backgroundColor: AppPalette.black.withValues(alpha: 0.12),
            borderColor: AppPalette.white.withValues(alpha: 0.04),
          ),
        ),
      ),
    );
  }
}

class _SharedDownloadBadge extends StatelessWidget {
  const _SharedDownloadBadge({
    required this.downloaded,
    required this.busy,
    this.size = 34,
  });

  final bool downloaded;
  final bool busy;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: AppBoxDecoration(
        shape: BoxShape.circle,
        color: downloaded
            ? AppPalette.primary
            : AppPalette.warmOverlaySurface16,
        border: Border.all(color: AppPalette.white.withValues(alpha: 0.14)),
      ),
      child: Center(
        child: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppPalette.white,
                ),
              )
            : Icon(
                downloaded
                    ? Icons.open_in_full_rounded
                    : Icons.download_rounded,
                size: size * 0.52,
                color: AppPalette.white,
              ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyle(
        fontSize: MediaQuery.sizeOf(context).width < 360 ? 15 : 16,
        height: 1.1,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.6,
        color: AppPalette.orangeSoft36,
      ),
    );
  }
}

class _SharedAvatar extends StatelessWidget {
  const _SharedAvatar({
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
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: AppBoxDecoration(
        shape: BoxShape.circle,
        gradient: url == null
            ? const LinearGradient(
                begin: Alignment(-0.3, -0.5),
                end: Alignment(0.8, 1),
                colors: [AppPalette.orangeSoft40, AppPalette.warmSurfaceHigh34],
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: AppPalette.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: url == null
            ? Center(
                child: Text(
                  initial,
                  style: AppTextStyle(
                    fontSize: size * 0.38,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.white,
                  ),
                ),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Text(
                    initial,
                    style: AppTextStyle(
                      fontSize: size * 0.38,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.white,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _EmptyOrLoadingState extends StatelessWidget {
  const _EmptyOrLoadingState({
    required this.loading,
    required this.error,
    required this.title,
    required this.subtitle,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final String title;
  final String subtitle;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const AppEdgeInsets.fromLTRB(24, 96, 24, 0),
      child: Column(
        children: [
          if (loading) ...[
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: AppPalette.primary,
              ),
            ),
            const SizedBox(height: 18),
          ] else
            Container(
              width: 64,
              height: 64,
              decoration: AppBoxDecoration(
                shape: BoxShape.circle,
                color: AppPalette.primary.withValues(alpha: 0.12),
              ),
              child: Icon(
                error == null ? Icons.inventory_2_outlined : Icons.wifi_off,
                color: AppPalette.primary,
                size: 28,
              ),
            ),
          const SizedBox(height: 18),
          Text(
            error == null ? title : l10n.chatSharedLoadFailed,
            textAlign: TextAlign.center,
            style: const AppTextStyle(
              fontSize: 22,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: AppPalette.orangeWash10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error == null ? subtitle : l10n.chatSharedLoadFailedSubtitle,
            textAlign: TextAlign.center,
            style: const AppTextStyle(
              fontSize: 15,
              height: 1.35,
              color: AppPalette.orangeSoft04,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const AppEdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
                decoration: AppBoxDecoration(
                  color: AppPalette.primary,
                  borderRadius: AppBorderRadius.circular(999),
                ),
                child: Text(
                  l10n.retryButton,
                  style: const AppTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PartialLoadWarning extends StatelessWidget {
  const _PartialLoadWarning();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const AppEdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppBoxDecoration(
        color: AppPalette.primary.withValues(alpha: 0.1),
        borderRadius: AppBorderRadius.circular(18),
        border: Border.all(color: AppPalette.primary.withValues(alpha: 0.16)),
      ),
      child: Text(
        l10n.chatSharedPartialLoadWarning,
        textAlign: TextAlign.center,
        style: AppTextStyle(
          fontSize: 13,
          height: 1.25,
          fontWeight: FontWeight.w600,
          color: AppPalette.orangeSoft36,
        ),
      ),
    );
  }
}

class _FetchedFile {
  const _FetchedFile({
    required this.fileId,
    this.metadata,
    this.imageBytes,
    this.downloaded = false,
  });

  final String fileId;
  final FileMetadataVm? metadata;
  final Uint8List? imageBytes;
  final bool downloaded;
}

class _SharedFileRef {
  const _SharedFileRef({
    required this.message,
    required this.fileId,
    required this.metadata,
    required this.imageBytes,
    required this.downloaded,
  });

  final MessageVm message;
  final String fileId;
  final FileMetadataVm? metadata;
  final Uint8List? imageBytes;
  final bool downloaded;
}

class _SharedLinkRef {
  const _SharedLinkRef({
    required this.message,
    required this.url,
    required this.snippet,
    required this.senderName,
    required this.senderAvatarFileId,
  });

  final MessageVm message;
  final String url;
  final String snippet;
  final String senderName;
  final String? senderAvatarFileId;
}

class _DateGroup<T> {
  const _DateGroup({required this.label, required this.items});

  final String label;
  final List<T> items;
}

final _urlRegex = chatUrlRegex;

List<_DateGroup<T>> _groupByDate<T>(
  List<T> items,
  DateTime Function(T item) dateOf,
  AppLocalizations l10n,
) {
  final sorted = [...items]..sort((a, b) => dateOf(b).compareTo(dateOf(a)));
  final groups = <String, List<T>>{};

  for (final item in sorted) {
    final label = _dateLabel(dateOf(item), l10n);
    groups.putIfAbsent(label, () => <T>[]).add(item);
  }

  return groups.entries
      .map((entry) => _DateGroup(label: entry.key, items: entry.value))
      .toList(growable: false);
}

String _dateLabel(DateTime value, AppLocalizations l10n) {
  final local = value.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(local.year, local.month, local.day);
  final diff = today.difference(date).inDays;

  if (diff == 0) return l10n.chatDateToday;
  if (diff == 1) return l10n.chatDateYesterday;
  if (local.year == now.year) {
    return DateFormat.MMMd(l10n.localeName).format(local);
  }
  return DateFormat.yMMMd(l10n.localeName).format(local);
}

String _cleanUrl(String rawUrl) {
  return cleanChatUrl(rawUrl);
}

Uri? _externalUriForUrl(String rawUrl) {
  return externalUriForChatUrl(rawUrl);
}

String _linkHostLabel(String rawUrl) {
  return chatLinkHostLabel(rawUrl);
}

String? _internalAppRouteForUrl(String rawUrl) {
  return internalAppRouteForChatUrl(rawUrl);
}

String _snippetAroundUrl({
  required String content,
  required int matchStart,
  required int matchEnd,
}) {
  const beforeChars = 42;
  const afterChars = 62;
  final start = math.max(0, matchStart - beforeChars);
  final end = math.min(content.length, matchEnd + afterChars);
  final prefix = start > 0 ? '...' : '';
  final suffix = end < content.length ? '...' : '';
  return '$prefix${content.substring(start, end).trim()}$suffix';
}

LinearGradient _fallbackGradient(String seed) {
  final palettes = const [
    [
      AppPalette.blueSoft06,
      AppPalette.blueSurfaceHigh14,
      AppPalette.blueSurface03,
    ],
    [
      AppPalette.blueMuted02,
      AppPalette.blueSurfaceHigh16,
      AppPalette.blueSurface04,
    ],
    [
      AppPalette.warmSurface93,
      AppPalette.warmSurfaceHigh28,
      AppPalette.warmSurface29,
    ],
    [
      AppPalette.warmSurfaceHigh13,
      AppPalette.warmSurface42,
      AppPalette.warmInk20,
    ],
  ];
  final index =
      seed.codeUnits.fold<int>(0, (sum, code) => sum + code) % palettes.length;
  final colors = palettes[index];
  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: colors,
  );
}

IconData _fileIcon(FileMetadataVm? metadata) {
  final extension = metadata?.extensionLabel.toLowerCase() ?? '';
  if (extension == 'pdf') return Icons.picture_as_pdf_rounded;
  if (extension == 'zip' || extension == 'rar' || extension == '7z') {
    return Icons.archive_rounded;
  }
  if (extension == 'xls' || extension == 'xlsx' || extension == 'csv') {
    return Icons.table_chart_rounded;
  }
  if (metadata?.isAudio ?? false) return Icons.mic_rounded;
  if (metadata?.isImage ?? false) return Icons.image_rounded;
  if (metadata?.isVideo ?? false) return Icons.movie_rounded;
  return Icons.description_rounded;
}

Color _fileIconColor(FileMetadataVm? metadata) {
  final extension = metadata?.extensionLabel.toLowerCase() ?? '';
  if (extension == 'zip' || extension == 'rar' || extension == '7z') {
    return AppPalette.blueLight02;
  }
  if (extension == 'xls' || extension == 'xlsx' || extension == 'csv') {
    return AppPalette.orangeSoft35;
  }
  return AppPalette.primary;
}

bool _isSharedMediaOrAudio(FileMetadataVm? metadata) {
  return (metadata?.isMedia ?? false) || (metadata?.isAudio ?? false);
}

String _formatSize(int bytes) {
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

String _downloadStatusLabel(BuildContext context, bool downloaded, bool busy) {
  final l10n = AppLocalizations.of(context)!;
  if (busy) return l10n.chatAttachmentDownloading;
  return downloaded
      ? l10n.chatAttachmentDownloadedStatus
      : l10n.chatAttachmentNotDownloadedStatus;
}

String _shortId(String id) {
  final value = id.trim();
  if (value.length <= 8) return value;
  return value.substring(0, 8);
}
