import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../../../core/network/dio_error_mapper.dart';
import '../../../core/network/file_api.dart';
import '../../../core/network/post_api.dart';
import '../../../core/ui/error_dialog.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/feed_api.dart';
import '../../stories/models/post_vm.dart';
import '../../stories/story_ui.dart';
import 'feed_post_card.dart';
import 'post_saved_bookmark_button.dart';

typedef QuickPostEngagementCallback =
    void Function(PostVm post, String eventType);

class QuickPostThreadCard extends StatefulWidget {
  const QuickPostThreadCard({
    super.key,
    required this.post,
    required this.postApi,
    this.canInteract = true,
    this.previewCommentLimit = 3,
    this.onOpen,
    this.onEdit,
    this.onShare,
    this.onHide,
    this.onNotInterested,
    this.onEngagement,
  });

  final PostVm post;
  final PostApi postApi;
  final bool canInteract;
  final int previewCommentLimit;
  final ValueChanged<PostVm>? onOpen;
  final ValueChanged<PostVm>? onEdit;
  final FeedPostActionCallback? onShare;
  final FeedPostActionCallback? onHide;
  final FeedPostActionCallback? onNotInterested;
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
  bool _isSharing = false;
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
    } catch (error) {
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
        message: error is DioException
            ? DioErrorMapper.toMessage(error)
            : l10n.storyReplySendFailed,
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

  Future<void> _share() async {
    final onShare = widget.onShare;
    if (onShare == null || _isSharing) {
      return;
    }
    setState(() {
      _isSharing = true;
    });
    try {
      await onShare(widget.post);
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        await showErrorDialog(
          context,
          title: l10n.error,
          message: l10n.feedPostActionFailed,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  Future<void> _handleFeedback(FeedPostFeedbackAction action) async {
    final callback = switch (action) {
      FeedPostFeedbackAction.hide => widget.onHide,
      FeedPostFeedbackAction.notInterested => widget.onNotInterested,
    };
    if (callback == null) {
      return;
    }
    try {
      await callback(widget.post);
    } catch (_) {
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.feedPostActionFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrls = _quickPostImageUrls(widget.post);
    final body = _quickPostBody(widget.post);
    final canSubmit = _controller.text.trim().isNotEmpty && !_isSubmitting;
    final editedAt = widget.post.editedAt;
    final canOpen = widget.onOpen != null;
    final hasFeedActions =
        widget.onShare != null ||
        widget.onHide != null ||
        widget.onNotInterested != null;

    return Material(
      color: colors.transparent,
      borderRadius: AppBorderRadius.circular(8),
      child: InkWell(
        key: ValueKey('open-feed-post-${widget.post.id}'),
        onTap: canOpen ? () => widget.onOpen!(widget.post) : null,
        borderRadius: AppBorderRadius.circular(8),
        child: DecoratedBox(
          key: ValueKey('quick-post-thread-${widget.post.id}'),
          decoration: AppBoxDecoration(
            borderRadius: AppBorderRadius.circular(8),
            color: colors.surfaceRaised,
            border: Border.all(color: colors.borderPrimary),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.surfaceRaised, colors.surface, colors.background],
              stops: const [0, 0.54, 1],
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: colors.black.withValues(alpha: 0.24),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.06),
                      blurRadius: 26,
                      offset: const Offset(0, 14),
                    ),
                  ]
                : const [],
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
                              color: colors.textPrimary,
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
                              color: colors.textSecondary,
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
                                color: colors.textMuted,
                                fontWeight: FontWeight.w700,
                                height: 1.12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    PostSavedBookmarkButton(post: widget.post),
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
                      color: colors.textPrimary,
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
                      color: colors.textSecondary,
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
                        key: ValueKey(
                          'quick-post-likes-count-${widget.post.id}',
                        ),
                        icon: Icons.favorite_border_rounded,
                        label: formatStoryCountCompact(_likeCount),
                      ),
                    _QuickPostMetric(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: formatStoryCountCompact(_commentCount),
                    ),
                  ],
                ),
                if (hasFeedActions) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (widget.onShare != null)
                        OutlinedButton.icon(
                          key: ValueKey('feed-post-share-${widget.post.id}'),
                          onPressed: _isSharing ? null : _share,
                          icon: _isSharing
                              ? SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.primary,
                                  ),
                                )
                              : const Icon(Icons.ios_share_rounded, size: 18),
                          label: Text(l10n.storyCommentShareAction),
                        ),
                      const Spacer(),
                      if (widget.onHide != null ||
                          widget.onNotInterested != null)
                        PopupMenuButton<FeedPostFeedbackAction>(
                          key: ValueKey('feed-post-more-${widget.post.id}'),
                          tooltip: l10n.feedPostMoreActions,
                          position: PopupMenuPosition.under,
                          color: colors.surfaceRaised,
                          surfaceTintColor: colors.transparent,
                          icon: Icon(
                            Icons.more_horiz_rounded,
                            color: colors.primary,
                          ),
                          onSelected: _handleFeedback,
                          itemBuilder: (context) => [
                            if (widget.onHide != null)
                              PopupMenuItem<FeedPostFeedbackAction>(
                                key: ValueKey(
                                  'feed-post-hide-${widget.post.id}',
                                ),
                                value: FeedPostFeedbackAction.hide,
                                child: Text(l10n.feedPostHideAction),
                              ),
                            if (widget.onNotInterested != null)
                              PopupMenuItem<FeedPostFeedbackAction>(
                                key: ValueKey(
                                  'feed-post-not-interested-${widget.post.id}',
                                ),
                                value: FeedPostFeedbackAction.notInterested,
                                child: Text(l10n.feedPostNotInterestedAction),
                              ),
                          ],
                        ),
                    ],
                  ),
                ],
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
                          style: AppTextStyle(color: colors.textPrimary),
                          decoration: AppInputDecoration(
                            hintText: l10n.storyCommentHint,
                            hintStyle: AppTextStyle(color: colors.textMuted),
                            isDense: true,
                            filled: true,
                            fillColor: colors.surfaceHigh,
                            contentPadding: const AppEdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: AppBorderRadius.circular(8),
                              borderSide: BorderSide(color: colors.borderSoft),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppBorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: colors.borderPrimary,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: AppBorderRadius.circular(8),
                              borderSide: BorderSide(color: colors.primary),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        key: ValueKey(
                          'quick-post-comment-send-${widget.post.id}',
                        ),
                        onPressed: canSubmit ? _submitComment : null,
                        style: IconButton.styleFrom(
                          backgroundColor: colors.primary,
                          disabledBackgroundColor: colors.primary.withValues(
                            alpha: 0.20,
                          ),
                          foregroundColor: colors.onPrimary,
                          disabledForegroundColor: colors.onPrimary.withValues(
                            alpha: 0.42,
                          ),
                        ),
                        tooltip: l10n.storyReplySendAction,
                        icon: _isSubmitting
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.onPrimary,
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
    final colors = AppDesignSystem.colorsFor(context);
    if (imageUrls.length == 1) {
      return DecoratedBox(
        decoration: AppBoxDecoration(
          borderRadius: AppBorderRadius.circular(8),
          border: Border.all(color: colors.borderPrimary),
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
                  border: Border.all(color: colors.borderPrimary),
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
      final colors = AppDesignSystem.colorsFor(context);
      return Padding(
        padding: const AppEdgeInsets.symmetric(vertical: 4),
        child: LinearProgressIndicator(
          minHeight: 2,
          color: colors.primary,
          backgroundColor: colors.surfaceHigh,
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
    final colors = AppDesignSystem.colorsFor(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: colors.primary.withValues(alpha: 0.20),
          child: Text(
            comment.author.initials,
            style: textTheme.labelSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DecoratedBox(
            decoration: AppBoxDecoration(
              color: colors.surfaceHigh,
              borderRadius: AppBorderRadius.circular(8),
              border: Border.all(color: colors.borderPrimary),
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
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    comment.body,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
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
    final colors = AppDesignSystem.colorsFor(context);
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: colors.primary.withValues(alpha: 0.13),
        borderRadius: AppBorderRadius.circular(999),
        border: Border.all(color: colors.borderPrimary),
      ),
      child: Padding(
        padding: const AppEdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: colors.primary),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textPrimary,
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
    final colors = AppDesignSystem.colorsFor(context);
    final foreground = likedByViewer ? colors.primarySoft : colors.primary;
    return Material(
      color: colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: AppBorderRadius.circular(999),
        child: DecoratedBox(
          decoration: AppBoxDecoration(
            color: colors.primary.withValues(
              alpha: likedByViewer ? 0.22 : 0.13,
            ),
            borderRadius: AppBorderRadius.circular(999),
            border: Border.all(
              color: colors.primary.withValues(
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
                      color: colors.textPrimary,
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
    final colors = AppDesignSystem.colorsFor(context);
    return PopupMenuButton<_QuickPostAction>(
      tooltip: l10n.storyEditAction,
      position: PopupMenuPosition.under,
      color: colors.surfaceRaised,
      surfaceTintColor: colors.transparent,
      elevation: 14,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.circular(8),
        side: BorderSide(color: colors.borderPrimary),
      ),
      icon: Icon(Icons.more_horiz_rounded, color: colors.primary),
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
                Icon(Icons.edit_outlined, size: 18, color: colors.primary),
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
    final colors = AppDesignSystem.colorsFor(context);
    final avatarUrl = author.avatarUrl;
    return Container(
      width: 42,
      height: 42,
      decoration: AppBoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colors.primary.withValues(alpha: 0.38)),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 19,
        backgroundColor: colors.primary.withValues(alpha: 0.18),
        backgroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl),
        child: avatarUrl == null
            ? Text(
                author.initials,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.primary,
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
