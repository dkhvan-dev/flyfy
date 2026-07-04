import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('edit profile screen uses adaptive V2 design system colors', () async {
    final source = await File(
      'lib/screens/profile/edit_profile_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.themeFor(context)'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.secondary'));
    expect(source, contains('colors.secondaryContainer'));
    expect(source, contains('colors.borderSecondary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test(
    'edit profile save action overlays transparent profile content',
    () async {
      final source = await File(
        'lib/screens/profile/edit_profile_screen.dart',
      ).readAsString();

      final scaffoldStart = source.indexOf('child: Scaffold(');
      final bodyStart = source.indexOf(
        'body: ProfileResponsiveScope(',
        scaffoldStart,
      );
      final backgroundStart = source.indexOf(
        'child: ProfileGlassBackground(',
        bodyStart,
      );
      final stackStart = source.indexOf('child: Stack(', backgroundStart);
      final safeAreaStart = source.indexOf('SafeArea(', stackStart);
      final saveOverlayStart = source.indexOf('Positioned(', stackStart);
      final saveButtonStart = source.indexOf(
        'child: _buildStickySaveButton(l10n)',
        saveOverlayStart,
      );

      expect(scaffoldStart, isNonNegative);
      expect(bodyStart, greaterThan(scaffoldStart));
      expect(backgroundStart, greaterThan(bodyStart));
      expect(stackStart, greaterThan(backgroundStart));
      expect(safeAreaStart, greaterThan(stackStart));
      expect(saveOverlayStart, greaterThan(stackStart));
      expect(saveButtonStart, greaterThan(saveOverlayStart));
      expect(
        source.substring(scaffoldStart, bodyStart),
        contains('extendBody: true'),
      );
      expect(
        source.substring(scaffoldStart, bodyStart),
        isNot(contains('bottomNavigationBar:')),
      );
      expect(
        source.substring(backgroundStart, stackStart),
        isNot(contains('SafeArea(')),
      );
      expect(
        source.substring(safeAreaStart, saveOverlayStart),
        contains('bottom: false'),
      );

      final saveOverlaySource = source.substring(
        saveOverlayStart,
        saveButtonStart,
      );
      expect(
        saveOverlaySource,
        contains('MediaQuery.paddingOf(context).bottom'),
      );
      expect(saveOverlaySource, isNot(contains('Container(')));
      expect(saveOverlaySource, isNot(contains('DecoratedBox(')));
      expect(saveOverlaySource, isNot(contains('AppBoxDecoration(')));
      expect(saveOverlaySource, isNot(contains('ColoredBox(')));
    },
  );

  test(
    'edit profile input fields use visible V2 surfaces and borders',
    () async {
      final source = await File(
        'lib/screens/profile/edit_profile_screen.dart',
      ).readAsString();

      final styledFieldStart = source.indexOf('class _StyledTextField');
      final styledFieldEnd = source.indexOf('class ', styledFieldStart + 1);
      final countryFieldStart = source.indexOf(
        'class _ProfileCountrySearchField',
      );
      final countryFieldEnd = source.indexOf(
        'class _ProfileCurrencySearchField',
        countryFieldStart,
      );
      final currencyFieldEnd = source.indexOf(
        'class _ProfileSectionCard',
        countryFieldEnd,
      );

      expect(styledFieldStart, isNonNegative);
      expect(countryFieldStart, isNonNegative);
      expect(countryFieldEnd, greaterThan(countryFieldStart));
      expect(currencyFieldEnd, greaterThan(countryFieldEnd));

      final fieldSources = [
        source.substring(
          styledFieldStart,
          styledFieldEnd == -1 ? source.length : styledFieldEnd,
        ),
        source.substring(countryFieldStart, countryFieldEnd),
        source.substring(countryFieldEnd, currencyFieldEnd),
      ];

      for (final fieldSource in fieldSources) {
        expect(fieldSource, contains('secondaryContainer'));
        expect(fieldSource, contains('borderSecondary'));
        expect(fieldSource, isNot(contains('white.withValues(alpha: 0.04)')));
        expect(fieldSource, isNot(contains('white.withValues(alpha: 0.05)')));
        expect(fieldSource, isNot(contains('borderSide: BorderSide.none')));
      }
    },
  );
}
