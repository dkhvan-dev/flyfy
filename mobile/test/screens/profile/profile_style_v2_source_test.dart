import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile screen uses adaptive V2 design system colors', () async {
    final source = await File(
      'lib/screens/profile/profile_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.themeFor(context)'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.secondary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test('profile verified guide badge uses secondary trust accent', () async {
    final source = await File(
      'lib/screens/profile/profile_screen.dart',
    ).readAsString();

    final avatarStart = source.indexOf('class _ProfileAvatar');
    final verifiedStart = source.indexOf('if (verified)', avatarStart);
    final pillStart = source.indexOf('class _ProfilePill', avatarStart);
    expect(avatarStart, isNonNegative);
    expect(verifiedStart, greaterThan(avatarStart));
    expect(pillStart, greaterThan(verifiedStart));

    final avatarSource = source.substring(verifiedStart, pillStart);
    expect(avatarSource, contains('color: context.profileColors.secondary'));
    expect(
      avatarSource,
      contains('color: context.profileColors.secondary.withValues'),
    );
    expect(
      avatarSource,
      isNot(contains('color: context.profileColors.primary.withValues')),
    );
  });

  test('profile style helpers use V2 design system colors', () async {
    final source = await File(
      'lib/screens/profile/profile_style.dart',
    ).readAsString();
    final decorationStart = source.indexOf(
      'BoxDecoration profileCardDecoration',
    );
    expect(decorationStart, isNonNegative);
    final helperSource = source.substring(decorationStart);

    expect(source, contains('app_design_system.dart'));
    expect(helperSource, contains('AppDesignSystem.colorsFor(context)'));
    expect(helperSource, contains('colors.primary'));
    expect(helperSource, contains('colors.textPrimary'));
    expect(helperSource, isNot(contains('AppPalette.')));
  });

  test('profile shell background uses shared V2 screen gradient', () async {
    final source = await File(
      'lib/screens/profile/profile_style.dart',
    ).readAsString();

    final backgroundStart = source.indexOf('class ProfileGlassBackground');
    expect(backgroundStart, isNonNegative);

    final backgroundSource = source.substring(backgroundStart);

    expect(backgroundSource, contains('colors.screenGradientColors'));
    expect(
      backgroundSource,
      isNot(contains('[colors.backgroundDeep, colors.background]')),
    );
  });

  test('profile journey menu arrows use primary accent when enabled', () async {
    final source = await File(
      'lib/screens/profile/profile_screen.dart',
    ).readAsString();

    final menuTileStart = source.indexOf('class _ProfileMenuTile');
    final nextClassStart = source.indexOf('class ', menuTileStart + 1);
    expect(menuTileStart, isNonNegative);
    expect(nextClassStart, greaterThan(menuTileStart));

    final menuTileSource = source.substring(menuTileStart, nextClassStart);
    final chevronStart = menuTileSource.indexOf('Icons.chevron_right_rounded');
    expect(chevronStart, isNonNegative);

    final chevronSource = menuTileSource.substring(chevronStart);
    expect(chevronSource, contains('color: effectiveDisabled'));
    expect(chevronSource, contains('? profileDisabled'));
    expect(chevronSource, contains(': context.profileColors.primary'));
    expect(
      chevronSource,
      isNot(
        contains(
          'color: effectiveDisabled ? profileDisabled : profileTextMuted',
        ),
      ),
    );
  });
}
