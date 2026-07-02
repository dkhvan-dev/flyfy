import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../models/feed_block_vm.dart';
import 'community_display_helpers.dart';

class CommunityListItem extends StatelessWidget {
  const CommunityListItem({
    super.key,
    required this.community,
    required this.onToggle,
    this.onOpen,
    this.onModerationOpen,
    this.isUpdating = false,
    this.openKeyPrefix = 'open-community',
    this.compact = false,
    this.displayTitle,
    this.subtitleOverride,
    this.tertiaryOverride,
    this.subtitleWidget,
    this.tertiaryWidget,
  });

  final FeedCommunityVm community;
  final ValueChanged<FeedCommunityVm> onToggle;
  final ValueChanged<FeedCommunityVm>? onOpen;
  final ValueChanged<FeedCommunityVm>? onModerationOpen;
  final bool isUpdating;
  final String openKeyPrefix;
  final bool compact;
  final String? displayTitle;
  final String? subtitleOverride;
  final String? tertiaryOverride;
  final Widget? subtitleWidget;
  final Widget? tertiaryWidget;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final title = (displayTitle ?? feedCommunityDisplayTitle(community, l10n))
        .trim();
    final subtitle =
        _trimmedOrNull(subtitleOverride) ?? _communitySubtitle(community, l10n);
    final tertiary = _trimmedOrNull(tertiaryOverride);
    final actionLabel = community.followedByViewer
        ? l10n.feedCommunityJoinedAction
        : l10n.feedJoinCommunityAction;

    return InkWell(
      key: ValueKey('$openKeyPrefix-${community.id}'),
      borderRadius: AppBorderRadius.circular(8),
      onTap: onOpen == null ? null : () => onOpen!(community),
      child: Padding(
        padding: const AppEdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            _CommunityAvatar(title: title, radius: compact ? 20 : 22),
            SizedBox(width: compact ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitleWidget != null) ...[
                    SizedBox(height: compact ? 2 : 4),
                    subtitleWidget!,
                  ] else if (subtitle.isNotEmpty) ...[
                    SizedBox(height: compact ? 2 : 4),
                    Text(
                      subtitle,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                  if (tertiaryWidget != null) ...[
                    const SizedBox(height: 2),
                    tertiaryWidget!,
                  ] else if (tertiary != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      tertiary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                        height: 1.12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: compact ? 8 : 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                compact
                    ? IconButton(
                        onPressed: isUpdating
                            ? null
                            : () => onToggle(community),
                        style: IconButton.styleFrom(
                          foregroundColor: colors.primary,
                          backgroundColor: colors.primary.withValues(
                            alpha: 0.12,
                          ),
                          minimumSize: const Size.square(36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: isUpdating
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.textPrimary,
                                ),
                              )
                            : const Icon(Icons.add_circle_outline_rounded),
                      )
                    : TextButton(
                        onPressed: isUpdating
                            ? null
                            : () => onToggle(community),
                        style: TextButton.styleFrom(
                          foregroundColor: community.followedByViewer
                              ? colors.textSecondary
                              : colors.primary,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: isUpdating
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.textPrimary,
                                ),
                              )
                            : Text(
                                actionLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                if (!compact &&
                    community.viewerCanModerate &&
                    onModerationOpen != null)
                  TextButton.icon(
                    key: ValueKey('moderate-${community.id}'),
                    onPressed: () => onModerationOpen!(community),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.secondary,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.shield_outlined, size: 16),
                    label: Text(
                      l10n.feedCommunityModerationAction,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityAvatar extends StatelessWidget {
  const _CommunityAvatar({required this.title, required this.radius});

  final String title;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final initial = title.trim().isEmpty ? 'F' : title.trim()[0].toUpperCase();

    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.primary.withValues(alpha: 0.16),
      foregroundColor: colors.primary,
      child: Text(
        initial,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: AppTextStyle(color: colors.primary, fontWeight: FontWeight.w800),
      ),
    );
  }
}

String _communitySubtitle(FeedCommunityVm community, AppLocalizations l10n) {
  final subtitle = feedCommunityDisplayDescription(community, l10n);
  if (subtitle.isNotEmpty) {
    return subtitle;
  }
  if (community.membersCount > 0) {
    return l10n.feedCommunityMembersLabel(community.membersCount.toString());
  }
  return '';
}

String? _trimmedOrNull(String? value) {
  final trimmed = (value ?? '').trim();
  return trimmed.isEmpty ? null : trimmed;
}
