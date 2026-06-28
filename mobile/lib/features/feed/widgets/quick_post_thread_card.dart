import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../../../core/network/file_api.dart';
import '../../../core/network/post_api.dart';
import '../../../core/ui/error_dialog.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/feed_api.dart';
import '../../stories/models/post_vm.dart';
import '../../stories/story_ui.dart';

typedef QuickPostEngagementCallback =
    void Function(PostVm post, String eventType);

class QuickPostThreadCard extends StatefulWidget {
  const QuickPostThreadCard({
    super.key,
    required this.post,
    required this.postApi,
    this.canInteract = true,
    this.previewCommentLimit = 3,
    this.onEdit,
    this.onEngagement,
  });

  final PostVm post;
  final PostApi postApi;
  final bool canInteract;
  final int previewCommentLimit;
  final ValueChanged<PostVm>? onEdit;
  final QuickPostEngagementCallback? onEngagement;

  @override
  State<QuickPostThreadCard> createState() => _QuickPostThreadCardState();
}

class _QuickPostThreadCardState extends State<QuickPostThreadCard> {
  late final TextEditingController _controller;
  late int _viewCount;
  late int _likeCount;
  late int _commentCount;
  late bool _likedByViewer;

  List<PostCommentVm> _comments = const [];
  bool _isLoadingComments = false;
  bool _isSubmitting = false;
  bool _isTogglingLike = false;
  Object? _commentsError;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(_handleTextChanged);
    _viewCount = widget.post.stats.views;
    _likeCount = widget.post.stats.likes;
    _commentCount = widget.post.stats.comments;
    _likedByViewer = widget.post.likedByViewer;
    _loadComments();
  }

  @override
  void didUpdateWidget(covariant QuickPostThreadCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      _comments = const [];
      _commentsError = null;
      _viewCount = widget.post.stats.views;
      _likeCount = widget.post.stats.likes;
      _commentCount = widget.post.stats.comments;
      _likedByViewer = widget.post.likedByViewer;
      _isTogglingLike = false;
      _controller.clear();
      _loadComments();
      return;
    }
    if (oldWidget.post.stats.views != widget.post.stats.views) {
      _viewCount = widget.post.stats.views;
    }
    if (oldWidget.post.stats.likes != widget.post.stats.likes) {
      _likeCount = widget.post.stats.likes;
    }
    if (oldWidget.post.stats.comments != widget.post.stats.comments) {
      _commentCount = widget.post.stats.comments;
    }
    if (oldWidget.post.likedByViewer != widget.post.likedByViewer) {
      _likedByViewer = widget.post.likedByViewer;
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleTextChanged)
      ..dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadComments() async {
    final postId = widget.post.id.trim();
    if (postId.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingComments = true;
      _commentsError = null;
    });

    try {
      final comments = await widget.postApi.listComments(
        postId,
        limit: widget.previewCommentLimit,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _comments = comments;
        _commentsError = null;
        _isLoadingComments = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _commentsError = error;
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _submitComment() async {
    final body = _controller.text.trim();
    final postId = widget.post.id.trim();
    if (!widget.canInteract ||
        body.isEmpty ||
        postId.isEmpty ||
        _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final comment = await widget.postApi.createComment(postId, body);
      if (!mounted) {
        return;
      }
      _controller.clear();
      setState(() {
        _comments = [
          comment,
          ..._comments.where((item) => item.id != comment.id),
        ].take(widget.previewCommentLimit).toList(growable: false);
        _commentCount += 1;
        _isSubmitting = false;
      });
      widget.onEngagement?.call(widget.post, FeedEventTypes.comment);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
      });
      final l10n = AppLocalizations.of(context)!;
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.storyReplySendFailed,
      );
    }
  }

  Future<void> _toggleLike() async {
    final postId = widget.post.id.trim();
    if (!widget.canInteract || postId.isEmpty || _isTogglingLike) {
      return;
    }

    setState(() {
      _isTogglingLike = true;
    });

    try {
      final wasLikedByViewer = _likedByViewer;
      final likes = _likedByViewer
          ? await widget.postApi.unlikePost(postId)
          : await widget.postApi.likePost(postId);
      if (!mounted) {
        return;
      }
      setState(() {
        _likeCount = likes;
        _likedByViewer = !_likedByViewer;
        _isTogglingLike = false;
      });
      if (!wasLikedByViewer) {
        widget.onEngagement?.call(widget.post, FeedEventTypes.like);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isTogglingLike = false;
      });
      final l10n = AppLocalizations.of(context)!;
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.storyLikeActionFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final imageUrls = _quickPostImageUrls(widget.post);
    final body = _quickPostBody(widget.post);
    final canSubmit = _controller.text.trim().isNotEmpty && !_isSubmitting;
    final editedAt = widget.post.editedAt;

    return DecoratedBox(
      key: ValueKey('quick-post-thread-${widget.post.id}'),
      decoration: AppBoxDecoration(
        borderRadius: AppBorderRadius.circular(8),
        border: Border.all(color: AppPalette.primary.withValues(alpha: 0.30)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppPalette.warmSurface52.withValues(alpha: 0.96),
            AppPalette.warmInk92,
            AppPalette.warmInk16,
          ],
          stops: const [0, 0.54, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.black.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppPalette.primary.withValues(alpha: 0.06),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const AppEdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _QuickPostAvatar(author: widget.post.author),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.author.preferredName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppPalette.surfaceInverse,
                          fontWeight: FontWeight.w900,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatStoryDate(context, widget.post.sortDate),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppPalette.orangeSoft18,
                          fontWeight: FontWeight.w700,
                          height: 1.12,
                        ),
                      ),
                      if (editedAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${l10n.chatEditedLabel} ${formatStoryDate(context, editedAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppPalette.warmMuted17,
                            fontWeight: FontWeight.w700,
                            height: 1.12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (widget.canInteract &&
                    widget.post.editable &&
                    widget.onEdit != null) ...[
                  _QuickPostActionsMenu(
                    post: widget.post,
                    onEdit: widget.onEdit!,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (body.isNotEmpty)
              Text(
                body,
                style: textTheme.titleMedium?.copyWith(
                  color: AppPalette.surfaceInverse,
                  height: 1.30,
                  fontWeight: FontWeight.w800,
                ),
              ),
            if (widget.post.excerpt.trim().isNotEmpty &&
                widget.post.excerpt.trim() != body) ...[
              const SizedBox(height: 8),
              Text(
                widget.post.excerpt.trim(),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppPalette.orangeLight19,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              _QuickPostImages(imageUrls: imageUrls),
            ],
            const SizedBox(height: 12),
            _QuickPostCommentsPreview(
              comments: _comments,
              isLoading: _isLoadingComments,
              hasError: _commentsError != null,
              onRetry: _loadComments,
            ),
            const SizedBox(height: 12),
            Wrap(
              key: ValueKey('quick-post-engagement-row-${widget.post.id}'),
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _QuickPostMetric(
                  key: ValueKey('quick-post-views-${widget.post.id}'),
                  icon: Icons.visibility_outlined,
                  label: formatStoryCountCompact(_viewCount),
                ),
                if (widget.canInteract)
                  _QuickPostLikeButton(
                    key: ValueKey('quick-post-like-${widget.post.id}'),
                    likes: _likeCount,
                    likedByViewer: _likedByViewer,
                    isLoading: _isTogglingLike,
                    onPressed: _toggleLike,
                  )
                else
                  _QuickPostMetric(
                    key: ValueKey('quick-post-likes-count-${widget.post.id}'),
                    icon: Icons.favorite_border_rounded,
                    label: formatStoryCountCompact(_likeCount),
                  ),
                _QuickPostMetric(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: formatStoryCountCompact(_commentCount),
                ),
              ],
            ),
            if (widget.canInteract) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      key: ValueKey(
                        'quick-post-comment-field-${widget.post.id}',
                      ),
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitComment(),
                      style: const AppTextStyle(
                        color: AppPalette.surfaceInverse,
                      ),
                      decoration: AppInputDecoration(
                        hintText: l10n.storyCommentHint,
                        hintStyle: AppTextStyle(
                          color: AppPalette.white.withValues(alpha: 0.42),
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: AppPalette.black.withValues(alpha: 0.20),
                        contentPadding: const AppEdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: AppBorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppPalette.white.withValues(alpha: 0.08),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppBorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppPalette.primary.withValues(alpha: 0.12),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppBorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppPalette.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: ValueKey('quick-post-comment-send-${widget.post.id}'),
                    onPressed: canSubmit ? _submitComment : null,
                    style: IconButton.styleFrom(
                      backgroundColor: AppPalette.primary,
                      disabledBackgroundColor: AppPalette.primary.withValues(
                        alpha: 0.20,
                      ),
                      foregroundColor: AppPalette.black,
                      disabledForegroundColor: AppPalette.white.withValues(
                        alpha: 0.42,
                      ),
                    ),
                    tooltip: l10n.storyReplySendAction,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppPalette.black,
                            ),
                          )
                        : const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickPostImages extends StatelessWidget {
  const _QuickPostImages({required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    if (imageUrls.length == 1) {
      return DecoratedBox(
        decoration: AppBoxDecoration(
          borderRadius: AppBorderRadius.circular(8),
          border: Border.all(color: AppPalette.primary.withValues(alpha: 0.16)),
        ),
        child: ClipRRect(
          borderRadius: AppBorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: StoryCoverImage(url: imageUrls.first),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final thumbnailExtent = (availableWidth * 0.34).clamp(110.0, 150.0);
        return SizedBox(
          height: thumbnailExtent,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: imageUrls.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return DecoratedBox(
                decoration: AppBoxDecoration(
                  borderRadius: AppBorderRadius.circular(8),
                  border: Border.all(
                    color: AppPalette.primary.withValues(alpha: 0.16),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: AppBorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: StoryCoverImage(url: imageUrls[index]),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _QuickPostCommentsPreview extends StatelessWidget {
  const _QuickPostCommentsPreview({
    required this.comments,
    required this.isLoading,
    required this.hasError,
    required this.onRetry,
  });

  final List<PostCommentVm> comments;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: AppEdgeInsets.symmetric(vertical: 4),
        child: LinearProgressIndicator(
          minHeight: 2,
          color: AppPalette.primary,
          backgroundColor: AppPalette.warmOverlaySurface02,
        ),
      );
    }

    if (hasError) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: Text(AppLocalizations.of(context)!.feedRetryAction),
        ),
      );
    }

    if (comments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        for (final comment in comments)
          Padding(
            padding: const AppEdgeInsets.only(bottom: 8),
            child: _QuickPostCommentRow(comment: comment),
          ),
      ],
    );
  }
}

class _QuickPostCommentRow extends StatelessWidget {
  const _QuickPostCommentRow({required this.comment});

  final PostCommentVm comment;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: AppPalette.primary.withValues(alpha: 0.20),
          child: Text(
            comment.author.initials,
            style: textTheme.labelSmall?.copyWith(
              color: AppPalette.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DecoratedBox(
            decoration: AppBoxDecoration(
              color: AppPalette.black.withValues(alpha: 0.18),
              borderRadius: AppBorderRadius.circular(8),
              border: Border.all(
                color: AppPalette.primary.withValues(alpha: 0.10),
              ),
            ),
            child: Padding(
              padding: const AppEdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.author.preferredName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelMedium?.copyWith(
                      color: AppPalette.surfaceInverse,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    comment.body,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppPalette.orangeLight27,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickPostMetric extends StatelessWidget {
  const _QuickPostMetric({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: AppPalette.primary.withValues(alpha: 0.13),
        borderRadius: AppBorderRadius.circular(999),
        border: Border.all(color: AppPalette.primary.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const AppEdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppPalette.primary),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppPalette.amberLight12,
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

class _QuickPostLikeButton extends StatelessWidget {
  const _QuickPostLikeButton({
    super.key,
    required this.likes,
    required this.likedByViewer,
    required this.isLoading,
    required this.onPressed,
  });

  final int likes;
  final bool likedByViewer;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = likedByViewer
        ? AppPalette.orangeLight44
        : AppPalette.primary;
    return Material(
      color: AppPalette.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: AppBorderRadius.circular(999),
        child: DecoratedBox(
          decoration: AppBoxDecoration(
            color: AppPalette.primary.withValues(
              alpha: likedByViewer ? 0.22 : 0.13,
            ),
            borderRadius: AppBorderRadius.circular(999),
            border: Border.all(
              color: AppPalette.primary.withValues(
                alpha: likedByViewer ? 0.34 : 0.16,
              ),
            ),
          ),
          child: Padding(
            padding: const AppEdgeInsets.symmetric(horizontal: 9, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foreground,
                    ),
                  )
                else
                  Icon(
                    likedByViewer
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 15,
                    color: foreground,
                  ),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    formatStoryCountCompact(likes),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppPalette.amberLight12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickPostActionsMenu extends StatelessWidget {
  const _QuickPostActionsMenu({required this.post, required this.onEdit});

  final PostVm post;
  final ValueChanged<PostVm> onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<_QuickPostAction>(
      tooltip: l10n.storyEditAction,
      position: PopupMenuPosition.under,
      color: AppPalette.warmSurface10,
      surfaceTintColor: AppPalette.transparent,
      elevation: 14,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.circular(8),
        side: BorderSide(color: AppPalette.primary.withValues(alpha: 0.24)),
      ),
      icon: const Icon(Icons.more_horiz_rounded, color: AppPalette.amberSoft22),
      onSelected: (action) {
        switch (action) {
          case _QuickPostAction.edit:
            onEdit(post);
        }
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem<_QuickPostAction>(
            value: _QuickPostAction.edit,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppPalette.primary,
                ),
                const SizedBox(width: 8),
                Text(l10n.storyEditAction),
              ],
            ),
          ),
        ];
      },
    );
  }
}

enum _QuickPostAction { edit }

class _QuickPostAvatar extends StatelessWidget {
  const _QuickPostAvatar({required this.author});

  final PostAuthorVm author;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = author.avatarUrl;
    return Container(
      width: 42,
      height: 42,
      decoration: AppBoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppPalette.primary.withValues(alpha: 0.38)),
        boxShadow: [
          BoxShadow(
            color: AppPalette.primary.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 19,
        backgroundColor: AppPalette.primary.withValues(alpha: 0.18),
        backgroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl),
        child: avatarUrl == null
            ? Text(
                author.initials,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppPalette.primary,
                  fontWeight: FontWeight.w900,
                ),
              )
            : null,
      ),
    );
  }
}

String _quickPostBody(PostVm post) {
  final content = post.content?.trim() ?? '';
  if (content.isNotEmpty) {
    return content;
  }
  final title = post.title.trim();
  if (title.isNotEmpty) {
    return title;
  }
  return post.excerpt.trim();
}

List<String> _quickPostImageUrls(PostVm post) {
  final urls = <String>[];

  void addUrl(String? value) {
    final url = value?.trim();
    if (url == null || url.isEmpty || urls.contains(url)) {
      return;
    }
    urls.add(url);
  }

  void addFileId(Object? rawFileId) {
    final fileId = rawFileId?.toString().trim() ?? '';
    if (fileId.isEmpty) {
      return;
    }
    addUrl(resolvePublicFileContentUrl(fileId));
  }

  addUrl(post.coverUrl);

  for (final block in post.contentBlocks) {
    final type = block['type']?.toString().trim().toLowerCase();
    if (type == 'image') {
      final image = block['image'];
      if (image is Map<String, dynamic>) {
        addFileId(image['fileId']);
      }
    }
    if (type == 'gallery') {
      final gallery = block['gallery'];
      final images = gallery is Map<String, dynamic>
          ? gallery['images']
          : block['images'];
      if (images is List) {
        for (final image in images) {
          if (image is Map<String, dynamic>) {
            addFileId(image['fileId']);
          }
        }
      }
    }
  }

  return urls;
}
