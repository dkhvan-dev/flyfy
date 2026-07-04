import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('my activities screen uses adaptive V2 design system colors', () async {
    final source = await File(
      'lib/screens/activities/my_activities_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.themeFor(context)'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test(
    'my activities root background uses shared V2 screen gradient',
    () async {
      final source = await File(
        'lib/screens/activities/my_activities_screen.dart',
      ).readAsString();

      expect(source, contains('List<Color> get screenGradientColors'));
      expect(source, contains('colors.screenGradientColors'));
      expect(source, contains('colors: palette.screenGradientColors'));
      expect(source, isNot(contains('palette.backgroundTop,')));
      expect(source, isNot(contains('palette.backgroundBottom,')));
    },
  );

  test(
    'my activities empty state suggests changing city filter when city is active',
    () async {
      final source = await File(
        'lib/screens/activities/my_activities_screen.dart',
      ).readAsString();
      final enSource = await File('lib/l10n/app_en.arb').readAsString();
      final ruSource = await File('lib/l10n/app_ru.arb').readAsString();
      final kkSource = await File('lib/l10n/app_kk.arb').readAsString();

      expect(source, contains('_myActivitiesEmptyMessage'));
      expect(source, contains('l10n.cityFilterEmptyHint'));
      expect(source, contains('final filters = _filtersForTab(_activeTab)'));
      expect(
        source,
        contains('filters.city == null && filters.country == null'),
      );
      expect(enSource, contains('"cityFilterEmptyHint"'));
      expect(ruSource, contains('"cityFilterEmptyHint"'));
      expect(kkSource, contains('"cityFilterEmptyHint"'));
    },
  );

  test(
    'my activities filter starts with current-location country and city filter',
    () async {
      final source = await File(
        'lib/screens/activities/my_activities_screen.dart',
      ).readAsString();

      expect(
        source,
        contains("import '../../providers/home_location_provider.dart';"),
      );
      expect(
        source,
        contains("import '../../shared/widgets/app_city_filter_section.dart';"),
      );
      expect(
        source,
        contains(
          "import '../../shared/location/home_location_filter_defaults.dart';",
        ),
      );
      expect(source, contains('HomeLocationProvider'));
      expect(source, contains('provider.effectiveLocation'));
      expect(source, contains('HomeLocationFilterDefaults.fromPreference'));
      expect(source, contains('if (!defaults.hasValue) return;'));
      expect(
        source,
        isNot(contains('final location = provider.selectedLocation')),
      );
      expect(source, contains('_initializeDefaultLocationFilter'));
      expect(source, contains('_applyDefaultLocationFilter'));
      expect(source, contains('final AppCountryFilterValue? country'));
      expect(source, contains('final AppCityFilterValue? city'));
      expect(source, contains('country: defaults.country'));
      expect(source, contains('city: defaults.city'));
      expect(source, contains('AppCountryFilterSection'));
      expect(source, contains('AppCityFilterSection'));
      expect(source, contains('activitiesFilterCountrySection'));
      expect(source, contains('activitiesFilterCountryAll'));
      expect(source, contains('activitiesFilterCountrySearchHint'));
      expect(source, contains('activitiesFilterCountryNoResults'));
      expect(source, contains('locationFilterCitySection'));
      expect(source, contains('filters.country'));
      expect(source, contains('filters.city'));
      expect(source, contains('item.cityId'));
      expect(source, contains('item.cityName'));
      expect(source, contains('countryCode: item.countryCode'));
      expect(source, isNot(contains('profile?.countryCode')));
    },
  );

  test(
    'my activities city filter is compact and searchable through shared selector',
    () async {
      final source = await File(
        'lib/screens/activities/my_activities_screen.dart',
      ).readAsString();

      expect(source, contains('AppCityFilterSection'));
      expect(source, contains('locationFilterCitySearchHint'));
      expect(source, contains('locationFilterCityNoResults'));
      expect(source, contains('AppCountryFilterSection'));
      expect(source, contains('countryCode: _country?.countryCode'));
      expect(source, contains('if (_country != null) ...['));

      final countrySectionStart = source.indexOf('AppCountryFilterSection(');
      final citySectionStart = source.indexOf('AppCityFilterSection(');
      final dateSectionStart = source.indexOf(
        'widget.l10n.myActivitiesFilterDateRange',
      );
      expect(countrySectionStart, isNonNegative);
      expect(citySectionStart, isNonNegative);
      expect(citySectionStart, greaterThan(countrySectionStart));
      expect(dateSectionStart, greaterThan(citySectionStart));

      final citySection = source.substring(citySectionStart, dateSectionStart);
      expect(citySection, contains('AppCityFilterSection'));
      expect(citySection, isNot(contains('Wrap(')));
    },
  );

  test(
    'my activities search field uses the same shared control as activities',
    () async {
      final source = await File(
        'lib/screens/activities/my_activities_screen.dart',
      ).readAsString();

      expect(
        source,
        contains("import '../../core/ui/app_list_search_field.dart';"),
      );

      final searchStart = source.indexOf('class _MyActivitiesSearchField');
      final nextWidgetStart = source.indexOf('class _MyActivitiesTabSwitcher');
      expect(searchStart, isNonNegative);
      expect(nextWidgetStart, greaterThan(searchStart));

      final searchSource = source.substring(searchStart, nextWidgetStart);

      expect(searchSource, contains('return AppListSearchField('));
      expect(searchSource, contains('activeFilterCount: filterActiveCount'));
      expect(searchSource, contains('showClearButton: true'));
      expect(
        searchSource,
        contains('onTapOutside: (_) => FocusScope.of(context).unfocus()'),
      );
      expect(
        searchSource,
        contains(
          "filterTooltip: AppLocalizations.of(context)!.myActivitiesFilterTitle",
        ),
      );
      expect(searchSource, isNot(contains('TextField(')));
      expect(searchSource, isNot(contains('gradient: LinearGradient(')));
      expect(searchSource, isNot(contains('boxShadow: [')));
    },
  );

  test('my activities tabs have visible V2 borders', () async {
    final source = await File(
      'lib/screens/activities/my_activities_screen.dart',
    ).readAsString();

    final switcherStart = source.indexOf('class _MyActivitiesTabSwitcher');
    final segmentStart = source.indexOf('class _SegmentButton');
    final cardStart = source.indexOf('class _MyActivitiesCard');
    expect(switcherStart, isNonNegative);
    expect(segmentStart, greaterThan(switcherStart));
    expect(cardStart, greaterThan(segmentStart));

    final switcherSource = source.substring(switcherStart, segmentStart);
    final segmentSource = source.substring(segmentStart, cardStart);

    expect(source, contains('Color get borderSoft => colors.borderSoft;'));
    expect(
      switcherSource,
      contains('border: Border.all(color: palette.borderSoft)'),
    );
    expect(switcherSource, isNot(contains('white.withValues(alpha: 0.05)')));
    expect(segmentSource, contains('border: Border.all('));
    expect(segmentSource, contains('palette.borderPrimary'));
  });

  test('my activities country changes reset city to all cities', () async {
    final source = await File(
      'lib/screens/activities/my_activities_screen.dart',
    ).readAsString();

    expect(
      source,
      contains('void _setCountry(AppCountryFilterValue? country)'),
    );
    expect(source, contains('_country = country'));
    expect(source, contains('_city = null'));
  });

  test(
    'my activities can filter by country without selecting a city',
    () async {
      final source = await File(
        'lib/screens/activities/my_activities_screen.dart',
      ).readAsString();

      expect(source, contains('filters.country != null'));
      expect(source, contains('!filters.country!.matches('));
      expect(source, contains('countryCode: item.countryCode'));
    },
  );

  test(
    'my activities card does not duplicate location under category label',
    () async {
      final source = await File(
        'lib/screens/activities/my_activities_screen.dart',
      ).readAsString();

      final cardStart = source.indexOf('class _MyActivitiesCard');
      final coverStart = source.indexOf('class _ActivityCover');
      expect(cardStart, isNonNegative);
      expect(coverStart, greaterThan(cardStart));

      final cardSource = source.substring(cardStart, coverStart);
      final categoryLabelStart = cardSource.indexOf(
        'normalizedCategoryLabel.toUpperCase()',
      );
      final compactTitleStart = cardSource.indexOf('if (compactCard)');
      expect(categoryLabelStart, isNonNegative);
      expect(compactTitleStart, greaterThan(categoryLabelStart));

      final categoryHeaderSource = cardSource.substring(
        categoryLabelStart,
        compactTitleStart,
      );

      expect(categoryHeaderSource, isNot(contains('locationText')));
      expect(
        cardSource,
        contains(
          'final locationFallbackText = activityLocationFallbackText(item, l10n);',
        ),
      );
      expect(
        cardSource,
        contains('labelBuilder: (style) => AppLocalizedLocationText('),
      );
      expect(cardSource, contains('fallbackText: locationFallbackText'));
      expect(cardSource, isNot(contains('fallbackText: locationText')));
    },
  );

  test(
    'my activities cards reuse the discover activity card visual system',
    () async {
      final source = await File(
        'lib/screens/activities/my_activities_screen.dart',
      ).readAsString();

      expect(
        source,
        contains(
          "import '../../features/activities/activity_category_art.dart';",
        ),
      );

      final cardStart = source.indexOf('class _MyActivitiesCard');
      final coverStart = source.indexOf('class _ActivityCover');
      final fallbackStart = source.indexOf('class _ActivityCoverFallback');
      final metaStart = source.indexOf('class _MetaItem');
      expect(cardStart, isNonNegative);
      expect(coverStart, greaterThan(cardStart));
      expect(fallbackStart, -1);
      expect(metaStart, greaterThan(coverStart));

      final cardSource = source.substring(cardStart, coverStart);
      final coverSource = source.substring(coverStart, metaStart);

      expect(
        cardSource,
        contains('final artSpec = activityCardArtForItem(item);'),
      );
      expect(cardSource, contains('_activityCategoryAvatarDecoration('));
      expect(cardSource, contains('activityCardSurface'));
      expect(cardSource, contains('activityCardBorder'));
      expect(cardSource, isNot(contains('gradient: LinearGradient(')));
      expect(
        cardSource,
        isNot(contains('_MyActivitiesPalette.of(context).card')),
      );

      expect(coverSource, contains('ActivityDecorativeCover('));
      expect(coverSource, contains('spec: artSpec'));
      expect(coverSource, contains('imageUrl: resolveActivityCoverUrl(item)'));
      expect(coverSource, isNot(contains('Image.network(')));
      expect(
        coverSource,
        isNot(contains('_ActivityCoverFallback(item: item)')),
      );
    },
  );

  test(
    'attended completed activities expose reviews only after checked-in eligibility',
    () async {
      final source = await File(
        'lib/screens/activities/my_activities_screen.dart',
      ).readAsString();

      expect(
        source,
        contains("import '../../core/network/activity_api.dart';"),
      );
      expect(
        source,
        contains(
          "import '../../features/activities/models/activity_review_vm.dart';",
        ),
      );
      expect(
        source,
        contains(
          "import '../../features/activities/models/activity_participant_vm.dart';",
        ),
      );
      expect(source, contains("import 'widgets/activity_review_sheet.dart';"));
      expect(
        source,
        contains('final ActivityApi _activityApi = ActivityApi();'),
      );
      expect(
        source,
        contains('final Set<String> _reviewEligibleActivityIds = {};'),
      );
      expect(
        source,
        contains('final Set<String> _reviewEligibilityLoadedActivityIds = {};'),
      );
      expect(
        source,
        contains(
          'Future<void> _openReviewSheet(ActivityListItemVm item) async',
        ),
      );
      expect(
        RegExp(
          r'_activityApi\.getActivityReviews\(\s*activityId:\s*item\.id,\s*limit:\s*1000,?\s*\)',
        ).hasMatch(source),
        isTrue,
      );
      expect(
        RegExp(
          r'_activityApi\.getActivityParticipants\(\s*item\.id,\s*limit: 1000,\s*\)',
        ).hasMatch(source),
        isTrue,
      );
      expect(source, contains('bool _isReviewableParticipant('));
      expect(source, contains("case 'CHECKED_IN':"));
      expect(source, isNot(contains("case 'ATTENDED':")));
      expect(source, contains('_isReviewableParticipant(currentParticipant)'));
      expect(
        source,
        contains('bool _canShowReviewAction(ActivityListItemVm item)'),
      );
      expect(
        source,
        contains('_reviewEligibleActivityIds.contains(activityId)'),
      );
      expect(
        RegExp(
          r'_activityApi\.getActivityOrganizerReviews\(\s*activityId:\s*item\.id,\s*limit:\s*1000,?\s*\)',
        ).hasMatch(source),
        isTrue,
      );
      expect(source, contains('showActivityReviewSheet('));
      expect(
        source,
        contains('_activityApi.saveActivityReviews(item.id, request)'),
      );
      expect(source, contains('l10n.activityReviewSaved'));
      expect(source, contains('l10n.activityReviewSaveFailed'));
      expect(
        source,
        contains('bool _canReviewActivity(ActivityListItemVm item)'),
      );
      expect(
        RegExp(
          r'_activeTab\s*==\s*_MyActivitiesTab\.attended\s*&&\s*_canShowReviewAction\(item\)',
        ).hasMatch(source),
        isTrue,
      );

      final cardStart = source.indexOf('class _MyActivitiesCard');
      final coverStart = source.indexOf('class _ActivityCover');
      expect(cardStart, isNonNegative);
      expect(coverStart, greaterThan(cardStart));

      final cardSource = source.substring(cardStart, coverStart);
      expect(cardSource, contains('final VoidCallback? onReviewTap;'));
      expect(cardSource, contains('final bool hasReview;'));
      expect(cardSource, contains('l10n.activityReviewWriteButton'));
      expect(cardSource, contains('l10n.activityReviewEditButton'));
      expect(cardSource, contains('Icons.star_rounded'));
    },
  );

  test('review action label switches to edit after user has a review', () async {
    final source = await File(
      'lib/screens/activities/my_activities_screen.dart',
    ).readAsString();

    expect(source, contains('final Set<String> _reviewedActivityIds = {};'));
    expect(
      source,
      contains(
        'final Map<String, ActivityReviewVm> _activityReviewCache = {};',
      ),
    );
    expect(
      source,
      contains(
        'final Map<String, ActivityOrganizerReviewVm> _organizerReviewCache = {};',
      ),
    );
    expect(
      RegExp(
        r'hasReview:\s*_reviewedActivityIds\.contains\(\s*item\.id\s*,?\s*\)',
      ).hasMatch(source),
      isTrue,
    );
    expect(
      RegExp(
        r'label:\s*hasReview\s*\?\s*l10n\.activityReviewEditButton\s*:\s*l10n\.activityReviewWriteButton',
      ).hasMatch(source),
      isTrue,
    );
    expect(
      RegExp(r'_setActivityReviewState\(\s*item\.id,').hasMatch(source),
      isTrue,
    );
  });

  test(
    'review edit still validates checked-in participant before cached reviews',
    () async {
      final source = await File(
        'lib/screens/activities/my_activities_screen.dart',
      ).readAsString();

      final methodStart = source.indexOf(
        'Future<void> _openReviewSheet(ActivityListItemVm item) async',
      );
      final nextMethodStart = source.indexOf(
        'void _handleSearchChanged()',
        methodStart,
      );
      expect(methodStart, isNonNegative);
      expect(nextMethodStart, greaterThan(methodStart));

      final methodSource = source.substring(methodStart, nextMethodStart);
      final cacheBranchStart = methodSource.indexOf(
        '_reviewStateLoadedActivityIds.contains(item.id)',
      );
      final editorStart = methodSource.indexOf('_showReviewEditor(');
      final participantsFetchStart = methodSource.indexOf(
        '_activityApi.getActivityParticipants(',
      );

      expect(participantsFetchStart, isNonNegative);
      expect(cacheBranchStart, greaterThan(participantsFetchStart));
      expect(editorStart, greaterThan(cacheBranchStart));
      expect(methodSource, contains('_setReviewEligibility('));
      expect(methodSource, contains('return;'));
    },
  );

  test(
    'my activities cards open details by tap instead of open button',
    () async {
      final source = await File(
        'lib/screens/activities/my_activities_screen.dart',
      ).readAsString();

      final cardStart = source.indexOf('class _MyActivitiesCard');
      final coverStart = source.indexOf('class _ActivityCover');
      expect(cardStart, isNonNegative);
      expect(coverStart, greaterThan(cardStart));

      final cardSource = source.substring(cardStart, coverStart);
      expect(cardSource, contains('onCardTap'));
      expect(cardSource, isNot(contains('myActivitiesOpenButton')));
      expect(cardSource, isNot(contains('Icons.open_in_new_rounded')));
    },
  );

  test(
    'my activities loading skeleton avoids fixed content dimensions',
    () async {
      final source = await File(
        'lib/screens/activities/my_activities_screen.dart',
      ).readAsString();

      final skeletonStart = source.indexOf('class _MyActivitiesSkeletonCard');
      final filterSheetStart = source.indexOf('class _MyActivitiesFilterSheet');
      expect(skeletonStart, isNonNegative);
      expect(filterSheetStart, greaterThan(skeletonStart));

      final skeletonSource = source.substring(skeletonStart, filterSheetStart);
      expect(skeletonSource, contains('AspectRatio('));
      expect(skeletonSource, contains('LayoutBuilder('));
      expect(skeletonSource, contains('constraints.maxWidth'));
      expect(skeletonSource, isNot(contains('height: compact ? 188 : 210')));
      expect(skeletonSource, isNot(contains('_SkeletonLine(width: 180')));
    },
  );
}
