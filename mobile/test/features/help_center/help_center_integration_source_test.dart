import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Help Center is routed publicly and exposed in services catalog',
    () async {
      final routerSource = await File(
        'lib/core/router/app_router.dart',
      ).readAsString();
      final catalogSource = await File(
        'lib/features/services/service_catalog.dart',
      ).readAsString();

      expect(
        routerSource,
        contains(
          "import '../../features/help_center/presentation/help_center_screen.dart';",
        ),
      );
      expect(routerSource, contains("path: '/help'"));
      expect(routerSource, contains('const HelpCenterScreen()'));
      expect(routerSource, contains("location == '/help'"));

      expect(catalogSource, contains('l10n.helpCenterTitle'));
      expect(catalogSource, contains("route: '/help'"));

      final currencyIndex = catalogSource.indexOf(
        'l10n.homeServiceCurrencyConverter',
      );
      final helpIndex = catalogSource.indexOf('l10n.helpCenterTitle');
      expect(currencyIndex, isNonNegative);
      expect(helpIndex, isNonNegative);
      expect(
        helpIndex,
        greaterThan(currencyIndex),
        reason: 'Help Center must appear after Currency Converter in services.',
      );
    },
  );

  test('contextual Q&A is embedded into travel detail screens', () async {
    final activitySource = await File(
      'lib/screens/activities/activity_details_screen.dart',
    ).readAsString();
    final excursionSource = await File(
      'lib/screens/excursions/excursion_details_screen.dart',
    ).readAsString();
    final placeSource = await File(
      'lib/screens/places/place_details_screen.dart',
    ).readAsString();
    final placesSource = await File(
      'lib/screens/places/places_screen.dart',
    ).readAsString();
    final currencySource = await File(
      'lib/screens/currency/currency_converter_screen.dart',
    ).readAsString();

    for (final source in [
      activitySource,
      excursionSource,
      placeSource,
      placesSource,
      currencySource,
    ]) {
      expect(source, contains('ContextualHelpSection('));
    }

    expect(activitySource, contains('HelpCenterSurface.activityDetails'));
    expect(activitySource, contains("'activity_id': widget.activityId"));
    expect(activitySource, contains("'entity_id': widget.activityId"));
    expect(activitySource, contains("'screen': 'activity_details'"));
    expect(
      activitySource,
      contains("'locale': Localizations.localeOf(context).languageCode"),
    );
    expect(activitySource, contains('_handleContextualHelpAction'));
    expect(
      activitySource,
      contains('action.type == HelpArticleActionType.openChat'),
    );
    expect(activitySource, contains("'/activities/\$encodedActivityId/chat'"));

    expect(excursionSource, contains('HelpCenterSurface.excursionDetails'));
    expect(excursionSource, contains("'excursion_id': widget.excursionId"));
    expect(excursionSource, contains("'entity_id': widget.excursionId"));
    expect(excursionSource, contains("'screen': 'excursion_details'"));
    expect(
      excursionSource,
      contains("'locale': Localizations.localeOf(context).languageCode"),
    );
    expect(excursionSource, contains('_handleContextualHelpAction'));
    expect(excursionSource, contains('_openGuideChat'));
    expect(
      excursionSource,
      contains('action.type == HelpArticleActionType.openChat'),
    );
    expect(excursionSource, contains('await _openGuideChat(guideUserId);'));

    expect(placeSource, contains('HelpCenterSurface.placeDetails'));
    expect(placeSource, contains("'place_id': widget.placeId"));
    expect(placeSource, contains("'screen': 'place_details'"));

    expect(placesSource, contains('HelpCenterSurface.places'));
    expect(placesSource, contains("'screen': 'places'"));
    expect(placesSource, contains("'search_query': search"));
    expect(placesSource, contains("'city_id': cityId"));
    expect(placesSource, contains("'country_code': countryCode"));

    expect(currencySource, contains('HelpCenterSurface.currencyConverter'));
    expect(
      currencySource,
      contains("'currency_pair': '\$_fromCurrency-\$_toCurrency'"),
    );
    expect(currencySource, contains("'screen': 'currency_converter'"));
    expect(currencySource, contains("'locale': _currentSupportLocale"));
    expect(currencySource, contains("'from_currency': _fromCurrency"));
    expect(currencySource, contains("'to_currency': _toCurrency"));
    expect(currencySource, contains("'amount': _amountController.text.trim()"));
  });
}
