import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'excursion location selector loads places and returns a selection',
    () async {
      final source = await File(
        'lib/screens/excursions/excursion_select_location_screen.dart',
      ).readAsString();

      expect(source, contains('class ExcursionSelectLocationScreen'));
      expect(source, contains('class ExcursionLocationSelection'));
      expect(source, contains('final String? cityId'));
      expect(source, contains('PlaceApi'));
      expect(source, contains('getPlaces('));
      expect(source, contains('context.pop<ExcursionLocationSelection>'));
      expect(source, contains('GridView.builder'));
      expect(source, contains('RefreshIndicator'));
    },
  );

  test('location selector receives country from create screen', () async {
    final source = await File(
      'lib/screens/excursions/excursion_select_location_screen.dart',
    ).readAsString();

    expect(source, contains('required this.countryCode'));
    expect(source, contains('final String countryCode'));
    expect(source, contains('_selectedCountryCode = widget.countryCode'));
    expect(source, contains('countryCode: _filters.countryCode'));
    expect(source, contains('_initialLocationFilter'));
    expect(source, contains('AppCountryFilterValue.fromParts'));
    expect(source, contains('AppCityFilterValue.fromParts'));
    expect(source, contains('cityId: initial.cityId'));
    expect(source, contains('cityName: initial.cityName'));
    expect(source, contains('_hasUsableInitialSelection'));
    expect(
      source,
      contains("import '../../core/ui/app_list_search_field.dart';"),
    );
    expect(source, isNot(contains('class _CountrySelector')));
    expect(source, isNot(contains('_countrySearchCtrl')));
    expect(source, isNot(contains('_selectCountry')));
    expect(source, isNot(contains('excursionSelectLocationCountrySection')));
  });

  test('location selector can be closed with an edge swipe', () async {
    final source = await File(
      'lib/screens/excursions/excursion_select_location_screen.dart',
    ).readAsString();

    expect(source, contains('_swipeCloseMinDistance'));
    expect(source, contains('_handleSwipeCloseStart'));
    expect(source, contains('_handleSwipeCloseEnd'));
    expect(source, contains('onHorizontalDragEnd: _handleSwipeCloseEnd'));
    expect(source, contains('Navigator.of(context).maybePop'));
  });

  test('location selector filter button opens place filters', () async {
    final source = await File(
      'lib/screens/excursions/excursion_select_location_screen.dart',
    ).readAsString();
    final filterSource = await File(
      'lib/screens/places/places_filter_sheet.dart',
    ).readAsString();

    expect(source, contains("import '../places/places_filter_sheet.dart';"));
    expect(source, contains('PlaceFilterResult _filters'));
    expect(source, contains('Future<void> _openFilters() async'));
    expect(source, contains('showAppModalBottomSheet<PlaceFilterResult>'));
    expect(source, contains('PlacesFilterSheet('));
    expect(source, contains('fallbackCountryCode: _selectedCountryCode'));
    expect(source, isNot(contains('accessCityId: widget.accessCityId')));
    expect(source, isNot(contains('widget.accessCityId')));
    expect(source, contains('AppListSearchField('));
    expect(source, contains('activeFilterCount: _filters.activeCount'));
    expect(source, contains('category: _filters.category'));
    expect(source, contains('minRating: _filters.minRating'));
    expect(source, contains('priceMin: _filters.priceMin'));
    expect(source, contains('durationMin: _filters.durationMin'));
    expect(source, contains('durationMax: _filters.durationMax'));
    expect(filterSource, contains('final String? fallbackCountryCode'));
    expect(filterSource, contains('final String? accessCityId'));
    expect(filterSource, contains('accessCityId: _normalizedAccessCityId()'));
    expect(filterSource, contains('_city = null;'));
  });

  test('location selector uses V2 colors only', () async {
    final source = await File(
      'lib/screens/excursions/excursion_select_location_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.themeFor(context)'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.screenGradientColors'));
    expect(source, contains('colors.surface'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test(
    'router exposes excursion location selection as an authenticated route',
    () async {
      final routerSource = await File(
        'lib/core/router/app_router.dart',
      ).readAsString();

      expect(routerSource, contains("path: '/excursions/create/location'"));
      expect(routerSource, contains('ExcursionSelectLocationScreen'));
      expect(routerSource, isNot(contains('accessCityId: args?.accessCityId')));
      expect(
        routerSource,
        isNot(contains("location == '/excursions/create/location'")),
      );
    },
  );
}
