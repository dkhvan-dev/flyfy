import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('create tour screen keeps a responsive three-step guide flow', () async {
    final source = await File(
      'lib/screens/tours/create_tour_screen.dart',
    ).readAsString();

    expect(source, contains('class CreateTourScreen'));
    expect(source, contains('PageView('));
    expect(source, contains('_TourStepIndicator'));
    expect(source, contains('_buildStepLandmark'));
    expect(source, contains('_buildStepLogistics'));
    expect(source, contains('_buildStepStoryAndPrice'));
    expect(source, contains('_openLocationSelector'));
    expect(source, contains("context.push<TourLocationSelection>"));
    expect(source, contains("'/tours/create/location'"));
    expect(source, contains('landmarkId: _selectedLandmarkId'));
    expect(source, contains('latitude: _selectedLatitude'));
    expect(source, contains('longitude: _selectedLongitude'));
    expect(source, contains('MediaQuery.viewInsetsOf(context).bottom'));
    expect(source, contains('ListView('));
    expect(source, isNot(contains('height: 500')));
  });

  test('create tour stepper marks completed steps with success color',
      () async {
    final source = await File(
      'lib/screens/tours/create_tour_screen.dart',
    ).readAsString();

    expect(source, contains('isDone'));
    expect(source, contains('? AppColors.success'));
    expect(source, contains('AppColors.success.withValues'));
    expect(source, contains('onStepTap'));
    expect(
      source,
      contains('final stepSize = isActive ? 48.0 : (isDone ? 40.0 : 34.0)'),
    );
  });

  test('create tour visibility cards use the activity selected accent color',
      () async {
    final source = await File(
      'lib/screens/tours/create_tour_screen.dart',
    ).readAsString();

    expect(source, contains('class _VisibilityCard'));
    expect(
      source,
      contains('color: selected ? AppColors.accent : const Color(0xFF3A2108)'),
    );
    expect(
        source, contains('selected ? Colors.white : const Color(0xFFFFDEB6)'));
  });

  test('create tour form fields keep labels outside filled inputs', () async {
    final source = await File(
      'lib/screens/tours/create_tour_screen.dart',
    ).readAsString();

    expect(source, contains('class _TourFieldShell'));
    expect(
        source, contains('floatingLabelBehavior: FloatingLabelBehavior.never'));
    expect(source, contains('Text(label,'));
    expect(source, contains('fillColor: const Color(0xFF2D2115)'));
  });

  test('create tour uses a real map picker for meeting point', () async {
    final source = await File(
      'lib/screens/tours/create_tour_screen.dart',
    ).readAsString();

    expect(source, contains("package:flutter_map/flutter_map.dart"));
    expect(source, contains("package:latlong2/latlong.dart"));
    expect(source, contains('final MapController _mapController'));
    expect(source, contains('FlutterMap('));
    expect(source, contains('TileLayer('));
    expect(source, contains('MarkerLayer(markers: markers)'));
    expect(source, contains('_handleMapTapped'));
    expect(source, contains('_buildMapUrl'));
  });

  test('create tour displays localized currency names and keeps currency codes',
      () async {
    final source = await File(
      'lib/screens/tours/create_tour_screen.dart',
    ).readAsString();

    expect(source, contains('class _CurrencyOption'));
    expect(source, contains('class _CurrencyPickerField'));
    expect(source, contains('createCurrencyKzt'));
    expect(source, contains('createCurrencyUsd'));
    expect(source, contains('currency: _selectedCurrencyCode'));
    expect(source, contains("'KZT'"));
    expect(source, isNot(contains('controller: _currencyCtrl')));
  });

  test('create tour uses dictionary language picker capped at five languages',
      () async {
    final source = await File(
      'lib/screens/tours/create_tour_screen.dart',
    ).readAsString();

    expect(source, contains('static const int _maxTourLanguages = 5'));
    expect(source, contains('Set<String> _selectedLanguageCodes'));
    expect(source, contains('class _TourLanguagePickerField'));
    expect(source, contains('_toggleLanguageCode'));
    expect(
        source, contains('_selectedLanguageCodes.length >= _maxTourLanguages'));
    expect(source, contains('languageCodes: _selectedLanguageCodes.toList'));
    expect(source, isNot(contains('_languagesCtrl')));
  });

  test('create tour edits included items with typed entries instead of commas',
      () async {
    final source = await File(
      'lib/screens/tours/create_tour_screen.dart',
    ).readAsString();

    expect(source, contains('class _TourIncludedItemDraft'));
    expect(source, contains('class _TourIncludedItemsEditorSheet'));
    expect(source, contains('enum _TourIncludedItemType'));
    expect(source, contains('_openIncludedItemsEditor'));
    expect(
        source, contains('showModalBottomSheet<List<_TourIncludedItemDraft>>'));
    expect(source, contains('includedItems: _includedItems'));
    expect(source, isNot(contains('_includedItemsCtrl')));
  });

  test(
      'create tour can upload a custom cover or reuse selected attraction cover',
      () async {
    final source = await File(
      'lib/screens/tours/create_tour_screen.dart',
    ).readAsString();
    final fileApiSource =
        await File('lib/core/network/file_api.dart').readAsString();
    final selectorSource = await File(
      'lib/screens/tours/tour_select_location_screen.dart',
    ).readAsString();

    expect(source, contains('ImagePicker'));
    expect(source, contains('FileApi'));
    expect(source, contains('_pickCoverImage'));
    expect(source, contains('_effectiveCoverFileId'));
    expect(source, contains('coverFileId: _effectiveCoverFileId'));
    expect(source, contains('_selectedAttractionCoverFileId'));
    expect(source, contains('_selectedAttractionCoverImageUrl'));
    expect(source, contains('_TourCoverUploadCard'));
    expect(fileApiSource, contains('createTourCoverUpload'));
    expect(fileApiSource, contains("purpose: 'TOUR_MEDIA'"));
    expect(selectorSource, contains('coverFileId'));
    expect(selectorSource, contains('coverImageUrl'));
    expect(selectorSource, contains('resolveAttractionMediaUrl'));
  });

  test('create tour supports activity-like edge swipe to previous step',
      () async {
    final source = await File(
      'lib/screens/tours/create_tour_screen.dart',
    ).readAsString();

    expect(source, contains('_stepBackSwipeMinDistance'));
    expect(source, contains('_handleStepBackSwipeStart'));
    expect(source, contains('_handleStepBackSwipeUpdate'));
    expect(source, contains('_handleStepBackSwipeEnd'));
    expect(
        source, contains('onHorizontalDragStart: _handleStepBackSwipeStart'));
    expect(source, contains('_goToStep(_currentStep - 1)'));
  });

  test('create tour itinerary cards use unselected category color', () async {
    final source = await File(
      'lib/screens/tours/create_tour_screen.dart',
    ).readAsString();

    expect(source, contains('class _ItinerarySlotCard'));
    expect(source, contains('color: const Color(0xFF4A321D)'));
    expect(source, isNot(contains('color: const Color(0xFFF1E4D3)')));
  });

  test('create tour uses country picker before attraction selection', () async {
    final source = await File(
      'lib/screens/tours/create_tour_screen.dart',
    ).readAsString();

    expect(source, contains('class _TourCountryPickerField'));
    expect(source, contains('class _TourCountryPickerSheet'));
    expect(source, contains('_openCountryPicker'));
    expect(source, contains('String? _selectedCountryCode'));
    expect(source, contains('_hasSelectedCountry'));
    expect(source, contains('_isLocationEditingEnabled'));
    expect(source, contains('enabled: isEditable'));
    expect(source, contains('context.push<TourLocationSelection>'));
    expect(source, contains('countryCode: _selectedCountryCode!'));
    expect(source, contains('actionLabel: _hasSelectedCountry'));
    expect(source, isNot(contains('countryCodeController')));
  });

  test('router exposes create tour as an authenticated route', () async {
    final routerSource =
        await File('lib/core/router/app_router.dart').readAsString();

    expect(routerSource, contains("path: '/tours/create'"));
    expect(routerSource, contains('CreateTourScreen'));
    expect(routerSource, isNot(contains("location == '/tours/create'")));
  });
}
