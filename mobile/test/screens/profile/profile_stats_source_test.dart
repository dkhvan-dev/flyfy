import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile stats show activities stories and followers', () async {
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
    final storiesIndex = gridSource.indexOf('profileStoriesStat');
    final followersIndex = gridSource.indexOf('profileFollowersStat');

    expect(activitiesIndex, isNonNegative);
    expect(storiesIndex, greaterThan(activitiesIndex));
    expect(followersIndex, greaterThan(storiesIndex));
    expect(gridSource, isNot(contains('profileBlogsStat')));
    expect(gridSource, isNot(contains('profileReviewsStat')));
    expect(gridSource, contains(r"'${profile.followersCount}'"));
    expect(RegExp('highlighted: true').allMatches(gridSource), hasLength(3));
    expect(
      gridSource,
      isNot(contains('isGuideProfile ? null : onFollowersTap')),
    );
    expect(
      resolvedSource,
      contains(
        'final VoidCallback onFollowersTap = isOwnProfile || canUseProtectedActions',
      ),
    );
    expect(
      resolvedSource,
      contains('? () => _openFollowers(effectiveProfile)'),
    );
    expect(resolvedSource, contains(': _openLoginForProtectedAction;'));
    expect(resolvedSource, contains('onFollowersTap: onFollowersTap'));
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

  test('profile published stories stat uses public author counter', () async {
    final source = await File(
      'lib/screens/profile/profile_screen.dart',
    ).readAsString();
    final statsFutureStart = source.indexOf(
      'Future<int> _publishedStoriesCountFutureFor',
    );
    final statsFutureEnd = source.indexOf(
      'Future<ExcursionReviewsPage>',
      statsFutureStart,
    );
    final gridStart = source.indexOf('class _ProfileStatsGrid');
    final gridEnd = source.indexOf('class _StatsGridLayout');

    expect(statsFutureStart, isNonNegative);
    expect(statsFutureEnd, greaterThan(statsFutureStart));
    expect(gridStart, isNonNegative);
    expect(gridEnd, greaterThan(gridStart));

    final statsFutureSource = source.substring(
      statsFutureStart,
      statsFutureEnd,
    );
    final gridSource = source.substring(gridStart, gridEnd);

    expect(source, contains("import '../../core/network/post_api.dart';"));
    expect(source, contains('PostApi _postApi = PostApi()'));
    expect(statsFutureSource, contains('countPublishedPostsForUser('));
    expect(statsFutureSource, contains('profile.userId.trim()'));
    expect(gridSource, contains('publishedStoriesCountFuture'));
    expect(gridSource, contains('publishedStoriesCount'));
    expect(gridSource, isNot(contains("value: '0'")));
  });

  test('own profile menu omits bookings and my activities shortcuts', () async {
    final source = await File(
      'lib/screens/profile/profile_screen.dart',
    ).readAsString();
    final sectionsStart = source.indexOf('class _OwnProfileSections');
    final sectionsEnd = source.indexOf('class _OwnProfileQuickActions');

    expect(sectionsStart, isNonNegative);
    expect(sectionsEnd, greaterThan(sectionsStart));

    final sectionsSource = source.substring(sectionsStart, sectionsEnd);

    expect(sectionsSource, isNot(contains('profileBookingsTitle')));
    expect(sectionsSource, isNot(contains('profileBookingsSubtitle')));
    expect(sectionsSource, isNot(contains('myActivitiesTitle')));
    expect(sectionsSource, isNot(contains('profileMyActivitiesSubtitle')));
    expect(sectionsSource, isNot(contains("context.push('/me/activities')")));
  });

  test(
    'profile hero shows full name and hides country currency badges',
    () async {
      final source = await File(
        'lib/screens/profile/profile_screen.dart',
      ).readAsString();
      final heroStart = source.indexOf('class _ProfileHero');
      final avatarStart = source.indexOf('class _ProfileAvatar');
      final extrasStart = source.indexOf('class _ProfileExtras');
      final reviewInitialStart = source.indexOf('String _reviewInitial');

      expect(heroStart, isNonNegative);
      expect(avatarStart, greaterThan(heroStart));
      expect(extrasStart, isNonNegative);
      expect(reviewInitialStart, greaterThan(extrasStart));

      final heroSource = source.substring(heroStart, avatarStart);
      final extrasSource = source.substring(extrasStart, reviewInitialStart);

      expect(
        source,
        isNot(contains("import '../../core/network/reference_api.dart';")),
      );
      expect(
        source,
        isNot(contains('ReferenceApi _referenceApi = ReferenceApi()')),
      );
      expect(source, isNot(contains('getCountry(')));
      expect(source, isNot(contains('listCurrencies(')));
      expect(source, isNot(contains('normalizeReferenceCountryCode(')));
      expect(source, isNot(contains('referenceCurrencyLabel(')));
      expect(source, isNot(contains('_resolveProfileReferenceLabels(')));
      expect(extrasSource, isNot(contains('referenceLabels')));
      expect(heroSource, contains('profile.fullName'));
      expect(heroSource, contains('if (fullName.isNotEmpty'));
      expect(heroSource, isNot(contains('referenceLabels.country')));
      expect(heroSource, isNot(contains('referenceLabels.currency')));
      expect(heroSource, isNot(contains('profile.countryCode')));
      expect(heroSource, isNot(contains('profile.currency')));
    },
  );

  test('profile avatar clips the image and inner border as a circle', () async {
    final source = await File(
      'lib/screens/profile/profile_screen.dart',
    ).readAsString();
    final avatarStart = source.indexOf('class _ProfileAvatar');
    final extrasStart = source.indexOf('class _ProfileExtras');

    expect(avatarStart, isNonNegative);
    expect(extrasStart, greaterThan(avatarStart));

    final avatarSource = source.substring(avatarStart, extrasStart);
    final clipStart = avatarSource.indexOf('child: ClipOval(');
    final imageSwitchStart = avatarSource.indexOf('child: avatarUrl == null');

    expect(clipStart, isNonNegative);
    expect(imageSwitchStart, greaterThan(clipStart));

    final clippedDecorationSource = avatarSource.substring(
      clipStart,
      imageSwitchStart,
    );

    expect(clippedDecorationSource, contains('shape: BoxShape.circle'));
    expect(avatarSource, contains('Image.network('));
    expect(avatarSource, contains('fit: BoxFit.cover'));
  });

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
      expect(source, contains('return const SizedBox.shrink();'));
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
      expect(source, contains('return const SizedBox.shrink();'));
      expect(source, contains('GuideReviewVm'));
      expect(source, contains('directGuideReviewsFuture:'));
    },
  );

  test(
    'foreign verified guide profile shows rating and calendar action',
    () async {
      final source = await File(
        'lib/screens/profile/profile_screen.dart',
      ).readAsString();
      final heroStart = source.indexOf('class _ProfileHero');
      final heroEnd = source.indexOf('class _ProfileAvatar');
      final bodyStart = source.indexOf('class _ProfileBody');
      final bodyEnd = source.indexOf('class _ProfileTopBar');
      final actionsStart = source.indexOf('class _ProfileHeroActions');
      final actionsEnd = source.indexOf('class _ProfileHeroActionButton');

      expect(heroStart, isNonNegative);
      expect(heroEnd, greaterThan(heroStart));
      expect(bodyStart, isNonNegative);
      expect(bodyEnd, greaterThan(bodyStart));
      expect(actionsStart, isNonNegative);
      expect(actionsEnd, greaterThan(actionsStart));

      final heroSource = source.substring(heroStart, heroEnd);
      final bodySource = source.substring(bodyStart, bodyEnd);
      final actionsSource = source.substring(actionsStart, actionsEnd);

      expect(heroSource, contains('class _GuideRatingBadge'));
      expect(heroSource, contains('_GuideRatingBadge(guide: guide!)'));
      expect(heroSource, contains('guide.ratingAvg'));
      expect(heroSource, contains('profileGuideRatingLabel'));
      expect(heroSource, isNot(contains('profileGuideRatingSummary(')));
      expect(heroSource, isNot(contains('guide.reviewsCount')));
      expect(bodySource, contains('onGuideCalendarTap: isGuideProfile'));
      expect(actionsSource, contains('guideCalendarTitle'));
      expect(actionsSource, contains('Icons.calendar_month_rounded'));
      expect(
        bodySource,
        contains("context.push('/guides/\${profile.userId}/calendar')"),
      );
    },
  );
}
