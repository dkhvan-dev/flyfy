import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:provider/provider.dart';

import '../../../core/ui/app_language_sheet.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/theme_mode_provider.dart';

class AppPreferencesSection extends StatelessWidget {
  const AppPreferencesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final localeCode = context.watch<LocaleProvider>().locale.languageCode;
    final selectedThemeMode = context.watch<ThemeModeProvider>().selectedMode;

    return Column(
      children: [
        _AppPreferenceAction(
          key: const ValueKey('app-language-preference'),
          icon: Icons.language_rounded,
          title: AppLocalizations.of(context)!.appLanguageTitle,
          subtitle: _languageName(localeCode),
          onTap: () => showAppLanguageSheet(context),
        ),
        const SizedBox(height: 12),
        _AppThemePreference(
          selectedMode: selectedThemeMode,
          onChanged: (mode) {
            unawaited(context.read<ThemeModeProvider>().setThemeMode(mode));
          },
        ),
      ],
    );
  }
}

class _AppPreferenceAction extends StatelessWidget {
  const _AppPreferenceAction({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Semantics(
      button: true,
      label: title,
      value: subtitle,
      child: Material(
        color: colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppBorderRadius.circular(20),
          child: Ink(
            padding: const AppEdgeInsets.all(16),
            decoration: _preferenceDecoration(context),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Row(
                children: [
                  _PreferenceIcon(icon: icon),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyle(
                            color: colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle(
                            color: colors.textMuted,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.chevron_right_rounded, color: colors.textMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppThemePreference extends StatelessWidget {
  const _AppThemePreference({
    required this.selectedMode,
    required this.onChanged,
  });

  final AppThemeModePreference selectedMode;
  final ValueChanged<AppThemeModePreference> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      key: const ValueKey('app-theme-preference'),
      width: double.infinity,
      padding: const AppEdgeInsets.all(16),
      decoration: _preferenceDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PreferenceIcon(icon: Icons.contrast_rounded),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.appThemeTitle,
                      style: AppTextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      child: Text(
                        '${_themeModeLabel(l10n, selectedMode)}: '
                        '${_themeModeDescription(l10n, selectedMode)}',
                        key: ValueKey(selectedMode),
                        style: AppTextStyle(
                          color: colors.textMuted,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<AppThemeModePreference>(
              segments: [
                for (final mode in AppThemeModePreference.values)
                  ButtonSegment<AppThemeModePreference>(
                    value: mode,
                    tooltip: _themeModeLabel(l10n, mode),
                    icon: Icon(
                      _themeModeIcon(mode),
                      key: ValueKey('app-theme-mode-${mode.name}'),
                      size: 20,
                    ),
                  ),
              ],
              selected: {selectedMode},
              showSelectedIcon: false,
              expandedInsets: AppEdgeInsets.zero,
              onSelectionChanged: (selection) {
                final nextMode = selection.firstOrNull;
                if (nextMode != null && nextMode != selectedMode) {
                  onChanged(nextMode);
                }
              },
              style: ButtonStyle(
                minimumSize: WidgetStateProperty.all(const Size(0, 48)),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  return states.contains(WidgetState.selected)
                      ? colors.onPrimary
                      : colors.textSecondary;
                }),
                iconColor: WidgetStateProperty.resolveWith((states) {
                  return states.contains(WidgetState.selected)
                      ? colors.onPrimary
                      : colors.primary;
                }),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  return states.contains(WidgetState.selected)
                      ? colors.primary
                      : colors.surfaceRaised;
                }),
                side: WidgetStateProperty.resolveWith((states) {
                  return BorderSide(
                    color: states.contains(WidgetState.selected)
                        ? colors.primary
                        : colors.borderPrimary,
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceIcon extends StatelessWidget {
  const _PreferenceIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return Container(
      width: 46,
      height: 46,
      decoration: AppBoxDecoration(
        shape: BoxShape.circle,
        color: colors.primary.withValues(alpha: 0.12),
      ),
      child: Icon(icon, color: colors.primary),
    );
  }
}

BoxDecoration _preferenceDecoration(BuildContext context) {
  final colors = AppDesignSystem.colorsFor(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return AppBoxDecoration(
    color: colors.surface,
    borderRadius: AppBorderRadius.circular(20),
    border: Border.all(color: colors.borderSoft),
    boxShadow: isDark
        ? [
            BoxShadow(
              color: colors.black.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ]
        : null,
  );
}

String _languageName(String languageCode) {
  return switch (languageCode.trim().toLowerCase()) {
    'ru' => 'Русский',
    'kk' => 'Қазақша',
    _ => 'English',
  };
}

String _themeModeLabel(AppLocalizations l10n, AppThemeModePreference mode) {
  return switch (mode) {
    AppThemeModePreference.system => l10n.appThemeSystem,
    AppThemeModePreference.light => l10n.appThemeLight,
    AppThemeModePreference.dark => l10n.appThemeDark,
  };
}

String _themeModeDescription(
  AppLocalizations l10n,
  AppThemeModePreference mode,
) {
  return switch (mode) {
    AppThemeModePreference.system => l10n.appThemeSystemDescription,
    AppThemeModePreference.light => l10n.appThemeLightDescription,
    AppThemeModePreference.dark => l10n.appThemeDarkDescription,
  };
}

IconData _themeModeIcon(AppThemeModePreference mode) {
  return switch (mode) {
    AppThemeModePreference.system => Icons.brightness_auto_rounded,
    AppThemeModePreference.light => Icons.light_mode_rounded,
    AppThemeModePreference.dark => Icons.dark_mode_rounded,
  };
}
