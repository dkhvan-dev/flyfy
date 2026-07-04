import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'route widgets use generated localizations instead of hardcoded labels',
    () async {
      final summarySource = await File(
        'lib/features/routing/widgets/route_summary_card.dart',
      ).readAsString();
      final selectorSource = await File(
        'lib/features/routing/widgets/route_mode_selector.dart',
      ).readAsString();
      final badgeSource = await File(
        'lib/features/routing/widgets/travel_time_badge.dart',
      ).readAsString();
      final ruArb = await File('lib/l10n/app_ru.arb').readAsString();

      expect(summarySource, contains('AppLocalizations.of(context)!'));
      expect(selectorSource, contains('AppLocalizations.of(context)!'));
      expect(badgeSource, contains('AppLocalizations.of(context)!'));
      expect(summarySource, isNot(contains('Tourist walk')));
      expect(summarySource, isNot(contains('Guide route')));
      expect(selectorSource, isNot(contains("'Walk'")));
      expect(selectorSource, isNot(contains("'Transit'")));
      expect(badgeSource, isNot(contains(r"'$minutes min'")));
      expect(ruArb, contains('"routeSummaryTitle": "Время в пути"'));
      expect(ruArb, contains('"routeProfileGuideRoute": "Маршрут гида"'));
      expect(ruArb, contains('"routeDurationMinutesShort": "{minutes} мин"'));
    },
  );

  test(
    'route summary card uses adaptive V2 styling and no external maps action',
    () async {
      final summarySource = await File(
        'lib/features/routing/widgets/route_summary_card.dart',
      ).readAsString();

      expect(summarySource, contains('app_design_system.dart'));
      expect(summarySource, contains('AppDesignSystem.colorsFor(context)'));
      expect(summarySource, contains('colors.secondaryContainer'));
      expect(summarySource, contains('colors.borderSecondary'));
      expect(summarySource, contains('colors.secondary'));
      expect(summarySource, contains('Icons.route_rounded'));
      expect(summarySource, contains('routeSummaryTitle'));
      expect(summarySource, contains('routeSummaryDistance'));
      expect(summarySource, contains('routeSummaryDuration'));
      expect(summarySource, isNot(contains('AppPalette.')));
      expect(summarySource, isNot(contains('onOpenExternalMap')));
      expect(summarySource, isNot(contains('Open in maps')));
    },
  );

  test(
    'route mode selector is adaptive V2 styled and omits fast walk by default',
    () async {
      final selectorSource = await File(
        'lib/features/routing/widgets/route_mode_selector.dart',
      ).readAsString();

      expect(selectorSource, contains('static const List<RouteProfile>'));
      expect(selectorSource, contains('app_design_system.dart'));
      expect(selectorSource, contains('AppDesignSystem.colorsFor(context)'));
      expect(selectorSource, contains('colors.primary'));
      expect(selectorSource, contains('RouteProfile.touristWalk'));
      expect(selectorSource, contains('RouteProfile.bikeCity'));
      expect(selectorSource, contains('RouteProfile.carStandard'));
      expect(selectorSource, isNot(contains('AppPalette.')));
      expect(selectorSource, isNot(contains('RouteProfile.values')));

      final defaultsStart = selectorSource.indexOf('_defaultProfiles');
      expect(defaultsStart, isNonNegative);
      final defaultsEnd = selectorSource.indexOf('];', defaultsStart);
      expect(defaultsEnd, greaterThan(defaultsStart));
      final defaultsSource = selectorSource.substring(
        defaultsStart,
        defaultsEnd,
      );
      expect(defaultsSource, isNot(contains('RouteProfile.fastWalk')));
    },
  );

  test('reachability badge uses adaptive V2 colors', () async {
    final source = await File(
      'lib/features/routing/widgets/reachability_badge.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.success'));
    expect(source, contains('colors.danger'));
    expect(source, isNot(contains('AppPalette.')));
  });
}
