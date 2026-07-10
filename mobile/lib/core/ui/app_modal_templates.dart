import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

enum AppModalActionVariant { primary, secondary, ghost, destructive }

class AppModalAction<T> {
  const AppModalAction({
    required this.label,
    this.icon,
    this.result,
    this.onPressed,
    this.variant = AppModalActionVariant.secondary,
    this.dismissesModal = true,
    this.enabled = true,
  });

  final String label;
  final IconData? icon;
  final T? result;
  final VoidCallback? onPressed;
  final AppModalActionVariant variant;
  final bool dismissesModal;
  final bool enabled;
}

class AppActionSheetItem<T> {
  const AppActionSheetItem({
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.destructive = false,
    this.enabled = true,
  });

  final String label;
  final T value;
  final String? subtitle;
  final IconData? icon;
  final bool destructive;
  final bool enabled;
}

class AppModalScaffold<T> extends StatelessWidget {
  const AppModalScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.actions = const [],
    this.scrollController,
    this.showDragHandle = false,
    this.showCloseButton = true,
    this.scrollable = true,
    this.contentPadding = AppInsets.panel,
    this.maxWidth = 440,
    this.surfaceBorderRadius = AppRadius.panel,
    this.bottomSafeAreaPadding = 0,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;
  final List<AppModalAction<T>> actions;
  final ScrollController? scrollController;
  final bool showDragHandle;
  final bool showCloseButton;
  final bool scrollable;
  final AppEdgeInsets contentPadding;
  final double maxWidth;
  final BorderRadiusGeometry surfaceBorderRadius;
  final double bottomSafeAreaPadding;

  @override
  Widget build(BuildContext context) {
    final adaptive = context.appAdaptive;
    final colors = AppDesignSystem.colorsFor(context);
    final titleStyle = AppTypography.titleLargeStyle.copyWith(
      color: colors.textPrimary,
      fontSize: adaptive.isNarrow ? 18 : 20,
      height: 1.16,
    );
    final subtitleStyle = AppTypography.bodyStyle.copyWith(
      color: colors.textSecondary,
      fontSize: 13,
      height: 1.42,
    );
    final effectiveContentPadding = actions.isEmpty && bottomSafeAreaPadding > 0
        ? contentPadding.copyWith(
            bottom: contentPadding.bottom + bottomSafeAreaPadding,
          )
        : contentPadding;
    final actionsBottomPadding = AppSpacing.xl + bottomSafeAreaPadding;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Material(
        color: colors.transparent,
        child: ClipRRect(
          borderRadius: surfaceBorderRadius,
          child: DecoratedBox(
            decoration: _modalSurfaceDecoration(
              context,
              colors,
              borderRadius: surfaceBorderRadius,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showDragHandle) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _AppModalDragHandle(),
                ],
                Padding(
                  padding: AppEdgeInsets.fromLTRB(
                    adaptive.isNarrow ? AppSpacing.lg : AppSpacing.xl,
                    showDragHandle ? AppSpacing.md : AppSpacing.xl,
                    adaptive.isNarrow ? AppSpacing.lg : AppSpacing.xl,
                    AppSpacing.md,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (icon != null) ...[
                        _AppModalIcon(icon: icon!),
                        const SizedBox(width: AppSpacing.md),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: titleStyle,
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                subtitle!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: subtitleStyle,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (showCloseButton) ...[
                        const SizedBox(width: AppSpacing.sm),
                        IconButton(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ],
                  ),
                ),
                if (scrollable)
                  Flexible(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: effectiveContentPadding,
                      child: child,
                    ),
                  )
                else
                  Padding(padding: effectiveContentPadding, child: child),
                if (actions.isNotEmpty)
                  Padding(
                    padding: AppEdgeInsets.fromLTRB(
                      adaptive.isNarrow ? AppSpacing.lg : AppSpacing.xl,
                      AppSpacing.sm,
                      adaptive.isNarrow ? AppSpacing.lg : AppSpacing.xl,
                      actionsBottomPadding,
                    ),
                    child: _AppModalActions<T>(actions: actions),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppModalDialogCard extends StatelessWidget {
  const AppModalDialogCard({
    super.key,
    this.icon,
    this.title,
    this.content,
    this.actions = const [],
    this.backgroundColor,
    this.surfaceTintColor,
    this.shape,
    this.titleTextStyle,
    this.contentTextStyle,
    this.actionsPadding,
  });

  final Widget? icon;
  final Widget? title;
  final Widget? content;
  final List<Widget> actions;
  final Color? backgroundColor;
  final Color? surfaceTintColor;
  final ShapeBorder? shape;
  final TextStyle? titleTextStyle;
  final TextStyle? contentTextStyle;
  final EdgeInsetsGeometry? actionsPadding;

  @override
  Widget build(BuildContext context) {
    final adaptive = context.appAdaptive;
    final colors = AppDesignSystem.colorsFor(context);
    final horizontalPadding = adaptive.isNarrow ? AppSpacing.lg : AppSpacing.xl;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Material(
        color: colors.transparent,
        child: ClipRRect(
          borderRadius: AppRadius.panel,
          child: DecoratedBox(
            decoration: backgroundColor == null
                ? _modalSurfaceDecoration(context, colors)
                : _modalSurfaceDecoration(
                    context,
                    colors,
                    backgroundColor: backgroundColor,
                  ),
            child: Padding(
              padding: AppEdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.xl,
                horizontalPadding,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (icon != null) ...[
                    Center(child: icon),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (title != null)
                    DefaultTextStyle.merge(
                      textAlign: TextAlign.start,
                      style: AppTypography.titleLargeStyle
                          .copyWith(
                            color: colors.textPrimary,
                            fontSize: adaptive.isNarrow ? 18 : 20,
                            height: 1.16,
                          )
                          .merge(titleTextStyle),
                      child: title!,
                    ),
                  if (content != null) ...[
                    if (title != null) const SizedBox(height: AppSpacing.md),
                    DefaultTextStyle.merge(
                      style: AppTypography.bodyStyle
                          .copyWith(
                            color: colors.textSecondary,
                            fontSize: 13,
                            height: 1.42,
                          )
                          .merge(contentTextStyle),
                      child: content!,
                    ),
                  ],
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Padding(
                      padding: actionsPadding ?? AppInsets.none,
                      child: Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.md,
                        alignment: WrapAlignment.end,
                        children: actions,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppModalSheetFrame extends StatelessWidget {
  const AppModalSheetFrame({
    super.key,
    required this.child,
    this.alignment = Alignment.bottomCenter,
    this.useSafeArea = true,
    this.safeAreaTop = false,
    this.safeAreaBottom = false,
    this.onTapOutside,
  });

  final Widget child;
  final AlignmentGeometry alignment;
  final bool useSafeArea;
  final bool safeAreaTop;
  final bool safeAreaBottom;
  final VoidCallback? onTapOutside;

  @override
  Widget build(BuildContext context) {
    final alignedChild = Align(alignment: alignment, child: child);
    final content = onTapOutside == null
        ? SizedBox(width: double.infinity, child: alignedChild)
        : SizedBox(
            width: double.infinity,
            height: MediaQuery.sizeOf(context).height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTapOutside,
                    child: const SizedBox.expand(),
                  ),
                ),
                alignedChild,
              ],
            ),
          );

    if (!useSafeArea) return content;

    return SafeArea(top: safeAreaTop, bottom: safeAreaBottom, child: content);
  }
}

BoxConstraints _fullWidthBottomSheetConstraints(
  BuildContext context,
  BoxConstraints? constraints,
) {
  final viewportWidth = MediaQuery.sizeOf(context).width;
  return (constraints ?? const BoxConstraints()).copyWith(
    minWidth: viewportWidth,
    maxWidth: viewportWidth,
  );
}

class AppModalDraggableSheet extends StatelessWidget {
  const AppModalDraggableSheet({
    super.key,
    required this.builder,
    this.initialChildSize = 0.58,
    this.minChildSize = 0.28,
    this.maxChildSize = 0.92,
    this.expand = false,
    this.snap = false,
    this.snapSizes,
    this.shouldCloseOnMinExtent = true,
  });

  final ScrollableWidgetBuilder builder;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final bool expand;
  final bool snap;
  final List<double>? snapSizes;
  final bool shouldCloseOnMinExtent;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      expand: expand,
      snap: snap,
      snapSizes: snapSizes,
      shouldCloseOnMinExtent: shouldCloseOnMinExtent,
      builder: builder,
    );
  }
}

Future<T?> showAppModalDialog<T>({
  required BuildContext context,
  String? title,
  String? subtitle,
  Widget? child,
  WidgetBuilder? builder,
  RoutePageBuilder? pageBuilder,
  RouteTransitionsBuilder? transitionBuilder,
  IconData? icon,
  List<AppModalAction<T>> actions = const [],
  String? barrierLabel,
  Color? barrierColor,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  bool showCloseButton = true,
  Duration transitionDuration = const Duration(milliseconds: 180),
  Offset? anchorPoint,
}) {
  final effectiveBarrierLabel =
      barrierLabel ??
      MaterialLocalizations.of(context).modalBarrierDismissLabel;
  final colors = AppDesignSystem.colorsFor(context);

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: effectiveBarrierLabel,
    barrierColor: barrierColor ?? colors.scrim.withValues(alpha: 0.72),
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    transitionDuration: transitionDuration,
    anchorPoint: anchorPoint,
    pageBuilder:
        pageBuilder ??
        (context, _, _) {
          if (title == null) {
            final content = builder?.call(context) ?? child;
            final dialog = Center(
              child: Padding(
                padding: const AppEdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.xl,
                ),
                child: content ?? const SizedBox.shrink(),
              ),
            );
            return useSafeArea ? SafeArea(child: dialog) : dialog;
          }

          final content = builder?.call(context) ?? child;
          final mediaQuery = MediaQuery.of(context);
          final maxHeight =
              mediaQuery.size.height - mediaQuery.viewPadding.vertical;

          return SafeArea(
            child: Center(
              child: Padding(
                padding: const AppEdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.xl,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  child: AppModalScaffold<T>(
                    title: title,
                    subtitle: subtitle,
                    icon: icon,
                    actions: actions,
                    showDragHandle: false,
                    showCloseButton: showCloseButton,
                    child: content ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          );
        },
    transitionBuilder:
        transitionBuilder ??
        (context, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
              child: child,
            ),
          );
        },
  );
}

Future<T?> showAppModalBottomSheet<T>({
  required BuildContext context,
  String? title,
  String? subtitle,
  Widget? child,
  WidgetBuilder? builder,
  IconData? icon,
  List<AppModalAction<T>> actions = const [],
  Color? backgroundColor,
  String? barrierLabel,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  Color? barrierColor,
  bool isScrollControlled = true,
  double scrollControlDisabledMaxHeightRatio = 9.0 / 16.0,
  bool enableDrag = true,
  bool? showDragHandle,
  bool useSafeArea = false,
  bool useRootNavigator = false,
  bool isDismissible = true,
  RouteSettings? routeSettings,
  AnimationController? transitionAnimationController,
  Offset? anchorPoint,
  AnimationStyle? sheetAnimationStyle,
  bool? requestFocus,
  bool showCloseButton = true,
  bool extendToBottom = false,
  double initialChildSize = 0.58,
  double minChildSize = 0.28,
  double maxChildSize = 0.92,
}) {
  final colors = AppDesignSystem.colorsFor(context);

  return showModalBottomSheet<T>(
    context: context,
    builder: (context) {
      final content = builder?.call(context) ?? child;
      final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
      final systemBottomPadding = MediaQuery.viewPaddingOf(context).bottom;
      final effectiveBottomInset = keyboardInset > 0
          ? keyboardInset
          : systemBottomPadding;

      if (title == null) {
        final customContentBottomInset = keyboardInset > 0
            ? keyboardInset
            : extendToBottom
            ? 0.0
            : systemBottomPadding;
        return Padding(
          padding: AppEdgeInsets.only(bottom: customContentBottomInset),
          child: SizedBox(
            width: double.infinity,
            child: content ?? const SizedBox.shrink(),
          ),
        );
      }

      return AppModalSheetFrame(
        useSafeArea: false,
        onTapOutside: isDismissible
            ? () => Navigator.of(context).maybePop()
            : null,
        child: Padding(
          padding: AppEdgeInsets.only(bottom: effectiveBottomInset),
          child: SafeArea(
            top: false,
            bottom: false,
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: initialChildSize,
              minChildSize: minChildSize,
              maxChildSize: maxChildSize,
              builder: (context, scrollController) {
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: double.infinity,
                    child: AppModalScaffold<T>(
                      title: title,
                      subtitle: subtitle,
                      icon: icon,
                      actions: actions,
                      scrollController: scrollController,
                      showDragHandle: showDragHandle ?? true,
                      showCloseButton: showCloseButton,
                      maxWidth: double.infinity,
                      surfaceBorderRadius: AppRadius.sheetTop,
                      bottomSafeAreaPadding: systemBottomPadding,
                      child: content ?? const SizedBox.shrink(),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
    backgroundColor: backgroundColor ?? colors.transparent,
    barrierLabel: barrierLabel,
    elevation: elevation,
    shape: shape,
    clipBehavior: clipBehavior,
    constraints: _fullWidthBottomSheetConstraints(context, constraints),
    barrierColor: barrierColor ?? colors.scrim.withValues(alpha: 0.58),
    isScrollControlled: isScrollControlled,
    scrollControlDisabledMaxHeightRatio: scrollControlDisabledMaxHeightRatio,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: title == null ? showDragHandle : false,
    useSafeArea: useSafeArea,
    routeSettings: routeSettings,
    transitionAnimationController: transitionAnimationController,
    anchorPoint: anchorPoint,
    sheetAnimationStyle: sheetAnimationStyle,
    requestFocus: requestFocus,
  );
}

Future<T?> showAppActionSheet<T>({
  required BuildContext context,
  required String title,
  required List<AppActionSheetItem<T>> items,
  String? subtitle,
  IconData? icon,
}) {
  return showAppModalBottomSheet<T>(
    context: context,
    title: title,
    subtitle: subtitle,
    icon: icon,
    child: _AppActionSheetList<T>(items: items),
    actions: const [],
  );
}

AppBoxDecoration _modalSurfaceDecoration(
  BuildContext context,
  AppColors colors, {
  Color? backgroundColor,
  BorderRadiusGeometry borderRadius = AppRadius.panel,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return AppBoxDecoration(
    color: backgroundColor ?? colors.surface,
    borderRadius: borderRadius,
    border: Border.all(color: colors.borderSoft),
    boxShadow: isDark
        ? [
            BoxShadow(
              color: colors.black.withValues(alpha: 0.28),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ]
        : null,
  );
}

ButtonStyle _destructiveButtonStyle(AppColors colors) {
  return FilledButton.styleFrom(
    minimumSize: const Size(0, AppSizes.minTapTarget),
    padding: AppInsets.button,
    backgroundColor: colors.danger,
    foregroundColor: colors.textPrimary,
    disabledBackgroundColor: colors.surfaceHigh,
    disabledForegroundColor: colors.textDisabled,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
    textStyle: _modalActionTextStyle(),
  );
}

class _AppModalDragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return DecoratedBox(
      decoration: AppDecorations.pill(
        background: colors.textSecondary.withValues(alpha: 0.34),
        border: colors.transparent,
      ),
      child: const SizedBox(width: 44, height: 5),
    );
  }
}

class _AppModalIcon extends StatelessWidget {
  const _AppModalIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: colors.secondaryContainer,
        shape: BoxShape.circle,
        border: Border.all(color: colors.borderSecondary),
      ),
      child: SizedBox.square(
        dimension: AppSizes.minTapTarget,
        child: Icon(icon, color: colors.secondary, size: AppSizes.iconMd),
      ),
    );
  }
}

class _AppModalActions<T> extends StatelessWidget {
  const _AppModalActions({required this.actions});

  final List<AppModalAction<T>> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final stack = constraints.maxWidth < 340 || textScale > 1.2;
        final buttonWidth = stack
            ? constraints.maxWidth
            : (constraints.maxWidth - AppSpacing.md) / 2;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          alignment: WrapAlignment.end,
          children: [
            for (final action in actions)
              SizedBox(
                width: stack ? buttonWidth : null,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: buttonWidth),
                  child: _AppModalActionButton<T>(action: action),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AppModalActionButton<T> extends StatelessWidget {
  const _AppModalActionButton({required this.action});

  final AppModalAction<T> action;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final onPressed = action.enabled
        ? () {
            action.onPressed?.call();
            if (action.dismissesModal) {
              Navigator.of(context).pop<T>(action.result);
            }
          }
        : null;

    final label = Text(
      action.label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
    final icon = action.icon;

    return switch (action.variant) {
      AppModalActionVariant.primary =>
        icon == null
            ? FilledButton(
                onPressed: onPressed,
                style: _compactModalButtonStyle(
                  AppButtonStyles.primary(colors),
                ),
                child: label,
              )
            : FilledButton.icon(
                onPressed: onPressed,
                style: _compactModalButtonStyle(
                  AppButtonStyles.primary(colors),
                ),
                icon: Icon(icon, size: AppSizes.iconSm),
                label: label,
              ),
      AppModalActionVariant.destructive =>
        icon == null
            ? FilledButton(
                onPressed: onPressed,
                style: _destructiveButtonStyle(colors),
                child: label,
              )
            : FilledButton.icon(
                onPressed: onPressed,
                style: _destructiveButtonStyle(colors),
                icon: Icon(icon, size: AppSizes.iconSm),
                label: label,
              ),
      AppModalActionVariant.ghost =>
        icon == null
            ? TextButton(
                onPressed: onPressed,
                style: _compactModalButtonStyle(AppButtonStyles.ghost(colors)),
                child: label,
              )
            : TextButton.icon(
                onPressed: onPressed,
                style: _compactModalButtonStyle(AppButtonStyles.ghost(colors)),
                icon: Icon(icon, size: AppSizes.iconSm),
                label: label,
              ),
      AppModalActionVariant.secondary =>
        icon == null
            ? OutlinedButton(
                onPressed: onPressed,
                style: _compactModalButtonStyle(
                  AppButtonStyles.secondary(colors),
                ),
                child: label,
              )
            : OutlinedButton.icon(
                onPressed: onPressed,
                style: _compactModalButtonStyle(
                  AppButtonStyles.secondary(colors),
                ),
                icon: Icon(icon, size: AppSizes.iconSm),
                label: label,
              ),
    };
  }
}

TextStyle _modalActionTextStyle() {
  return AppTypography.bodyStrongStyle.copyWith(fontSize: 14, height: 1.28);
}

ButtonStyle _compactModalButtonStyle(ButtonStyle style) {
  return style.copyWith(
    textStyle: WidgetStatePropertyAll(_modalActionTextStyle()),
  );
}

class _AppActionSheetList<T> extends StatelessWidget {
  const _AppActionSheetList({required this.items});

  final List<AppActionSheetItem<T>> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [for (final item in items) _AppActionSheetTile<T>(item: item)],
    );
  }
}

class _AppActionSheetTile<T> extends StatelessWidget {
  const _AppActionSheetTile({required this.item});

  final AppActionSheetItem<T> item;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final color = item.destructive ? colors.danger : colors.textPrimary;
    final iconColor = item.destructive ? colors.danger : colors.primary;

    return Material(
      color: colors.transparent,
      child: InkWell(
        onTap: item.enabled
            ? () => Navigator.of(context).pop<T>(item.value)
            : null,
        borderRadius: AppRadius.card,
        child: Padding(
          padding: const AppEdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              if (item.icon != null) ...[
                Icon(item.icon, color: iconColor, size: AppSizes.iconMd),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyStrongStyle.copyWith(
                        color: item.enabled ? color : colors.textDisabled,
                        fontSize: 14,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.subtitle!,
                        style: AppTypography.captionStyle.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                color: item.enabled ? colors.textMuted : colors.textDisabled,
                size: AppSizes.iconSm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
