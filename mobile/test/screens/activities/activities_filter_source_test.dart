import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'discover activities sort row matches the stories text control style',
    () async {
      final source = await File(
        'lib/screens/activities/activities_screen.dart',
      ).readAsString();
      final inlineSortRowSource = await File(
        'lib/core/ui/app_inline_sort_row.dart',
      ).readAsString();
      final sortBarStart = source.indexOf('class _DiscoverSortBar');
      final sortBarEnd = source.indexOf('class _ActivitiesNearbyMapSection');

      expect(sortBarStart, isNonNegative);
      expect(sortBarEnd, greaterThan(sortBarStart));

      final sortBarSource = source.substring(sortBarStart, sortBarEnd);

      expect(sortBarSource, contains('AppInlineSortRow<_ActivitySortField>'));
      expect(sortBarSource, contains('activitiesSortLabel'));
      expect(inlineSortRowSource, contains('SingleChildScrollView'));
      expect(inlineSortRowSource, contains('scrollDirection: Axis.horizontal'));
      expect(inlineSortRowSource, contains('GestureDetector('));
      expect(inlineSortRowSource, contains("'\$label:'"));
      expect(inlineSortRowSource, contains('Icons.arrow_upward_rounded'));
      expect(inlineSortRowSource, contains('Icons.arrow_downward_rounded'));
      expect(sortBarSource, isNot(contains('_DiscoverSortButton(')));
      expect(sortBarSource, isNot(contains('LinearGradient(')));
      expect(source, isNot(contains('class _DiscoverSortButton')));
    },
  );

  test(
    'discover activities filter uses the full-width shared apply button',
    () async {
      final source = await File(
        'lib/screens/activities/activities_screen.dart',
      ).readAsString();
      final scaffoldStart = source.indexOf('class _RangeSheetScaffold');
      final scaffoldEnd = source.indexOf('class _RangeTextField');

      expect(scaffoldStart, isNonNegative);
      expect(scaffoldEnd, greaterThan(scaffoldStart));

      final scaffoldSource = source.substring(scaffoldStart, scaffoldEnd);

      expect(scaffoldSource, contains('AppFilterApplyButton'));
      expect(scaffoldSource, isNot(contains('_PrimaryPillButton(')));
    },
  );

  test(
    'discover activities filter uses searchable country before city',
    () async {
      final source = await File(
        'lib/screens/activities/activities_screen.dart',
      ).readAsString();

      expect(source, contains('final AppCountryFilterValue? country'));
      expect(source, contains('final AppCityFilterValue? city'));
      expect(source, contains('_initializeDefaultLocationFilter'));
      expect(
        source,
        contains(
          "import '../../shared/location/home_location_filter_defaults.dart';",
        ),
      );
      expect(source, contains('HomeLocationFilterDefaults.fromPreference'));
      expect(source, contains('country: defaults.country'));
      expect(source, contains('city: defaults.city'));
      expect(source, contains('AppCountryFilterSection'));
      expect(source, contains('activitiesFilterCountrySection'));
      expect(source, contains('activitiesFilterCountryAll'));
      expect(source, contains('activitiesFilterCountrySearchHint'));
      expect(source, contains('activitiesFilterCountryNoResults'));
      expect(source, contains('if (_selectedCountry != null) ...['));
      expect(source, contains('countryCode: _selectedCountry?.countryCode'));

      final countrySectionStart = source.indexOf('AppCountryFilterSection(');
      final citySectionStart = source.indexOf('AppCityFilterSection(');
      final categorySectionStart = source.indexOf(
        'Widget _buildCategorySection',
      );

      expect(countrySectionStart, isNonNegative);
      expect(citySectionStart, isNonNegative);
      expect(citySectionStart, greaterThan(countrySectionStart));
      expect(categorySectionStart, greaterThan(citySectionStart));
    },
  );

  test(
    'discover activities default filter uses device-backed effective location',
    () async {
      final source = await File(
        'lib/screens/activities/activities_screen.dart',
      ).readAsString();
      final initStart = source.indexOf(
        'Future<void> _initializeDefaultLocationFilter()',
      );
      final applyStart = source.indexOf(
        'void _applyDefaultLocationFilter',
        initStart,
      );
      final disposeStart = source.indexOf('@override\n  void dispose()');

      expect(initStart, isNonNegative);
      expect(applyStart, greaterThan(initStart));
      expect(disposeStart, greaterThan(applyStart));

      final initSource = source.substring(initStart, applyStart);
      final applySource = source.substring(applyStart, disposeStart);

      expect(
        initSource,
        isNot(
          contains('final sessionProvider = context.read<SessionProvider>();'),
        ),
      );
      expect(initSource, isNot(contains('profile: sessionProvider.profile')));
      expect(
        initSource,
        contains('languageCode: Localizations.localeOf(context).languageCode'),
      );
      expect(applySource, contains('provider.effectiveLocation'));
      expect(
        applySource,
        contains('HomeLocationFilterDefaults.fromPreference'),
      );
      expect(applySource, contains('if (!defaults.hasValue) return;'));
      expect(
        applySource,
        isNot(contains('final location = provider.selectedLocation')),
      );
    },
  );

  test(
    'discover activities country changes reset city to all cities',
    () async {
      final source = await File(
        'lib/screens/activities/activities_screen.dart',
      ).readAsString();

      expect(
        source,
        contains('void _setCountry(AppCountryFilterValue? country)'),
      );
      expect(source, contains('_selectedCountry = country'));
      expect(source, contains('_selectedCity = null'));
    },
  );

  test('discover activities can filter by country without city', () async {
    final source = await File(
      'lib/screens/activities/activities_screen.dart',
    ).readAsString();

    expect(source, contains('filters.country != null'));
    expect(source, contains('!filters.country!.matches('));
    expect(source, contains('countryCode: item.countryCode'));
  });

  test(
    'discover activities does not render clear controls below sorting or empty state',
    () async {
      final source = await File(
        'lib/screens/activities/activities_screen.dart',
      ).readAsString();
      final filteredEmptyStart = source.indexOf(
        'else if (filteredItems.isEmpty)',
      );
      final listStart = source.indexOf(
        'else\n                            SliverPadding',
        filteredEmptyStart,
      );

      expect(filteredEmptyStart, isNonNegative);
      expect(listStart, greaterThan(filteredEmptyStart));

      final filteredEmptySource = source.substring(
        filteredEmptyStart,
        listStart,
      );

      expect(source, isNot(contains('_FiltersSummaryBar(')));
      expect(
        source,
        isNot(contains('activitiesResultsCount(filteredItems.length)')),
      );
      expect(filteredEmptySource, contains('activitiesFilteredEmptyTitle'));
      expect(filteredEmptySource, contains('activitiesFilteredEmptySubtitle'));
      expect(filteredEmptySource, isNot(contains('actionLabel:')));
      expect(filteredEmptySource, isNot(contains('onActionTap:')));
    },
  );

  test('discover activities price filter keeps only a free preset', () async {
    final source = await File(
      'lib/screens/activities/activities_screen.dart',
    ).readAsString();
    final priceSectionStart = source.indexOf('Widget _buildPriceSection');
    final priceSectionEnd = source.indexOf('Widget _buildVisibilitySection');
    final presetsStart = source.indexOf(
      'List<_PricePreset> _buildPricePresets',
    );
    final presetsEnd = source.indexOf('List<_DatePreset> _buildDatePresets');

    expect(priceSectionStart, isNonNegative);
    expect(priceSectionEnd, greaterThan(priceSectionStart));
    expect(presetsStart, isNonNegative);
    expect(presetsEnd, greaterThan(presetsStart));

    final priceSectionSource = source.substring(
      priceSectionStart,
      priceSectionEnd,
    );
    final presetsSource = source.substring(presetsStart, presetsEnd);

    expect(priceSectionSource, contains("prefix: ''"));
    expect(priceSectionSource, isNot(contains('filterCurrencyLabel')));
    expect(priceSectionSource, isNot(contains('pricePresetNominalUnit')));
    expect(presetsSource, contains('l10n.createPriceFree'));
    expect(RegExp(r'_PricePreset\(').allMatches(presetsSource), hasLength(1));
    expect(presetsSource, isNot(contains('currencyLabel')));
    expect(presetsSource, isNot(contains('nominalUnit')));
  });

  test('discover activities filter option cards avoid fixed heights', () async {
    final source = await File(
      'lib/screens/activities/activities_screen.dart',
    ).readAsString();
    final categoryStart = source.indexOf('class _CategoryFilterPill');
    final visibilityStart = source.indexOf('class _VisibilityOptionCard');
    final filterSectionStart = source.indexOf('class _FilterSection');

    expect(categoryStart, isNonNegative);
    expect(visibilityStart, greaterThan(categoryStart));
    expect(filterSectionStart, greaterThan(visibilityStart));

    final categorySource = source.substring(categoryStart, visibilityStart);
    final visibilitySource = source.substring(
      visibilityStart,
      filterSectionStart,
    );

    expect(categorySource, contains('constraints: BoxConstraints('));
    expect(categorySource, contains('minHeight:'));
    expect(
      categorySource,
      isNot(contains('height: _activitiesScaled(context, 58')),
    );
    expect(visibilitySource, contains('constraints: BoxConstraints('));
    expect(visibilitySource, contains('minHeight:'));
    expect(
      visibilitySource,
      isNot(contains('height: _activitiesScaled(context, 76')),
    );
  });

  test(
    'discover activities filter controls use readable V2 surfaces and text',
    () async {
      final source = await File(
        'lib/screens/activities/activities_screen.dart',
      ).readAsString();
      final categoryStart = source.indexOf('class _CategoryFilterPill');
      final visibilityStart = source.indexOf('class _VisibilityOptionCard');
      final filterSectionStart = source.indexOf('class _FilterSection');
      final rangeFieldStart = source.indexOf('class _RangeTextField');
      final presetChipStart = source.indexOf('class _PresetChip');
      final primaryButtonStart = source.indexOf('class _PrimaryPillButton');

      expect(categoryStart, isNonNegative);
      expect(visibilityStart, greaterThan(categoryStart));
      expect(filterSectionStart, greaterThan(visibilityStart));
      expect(rangeFieldStart, isNonNegative);
      expect(presetChipStart, greaterThan(rangeFieldStart));
      expect(primaryButtonStart, greaterThan(presetChipStart));

      final categorySource = source.substring(categoryStart, visibilityStart);
      final visibilitySource = source.substring(
        visibilityStart,
        filterSectionStart,
      );
      final rangeFieldSource = source.substring(
        rangeFieldStart,
        presetChipStart,
      );
      final presetChipSource = source.substring(
        presetChipStart,
        primaryButtonStart,
      );

      expect(
        categorySource,
        contains('context.activitiesColors.surfaceRaised'),
      );
      expect(categorySource, contains('context.activitiesColors.textPrimary'));
      expect(
        categorySource,
        contains('context.activitiesColors.textSecondary'),
      );
      expect(categorySource, isNot(contains('orangeOverlayWash11')));
      expect(categorySource, isNot(contains('orangeOverlayWash04')));
      expect(categorySource, isNot(contains('white.withValues(alpha: 0.03)')));
      expect(categorySource, isNot(contains('white.withValues(alpha: 0.015)')));

      expect(
        visibilitySource,
        contains('context.activitiesColors.surfaceRaised'),
      );
      expect(
        visibilitySource,
        contains('context.activitiesColors.textPrimary'),
      );
      expect(
        visibilitySource,
        contains('context.activitiesColors.textSecondary'),
      );
      expect(visibilitySource, isNot(contains('orangeOverlayLight03')));
      expect(visibilitySource, isNot(contains('orangeOverlayWash07')));
      expect(
        visibilitySource,
        isNot(contains('white.withValues(alpha: 0.03)')),
      );
      expect(
        visibilitySource,
        isNot(contains('white.withValues(alpha: 0.015)')),
      );

      expect(
        rangeFieldSource,
        contains('context.activitiesColors.surfaceRaised'),
      );
      expect(
        rangeFieldSource,
        contains('context.activitiesColors.textPrimary'),
      );
      expect(
        rangeFieldSource,
        contains('context.activitiesColors.textSecondary'),
      );
      expect(rangeFieldSource, contains('context.activitiesColors.textMuted'));
      expect(rangeFieldSource, isNot(contains('orangeOverlayWash06')));
      expect(rangeFieldSource, isNot(contains('orangeOverlayWash10')));
      expect(rangeFieldSource, isNot(contains('orangeOverlayWash01')));
      expect(
        rangeFieldSource,
        isNot(contains('white.withValues(alpha: 0.015)')),
      );

      expect(
        presetChipSource,
        contains('context.activitiesColors.surfaceRaised'),
      );
      expect(
        presetChipSource,
        contains('context.activitiesColors.textPrimary'),
      );
      expect(presetChipSource, isNot(contains('orangeOverlayLight03')));
      expect(
        presetChipSource,
        isNot(contains('white.withValues(alpha: 0.02)')),
      );
    },
  );
}
