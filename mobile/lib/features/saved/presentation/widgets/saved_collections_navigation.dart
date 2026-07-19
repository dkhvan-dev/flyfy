import 'package:flutter/material.dart';

import '../../../../core/ui/app_design_system.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/saved_operation.dart';
import 'saved_cover_thumbnail.dart';

const _sidebarCoverExtent = AppSizes.minTapTarget;
const _compactCoverExtent = AppSizes.avatarLg;
const _compactPreviewItemLimit = 4;
const _compactTwoColumnMinWidth = 300.0;
const _compactTwoColumnMaxTextScale = 1.35;

class SavedCollectionsNavigation extends StatelessWidget {
  const SavedCollectionsNavigation({
    super.key,
    required this.collections,
    required this.selectedCollectionId,
    required this.expanded,
    required this.isRefreshing,
    required this.hasError,
    required this.onAllTap,
    required this.onCollectionTap,
    required this.onRetry,
    this.onSeeAllTap,
  });

  final List<SavedCollectionRecord> collections;
  final String? selectedCollectionId;
  final bool expanded;
  final bool isRefreshing;
  final bool hasError;
  final VoidCallback onAllTap;
  final ValueChanged<SavedCollectionRecord> onCollectionTap;
  final VoidCallback onRetry;
  final VoidCallback? onSeeAllTap;

  @override
  Widget build(BuildContext context) {
    return expanded ? _buildSidebar(context) : _buildCompactGrid(context);
  }

  Widget _buildSidebar(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final l10n = AppLocalizations.of(context)!;
    return ColoredBox(
      color: colors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const AppEdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.savedCollectionsTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                if (isRefreshing)
                  const Padding(
                    padding: AppInsets.allSm,
                    child: SizedBox.square(
                      dimension: AppSizes.iconSm,
                      child: CircularProgressIndicator(
                        strokeWidth: AppSpacing.xxs,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (hasError)
            SavedCollectionsLoadError(
              isRetrying: isRefreshing,
              onRetry: onRetry,
            ),
          Expanded(
            child: ListView.builder(
              key: const PageStorageKey('saved-collections-sidebar'),
              padding: const AppEdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.xs,
                AppSpacing.sm,
                AppSpacing.xl,
              ),
              itemCount: collections.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _SidebarTile(
                    key: const ValueKey('saved-all-navigation'),
                    selected: selectedCollectionId == null,
                    title: l10n.savedAllItems,
                    subtitle: null,
                    leading: SavedCoverThumbnail(
                      imageUrl: null,
                      fallbackIcon: Icons.bookmarks_rounded,
                      extent: _sidebarCoverExtent,
                      selected: selectedCollectionId == null,
                    ),
                    onTap: onAllTap,
                  );
                }
                final collection = collections[index - 1];
                return _SidebarTile(
                  key: ValueKey(
                    'saved-collection-navigation-${collection.collectionId}',
                  ),
                  selected: selectedCollectionId == collection.collectionId,
                  title: collection.title,
                  subtitle: l10n.savedCollectionItemCount(
                    collection.activeItemCount,
                  ),
                  leading: SavedCoverThumbnail(
                    imageUrl: collection.coverPreview is CollectionItemCover
                        ? (collection.coverPreview as CollectionItemCover)
                              .imageUrl
                        : null,
                    fallbackIcon: Icons.folder_rounded,
                    extent: _sidebarCoverExtent,
                    selected: selectedCollectionId == collection.collectionId,
                  ),
                  onTap: () => onCollectionTap(collection),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactGrid(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final l10n = AppLocalizations.of(context)!;
    final baseFontSize =
        Theme.of(context).textTheme.bodyMedium?.fontSize ?? AppTypography.body;
    final textScale =
        MediaQuery.textScalerOf(context).scale(baseFontSize) / baseFontSize;
    final canSeeAll = collections.length >= _compactPreviewItemLimit;
    final visibleCollections = _compactCollectionPreview(
      collections,
      selectedCollectionId,
    );
    final seeAllLabel = l10n.savedCollectionsSeeAll;
    final useIconToggle =
        MediaQuery.sizeOf(context).width < 360 ||
        textScale > _compactTwoColumnMaxTextScale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const AppEdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.savedCollectionsTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
              if (isRefreshing)
                const Padding(
                  padding: AppInsets.allSm,
                  child: SizedBox.square(
                    dimension: AppSizes.iconSm,
                    child: CircularProgressIndicator(
                      strokeWidth: AppSpacing.xxs,
                    ),
                  ),
                ),
              if (canSeeAll && onSeeAllTap != null)
                if (useIconToggle)
                  IconButton(
                    key: const ValueKey('saved-collections-see-all'),
                    tooltip: seeAllLabel,
                    onPressed: onSeeAllTap,
                    style: AppButtonStyles.icon(colors),
                    icon: const Icon(Icons.grid_view_rounded),
                  )
                else
                  TextButton(
                    key: const ValueKey('saved-collections-see-all'),
                    onPressed: onSeeAllTap,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.primary,
                      minimumSize: const Size(0, AppSizes.minDenseTapTarget),
                      padding: const AppEdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                    ),
                    child: Text(seeAllLabel),
                  ),
            ],
          ),
        ),
        if (hasError)
          SavedCollectionsLoadError(isRetrying: isRefreshing, onRetry: onRetry),
        Padding(
          padding: const AppEdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columnCount =
                  constraints.maxWidth >= _compactTwoColumnMinWidth &&
                      textScale <= _compactTwoColumnMaxTextScale
                  ? 2
                  : 1;
              final itemWidth =
                  (constraints.maxWidth - ((columnCount - 1) * AppSpacing.md)) /
                  columnCount;
              return Wrap(
                key: const ValueKey('saved-collections-grid'),
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: SavedCollectionTile(
                      key: const ValueKey('saved-all-navigation'),
                      selected: selectedCollectionId == null,
                      title: l10n.savedAllItems,
                      subtitle: null,
                      allItems: true,
                      onTap: onAllTap,
                    ),
                  ),
                  for (final collection in visibleCollections)
                    SizedBox(
                      width: itemWidth,
                      child: SavedCollectionTile(
                        key: ValueKey(
                          'saved-collection-navigation-${collection.collectionId}',
                        ),
                        selected:
                            selectedCollectionId == collection.collectionId,
                        title: collection.title,
                        subtitle: l10n.savedCollectionItemCount(
                          collection.activeItemCount,
                        ),
                        coverPreview: collection.coverPreview,
                        onTap: () => onCollectionTap(collection),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  List<SavedCollectionRecord> _compactCollectionPreview(
    List<SavedCollectionRecord> source,
    String? selectedId,
  ) {
    const collectionLimit = _compactPreviewItemLimit - 1;
    if (source.length <= collectionLimit) return source;
    final preview = source.take(collectionLimit).toList(growable: true);
    if (selectedId == null ||
        preview.any((collection) => collection.collectionId == selectedId)) {
      return preview;
    }
    final selected = source.cast<SavedCollectionRecord?>().firstWhere(
      (collection) => collection?.collectionId == selectedId,
      orElse: () => null,
    );
    if (selected != null) preview[preview.length - 1] = selected;
    return preview;
  }
}

class SavedCollectionsLoadError extends StatelessWidget {
  const SavedCollectionsLoadError({
    super.key,
    required this.isRetrying,
    required this.onRetry,
  });

  final bool isRetrying;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const AppEdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.zero,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: Material(
          color: colors.surfaceWarm,
          borderRadius: AppRadius.compactCard,
          child: Padding(
            padding: const AppEdgeInsets.only(left: AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  color: colors.danger,
                  size: AppSizes.iconSm,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.savedCollectionsLoadError,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('saved-collections-retry'),
                  tooltip: l10n.retryButton,
                  onPressed: isRetrying ? null : onRetry,
                  icon: isRetrying
                      ? const SizedBox.square(
                          dimension: AppSizes.iconSm,
                          child: CircularProgressIndicator(
                            strokeWidth: AppSpacing.xxs,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    super.key,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String? subtitle;
  final Widget leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return Padding(
      padding: const AppEdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: selected ? colors.primaryContainer : colors.transparent,
        borderRadius: AppRadius.compactCard,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.compactCard,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
            child: Padding(
              padding: AppInsets.listItem,
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: _sidebarCoverExtent,
                    child: leading,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: colors.textPrimary,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                letterSpacing: 0,
                              ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colors.textMuted,
                                  letterSpacing: 0,
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
        ),
      ),
    );
  }
}

class SavedCollectionTile extends StatelessWidget {
  const SavedCollectionTile({
    super.key,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.coverPreview,
    this.allItems = false,
  }) : assert(
         allItems || coverPreview != null,
         'A collection cover is required.',
       );

  final bool selected;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final CollectionCoverPreview? coverPreview;
  final bool allItems;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final collectionItem = coverPreview is CollectionItemCover
        ? coverPreview as CollectionItemCover
        : null;
    final cover = SavedCoverThumbnail(
      imageUrl: allItems ? null : collectionItem?.imageUrl,
      fallbackIcon: allItems ? Icons.bookmarks_rounded : Icons.folder_rounded,
      selected: selected,
    );
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? colors.primaryContainer : colors.transparent,
        borderRadius: AppRadius.compactCard,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.compactCard,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: _compactCoverExtent + (AppSpacing.xs * 2),
            ),
            child: Padding(
              padding: AppInsets.allXs,
              child: Row(
                children: [
                  SizedBox.square(dimension: _compactCoverExtent, child: cover),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0,
                              ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Row(
                            children: [
                              Icon(
                                Icons.bookmark_border_rounded,
                                size: AppSizes.iconXs,
                                color: colors.textMuted,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  subtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colors.textMuted,
                                        letterSpacing: 0,
                                      ),
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
            ),
          ),
        ),
      ),
    );
  }
}
