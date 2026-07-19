import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/app_design_system.dart';
import '../../../../l10n/generated/app_localizations.dart';

class SavedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SavedAppBar({
    super.key,
    required this.title,
    required this.titleKey,
    required this.fallbackRoute,
    required this.createButtonKey,
    required this.isCreating,
    this.onCreate,
  });

  final String title;
  final Key titleKey;
  final String fallbackRoute;
  final Key createButtonKey;
  final bool isCreating;
  final VoidCallback? onCreate;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final l10n = AppLocalizations.of(context)!;
    final titleStyle =
        Theme.of(context).appBarTheme.titleTextStyle ??
        Theme.of(context).textTheme.titleLarge;
    return AppBar(
      backgroundColor: colors.background,
      foregroundColor: colors.textPrimary,
      surfaceTintColor: colors.transparent,
      leadingWidth: 78,
      title: Text(
        title,
        key: titleKey,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: titleStyle?.copyWith(
          color: colors.textPrimary,
          letterSpacing: 0,
        ),
      ),
      titleSpacing: 0,
      leading: Padding(
        padding: const AppEdgeInsets.only(left: 18),
        child: Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(fallbackRoute);
              }
            },
            style: IconButton.styleFrom(
              backgroundColor: colors.surfaceRaised,
              foregroundColor: colors.textPrimary,
              minimumSize: const Size.square(AppSizes.minTapTarget),
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          ),
        ),
      ),
      actions: [
        if (onCreate != null)
          Padding(
            padding: const AppEdgeInsets.only(right: 18),
            child: IconButton(
              key: createButtonKey,
              tooltip: l10n.savedCreateCollection,
              onPressed: isCreating ? null : onCreate,
              style: IconButton.styleFrom(
                backgroundColor: colors.primaryContainer,
                foregroundColor: colors.primary,
                disabledBackgroundColor: colors.surfaceHigh,
                disabledForegroundColor: colors.textMuted,
                minimumSize: const Size.square(AppSizes.minTapTarget),
              ),
              icon: isCreating
                  ? SizedBox.square(
                      dimension: AppSizes.iconSm,
                      child: CircularProgressIndicator(
                        color: colors.primary,
                        strokeWidth: AppSpacing.xxs,
                      ),
                    )
                  : const Icon(Icons.add_rounded),
            ),
          ),
      ],
    );
  }
}
