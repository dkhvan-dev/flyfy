import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';

class FeatureStubScreen extends StatelessWidget {
  const FeatureStubScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.background,
      body: DecoratedBox(
        decoration: AppBoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors.screenGradientColors,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const AppEdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    Material(
                      color: colors.transparent,
                      child: InkWell(
                        onTap: () => context.pop(),
                        borderRadius: AppBorderRadius.circular(999),
                        child: Ink(
                          width: 44,
                          height: 44,
                          decoration: AppBoxDecoration(
                            color: colors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.borderSoft),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: colors.textPrimary,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyle(
                          color: colors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: AppBoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.primaryContainer,
                              border: Border.all(
                                color: colors.borderPrimary,
                                width: 2,
                              ),
                              boxShadow: isDark
                                  ? [
                                      BoxShadow(
                                        color: colors.primary.withValues(
                                          alpha: 0.10,
                                        ),
                                        blurRadius: 34,
                                      ),
                                    ]
                                  : const [],
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              size: 48,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: AppTextStyle(
                              color: colors.textPrimary,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.comingSoon,
                            textAlign: TextAlign.center,
                            style: AppTextStyle(
                              color: colors.textSecondary,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 28),
                          FilledButton(
                            onPressed: () => context.go('/'),
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: colors.onPrimary,
                              minimumSize: const Size(180, 54),
                            ),
                            child: Text(l10n.homeNavHome),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
