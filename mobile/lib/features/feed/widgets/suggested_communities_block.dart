import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/reference/app_location_label_resolver.dart';
import '../models/feed_block_vm.dart';
import 'community_display_helpers.dart';
import 'community_location_text.dart';
import 'community_list_item.dart';

class SuggestedCommunitiesBlock extends StatelessWidget {
  const SuggestedCommunitiesBlock({
    super.key,
    required this.communities,
    required this.onCommunityToggle,
    this.onCommunityOpen,
    this.onCommunityModerationOpen,
    this.onOpenAll,
    this.updatingCommunityIds = const {},
    this.locationLabelResolver,
  });

  final List<FeedCommunityVm> communities;
  final ValueChanged<FeedCommunityVm> onCommunityToggle;
  final ValueChanged<FeedCommunityVm>? onCommunityOpen;
  final ValueChanged<FeedCommunityVm>? onCommunityModerationOpen;
  final VoidCallback? onOpenAll;
  final Set<String> updatingCommunityIds;
  final AppLocationLabelResolver? locationLabelResolver;

  @override
  Widget build(BuildContext context) {
    final visibleCommunities = communities
        .where((community) => !community.followedByViewer)
        .toList(growable: false);
    if (visibleCommunities.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      key: const ValueKey('suggested-communities-block'),
      decoration: AppBoxDecoration(
        color: colors.surface,
        borderRadius: AppBorderRadius.circular(8),
        border: Border.all(color: colors.borderPrimary),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
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
                Expanded(
                  child: Text(
                    l10n.feedSuggestedCommunitiesTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  key: const ValueKey('open-community-discovery-sheet'),
                  onPressed: onOpenAll,
                  tooltip: l10n.communityDiscoveryTitle,
                  style: IconButton.styleFrom(
                    backgroundColor: colors.primary.withValues(alpha: 0.16),
                    foregroundColor: colors.primary,
                    minimumSize: const Size.square(40),
                  ),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth * 0.78).clamp(
                  220.0,
                  300.0,
                );
                return ClipRect(
                  key: const ValueKey('suggested-communities-clip'),
                  child: SingleChildScrollView(
                    key: const ValueKey('suggested-communities-rail'),
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.hardEdge,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SuggestedCommunityRow(
                          key: const ValueKey('suggested-communities-row-0'),
                          itemWidth: itemWidth,
                          communities: [
                            for (
                              var i = 0;
                              i < visibleCommunities.length;
                              i += 2
                            )
                              visibleCommunities[i],
                          ],
                          updatingCommunityIds: updatingCommunityIds,
                          onCommunityToggle: onCommunityToggle,
                          onCommunityOpen: onCommunityOpen,
                          onCommunityModerationOpen: onCommunityModerationOpen,
                          locationLabelResolver: locationLabelResolver,
                        ),
                        if (visibleCommunities.length > 1) ...[
                          const SizedBox(height: 10),
                          _SuggestedCommunityRow(
                            key: const ValueKey('suggested-communities-row-1'),
                            itemWidth: itemWidth,
                            communities: [
                              for (
                                var i = 1;
                                i < visibleCommunities.length;
                                i += 2
                              )
                                visibleCommunities[i],
                            ],
                            updatingCommunityIds: updatingCommunityIds,
                            onCommunityToggle: onCommunityToggle,
                            onCommunityOpen: onCommunityOpen,
                            onCommunityModerationOpen:
                                onCommunityModerationOpen,
                            locationLabelResolver: locationLabelResolver,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestedCommunityRow extends StatelessWidget {
  const _SuggestedCommunityRow({
    super.key,
    required this.itemWidth,
    required this.communities,
    required this.updatingCommunityIds,
    required this.onCommunityToggle,
    this.onCommunityOpen,
    this.onCommunityModerationOpen,
    this.locationLabelResolver,
  });

  final double itemWidth;
  final List<FeedCommunityVm> communities;
  final Set<String> updatingCommunityIds;
  final ValueChanged<FeedCommunityVm> onCommunityToggle;
  final ValueChanged<FeedCommunityVm>? onCommunityOpen;
  final ValueChanged<FeedCommunityVm>? onCommunityModerationOpen;
  final AppLocationLabelResolver? locationLabelResolver;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < communities.length; index++) ...[
          SizedBox(
            width: itemWidth,
            child: _SuggestedCommunityPill(
              community: communities[index],
              isUpdating: updatingCommunityIds.contains(communities[index].id),
              onCommunityToggle: onCommunityToggle,
              onCommunityOpen: onCommunityOpen,
              onCommunityModerationOpen: onCommunityModerationOpen,
              locationLabelResolver: locationLabelResolver,
            ),
          ),
          if (index != communities.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _SuggestedCommunityPill extends StatelessWidget {
  const _SuggestedCommunityPill({
    required this.community,
    required this.isUpdating,
    required this.onCommunityToggle,
    this.onCommunityOpen,
    this.onCommunityModerationOpen,
    this.locationLabelResolver,
  });

  final FeedCommunityVm community;
  final bool isUpdating;
  final ValueChanged<FeedCommunityVm> onCommunityToggle;
  final ValueChanged<FeedCommunityVm>? onCommunityOpen;
  final ValueChanged<FeedCommunityVm>? onCommunityModerationOpen;
  final AppLocationLabelResolver? locationLabelResolver;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: colors.surfaceHigh,
        borderRadius: AppBorderRadius.circular(8),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.42),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const AppEdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: CommunityListItem(
          community: community,
          isUpdating: isUpdating,
          openKeyPrefix: 'open-suggested-community',
          onToggle: onCommunityToggle,
          onOpen: onCommunityOpen,
          onModerationOpen: onCommunityModerationOpen,
          compact: true,
          displayTitle: feedCommunityDisplayTitle(community, l10n),
          subtitleWidget: FeedCommunityLocationText(
            community: community,
            resolver: locationLabelResolver,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              height: 1.12,
            ),
          ),
          tertiaryWidget: Text(
            feedCommunityMembersLabel(community, l10n),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
              height: 1.12,
            ),
          ),
        ),
      ),
    );
  }
}
