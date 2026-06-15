import 'package:flutter/material.dart';

import '../../../core/ui/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../stories/models/post_vm.dart';

class FeedSystemPostsBlock extends StatelessWidget {
  const FeedSystemPostsBlock({
    super.key,
    required this.posts,
    this.onPostOpen,
    this.onOpenAll,
  });

  static const maxPreviewPosts = 5;

  final List<PostVm> posts;
  final ValueChanged<PostVm>? onPostOpen;
  final ValueChanged<List<PostVm>>? onOpenAll;

  @override
  Widget build(BuildContext context) {
    final visiblePosts = posts.take(maxPreviewPosts).toList(growable: false);
    if (visiblePosts.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      key: const ValueKey('feed-system-posts-block'),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.feedSystemPostsTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onOpenAll == null ? null : () => onOpenAll!(posts),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  child: Text(l10n.feedSystemPostsViewAll),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (var index = 0; index < visiblePosts.length; index++) ...[
              _SystemPostPreviewCard(
                post: visiblePosts[index],
                onOpen: onPostOpen,
              ),
              if (index != visiblePosts.length - 1) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _SystemPostPreviewCard extends StatelessWidget {
  const _SystemPostPreviewCard({required this.post, this.onOpen});

  final PostVm post;
  final ValueChanged<PostVm>? onOpen;

  @override
  Widget build(BuildContext context) {
    final title = post.title.trim();
    final excerpt = post.excerpt.trim();
    final author = post.author.nickname?.trim() ?? '';

    return Material(
      color: const Color(0xFF21170D),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onOpen == null ? null : () => onOpen!(post),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? post.slug : title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (excerpt.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        excerpt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.25,
                        ),
                      ),
                    ],
                    if (author.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
