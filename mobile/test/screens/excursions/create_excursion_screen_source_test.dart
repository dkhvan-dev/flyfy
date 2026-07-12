import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('create excursion screen uses adaptive V2 colors only', () async {
    final source = await File(
      'lib/screens/excursions/create_excursion_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('createExcursionColors.primary'));
    expect(source, contains('createExcursionColors.textPrimary'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test(
    'create and edit excursion shell uses shared V2 screen gradient',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      final stateStart = source.indexOf('class _CreateExcursionScreenState');
      final buildStart = source.indexOf(
        '@override\n  Widget build',
        stateStart,
      );
      final buildEnd = source.indexOf(
        '  Widget _buildStepOfferMediaAndItinerary',
        buildStart,
      );
      expect(stateStart, isNonNegative);
      expect(buildStart, isNonNegative);
      expect(buildEnd, greaterThan(buildStart));

      final shellSource = source.substring(buildStart, buildEnd);

      expect(source, contains('List<Color> get screenGradientColors'));
      expect(source, contains('colors.screenGradientColors'));
      expect(
        shellSource,
        contains('colors: context.createExcursionColors.screenGradientColors'),
      );
      expect(
        shellSource,
        contains('backgroundColor: context.createExcursionColors.background'),
      );
      expect(shellSource, isNot(contains('surfaceWarm,')));
      expect(shellSource, isNot(contains('backgroundWarm')));
    },
  );

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
      expect(source, contains("context.go('/profile/guide-dashboard')"));
      expect(source, isNot(contains("context.go('/')")));
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
    'create excursion defers native map until meeting point step settles',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(source, contains('int? _pendingProgrammaticStep;'));
      expect(source, contains('final Set<int> _nativeMapActivatedSteps'));
      expect(source, contains('bool _isStepNativeMapEnabled(int step)'));
      expect(source, contains('_pendingProgrammaticStep == null'));
      expect(source, contains('void _handlePageChanged(int step)'));
      expect(source, contains('onPageChanged: _handlePageChanged'));
      expect(
        source,
        contains(
          'nativeMapEnabled: _isStepNativeMapEnabled(_meetingPointStep)',
        ),
      );
      expect(source, contains('if (_pendingProgrammaticStep != null) return;'));
      expect(
        source,
        contains('_nativeMapActivatedSteps.add(_meetingPointStep);'),
      );
      expect(source, contains('_pendingProgrammaticStep = restoredStep;'));
    },
  );

  test('create excursion carousel allows up to ten photos', () async {
    final source = await File(
      'lib/screens/excursions/create_excursion_screen.dart',
    ).readAsString();

    expect(source, contains('static const int _maxExcursionPhotos = 10;'));
    expect(
      source,
      contains(
        'final availableSlots = _maxExcursionPhotos - _photoDrafts.length;',
      ),
    );
    expect(source, contains('pickedImages.take(availableSlots)'));
    expect(source, contains('maxPhotos: _maxExcursionPhotos'));
  });

  test(
    'create excursion loads effective device location before prefill',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(source, contains('Future<void> _applyHomeLocation()'));
      expect(source, contains('await provider.load('));
      expect(
        source,
        contains('languageCode: Localizations.localeOf(context).languageCode'),
      );
      expect(source, contains('provider.effectiveLocation'));
      expect(
        source,
        contains('location.source == HomeLocationSource.fallback'),
      );
      expect(
        source,
        isNot(
          contains(
            'final location = context.read<HomeLocationProvider>().effectiveLocation',
          ),
        ),
      );
    },
  );

  test(
    'create excursion stepper marks completed steps with success color',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(source, contains('isDone'));
      expect(source, contains('? context.createExcursionColors.success'));
      expect(
        RegExp(
          r'context\.createExcursionColors\.success\s*\.withValues',
        ).hasMatch(source),
        isTrue,
      );
      expect(source, contains('onStepTap'));
      expect(
        source,
        contains('final stepSize = isActive ? 48.0 : (isDone ? 40.0 : 34.0)'),
      );
    },
  );

  test(
    'create excursion header matches activity neutral header colors',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      final topBarStart = source.indexOf('class _ExcursionTopBar');
      final stepperStart = source.indexOf('class _ExcursionStepIndicator');
      final inlineErrorStart = source.indexOf(
        'class _InlineError',
        stepperStart,
      );
      expect(topBarStart, isNonNegative);
      expect(stepperStart, greaterThan(topBarStart));
      expect(inlineErrorStart, greaterThan(stepperStart));

      final topBarSource = source.substring(topBarStart, stepperStart);
      final stepperSource = source.substring(stepperStart, inlineErrorStart);

      expect(topBarSource, contains('MediaQuery.of(context)'));
      expect(topBarSource, contains('textPrimary'));
      expect(topBarSource, contains('titleSize'));
      expect(topBarSource, isNot(contains('createExcursionColors.primary')));
      expect(stepperSource, contains('border'));
      expect(stepperSource, contains('context.createExcursionColors.border'));
      expect(
        stepperSource,
        contains('context.createExcursionColors.orangeLight37'),
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
        RegExp(
          r'color:\s+selected\s+\?\s+context\.createExcursionColors\.primary\s+:\s+context\.createExcursionColors\.surfaceWarm',
        ).hasMatch(source),
        isTrue,
      );
      expect(
        RegExp(
          r'selected\s+\?\s+context\.createExcursionColors\.onPrimary\s+:\s+context\.createExcursionColors\.primary',
        ).hasMatch(source),
        isTrue,
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
      expect(RegExp(r'Text\(\s*label,').hasMatch(source), isTrue);
      expect(
        source,
        contains('fillColor: context.createExcursionColors.surfaceWarm'),
      );
    },
  );

  test(
    'create excursion uses shared MapLibre picker for meeting point',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(source, contains("../../shared/map/app_map_links.dart"));
      expect(source, contains("../../shared/widgets/app_map_card.dart"));
      expect(source, contains("package:latlong2/latlong.dart"));
      expect(source, contains("package:geocoding/geocoding.dart"));
      expect(source, contains("../map/map_screen.dart"));
      expect(source, contains('AppMapCard('));
      expect(source, contains('onTap: _handleMapTapped'));
      expect(source, contains('overlay: _MapExpandButton('));
      expect(source, contains('Icons.open_in_full_rounded'));
      expect(source, contains('Future<void> _openExpandedMeetingPointMap()'));
      expect(source, contains("context.push<MapTarget>"));
      expect(source, contains("'/map?mode=meeting-point-picker'"));
      expect(
        source,
        contains(
          '_handleMapTapped(result.point, meetingPointLabel: result.subtitle)',
        ),
      );
      expect(source, contains('Future<void> _handleMapTapped('));
      expect(source, contains('String? meetingPointLabel'));
      expect(source, contains('_handleMapTapped'));
      expect(source, contains('AppMapLinks.buildUrl('));
      expect(source, contains('_composeMeetingPointLabel'));
      expect(source, contains('placemarkFromCoordinates('));
      expect(source, contains('_meetingPointCtrl.text = address'));
      expect(source, contains('class _MapExpandButton'));
      expect(source, isNot(contains("package:flutter_map/flutter_map.dart")));
      expect(source, isNot(contains('final MapController _mapController')));
      expect(source, isNot(contains('FlutterMap(')));
      expect(source, isNot(contains('TileLayer(')));
      expect(source, isNot(contains('MarkerLayer(')));
      expect(source, isNot(contains('tile.openstreetmap.org')));
    },
  );

  test('create excursion parses pasted map links into the shared map', () async {
    final source = await File(
      'lib/screens/excursions/create_excursion_screen.dart',
    ).readAsString();
    final ruArb = await File('lib/l10n/app_ru.arb').readAsString();

    expect(source, contains('Timer? _mapUrlParseDebounce;'));
    expect(source, contains('_handleMapUrlTextChanged'));
    expect(source, contains('_applyParsedMapUrl'));
    expect(source, contains('AppMapLinks.normalizePastedMapLink(rawInput)'));
    expect(source, contains('AppMapLinks.normalizePastedMapLink(rawValue)'));
    expect(
      source,
      contains('AppMapLinks.tryParseCoordinates(normalizedRawValue)'),
    );
    expect(source, contains('AppMapLinkResolver'));
    expect(source, contains('AppMapLinkResolver.canResolveRemoteMapLink'));
    expect(
      source,
      contains('_mapLinkResolver.resolveCoordinates(normalizedRawValue)'),
    );
    expect(source, contains('_applyParsedMeetingPointAddress('));
    expect(source, contains('_meetingPointCtrl.text = address'));
    expect(source, contains('_setMapUrlText(normalizedUrl)'));
    expect(source, contains('_setMapUrlText(mapUrl)'));
    expect(source, contains('readOnly: true'));
    expect(source, contains('required: true'));
    expect(source, contains('l10n.createMapLinkRequiredError'));
    expect(source, contains('l10n.createMapEarlyStageNotice'));
    expect(source, contains('_mapUrlResolvingRawValue'));
    expect(source, contains('_mapUrlResolveFailedRawValue'));
    expect(source, contains('_mapUrlErrorText'));
    expect(source, contains('errorText: _mapUrlErrorText'));
    expect(source, contains('l10n.createMapLinkInvalidError'));
    expect(source, contains('l10n.createMapLinkRequiredError'));
    expect(source, contains('l10n.createMapLinkResolvingError'));
    expect(source, contains('return l10n.createMapLinkResolvingError;'));
    expect(
      ruArb,
      contains(
        '"createMapLinkInvalidError": "Не удалось определить координаты по ссылке. Выберите точку на нашей карте или вставьте ссылку с координатами из другой карты."',
      ),
    );
    expect(
      ruArb,
      contains(
        '"createMapLinkResolvingError": "Определяем координаты по ссылке. Подождите несколько секунд."',
      ),
    );
    expect(
      ruArb,
      contains(
        '"createMapLinkRequiredError": "Добавьте ссылку на карту или выберите точку на нашей карте."',
      ),
    );
    expect(ruArb, contains('"createMapEarlyStageNotice":'));
  });

  test(
    'create excursion does not use selected place as meeting point',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      final selectorStart = source.indexOf(
        'Future<void> _openLocationSelector() async',
      );
      final itineraryEditorStart = source.indexOf(
        'Future<void> _openItineraryEditor',
      );
      expect(selectorStart, isNonNegative);
      expect(itineraryEditorStart, greaterThan(selectorStart));

      final selectorSource = source.substring(
        selectorStart,
        itineraryEditorStart,
      );

      expect(source, contains('void _clearMeetingPointSelection()'));
      expect(selectorSource, contains('_clearMeetingPointSelection();'));
      expect(selectorSource, isNot(contains('latitude: _selectedLatitude,')));
      expect(selectorSource, isNot(contains('longitude: _selectedLongitude,')));
      expect(
        selectorSource,
        isNot(contains('mapUrl: _mapUrlCtrl.text.trim()')),
      );
      expect(
        selectorSource,
        isNot(contains('_selectedLatitude = result.latitude;')),
      );
      expect(
        selectorSource,
        isNot(contains('_selectedLongitude = result.longitude;')),
      );
      expect(selectorSource, isNot(contains('_setMapUrlText(result.mapUrl')));
      expect(
        selectorSource,
        isNot(contains('_setMapUrlText(_buildMapUrl(result.latitude!')),
      );
      expect(
        selectorSource,
        isNot(contains('_meetingPointCtrl.text = result.name')),
      );
    },
  );

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
      expect(
        source,
        contains('iconColor: context.createExcursionColors.primary'),
      );
      expect(
        RegExp(
          r'iconColor: context\.createExcursionColors\.primary',
        ).allMatches(source).length,
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

  test('create excursion highlights logistics input icons with accent color', () async {
    final source = await File(
      'lib/screens/excursions/create_excursion_screen.dart',
    ).readAsString();

    expect(source, contains('icon: Icons.schedule_rounded'));
    expect(source, contains('icon: Icons.group_outlined'));
    expect(
      RegExp(
        r'Icons\.schedule_rounded,[\s\S]*?iconColor: context\.createExcursionColors\.primary',
      ).hasMatch(source),
      isTrue,
    );
    expect(
      RegExp(
        r'Icons\.group_outlined,[\s\S]*?iconColor: context\.createExcursionColors\.primary',
      ).hasMatch(source),
      isTrue,
    );
    expect(
      RegExp(
        r'Icons\.timelapse_rounded,[\s\S]*?color: context\.createExcursionColors\.primary',
      ).hasMatch(source),
      isTrue,
    );
    expect(
      RegExp(
        r'Icons\.keyboard_arrow_down_rounded,[\s\S]*?color: context\.createExcursionColors\.primary',
      ).hasMatch(source),
      isTrue,
    );
  });

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
      expect(source, isNot(contains('extendSheetToBottom')));
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
    'create excursion itinerary editor constrains itself above the keyboard',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      final sheetStart = source.indexOf('class _AddItinerarySlotSheet');
      expect(sheetStart, isNonNegative);

      final sheetSource = source.substring(sheetStart);

      expect(source, contains('double _modalMaxHeightAboveKeyboard('));
      expect(sheetSource, contains('LayoutBuilder('));
      expect(sheetSource, contains('_modalMaxHeightAboveKeyboard(context)'));
      expect(sheetSource, contains('ConstrainedBox('));
      expect(sheetSource, contains('SingleChildScrollView('));
      expect(sheetSource, isNot(contains('16 + bottomInset')));
      expect(
        sheetSource,
        isNot(
          contains(
            'final bottomInset = MediaQuery.viewInsetsOf(context).bottom',
          ),
        ),
      );
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
        contains('showAppModalBottomSheet<List<_ExcursionIncludedItemDraft>>'),
      );
      expect(source, contains('includedItems: _includedItems'));
      expect(source, contains('String toPayload() => type.payloadKey'));
      expect(source, contains('_ExcursionIncludedItemType.accommodation'));
      expect(source, contains('_ExcursionIncludedItemType.permitsFees'));
      expect(source, contains('ExcursionIncludedItemKey.isDeprecated(value)'));
      expect(source, isNot(contains('_ExcursionIncludedItemType.guide')));
      expect(source, isNot(contains('_ExcursionIncludedItemType.photo')));
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
      expect(source, contains('setState(() => _itinerary.remove(item));'));
      expect(source, contains('_scheduleAutosave();'));
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
    'create excursion itinerary slot sheet uses full device width',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      final sheetStart = source.indexOf('class _AddItinerarySlotSheet');
      final sheetEnd = source.length;
      expect(sheetStart, isNonNegative);
      expect(sheetEnd, greaterThan(sheetStart));

      final sheetSource = source.substring(sheetStart, sheetEnd);
      expect(source, isNot(contains('extendToBottom')));
      expect(sheetSource, contains('width: double.infinity'));
      expect(
        sheetSource,
        isNot(contains('MediaQuery.viewPaddingOf(context).bottom')),
      );
      expect(sheetSource, isNot(contains('systemBottomPadding')));
      expect(
        sheetSource,
        contains('const AppEdgeInsets.fromLTRB(18, 18, 18, 34)'),
      );
      expect(sheetSource, contains('AppBorderRadius.vertical('));
      expect(sheetSource, contains("'excursion-itinerary-slot-confirm'"));
      expect(
        sheetSource,
        isNot(contains('padding: const AppEdgeInsets.fromLTRB(16, 0, 16, 16)')),
      );
      expect(
        sheetSource,
        isNot(contains('padding: const AppEdgeInsets.only(bottom: 16)')),
      );
    },
  );

  test(
    'create excursion can upload a custom cover or reuse selected place cover',
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
      expect(source, contains('_selectedPlaceCoverFileId'));
      expect(source, contains('_selectedPlaceCoverImageUrl'));
      expect(source, contains('_ExcursionCoverUploadCard'));
      expect(fileApiSource, contains('createExcursionCoverUpload'));
      expect(fileApiSource, contains("purpose: 'EXCURSION_MEDIA'"));
      expect(selectorSource, contains('coverFileId'));
      expect(selectorSource, contains('coverImageUrl'));
      expect(selectorSource, contains('resolvePlaceMediaUrl'));
    },
  );

  test(
    'create excursion helper route and cover upload hints use secondary accents',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      final coverStart = source.indexOf('class _ExcursionCoverUploadCard');
      final coverEnd = source.indexOf(
        'class _DashedExcursionCoverBorderPainter',
        coverStart,
      );
      final emptyStart = source.indexOf('class _ItineraryEmptyState');
      final emptyEnd = source.indexOf('class _ItinerarySlotCard', emptyStart);
      final actionBarStart = source.indexOf('class _ExcursionBottomActionBar');

      expect(coverStart, isNonNegative);
      expect(coverEnd, greaterThan(coverStart));
      expect(emptyStart, isNonNegative);
      expect(emptyEnd, greaterThan(emptyStart));
      expect(actionBarStart, isNonNegative);

      final coverSource = source.substring(coverStart, coverEnd);
      final emptySource = source.substring(emptyStart, emptyEnd);
      final actionBarSource = source.substring(actionBarStart);

      expect(coverSource, contains('context.createExcursionColors.secondary'));
      expect(
        coverSource,
        contains('context.createExcursionColors.secondaryContainer'),
      );
      expect(
        coverSource,
        isNot(contains('context.createExcursionColors.primary.withValues')),
      );
      expect(emptySource, contains('context.createExcursionColors.secondary'));
      expect(
        emptySource,
        contains('context.createExcursionColors.secondaryContainer'),
      );
      expect(
        emptySource,
        isNot(contains('color: context.createExcursionColors.primary')),
      );
      expect(
        actionBarSource,
        contains('backgroundColor: context.createExcursionColors.primary'),
      );
    },
  );

  test(
    'location and empty cover cards stay light without inner dimming',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      final landmarkStart = source.indexOf('class _LandmarkSelectionCard');
      final landmarkEnd = source.indexOf(
        'class _ExcursionPhotoDraft',
        landmarkStart,
      );
      final coverStart = source.indexOf('class _ExcursionCoverUploadCard');
      final coverEnd = source.indexOf(
        'class _DashedExcursionCoverBorderPainter',
        coverStart,
      );
      expect(landmarkStart, isNonNegative);
      expect(landmarkEnd, greaterThan(landmarkStart));
      expect(coverStart, isNonNegative);
      expect(coverEnd, greaterThan(coverStart));

      final landmarkSource = source.substring(landmarkStart, landmarkEnd);
      final coverSource = source.substring(coverStart, coverEnd);

      expect(
        landmarkSource,
        contains('Theme.of(context).brightness == Brightness.light'),
      );
      expect(landmarkSource, contains('color: isLightTheme'));
      expect(landmarkSource, contains('gradient: isLightTheme'));
      expect(landmarkSource, contains('alpha: isLightTheme ? 0.08 : 0.24'));
      expect(coverSource, contains('if (hasPreview || !isLightTheme)'));
      expect(coverSource, contains('final isLightPlaceholder ='));
      expect(
        coverSource,
        contains('context.createExcursionColors.textSecondary'),
      );
    },
  );

  test(
    'create excursion replaces custom cover when place is selected',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(source, contains('_replaceCustomCoverWithPlaceCover'));
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
      expect(selectorSource, contains('_selectedPlaceCoverFileId ='));
      expect(selectorSource, contains('_replaceCustomCoverWithPlaceCover();'));
    },
  );

  test(
    'create excursion cover copy truncates to avoid horizontal overflow',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      final copyStart = source.indexOf('class _ExcursionCoverCardCopy');
      final borderStart = source.indexOf(
        'class _DashedExcursionCoverBorderPainter',
        copyStart,
      );
      expect(copyStart, isNonNegative);
      expect(borderStart, greaterThan(copyStart));

      final copySource = source.substring(copyStart, borderStart);
      expect(copySource, contains('ConstrainedBox('));
      expect(copySource, contains('Flexible('));
      expect(copySource, contains('maxLines: 1'));
      expect(copySource, contains('overflow: TextOverflow.ellipsis'));
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
      final cardStart = source.indexOf('class _ItinerarySlotCard');
      final cardEnd = source.indexOf('class _OutlineActionButton', cardStart);

      expect(cardStart, isNonNegative);
      expect(cardEnd, greaterThan(cardStart));

      final cardSource = source.substring(cardStart, cardEnd);

      expect(
        cardSource,
        contains('color: context.createExcursionColors.surfaceHigh'),
      );
      expect(cardSource, contains('context.createExcursionColors.borderSoft'));
      expect(cardSource, contains('context.createExcursionColors.textPrimary'));
      expect(
        cardSource,
        contains('context.createExcursionColors.textSecondary'),
      );
      expect(
        cardSource,
        isNot(contains('color: context.createExcursionColors.primarySoft')),
      );
      expect(
        cardSource,
        isNot(contains('color: context.createExcursionColors.white')),
      );
    },
  );

  test(
    'create excursion included items sheet is full-width and readable',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      final sheetStart = source.indexOf(
        'class _ExcursionIncludedItemsEditorSheet',
      );
      final dialogStart = source.indexOf(
        'class _ExcursionAmberConfirmDialog',
        sheetStart,
      );
      expect(sheetStart, isNonNegative);
      expect(dialogStart, greaterThan(sheetStart));

      final sheetSource = source.substring(sheetStart, dialogStart);

      expect(sheetSource, contains('AppModalSheetFrame('));
      expect(
        sheetSource,
        contains('onTapOutside: () => Navigator.of(context).maybePop()'),
      );
      expect(sheetSource, contains('width: double.infinity'));
      expect(sheetSource, contains('context.createExcursionColors.surface'));
      expect(sheetSource, contains('context.createExcursionColors.borderSoft'));
      expect(
        sheetSource,
        contains('context.createExcursionColors.textPrimary'),
      );
      expect(sheetSource, contains('context.createExcursionColors.textMuted'));
      expect(
        sheetSource,
        isNot(contains('MediaQuery.viewPaddingOf(context).bottom')),
      );
      expect(sheetSource, isNot(contains('systemBottomPadding')));
      expect(
        sheetSource,
        contains('const AppEdgeInsets.fromLTRB(16, 0, 16, 16)'),
      );
      expect(sheetSource, isNot(contains('left: 16')));
      expect(sheetSource, isNot(contains('right: 16')));

      final openEditorStart = source.indexOf(
        'Future<void> _openIncludedItemsEditor()',
      );
      final uniqueItemsStart = source.indexOf(
        'List<_ExcursionIncludedItemDraft> _uniqueIncludedItemDrafts',
        openEditorStart,
      );
      expect(openEditorStart, isNonNegative);
      expect(uniqueItemsStart, greaterThan(openEditorStart));
      final openEditorSource = source.substring(
        openEditorStart,
        uniqueItemsStart,
      );
      expect(openEditorSource, isNot(contains('extendToBottom')));
    },
  );

  test(
    'create excursion opens place selector without a country picker',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(source, contains('class _LandmarkSelectionCard'));
      expect(source, contains('String? _selectedCountryCode'));
      expect(source, contains('l10n.excursionSelectLocationPlaceSection'));
      expect(source, contains('context.push<ExcursionLocationSelection>'));
      expect(source, contains("countryCode: _selectedCountryCode ?? ''"));
      expect(source, contains('onSelectLocation:'));
      expect(source, contains('_openLocationSelector'));
      expect(source, contains('cityId: _departureCityId'));
      expect(source, contains('cityName: _cityNameCtrl.text.trim()'));
      expect(source, isNot(contains('accessCityId: _departureCityId')));
      expect(source, isNot(contains('class _ExcursionCountryPickerField')));
      expect(source, isNot(contains('class _ExcursionCountryPickerSheet')));
      expect(source, isNot(contains('_openCountryPicker')));
      expect(source, isNot(contains('AppCountryFilterSection')));
      expect(source, isNot(contains('const excursionCountryOptions')));
      expect(source, isNot(contains('ExcursionCountryOption')));
      expect(source, isNot(contains('countryCodeController')));
      expect(source, isNot(contains('actionLabel: _hasSelectedCountry')));
      expect(source, isNot(contains('_isLocationEditingEnabled')));
      expect(source, isNot(contains('enabled: isEditable')));
      expect(source, isNot(contains('class _TransparentTextField')));
    },
  );

  test(
    'create excursion supports single place and combined route modes',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(source, contains('enum _ExcursionCreationMode'));
      expect(source, contains('singlePlace'));
      expect(source, contains('combinedRoute'));
      expect(source, contains('_maxItineraryPlaceStops = 5'));
      expect(
        source,
        contains('_creationMode = _ExcursionCreationMode.singlePlace'),
      );
      expect(source, contains('class _CreationModeSelector'));
      expect(source, contains('createExcursionSinglePlaceMode'));
      expect(source, contains('createExcursionCombinedRouteMode'));
      expect(source, contains('Wrap('));
      expect(source, contains('enablePlaceSelection: isCombinedRoute'));
      expect(source, contains('_openStopPlaceSelector'));
    },
  );

  test(
    'create excursion confirms mode switch and clears only mode-specific draft',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();
      final enSource = await File('lib/l10n/app_en.arb').readAsString();
      final ruSource = await File('lib/l10n/app_ru.arb').readAsString();
      final kkSource = await File('lib/l10n/app_kk.arb').readAsString();

      expect(source, contains('_selectCreationModeWithConfirmation'));
      expect(source, contains('_confirmCreationModeChangeIfNeeded'));
      expect(source, contains('_hasCreationModeSpecificDraft'));
      expect(source, contains('_clearModeSpecificDraft'));
      expect(source, contains('_clearSinglePlaceModeDraft'));
      expect(source, contains('_clearCombinedRouteModeDraft'));
      expect(source, contains('l10n.createExcursionModeSwitchTitle'));
      expect(source, contains('l10n.createExcursionModeSwitchConfirm'));
      expect(source, contains('_ExcursionAmberConfirmDialog'));
      expect(enSource, contains('"createExcursionModeSwitchTitle"'));
      expect(ruSource, contains('"createExcursionModeSwitchTitle"'));
      expect(kkSource, contains('"createExcursionModeSwitchTitle"'));
    },
  );

  test(
    'create excursion validates combined routes by place stop count',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();

      expect(
        source,
        contains('_creationMode == _ExcursionCreationMode.singlePlace'),
      );
      expect(
        source,
        contains('_creationMode == _ExcursionCreationMode.combinedRoute'),
      );
      expect(source, contains('_itineraryPlaceStopCount'));
      expect(
        source,
        contains('createExcursionCombinedRouteMinStopsValidation'),
      );
      expect(
        source,
        contains('createExcursionCombinedRouteMaxStopsValidation'),
      );
      expect(source, contains('_maxItineraryPlaceStops'));
      expect(
        source,
        isNot(contains('if (!_hasSelectedPlace) {\n      _landmarkErrorText')),
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

      expect(source, contains('reservedPlaceIds'));
      expect(source, contains('_reservedItineraryPlaceIds'));
      expect(source, contains('_isReservedPlace'));
      expect(source, contains('createExcursionDuplicateRouteStopValidation'));
      expect(
        RegExp(
          r"readOnly:\s*widget\.enablePlaceSelection\s*&&\s*\(_selectedPlaceId \?\? ''\)\.trim\(\)\.isNotEmpty",
        ).hasMatch(source),
        isTrue,
      );
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
      expect(source, contains('placeId: item.placeId'));
      expect(source, contains('placeName: item.placeName'));
      expect(source, contains('latitude: item.latitude'));
      expect(source, contains('longitude: item.longitude'));
      expect(
        source,
        contains('travelFromPreviousMinutes: item.travelFromPreviousMinutes'),
      );
      expect(source, contains('placeId: _selectedPlaceId'));
      expect(source, contains('placeName: _selectedPlaceName'));
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
        RegExp(
          r'landmarkId:\s*isCombinedRoute\s*\?\s*null\s*:\s*_selectedLandmarkId',
        ).hasMatch(source),
        isTrue,
      );
      expect(
        RegExp(
          r'placeId:\s*isCombinedRoute\s*\?\s*item\.placeId\s*:\s*null',
        ).hasMatch(source),
        isTrue,
      );
      expect(
        RegExp(
          r'placeName:\s*isCombinedRoute\s*\?\s*item\.placeName\s*:\s*null',
        ).hasMatch(source),
        isTrue,
      );
      expect(
        RegExp(
          r'latitude:\s*isCombinedRoute\s*\?\s*item\.latitude\s*:\s*null',
        ).hasMatch(source),
        isTrue,
      );
      expect(
        RegExp(
          r'longitude:\s*isCombinedRoute\s*\?\s*item\.longitude\s*:\s*null',
        ).hasMatch(source),
        isTrue,
      );
      expect(source, contains('travelFromPreviousMinutes:'));
      expect(
        RegExp(
          r'isCombinedRoute\s*\?\s*item\.travelFromPreviousMinutes\s*:\s*null',
        ).hasMatch(source),
        isTrue,
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

  test('create excursion autosaves and restores local draft fields', () async {
    final source = await File(
      'lib/screens/excursions/create_excursion_screen.dart',
    ).readAsString();
    final enSource = await File('lib/l10n/app_en.arb').readAsString();
    final ruSource = await File('lib/l10n/app_ru.arb').readAsString();
    final kkSource = await File('lib/l10n/app_kk.arb').readAsString();

    expect(source, contains('SharedPreferences'));
    expect(source, contains('_autosaveKey'));
    expect(source, contains('Timer? _autosaveDebounce'));
    expect(source, contains('Future<void> _restoreAutosaveDraft()'));
    expect(source, contains('Future<void> _persistAutosaveDraft()'));
    expect(source, contains('Future<void> _clearAutosaveDraft()'));
    expect(source, contains('_attachAutosaveListeners()'));
    expect(source, contains('_scheduleAutosave()'));
    expect(source, contains('_autosaveDraftPayload()'));
    expect(source, contains('_applyAutosaveDraftPayload'));
    expect(source, contains("'serverDraftId': _serverDraftId"));
    expect(source, contains("draft['serverDraftId']"));
    expect(source, contains('_rememberServerDraft(draftId)'));
    expect(source, contains('hasActiveExcursionForPlaceConflict'));
    expect(source, contains('findActiveExcursionForCreateRequest'));
    expect(source, contains('createExcursionAutosaveRestored'));
    expect(enSource, contains('"createExcursionAutosaveRestored"'));
    expect(ruSource, contains('"createExcursionAutosaveRestored"'));
    expect(kkSource, contains('"createExcursionAutosaveRestored"'));
  });

  test(
    'create excursion confirms discard and clears autosave on route exit',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();
      final enSource = await File('lib/l10n/app_en.arb').readAsString();
      final ruSource = await File('lib/l10n/app_ru.arb').readAsString();
      final kkSource = await File('lib/l10n/app_kk.arb').readAsString();

      expect(source, contains('Future<void> _handleRouteBack()'));
      expect(source, contains('void _handleRoutePopInvoked(bool didPop)'));
      expect(source, contains('bool get _hasUnsavedChanges'));
      expect(source, contains('Future<bool> _confirmDiscardIfNeeded()'));
      expect(source, contains('await _clearAutosaveDraft();'));
      expect(source, contains('canPop: false'));
      expect(source, contains('onBack: () => unawaited(_handleRouteBack())'));
      expect(source, contains('_ExcursionAmberConfirmDialog'));
      expect(source, contains('Icons.warning_amber_rounded'));
      expect(source, contains('l10n.createExcursionDiscardTitle'));
      expect(source, contains('l10n.createExcursionDiscardConfirm'));
      expect(source, contains('context.createExcursionColors.orangeWash23'));
      expect(source, contains('context.createExcursionColors.orangeLight13'));
      expect(source, contains('context.createExcursionColors.orangeLight29'));
      expect(source, contains('context.createExcursionColors.warmSurface81'));
      expect(source, contains('context.createExcursionColors.textOnInverse'));
      expect(ruSource, contains('"createExcursionDiscardConfirm": "Выйти"'));
      expect(enSource, contains('"createExcursionDiscardTitle"'));
      expect(ruSource, contains('"createExcursionDiscardTitle"'));
      expect(kkSource, contains('"createExcursionDiscardTitle"'));
    },
  );

  test(
    'next-step arrow is rendered after the excursion button label',
    () async {
      final source = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();
      final actionStart = source.indexOf('class _ExcursionBottomActionBar');
      final actionEnd = source.indexOf(
        'class _AddItinerarySlotSheet',
        actionStart,
      );

      expect(actionStart, isNonNegative);
      expect(actionEnd, greaterThan(actionStart));

      final actionSource = source.substring(actionStart, actionEnd);
      final labelIndex = actionSource.indexOf(
        'Text(\n                            label,',
      );
      final arrowIndex = actionSource.indexOf(
        'const Icon(Icons.arrow_forward_rounded)',
      );

      expect(actionSource, contains('child: FilledButton('));
      expect(actionSource, isNot(contains('child: FilledButton.icon(')));
      expect(labelIndex, isNonNegative);
      expect(arrowIndex, greaterThan(labelIndex));
    },
  );
}
