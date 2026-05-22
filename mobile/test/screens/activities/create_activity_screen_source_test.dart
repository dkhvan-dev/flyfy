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
    'create activity accepts selected map point as offline location',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();

      expect(source, contains('final hasOfflineLocation ='));
      expect(source, contains('(_mapUrlValue ?? \'\').isNotEmpty'));
      expect(source, contains('!hasOfflineLocation'));
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

      final mapTapStart = source.indexOf('Future<void> _handleMapTapped');
      final buildStart = source.indexOf('@override', mapTapStart);
      expect(mapTapStart, isNonNegative);
      expect(buildStart, greaterThan(mapTapStart));

      final mapTapSource = source.substring(mapTapStart, buildStart);

      expect(mapTapSource, contains('setLocaleIdentifier('));
      expect(mapTapSource, contains('_resolveReferenceCity('));
      expect(mapTapSource, contains('_locationLabelResolver.resolveAddress('));
      expect(mapTapSource, contains('_cityNameCtrl.text = localizedCityName'));
      expect(
        mapTapSource,
        isNot(contains('final countryLabel = (placemark.country')),
      );
    },
  );

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
    expect(currencySource, contains('surfaceColor: const Color(0xFF3A2108)'));
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
}
