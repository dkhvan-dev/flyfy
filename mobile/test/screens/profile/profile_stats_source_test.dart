import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile stats show activities blogs and followers', () async {
    final source = await File(
      'lib/screens/profile/profile_screen.dart',
    ).readAsString();
    final resolvedStart = source.indexOf('Widget _buildResolvedProfile(');
    final resolvedEnd = source.indexOf('class _ProfileBody');
    final gridStart = source.indexOf('class _ProfileStatsGrid');
    final gridEnd = source.indexOf('class _StatsGridLayout');

    expect(resolvedStart, isNonNegative);
    expect(resolvedEnd, greaterThan(resolvedStart));
    expect(gridStart, isNonNegative);
    expect(gridEnd, greaterThan(gridStart));

    final resolvedSource = source.substring(resolvedStart, resolvedEnd);
    final gridSource = source.substring(gridStart, gridEnd);

    final activitiesIndex = gridSource.indexOf('profileActivitiesStat');
    final blogsIndex = gridSource.indexOf('profileBlogsStat');
    final followersIndex = gridSource.indexOf('profileFollowersStat');

    expect(activitiesIndex, isNonNegative);
    expect(blogsIndex, greaterThan(activitiesIndex));
    expect(followersIndex, greaterThan(blogsIndex));
    expect(gridSource, isNot(contains('profileReviewsStat')));
    expect(gridSource, contains(r"'${profile.followersCount}'"));
    expect(RegExp('highlighted: true').allMatches(gridSource), hasLength(3));
    expect(
      gridSource,
      isNot(contains('isGuideProfile ? null : onFollowersTap')),
    );
    expect(
      resolvedSource,
      contains('onFollowersTap: () => _openFollowers(effectiveProfile)'),
    );
  });

  test(
    'profile activity stat uses the same public counter for every viewer',
    () async {
      final source = await File(
        'lib/screens/profile/profile_screen.dart',
      ).readAsString();
      final statsFutureStart = source.indexOf(
        'Future<int> _activityCountFutureFor',
      );
      final statsFutureEnd = source.indexOf(
        'Future<ExcursionReviewsPage>',
        statsFutureStart,
      );

      expect(statsFutureStart, isNonNegative);
      expect(statsFutureEnd, greaterThan(statsFutureStart));

      final statsFutureSource = source.substring(
        statsFutureStart,
        statsFutureEnd,
      );

      expect(statsFutureSource, contains('countCompletedActivitiesForUser('));
      expect(statsFutureSource, contains('profile.userId.trim()'));
      expect(statsFutureSource, isNot(contains('isOwnProfile')));
      expect(source, isNot(contains('getMyCompletionStats(')));
      expect(source, isNot(contains('hostedCompleted + joinedCompleted')));
    },
  );

  test(
    'foreign guide profile loads and renders top excursion reviews',
    () async {
      final source = await File(
        'lib/screens/profile/profile_screen.dart',
      ).readAsString();

      expect(source, contains('ExcursionApi _excursionApi = ExcursionApi()'));
      expect(source, contains('_guideReviewsFutureFor('));
      expect(source, contains('getGuideExcursionReviews('));
      expect(source, contains("sort: 'rating_desc'"));
      expect(source, contains('limit: 10'));
      expect(source, contains('class _GuideExcursionReviewsSection'));
      expect(source, contains('profileGuideReviewsTitle'));
      expect(source, contains('profileGuideReviewsEmpty'));
      expect(source, contains('review.author.resolvedDisplayName'));
    },
  );

  test(
    'foreign guide profile renders direct guide reviews separately',
    () async {
      final source = await File(
        'lib/screens/profile/profile_screen.dart',
      ).readAsString();

      expect(source, contains('_directGuideReviewsFutureFor('));
      expect(source, contains('getGuideReviews('));
      expect(source, contains('class _DirectGuideReviewsSection'));
      expect(source, contains('profileDirectGuideReviewsTitle'));
      expect(source, contains('profileDirectGuideReviewsEmpty'));
      expect(source, contains('GuideReviewVm'));
      expect(source, contains('directGuideReviewsFuture:'));
    },
  );
}
