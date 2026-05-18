import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('guide reviews screen loads latest twenty reviews for current guide',
      () async {
    final source = await File(
      'lib/screens/excursions/guide_reviews_screen.dart',
    ).readAsString();

    expect(source, contains('class GuideReviewsScreen'));
    expect(source, contains('getGuideExcursionReviews('));
    expect(source, contains('limit: 20'));
    expect(source, contains("sort: 'latest'"));
    expect(source, contains('profileGuideReviewsLatestTitle'));
    expect(source, contains('profileGuideReviewsEmpty'));
    expect(source, contains('RefreshIndicator('));
    expect(source, contains('review.author.resolvedDisplayName'));
  });
}
