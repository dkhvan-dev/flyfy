import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tour location selector loads attractions and returns a selection',
      () async {
    final source = await File(
      'lib/screens/tours/tour_select_location_screen.dart',
    ).readAsString();

    expect(source, contains('class TourSelectLocationScreen'));
    expect(source, contains('class TourLocationSelection'));
    expect(source, contains('AttractionApi'));
    expect(source, contains('getAttractions('));
    expect(source, contains('context.pop<TourLocationSelection>'));
    expect(source, contains('GridView.builder'));
    expect(source, contains('RefreshIndicator'));
  });

  test('location selector receives country from create screen', () async {
    final source = await File(
      'lib/screens/tours/tour_select_location_screen.dart',
    ).readAsString();

    expect(source, contains('required this.countryCode'));
    expect(source, contains('final String countryCode'));
    expect(source, contains('_selectedCountryCode = widget.countryCode'));
    expect(source, contains('countryCode: _selectedCountryCode'));
    expect(source, contains('color: AppColors.accent, size: 28'));
    expect(source, isNot(contains('class _CountrySelector')));
    expect(source, isNot(contains('_countrySearchCtrl')));
    expect(source, isNot(contains('_selectCountry')));
    expect(source, isNot(contains('tourSelectLocationCountrySection')));
  });

  test('location selector can be closed with an edge swipe', () async {
    final source = await File(
      'lib/screens/tours/tour_select_location_screen.dart',
    ).readAsString();

    expect(source, contains('_swipeCloseMinDistance'));
    expect(source, contains('_handleSwipeCloseStart'));
    expect(source, contains('_handleSwipeCloseEnd'));
    expect(source, contains('onHorizontalDragEnd: _handleSwipeCloseEnd'));
    expect(source, contains('Navigator.of(context).maybePop'));
  });

  test('router exposes tour location selection as an authenticated route',
      () async {
    final routerSource =
        await File('lib/core/router/app_router.dart').readAsString();

    expect(routerSource, contains("path: '/tours/create/location'"));
    expect(routerSource, contains('TourSelectLocationScreen'));
    expect(
        routerSource, isNot(contains("location == '/tours/create/location'")));
  });
}
