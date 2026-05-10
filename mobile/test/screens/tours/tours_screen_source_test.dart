import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tours screen loads public tours and guards guide-only creation',
      () async {
    final source =
        await File('lib/screens/tours/tours_screen.dart').readAsString();

    expect(source, contains('class ToursScreen'));
    expect(source, contains('loadTours('));
    expect(source, contains('refreshTours('));
    expect(source, contains('profile?.isGuide == true'));
    expect(source, contains('ToursBottomNavigation'));
    expect(source, contains('CreateActionBottomNavigationBar'));
    expect(source, contains('CommonBottomNavigationBar'));
    expect(source, contains("context.push('/tours/create')"));
    expect(source, contains("context.push('/map')"));
  });

  test('tours screen uses shared sorting, filter chrome, and accent search',
      () async {
    final source =
        await File('lib/screens/tours/tours_screen.dart').readAsString();

    expect(
        source, contains("import '../../core/ui/app_inline_sort_row.dart';"));
    expect(
        source, contains("import '../../core/ui/filter_sheet_chrome.dart';"));
    expect(source, contains('AppInlineSortRow<_ToursSortMode>'));
    expect(source, contains('toursSortLabel'));
    expect(source, contains('showModalBottomSheet<_ToursFilters>'));
    expect(source, contains('class _ToursFiltersSheet'));
    expect(source, contains('class _ToursFilters'));
    expect(source, contains('AppFilterSheetHeader'));
    expect(source, contains('AppFilterApplyButton'));
    expect(
      source,
      contains('const Icon(Icons.search_rounded, color: AppColors.accent'),
    );
    expect(source, isNot(contains('class _ToursSortTabs')));
    expect(source, isNot(contains('class _ToursFilterOption')));
  });

  test('router exposes tours list as a public route', () async {
    final routerSource =
        await File('lib/core/router/app_router.dart').readAsString();

    expect(routerSource, contains("path: '/tours'"));
    expect(routerSource, contains('ToursScreen'));
    expect(routerSource, contains("location == '/tours'"));
  });

  test('tour provider has list loading and refresh states', () async {
    final providerSource =
        await File('lib/providers/tour_provider.dart').readAsString();

    expect(providerSource, contains('Future<void> loadTours'));
    expect(providerSource, contains('Future<void> refreshTours'));
    expect(providerSource, contains('List<TourVm>'));
  });

  test('tours list resolves cover file ids into real image urls', () async {
    final source =
        await File('lib/screens/tours/tours_screen.dart').readAsString();

    expect(
        source, contains("import '../../features/tours/tour_cover_url.dart';"));
    expect(source, contains('resolveTourCoverUrl(tour)'));
    expect(source, contains('imageUrl: resolveTourCoverUrl(tour)'));
    expect(source, contains('Image.network'));
  });

  test('tour cards do not show check mark badge over cover', () async {
    final source =
        await File('lib/screens/tours/tours_screen.dart').readAsString();

    final coverArtIndex = source.indexOf('class _TourCoverArt');
    final coverPainterIndex = source.indexOf('class _TourCoverPainter');
    expect(coverArtIndex, isNonNegative);
    expect(coverPainterIndex, greaterThan(coverArtIndex));

    final coverArtSource = source.substring(coverArtIndex, coverPainterIndex);
    expect(coverArtSource, isNot(contains('Icons.check_rounded')));
  });
}
