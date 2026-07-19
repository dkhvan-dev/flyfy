import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/ui/app_design_system.dart';
import '../../../../core/ui/app_modal_templates.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/saved_browse_models.dart';
import '../../domain/saved_operation.dart';
import '../../domain/saved_target.dart';
import '../saved_ui_messages.dart';
import '../state/saved_screen_controller.dart';
import 'saved_cover_thumbnail.dart';

const _compactSheetHeightRatio = 0.48;
const _compactSheetMaxHeightRatio = 0.58;
const _largeTextSheetHeightRatio = 0.64;
const _pickerSearchThreshold = 8;

typedef SavedGlobalUnsaveCallback = Future<SavedUserActionResult> Function();

Future<SavedUserActionResult?> showSavedCollectionPicker({
  required BuildContext context,
  required SavedScreenController controller,
  required SavedTarget target,
  SavedTargetCollectionsSnapshot? initialSnapshot,
  SavedSourceSurface? sourceSurface,
  bool allowGlobalUnsave = false,
  SavedGlobalUnsaveCallback? onGlobalUnsave,
  String? previewTitle,
  String? previewSubtitle,
  String? previewImageUrl,
}) {
  if (initialSnapshot != null && initialSnapshot.target != target) {
    throw ArgumentError.value(
      initialSnapshot.target,
      'initialSnapshot',
      'Snapshot target must match the picker target.',
    );
  }
  if (allowGlobalUnsave && sourceSurface == null && onGlobalUnsave == null) {
    throw ArgumentError(
      'Global unsave requires a source surface or an explicit callback.',
    );
  }
  final isExpanded =
      AppBreakpoints.classify(MediaQuery.sizeOf(context).width) ==
      AppScreenClass.expanded;
  if (isExpanded) {
    return showAppModalDialog<SavedUserActionResult>(
      context: context,
      builder: (dialogContext) {
        final mediaQuery = MediaQuery.of(dialogContext);
        final colors = AppDesignSystem.colorsFor(dialogContext);
        final availableContentHeight =
            mediaQuery.size.height -
            mediaQuery.viewPadding.vertical -
            mediaQuery.viewInsets.bottom -
            AppSpacing.huge -
            AppSpacing.xxxl;
        final contentHeight = availableContentHeight
            .clamp(AppSpacing.zero, 560.0)
            .toDouble();

        return AnimatedPadding(
          duration: AppMotion.normal,
          curve: AppMotion.curve,
          padding: AppEdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
          child: AppModalDialogCard(
            content: SizedBox(
              width: double.infinity,
              height: contentHeight,
              child: Material(
                color: colors.transparent,
                child: _SavedCollectionPickerContent(
                  controller: controller,
                  target: target,
                  initialSnapshot: initialSnapshot,
                  sourceSurface: sourceSurface,
                  allowGlobalUnsave: allowGlobalUnsave,
                  onGlobalUnsave: onGlobalUnsave,
                  previewTitle: previewTitle,
                  previewSubtitle: previewSubtitle,
                  previewImageUrl: previewImageUrl,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  final colors = AppDesignSystem.colorsFor(context);
  return showAppModalBottomSheet<SavedUserActionResult>(
    context: context,
    backgroundColor: colors.surfaceRaised,
    showDragHandle: false,
    enableDrag: true,
    isDismissible: true,
    requestFocus: false,
    builder: (sheetContext) {
      return SizedBox(
        height: _compactPickerHeight(sheetContext),
        child: _SavedCollectionPickerContent(
          controller: controller,
          target: target,
          initialSnapshot: initialSnapshot,
          sourceSurface: sourceSurface,
          allowGlobalUnsave: allowGlobalUnsave,
          onGlobalUnsave: onGlobalUnsave,
          previewTitle: previewTitle,
          previewSubtitle: previewSubtitle,
          previewImageUrl: previewImageUrl,
          showDragHandle: true,
        ),
      );
    },
  );
}

class _SavedCollectionPickerContent extends StatefulWidget {
  const _SavedCollectionPickerContent({
    required this.controller,
    required this.target,
    required this.initialSnapshot,
    required this.sourceSurface,
    required this.allowGlobalUnsave,
    required this.onGlobalUnsave,
    required this.previewTitle,
    required this.previewSubtitle,
    required this.previewImageUrl,
    this.showDragHandle = false,
  });

  final SavedScreenController controller;
  final SavedTarget target;
  final SavedTargetCollectionsSnapshot? initialSnapshot;
  final SavedSourceSurface? sourceSurface;
  final bool allowGlobalUnsave;
  final SavedGlobalUnsaveCallback? onGlobalUnsave;
  final String? previewTitle;
  final String? previewSubtitle;
  final String? previewImageUrl;
  final bool showDragHandle;

  @override
  State<_SavedCollectionPickerContent> createState() =>
      _SavedCollectionPickerContentState();
}

class _SavedCollectionPickerContentState
    extends State<_SavedCollectionPickerContent> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _newCollectionController =
      TextEditingController();
  final CancelToken _cancelToken = CancelToken();
  late final int _lifecycleEpoch;
  SavedTargetCollectionsSnapshot? _snapshot;
  Set<String> _selectedIds = <String>{};
  Object? _loadError;
  String? _actionError;
  bool _creatingInline = false;
  bool _submitting = false;
  bool _closingForLifecycle = false;

  @override
  void initState() {
    super.initState();
    _lifecycleEpoch = widget.controller.lifecycleEpoch;
    widget.controller.addListener(_handleControllerChanged);
    _searchController.addListener(_handleSearchChanged);
    final initialSnapshot = widget.initialSnapshot;
    if (initialSnapshot == null) {
      _load();
    } else {
      _snapshot = initialSnapshot;
      _selectedIds = initialSnapshot.effectiveCollectionIds.toSet();
      unawaited(_refreshCollectionPreviews(initialSnapshot));
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    _newCollectionController.dispose();
    _cancelToken.cancel('Collection picker closed.');
    super.dispose();
  }

  void _handleControllerChanged() {
    if (widget.controller.lifecycleEpoch != _lifecycleEpoch) {
      if (_closingForLifecycle) return;
      _closingForLifecycle = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context, SavedUserActionResult.superseded);
        }
      });
      return;
    }
    if (mounted) setState(() {});
  }

  void _handleSearchChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _loadError = null;
      _snapshot = null;
    });
    try {
      final snapshot = await widget.controller.loadTargetCollections(
        widget.target,
        cancelToken: _cancelToken,
      );
      if (!mounted || widget.controller.lifecycleEpoch != _lifecycleEpoch) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _selectedIds = snapshot.effectiveCollectionIds.toSet();
      });
      unawaited(_refreshCollectionPreviews(snapshot));
    } on Object catch (error) {
      if (!mounted || _cancelToken.isCancelled) return;
      setState(() => _loadError = error);
    }
  }

  Future<void> _refreshCollectionPreviews(
    SavedTargetCollectionsSnapshot snapshot,
  ) async {
    if (snapshot.collectionOptions.isEmpty) return;
    final knownCollectionIds = widget.controller.collections
        .map((collection) => collection.collectionId)
        .toSet();
    final hasEveryPreview = snapshot.collectionOptions.every(
      (option) => knownCollectionIds.contains(option.collectionId),
    );
    if (widget.controller.initialized && hasEveryPreview) return;
    await widget.controller.refreshCollections(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final l10n = AppLocalizations.of(context)!;
    final snapshot = _snapshot;
    final isPending = widget.controller.isAssignmentPending(widget.target);
    final hasChanges = snapshot != null && _hasChanges(snapshot);
    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showDragHandle) const _SavedPickerDragHandle(),
          _buildSavedItemPreview(context, isPending: isPending),
          Divider(height: 1, thickness: 1, color: colors.borderSoft),
          _buildCollectionsHeader(context, isPending: isPending),
          Expanded(child: _buildBody(context)),
          if (_actionError != null)
            Padding(
              padding: const AppEdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.zero,
              ),
              child: Text(
                _actionError!,
                style: AppTypography.captionStyle.copyWith(
                  color: colors.danger,
                ),
              ),
            ),
          if (hasChanges)
            Padding(
              padding: const AppEdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: FilledButton.icon(
                key: const ValueKey('saved-collection-picker-submit'),
                onPressed: _submitting || isPending ? null : _submit,
                style: AppButtonStyles.primary(colors),
                icon: _submitting || isPending
                    ? SizedBox.square(
                        dimension: AppSizes.iconSm,
                        child: CircularProgressIndicator(
                          color: colors.onPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(l10n.savedCollectionPickerDone),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSavedItemPreview(
    BuildContext context, {
    required bool isPending,
  }) {
    final colors = AppDesignSystem.colorsFor(context);
    final l10n = AppLocalizations.of(context)!;
    final title =
        _nonEmpty(widget.previewTitle) ?? l10n.savedCollectionPickerTitle;
    final subtitle =
        _nonEmpty(widget.previewSubtitle) ??
        _entityLabel(l10n, widget.target.entityType);

    return Padding(
      padding: const AppEdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Semantics(
        container: true,
        label: '$title, $subtitle',
        child: Row(
          children: [
            SavedCoverThumbnail(
              key: const ValueKey('saved-picker-item-preview'),
              imageUrl: widget.previewImageUrl,
              imageKey: const ValueKey('saved-picker-item-preview-image'),
              fallbackIcon: _entityIcon(widget.target.entityType),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.subtitleStyle.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyStyle.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (widget.allowGlobalUnsave)
              IconButton(
                key: const ValueKey('saved-collection-picker-cancel-save'),
                tooltip: l10n.savedRemoveEverywhereTooltip,
                onPressed: _snapshot == null || _submitting || isPending
                    ? null
                    : _cancelSave,
                style: AppButtonStyles.icon(colors),
                icon: _submitting
                    ? SizedBox.square(
                        dimension: AppSizes.iconSm,
                        child: CircularProgressIndicator(
                          color: colors.primary,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        Icons.bookmark_rounded,
                        color: colors.primary,
                        size: AppSizes.iconLg,
                      ),
              )
            else
              Padding(
                padding: AppInsets.allSm,
                child: Icon(
                  Icons.bookmark_rounded,
                  color: colors.primary,
                  size: AppSizes.iconLg,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionsHeader(
    BuildContext context, {
    required bool isPending,
  }) {
    final colors = AppDesignSystem.colorsFor(context);
    final l10n = AppLocalizations.of(context)!;
    final title = Text(
      l10n.savedCollectionsTitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.titleStyle.copyWith(color: colors.textPrimary),
    );
    final createButton = widget.controller.collectionsExpansionEnabled
        ? TextButton(
            key: const ValueKey('saved-create-inline-collection'),
            onPressed: _submitting || isPending
                ? null
                : () => setState(() {
                    _creatingInline = !_creatingInline;
                    _actionError = null;
                    if (!_creatingInline) {
                      _newCollectionController.clear();
                    }
                  }),
            style: AppButtonStyles.ghost(colors),
            child: Text(l10n.savedCollectionCreateInline),
          )
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useStackedHeader =
            createButton != null &&
            constraints.maxWidth < 340 &&
            MediaQuery.textScalerOf(context).scale(1) > 1.2;
        return Padding(
          padding: const AppEdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
          child: useStackedHeader
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    title,
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: createButton,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: title),
                    ?createButton,
                  ],
                ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final l10n = AppLocalizations.of(context)!;
    final snapshot = _snapshot;
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: AppInsets.panel,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                color: colors.danger,
                size: AppSizes.minTapTarget,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                savedErrorMessage(l10n, _loadError!),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _load,
                style: AppButtonStyles.secondary(colors),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.retryButton),
              ),
            ],
          ),
        ),
      );
    }
    if (snapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _filterOptions(
      snapshot.collectionOptions,
      _searchController.text,
    );
    final collectionsById = <String, SavedCollectionRecord>{
      for (final collection in widget.controller.collections)
        collection.collectionId: collection,
    };
    final isPending = widget.controller.isAssignmentPending(widget.target);
    final showSearch =
        snapshot.collectionOptions.length >= _pickerSearchThreshold;
    return CustomScrollView(
      slivers: [
        if (showSearch)
          SliverPadding(
            padding: const AppEdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: TextField(
                key: const ValueKey('saved-collection-picker-search'),
                controller: _searchController,
                enabled: !_submitting && !isPending,
                textInputAction: TextInputAction.search,
                decoration: AppInputDecorations.textField(
                  label: l10n.savedCollectionPickerSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).deleteButtonTooltip,
                          onPressed: _searchController.clear,
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),
          ),
        if (_creatingInline)
          SliverPadding(
            padding: const AppEdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: TextField(
                key: const ValueKey('saved-inline-collection-title'),
                controller: _newCollectionController,
                autofocus: true,
                enabled: !_submitting,
                maxLength: 80,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                textCapitalization: TextCapitalization.sentences,
                decoration: AppInputDecorations.textField(
                  label: l10n.savedCollectionTitleLabel,
                  hint: l10n.savedCollectionTitleHint,
                ),
              ),
            ),
          ),
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: AppInsets.panel,
                child: Text(
                  _searchController.text.trim().isEmpty
                      ? l10n.savedCollectionPickerEmpty
                      : l10n.savedCollectionPickerNoMatches,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyStyle.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const AppEdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            sliver: SliverList.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final option = filtered[index];
                final isSelected = _selectedIds.contains(option.collectionId);
                final canToggle =
                    !_submitting &&
                    !isPending &&
                    (widget.controller.collectionsExpansionEnabled ||
                        isSelected);
                return _SavedCollectionPickerRow(
                  key: ValueKey('saved-picker-option-${option.collectionId}'),
                  option: option,
                  collection: collectionsById[option.collectionId],
                  selected: isSelected,
                  enabled: canToggle,
                  onTap: canToggle
                      ? () => _toggleCollection(option.collectionId)
                      : null,
                );
              },
            ),
          ),
      ],
    );
  }

  void _toggleCollection(String collectionId) {
    setState(() {
      _actionError = null;
      if (_selectedIds.contains(collectionId)) {
        _selectedIds.remove(collectionId);
      } else {
        _selectedIds.add(collectionId);
      }
    });
  }

  bool _hasChanges(SavedTargetCollectionsSnapshot snapshot) {
    return _creatingInline ||
        !setEquals(_selectedIds, snapshot.effectiveCollectionIds.toSet());
  }

  Future<void> _submit() async {
    final snapshot = _snapshot;
    if (snapshot == null ||
        widget.controller.lifecycleEpoch != _lifecycleEpoch) {
      return;
    }
    final newTitle = _creatingInline
        ? _newCollectionController.text.trim()
        : '';
    if (!widget.controller.collectionsExpansionEnabled &&
        (_creatingInline ||
            _selectedIds.any(
              (collectionId) =>
                  !snapshot.effectiveCollectionIds.contains(collectionId),
            ))) {
      return;
    }
    if (_creatingInline && newTitle.isEmpty) {
      setState(
        () => _actionError = AppLocalizations.of(
          context,
        )!.savedCollectionTitleLabel,
      );
      return;
    }
    if (!_creatingInline &&
        _selectedIds.length == snapshot.effectiveCollectionIds.length &&
        _selectedIds.containsAll(snapshot.effectiveCollectionIds)) {
      Navigator.pop(context, SavedUserActionResult.noOp);
      return;
    }

    setState(() {
      _submitting = true;
      _actionError = null;
    });
    try {
      final result = await widget.controller.replaceTargetCollections(
        current: snapshot,
        desiredCollectionIds: _selectedIds,
        newCollectionTitle: _creatingInline ? newTitle : null,
        sourceSurface: widget.sourceSurface,
      );
      if (!mounted) return;
      if (result == SavedUserActionResult.applied ||
          result == SavedUserActionResult.noOp ||
          result == SavedUserActionResult.pending ||
          result == SavedUserActionResult.superseded) {
        if (result == SavedUserActionResult.superseded &&
            _closingForLifecycle) {
          return;
        }
        Navigator.pop(context, result);
      } else {
        setState(() {
          _actionError = savedActionMessage(
            AppLocalizations.of(context)!,
            result,
          );
        });
      }
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _actionError = savedErrorMessage(AppLocalizations.of(context)!, error);
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _cancelSave() async {
    final snapshot = _snapshot;
    final sourceSurface = widget.sourceSurface;
    final onGlobalUnsave = widget.onGlobalUnsave;
    if (snapshot == null ||
        (sourceSurface == null && onGlobalUnsave == null) ||
        _submitting) {
      return;
    }

    if (snapshot.effectiveCollectionIds.isNotEmpty) {
      final l10n = AppLocalizations.of(context)!;
      final confirmed = await showAppModalDialog<bool>(
        context: context,
        title: l10n.savedRemoveEverywhereTitle,
        child: Text(
          l10n.savedRemoveEverywhereMessage(
            snapshot.effectiveCollectionIds.length,
          ),
        ),
        actions: <AppModalAction<bool>>[
          AppModalAction<bool>(
            label: l10n.cancelButton,
            result: false,
            variant: AppModalActionVariant.ghost,
          ),
          AppModalAction<bool>(
            label: l10n.savedRemoveEverywhereAction,
            icon: Icons.bookmark_remove_rounded,
            result: true,
            variant: AppModalActionVariant.destructive,
          ),
        ],
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() {
      _submitting = true;
      _actionError = null;
    });
    try {
      final result = onGlobalUnsave != null
          ? await onGlobalUnsave()
          : await widget.controller.unsaveBookmark(
              widget.target,
              sourceSurface: sourceSurface!,
            );
      if (!mounted) return;
      if (result == SavedUserActionResult.applied ||
          result == SavedUserActionResult.noOp ||
          result == SavedUserActionResult.pending ||
          result == SavedUserActionResult.superseded) {
        if (result == SavedUserActionResult.superseded &&
            _closingForLifecycle) {
          return;
        }
        Navigator.pop(context, result);
      } else {
        setState(() {
          _actionError = savedActionMessage(
            AppLocalizations.of(context)!,
            result,
          );
        });
      }
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _actionError = savedErrorMessage(AppLocalizations.of(context)!, error);
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _SavedPickerDragHandle extends StatelessWidget {
  const _SavedPickerDragHandle();

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return Padding(
      padding: const AppEdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.xs,
      ),
      child: Center(
        child: SizedBox(
          key: const ValueKey('saved-picker-drag-handle'),
          width: AppSpacing.xxxl,
          height: AppSpacing.xs,
          child: DecoratedBox(
            decoration: AppBoxDecoration(
              color: colors.textMuted.withValues(alpha: 0.72),
              borderRadius: AppRadius.pill,
            ),
          ),
        ),
      ),
    );
  }
}

class _SavedCollectionPickerRow extends StatelessWidget {
  const _SavedCollectionPickerRow({
    super.key,
    required this.option,
    required this.collection,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final SavedCollectionOption option;
  final SavedCollectionRecord? collection;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final l10n = AppLocalizations.of(context)!;
    final cover = collection?.coverPreview;
    final itemCover = cover is CollectionItemCover ? cover : null;
    final subtitle = collection == null
        ? null
        : l10n.savedCollectionItemCount(collection!.activeItemCount);
    final actionTooltip = selected
        ? l10n.savedRemoveFromCollection
        : l10n.savedCollectionPickerTitle;

    return Padding(
      padding: const AppEdgeInsets.only(bottom: AppSpacing.xs),
      child: Semantics(
        button: true,
        enabled: enabled,
        selected: selected,
        label: option.title,
        child: Material(
          color: colors.transparent,
          borderRadius: AppRadius.compactCard,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('saved-picker-option-action-${option.collectionId}'),
            onTap: onTap,
            borderRadius: AppRadius.compactCard,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSizes.avatarLg + (AppSpacing.xs * 2),
              ),
              child: Padding(
                padding: const AppEdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    SavedCoverThumbnail(
                      key: ValueKey(
                        'saved-picker-cover-${option.collectionId}',
                      ),
                      imageUrl: itemCover?.imageUrl,
                      imageKey: ValueKey(
                        'saved-picker-cover-image-${option.collectionId}',
                      ),
                      fallbackIcon: Icons.folder_rounded,
                      selected: selected,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.subtitleStyle.copyWith(
                              color: enabled
                                  ? colors.textPrimary
                                  : colors.textDisabled,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyStyle.copyWith(
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ExcludeSemantics(
                      child: IconButton(
                        tooltip: actionTooltip,
                        onPressed: onTap,
                        style: AppButtonStyles.icon(colors).copyWith(
                          backgroundColor: WidgetStatePropertyAll(
                            selected ? colors.primary : colors.transparent,
                          ),
                          foregroundColor: WidgetStatePropertyAll(
                            selected ? colors.onPrimary : colors.textMuted,
                          ),
                          side: WidgetStatePropertyAll(
                            BorderSide(
                              color: selected ? colors.primary : colors.border,
                            ),
                          ),
                        ),
                        icon: Icon(
                          selected ? Icons.check_rounded : Icons.add_rounded,
                          size: AppSizes.iconMd,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

double _compactPickerHeight(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final availableHeight = math.max(
    AppSpacing.zero,
    mediaQuery.size.height - mediaQuery.viewPadding.top,
  );
  final hasLargeText = MediaQuery.textScalerOf(context).scale(1) > 1.18;
  final preferredRatio = hasLargeText
      ? _largeTextSheetHeightRatio
      : _compactSheetHeightRatio;
  final maxRatio = hasLargeText ? 0.72 : _compactSheetMaxHeightRatio;
  final maxHeight = availableHeight * maxRatio;
  final minHeight = math.min(340.0, maxHeight);
  return (availableHeight * preferredRatio)
      .clamp(minHeight, maxHeight)
      .toDouble();
}

String? _nonEmpty(String? value) {
  final normalized = value?.trim() ?? '';
  return normalized.isEmpty ? null : normalized;
}

String _entityLabel(AppLocalizations l10n, SavedEntityType type) {
  return switch (type) {
    SavedEntityType.activity => l10n.savedCategoryActivities,
    SavedEntityType.attraction => l10n.savedCategoryAttractions,
    SavedEntityType.guide || SavedEntityType.user => l10n.savedCategoryUsers,
    SavedEntityType.post => l10n.savedCategoryPosts,
  };
}

IconData _entityIcon(SavedEntityType type) {
  return switch (type) {
    SavedEntityType.activity => Icons.directions_run_outlined,
    SavedEntityType.guide => Icons.person_pin_circle_outlined,
    SavedEntityType.user => Icons.people_alt_outlined,
    SavedEntityType.attraction => Icons.account_balance_outlined,
    SavedEntityType.post => Icons.article_outlined,
  };
}

List<SavedCollectionOption> _filterOptions(
  Iterable<SavedCollectionOption> options,
  String query,
) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return options.toList(growable: false);
  final queryTokens = normalized.split(RegExp(r'\s+'));
  return options
      .where((option) {
        final title = option.title.toLowerCase();
        final titleTokens = title.split(RegExp(r'\s+'));
        return title == normalized ||
            queryTokens.every(
              (queryToken) => titleTokens.any(
                (titleToken) =>
                    titleToken == queryToken ||
                    titleToken.startsWith(queryToken),
              ),
            );
      })
      .toList(growable: false);
}
