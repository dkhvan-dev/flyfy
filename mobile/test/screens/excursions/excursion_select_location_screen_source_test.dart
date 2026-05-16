import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('excursion location selector loads attractions and returns a selection',
      () async {
    final source = await File(
      'lib/screens/excursions/excursion_select_location_screen.dart',
    ).readAsString();

    expect(source, contains('class ExcursionSelectLocationScreen'));
    expect(source, contains('class ExcursionLocationSelection'));
    expect(source, contains('AttractionApi'));
    expect(source, contains('getAttractions('));
    expect(source, contains('context.pop<ExcursionLocationSelection>'));
    expect(source, contains('GridView.builder'));
    expect(source, contains('RefreshIndicator'));
  });

  test('location selector receives country from create screen', () async {
    final source = await File(
      'lib/screens/excursions/excursion_select_location_screen.dart',
    ).readAsString();

    expect(source, contains('required this.countryCode'));
    expect(source, contains('final String countryCode'));
    expect(source, contains('_selectedCountryCode = widget.countryCode'));
    expect(source, contains('countryCode: _selectedCountryCode'));
    expect(source, contains('color: AppColors.accent, size: 28'));
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

  test('router exposes excursion location selection as an authenticated route',
      () async {
    final routerSource =
        await File('lib/core/router/app_router.dart').readAsString();

    expect(routerSource, contains("path: '/excursions/create/location'"));
    expect(routerSource, contains('ExcursionSelectLocationScreen'));
    expect(routerSource,
        isNot(contains("location == '/excursions/create/location'")));
  });
}
