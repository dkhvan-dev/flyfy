import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'guide verification header uses primary text and amber status gradient',
    () async {
      final source = await File(
        'lib/screens/profile/guide_verification_screen.dart',
      ).readAsString();

      final wizardTitle = source.indexOf('l10n.guideVerificationTitle');
      final wizardDivider = source.indexOf('Divider(', wizardTitle);
      final statusTitle = source.indexOf(
        "AppLocalizations.of(context)!.guideVerificationTitle",
      );
      final statusDivider = source.indexOf('Divider(', statusTitle);
      final heroStart = source.indexOf('class _HeroBanner');
      final heroEnd = source.indexOf('class _SectionTitle', heroStart);

      expect(wizardTitle, isNonNegative);
      expect(wizardDivider, greaterThan(wizardTitle));
      expect(statusTitle, isNonNegative);
      expect(statusDivider, greaterThan(statusTitle));
      expect(heroStart, isNonNegative);
      expect(heroEnd, greaterThan(heroStart));

      final wizardHeaderSource = source.substring(wizardTitle, wizardDivider);
      final statusHeaderSource = source.substring(statusTitle, statusDivider);
      final heroSource = source.substring(heroStart, heroEnd);

      expect(wizardHeaderSource, contains('color: AppPalette.textPrimary'));
      expect(statusHeaderSource, contains('color: AppPalette.textPrimary'));
      expect(wizardHeaderSource, isNot(contains('color: AppPalette.primary')));
      expect(statusHeaderSource, isNot(contains('color: AppPalette.primary')));

      expect(heroSource, contains('_guideAmberHeroGradientColors'));
      expect(
        heroSource,
        contains('stops: gradientColors == null ? const [0, 0.58, 1] : null'),
      );
      expect(
        heroSource,
        contains('effectiveAccentColor.withValues(alpha: 0.34)'),
      );
      expect(heroSource, contains('BoxShadow('));
    },
  );

  test(
    'guide verification screen uses amber glass system across the form',
    () async {
      final source = await File(
        'lib/screens/profile/guide_verification_screen.dart',
      ).readAsString();

      final progressStart = source.indexOf('class _ProgressMeta');
      final progressEnd = source.indexOf('class _HeroBanner', progressStart);
      final heroStart = progressEnd;
      final heroEnd = source.indexOf('class _SectionTitle', heroStart);
      final panelStart = source.indexOf('class _PanelCard');
      final panelEnd = source.indexOf('class _FieldBlock', panelStart);
      final inputStart = source.indexOf('class _DarkInput');
      final inputEnd = source.indexOf('class _DateTextInputFormatter');
      final actionStart = source.indexOf('class _AmberGradientButton');
      final actionEnd = actionStart < 0
          ? -1
          : source.indexOf('class _StatusScreen', actionStart);

      expect(progressStart, isNonNegative);
      expect(progressEnd, greaterThan(progressStart));
      expect(heroStart, isNonNegative);
      expect(heroEnd, greaterThan(heroStart));
      expect(panelStart, isNonNegative);
      expect(panelEnd, greaterThan(panelStart));
      expect(inputStart, isNonNegative);
      expect(inputEnd, greaterThan(inputStart));
      expect(actionStart, isNonNegative);
      expect(actionEnd, greaterThan(actionStart));

      final progressSource = source.substring(progressStart, progressEnd);
      final heroSource = source.substring(heroStart, heroEnd);
      final panelSource = source.substring(panelStart, panelEnd);
      final inputSource = source.substring(inputStart, inputEnd);
      final actionSource = source.substring(actionStart, actionEnd);

      expect(source, contains('_guideAmberGlassDecoration('));
      expect(source, contains('_guideAmberGradientButtonDecoration('));
      expect(source, contains('_guideAmberHeroGradientColors'));
      expect(progressSource, contains('_guideAmberGlassDecoration('));
      expect(progressSource, contains('AppPalette.warning'));
      expect(heroSource, isNot(contains('gradientSets')));
      expect(heroSource, isNot(contains('AppPalette.amberLight07')));
      expect(heroSource, isNot(contains('AppPalette.amberSoft14')));
      expect(heroSource, isNot(contains('AppPalette.warmMuted30')));
      expect(heroSource, isNot(contains('AppPalette.tealLight03')));
      expect(heroSource, contains('_guideHeroAccentIcon('));
      expect(panelSource, contains('_guideAmberGlassDecoration('));
      expect(inputSource, contains('focusedBorder: OutlineInputBorder('));
      expect(
        inputSource,
        contains('borderSide: _guideAmberDropdownBorderSide()'),
      );
      expect(actionSource, contains('Semantics('));
      expect(actionSource, contains('_guideAmberGradientButtonDecoration('));
      expect(actionSource, contains('Icons.arrow_forward_rounded'));
    },
  );

  test(
    'guide verification status card uses excursion detail amber gradient',
    () async {
      final source = await File(
        'lib/screens/profile/guide_verification_screen.dart',
      ).readAsString();
      final excursionDetailsSource = await File(
        'lib/screens/excursions/excursion_details_screen.dart',
      ).readAsString();
      final statusStart = source.indexOf('class _StatusScreen');
      final statusEnd = source.length;
      final heroStart = source.indexOf('class _HeroBanner');
      final heroEnd = source.indexOf('class _SectionTitle', heroStart);
      final checkoutStart = excursionDetailsSource.indexOf(
        'class _ExcursionCheckoutBar',
      );
      final checkoutEnd = excursionDetailsSource.indexOf(
        'class _ExcursionDetailsLoading',
        checkoutStart,
      );

      expect(statusStart, isNonNegative);
      expect(statusEnd, greaterThan(statusStart));
      expect(heroStart, isNonNegative);
      expect(heroEnd, greaterThan(heroStart));
      expect(checkoutStart, isNonNegative);
      expect(checkoutEnd, greaterThan(checkoutStart));

      final statusSource = source.substring(statusStart, statusEnd);
      final heroSource = source.substring(heroStart, heroEnd);
      final checkoutSource = excursionDetailsSource.substring(
        checkoutStart,
        checkoutEnd,
      );

      expect(checkoutSource, contains('backgroundColor: AppPalette.primary'));
      expect(source, contains('_guideExcursionAmberStatusGradientColors'));
      expect(source, contains('const [_guideAmberGold, AppPalette.primary]'));
      expect(source, contains('AppPalette.amberSoft19'));
      expect(source, contains('AppPalette.orangeSoft46'));
      expect(source, contains('AppPalette.orangeMuted06'));
      expect(
        source,
        isNot(
          contains(
            '_guideExcursionAmberStatusGradientColors = [\n'
            '  _guideAmberGold,\n'
            '  AppPalette.primary,\n'
            ']',
          ),
        ),
      );
      expect(source, isNot(contains('_guideSoundCloudStatusGradientColors')));
      expect(source, isNot(contains('AppPalette.warmMuted37')));
      expect(source, isNot(contains('AppPalette.redMuted38')));
      expect(heroSource, contains('gradientColors'));
      expect(
        heroSource,
        contains('gradientColors ?? _guideAmberHeroGradientColors'),
      );
      expect(
        statusSource,
        contains('gradientColors: _guideExcursionAmberStatusGradientColors'),
      );
      expect(
        statusSource,
        contains('accentColor: _guideExcursionAmberStatusAccent'),
      );
      expect(
        statusSource,
        contains('overlayInkColor: _guideExcursionAmberStatusInk'),
      );
      expect(statusSource, contains('overlayMidAlpha: 0.08'));
      expect(statusSource, contains('overlayEndAlpha: 0.32'));
    },
  );

  test(
    'guide verification wizard buttons match edit profile save button',
    () async {
      final source = await File(
        'lib/screens/profile/guide_verification_screen.dart',
      ).readAsString();
      final editProfileSource = await File(
        'lib/screens/profile/edit_profile_screen.dart',
      ).readAsString();
      final actionStart = source.indexOf('class _GuideSolidActionButton');
      final actionEnd = source.indexOf(
        'class _AmberGradientButton',
        actionStart,
      );

      expect(actionStart, isNonNegative);
      expect(actionEnd, greaterThan(actionStart));

      final actionSource = source.substring(actionStart, actionEnd);

      expect(source, isNot(contains('useProfileSaveStyle:')));
      expect(
        editProfileSource,
        contains('fontSize: profileScaled(context, 15, min: 14, max: 16)'),
      );
      expect(source, contains('_GuideSolidActionButton('));
      expect(source, contains('label: _ctaLabel(context, _step),'));
      expect(actionSource, contains('backgroundColor: AppPalette.primary'));
      expect(actionSource, contains('foregroundColor: AppPalette.white'));
      expect(
        actionSource,
        contains('fontSize: profileScaled(context, 15, min: 14, max: 16)'),
      );
      expect(actionSource, contains('fontWeight: FontWeight.w800'));
      expect(actionSource, contains('letterSpacing: 0.4'));
      expect(actionSource, contains('Text(\n              label,'));
      expect(actionSource, isNot(contains('label.toUpperCase()')));
    },
  );

  test(
    'guide verification fillable field borders match upload card amber border',
    () async {
      final source = await File(
        'lib/screens/profile/guide_verification_screen.dart',
      ).readAsString();
      final inputStart = source.indexOf('class _DarkInput');
      final inputEnd = source.indexOf(
        'class _DateTextInputFormatter',
        inputStart,
      );
      final dropdownStart = source.indexOf('class _DarkDropdown');
      final dropdownEnd = dropdownStart < 0
          ? -1
          : source.indexOf('class _ResponsiveTipRow', dropdownStart);

      expect(inputStart, isNonNegative);
      expect(inputEnd, greaterThan(inputStart));
      expect(dropdownStart, isNonNegative);
      expect(dropdownEnd, greaterThan(dropdownStart));

      final inputSource = source.substring(inputStart, inputEnd);
      final dropdownSource = source.substring(dropdownStart, dropdownEnd);

      expect(source, contains('_guideAmberDropdownBorderSide'));
      expect(
        source,
        contains('color: AppPalette.primary.withValues(alpha: 0.34)'),
      );
      expect(source, contains('width: 1.6'));
      expect(
        inputSource,
        contains('borderSide: _guideAmberDropdownBorderSide()'),
      );
      expect(
        dropdownSource,
        contains('borderSide: _guideAmberDropdownBorderSide()'),
      );
    },
  );

  test('guide verification supporting copy omits trailing periods', () async {
    final files = [
      'lib/l10n/app_ru.arb',
      'lib/l10n/app_en.arb',
      'lib/l10n/app_kk.arb',
    ];
    const keys = [
      'guideVerificationIdentityNotice',
      'guideVerificationNoGlareHint',
      'guideVerificationFullFrameHint',
      'guideVerificationDocumentConfirm',
      'guideVerificationUploadLicenseSubtitle',
      'guideVerificationFirstAidHint',
      'guideVerificationLanguageProficiencyHint',
      'guideVerificationAgreement',
      'guideVerificationReviewNote',
    ];

    for (final path in files) {
      final arb =
          jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
      for (final key in keys) {
        final value = arb[key] as String;
        expect(value.endsWith('.'), isFalse, reason: '$path:$key');
      }
    }
  });

  test(
    'guide verification country selection is an inline searchable dropdown',
    () async {
      final source = await File(
        'lib/screens/profile/guide_verification_screen.dart',
      ).readAsString();
      final identityStart = source.indexOf('Widget _buildIdentityStep');
      final identityEnd = source.indexOf(
        'Widget _buildIdentityDocumentStep',
        identityStart,
      );
      final searchStart = source.indexOf('class _GuideCountrySearchField');
      final searchEnd = searchStart < 0
          ? -1
          : source.indexOf('class _DropdownItem', searchStart);

      expect(identityStart, isNonNegative);
      expect(identityEnd, greaterThan(identityStart));
      expect(searchStart, isNonNegative);
      expect(searchEnd, greaterThan(searchStart));

      final identitySource = source.substring(identityStart, identityEnd);
      final searchSource = source.substring(searchStart, searchEnd);

      expect(source, isNot(contains('Future<void> _selectCountry()')));
      expect(identitySource, contains('_GuideCountrySearchField('));
      expect(
        identitySource,
        contains('searchHint: l10n.activitiesFilterCountrySearchHint'),
      );
      expect(searchSource, contains('TextEditingController'));
      expect(searchSource, contains('FocusNode'));
      expect(searchSource, contains('TextField('));
      expect(searchSource, contains('Icons.search_rounded'));
      expect(
        source,
        contains("import '../../core/network/reference_api.dart';"),
      );
      expect(source, contains("import 'dart:async';"));
      expect(searchSource, contains('late final ReferenceApi _api'));
      expect(searchSource, contains('Timer? _searchDebounce'));
      expect(
        searchSource,
        contains('List<ReferenceCountry> _visibleCountries'),
      );
      expect(searchSource, contains('_api.searchCountries('));
      expect(searchSource, contains('limit: 24'));
      expect(searchSource, contains('_selectedReferenceCountry'));
      expect(searchSource, contains('ListView.separated'));
    },
  );

  test(
    'guide verification upload cards switch to replace file after attachment',
    () async {
      final source = await File(
        'lib/screens/profile/guide_verification_screen.dart',
      ).readAsString();
      final ruArb = await File('lib/l10n/app_ru.arb').readAsString();
      final enArb = await File('lib/l10n/app_en.arb').readAsString();
      final kkArb = await File('lib/l10n/app_kk.arb').readAsString();

      expect(source, contains('String _guideDocumentButtonLabel('));
      expect(source, contains('document.hasFile'));
      expect(source, contains('l10n.guideVerificationReplaceFile'));
      expect(source, contains('l10n.guideVerificationChooseFile'));
      expect(
        ruArb,
        contains('"guideVerificationReplaceFile": "Заменить файл"'),
      );
      expect(enArb, contains('"guideVerificationReplaceFile": "Replace file"'));
      expect(
        kkArb,
        contains('"guideVerificationReplaceFile": "Файлды ауыстыру"'),
      );
    },
  );

  test(
    'guide verification review step omits confirmation explainer block',
    () async {
      final source = await File(
        'lib/screens/profile/guide_verification_screen.dart',
      ).readAsString();
      final reviewStart = source.indexOf('Widget _buildReviewStep');
      final reviewEnd = source.indexOf('String _stageLabel', reviewStart);

      expect(reviewStart, isNonNegative);
      expect(reviewEnd, greaterThan(reviewStart));

      final reviewSource = source.substring(reviewStart, reviewEnd);

      expect(reviewSource, isNot(contains('guideVerificationTermsTitle')));
      expect(reviewSource, isNot(contains('_TermsCard(')));
      expect(reviewSource, contains('_ConfirmCard('));
      expect(source, isNot(contains('class _TermsCard')));
    },
  );
}
