import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/ui/app_design_system.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'saved_collection_actions.dart';
import 'saved_ui_messages.dart';
import 'state/saved_screen_controller.dart';
import 'widgets/saved_app_bar.dart';
import 'widgets/saved_collections_navigation.dart';

const _threeColumnMinWidth = 500.0;
const _fourColumnMinWidth = 760.0;
const _multiColumnMaxTextScale = 1.35;

class SavedCollectionsScreen extends StatefulWidget {
  const SavedCollectionsScreen({super.key});

  @override
  State<SavedCollectionsScreen> createState() => _SavedCollectionsScreenState();
}

class _SavedCollectionsScreenState extends State<SavedCollectionsScreen> {
  SavedScreenController? _controller;
  bool _entryLoadScheduled = false;
  bool _entryLoadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.read<SavedScreenController>();
    if (!identical(controller, _controller)) {
      _controller = controller;
      _entryLoadScheduled = false;
      _entryLoadStarted = false;
      _scheduleEntryLoad(controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SavedScreenController>();
    final colors = AppDesignSystem.colorsFor(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: SavedAppBar(
        title: l10n.savedCollectionsTitle,
        titleKey: const ValueKey('saved-collections-app-bar-title'),
        fallbackRoute: '/profile/saved',
        createButtonKey: const ValueKey(
          'saved-collections-screen-create-collection',
        ),
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
      body: SafeArea(top: false, child: _buildBody(context, controller)),
    );
  }

  Widget _buildBody(BuildContext context, SavedScreenController controller) {
    final l10n = AppLocalizations.of(context)!;
    if (!controller.initialized && controller.initializationError == null) {
      return const _SavedCollectionsSkeleton();
    }
    if (controller.initializationError != null && !controller.initialized) {
      return _SavedCollectionsFullState(
        icon: Icons.cloud_off_outlined,
        title: l10n.savedErrorGeneric,
        message: savedErrorMessage(l10n, controller.initializationError!),
        actionLabel: l10n.retryButton,
        onAction: () => unawaited(controller.initialize(force: true)),
      );
    }
    if (!controller.savedEnabled) {
      return _SavedCollectionsFullState(
        icon: Icons.bookmark_border_rounded,
        title: l10n.savedDisabledTitle,
        message: l10n.savedDisabledMessage,
        actionLabel: l10n.retryButton,
        onAction: () => unawaited(controller.initialize(force: true)),
      );
    }
    if (!controller.collectionsEnabled) {
      return _SavedCollectionsFullState(
        icon: Icons.folder_off_outlined,
        title: l10n.savedCollectionsUnavailableTitle,
        message: l10n.savedCollectionsUnavailableMessage,
      );
    }

    final itemCount = controller.collections.length + 1;
    return RefreshIndicator(
      onRefresh: controller.refreshCollections,
      child: CustomScrollView(
        key: const PageStorageKey('saved-collections-screen-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (controller.collectionsError != null)
            SliverToBoxAdapter(
              child: SavedCollectionsLoadError(
                isRetrying: controller.isRefreshingCollections,
                onRetry: () => unawaited(controller.refreshCollections()),
              ),
            ),
          SliverPadding(
            padding: context.appAdaptive.pagePadding,
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final columnCount = _collectionColumnCount(
                  context,
                  constraints.crossAxisExtent,
                );
                if (columnCount == 1) {
                  return SliverList.builder(
                    itemCount: itemCount,
                    itemBuilder: (context, index) => Padding(
                      padding: const AppEdgeInsets.only(bottom: AppSpacing.sm),
                      child: _buildTile(context, controller, index),
                    ),
                  );
                }
                return SliverGrid.builder(
                  itemCount: itemCount,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columnCount,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.sm,
                    mainAxisExtent: AppSizes.avatarLg + (AppSpacing.xs * 2),
                  ),
                  itemBuilder: (context, index) =>
                      _buildTile(context, controller, index),
                );
              },
            ),
          ),
          if (controller.collections.isEmpty)
            SliverToBoxAdapter(
              child: _SavedCollectionsEmptyHint(
                title: l10n.savedCollectionsEmptyTitle,
                message: l10n.savedCollectionsEmptyMessage,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    SavedScreenController controller,
    int index,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (index == 0) {
      return SavedCollectionTile(
        key: const ValueKey('saved-collections-screen-all'),
        selected: controller.currentViewId.isAll,
        title: l10n.savedAllItems,
        subtitle: null,
        allItems: true,
        onTap: () => _openSavedView(controller, const SavedViewId.all()),
      );
    }
    final collection = controller.collections[index - 1];
    return SavedCollectionTile(
      key: ValueKey('saved-collections-screen-${collection.collectionId}'),
      selected:
          controller.currentViewId.collectionId == collection.collectionId,
      title: collection.title,
      subtitle: l10n.savedCollectionItemCount(collection.activeItemCount),
      coverPreview: collection.coverPreview,
      onTap: () => _openSavedView(
        controller,
        SavedViewId.collection(collection.collectionId),
      ),
    );
  }

  void _openSavedView(SavedScreenController controller, SavedViewId viewId) {
    unawaited(controller.selectView(viewId));
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile/saved');
    }
  }

  void _scheduleEntryLoad(SavedScreenController controller) {
    if (_entryLoadScheduled || _entryLoadStarted) return;
    _entryLoadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entryLoadScheduled = false;
      if (!mounted ||
          _entryLoadStarted ||
          !identical(controller, _controller)) {
        return;
      }
      _entryLoadStarted = true;
      unawaited(_loadOnEntry(controller));
    });
  }

  Future<void> _loadOnEntry(SavedScreenController controller) async {
    if (!controller.initialized) {
      await controller.initialize(
        force: controller.initializationError != null,
      );
      return;
    }
    if (controller.savedEnabled) {
      await controller.refreshCollections(silent: true);
    }
  }
}

int _collectionColumnCount(BuildContext context, double width) {
  final baseFontSize =
      Theme.of(context).textTheme.bodyMedium?.fontSize ?? AppTypography.body;
  final textScale =
      MediaQuery.textScalerOf(context).scale(baseFontSize) / baseFontSize;
  if (width < 300 || textScale > _multiColumnMaxTextScale) return 1;
  if (width >= _fourColumnMinWidth) return 4;
  if (width >= _threeColumnMinWidth) return 3;
  return 2;
}

class _SavedCollectionsEmptyHint extends StatelessWidget {
  const _SavedCollectionsEmptyHint({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return Padding(
      padding: const AppEdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Semantics(
        container: true,
        child: Column(
          children: [
            Icon(
              Icons.create_new_folder_outlined,
              color: colors.textMuted,
              size: AppSizes.avatarMd,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedCollectionsFullState extends StatelessWidget {
  const _SavedCollectionsFullState({
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
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: context.appAdaptive.pagePadding,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: AppSizes.avatarMd, color: colors.textMuted),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
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
      ),
    );
  }
}

class _SavedCollectionsSkeleton extends StatelessWidget {
  const _SavedCollectionsSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return CustomScrollView(
      key: const ValueKey('saved-collections-screen-loading'),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: context.appAdaptive.pagePadding,
          sliver: SliverGrid.builder(
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.sm,
              mainAxisExtent: AppSizes.avatarLg + (AppSpacing.xs * 2),
            ),
            itemBuilder: (context, index) => DecoratedBox(
              decoration: AppBoxDecoration(
                color: colors.surfaceHigh,
                borderRadius: AppRadius.compactCard,
                border: Border.all(color: colors.borderSoft),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
