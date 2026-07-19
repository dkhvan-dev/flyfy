import 'package:flutter/material.dart';

import '../../../../core/ui/app_design_system.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/saved_browse_models.dart';
import '../../domain/saved_target.dart';

class SavedItemCard extends StatelessWidget {
  const SavedItemCard({
    super.key,
    required this.item,
    required this.isPending,
    required this.isAssignmentPending,
    required this.isAssignmentLoading,
    required this.inCollection,
    required this.onManageSavedItem,
    this.onRemoveFromCollection,
    this.onOpen,
  });

  final SavedListItem item;
  final bool isPending;
  final bool isAssignmentPending;
  final bool isAssignmentLoading;
  final bool inCollection;
  final VoidCallback onManageSavedItem;
  final VoidCallback? onRemoveFromCollection;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final l10n = AppLocalizations.of(context)!;
    final projection = item.projection;
    final available = projection is AvailableSavedCardProjection;
    final canOpen = available && onOpen != null;
    final title = available ? projection.title : l10n.savedUnavailableTitle;
    final searchMatchLabel = _searchMatchLabel(item, l10n);

    return RepaintBoundary(
      child: Semantics(
        key: ValueKey(
          'saved-card-semantics-${item.target.entityType.wireValue}-${item.target.entityId}',
        ),
        container: true,
        explicitChildNodes: true,
        label: searchMatchLabel == null ? title : '$title. $searchMatchLabel',
        button: canOpen,
        onTap: canOpen ? onOpen : null,
        child: Material(
          color: colors.surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.compactCard,
            side: BorderSide(color: colors.borderSoft),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            excludeFromSemantics: true,
            onTap: canOpen ? onOpen : null,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final thumbnailExtent = _thumbnailExtent(constraints.maxWidth);
                final targetKey =
                    '${item.target.entityType.wireValue}-${item.target.entityId}';
                return Padding(
                  padding: AppInsets.allMd,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox.square(
                        key: ValueKey('saved-media-$targetKey'),
                        dimension: thumbnailExtent,
                        child: ClipRRect(
                          borderRadius: AppRadius.compactCard,
                          child: _SavedItemMedia(
                            projection: projection,
                            entityType: item.target.entityType,
                            logicalWidth: thumbnailExtent,
                            imageKey: ValueKey(
                              'saved-network-image-$targetKey',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _SavedItemDetails(
                          targetKey: targetKey,
                          entityType: item.target.entityType,
                          title: title,
                          subtitle: available ? projection.subtitle : null,
                          unavailableMessage: available
                              ? null
                              : l10n.savedUnavailableMessage,
                          searchMatchLabel: searchMatchLabel,
                          collectionCount: item.effectiveCollectionCount,
                          isPending: isPending,
                          isAssignmentPending: isAssignmentPending,
                          isAssignmentLoading: isAssignmentLoading,
                          inCollection: inCollection,
                          onManageSavedItem: onManageSavedItem,
                          onRemoveFromCollection: onRemoveFromCollection,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  double _thumbnailExtent(double cardWidth) {
    if (cardWidth < 340) return 104;
    if (cardWidth < 480) return 112;
    return 120;
  }

  String? _searchMatchLabel(SavedListItem item, AppLocalizations l10n) {
    if (item is! SavedSearchItem) return null;
    final value = item.match.alternatePublicDisplayValue;
    if (value == null || value.isEmpty) return null;
    return switch (item.match.matchedField) {
      SavedSearchMatchedField.title => l10n.savedSearchMatchedTitle(value),
      SavedSearchMatchedField.city => l10n.savedSearchMatchedCity(value),
      SavedSearchMatchedField.country => l10n.savedSearchMatchedCountry(value),
    };
  }
}

class _SavedItemMedia extends StatelessWidget {
  const _SavedItemMedia({
    required this.projection,
    required this.entityType,
    required this.logicalWidth,
    required this.imageKey,
  });

  final SavedCardProjection projection;
  final SavedEntityType entityType;
  final double logicalWidth;
  final Key imageKey;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final available = projection is AvailableSavedCardProjection
        ? projection as AvailableSavedCardProjection
        : null;
    final imageUrl = available?.imageUrl;
    if (imageUrl == null) {
      return ColoredBox(
        color: available == null ? colors.surfaceHigh : colors.surfaceWarm,
        child: Center(
          child: Icon(
            available == null
                ? Icons.hide_image_outlined
                : _placeholderIcon(entityType),
            color: available == null ? colors.textMuted : colors.secondary,
            size: AppSizes.iconLg,
          ),
        ),
      );
    }

    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (logicalWidth * pixelRatio).round();
    return Image.network(
      imageUrl.toString(),
      key: imageKey,
      fit: BoxFit.cover,
      cacheWidth: cacheWidth,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return ColoredBox(color: colors.surfaceHigh);
      },
      errorBuilder: (context, error, stackTrace) {
        return ColoredBox(
          color: colors.surfaceWarm,
          child: Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: colors.textMuted,
              size: AppSizes.iconLg,
            ),
          ),
        );
      },
    );
  }

  IconData _placeholderIcon(SavedEntityType type) {
    return switch (type) {
      SavedEntityType.activity => Icons.directions_run_outlined,
      SavedEntityType.guide => Icons.person_pin_circle_outlined,
      SavedEntityType.user => Icons.people_alt_outlined,
      SavedEntityType.attraction => Icons.account_balance_outlined,
      SavedEntityType.post => Icons.article_outlined,
    };
  }
}

class _SavedItemDetails extends StatelessWidget {
  const _SavedItemDetails({
    required this.targetKey,
    required this.entityType,
    required this.title,
    required this.subtitle,
    required this.unavailableMessage,
    required this.searchMatchLabel,
    required this.collectionCount,
    required this.isPending,
    required this.isAssignmentPending,
    required this.isAssignmentLoading,
    required this.inCollection,
    required this.onManageSavedItem,
    required this.onRemoveFromCollection,
  });

  final String targetKey;
  final SavedEntityType entityType;
  final String title;
  final String? subtitle;
  final String? unavailableMessage;
  final String? searchMatchLabel;
  final int collectionCount;
  final bool isPending;
  final bool isAssignmentPending;
  final bool isAssignmentLoading;
  final bool inCollection;
  final VoidCallback onManageSavedItem;
  final VoidCallback? onRemoveFromCollection;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final l10n = AppLocalizations.of(context)!;
    final hasActions = inCollection && onRemoveFromCollection != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EntityTypeLabel(entityType: entityType),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Tooltip(
              message: l10n.savedBookmarkManageTooltip,
              child: IconButton(
                key: ValueKey('saved-bookmark-$targetKey'),
                onPressed: isPending || isAssignmentPending
                    ? null
                    : onManageSavedItem,
                style: AppButtonStyles.icon(colors),
                icon: isPending || isAssignmentLoading
                    ? const SizedBox.square(
                        dimension: AppSizes.iconSm,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bookmark_rounded, size: AppSizes.iconMd),
              ),
            ),
          ],
        ),
        if (subtitle?.isNotEmpty == true) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              letterSpacing: 0,
            ),
          ),
        ] else if (unavailableMessage != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            unavailableMessage!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              letterSpacing: 0,
            ),
          ),
        ],
        if (searchMatchLabel != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.search_rounded,
                size: AppSizes.iconSm,
                color: colors.secondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  searchMatchLabel!,
                  key: ValueKey('saved-search-match-$targetKey'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (collectionCount > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.savedCardCollectionsCount(collectionCount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
        if (hasActions) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (inCollection && onRemoveFromCollection != null)
                  Tooltip(
                    message: l10n.savedRemoveFromCollection,
                    child: IconButton(
                      key: ValueKey('saved-remove-current-$targetKey'),
                      onPressed: isPending || isAssignmentPending
                          ? null
                          : onRemoveFromCollection,
                      style: AppButtonStyles.icon(colors),
                      icon: const Icon(
                        Icons.folder_off_outlined,
                        size: AppSizes.iconMd,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _EntityTypeLabel extends StatelessWidget {
  const _EntityTypeLabel({required this.entityType});

  final SavedEntityType entityType;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final l10n = AppLocalizations.of(context)!;
    final (label, icon) = switch (entityType) {
      SavedEntityType.activity => (
        l10n.savedCategoryActivities,
        Icons.directions_run_outlined,
      ),
      SavedEntityType.guide => (
        l10n.savedCategoryUsers,
        Icons.person_pin_circle_outlined,
      ),
      SavedEntityType.user => (
        l10n.savedCategoryUsers,
        Icons.people_alt_outlined,
      ),
      SavedEntityType.attraction => (
        l10n.savedCategoryAttractions,
        Icons.account_balance_outlined,
      ),
      SavedEntityType.post => (l10n.savedCategoryPosts, Icons.article_outlined),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.iconXs, color: colors.secondary),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.secondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}
