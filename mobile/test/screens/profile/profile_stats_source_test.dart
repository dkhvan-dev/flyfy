import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile stats show activities blogs and followers', () async {
    final source =
        await File('lib/screens/profile/profile_screen.dart').readAsString();
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
        gridSource, isNot(contains('isGuideProfile ? null : onFollowersTap')));
    expect(
      resolvedSource,
      contains('onFollowersTap: () => _openFollowers(effectiveProfile)'),
    );
  });
}
