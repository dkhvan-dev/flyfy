import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('create activity screen uses adaptive V2 colors only', () async {
    final source = await File(
      'lib/screens/activities/create_activity_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('createActivityColors.primary'));
    expect(source, contains('createActivityColors.textPrimary'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test(
    'create and edit activity shell uses shared V2 screen gradient',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();

      final stateStart = source.indexOf('class _CreateActivityScreenState');
      final buildStart = source.indexOf(
        '@override\n  Widget build',
        stateStart,
      );
      final buildEnd = source.indexOf('  // ── Step 1', buildStart);
      expect(stateStart, isNonNegative);
      expect(buildStart, isNonNegative);
      expect(buildEnd, greaterThan(buildStart));

      final shellSource = source.substring(buildStart, buildEnd);

      expect(source, contains('List<Color> get screenGradientColors'));
      expect(source, contains('colors.screenGradientColors'));
      expect(
        shellSource,
        contains('colors: context.createActivityColors.screenGradientColors'),
      );
      expect(
        shellSource,
        contains('backgroundColor: context.createActivityColors.background'),
      );
      expect(
        shellSource,
        isNot(contains('context.createActivityColors.backgroundWarm,')),
      );
      expect(shellSource, isNot(contains('warmSurface19')));
    },
  );

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
    expect(source, contains('_showActivityAmberConfirmDialog'));
    expect(source, contains('_ActivityAmberConfirmDialog'));
    expect(source, contains('Icons.warning_amber_rounded'));
    expect(source, isNot(contains('barrierDismissible: false')));
    expect(source, contains('cancelLabel: l10n.cancelButton'));
    expect(source, contains('confirmLabel: l10n.createActivityDiscardConfirm'));
    expect(source, contains('l10n.createActivityDiscardTitle'));
    expect(source, contains('l10n.createActivityDiscardConfirm'));
    expect(enArb, contains('"createActivityDiscardTitle"'));
    expect(ruArb, contains('"createActivityDiscardTitle"'));
    expect(kkArb, contains('"createActivityDiscardTitle"'));
  });

  test('create activity discard dialog uses a wider compact layout', () async {
    final source = await File(
      'lib/screens/activities/create_activity_screen.dart',
    ).readAsString();
    final dialogStart = source.indexOf('class _ActivityAmberConfirmDialog');
    final mapButtonStart = source.indexOf('class _MapExpandButton');

    expect(dialogStart, isNonNegative);
    expect(mapButtonStart, greaterThan(dialogStart));

    final dialogSource = source.substring(dialogStart, mapButtonStart);

    expect(
      dialogSource,
      contains(
        'insetPadding: const AppEdgeInsets.symmetric(horizontal: 12, vertical: 24)',
      ),
    );
    expect(dialogSource, contains('BoxConstraints(maxWidth: 520)'));
    expect(dialogSource, contains('LayoutBuilder('));
    expect(
      dialogSource,
      contains('final isCompactDialog = constraints.maxWidth < 360;'),
    );
    expect(dialogSource, contains('final header = isCompactDialog'));
    expect(dialogSource, contains('? Column('));
    expect(dialogSource, contains('width: double.infinity'));
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
      expect(source, contains("../map/map_screen.dart"));
      expect(source, contains("package:latlong2/latlong.dart"));
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
          '_handleMapTapped(result.point, addressLabel: result.subtitle)',
        ),
      );
      expect(source, contains('String? addressLabel'));
      expect(source, contains('AppMapLinks.buildUrl('));
      expect(source, contains('placemarkFromCoordinates('));
      expect(source, contains('class _MapExpandButton'));
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
    expect(
      currencySource,
      contains('surfaceColor: context.createActivityColors.warmSurface48'),
    );
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
    'activity price amount field does not draw an inner fill layer',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();
      final priceStart = source.indexOf('class _Step3PriceField');
      final step3TextStart = source.indexOf('class _Step3TextField');

      expect(priceStart, isNonNegative);
      expect(step3TextStart, greaterThan(priceStart));

      final priceSource = source.substring(priceStart, step3TextStart);

      expect(priceSource, contains('_createActivityInputDecoration('));
      expect(priceSource, contains('hasFocus: false'));
      expect(priceSource, contains('hasError: errorText != null'));
      expect(priceSource, contains('filled: false'));
      expect(priceSource, contains('enabledBorder: InputBorder.none'));
      expect(priceSource, contains('focusedBorder: InputBorder.none'));
      expect(priceSource, contains('disabledBorder: InputBorder.none'));
      expect(priceSource, contains('errorBorder: InputBorder.none'));
      expect(priceSource, contains('focusedErrorBorder: InputBorder.none'));
      expect(priceSource, isNot(contains('fillColor:')));
      expect(priceSource, isNot(contains('warmSurface48')));
    },
  );

  test(
    'create activity input blocks use clean V2 borders without edge glow',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();
      final step1Start = source.indexOf('class _Step1TextField');
      final categorySelectorStart = source.indexOf(
        'class _CategorySelectorField',
      );
      final priceStart = source.indexOf('class _Step3PriceField');
      final step3TextStart = source.indexOf('class _Step3TextField');
      final toggleStart = source.indexOf('class _Step3ToggleRow');
      final limitStart = source.indexOf('class _Step3LimitField');
      final actionBarStart = source.indexOf('class _Step3ActionBar');
      final step1Source = source.substring(step1Start, categorySelectorStart);
      final priceSource = source.substring(priceStart, step3TextStart);
      final step3TextSource = source.substring(step3TextStart, toggleStart);
      final limitSource = source.substring(limitStart, actionBarStart);

      expect(step1Start, isNonNegative);
      expect(categorySelectorStart, greaterThan(step1Start));
      expect(priceStart, isNonNegative);
      expect(step3TextStart, greaterThan(priceStart));
      expect(toggleStart, greaterThan(step3TextStart));
      expect(limitStart, greaterThan(toggleStart));
      expect(actionBarStart, greaterThan(limitStart));

      expect(source, contains('BoxDecoration _createActivityInputDecoration'));
      expect(step1Source, contains('_createActivityInputDecoration('));
      expect(priceSource, contains('_createActivityInputDecoration('));
      expect(source, contains('return colors.border;'));

      expect(step3TextSource, contains('context.createActivityColors.border'));
      for (final fieldSource in [priceSource, step3TextSource]) {
        expect(fieldSource, isNot(contains('white.withValues(alpha: 0.02)')));
        expect(fieldSource, isNot(contains('white.withValues(alpha: 0.03)')));
      }

      expect(step1Source, isNot(contains('white.withValues(alpha: 0.02)')));
      expect(step1Source, isNot(contains('white.withValues(alpha: 0.03)')));
      expect(limitSource, contains('colors.border'));
      expect(limitSource, isNot(contains('white.withValues(alpha: 0.02)')));
      expect(limitSource, isNot(contains('white.withValues(alpha: 0.03)')));

      expect(step1Source, contains('context.createActivityColors.textMuted'));
      expect(step1Source, isNot(contains('white.withValues(alpha: 0.58)')));
    },
  );

  test(
    'create activity focused and invalid text inputs use visible V2 borders',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();
      final helperStart = source.indexOf(
        'Color _createActivityInputBorderColor',
      );
      final step1Start = source.indexOf('class _Step1TextField');
      final categorySelectorStart = source.indexOf(
        'class _CategorySelectorField',
      );

      expect(helperStart, isNonNegative);
      final helperEnd = source.indexOf(
        'double _createActivityInputBorderWidth',
        helperStart,
      );
      final widthHelperEnd = source.indexOf(
        'extension _CreateActivityColorContext',
        helperEnd,
      );
      expect(helperEnd, greaterThan(helperStart));
      expect(widthHelperEnd, greaterThan(helperEnd));
      expect(step1Start, isNonNegative);
      expect(categorySelectorStart, greaterThan(step1Start));

      final colorHelperSource = source.substring(helperStart, helperEnd);
      final widthHelperSource = source.substring(helperEnd, widthHelperEnd);
      final step1Source = source.substring(step1Start, categorySelectorStart);

      expect(colorHelperSource, contains('if (hasError)'));
      expect(colorHelperSource, contains('return colors.danger;'));
      expect(colorHelperSource, contains('if (hasFocus)'));
      expect(colorHelperSource, contains('return colors.primary;'));
      expect(
        colorHelperSource,
        isNot(contains('return colors.borderPrimary;')),
      );
      expect(widthHelperSource, contains('if (hasError)'));
      expect(widthHelperSource, contains('return 1.6;'));
      expect(widthHelperSource, contains('if (hasFocus)'));
      expect(widthHelperSource, contains('return 1.3;'));
      expect(
        widthHelperSource,
        contains('BoxDecoration _createActivityInputDecoration'),
      );
      expect(widthHelperSource, contains('_createActivityInputBorderColor('));
      expect(widthHelperSource, contains('_createActivityInputBorderWidth('));

      expect(step1Source, contains('_createActivityInputDecoration('));
      expect(
        step1Source,
        isNot(
          contains(
            '_focusNode.hasFocus\n                        ? context.createActivityColors.primary',
          ),
        ),
      );
      expect(step1Source, isNot(contains('_focusNode.hasFocus ? 1.5 : 1')));
    },
  );

  test(
    'create activity step one text fields do not draw an inner fill layer',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();
      final helperStart = source.indexOf(
        'BoxDecoration _createActivityInputDecoration',
      );
      final helperEnd = helperStart < 0
          ? -1
          : source.indexOf(
              'extension _CreateActivityColorContext',
              helperStart,
            );
      final step1Start = source.indexOf('class _Step1TextField');
      final categorySelectorStart = source.indexOf(
        'class _CategorySelectorField',
      );

      expect(helperStart, isNonNegative);
      expect(helperEnd, greaterThan(helperStart));
      expect(step1Start, isNonNegative);
      expect(categorySelectorStart, greaterThan(step1Start));

      final helperSource = source.substring(helperStart, helperEnd);
      final step1Source = source.substring(step1Start, categorySelectorStart);

      expect(
        helperSource,
        contains('color: context.createActivityColors.inputSurface'),
      );
      expect(step1Source, contains('_createActivityInputDecoration('));
      expect(step1Source, contains('filled: false'));
      expect(step1Source, contains('enabledBorder: InputBorder.none'));
      expect(step1Source, contains('focusedBorder: InputBorder.none'));
      expect(step1Source, contains('disabledBorder: InputBorder.none'));
      expect(step1Source, contains('errorBorder: InputBorder.none'));
      expect(step1Source, contains('focusedErrorBorder: InputBorder.none'));
      expect(step1Source, isNot(contains('fillColor:')));
      expect(
        step1Source,
        isNot(contains('color: context.createActivityColors.inputSurface')),
      );
    },
  );

  test(
    'category selector fields match step one V2 input surface and border',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();
      final helperStart = source.indexOf(
        'BoxDecoration _createActivityInputDecoration',
      );
      final helperEnd = helperStart < 0
          ? -1
          : source.indexOf(
              'extension _CreateActivityColorContext',
              helperStart,
            );
      final selectorStart = source.indexOf('class _CategorySelectorField');
      final selectorEnd = source.indexOf(
        'class _CoverUploadCard',
        selectorStart,
      );

      expect(helperStart, isNonNegative);
      expect(helperEnd, greaterThan(helperStart));
      expect(selectorStart, isNonNegative);
      expect(selectorEnd, greaterThan(selectorStart));

      final helperSource = source.substring(helperStart, helperEnd);
      final selectorSource = source.substring(selectorStart, selectorEnd);

      expect(
        helperSource,
        contains('color: context.createActivityColors.inputSurface'),
      );
      expect(helperSource, contains('_createActivityInputBorderColor('));
      expect(helperSource, contains('_createActivityInputBorderWidth('));
      expect(selectorSource, contains('_createActivityInputDecoration('));
      expect(selectorSource, contains('final hasError = errorText != null'));
      expect(selectorSource, contains('hasFocus: false'));
      expect(selectorSource, contains('hasError: hasError'));
      expect(
        selectorSource,
        isNot(contains('color: context.createActivityColors.inputSurface')),
      );
      expect(
        selectorSource,
        isNot(
          contains(
            'context.createActivityColors.primary.withValues(\n'
            '            alpha: isPlaceholder ? 0.28 : 0.42,\n'
            '          )',
          ),
        ),
      );
    },
  );

  test(
    'create activity helper notices and upload hints use secondary accents',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();

      final noticeStart = source.indexOf('class _Step2LocationMismatchNotice');
      final uploadStart = source.indexOf('class _CoverUploadCard');
      final uploadEnd = source.indexOf(
        'class _DashedCoverBorderPainter',
        uploadStart,
      );
      final actionBarStart = source.indexOf('class _Step3ActionBar');

      expect(noticeStart, isNonNegative);
      expect(uploadStart, isNonNegative);
      expect(uploadEnd, greaterThan(uploadStart));
      expect(actionBarStart, isNonNegative);

      final noticeSource = source.substring(noticeStart, uploadStart);
      final uploadSource = source.substring(uploadStart, uploadEnd);
      final actionBarSource = source.substring(actionBarStart);

      expect(
        noticeSource,
        contains('context.createActivityColors.secondaryContainer'),
      );
      expect(
        noticeSource,
        contains('context.createActivityColors.borderSecondary'),
      );
      expect(noticeSource, contains('context.createActivityColors.secondary'));
      expect(noticeSource, isNot(contains('amberSoft24')));

      expect(uploadSource, contains('context.createActivityColors.secondary'));
      expect(
        uploadSource,
        contains('context.createActivityColors.secondaryContainer'),
      );
      expect(
        uploadSource,
        isNot(contains('context.createActivityColors.primary.withValues')),
      );

      expect(
        actionBarSource,
        contains('backgroundColor: context.createActivityColors.primary'),
      );
    },
  );

  test(
    'create activity participant limit fields use a single V2 input surface',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();
      final participantSectionStart = source.indexOf(
        'title: l10n.createParticipantLimitsTitle',
      );
      final reusableWidgetsStart = source.indexOf(
        '// ════════════════════════════════════════════════════════════════',
        participantSectionStart,
      );
      final limitStart = source.indexOf('class _Step3LimitField');
      final actionBarStart = source.indexOf('class _Step3ActionBar');

      expect(participantSectionStart, isNonNegative);
      expect(reusableWidgetsStart, greaterThan(participantSectionStart));
      expect(limitStart, isNonNegative);
      expect(actionBarStart, greaterThan(limitStart));

      final participantSectionSource = source.substring(
        participantSectionStart,
        reusableWidgetsStart,
      );
      final limitSource = source.substring(limitStart, actionBarStart);

      expect(
        participantSectionSource,
        contains('icon: Icons.person_add_alt_1_outlined'),
      );
      expect(
        participantSectionSource,
        contains('icon: Icons.groups_2_outlined'),
      );

      expect(limitSource, contains('required this.icon'));
      expect(limitSource, contains('final IconData icon;'));
      expect(
        limitSource,
        contains('context.createActivityColors.surfaceRaised'),
      );
      expect(limitSource, contains('context.createActivityColors.surfaceWarm'));
      expect(limitSource, contains('filled: false'));
      expect(limitSource, contains('contentPadding: EdgeInsets.zero'));
      expect(limitSource, isNot(contains('warmSurface48')));
      expect(
        limitSource,
        isNot(
          contains('padding: const AppEdgeInsets.symmetric(horizontal: 20)'),
        ),
      );
    },
  );

  test(
    'create activity participant limit fields stay top aligned on validation',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();
      final participantSectionStart = source.indexOf(
        'title: l10n.createParticipantLimitsTitle',
      );
      final reusableWidgetsStart = source.indexOf(
        '// ════════════════════════════════════════════════════════════════',
        participantSectionStart,
      );

      expect(participantSectionStart, isNonNegative);
      expect(reusableWidgetsStart, greaterThan(participantSectionStart));

      final participantSectionSource = source.substring(
        participantSectionStart,
        reusableWidgetsStart,
      );

      expect(
        participantSectionSource,
        contains(
          ': Row(\n'
          '                      crossAxisAlignment: CrossAxisAlignment.start,\n'
          '                      children: [\n'
          '                        Expanded(\n'
          '                          child: _Step3LimitField(',
        ),
      );
    },
  );

  test('create activity maximum participants requires at least two people', () async {
    final source = await File(
      'lib/screens/activities/create_activity_screen.dart',
    ).readAsString();
    final enArb = await File('lib/l10n/app_en.arb').readAsString();
    final ruArb = await File('lib/l10n/app_ru.arb').readAsString();
    final kkArb = await File('lib/l10n/app_kk.arb').readAsString();

    expect(source, contains('_maxParticipants < _minActivityParticipants'));
    expect(source, isNot(contains('_maxParticipants <= 0')));
    expect(
      enArb,
      contains(
        '"createMaxParticipantsValidation": "Please enter a maximum between 2 and 100 participants"',
      ),
    );
    expect(
      ruArb,
      contains(
        '"createMaxParticipantsValidation": "Укажите максимум от 2 до 100 участников"',
      ),
    );
    expect(
      kkArb,
      contains(
        '"createMaxParticipantsValidation": "2 мен 100 қатысушы аралығындағы максимумды енгізіңіз"',
      ),
    );
  });

  test(
    'create activity category selectors use the same V2 input surface',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();
      final helperStart = source.indexOf(
        'BoxDecoration _createActivityInputDecoration',
      );
      final helperEnd = helperStart < 0
          ? -1
          : source.indexOf(
              'extension _CreateActivityColorContext',
              helperStart,
            );
      final selectorStart = source.indexOf('class _CategorySelectorField');
      final coverCardStart = source.indexOf('class _CoverUploadCard');

      expect(helperStart, isNonNegative);
      expect(helperEnd, greaterThan(helperStart));
      expect(selectorStart, isNonNegative);
      expect(coverCardStart, greaterThan(selectorStart));

      final helperSource = source.substring(helperStart, helperEnd);
      final selectorSource = source.substring(selectorStart, coverCardStart);

      expect(
        helperSource,
        contains('context.createActivityColors.inputSurface'),
      );
      expect(selectorSource, contains('_createActivityInputDecoration('));
      expect(selectorSource, contains('context.createActivityColors.primary'));
      expect(
        selectorSource,
        contains('context.createActivityColors.textMuted'),
      );
      expect(selectorSource, isNot(contains('surfaceWarm')));
      expect(selectorSource, isNot(contains('warmSurface47')));
      expect(selectorSource, isNot(contains('white.withValues(alpha: 0.02)')));
      expect(selectorSource, isNot(contains('white.withValues(alpha: 0.58)')));
      expect(selectorSource, isNot(contains('white.withValues(alpha: 0.78)')));
    },
  );

  test(
    'create activity category field states use graphite input surface',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();
      final colorsStart = source.indexOf('final class _CreateActivityColors');
      final colorsEnd = colorsStart < 0
          ? -1
          : source.indexOf(
              'Color _createActivityInputBorderColor',
              colorsStart,
            );
      final catalogStart = source.indexOf('class _CategoryCatalogState');
      final pickerStart = source.indexOf('class _CategoryPickerSheet');

      expect(colorsStart, isNonNegative);
      expect(colorsEnd, greaterThan(colorsStart));
      expect(catalogStart, isNonNegative);
      expect(pickerStart, greaterThan(catalogStart));

      final colorsSource = source.substring(colorsStart, colorsEnd);
      final catalogSource = source.substring(catalogStart, pickerStart);

      expect(
        colorsSource,
        contains('Color get inputSurface => colors.surfaceRaised'),
      );
      expect(
        catalogSource,
        contains('decoration: _createActivityInputDecoration('),
      );
      expect(catalogSource, contains('hasFocus: false'));
      expect(catalogSource, contains('hasError: false'));
      expect(catalogSource, isNot(contains('warmSurface47')));
      expect(catalogSource, isNot(contains('white.withValues(alpha: 0.02)')));
      expect(catalogSource, isNot(contains('white.withValues(alpha: 0.72)')));
    },
  );

  test(
    'create activity category selectors avoid warm-looking input fill',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();
      final colorsStart = source.indexOf('final class _CreateActivityColors');
      final colorsEnd = colorsStart < 0
          ? -1
          : source.indexOf(
              'Color _createActivityInputBorderColor',
              colorsStart,
            );
      final selectorStart = source.indexOf('class _CategorySelectorField');
      final selectorEnd = source.indexOf(
        'class _CoverUploadCard',
        selectorStart,
      );

      expect(colorsStart, isNonNegative);
      expect(colorsEnd, greaterThan(colorsStart));
      expect(selectorStart, isNonNegative);
      expect(selectorEnd, greaterThan(selectorStart));

      final colorsSource = source.substring(colorsStart, colorsEnd);
      final selectorSource = source.substring(selectorStart, selectorEnd);

      expect(
        colorsSource,
        contains('Color get inputSurface => colors.surfaceRaised'),
      );
      expect(
        colorsSource,
        isNot(contains('Color get inputSurface => colors.surfaceWarm')),
      );
      expect(selectorSource, contains('_createActivityInputDecoration('));
      expect(selectorSource, isNot(contains('surfaceRaised')));
      expect(selectorSource, isNot(contains('surfaceWarm')));
    },
  );

  test(
    'create activity inactive choices and toggles stay visible in light V2',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();

      final segmentedStart = source.indexOf('class _Step2FormatSegmented');
      final segmentedEnd = source.indexOf('class _Step2PillTextField');
      final chipStart = source.indexOf('class _Step3ChoiceChip');
      final priceStart = source.indexOf('class _Step3PriceField');
      final toggleStart = source.indexOf('class _Step3ToggleRow');
      final limitStart = source.indexOf('class _Step3LimitField');

      expect(segmentedStart, isNonNegative);
      expect(segmentedEnd, greaterThan(segmentedStart));
      expect(chipStart, isNonNegative);
      expect(priceStart, greaterThan(chipStart));
      expect(toggleStart, isNonNegative);
      expect(limitStart, greaterThan(toggleStart));

      final segmentedSource = source.substring(segmentedStart, segmentedEnd);
      final chipSource = source.substring(chipStart, priceStart);
      final toggleSource = source.substring(toggleStart, limitStart);

      expect(segmentedSource, contains('Border.all('));
      expect(segmentedSource, contains('context.createActivityColors.border'));
      expect(segmentedSource, contains('final labelColor = isActive'));
      expect(
        segmentedSource,
        contains('context.createActivityColors.textPrimary'),
      );
      expect(segmentedSource, contains('context.createActivityColors.primary'));
      expect(chipSource, contains('final labelColor ='));
      expect(chipSource, contains('Border.all('));
      expect(chipSource, contains('context.createActivityColors.border'));
      expect(chipSource, contains('color: labelColor'));
      expect(
        chipSource,
        isNot(contains('color: context.createActivityColors.white')),
      );
      expect(toggleSource, contains('Border.all('));
      expect(toggleSource, contains('context.createActivityColors.border'));
      expect(
        toggleSource,
        contains('context.createActivityColors.textPrimary'),
      );
    },
  );

  test('create activity step circles use visible light V2 borders', () async {
    final source = await File(
      'lib/screens/activities/create_activity_screen.dart',
    ).readAsString();

    final indicatorStart = source.indexOf('class _StepIndicator');
    final step2NavStart = source.indexOf('class _Step2NavBar');
    expect(indicatorStart, isNonNegative);
    expect(step2NavStart, greaterThan(indicatorStart));

    final indicatorSource = source.substring(indicatorStart, step2NavStart);
    final compactIndicatorEnd = indicatorSource.indexOf(
      '    return Container(',
    );
    expect(compactIndicatorEnd, isNonNegative);
    final compactIndicatorSource = indicatorSource.substring(
      0,
      compactIndicatorEnd,
    );

    expect(compactIndicatorSource, contains('final stepBorderColor ='));
    expect(
      compactIndicatorSource,
      contains('context.createActivityColors.border'),
    );
    expect(compactIndicatorSource, contains('width: isActive ? 1.3 : 1'));
    expect(
      compactIndicatorSource,
      isNot(contains('context.createActivityColors.white.withValues')),
    );
  });

  test(
    'create activity category selectors use neutral graphite input fill',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();
      final colorsStart = source.indexOf('final class _CreateActivityColors');
      final colorsEnd = colorsStart < 0
          ? -1
          : source.indexOf(
              'Color _createActivityInputBorderColor',
              colorsStart,
            );
      final selectorStart = source.indexOf('class _CategorySelectorField');
      final selectorEnd = source.indexOf(
        'class _CoverUploadCard',
        selectorStart,
      );

      expect(colorsStart, isNonNegative);
      expect(colorsEnd, greaterThan(colorsStart));
      expect(selectorStart, isNonNegative);
      expect(selectorEnd, greaterThan(selectorStart));

      final colorsSource = source.substring(colorsStart, colorsEnd);
      final selectorSource = source.substring(selectorStart, selectorEnd);

      expect(
        colorsSource,
        contains('Color get inputSurface => colors.surfaceRaised'),
      );
      expect(
        colorsSource,
        isNot(contains('Color get inputSurface => colors.surfaceWarm')),
      );
      expect(selectorSource, contains('_createActivityInputDecoration('));
      expect(selectorSource, contains('hasFocus: false'));
      expect(selectorSource, isNot(contains('surfaceWarm')));
      expect(selectorSource, isNot(contains('borderPrimary')));
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
    'create activity cover upload card removes light image shadow overlay and keeps copy readable',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();

      final helperStart = source.indexOf(
        'LinearGradient? _coverUploadOverlayGradient',
      );
      final cardStart = source.indexOf('class _CoverUploadCard');
      final copyStart = source.indexOf('class _CoverCardCopy');
      final borderStart = source.indexOf('class _DashedCoverBorderPainter');
      expect(helperStart, isNonNegative);
      expect(cardStart, isNonNegative);
      expect(copyStart, greaterThan(cardStart));
      expect(borderStart, greaterThan(copyStart));

      final helperSource = source.substring(helperStart, cardStart);
      final cardSource = source.substring(cardStart, copyStart);
      final copySource = source.substring(copyStart, borderStart);

      expect(helperSource, contains('Brightness.light'));
      expect(helperSource, contains('return null;'));
      expect(cardSource, contains('final overlayGradient ='));
      expect(cardSource, contains('if (overlayGradient != null)'));
      expect(copySource, contains('final isLight ='));
      expect(copySource, contains('context.createActivityColors.surface'));
      expect(copySource, contains('context.createActivityColors.border'));
      expect(
        copySource,
        contains('context.createActivityColors.textSecondary'),
      );
      expect(
        copySource,
        isNot(
          contains(
            'context.createActivityColors.white.withValues(alpha: 0.88)',
          ),
        ),
      );
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

  test('create activity picker sheets use full-width modal frame', () async {
    final source = await File(
      'lib/screens/activities/create_activity_screen.dart',
    ).readAsString();

    final sheetStart = source.indexOf('class _CategoryPickerSheet');
    expect(sheetStart, isNonNegative);

    final sheetSource = source.substring(sheetStart);
    expect(sheetSource, contains('AppModalSheetFrame('));
    expect(
      sheetSource,
      contains('onTapOutside: () => Navigator.of(context).maybePop()'),
    );
    expect(sheetSource, contains('width: double.infinity'));
    expect(sheetSource, isNot(contains('left: 16')));
    expect(sheetSource, isNot(contains('right: 16')));
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
