import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'places screen uses adaptive V2 colors instead of legacy palette',
    () async {
      final source = await File(
        'lib/screens/places/places_screen.dart',
      ).readAsString();

      expect(
        source,
        contains("import 'package:inflap/core/ui/app_design_system.dart';"),
      );
      expect(source, contains('AppDesignSystem.themeFor(context)'));
      expect(source, contains('AppDesignSystem.colorsFor(context)'));
      expect(source, contains('colors.screenGradientColors'));
      expect(source, isNot(contains('AppPalette.')));
    },
  );

  test(
    'places light theme cover cards use clean image borders without overlay gradients',
    () async {
      final source = await File(
        'lib/screens/places/places_screen.dart',
      ).readAsString();

      final helperStart = source.indexOf(
        'LinearGradient? _placesCoverOverlayGradient',
      );
      final mustVisitStart = source.indexOf('class _MustVisitCard');
      final discoverStart = source.indexOf('class _DiscoverCard');
      final retryingStart = source.indexOf('class _RetryingPlaceCoverImage');
      expect(helperStart, isNonNegative);
      expect(mustVisitStart, isNonNegative);
      expect(retryingStart, greaterThan(mustVisitStart));
      expect(discoverStart, greaterThan(retryingStart));

      final helperSource = source.substring(helperStart, mustVisitStart);
      final mustVisitSource = source.substring(mustVisitStart, retryingStart);
      final discoverSource = source.substring(discoverStart);

      expect(helperSource, contains('Brightness.light'));
      expect(helperSource, contains('return null;'));
      expect(mustVisitSource, contains('final coverOverlayGradient ='));
      expect(discoverSource, contains('final coverOverlayGradient ='));
      expect(mustVisitSource, contains('if (coverOverlayGradient != null)'));
      expect(discoverSource, contains('if (coverOverlayGradient != null)'));
      expect(mustVisitSource, contains('DecorationPosition.foreground'));
      expect(discoverSource, contains('DecorationPosition.foreground'));
      expect(mustVisitSource, contains('Border.all(color: colors.border)'));
      expect(discoverSource, contains('Border.all(color: colors.border)'));
    },
  );
}
