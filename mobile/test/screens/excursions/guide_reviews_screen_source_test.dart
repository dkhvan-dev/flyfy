import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'guide reviews screen loads latest twenty reviews for current guide',
    () async {
      final source = await File(
        'lib/screens/excursions/guide_reviews_screen.dart',
      ).readAsString();

      expect(source, contains('class GuideReviewsScreen'));
      expect(source, contains('getGuideExcursionReviews('));
      expect(source, contains('limit: 20'));
      expect(source, contains("sort: 'latest'"));
      expect(source, contains('guideDashboardReviewsTitle'));
      expect(source, contains('profileGuideReviewsEmpty'));
      expect(source, contains('RefreshIndicator('));
      expect(source, contains('review.author.resolvedDisplayName'));
    },
  );

  test(
    'guide reviews screen separates excursion and direct guide reviews',
    () async {
      final source = await File(
        'lib/screens/excursions/guide_reviews_screen.dart',
      ).readAsString();

      expect(source, contains('DefaultTabController('));
      expect(source, contains('TabBar('));
      expect(source, contains('TabBarView('));
      expect(source, contains('getGuideExcursionReviews('));
      expect(source, contains('getGuideReviews('));
      expect(source, contains('GuideReviewVm'));
      expect(source, contains('guideDashboardExcursionReviewsTab'));
      expect(source, contains('guideDashboardDirectGuideReviewsTab'));
      expect(source, contains('guideDashboardDirectGuideReviewsEmpty'));
    },
  );

  test('guide reviews screen uses V2 colors only', () async {
    final source = await File(
      'lib/screens/excursions/guide_reviews_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.themeFor(context)'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.screenGradientColors'));
    expect(source, contains('colors.surface'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, isNot(contains('AppPalette.')));
  });
}
