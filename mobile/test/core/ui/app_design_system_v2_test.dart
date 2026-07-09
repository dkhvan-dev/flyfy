import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/ui/app_design_system.dart';

void main() {
  test('dark v2 theme uses Amber primary and Teal secondary', () {
    final theme = AppDesignSystem.darkTheme();

    expect(AppPalette.primary, const Color(0xFFFF9F0A));
    expect(AppPalette.secondary, const Color(0xFF00A99D));
    expect(AppPalette.background, const Color(0xFF111B21));
    expect(AppPalette.surfaceRaised, const Color(0xFF1A2127));
    expect(AppPalette.onPrimary, const Color(0xFF111827));
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, AppPalette.background);
    expect(theme.colorScheme.primary, AppPalette.primary);
    expect(theme.colorScheme.secondary, AppPalette.secondary);
    expect(theme.colorScheme.onPrimary, AppPalette.textPrimary);
  });

  test('light v2 theme uses Amber primary and Teal secondary', () {
    final theme = AppDesignSystem.lightTheme();

    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, AppColorSchemes.light.background);
    expect(theme.colorScheme.primary, AppColorSchemes.light.primary);
    expect(theme.colorScheme.secondary, AppColorSchemes.light.secondary);
    expect(theme.colorScheme.onPrimary, AppColorSchemes.light.textPrimary);
    expect(
      AppButtonStyles.primary(
        AppColorSchemes.light,
      ).foregroundColor?.resolve(<WidgetState>{}),
      AppColorSchemes.light.textPrimary,
    );
  });

  test('light v2 palette keeps clean white surfaces with visible controls', () {
    final colors = AppColorSchemes.light;

    expect(colors.backgroundDeep, const Color(0xFFFFFFFF));
    expect(colors.background, const Color(0xFFFBFCFE));
    expect(colors.backgroundWarm, const Color(0xFFF6F8FB));
    expect(colors.surface, const Color(0xFFFFFFFF));
    expect(colors.surfaceRaised, const Color(0xFFFFFFFF));
    expect(colors.surfaceHigh, const Color(0xFFF1F5F9));
    expect(colors.textPrimary, const Color(0xFF111827));
    expect(colors.textSecondary, const Color(0xFF475569));
    expect(colors.textMuted, const Color(0xFF64748B));
    expect(colors.border, const Color(0xFFCBD5E1));
    expect(colors.borderSoft, const Color(0xFFCBD5E1));
    expect(
      _contrastRatio(colors.borderSoft, colors.surface),
      greaterThan(1.35),
    );
    expect(colors.screenGradientColors, [
      const Color(0xFFFFFFFF),
      const Color(0xFFFBFCFE),
      const Color(0xFFFBFCFE),
    ]);
  });

  test('v2 screen gradient uses the shared graphite background recipe', () {
    final dark = AppColorSchemes.dark;
    final light = AppColorSchemes.light;

    expect(dark.screenGradientColors, [
      dark.surface,
      dark.background,
      dark.background,
    ]);
    expect(light.screenGradientColors, [
      light.surface,
      light.background,
      light.background,
    ]);
    expect(dark.screenGradientColors, isNot(contains(dark.backgroundDeep)));
    expect(dark.screenGradientColors, isNot(contains(dark.backgroundWarm)));
  });

  test('light v2 secondary has readable contrast on white surfaces', () {
    final colors = AppColorSchemes.light;

    expect(_contrastRatio(colors.secondary, colors.surface), greaterThan(4.5));
    expect(
      _contrastRatio(colors.secondary, colors.backgroundDeep),
      greaterThan(4.5),
    );
  });

  test('light v2 secondary buttons use visible neutral outlines', () {
    final colors = AppColorSchemes.light;
    final style = AppButtonStyles.secondary(colors);

    expect(style.side?.resolve(<WidgetState>{})?.color, colors.borderSoft);
  });

  testWidgets('v2 adaptive theme follows parent brightness', (tester) async {
    final observedBrightness = <Brightness>[];

    await tester.pumpWidget(
      Theme(
        data: ThemeData.light(),
        child: Builder(
          builder: (context) {
            observedBrightness.add(
              AppDesignSystem.themeFor(context).brightness,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    await tester.pumpWidget(
      Theme(
        data: ThemeData.dark(),
        child: Builder(
          builder: (context) {
            observedBrightness.add(
              AppDesignSystem.themeFor(context).brightness,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(observedBrightness, [Brightness.light, Brightness.dark]);
  });

  test('primary button backgrounds use textPrimary foreground colors', () {
    final legacyTheme = AppDesignSystem.darkTheme();
    final v2Theme = AppDesignSystem.darkTheme();

    expect(
      AppButtonStyles.primary().foregroundColor?.resolve(<WidgetState>{}),
      AppPalette.textPrimary,
    );
    expect(
      AppButtonStyles.primary().foregroundColor?.resolve(<WidgetState>{}),
      AppPalette.textPrimary,
    );
    expect(legacyTheme.colorScheme.onPrimary, AppPalette.textPrimary);
    expect(v2Theme.colorScheme.onPrimary, AppPalette.textPrimary);
  });
}

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;

  return (lighter + 0.05) / (darker + 0.05);
}
