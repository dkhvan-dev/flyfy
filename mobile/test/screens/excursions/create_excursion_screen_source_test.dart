import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'create excursion screen keeps a responsive three-step guide flow',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(source, contains('class CreateExcursionScreen'));
      expect(source, contains('PageView('));
      expect(source, contains('_ExcursionStepIndicator'));
      expect(source, contains('_buildStepLandmark'));
      expect(source, contains('_buildStepLogistics'));
      expect(source, contains('_buildStepStoryAndPrice'));
      expect(source, contains('_openLocationSelector'));
      expect(source, contains("context.push<ExcursionLocationSelection>"));
      expect(source, contains("'/excursions/create/location'"));
      expect(
        source,
        contains('landmarkId: isCombinedRoute ? null : _selectedLandmarkId'),
      );
      expect(source, contains('latitude: _selectedLatitude'));
      expect(source, contains('longitude: _selectedLongitude'));
      expect(source, contains('MediaQuery.viewInsetsOf(context).bottom'));
      expect(source, contains('ListView('));
      expect(source, isNot(contains('height: 500')));
    },
  );

  test(
    'create excursion clears keyboard focus before switching steps',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(source, contains('void _goToStep(int step)'));
      expect(
        source,
        contains('FocusManager.instance.primaryFocus?.unfocus();'),
      );
      expect(source, contains('_pageController.animateToPage('));
    },
  );

  test(
    'create excursion stepper marks completed steps with success color',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(source, contains('isDone'));
      expect(source, contains('? AppColors.success'));
      expect(source, contains('AppColors.success.withValues'));
      expect(source, contains('onStepTap'));
      expect(
        source,
        contains('final stepSize = isActive ? 48.0 : (isDone ? 40.0 : 34.0)'),
      );
    },
  );

  test(
    'create excursion visibility cards use the activity selected accent color',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(source, contains('class _VisibilityCard'));
      expect(
        source,
        contains(
          'color: selected ? AppColors.accent : const Color(0xFF3A2108)',
        ),
      );
      expect(
        source,
        contains('selected ? Colors.white : const Color(0xFFFFDEB6)'),
      );
    },
  );

  test(
    'create excursion form fields keep labels outside filled inputs',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(source, contains('class _ExcursionFieldShell'));
      expect(
        source,
        contains('floatingLabelBehavior: FloatingLabelBehavior.never'),
      );
      expect(source, contains('Text(label,'));
      expect(source, contains('fillColor: const Color(0xFF2D2115)'));
    },
  );

  test('create excursion uses a real map picker for meeting point', () async {
    final source = await File(
      'lib/screens/excursions/create_excursion_screen.dart',
    ).readAsString();

    expect(source, contains("package:flutter_map/flutter_map.dart"));
    expect(source, contains("package:latlong2/latlong.dart"));
    expect(source, contains("package:geocoding/geocoding.dart"));
    expect(source, contains('final MapController _mapController'));
    expect(source, contains('FlutterMap('));
    expect(source, contains('TileLayer('));
    expect(source, contains('MarkerLayer(markers: markers)'));
    expect(source, contains('_handleMapTapped'));
    expect(source, contains('_buildMapUrl'));
    expect(source, contains('_composeMeetingPointLabel'));
    expect(source, contains('placemarkFromCoordinates('));
    expect(source, contains('_meetingPointCtrl.text = address'));
  });

  test(
    'create excursion keeps long single-line fields horizontally scrollable',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(source, contains('horizontalScroll: true'));
      expect(source, contains('scrollPhysics: horizontalScroll'));
      expect(source, contains('final effectiveMaxLines = horizontalScroll'));
      expect(source, contains('label: l10n.createMeetingPointLocationLabel'));
      expect(source, contains('label: l10n.createMapLinkLabel'));
      expect(source, isNot(contains('label: l10n.createExcursionNameLabel')));
      expect(
        source,
        isNot(contains('label: l10n.createExcursionSummaryLabel')),
      );
      expect(source, isNot(contains('label: l10n.createTagsLabel')));
    },
  );

  test(
    'create excursion highlights story and price icons with accent color',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(source, contains('final effectiveIconColor'));
      expect(source, contains('iconColor: AppColors.accent'));
      expect(
        RegExp('iconColor: AppColors\\.accent').allMatches(source).length,
        greaterThanOrEqualTo(3),
      );
      expect(source, contains('label: l10n.createMeetingPointLocationLabel'));
      expect(source, contains('label: l10n.createMapLinkLabel'));
      expect(source, contains('label: l10n.createPriceAmountLabel'));
    },
  );

  test(
    'create excursion duration uses numeric input and localized unit picker',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(source, contains('_durationValueCtrl'));
      expect(source, contains("TextEditingController(text: '4')"));
      expect(source, contains('_selectedDurationUnit'));
      expect(source, contains('_ExcursionDurationUnit.hours'));
      expect(source, contains('enum _ExcursionDurationUnit'));
      expect(source, contains('class _DurationUnitPickerField'));
      expect(source, contains('_durationMinutesFromInput()'));
      expect(source, contains('createExcursionDurationUnitLabel'));
      expect(source, contains('createExcursionDurationUnitHours'));
      expect(source, isNot(contains("TextEditingController(text: '4 hours')")));
      expect(
        source,
        isNot(contains('_parseDurationMinutes(_durationCtrl.text)')),
      );
    },
  );

  test(
    'create excursion highlights logistics input icons with accent color',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(source, contains('icon: Icons.schedule_rounded'));
      expect(source, contains('icon: Icons.group_outlined'));
      expect(
        RegExp(
          r'Icons\.schedule_rounded,[\s\S]*?iconColor: AppColors\.accent',
        ).hasMatch(source),
        isTrue,
      );
      expect(
        RegExp(
          r'Icons\.group_outlined,[\s\S]*?iconColor: AppColors\.accent',
        ).hasMatch(source),
        isTrue,
      );
      expect(
        RegExp(
          r'Icons\.timelapse_rounded,[\s\S]*?color: AppColors\.accent',
        ).hasMatch(source),
        isTrue,
      );
      expect(
        RegExp(
          r'Icons\.keyboard_arrow_down_rounded,[\s\S]*?color: AppColors\.accent',
        ).hasMatch(source),
        isTrue,
      );
    },
  );

  test(
    'create excursion displays localized currency names and keeps currency codes',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();
      final pickerSource = await File(
        'lib/shared/widgets/app_currency_picker_field.dart',
      ).readAsString();

      expect(source, contains('AppCurrencyPickerField('));
      expect(source, isNot(contains('class _CurrencyOption')));
      expect(source, isNot(contains('class _CurrencyPickerField')));
      expect(pickerSource, contains('createCurrencyKzt'));
      expect(pickerSource, contains('createCurrencyUsd'));
      expect(source, contains('currency: _selectedCurrencyCode'));
      expect(source, contains("'KZT'"));
      expect(source, isNot(contains('controller: _currencyCtrl')));
    },
  );

  test(
    'edit excursion can resubmit draft or rejected offers after changes',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(source, contains('String? _editingExcursionStatus'));
      expect(source, contains('bool get _canSubmitEditedExcursionForReview'));
      expect(source, contains("status == 'DRAFT' || status == 'REJECTED'"));
      expect(
        source,
        contains('await provider.submitExcursionForPublishing(excursionId)'),
      );
      expect(source, contains('_submit(submitForReview: !_isEditMode)'));
      expect(source, contains('l10n.createExcursionSubmit'));
    },
  );

  test(
    'create excursion uses dictionary language picker capped at five languages',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(source, contains('static const int _maxExcursionLanguages = 5'));
      expect(source, contains('Set<String> _selectedLanguageCodes'));
      expect(source, contains('class _ExcursionLanguagePickerField'));
      expect(source, contains('_languageSearchController'));
      expect(source, contains('_handleLanguageSearchChanged'));
      expect(source, contains('_visibleLanguages(AppLocalizations l10n)'));
      expect(source, contains('_languageSearchHaystack('));
      expect(source, contains('createExcursionLanguagesSearchHint'));
      expect(source, contains('createExcursionLanguagesNoResults'));
      expect(source, contains('_ExcursionLanguageOptionRow'));
      expect(source, contains('TextField'));
      expect(source, contains('_toggleLanguageCode'));
      expect(
        source,
        contains('_selectedLanguageCodes.length >= _maxExcursionLanguages'),
      );
      expect(
        source,
        contains('createExcursionLanguagesPickerHint(maxSelected)'),
      );
      expect(source, contains('languageCodes: _selectedLanguageCodes.toList'));
      expect(source, isNot(contains('_languagesCtrl')));
    },
  );

  test(
    'create excursion selects included item types without free text',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(source, contains('class _ExcursionIncludedItemDraft'));
      expect(source, contains('class _ExcursionIncludedItemsEditorSheet'));
      expect(source, contains('enum _ExcursionIncludedItemType'));
      expect(source, contains('_openIncludedItemsEditor'));
      expect(
        source,
        contains('showModalBottomSheet<List<_ExcursionIncludedItemDraft>>'),
      );
      expect(source, contains('includedItems: _includedItems'));
      expect(source, contains('String toPayload() => type.name'));
      expect(source, contains('selectedTypes'));
      expect(source, isNot(contains('_includedItemsCtrl')));
      expect(source, isNot(contains('createExcursionIncludedItemsValueLabel')));
      expect(source, isNot(contains('TextEditingController(text: title)')));
    },
  );

  test(
    'create excursion starts with empty itinerary and lets guides delete any slot',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(
        source,
        contains('final List<_ExcursionItineraryDraft> _itinerary = [];'),
      );
      expect(source, contains('l10n.createExcursionItineraryEmpty'));
      expect(
        source,
        contains('onDelete: () => setState(() => _itinerary.remove(item))'),
      );
      expect(source, isNot(contains('Meet at base camp')));
      expect(source, isNot(contains('Mountain ascent and photography')));
      expect(source, isNot(contains('_itinerary.length == 1')));
    },
  );

  test(
    'create excursion validates itinerary description before submit',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(source, contains('_isCompleteItineraryDraft('));
      expect(source, contains("item.description.trim().length >= 5"));
      expect(source, contains('_validateAllStepsBeforeSubmit'));
      expect(source, contains('_isCompleteItineraryDraft(draft)'));
    },
  );

  test(
    'create excursion shows specific itinerary validation messages',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(source, contains('_minItinerarySlots = 2'));
      expect(source, contains('_itinerary.length < _minItinerarySlots'));
      expect(source, contains('createExcursionItineraryMinSlotsValidation'));
      expect(
        source,
        contains('createExcursionItineraryDescriptionMinLengthValidation'),
      );
      expect(source, contains('errorText: _descriptionErrorText'));
    },
  );

  test(
    'create excursion shows validation errors next to invalid fields',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      for (final fieldError in [
        '_countryErrorText',
        '_landmarkErrorText',
        '_itineraryErrorText',
        '_durationErrorText',
        '_groupSizeErrorText',
        '_languagesErrorText',
        '_meetingPointErrorText',
        '_priceErrorText',
        '_currencyErrorText',
      ]) {
        expect(source, contains(fieldError));
      }

      expect(source, contains('errorText: _durationErrorText'));
      expect(source, contains('errorText: _groupSizeErrorText'));
      expect(source, contains('errorText: _languagesErrorText'));
      expect(source, contains('errorText: _meetingPointErrorText'));
      expect(source, contains('errorText: _priceErrorText'));
      expect(source, contains('errorText: _currencyErrorText'));
      expect(source, contains('hasError: !_isCompleteItineraryDraft(item)'));
      expect(source, contains('errorText: _itineraryErrorText'));
      expect(
        source,
        contains('if (_stepErrorText != null && !_hasFieldValidationErrors)'),
      );
    },
  );

  test(
    'create excursion validates itinerary editor fields individually',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(source, contains('_offsetErrorText'));
      expect(source, contains('_titleErrorText'));
      expect(source, contains('createExcursionStartOffsetValidation'));
      expect(source, contains('createExcursionItineraryTitleValidation'));
      expect(source, contains('errorText: _offsetErrorText'));
      expect(source, contains('errorText: _titleErrorText'));
      expect(source, contains('errorText: _descriptionErrorText'));
    },
  );

  test('create excursion localizes itinerary offset labels', () async {
    final source = await File(
      'lib/screens/excursions/create_excursion_screen.dart',
    ).readAsString();
    final ruSource = await File('lib/l10n/app_ru.arb').readAsString();

    expect(source, contains('_formatOffset(context, item.startOffsetMinutes)'));
    expect(source, contains('createExcursionOffsetHoursShort'));
    expect(source, contains('createExcursionOffsetMinutesShort'));
    expect(source, contains('createExcursionOffsetHoursMinutesShort'));
    expect(ruSource, contains('"+{hours} ч"'));
  });

  test(
    'create excursion lets guides edit an added itinerary slot by tap',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(
        source,
        contains(
          'Future<void> _openItineraryEditor({_ExcursionItineraryDraft? item})',
        ),
      );
      expect(source, contains('initialItem: item'));
      expect(source, contains('_itinerary[itemIndex] = result'));
      expect(source, contains('onTap: () => _openItineraryEditor(item: item)'));
      expect(source, contains('final _ExcursionItineraryDraft? initialItem'));
    },
  );

  test(
    'create excursion can upload a custom cover or reuse selected attraction cover',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();
      final fileApiSource = await File(
        'lib/core/network/file_api.dart',
      ).readAsString();
      final selectorSource = await File(
        'lib/screens/excursions/excursion_select_location_screen.dart',
      ).readAsString();

      expect(source, contains('ImagePicker'));
      expect(source, contains('FileApi'));
      expect(source, contains('_pickCoverImage'));
      expect(source, contains('_effectiveCoverFileId'));
      expect(source, contains('coverFileId: _offerCoverFileId'));
      expect(source, contains('productCoverFileId: _productCoverFileId'));
      expect(source, contains('_selectedAttractionCoverFileId'));
      expect(source, contains('_selectedAttractionCoverImageUrl'));
      expect(source, contains('_ExcursionCoverUploadCard'));
      expect(fileApiSource, contains('createExcursionCoverUpload'));
      expect(fileApiSource, contains("purpose: 'EXCURSION_MEDIA'"));
      expect(selectorSource, contains('coverFileId'));
      expect(selectorSource, contains('coverImageUrl'));
      expect(selectorSource, contains('resolveAttractionMediaUrl'));
    },
  );

  test(
    'create excursion replaces custom cover when attraction is selected',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(source, contains('_replaceCustomCoverWithAttractionCover'));
      expect(source, contains('_coverPreviewBytes = null'));
      expect(source, contains('_coverFileId = null'));
      expect(source, contains('_coverChanged = false'));
      expect(source, contains('_coverUploadGeneration'));

      final selectorStart = source.indexOf(
        'Future<void> _openLocationSelector',
      );
      final selectorEnd = source.indexOf(
        'Future<void> _openItineraryEditor',
        selectorStart,
      );
      expect(selectorStart, isNonNegative);
      expect(selectorEnd, greaterThan(selectorStart));

      final selectorSource = source.substring(selectorStart, selectorEnd);
      expect(selectorSource, contains('_selectedAttractionCoverFileId ='));
      expect(
        selectorSource,
        contains('_replaceCustomCoverWithAttractionCover();'),
      );
    },
  );

  test('create excursion edit mode hides shared product-only blocks', () async {
    final source = await File(
      'lib/screens/excursions/create_excursion_screen.dart',
    ).readAsString();

    expect(source, contains('List<Widget> _visibleStepPages('));
    expect(source, contains('if (_isEditMode) {'));
    expect(source, contains('return ['));
    expect(source, contains('_buildStepOfferMediaAndItinerary'));
    expect(source, contains('_buildStepLogistics(l10n, bottomInset)'));
    expect(source, contains('_buildStepStoryAndPrice(l10n, bottomInset)'));
    expect(source, contains('_validateOfferMediaAndItineraryStep'));
    expect(source, contains('_validateEditStep'));
    expect(
      source,
      isNot(contains('_isEditMode ? _buildStepLandmark(l10n, bottomInset)')),
    );
  });

  test(
    'create excursion supports activity-like edge swipe to previous step',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(source, contains('_stepBackSwipeMinDistance'));
      expect(source, contains('_handleStepBackSwipeStart'));
      expect(source, contains('_handleStepBackSwipeUpdate'));
      expect(source, contains('_handleStepBackSwipeEnd'));
      expect(
        source,
        contains('onHorizontalDragStart: _handleStepBackSwipeStart'),
      );
      expect(source, contains('_goToStep(_currentStep - 1)'));
    },
  );

  test(
    'create excursion itinerary cards use unselected category color',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(source, contains('class _ItinerarySlotCard'));
      expect(source, contains('color: const Color(0xFF4A321D)'));
      expect(source, isNot(contains('color: const Color(0xFFF1E4D3)')));
    },
  );

  test(
    'create excursion uses country picker before attraction selection',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(source, contains('class _ExcursionCountryPickerField'));
      expect(source, contains('class _ExcursionCountryPickerSheet'));
      expect(source, contains('class _LandmarkSelectionCard'));
      expect(source, contains('_openCountryPicker'));
      expect(source, contains('String? _selectedCountryCode'));
      expect(source, contains('_hasSelectedCountry'));
      expect(source, contains('l10n.excursionSelectLocationAttractionSection'));
      expect(source, contains('context.push<ExcursionLocationSelection>'));
      expect(source, contains('countryCode: _selectedCountryCode!'));
      expect(source, contains('onSelectLocation:'));
      expect(source, contains('_openLocationSelector'));
      expect(source, isNot(contains('countryCodeController')));
      expect(source, isNot(contains('actionLabel: _hasSelectedCountry')));
      expect(source, isNot(contains('_isLocationEditingEnabled')));
      expect(source, isNot(contains('enabled: isEditable')));
      expect(source, isNot(contains('class _TransparentTextField')));
    },
  );

  test(
    'create excursion supports single attraction and combined route modes',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(source, contains('enum _ExcursionCreationMode'));
      expect(source, contains('singleAttraction'));
      expect(source, contains('combinedRoute'));
      expect(source, contains('_maxItineraryAttractionStops = 5'));
      expect(
        source,
        contains('_creationMode = _ExcursionCreationMode.singleAttraction'),
      );
      expect(source, contains('class _CreationModeSelector'));
      expect(source, contains('createExcursionSingleAttractionMode'));
      expect(source, contains('createExcursionCombinedRouteMode'));
      expect(source, contains('Wrap('));
      expect(source, contains('enableAttractionSelection: isCombinedRoute'));
      expect(source, contains('_openStopAttractionSelector'));
    },
  );

  test(
    'create excursion validates combined routes by attraction stop count',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(
        source,
        contains('_creationMode == _ExcursionCreationMode.singleAttraction'),
      );
      expect(
        source,
        contains('_creationMode == _ExcursionCreationMode.combinedRoute'),
      );
      expect(source, contains('_itineraryAttractionStopCount'));
      expect(
        source,
        contains('createExcursionCombinedRouteMinStopsValidation'),
      );
      expect(
        source,
        contains('createExcursionCombinedRouteMaxStopsValidation'),
      );
      expect(source, contains('_maxItineraryAttractionStops'));
      expect(
        source,
        isNot(
          contains('if (!_hasSelectedAttraction) {\n      _landmarkErrorText'),
        ),
      );
    },
  );

  test(
    'create excursion prevents duplicate combined route stops and locks selected stop title',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();
      final enSource = await File('lib/l10n/app_en.arb').readAsString();
      final ruSource = await File('lib/l10n/app_ru.arb').readAsString();

      expect(source, contains('reservedAttractionIds'));
      expect(source, contains('_reservedItineraryAttractionIds'));
      expect(source, contains('_isReservedAttraction'));
      expect(source, contains('createExcursionDuplicateRouteStopValidation'));
      expect(source, contains('readOnly: widget.enableAttractionSelection'));
      expect(source, contains('_titleCtrl.text = result.name.trim();'));
      expect(enSource, contains('createExcursionDuplicateRouteStopValidation'));
      expect(ruSource, contains('createExcursionDuplicateRouteStopValidation'));
    },
  );

  test(
    'create excursion hydrates edit mode route kind and itinerary stop snapshots',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(source, contains('excursion.routeKind'));
      expect(source, contains("'COMBINED_ROUTE'"));
      expect(source, contains('attractionId: item.attractionId'));
      expect(source, contains('attractionName: item.attractionName'));
      expect(source, contains('latitude: item.latitude'));
      expect(source, contains('longitude: item.longitude'));
      expect(
        source,
        contains('travelFromPreviousMinutes: item.travelFromPreviousMinutes'),
      );
      expect(source, contains('attractionId: _selectedAttractionId'));
      expect(source, contains('attractionName: _selectedAttractionName'));
      expect(source, contains('latitude: _selectedLatitude'));
      expect(source, contains('longitude: _selectedLongitude'));
    },
  );

  test(
    'create excursion serializes combined route requests without landmark id',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(source, contains('final isCombinedRoute ='));
      expect(
        source,
        contains('_creationMode == _ExcursionCreationMode.combinedRoute'),
      );
      expect(source, contains('landmarkName: isCombinedRoute ? null :'));
      expect(
        source,
        contains('landmarkId: isCombinedRoute ? null : _selectedLandmarkId'),
      );
      expect(
        source,
        contains('attractionId: isCombinedRoute ? item.attractionId : null'),
      );
      expect(
        source,
        contains(
          'attractionName: isCombinedRoute ? item.attractionName : null',
        ),
      );
      expect(
        source,
        contains('latitude: isCombinedRoute ? item.latitude : null'),
      );
      expect(
        source,
        contains('longitude: isCombinedRoute ? item.longitude : null'),
      );
      expect(source, contains('travelFromPreviousMinutes:'));
      expect(
        source,
        contains('isCombinedRoute ? item.travelFromPreviousMinutes : null'),
      );
      expect(source, contains('item.travelFromPreviousMinutes'));
    },
  );

  test('router exposes create excursion as an authenticated route', () async {
    final routerSource = await File(
      'lib/core/router/app_router.dart',
    ).readAsString();

    expect(routerSource, contains("path: '/excursions/create'"));
    expect(routerSource, contains('CreateExcursionScreen'));
    expect(routerSource, isNot(contains("location == '/excursions/create'")));
  });
}
