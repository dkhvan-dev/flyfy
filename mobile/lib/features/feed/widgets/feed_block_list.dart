import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../../../core/network/post_api.dart';
import '../../../core/ui/app_inline_sort_row.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/reference/app_location_label_resolver.dart';
import '../../stories/models/post_vm.dart';
import '../../stories/models/story_vm.dart';
import '../models/feed_block_vm.dart';
import 'feed_post_content_card.dart';
import 'feed_post_card.dart';
import 'feed_system_posts_block.dart';
import 'my_subscriptions_block.dart';
import 'quick_post_thread_card.dart';
import 'story_tray_block.dart';
import 'suggested_communities_block.dart';

enum FeedPostSortMode { recommended, newest, popular, discussed }

class FeedBlockList extends StatelessWidget {
  const FeedBlockList({
    super.key,
    required this.blocks,
    required this.postApi,
    required this.onCommunityToggle,
    this.postSortMode = FeedPostSortMode.recommended,
    this.onPostSortModeChanged,
    this.onStoryOpen,
    this.onPostOpen,
    this.onPostLike,
    this.onPostShare,
    this.onPostHide,
    this.onPostNotInterested,
    this.onQuickPostEngagement,
    this.onStoryTrayOpen,
    this.onCreateStory,
    this.viewerAvatarUrl,
    this.viewerInitials = 'F',
    this.viewerUserId,
    this.onCommunityOpen,
    this.onCommunityModerationOpen,
    this.onCommunityExploreOpen,
    this.onMySubscriptionsOpen,
    this.onSystemPostsOpen,
    this.onPersonOpen,
    this.onConversionBlockOpen,
    this.controller,
    this.isLoadingMore = false,
    this.hasLoadMoreError = false,
    this.onLoadMoreRetry,
    this.updatingCommunityIds = const {},
    this.locationLabelResolver,
  });

  final List<FeedBlockVm> blocks;
  final PostApi postApi;
  final ValueChanged<FeedCommunityVm> onCommunityToggle;
  final FeedPostSortMode postSortMode;
  final ValueChanged<FeedPostSortMode>? onPostSortModeChanged;
  final ValueChanged<StoryVm>? onStoryOpen;
  final ValueChanged<PostVm>? onPostOpen;
  final FeedPostLikeCallback? onPostLike;
  final FeedPostActionCallback? onPostShare;
  final FeedPostActionCallback? onPostHide;
  final FeedPostActionCallback? onPostNotInterested;
  final QuickPostEngagementCallback? onQuickPostEngagement;
  final StoryTrayOpenCallback? onStoryTrayOpen;
  final VoidCallback? onCreateStory;
  final String? viewerAvatarUrl;
  final String viewerInitials;
  final String? viewerUserId;
  final ValueChanged<FeedCommunityVm>? onCommunityOpen;
  final ValueChanged<FeedCommunityVm>? onCommunityModerationOpen;
  final VoidCallback? onCommunityExploreOpen;
  final VoidCallback? onMySubscriptionsOpen;
  final ValueChanged<List<PostVm>>? onSystemPostsOpen;
  final ValueChanged<FeedPersonVm>? onPersonOpen;
  final ValueChanged<FeedBlockVm>? onConversionBlockOpen;
  final ScrollController? controller;
  final bool isLoadingMore;
  final bool hasLoadMoreError;
  final VoidCallback? onLoadMoreRetry;
  final Set<String> updatingCommunityIds;
  final AppLocationLabelResolver? locationLabelResolver;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final renderableBlocks = blocks
            .where((block) => _isRenderableBlock(block, onCreateStory))
            .toList(growable: false);
        final entries = _withPostSortEntry(
          renderableBlocks,
          onPostSortModeChanged,
        );

        return ListView.builder(
          key: const PageStorageKey<String>('feed-block-list'),
          controller: controller,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppEdgeInsets.fromLTRB(
            _horizontalPadding(constraints.maxWidth),
            16,
            _horizontalPadding(constraints.maxWidth),
            24,
          ),
          itemCount:
              entries.length + (isLoadingMore || hasLoadMoreError ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= entries.length) {
              return _FeedPaginationFooter(
                isLoading: isLoadingMore,
                hasError: hasLoadMoreError,
                onRetry: onLoadMoreRetry,
              );
            }

            final entry = entries[index];
            final child = entry.isPostSort
                ? _FeedPostSortRow(
                    selectedValue: postSortMode,
                    onSelected: onPostSortModeChanged ?? (_) {},
                  )
                : _blockChild(entry.block!);

            return Padding(
              padding: AppEdgeInsets.only(
                bottom: index == entries.length - 1 ? 0 : 16,
              ),
              child: child,
            );
          },
        );
      },
    );
  }

  Widget _blockChild(FeedBlockVm block) {
    return switch (block.type) {
      FeedBlockType.storiesTray => StoryTrayBlock(
        stories: block.stories,
        onCreateStory: onCreateStory,
        viewerAvatarUrl: viewerAvatarUrl,
        viewerInitials: viewerInitials,
        viewerUserId: viewerUserId,
        onStoryOpen:
            onStoryTrayOpen ??
            (onStoryOpen == null
                ? null
                : (story, stories, index) => onStoryOpen!(story)),
      ),
      FeedBlockType.suggestedCommunities => SuggestedCommunitiesBlock(
        communities: block.communities,
        updatingCommunityIds: updatingCommunityIds,
        onCommunityToggle: onCommunityToggle,
        onCommunityOpen: onCommunityOpen,
        onCommunityModerationOpen: onCommunityModerationOpen,
        onOpenAll: onCommunityExploreOpen,
        locationLabelResolver: locationLabelResolver,
      ),
      FeedBlockType.mySubscriptions => MySubscriptionsBlock(
        subscriptions: FeedSubscriptionsVm(
          communities: block.communities,
          people: block.people,
        ),
        onCommunityOpen: onCommunityOpen,
        onPersonOpen: onPersonOpen,
        onOpenAll: onMySubscriptionsOpen,
        locationLabelResolver: locationLabelResolver,
      ),
      FeedBlockType.systemPosts => FeedSystemPostsBlock(
        posts: block.posts,
        onPostOpen: onPostOpen,
        onOpenAll: onSystemPostsOpen,
      ),
      FeedBlockType.postCard =>
        block.post == null ? const SizedBox.shrink() : _postCard(block.post!),
      FeedBlockType.profileCard ||
      FeedBlockType.officialNewsCard => const SizedBox.shrink(),
      FeedBlockType.tourCard ||
      FeedBlockType.guideCard => const SizedBox.shrink(),
      FeedBlockType.unknown => const SizedBox.shrink(),
    };
  }

  Widget _postCard(PostVm post) {
    return FeedPostContentCard(
      post: post,
      postApi: postApi,
      canInteract: onPostLike != null,
      onOpen: onPostOpen,
      onLike: onPostLike,
      onShare: onPostShare,
      onHide: onPostHide,
      onNotInterested: onPostNotInterested,
      onQuickPostEngagement: onQuickPostEngagement,
    );
  }
}

class _FeedPostSortRow extends StatelessWidget {
  const _FeedPostSortRow({
    required this.selectedValue,
    required this.onSelected,
  });

  final FeedPostSortMode selectedValue;
  final ValueChanged<FeedPostSortMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      key: const ValueKey('feed-post-sort-row'),
      padding: const AppEdgeInsets.symmetric(horizontal: 4),
      child: AppInlineSortRow<FeedPostSortMode>(
        label: l10n.activitiesSortLabel,
        options: [
          AppInlineSortOption(
            value: FeedPostSortMode.recommended,
            label: l10n.feedPostSortRecommended,
          ),
          AppInlineSortOption(
            value: FeedPostSortMode.newest,
            label: l10n.feedPostSortNewest,
          ),
          AppInlineSortOption(
            value: FeedPostSortMode.popular,
            label: l10n.feedPostSortPopular,
          ),
          AppInlineSortOption(
            value: FeedPostSortMode.discussed,
            label: l10n.feedPostSortDiscussed,
          ),
        ],
        selectedValue: selectedValue,
        isAscending: false,
        onSelected: onSelected,
      ),
    );
  }
}

class _FeedListEntry {
  const _FeedListEntry.block(this.block) : isPostSort = false;

  const _FeedListEntry.postSort() : block = null, isPostSort = true;

  final FeedBlockVm? block;
  final bool isPostSort;
}

List<_FeedListEntry> _withPostSortEntry(
  List<FeedBlockVm> blocks,
  ValueChanged<FeedPostSortMode>? onPostSortModeChanged,
) {
  final entries = [for (final block in blocks) _FeedListEntry.block(block)];
  if (onPostSortModeChanged == null ||
      !blocks.any((block) => block.type == FeedBlockType.postCard)) {
    return entries;
  }

  var anchorIndex = blocks.indexWhere(
    (block) => block.type == FeedBlockType.mySubscriptions,
  );
  anchorIndex = anchorIndex >= 0
      ? anchorIndex
      : blocks.indexWhere(
          (block) => block.type == FeedBlockType.suggestedCommunities,
        );
  if (anchorIndex < 0) {
    return entries;
  }

  return [
    ...entries.take(anchorIndex + 1),
    const _FeedListEntry.postSort(),
    ...entries.skip(anchorIndex + 1),
  ];
}

class _FeedPaginationFooter extends StatelessWidget {
  const _FeedPaginationFooter({
    required this.isLoading,
    required this.hasError,
    this.onRetry,
  });

  final bool isLoading;
  final bool hasError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: AppEdgeInsets.symmetric(vertical: 18),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!hasError) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const AppEdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.feedLoadFailedMessage,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onRetry,
                child: Text(
                  l10n.feedRetryAction,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isRenderableBlock(FeedBlockVm block, VoidCallback? onCreateStory) {
  return switch (block.type) {
    FeedBlockType.storiesTray =>
      block.stories.isNotEmpty || onCreateStory != null,
    FeedBlockType.suggestedCommunities => block.communities.isNotEmpty,
    FeedBlockType.mySubscriptions =>
      block.communities.isNotEmpty || block.people.isNotEmpty,
    FeedBlockType.systemPosts => block.posts.isNotEmpty,
    FeedBlockType.postCard => block.post != null,
    FeedBlockType.profileCard || FeedBlockType.officialNewsCard => false,
    FeedBlockType.tourCard || FeedBlockType.guideCard => false,
    FeedBlockType.unknown => false,
  };
}

double _horizontalPadding(double width) {
  if (width >= 840) {
    return 32;
  }
  if (width >= 600) {
    return 24;
  }
  return 16;
}
