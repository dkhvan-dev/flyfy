import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../../../core/ui/error_dialog.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../stories/models/post_vm.dart';
import '../../stories/story_ui.dart';

typedef FeedPostLikeCallback =
    Future<FeedPostLikeResult?> Function(PostVm post, bool likedByViewer);
typedef FeedPostActionCallback = Future<void> Function(PostVm post);

class FeedPostLikeResult {
  const FeedPostLikeResult({required this.likes, required this.likedByViewer});

  final int likes;
  final bool likedByViewer;
}

enum FeedPostFeedbackAction { hide, notInterested }

class FeedPostCardStyle {
  const FeedPostCardStyle({
    required this.blockedBorderColor,
    required this.seenBorderColor,
    required this.borderColor,
    required this.surfaceStartColor,
    required this.surfaceMiddleColor,
    required this.surfaceEndColor,
    required this.shadowColor,
    required this.glowColor,
    required this.hasShadow,
    required this.coverScrimGradient,
    required this.titleColor,
    required this.disabledTitleColor,
    required this.bodyColor,
    required this.metaColor,
    required this.chipBackgroundColor,
    required this.chipBorderColor,
    required this.chipForegroundColor,
    required this.actionSelectedBackgroundColor,
    required this.actionSelectedForegroundColor,
    required this.actionBackgroundColor,
    required this.actionForegroundColor,
    required this.menuBackgroundColor,
    required this.avatarBackgroundColor,
    required this.avatarBorderColor,
  });

  final Color blockedBorderColor;
  final Color seenBorderColor;
  final Color borderColor;
  final Color surfaceStartColor;
  final Color surfaceMiddleColor;
  final Color surfaceEndColor;
  final Color shadowColor;
  final Color glowColor;
  final bool hasShadow;
  final Gradient? coverScrimGradient;
  final Color titleColor;
  final Color disabledTitleColor;
  final Color bodyColor;
  final Color metaColor;
  final Color chipBackgroundColor;
  final Color chipBorderColor;
  final Color chipForegroundColor;
  final Color actionSelectedBackgroundColor;
  final Color actionSelectedForegroundColor;
  final Color actionBackgroundColor;
  final Color actionForegroundColor;
  final Color menuBackgroundColor;
  final Color avatarBackgroundColor;
  final Color avatarBorderColor;

  static FeedPostCardStyle v2(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final isDarkV2 = Theme.of(context).brightness == Brightness.dark;
    return FeedPostCardStyle(
      blockedBorderColor: colors.borderSoft,
      seenBorderColor: colors.primary.withValues(alpha: 0.18),
      borderColor: colors.border,
      surfaceStartColor: colors.surfaceRaised,
      surfaceMiddleColor: colors.surface,
      surfaceEndColor: colors.background,
      shadowColor: isDarkV2
          ? colors.black.withValues(alpha: 0.18)
          : colors.transparent,
      glowColor: isDarkV2
          ? colors.primary.withValues(alpha: 0.06)
          : colors.transparent,
      hasShadow: isDarkV2,
      coverScrimGradient: isDarkV2
          ? LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colors.transparent,
                colors.black.withValues(alpha: 0.10),
                colors.black.withValues(alpha: 0.34),
              ],
            )
          : null,
      titleColor: colors.textPrimary,
      disabledTitleColor: colors.textMuted,
      bodyColor: colors.textSecondary,
      metaColor: colors.textMuted,
      chipBackgroundColor: colors.primary.withValues(alpha: 0.13),
      chipBorderColor: colors.primary.withValues(alpha: 0.22),
      chipForegroundColor: colors.primarySoft,
      actionSelectedBackgroundColor: colors.primary,
      actionSelectedForegroundColor: colors.textPrimary,
      actionBackgroundColor: colors.primary.withValues(alpha: 0.12),
      actionForegroundColor: colors.primary,
      menuBackgroundColor: colors.surfaceRaised,
      avatarBackgroundColor: colors.primary.withValues(alpha: 0.18),
      avatarBorderColor: colors.primary.withValues(alpha: 0.38),
    );
  }
}

class FeedPostCard extends StatefulWidget {
  const FeedPostCard({
    super.key,
    required this.post,
    this.onOpen,
    this.onLike,
    this.onShare,
    this.onHide,
    this.onNotInterested,
    this.style,
  });

  final PostVm post;
  final ValueChanged<PostVm>? onOpen;
  final FeedPostLikeCallback? onLike;
  final FeedPostActionCallback? onShare;
  final FeedPostActionCallback? onHide;
  final FeedPostActionCallback? onNotInterested;
  final FeedPostCardStyle? style;

  @override
  State<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<FeedPostCard> {
  late int _likeCount;
  late bool _likedByViewer;
  bool _isTogglingLike = false;
  bool _isSharing = false;

  PostVm get post => widget.post;
  ValueChanged<PostVm>? get onOpen => widget.onOpen;
  FeedPostLikeCallback? get onLike => widget.onLike;
  FeedPostActionCallback? get onShare => widget.onShare;
  FeedPostActionCallback? get onHide => widget.onHide;
  FeedPostActionCallback? get onNotInterested => widget.onNotInterested;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post.stats.likes;
    _likedByViewer = widget.post.likedByViewer;
  }

  @override
  void didUpdateWidget(covariant FeedPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.stats.likes != widget.post.stats.likes) {
      _likeCount = widget.post.stats.likes;
    }
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.likedByViewer != widget.post.likedByViewer) {
      _likedByViewer = widget.post.likedByViewer;
    }
  }

  Future<void> _handleLike() async {
    final onLike = widget.onLike;
    if (onLike == null || _isTogglingLike) {
      return;
    }
    setState(() {
      _isTogglingLike = true;
    });
    try {
      final result = await onLike(widget.post, _likedByViewer);
      if (!mounted) {
        return;
      }
      setState(() {
        if (result != null) {
          _likeCount = result.likes;
          _likedByViewer = result.likedByViewer;
        } else {
          _likedByViewer = !_likedByViewer;
          final nextLikeCount = _likeCount + (_likedByViewer ? 1 : -1);
          _likeCount = nextLikeCount < 0 ? 0 : nextLikeCount;
        }
        _isTogglingLike = false;
      });
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
        message: l10n.feedPostActionFailed,
      );
    }
  }

  Future<void> _handleShare() async {
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
    final style = widget.style ?? FeedPostCardStyle.v2(context);
    final state = resolvePostEntryState(post);
    final isSeen = state == StoryEntryState.seen;
    final isBlocked = state.disablesEntry;
    final isInteractive = !isBlocked && onOpen != null;
    final hasActions =
        onLike != null ||
        onShare != null ||
        onHide != null ||
        onNotInterested != null;
    final l10n = hasActions ? AppLocalizations.of(context) : null;
    final borderColor = isBlocked
        ? style.blockedBorderColor
        : isSeen
        ? style.seenBorderColor
        : style.borderColor;
    final authorName = post.author.preferredName.trim();
    final normalizedCategory = _postCategoryLabel(post.category);
    final coverUrl = post.coverUrl;
    final hasCover = coverUrl != null && coverUrl.trim().isNotEmpty;

    return Opacity(
      opacity: isBlocked ? 0.54 : (isSeen ? 0.88 : 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppBorderRadius.circular(8),
        child: InkWell(
          key: ValueKey('open-feed-post-${post.id}'),
          onTap: isInteractive ? () => onOpen!(post) : null,
          borderRadius: AppBorderRadius.circular(8),
          child: DecoratedBox(
            decoration: AppBoxDecoration(
              borderRadius: AppBorderRadius.circular(8),
              border: Border.all(color: borderColor),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  style.surfaceStartColor,
                  style.surfaceMiddleColor,
                  style.surfaceEndColor,
                ],
                stops: const [0, 0.52, 1],
              ),
              boxShadow: style.hasShadow
                  ? [
                      BoxShadow(
                        color: style.shadowColor,
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: style.glowColor,
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: AppBorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const AppEdgeInsets.fromLTRB(14, 14, 12, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _AuthorAvatar(author: post.author, style: style),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                authorName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: style.titleColor,
                                  fontWeight: FontWeight.w900,
                                  height: 1.12,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                formatStoryDate(context, post.sortDate),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  color: style.metaColor,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (normalizedCategory.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 132),
                            child: _PostCategoryPill(
                              label: normalizedCategory,
                              style: style,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const AppEdgeInsets.symmetric(horizontal: 10),
                    child: ClipRRect(
                      borderRadius: AppBorderRadius.circular(8),
                      child: AspectRatio(
                        aspectRatio: hasCover ? 16 / 9 : 2.15,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            StoryCoverImage(url: coverUrl),
                            if (style.coverScrimGradient != null)
                              DecoratedBox(
                                decoration: AppBoxDecoration(
                                  gradient: style.coverScrimGradient,
                                ),
                              ),
                            if (state != StoryEntryState.available &&
                                state != StoryEntryState.seen)
                              Positioned(
                                top: 10,
                                right: 10,
                                child: StoryStateAffordance(
                                  state: state,
                                  compact: true,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const AppEdgeInsets.fromLTRB(16, 13, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            color: isBlocked
                                ? style.disabledTitleColor
                                : style.titleColor,
                            fontWeight: FontWeight.w900,
                            height: 1.16,
                          ),
                        ),
                        if (post.excerpt.trim().isNotEmpty) ...[
                          const SizedBox(height: 7),
                          Text(
                            post.excerpt.trim(),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              color: style.bodyColor,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 13),
                        Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _StoryMetaChip(
                                    icon: Icons.visibility_outlined,
                                    label: formatStoryCountCompact(
                                      post.stats.views,
                                    ),
                                    style: style,
                                  ),
                                  _StoryMetaChip(
                                    icon: Icons.favorite_border_rounded,
                                    label: formatStoryCountCompact(_likeCount),
                                    style: style,
                                  ),
                                  _StoryMetaChip(
                                    icon: Icons.chat_bubble_outline_rounded,
                                    label: formatStoryCountCompact(
                                      post.stats.comments,
                                    ),
                                    style: style,
                                  ),
                                ],
                              ),
                            ),
                            if (isInteractive) ...[
                              const SizedBox(width: 10),
                              _OpenPostAffordance(style: style),
                            ],
                          ],
                        ),
                        if (hasActions) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _PostActionButton(
                                key: ValueKey('feed-post-like-${post.id}'),
                                icon: _likedByViewer
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                label: formatStoryCountCompact(_likeCount),
                                tooltip: _likedByViewer
                                    ? l10n?.feedPostUnlikeAction ??
                                          'Remove like'
                                    : l10n?.feedPostLikeAction ?? 'Like post',
                                isSelected: _likedByViewer,
                                isBusy: _isTogglingLike,
                                style: style,
                                onPressed: onLike == null ? null : _handleLike,
                              ),
                              const SizedBox(width: 8),
                              _PostActionButton(
                                key: ValueKey('feed-post-share-${post.id}'),
                                icon: Icons.ios_share_rounded,
                                label: l10n?.storyCommentShareAction ?? 'Share',
                                tooltip:
                                    l10n?.feedPostShareAction ?? 'Share post',
                                isBusy: _isSharing,
                                style: style,
                                onPressed: onShare == null
                                    ? null
                                    : _handleShare,
                              ),
                              const Spacer(),
                              if (onHide != null || onNotInterested != null)
                                _PostFeedbackMenu(
                                  postId: post.id,
                                  onSelected: _handleFeedback,
                                  hideLabel:
                                      l10n?.feedPostHideAction ?? 'Hide post',
                                  notInterestedLabel:
                                      l10n?.feedPostNotInterestedAction ??
                                      'Not interested',
                                  tooltip:
                                      l10n?.feedPostMoreActions ??
                                      'Post actions',
                                  hasHide: onHide != null,
                                  hasNotInterested: onNotInterested != null,
                                  style: style,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OpenPostAffordance extends StatelessWidget {
  const _OpenPostAffordance({required this.style});

  final FeedPostCardStyle style;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: style.chipBackgroundColor,
        borderRadius: AppBorderRadius.circular(999),
        border: Border.all(color: style.chipBorderColor),
      ),
      child: SizedBox.square(
        dimension: 34,
        child: Icon(
          Icons.arrow_forward_rounded,
          color: style.actionForegroundColor,
          size: 20,
        ),
      ),
    );
  }
}

class _PostActionButton extends StatelessWidget {
  const _PostActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.tooltip,
    this.isSelected = false,
    this.isBusy = false,
    required this.style,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final bool isSelected;
  final bool isBusy;
  final FeedPostCardStyle style;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected
        ? style.actionSelectedForegroundColor
        : style.actionForegroundColor;
    final background = isSelected
        ? style.actionSelectedBackgroundColor
        : style.actionBackgroundColor;

    return Tooltip(
      message: tooltip,
      child: FilledButton.icon(
        onPressed: isBusy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          disabledBackgroundColor: background.withValues(alpha: 0.54),
          foregroundColor: foreground,
          disabledForegroundColor: foreground.withValues(alpha: 0.70),
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size(44, 36),
          padding: const AppEdgeInsets.symmetric(horizontal: 11, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.circular(999),
            side: BorderSide(
              color: isSelected ? Colors.transparent : style.chipBorderColor,
            ),
          ),
        ),
        icon: isBusy
            ? SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foreground,
                ),
              )
            : Icon(icon, size: 18),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const AppTextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _PostFeedbackMenu extends StatelessWidget {
  const _PostFeedbackMenu({
    required this.postId,
    required this.onSelected,
    required this.hideLabel,
    required this.notInterestedLabel,
    required this.tooltip,
    required this.hasHide,
    required this.hasNotInterested,
    required this.style,
  });

  final String postId;
  final ValueChanged<FeedPostFeedbackAction> onSelected;
  final String hideLabel;
  final String notInterestedLabel;
  final String tooltip;
  final bool hasHide;
  final bool hasNotInterested;
  final FeedPostCardStyle style;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<FeedPostFeedbackAction>(
      key: ValueKey('feed-post-more-$postId'),
      tooltip: tooltip,
      position: PopupMenuPosition.under,
      color: style.menuBackgroundColor,
      surfaceTintColor: Colors.transparent,
      icon: Icon(Icons.more_horiz_rounded, color: style.actionForegroundColor),
      onSelected: onSelected,
      itemBuilder: (context) => [
        if (hasHide)
          PopupMenuItem<FeedPostFeedbackAction>(
            key: ValueKey('feed-post-hide-$postId'),
            value: FeedPostFeedbackAction.hide,
            child: _PostFeedbackMenuItem(
              icon: Icons.visibility_off_outlined,
              label: hideLabel,
              style: style,
            ),
          ),
        if (hasNotInterested)
          PopupMenuItem<FeedPostFeedbackAction>(
            key: ValueKey('feed-post-not-interested-$postId'),
            value: FeedPostFeedbackAction.notInterested,
            child: _PostFeedbackMenuItem(
              icon: Icons.thumb_down_alt_outlined,
              label: notInterestedLabel,
              style: style,
            ),
          ),
      ],
    );
  }
}

class _PostFeedbackMenuItem extends StatelessWidget {
  const _PostFeedbackMenuItem({
    required this.icon,
    required this.label,
    required this.style,
  });

  final IconData icon;
  final String label;
  final FeedPostCardStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: style.actionForegroundColor, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle(
              color: style.titleColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _StoryMetaChip extends StatelessWidget {
  const _StoryMetaChip({
    required this.icon,
    required this.label,
    required this.style,
  });

  final IconData icon;
  final String label;
  final FeedPostCardStyle style;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: style.chipBackgroundColor,
        borderRadius: AppBorderRadius.circular(999),
        border: Border.all(color: style.chipBorderColor),
      ),
      child: Padding(
        padding: const AppEdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: style.actionForegroundColor, size: 15),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: style.chipForegroundColor,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({required this.author, required this.style});

  final PostAuthorVm author;
  final FeedPostCardStyle style;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = author.avatarUrl;
    return Container(
      width: 40,
      height: 40,
      decoration: AppBoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: style.avatarBorderColor),
        boxShadow: style.hasShadow
            ? [
                BoxShadow(
                  color: style.glowColor,
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: style.avatarBackgroundColor,
        backgroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl),
        child: avatarUrl == null
            ? Text(
                author.initials,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: style.actionForegroundColor,
                  fontWeight: FontWeight.w900,
                ),
              )
            : null,
      ),
    );
  }
}

class _PostCategoryPill extends StatelessWidget {
  const _PostCategoryPill({required this.label, required this.style});

  final String label;
  final FeedPostCardStyle style;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: style.chipBackgroundColor,
        borderRadius: AppBorderRadius.circular(999),
        border: Border.all(color: style.chipBorderColor),
      ),
      child: Padding(
        padding: const AppEdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: style.chipForegroundColor,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

String _postCategoryLabel(String value) {
  final normalized = value.trim().replaceAll('_', ' ').toLowerCase();
  if (normalized.isEmpty) {
    return '';
  }
  return normalized
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
