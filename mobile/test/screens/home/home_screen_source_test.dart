import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('top destinations cards size their footer from scaled text metrics',
      () async {
    final source =
        await File('lib/screens/home/home_screen.dart').readAsString();
    final rowStart = source.indexOf('class _TopDestinationsRow');
    final rowEnd = source.indexOf('class _TopDestinationAttractionCard');
    final cardStart = rowEnd;
    final cardEnd = source.indexOf('class _DestinationBookmarkBadge');

    expect(rowStart, isNonNegative);
    expect(rowEnd, greaterThan(rowStart));
    expect(cardEnd, greaterThan(cardStart));

    final rowSource = source.substring(rowStart, rowEnd);
    final cardSource = source.substring(cardStart, cardEnd);

    expect(rowSource, contains('_homeTopDestinationCardHeight'));
    expect(rowSource, isNot(contains('final infoHeight =')));
    expect(cardSource,
        contains('final textScale = _homeTextScaleFactor(context);'));
    expect(cardSource, contains('_homeTopDestinationTitleBlockHeight'));
  });

  test('language sheet is height constrained and scrollable', () async {
    final source =
        await File('lib/screens/home/home_screen.dart').readAsString();
    final sheetStart = source.indexOf('Future<void> _showLanguageSheet()');
    final sheetEnd = source.indexOf('void _ensureGuideBadgeState');

    expect(sheetStart, isNonNegative);
    expect(sheetEnd, greaterThan(sheetStart));

    final sheetSource = source.substring(sheetStart, sheetEnd);

    expect(sheetSource, contains('maxSheetHeight'));
    expect(sheetSource, contains('ConstrainedBox'));
    expect(sheetSource, contains('SingleChildScrollView'));
  });

  test('logout confirmation uses excursions filter sheet palette', () async {
    final source =
        await File('lib/screens/home/home_screen.dart').readAsString();
    final confirmStart = source.indexOf('Future<void> _confirmLogout()');
    final confirmEnd = source.indexOf('Future<void> _loadTopAttractions');
    final dialogStart = source.indexOf('class _LogoutConfirmDialog');
    final dialogEnd = source.indexOf('class _HomeHeader');

    expect(confirmStart, isNonNegative);
    expect(confirmEnd, greaterThan(confirmStart));
    expect(dialogStart, isNonNegative);
    expect(dialogEnd, greaterThan(dialogStart));

    final confirmSource = source.substring(confirmStart, confirmEnd);
    final dialogSource = source.substring(dialogStart, dialogEnd);

    expect(confirmSource, contains('_LogoutConfirmDialog('));
    expect(confirmSource, isNot(contains('AlertDialog(')));
    expect(dialogSource, contains('Icons.logout_rounded'));
    expect(dialogSource, contains('Color(0xFF21170D)'));
    expect(dialogSource, contains('Color(0x293A270F)'));
    expect(dialogSource, contains('Color(0xFF2C2118)'));
    expect(dialogSource, contains('Color(0xFF3B260D)'));
    expect(dialogSource, contains('Wrap('));
    expect(dialogSource, contains('AppColors.accent'));
    expect(dialogSource, isNot(contains('Color(0xFF243435)')));
    expect(dialogSource, isNot(contains('Color(0xFF7ED7C1)')));
  });

  test('excursions quick action opens the excursions list screen', () async {
    final source =
        await File('lib/screens/home/home_screen.dart').readAsString();

    expect(source, contains('void _openExcursions()'));
    expect(source, contains("context.push('/excursions')"));
    expect(source, contains('onTap: _openExcursions'));
  });

  test('home nav tap scrolls the current home feed to the top', () async {
    final source =
        await File('lib/screens/home/home_screen.dart').readAsString();
    final stateStart = source.indexOf('class _HomeScreenState');
    final buildStart = source.indexOf('@override\n  Widget build');

    expect(stateStart, isNonNegative);
    expect(buildStart, greaterThan(stateStart));

    final stateSource = source.substring(stateStart, buildStart);

    expect(stateSource, contains('final ScrollController _scrollController'));
    expect(stateSource, contains('void _handleHomeNavTap()'));
    expect(stateSource, contains('_scrollController.animateTo('));
    expect(stateSource, contains('void dispose()'));
    expect(source, contains('controller: _scrollController'));
    expect(source, contains('onHomeTap: _handleHomeNavTap'));
    expect(source, isNot(contains("onHomeTap: () => context.go('/')")));
  });

  test('home location is managed by a discovery provider and resolver',
      () async {
    final source =
        await File('lib/screens/home/home_screen.dart').readAsString();

    expect(source, contains('HomeLocationProvider'));
    expect(source, contains('HomeLocationPickerSheet'));
    expect(source, contains('AppLocalizedLocationText'));
    expect(source, contains('onLocationTap: _openLocationSheet'));
    expect(source, isNot(contains('_localizedCountryNames')));
    expect(source, isNot(contains('_localizedCityNames')));
  });

  test('home location sheet uses city search and localized selected preview',
      () async {
    final sheetSource = await File(
      'lib/screens/home/widgets/home_location_picker_sheet.dart',
    ).readAsString();
    final ruArb = await File('lib/l10n/app_ru.arb').readAsString();

    final previewStart = sheetSource.indexOf('class _CurrentLocationPreview');
    final previewEnd = sheetSource.indexOf('class _DetectLocationButton');

    expect(previewStart, isNonNegative);
    expect(previewEnd, greaterThan(previewStart));

    final previewSource = sheetSource.substring(previewStart, previewEnd);

    expect(ruArb, contains('"homeLocationSearchHint": "Поиск города"'));
    expect(previewSource, contains('AppLocalizedLocationText'));
    expect(previewSource, contains('countryCode: location.countryCode'));
    expect(previewSource, contains('cityId: location.cityId'));
    expect(previewSource, contains('cityName: location.cityName'));
    expect(previewSource, isNot(contains('Text(\n                  value,')));
    expect(sheetSource, contains('Icons.location_off_rounded'));
    expect(sheetSource, contains('color: AppColors.accent'));
  });

  test('home discovery location stays out of activity creation requests',
      () async {
    final providerSource =
        await File('lib/providers/home_location_provider.dart').readAsString();
    final createActivitySource =
        await File('lib/screens/activities/create_activity_screen.dart')
            .readAsString();

    expect(providerSource, contains('class HomeLocationProvider'));
    expect(providerSource, contains('flyfy_home_location_preference'));
    expect(createActivitySource, isNot(contains('HomeLocationProvider')));
    expect(createActivitySource, isNot(contains('homeLocationProvider')));
  });

  test('drawer opening refreshes verified guide badge state', () async {
    final source =
        await File('lib/screens/home/home_screen.dart').readAsString();

    final ensureStart = source.indexOf('void _ensureGuideBadgeState(');
    final buildStart = source.indexOf('@override\n  Widget build');
    final scaffoldStart = source.indexOf('return Scaffold(', buildStart);
    final scaffoldEnd = source.indexOf('drawer: AppSideDrawer(', scaffoldStart);

    expect(ensureStart, isNonNegative);
    expect(buildStart, greaterThan(ensureStart));
    expect(scaffoldStart, greaterThan(buildStart));
    expect(scaffoldEnd, greaterThan(scaffoldStart));

    final ensureSource = source.substring(ensureStart, buildStart);
    final scaffoldSource = source.substring(scaffoldStart, scaffoldEnd);

    expect(ensureSource, contains('{bool force = false}'));
    expect(ensureSource,
        contains('final isNewUser = _guideBadgeUserId != normalizedUserId'));
    expect(ensureSource, contains('if (!force && !isNewUser)'));
    expect(scaffoldSource, contains('onDrawerChanged:'));
    expect(scaffoldSource,
        contains('_ensureGuideBadgeState(currentUserId, force: true)'));
  });

  test('promo carousel is passive and sizes cards from content metrics',
      () async {
    final source =
        await File('lib/screens/home/home_screen.dart').readAsString();
    final carouselStart = source.indexOf('class _PromoCarousel');
    final carouselEnd = source.indexOf('class _PromoCard');
    final cardStart = carouselEnd;
    final cardEnd = source.indexOf('class _TopDestinationsRow');
    final dataStart = source.indexOf('class _PromoCardData');
    final dataEnd = source.indexOf('const List<_LanguageOption>', dataStart);

    expect(carouselStart, isNonNegative);
    expect(carouselEnd, greaterThan(carouselStart));
    expect(cardEnd, greaterThan(cardStart));
    expect(dataStart, isNonNegative);
    expect(dataEnd, greaterThan(dataStart));

    final carouselSource = source.substring(carouselStart, carouselEnd);
    final cardSource = source.substring(cardStart, cardEnd);
    final dataSource = source.substring(dataStart, dataEnd);

    expect(carouselSource, contains('_homePromoCardHeight('));
    expect(carouselSource, isNot(contains('required this.onTap')));
    expect(cardSource, isNot(contains('InkWell(')));
    expect(cardSource, isNot(contains('_HomePrimaryPill')));
    expect(cardSource, isNot(contains('data.buttonLabel')));
    expect(dataSource, isNot(contains('buttonLabel')));
    expect(source, isNot(contains('homePromoExplore')));
  });

  test('top destinations use backend attraction categories, not tag fallback',
      () async {
    final source =
        await File('lib/screens/home/home_screen.dart').readAsString();

    final labelMatch = RegExp(
      r'String\?? _homeAttractionCategoryLabel\(',
    ).firstMatch(source);
    final labelStart = labelMatch?.start ?? -1;
    final nextFunctionStart = source.indexOf(
      'String _homeStoryTagLabel',
      labelStart < 0 ? 0 : labelStart,
    );

    expect(labelStart, isNonNegative);
    expect(nextFunctionStart, greaterThan(labelStart));

    final labelSource = source.substring(labelStart, nextFunctionStart);

    for (final category in [
      'NATURE',
      'ARCHITECTURE',
      'MUSEUM',
      'BEACH',
      'PARK',
      'TEMPLE',
      'ENTERTAINMENT',
      'FOOD',
      'MARKET',
      'SHOPPING',
      'OTHER',
    ]) {
      expect(labelSource, contains("case '$category':"));
    }

    expect(labelSource, contains('l10n.attractionFilterCategoryOther'));
    expect(labelSource, isNot(contains('for (final tag in attraction.tags)')));
  });

  test(
    'recommended activities use localized taxonomy labels and compact text',
    () async {
      final source =
          await File('lib/screens/home/home_screen.dart').readAsString();
      final sectionStart = source.indexOf(
        'class _RecommendedActivitiesSection',
      );
      final cardStart = source.indexOf('class _RecommendedActivityCard');
      final buttonStart = source.indexOf('class _ActivityJoinButton');

      expect(sectionStart, isNonNegative);
      expect(cardStart, greaterThan(sectionStart));
      expect(buttonStart, greaterThan(cardStart));

      final sectionSource = source.substring(sectionStart, cardStart);
      final cardSource = source.substring(cardStart, buttonStart);

      expect(
        source,
        contains(
          "import '../../features/activities/activity_taxonomy_resolver.dart';",
        ),
      );
      expect(source, contains('provider.loadActivityCategories();'));
      expect(sectionSource, contains('categories: provider.categoryItems'));
      expect(sectionSource, contains('languageCode:'));
      expect(cardSource, contains('localizedActivityCategoryLabel('));
      expect(cardSource, contains('localizedActivitySubcategoryLabel('));
      expect(cardSource,
          contains("return '\$categoryLabel / \$subcategoryLabel';"));
      expect(cardSource, isNot(contains('ActivityCategoryVm.humanizeSlug')));
      expect(cardSource, contains('fontSize: isCompact ? 15 : 16'));
      expect(cardSource, contains('fontSize: isCompact ? 11.5 : 12'));
      expect(cardSource, contains('fontSize: isCompact ? 16 : 17'));
    },
  );
}
