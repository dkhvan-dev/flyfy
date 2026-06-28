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

    return Scaffold(
      backgroundColor: AppPalette.backgroundWarm,
      body: DecoratedBox(
        decoration: const AppBoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppPalette.warmInk38,
              AppPalette.warmInk08,
              AppPalette.warmInk04,
            ],
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
                      color: AppPalette.transparent,
                      child: InkWell(
                        onTap: () => context.pop(),
                        borderRadius: AppBorderRadius.circular(999),
                        child: Ink(
                          width: 44,
                          height: 44,
                          decoration: AppBoxDecoration(
                            color: AppPalette.white.withValues(alpha: 0.04),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppPalette.white.withValues(alpha: 0.06),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppPalette.textPrimary,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: const AppTextStyle(
                          color: AppPalette.textPrimary,
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
                              color: AppPalette.primary.withValues(alpha: 0.10),
                              border: Border.all(
                                color: AppPalette.primary.withValues(
                                  alpha: 0.24,
                                ),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppPalette.primary.withValues(
                                    alpha: 0.10,
                                  ),
                                  blurRadius: 34,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 48,
                              color: AppPalette.primary,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const AppTextStyle(
                              color: AppPalette.textPrimary,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.comingSoon,
                            textAlign: TextAlign.center,
                            style: const AppTextStyle(
                              color: AppPalette.textCoolSecondary,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 28),
                          FilledButton(
                            onPressed: () => context.go('/'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppPalette.primary,
                              foregroundColor: AppPalette.backgroundWarm,
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
