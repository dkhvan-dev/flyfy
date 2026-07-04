import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('community profile screen uses V2 design system colors', () async {
    final source = await File(
      'lib/features/feed/presentation/community_profile_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.themeFor(context)'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test('community profile info panel uses a clean solid V2 surface', () async {
    final source = await File(
      'lib/features/feed/presentation/community_profile_screen.dart',
    ).readAsString();
    final panelStart = source.indexOf(
      "key: const ValueKey('community-profile-info-panel')",
    );
    final avatarStart = source.indexOf('Positioned(', panelStart);

    expect(panelStart, isNonNegative);
    expect(avatarStart, greaterThan(panelStart));

    final panelSource = source.substring(panelStart, avatarStart);

    expect(panelSource, contains('color: colors.surface'));
    expect(panelSource, contains('border: Border.all(color: colors.border)'));
    expect(panelSource, isNot(contains('_communityAmberPanelColor(context)')));
    expect(panelSource, isNot(contains('LinearGradient(')));
    expect(panelSource, isNot(contains('gradient:')));
    expect(
      panelSource,
      isNot(contains('colors.primary.withValues(alpha: 0.10)')),
    );
  });

  test(
    'community profile fallback cover avoids dirty amber teal gradients',
    () async {
      final source = await File(
        'lib/features/feed/presentation/community_profile_screen.dart',
      ).readAsString();
      final fallbackStart = source.indexOf('class _CommunityCoverFallback');
      final avatarStart = source.indexOf(
        'class _CommunityAvatar',
        fallbackStart,
      );

      expect(fallbackStart, isNonNegative);
      expect(avatarStart, greaterThan(fallbackStart));

      final fallbackSource = source.substring(fallbackStart, avatarStart);

      expect(fallbackSource, contains('color: colors.surfaceHigh'));
      expect(fallbackSource, isNot(contains('LinearGradient(')));
      expect(fallbackSource, isNot(contains('gradient:')));
      expect(fallbackSource, isNot(contains('colors.surfaceTeal')));
    },
  );

  test(
    'community profile keeps bottom safe area inside the scroll content',
    () async {
      final source = await File(
        'lib/features/feed/presentation/community_profile_screen.dart',
      ).readAsString();

      final buildStart = source.indexOf('@override\n  Widget build');
      expect(buildStart, isNonNegative);
      final bodyStart = source.indexOf('Widget _buildBody', buildStart);
      expect(bodyStart, greaterThan(buildStart));
      final buildSource = source.substring(buildStart, bodyStart);

      expect(buildSource, contains('SafeArea('));
      expect(buildSource, contains('top: false'));
      expect(buildSource, contains('bottom: false'));

      final layoutStart = source.indexOf('return LayoutBuilder(');
      expect(layoutStart, isNonNegative);
      final layoutEnd = source.indexOf(
        'class _CommunityProfileHeader',
        layoutStart,
      );
      expect(layoutEnd, greaterThan(layoutStart));
      final layoutSource = source.substring(layoutStart, layoutEnd);

      expect(
        layoutSource,
        contains(
          'final bottomPadding = MediaQuery.paddingOf(context).bottom + 24',
        ),
      );
      expect(
        layoutSource,
        contains('padding: AppEdgeInsets.only(bottom: bottomPadding)'),
      );
      expect(
        layoutSource,
        isNot(contains('padding: const AppEdgeInsets.only(bottom: 32)')),
      );
    },
  );

  test(
    'community profile header buttons use primary filled V2 shell',
    () async {
      final source = await File(
        'lib/features/feed/presentation/community_profile_screen.dart',
      ).readAsString();

      final actionsStart = source.indexOf('class _CommunityHeaderActionsMenu');
      final menuTileStart = source.indexOf(
        'class _CommunityHeaderMenuTile',
        actionsStart,
      );
      final roundButtonStart = source.indexOf(
        'class _CommunityHeaderRoundButton',
      );
      final shellStart = source.indexOf(
        'class _CommunityHeaderRoundButtonShell',
        roundButtonStart,
      );

      expect(actionsStart, isNonNegative);
      expect(menuTileStart, greaterThan(actionsStart));
      expect(roundButtonStart, isNonNegative);
      expect(shellStart, greaterThan(roundButtonStart));

      final actionsSource = source.substring(actionsStart, menuTileStart);
      final roundButtonSource = source.substring(roundButtonStart, shellStart);

      expect(actionsSource, contains('color: colors.primary,'));
      expect(
        actionsSource,
        isNot(contains('color: colors.primary.withValues(alpha: 0.22)')),
      );
      expect(roundButtonSource, contains('color: colors.primary,'));
      expect(
        roundButtonSource,
        isNot(contains('color: colors.black.withValues(alpha: 0.32)')),
      );
    },
  );

  test('community profile location cue uses secondary V2 accent', () async {
    final source = await File(
      'lib/features/feed/presentation/community_profile_screen.dart',
    ).readAsString();

    final locationIconStart = source.indexOf('Icons.location_on_outlined');
    expect(locationIconStart, isNonNegative);
    final locationSource = source.substring(
      locationIconStart,
      source.indexOf('AppLocalizedLocationText(', locationIconStart),
    );

    expect(locationSource, contains('color: colors.secondary'));
    expect(locationSource, isNot(contains('colors.primary')));
  });
}
