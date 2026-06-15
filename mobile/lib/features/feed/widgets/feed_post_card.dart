import 'package:flutter/material.dart';

import '../../../core/ui/app_colors.dart';
import '../../stories/models/post_vm.dart';
import '../../stories/story_ui.dart';

class FeedPostCard extends StatelessWidget {
  const FeedPostCard({super.key, required this.post, this.onOpen});

  final PostVm post;
  final ValueChanged<PostVm>? onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final state = resolvePostEntryState(post);
    final isSeen = state == StoryEntryState.seen;
    final isBlocked = state.disablesEntry;
    final isInteractive = !isBlocked && onOpen != null;
    final borderColor = isBlocked
        ? Colors.white.withValues(alpha: 0.08)
        : isSeen
        ? AppColors.accent.withValues(alpha: 0.18)
        : AppColors.accent.withValues(alpha: 0.46);
    final authorName = post.author.preferredName.trim();
    final normalizedCategory = _postCategoryLabel(post.category);
    final coverUrl = post.coverUrl;
    final hasCover = coverUrl != null && coverUrl.trim().isNotEmpty;

    return Opacity(
      opacity: isBlocked ? 0.54 : (isSeen ? 0.88 : 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          key: ValueKey('open-feed-post-${post.id}'),
          onTap: isInteractive ? () => onOpen!(post) : null,
          borderRadius: BorderRadius.circular(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF3A220E).withValues(alpha: 0.96),
                  const Color(0xFF211209),
                  const Color(0xFF140B06),
                ],
                stops: const [0, 0.52, 1],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.07),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 12, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _AuthorAvatar(author: post.author),
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
                                  color: const Color(0xFFFFF7ED),
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
                                  color: const Color(0xFFC7AD92),
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
                            child: _PostCategoryPill(label: normalizedCategory),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AspectRatio(
                        aspectRatio: hasCover ? 16 / 9 : 2.15,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            StoryCoverImage(url: coverUrl),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.10),
                                    Colors.black.withValues(alpha: 0.34),
                                  ],
                                ),
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
                    padding: const EdgeInsets.fromLTRB(16, 13, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            color: isBlocked
                                ? AppColors.textSecondary
                                : const Color(0xFFFFF7ED),
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
                              color: const Color(0xFFE0C8AE),
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
                                  ),
                                  _StoryMetaChip(
                                    icon: Icons.favorite_border_rounded,
                                    label: formatStoryCountCompact(
                                      post.stats.likes,
                                    ),
                                  ),
                                  _StoryMetaChip(
                                    icon: Icons.chat_bubble_outline_rounded,
                                    label: formatStoryCountCompact(
                                      post.stats.comments,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isInteractive) ...[
                              const SizedBox(width: 10),
                              const _OpenPostAffordance(),
                            ],
                          ],
                        ),
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
  const _OpenPostAffordance();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.22)),
      ),
      child: const SizedBox.square(
        dimension: 34,
        child: Icon(
          Icons.arrow_forward_rounded,
          color: AppColors.accent,
          size: 20,
        ),
      ),
    );
  }
}

class _StoryMetaChip extends StatelessWidget {
  const _StoryMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.accent, size: 15),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFFFE0B2),
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
  const _AuthorAvatar({required this.author});

  final PostAuthorVm author;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = author.avatarUrl;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.38)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.accent.withValues(alpha: 0.18),
        backgroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl),
        child: avatarUrl == null
            ? Text(
                author.initials,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w900,
                ),
              )
            : null,
      ),
    );
  }
}

class _PostCategoryPill extends StatelessWidget {
  const _PostCategoryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFFFFC46B),
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
