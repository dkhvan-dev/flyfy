import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/ui/app_design_system.dart';
import '../../../core/ui/app_list_search_field.dart';
import '../../../core/ui/app_modal_templates.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/saved_browse_models.dart';
import '../domain/saved_operation.dart';
import '../domain/saved_target.dart';
import 'saved_collection_actions.dart';
import 'saved_ui_messages.dart';
import 'state/saved_screen_controller.dart';
import 'widgets/saved_app_bar.dart';
import 'widgets/saved_collection_picker.dart';
import 'widgets/saved_collections_navigation.dart';
import 'widgets/saved_item_card.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Set<SavedTarget> _loadingAssignments = <SavedTarget>{};
  SavedScreenController? _controller;
  SavedViewId? _boundViewId;
  bool _syncingSearch = false;
  bool _viewBindingScheduled = false;
  bool _initializationScheduled = false;
  bool _entrySynchronizationScheduled = false;
  bool _entrySynchronizationStarted = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.read<SavedScreenController>();
    if (!identical(controller, _controller)) {
      _controller = controller;
      _entrySynchronizationStarted = false;
      _scheduleEntrySynchronization(controller);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _searchController.removeListener(_handleSearchChanged);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SavedScreenController>();
    final colors = AppDesignSystem.colorsFor(context);
    final l10n = AppLocalizations.of(context)!;
    _scheduleInitialization(controller);
    _scheduleViewBinding(controller);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: SavedAppBar(
        title: l10n.savedScreenTitle,
        titleKey: const ValueKey('saved-screen-app-bar-title'),
        fallbackRoute: '/profile',
        createButtonKey: const ValueKey('saved-create-collection-app-bar'),
        isCreating: controller.isCreatingCollection,
        onCreate: controller.collectionsExpansionEnabled
            ? () => unawaited(
                createSavedCollectionFromUi(
                  context: context,
                  controller: controller,
                ),
              )
            : null,
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenClass = AppBreakpoints.classify(constraints.maxWidth);
            if (screenClass == AppScreenClass.expanded &&
                controller.initialized &&
                controller.savedEnabled &&
                controller.collectionsEnabled) {
              return Row(
                children: [
                  SizedBox(
                    width: 300,
                    child: SavedCollectionsNavigation(
                      collections: controller.collections,
                      selectedCollectionId:
                          controller.currentViewId.collectionId,
                      expanded: true,
                      isRefreshing: controller.isRefreshingCollections,
                      hasError: controller.collectionsError != null,
                      onAllTap: () => unawaited(
                        controller.selectView(const SavedViewId.all()),
                      ),
                      onCollectionTap: (collection) => unawaited(
                        controller.selectView(
                          SavedViewId.collection(collection.collectionId),
                        ),
                      ),
                      onRetry: () => unawaited(controller.refreshCollections()),
                    ),
                  ),
                  VerticalDivider(width: 1, color: colors.borderSoft),
                  Expanded(
                    child: _buildScreenBody(
                      context,
                      controller,
                      includeCompactCollections: false,
                      screenClass: screenClass,
                    ),
                  ),
                ],
              );
            }
            return _buildScreenBody(
              context,
              controller,
              includeCompactCollections: controller.collectionsEnabled,
              screenClass: screenClass,
            );
          },
        ),
      ),
    );
  }

  Widget _buildScreenBody(
    BuildContext context,
    SavedScreenController controller, {
    required bool includeCompactCollections,
    required AppScreenClass screenClass,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    if (!controller.initialized && controller.initializationError == null) {
      return const _SavedInitialSkeleton();
    }
    if (controller.initializationError != null && !controller.initialized) {
      return _SavedFullState(
        icon: Icons.cloud_off_outlined,
        title: l10n.savedErrorGeneric,
        message: savedErrorMessage(l10n, controller.initializationError!),
        actionLabel: l10n.retryButton,
        onAction: () => unawaited(controller.initialize(force: true)),
      );
    }
    if (controller.initialized && !controller.savedEnabled) {
      return _SavedFullState(
        icon: Icons.bookmark_border_rounded,
        title: l10n.savedDisabledTitle,
        message: l10n.savedDisabledMessage,
        actionLabel: l10n.retryButton,
        onAction: () => unawaited(controller.initialize(force: true)),
      );
    }

    final view = controller.currentView;
    return RefreshIndicator(
      onRefresh: controller.refreshCurrent,
      child: CustomScrollView(
        key: ValueKey(
          'saved-scroll-${controller.currentViewId.collectionId ?? 'all'}',
        ),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          if (includeCompactCollections)
            SliverToBoxAdapter(
              child: SavedCollectionsNavigation(
                collections: controller.collections,
                selectedCollectionId: controller.currentViewId.collectionId,
                expanded: false,
                isRefreshing: controller.isRefreshingCollections,
                hasError: controller.collectionsError != null,
                onAllTap: () =>
                    unawaited(controller.selectView(const SavedViewId.all())),
                onCollectionTap: (collection) => unawaited(
                  controller.selectView(
                    SavedViewId.collection(collection.collectionId),
                  ),
                ),
                onRetry: () => unawaited(controller.refreshCollections()),
                onSeeAllTap: () => context.push('/profile/saved/collections'),
              ),
            ),
          SliverToBoxAdapter(
            child: _SavedViewHeader(
              collection: controller.currentCollection,
              allTitle: l10n.savedAllItems,
              isCollectionPending: controller.currentCollection == null
                  ? false
                  : controller.isCollectionPending(
                      controller.currentCollection!.collectionId,
                    ),
              onRename: controller.currentCollection == null
                  ? null
                  : () => unawaited(
                      _renameCollection(
                        controller,
                        controller.currentCollection!,
                      ),
                    ),
              onDelete: controller.currentCollection == null
                  ? null
                  : () => unawaited(
                      _deleteCollection(
                        controller,
                        controller.currentCollection!,
                      ),
                    ),
            ),
          ),
          if (view.isStale)
            SliverToBoxAdapter(
              child: _SavedNetworkBanner(
                message: l10n.savedNetworkStale,
                retryLabel: l10n.retryButton,
                onRetry: () => unawaited(controller.retryCurrent()),
              ),
            ),
          if (controller.searchEnabled)
            SliverToBoxAdapter(
              child: Padding(
                padding: _contentPadding(
                  context,
                ).copyWith(top: AppSpacing.sm, bottom: AppSpacing.sm),
                child: AppListSearchField(
                  controller: _searchController,
                  hintText: l10n.savedSearchHint,
                  showFilterButton: false,
                  showClearButton: true,
                  onClear: _searchController.clear,
                  onSubmitted: (_) => unawaited(controller.submitSearch()),
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  textFieldKey: const ValueKey('saved-search-field'),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: _SavedCategorySelector(
              categories: controller.availableCategories,
              selected: view.selectedType,
              onSelected: (type) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(0);
                }
                unawaited(controller.selectCategory(type));
              },
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 3,
              child: view.isRefreshing
                  ? LinearProgressIndicator(
                      key: const ValueKey('saved-refreshing-indicator'),
                      color: colors.primary,
                      backgroundColor: colors.transparent,
                    )
                  : const SizedBox.expand(),
            ),
          ),
          if (view.loadState == SavedViewLoadState.loading &&
              view.items.isEmpty)
            const _SavedCardSkeletonSliver()
          else if (view.loadState == SavedViewLoadState.error &&
              view.items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _SavedFullState(
                icon: Icons.cloud_off_outlined,
                title: l10n.savedErrorGeneric,
                message: savedErrorMessage(l10n, view.error!),
                actionLabel: l10n.retryButton,
                onAction: () => unawaited(controller.retryCurrent()),
              ),
            )
          else if (view.items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _SavedEmptyState(
                view: view,
                inCollection: !controller.currentViewId.isAll,
                onGoAll: () =>
                    unawaited(controller.selectView(const SavedViewId.all())),
              ),
            )
          else
            _buildItemsSliver(context, controller, screenClass),
          if (view.items.isNotEmpty)
            SliverToBoxAdapter(
              child: _SavedPaginationFooter(
                isLoading: view.isLoadingMore,
                blocked: view.paginationBlocked,
                label: l10n.savedPaginationRetry,
                retryLabel: l10n.retryButton,
                onRetry: () => unawaited(controller.retryCurrent()),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }

  Widget _buildItemsSliver(
    BuildContext context,
    SavedScreenController controller,
    AppScreenClass screenClass,
  ) {
    final items = controller.currentView.items;
    final horizontalPadding = _contentPadding(context).horizontal / 2;
    final crossAxisCount = switch (screenClass) {
      AppScreenClass.compact => 1,
      AppScreenClass.medium => 2,
      AppScreenClass.expanded => 2,
    };
    final rowCount = (items.length / crossAxisCount).ceil();
    return SliverPadding(
      padding: AppEdgeInsets.fromLTRB(
        horizontalPadding,
        AppSpacing.sm,
        horizontalPadding,
        AppSpacing.lg,
      ),
      sliver: SliverList.builder(
        itemCount: rowCount,
        itemBuilder: (context, rowIndex) {
          final start = rowIndex * crossAxisCount;
          return Padding(
            padding: AppEdgeInsets.only(
              bottom: rowIndex == rowCount - 1
                  ? AppSpacing.zero
                  : AppSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var column = 0; column < crossAxisCount; column++) ...[
                  if (column > 0) const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: start + column < items.length
                        ? _buildItemCard(
                            context,
                            controller,
                            items[start + column],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    SavedScreenController controller,
    SavedListItem item,
  ) {
    final localAssignmentLoading = _loadingAssignments.contains(item.target);
    final projection = item.projection;
    return SavedItemCard(
      key: ValueKey(
        'saved-card-${item.target.entityType.wireValue}-${item.target.entityId}',
      ),
      item: item,
      isPending: controller.isTargetPending(item.target),
      isAssignmentPending:
          localAssignmentLoading || controller.isAssignmentPending(item.target),
      isAssignmentLoading:
          localAssignmentLoading ||
          controller.isAssignmentRequestInFlight(item.target),
      inCollection: !controller.currentViewId.isAll,
      onManageSavedItem: () => unawaited(_manageCollections(controller, item)),
      onRemoveFromCollection: controller.currentViewId.isAll
          ? null
          : () => unawaited(_removeFromCurrentCollection(controller, item)),
      onOpen: projection is AvailableSavedCardProjection
          ? () => unawaited(context.push(projection.canonicalDetailRoute))
          : null,
    );
  }

  Future<void> _manageCollections(
    SavedScreenController controller,
    SavedListItem item,
  ) async {
    if (_loadingAssignments.contains(item.target)) return;
    final lifecycleEpoch = controller.lifecycleEpoch;
    setState(() => _loadingAssignments.add(item.target));
    try {
      var removedEverywhere = false;
      final projection = item.projection;
      final availableProjection = projection is AvailableSavedCardProjection
          ? projection
          : null;
      final result = await showSavedCollectionPicker(
        context: context,
        controller: controller,
        target: item.target,
        allowGlobalUnsave: true,
        onGlobalUnsave: () async {
          final result = await controller.globallyUnsave(item);
          if (result == SavedUserActionResult.applied ||
              result == SavedUserActionResult.noOp) {
            removedEverywhere = true;
          }
          return result;
        },
        previewTitle: availableProjection?.title,
        previewSubtitle: availableProjection?.subtitle,
        previewImageUrl: availableProjection?.imageUrl?.toString(),
      );
      if (!mounted ||
          controller.lifecycleEpoch != lifecycleEpoch ||
          result == null) {
        return;
      }
      if (result == SavedUserActionResult.applied && !removedEverywhere) {
        _showMessage(AppLocalizations.of(context)!.savedAssignmentsUpdated);
      } else if (result != SavedUserActionResult.noOp && !removedEverywhere) {
        _showMessage(savedActionMessage(AppLocalizations.of(context)!, result));
      }
    } finally {
      if (mounted) setState(() => _loadingAssignments.remove(item.target));
    }
  }

  Future<void> _removeFromCurrentCollection(
    SavedScreenController controller,
    SavedListItem item,
  ) async {
    if (_loadingAssignments.contains(item.target)) return;
    final lifecycleEpoch = controller.lifecycleEpoch;
    setState(() => _loadingAssignments.add(item.target));
    try {
      final snapshot = await controller.loadTargetCollections(item.target);
      if (!mounted || controller.lifecycleEpoch != lifecycleEpoch) return;
      final result = await controller.removeFromCurrentCollection(snapshot);
      if (!mounted || controller.lifecycleEpoch != lifecycleEpoch) return;
      if (result == SavedUserActionResult.applied ||
          result == SavedUserActionResult.noOp) {
        _showMessage(AppLocalizations.of(context)!.savedAssignmentsUpdated);
      } else {
        _showMessage(savedActionMessage(AppLocalizations.of(context)!, result));
      }
    } on Object catch (error) {
      if (!mounted || controller.lifecycleEpoch != lifecycleEpoch) return;
      _showMessage(savedErrorMessage(AppLocalizations.of(context)!, error));
    } finally {
      if (mounted) setState(() => _loadingAssignments.remove(item.target));
    }
  }

  Future<void> _renameCollection(
    SavedScreenController controller,
    SavedCollectionRecord collection,
  ) async {
    final lifecycleEpoch = controller.lifecycleEpoch;
    final title = await showSavedCollectionTitleEditor(
      context: context,
      title: AppLocalizations.of(context)!.savedCollectionRenameTitle,
      initialValue: collection.title,
      lifecycleEpoch: lifecycleEpoch,
    );
    if (title == null ||
        title.trim() == collection.title ||
        !mounted ||
        controller.lifecycleEpoch != lifecycleEpoch) {
      return;
    }
    try {
      final result = await controller.renameCollection(collection, title);
      if (!mounted || controller.lifecycleEpoch != lifecycleEpoch) return;
      if (result == SavedUserActionResult.applied ||
          result == SavedUserActionResult.noOp) {
        _showMessage(AppLocalizations.of(context)!.savedCollectionRenamed);
      } else {
        _showMessage(savedActionMessage(AppLocalizations.of(context)!, result));
      }
    } on Object catch (error) {
      if (!mounted || controller.lifecycleEpoch != lifecycleEpoch) return;
      _showMessage(savedErrorMessage(AppLocalizations.of(context)!, error));
    }
  }

  Future<void> _deleteCollection(
    SavedScreenController controller,
    SavedCollectionRecord collection,
  ) async {
    final lifecycleEpoch = controller.lifecycleEpoch;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAppModalDialog<bool>(
      context: context,
      builder: (modalContext) => _SavedLifecycleBoundary(
        controller: controller,
        lifecycleEpoch: lifecycleEpoch,
        child: SingleChildScrollView(
          child: AppModalDialogCard(
            title: Text(l10n.savedCollectionDeleteTitle),
            content: Text(l10n.savedCollectionDeleteMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(modalContext).pop(false),
                child: Text(l10n.cancelButton),
              ),
              FilledButton.icon(
                key: const ValueKey('saved-confirm-delete-collection'),
                onPressed: () => Navigator.of(modalContext).pop(true),
                style: AppButtonStyles.destructive(),
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(l10n.savedCollectionDeleteAction),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true ||
        !mounted ||
        controller.lifecycleEpoch != lifecycleEpoch) {
      return;
    }
    try {
      final result = await controller.deleteCollection(collection);
      if (!mounted || controller.lifecycleEpoch != lifecycleEpoch) return;
      if (result == SavedUserActionResult.applied ||
          result == SavedUserActionResult.noOp) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.savedCollectionDeleted),
            action: SnackBarAction(
              label: l10n.savedCollectionGoAll,
              onPressed: () =>
                  unawaited(controller.selectView(const SavedViewId.all())),
            ),
          ),
        );
      } else {
        _showMessage(savedActionMessage(l10n, result));
      }
    } on Object catch (error) {
      if (!mounted || controller.lifecycleEpoch != lifecycleEpoch) return;
      _showMessage(savedErrorMessage(l10n, error));
    }
  }

  void _showMessage(String message) {
    if (message.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleScroll() {
    final controller = _controller;
    if (controller == null || !_scrollController.hasClients) return;
    controller.rememberScrollOffset(_scrollController.offset);
    if (_scrollController.position.extentAfter < 600) {
      unawaited(controller.loadMore());
    }
  }

  void _handleSearchChanged() {
    if (_syncingSearch) return;
    final controller = _controller;
    if (controller == null) return;
    final value = _searchController.text;
    if (value.runes.length > 200) {
      final truncated = String.fromCharCodes(value.runes.take(200));
      _syncingSearch = true;
      _searchController.value = TextEditingValue(
        text: truncated,
        selection: TextSelection.collapsed(offset: truncated.length),
      );
      _syncingSearch = false;
      controller.updateSearch(truncated);
      return;
    }
    controller.updateSearch(value);
  }

  void _scheduleViewBinding(SavedScreenController controller) {
    if (_boundViewId == controller.currentViewId || _viewBindingScheduled) {
      return;
    }
    _viewBindingScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewBindingScheduled = false;
      if (!mounted) return;
      final view = controller.currentView;
      _boundViewId = controller.currentViewId;
      if (_searchController.text != view.query) {
        _syncingSearch = true;
        _searchController.value = TextEditingValue(
          text: view.query,
          selection: TextSelection.collapsed(offset: view.query.length),
        );
        _syncingSearch = false;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        final target = view.scrollOffset.clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );
        _scrollController.jumpTo(target);
      });
    });
  }

  void _scheduleInitialization(SavedScreenController controller) {
    if (_initializationScheduled ||
        controller.initialized ||
        controller.isInitializing ||
        controller.initializationError != null) {
      return;
    }
    _initializationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializationScheduled = false;
      if (!mounted ||
          controller.initialized ||
          controller.isInitializing ||
          controller.initializationError != null) {
        return;
      }
      unawaited(controller.initialize());
    });
  }

  void _scheduleEntrySynchronization(SavedScreenController controller) {
    if (_entrySynchronizationScheduled || _entrySynchronizationStarted) {
      return;
    }
    _entrySynchronizationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entrySynchronizationScheduled = false;
      if (!mounted ||
          _entrySynchronizationStarted ||
          !identical(controller, _controller)) {
        return;
      }
      _entrySynchronizationStarted = true;
      unawaited(controller.synchronizeOnScreenEntry());
    });
  }
}

AppEdgeInsets _contentPadding(BuildContext context) {
  final adaptive = AppAdaptive.of(context);
  return switch (adaptive.screenClass) {
    AppScreenClass.compact => AppEdgeInsets.symmetric(
      horizontal: adaptive.isNarrow ? AppSpacing.md : AppSpacing.lg,
    ),
    AppScreenClass.medium => const AppEdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
    ),
    AppScreenClass.expanded => const AppEdgeInsets.symmetric(
      horizontal: AppSpacing.xxl,
    ),
  };
}

enum _CollectionMenuAction { rename, delete }

class _SavedLifecycleBoundary extends StatefulWidget {
  const _SavedLifecycleBoundary({
    required this.controller,
    required this.lifecycleEpoch,
    required this.child,
  });

  final SavedScreenController controller;
  final int lifecycleEpoch;
  final Widget child;

  @override
  State<_SavedLifecycleBoundary> createState() =>
      _SavedLifecycleBoundaryState();
}

class _SavedLifecycleBoundaryState extends State<_SavedLifecycleBoundary> {
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
    _handleControllerChanged();
  }

  @override
  void didUpdateWidget(covariant _SavedLifecycleBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
    }
    _handleControllerChanged();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    if (_closing || widget.controller.lifecycleEpoch == widget.lifecycleEpoch) {
      return;
    }
    _closing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = mounted ? ModalRoute.of(context) : null;
      if (route?.isCurrent == true) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _SavedViewHeader extends StatelessWidget {
  const _SavedViewHeader({
    required this.collection,
    required this.allTitle,
    required this.isCollectionPending,
    required this.onRename,
    required this.onDelete,
  });

  final SavedCollectionRecord? collection;
  final String allTitle;
  final bool isCollectionPending;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: _contentPadding(
        context,
      ).copyWith(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collection?.title ?? allTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                if (collection != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.savedCollectionItemCount(collection!.activeItemCount),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textMuted,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (collection != null)
            isCollectionPending
                ? const Padding(
                    padding: AppInsets.allSm,
                    child: SizedBox.square(
                      dimension: AppSizes.iconMd,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : PopupMenuButton<_CollectionMenuAction>(
                    tooltip: l10n.savedCollectionMenuTooltip,
                    onSelected: (action) {
                      switch (action) {
                        case _CollectionMenuAction.rename:
                          onRename?.call();
                        case _CollectionMenuAction.delete:
                          onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: _CollectionMenuAction.rename,
                        child: ListTile(
                          contentPadding: AppInsets.none,
                          leading: const Icon(Icons.edit_outlined),
                          title: Text(l10n.savedCollectionRenameAction),
                        ),
                      ),
                      PopupMenuItem(
                        value: _CollectionMenuAction.delete,
                        child: ListTile(
                          contentPadding: AppInsets.none,
                          leading: Icon(
                            Icons.delete_outline_rounded,
                            color: colors.danger,
                          ),
                          title: Text(
                            l10n.savedCollectionDeleteAction,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: colors.danger,
                                  letterSpacing: 0,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
        ],
      ),
    );
  }
}

class _SavedCategorySelector extends StatelessWidget {
  const _SavedCategorySelector({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<SavedEntityType> categories;
  final SavedEntityType? selected;
  final ValueChanged<SavedEntityType?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final segments = <ButtonSegment<SavedEntityType?>>[
      ButtonSegment<SavedEntityType?>(
        value: null,
        icon: const Icon(Icons.apps_rounded),
        label: Text(l10n.savedCategoryAll),
      ),
      for (final category in categories)
        ButtonSegment<SavedEntityType?>(
          value: category,
          icon: Icon(_categoryIcon(category)),
          label: Text(_categoryLabel(l10n, category)),
        ),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: _contentPadding(
        context,
      ).copyWith(top: AppSpacing.sm, bottom: AppSpacing.md),
      child: SegmentedButton<SavedEntityType?>(
        segments: segments,
        selected: <SavedEntityType?>{selected},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => onSelected(selection.single),
      ),
    );
  }
}

IconData _categoryIcon(SavedEntityType type) {
  return switch (type) {
    SavedEntityType.activity => Icons.directions_run_outlined,
    SavedEntityType.guide => Icons.person_pin_circle_outlined,
    SavedEntityType.user => Icons.people_alt_outlined,
    SavedEntityType.attraction => Icons.account_balance_outlined,
    SavedEntityType.post => Icons.article_outlined,
  };
}

String _categoryLabel(AppLocalizations l10n, SavedEntityType type) {
  return switch (type) {
    SavedEntityType.activity => l10n.savedCategoryActivities,
    SavedEntityType.guide => l10n.savedCategoryUsers,
    SavedEntityType.user => l10n.savedCategoryUsers,
    SavedEntityType.attraction => l10n.savedCategoryAttractions,
    SavedEntityType.post => l10n.savedCategoryPosts,
  };
}

class _SavedNetworkBanner extends StatelessWidget {
  const _SavedNetworkBanner({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return Padding(
      padding: _contentPadding(context).copyWith(top: AppSpacing.sm),
      child: Material(
        color: colors.surfaceWarm,
        borderRadius: AppRadius.compactCard,
        child: Padding(
          padding: AppInsets.listItem,
          child: Row(
            children: [
              Icon(Icons.cloud_off_outlined, color: colors.warning),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                    letterSpacing: 0,
                  ),
                ),
              ),
              TextButton(onPressed: onRetry, child: Text(retryLabel)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedPaginationFooter extends StatelessWidget {
  const _SavedPaginationFooter({
    required this.isLoading,
    required this.blocked,
    required this.label,
    required this.retryLabel,
    required this.onRetry,
  });

  final bool isLoading;
  final bool blocked;
  final String label;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: AppInsets.panel,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!blocked) return const SizedBox.shrink();
    return Padding(
      padding: AppInsets.panel,
      child: Column(
        children: [
          Text(label, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}

class _SavedEmptyState extends StatelessWidget {
  const _SavedEmptyState({
    required this.view,
    required this.inCollection,
    required this.onGoAll,
  });

  final SavedViewState view;
  final bool inCollection;
  final VoidCallback onGoAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (title, message) = view.isSearching
        ? (l10n.savedEmptySearchTitle, l10n.savedEmptySearchMessage)
        : view.selectedType != null
        ? (l10n.savedEmptyCategoryTitle, l10n.savedEmptyCategoryMessage)
        : inCollection
        ? (l10n.savedEmptyCollectionTitle, l10n.savedEmptyCollectionMessage)
        : (l10n.savedEmptyAllTitle, l10n.savedEmptyAllMessage);
    final showGoAll =
        inCollection && !view.isSearching && view.selectedType == null;
    return _SavedFullState(
      icon: view.isSearching
          ? Icons.search_off_rounded
          : Icons.bookmark_border_rounded,
      title: title,
      message: message,
      actionLabel: showGoAll ? l10n.savedCollectionGoAll : null,
      onAction: showGoAll ? onGoAll : null,
    );
  }
}

class _SavedFullState extends StatelessWidget {
  const _SavedFullState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return Center(
      child: SingleChildScrollView(
        padding: AppInsets.panel,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: colors.primary, size: 56),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  letterSpacing: 0,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: onAction,
                  style: AppButtonStyles.primary(colors),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedInitialSkeleton extends StatelessWidget {
  const _SavedInitialSkeleton();

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      key: ValueKey('saved-initial-loading'),
      physics: NeverScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: AppInsets.panel,
            child: _SkeletonBox(height: 58),
          ),
        ),
        _SavedCardSkeletonSliver(),
      ],
    );
  }
}

class _SavedCardSkeletonSliver extends StatelessWidget {
  const _SavedCardSkeletonSliver();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= AppBreakpoints.compact ? 2 : 1;
    return SliverPadding(
      padding: AppInsets.panel,
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: columns == 1 ? 0.78 : 0.72,
        ),
        itemCount: columns * 3,
        itemBuilder: (_, _) => const _SkeletonBox(),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return Container(
      height: height,
      decoration: AppBoxDecoration(
        color: colors.surfaceHigh,
        borderRadius: AppRadius.compactCard,
        border: Border.all(color: colors.borderSoft),
      ),
    );
  }
}
