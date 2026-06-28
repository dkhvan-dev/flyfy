import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'create activity clears keyboard focus before switching steps',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();

      expect(
        source,
        contains('void _goToStep(int step, {bool animate = true})'),
      );
      expect(
        source,
        contains('FocusManager.instance.primaryFocus?.unfocus();'),
      );
      expect(source, contains('_pageController.animateToPage('));
    },
  );

  test(
    'create activity defers native map until location step settles',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();

      expect(source, contains('bool _isStepNativeMapEnabled(int step)'));
      expect(source, contains('_pendingProgrammaticStep == null'));
      expect(source, contains('nativeMapEnabled: _isStepNativeMapEnabled(1)'));
      expect(source, contains('if (_pendingProgrammaticStep != null) return;'));
    },
  );

  test(
    'create activity publish action relies on backend auto-publication',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();

      final submitAndPublishStart = source.indexOf(
        'Future<void> _submitAndPublish() async',
      );
      final sharedHelpersStart = source.indexOf(
        '// ── Shared field extraction helpers',
      );
      expect(submitAndPublishStart, isNonNegative);
      expect(sharedHelpersStart, greaterThan(submitAndPublishStart));

      final submitAndPublishSource = source.substring(
        submitAndPublishStart,
        sharedHelpersStart,
      );

      expect(submitAndPublishSource, contains('provider.createActivity('));
      expect(
        submitAndPublishSource,
        isNot(contains('provider.publishActivity(')),
      );
    },
  );

  test(
    'created activity is passed to details screen to avoid not found flash',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();

      expect(
        source,
        contains(
          "context.pushReplacement('/activities/\${created.id}', extra: created)",
        ),
      );
    },
  );

  test(
    'repeat mode resets copied schedule to a valid future default',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();

      final initStart = source.indexOf('void _applyInitialActivity');
      final initEnd = source.indexOf(
        '@override\n  void didChangeDependencies',
        initStart,
      );
      expect(initStart, isNonNegative);
      expect(initEnd, greaterThan(initStart));

      final initSource = source.substring(initStart, initEnd);
      expect(initSource, contains('if (widget.isRepeatMode)'));
      expect(initSource, contains('_startAt = _defaultStartAt();'));
      expect(initSource, contains('_endAt = _defaultEndAt(_startAt);'));
      expect(initSource, isNot(contains('_startAt = a.startAt.toLocal();')));
    },
  );

  test('create activity asks before discarding a dirty draft', () async {
    final source = await File(
      'lib/screens/activities/create_activity_screen.dart',
    ).readAsString();
    final enArb = await File('lib/l10n/app_en.arb').readAsString();
    final ruArb = await File('lib/l10n/app_ru.arb').readAsString();
    final kkArb = await File('lib/l10n/app_kk.arb').readAsString();

    expect(source, contains('bool get _hasUnsavedChanges'));
    expect(source, contains('Future<bool> _confirmDiscardIfNeeded()'));
    expect(source, contains('Future<void> _handleRouteBack()'));
    expect(source, contains('canPop: false'));
    expect(source, contains('l10n.createActivityDiscardTitle'));
    expect(source, contains('l10n.createActivityDiscardConfirm'));
    expect(enArb, contains('"createActivityDiscardTitle"'));
    expect(ruArb, contains('"createActivityDiscardTitle"'));
    expect(kkArb, contains('"createActivityDiscardTitle"'));
  });

  test(
    'create activity splits price amount and currency into separate fields',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();

      expect(source, contains('AppCurrencyPickerField('));
      expect(source, contains('selectedCode: _selectedCurrencyCode'));
      expect(source, contains('onChanged: _setSelectedCurrencyCode'));
      expect(source, isNot(contains('final _currencyCtrl')));
    },
  );

  test(
    'create activity requires map link before leaving location step',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();

      expect(source, contains('final requiresMapLink ='));
      expect(source, contains('required: requiresMapLink'));
      expect(source, contains('l10n.createMapLinkRequiredError'));
      expect(source, isNot(contains('final hasOfflineLocation =')));
      expect(source, isNot(contains('!hasOfflineLocation')));
    },
  );

  test(
    'map selection writes city and country before address into location input',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();

      expect(source, contains('formatLocationAddressLabel('));
      expect(source, contains('final resolvedAddress ='));
      expect(source, contains('_addressTextCtrl.text = resolvedAddress;'));
    },
  );

  test(
    'map selection localizes reverse geocoded address before filling input',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();

      final helperStart = source.indexOf(
        'Future<void> _resolveSelectedMapPointAddress',
      );
      final mapTapStart = source.indexOf('Future<void> _handleMapTapped');
      final buildStart = source.indexOf('@override', mapTapStart);
      expect(helperStart, isNonNegative);
      expect(mapTapStart, isNonNegative);
      expect(buildStart, greaterThan(mapTapStart));

      final mapTapSource = source.substring(mapTapStart, buildStart);
      final reverseGeocodingSource = source.substring(helperStart, buildStart);

      expect(mapTapSource, contains('_resolveSelectedMapPointAddress('));
      expect(reverseGeocodingSource, contains('setLocaleIdentifier('));
      expect(reverseGeocodingSource, contains('_resolveReferenceCity('));
      expect(
        reverseGeocodingSource,
        contains('_locationLabelResolver.resolveAddress('),
      );
      expect(
        reverseGeocodingSource,
        contains('_cityNameCtrl.text = localizedCityName'),
      );
      expect(
        reverseGeocodingSource,
        isNot(contains('final countryLabel = (placemark.country')),
      );
    },
  );

  test(
    'create activity uses shared MapLibre picker for meeting point',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();

      expect(source, contains("../../shared/map/app_map_links.dart"));
      expect(source, contains("../../shared/widgets/app_map_card.dart"));
      expect(source, contains("package:latlong2/latlong.dart"));
      expect(source, contains('AppMapCard('));
      expect(source, contains('onTap: _handleMapTapped'));
      expect(source, contains('AppMapLinks.buildUrl('));
      expect(source, contains('placemarkFromCoordinates('));
      expect(source, isNot(contains("package:flutter_map/flutter_map.dart")));
      expect(source, isNot(contains('final MapController _mapController')));
      expect(source, isNot(contains('FlutterMap(')));
      expect(source, isNot(contains('TileLayer(')));
      expect(source, isNot(contains('MarkerLayer(')));
      expect(source, isNot(contains('tile.openstreetmap.org')));
    },
  );

  test('create activity parses pasted map links into the shared map', () async {
    final source = await File(
      'lib/screens/activities/create_activity_screen.dart',
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
    expect(source, contains('_applyParsedMapPointAddress('));
    expect(source, contains('_addressTextCtrl.text = resolvedAddress;'));
    expect(source, contains('_setMapUrlText(_selectedMapUrl!)'));
    expect(source, contains('readOnly: true'));
    expect(source, contains('final requiresMapLink ='));
    expect(source, contains('required: requiresMapLink'));
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
    'step two location and meeting inputs are horizontally scrollable',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();

      final fieldStart = source.indexOf('class _Step2PillTextField');
      final nextFieldStart = source.indexOf('class _Step3LimitField');
      expect(fieldStart, isNonNegative);
      expect(nextFieldStart, greaterThan(fieldStart));

      final fieldSource = source.substring(fieldStart, nextFieldStart);
      expect(fieldSource, contains('maxLines: 1'));
      expect(
        fieldSource,
        contains('scrollPhysics: const BouncingScrollPhysics()'),
      );
    },
  );

  test('step one title input is horizontally scrollable', () async {
    final source = await File(
      'lib/screens/activities/create_activity_screen.dart',
    ).readAsString();

    final fieldStart = source.indexOf('class _Step1TextField');
    expect(fieldStart, isNonNegative);

    final fieldSource = source.substring(fieldStart);
    expect(fieldSource, contains('scrollPhysics:'));
    expect(fieldSource, contains('widget.isMultiline'));
    expect(fieldSource, contains('? null'));
    expect(fieldSource, contains(': const BouncingScrollPhysics()'));
  });

  test(
    'activity step transition matches excursion creation animation',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();

      final goToStepStart = source.indexOf(
        'void _goToStep(int step, {bool animate = true})',
      );
      final pageChangedStart = source.indexOf('void _handlePageChanged');
      expect(goToStepStart, isNonNegative);
      expect(pageChangedStart, greaterThan(goToStepStart));

      final goToStepSource = source.substring(goToStepStart, pageChangedStart);
      expect(
        goToStepSource,
        contains('duration: const Duration(milliseconds: 260)'),
      );
      expect(goToStepSource, contains('curve: Curves.easeOutCubic'));
    },
  );

  test(
    'activity step number buttons animate like excursion creation stepper',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();

      final indicatorStart = source.indexOf('class _StepIndicator');
      final step2NavStart = source.indexOf('class _Step2NavBar');
      expect(indicatorStart, isNonNegative);
      expect(step2NavStart, greaterThan(indicatorStart));

      final indicatorSource = source.substring(indicatorStart, step2NavStart);

      expect(indicatorSource, contains('final stepSize = isActive ? 48.0'));
      expect(indicatorSource, contains('child: AnimatedContainer('));
      expect(
        indicatorSource,
        contains('duration: const Duration(milliseconds: 180)'),
      );
      expect(indicatorSource, contains('alpha: 0.24'));
      expect(indicatorSource, contains('fontSize: isActive ? 20 : 15'));
    },
  );

  test('activity currency dropdown uses amount input surface color', () async {
    final source = await File(
      'lib/screens/activities/create_activity_screen.dart',
    ).readAsString();

    final currencyStart = source.indexOf('AppCurrencyPickerField(');
    final pricingSectionEnd = source.indexOf('if (_isPublished) ...[');
    expect(currencyStart, isNonNegative);
    expect(pricingSectionEnd, greaterThan(currencyStart));

    final currencySource = source.substring(currencyStart, pricingSectionEnd);
    expect(currencySource, contains('surfaceColor: AppPalette.warmSurface48'));
  });

  test(
    'activity price amount and currency fields are always vertical',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();

      final priceBuilderStart = source.indexOf(
        "if (_priceType != 'FREE') ...[",
      );
      final editRestrictionStart = source.indexOf('if (_isPublished) ...[');
      expect(priceBuilderStart, isNonNegative);
      expect(editRestrictionStart, greaterThan(priceBuilderStart));

      final priceBuilderSource = source.substring(
        priceBuilderStart,
        editRestrictionStart,
      );

      expect(priceBuilderSource, contains('Column('));
      expect(
        priceBuilderSource,
        contains('crossAxisAlignment: CrossAxisAlignment.stretch'),
      );
      expect(priceBuilderSource, contains('_Step3PriceField('));
      expect(priceBuilderSource, contains('AppCurrencyPickerField('));
      expect(priceBuilderSource, isNot(contains('return Row(')));
      expect(priceBuilderSource, isNot(contains('constraints.maxWidth < 360')));
    },
  );

  test(
    'create activity cover placeholder decorations scale with available space',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();

      final placeholderStart = source.indexOf(
        'Widget _buildPlaceholder({required bool hasPreview})',
      );
      final nextMethodStart = source.indexOf('@override', placeholderStart);
      expect(placeholderStart, isNonNegative);
      expect(nextMethodStart, greaterThan(placeholderStart));

      final placeholderSource = source.substring(
        placeholderStart,
        nextMethodStart,
      );
      expect(placeholderSource, contains('LayoutBuilder('));
      expect(placeholderSource, contains('constraints.biggest.shortestSide'));
      expect(placeholderSource, isNot(contains('width: 138')));
      expect(placeholderSource, isNot(contains('height: 138')));
      expect(placeholderSource, isNot(contains('width: 150')));
      expect(placeholderSource, isNot(contains('height: 150')));
    },
  );

  test(
    'create activity cover upload action label is width constrained',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();

      final copyStart = source.indexOf('class _CoverCardCopy');
      final borderStart = source.indexOf('class _DashedCoverBorderPainter');
      expect(copyStart, isNonNegative);
      expect(borderStart, greaterThan(copyStart));

      final copySource = source.substring(copyStart, borderStart);
      expect(copySource, contains('Flexible('));
      expect(copySource, contains('maxLines: 1'));
      expect(copySource, contains('overflow: TextOverflow.ellipsis'));
    },
  );

  test('create activity picker list height follows screen height', () async {
    final source = await File(
      'lib/screens/activities/create_activity_screen.dart',
    ).readAsString();

    final sheetStart = source.indexOf('class _CategoryPickerSheet');
    expect(sheetStart, isNonNegative);
    final sheetSource = source.substring(sheetStart);

    expect(sheetSource, contains('MediaQuery.sizeOf(context).height'));
    expect(sheetSource, isNot(contains('maxHeight: 360')));
  });

  test('edit activity locks meeting address one hour before start', () async {
    final source = await File(
      'lib/screens/activities/create_activity_screen.dart',
    ).readAsString();

    expect(source, contains('ActivityEditPolicy.canEditMeetingAddress('));
    expect(source, contains('startAt: _meetingAddressEditStartAt'));
    expect(source, contains('final locationLocked ='));
    expect(source, contains('showOffline && !_canEditMeetingAddress'));
  });

  test(
    'edit activity omits locked meeting address fields from update payload',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();

      final requestStart = source.indexOf(
        'UpdateActivityRequest _buildUpdateRequest()',
      );
      final publishStart = source.indexOf(
        'Future<void> _submitUpdateAndPublish',
        requestStart,
      );
      expect(requestStart, isNonNegative);
      expect(publishStart, greaterThan(requestStart));

      final requestSource = source.substring(requestStart, publishStart);

      expect(
        requestSource,
        contains('final canEditMeetingAddress = _canEditMeetingAddress;'),
      );
      expect(
        requestSource,
        contains(
          'countryCode: canEditMeetingAddress ? _countryCodeValue : null',
        ),
      );
      expect(requestSource, contains('hasCountryCode: canEditMeetingAddress'));
      expect(
        requestSource,
        contains(
          'addressText: canEditMeetingAddress ? _addressTextValue : null',
        ),
      );
      expect(requestSource, contains('hasAddressText: canEditMeetingAddress'));
      expect(
        requestSource,
        contains('mapUrl: canEditMeetingAddress ? _mapUrlValue : null'),
      );
      expect(requestSource, contains('hasMapUrl: canEditMeetingAddress'));
    },
  );

  test(
    'create and edit activity expose participant friend invite setting',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();
      final l10nSource = await File('lib/l10n/app_ru.arb').readAsString();

      expect(source, contains('bool _allowsParticipantInvites = false;'));
      expect(source, contains('_setAllowsParticipantInvites'));
      expect(source, contains('a.allowsParticipantInvites'));
      expect(
        source,
        contains('allowsParticipantInvites: _allowsParticipantInvites'),
      );
      expect(source, contains('createAllowParticipantInvitesLabel'));
      expect(source, contains('createAllowParticipantInvitesHint'));
      expect(l10nSource, contains('createAllowParticipantInvitesLabel'));
      expect(l10nSource, contains('createAllowParticipantInvitesHint'));
    },
  );

  test('activity private password accepts only english ascii input', () async {
    final source = await File(
      'lib/screens/activities/create_activity_screen.dart',
    ).readAsString();
    final l10nSource = await File('lib/l10n/app_ru.arb').readAsString();

    expect(source, contains('_activityPasswordInputFormatter'));
    expect(source, contains('RegExp(r\'[\\x20-\\x7E]\')'));
    expect(source, contains('_isActivityPasswordAscii'));
    expect(source, contains('inputFormatters: _activityPasswordFormatters'));
    expect(source, contains('createVisibilityPasswordAsciiValidation'));
    expect(l10nSource, contains('createVisibilityPasswordAsciiValidation'));
  });

  test(
    'create activity prefills meeting city from effective home location',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();

      expect(
        source,
        contains("import '../../providers/home_location_provider.dart';"),
      );
      expect(source, contains('_prefillAuthorLocationFromHomeLocation'));
      expect(source, contains('HomeLocationProvider'));
      expect(source, contains('provider.effectiveLocation'));
      expect(source, isNot(contains('provider.selectedLocation ??')));
      expect(source, contains('_authorLocationCountryCode'));
      expect(source, contains('_authorLocationCityId'));
      expect(source, contains('_authorLocationCityName'));
      expect(source, contains('_applyCountryAndCurrency(location.countryCode'));
      expect(source, contains('_selectedCityId = location.cityId'));
      expect(source, contains('_cityNameCtrl.text = location.cityName'));
      expect(source, contains('_didApplyAuthorLocationSnapshot'));
      expect(source, contains('authorCountryCode: _authorLocationCountryCode'));
      expect(source, contains('authorCityId: _authorLocationCityId'));
      expect(source, contains('authorCityName: _authorLocationCityName'));
    },
  );

  test(
    'create activity warns when meeting city differs from author location',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();
      final enSource = await File('lib/l10n/app_en.arb').readAsString();
      final ruSource = await File('lib/l10n/app_ru.arb').readAsString();
      final kkSource = await File('lib/l10n/app_kk.arb').readAsString();

      expect(
        source,
        contains('bool get _meetingLocationDiffersFromAuthorLocation'),
      );
      expect(
        source,
        contains('activityMeetingLocationDiffersFromAuthorLocation('),
      );
      expect(
        source,
        contains("features/activities/activity_location_mismatch"),
      );
      expect(source, contains('meetingCountryCode: _countryCodeCtrl.text'));
      expect(source, contains('meetingCityName: _cityNameCtrl.text'));
      expect(source, contains('createAuthorLocationMismatchHint'));
      expect(source, contains('_Step2LocationMismatchNotice('));
      expect(enSource, contains('"createAuthorLocationMismatchHint"'));
      expect(ruSource, contains('"createAuthorLocationMismatchHint"'));
      expect(kkSource, contains('"createAuthorLocationMismatchHint"'));
    },
  );

  test('category selector fields expose semantic button targets', () async {
    final source = await File(
      'lib/screens/activities/create_activity_screen.dart',
    ).readAsString();
    final selectorStart = source.indexOf('class _CategorySelectorField');
    final selectorEnd = source.indexOf('class _CoverUploadCard', selectorStart);

    expect(selectorStart, isNonNegative);
    expect(selectorEnd, greaterThan(selectorStart));

    final selectorSource = source.substring(selectorStart, selectorEnd);

    expect(selectorSource, contains('Semantics('));
    expect(selectorSource, contains('container: true'));
    expect(selectorSource, contains('button: true'));
    expect(selectorSource, contains('label: value'));
    expect(selectorSource, contains('onTap: onTap'));
    expect(selectorSource, contains('ExcludeSemantics('));
  });

  test('category picker options expose semantic button targets', () async {
    final source = await File(
      'lib/screens/activities/create_activity_screen.dart',
    ).readAsString();
    final pickerStart = source.indexOf('class _CategoryPickerSheetState');

    expect(pickerStart, isNonNegative);

    final pickerSource = source.substring(pickerStart);

    expect(pickerSource, contains('Semantics('));
    expect(pickerSource, contains('button: true'));
    expect(pickerSource, contains('label: entry.value'));
    expect(pickerSource, contains('onTap: selectItem'));
    expect(pickerSource, contains('ExcludeSemantics('));
  });
}
