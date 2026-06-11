import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'foreign profile renders router initial profile while refresh loads',
    () async {
      final source = await File(
        'lib/screens/profile/profile_screen.dart',
      ).readAsString();

      expect(source, contains('UserProfileVm? _initialForeignProfile'));
      expect(source, contains('_initialForeignProfileForBuilder('));
      expect(source, contains('requestedUserId'));
      expect(
        source,
        contains('initialData: _initialForeignProfileForBuilder('),
      );
      expect(source, contains('snapshot.hasError && profile == null'));
    },
  );

  test(
    'own profile reuses public showcase previews and request badge',
    () async {
      final source = await File(
        'lib/screens/profile/profile_screen.dart',
      ).readAsString();

      expect(source, contains('incomingFriendRequestsFuture: isOwnProfile'));
      expect(source, contains('_incomingFriendRequestsFutureFor()'));
      expect(
        source,
        contains('recentActivitiesFuture: _recentActivitiesFutureFor'),
      );
      expect(
        source,
        contains('popularStoriesFuture: _popularStoriesFutureFor'),
      );
      expect(source, contains('class _IncomingFriendRequestsBadge'));
      expect(source, contains("label = data.nextOffset == null ? '1' : '1+'"));
    },
  );

  test(
    'profile stats keep loading state instead of showing false zeroes',
    () async {
      final source = await File(
        'lib/screens/profile/profile_screen.dart',
      ).readAsString();
      final gridStart = source.indexOf('class _ProfileStatsGrid');
      final gridEnd = source.indexOf('class _StatsGridLayout');

      expect(gridStart, isNonNegative);
      expect(gridEnd, greaterThan(gridStart));

      final gridSource = source.substring(gridStart, gridEnd);

      expect(gridSource, isNot(contains('snapshot.data ?? 0')));
      expect(gridSource, isNot(contains('storiesSnapshot.data ?? 0')));
      expect(gridSource, contains('activityCountLoading'));
      expect(gridSource, contains('publishedStoriesCountLoading'));
      expect(gridSource, contains('isLoading: activityCountLoading'));
    },
  );

  test(
    'foreign profile actions render as compact hero actions before about text',
    () async {
      final source = await File(
        'lib/screens/profile/profile_screen.dart',
      ).readAsString();
      final bodyStart = source.indexOf('class _ProfileBody');
      final bodyEnd = source.indexOf('class _ProfileTopBar');
      final heroStart = source.indexOf('class _ProfileHero');
      final heroEnd = source.indexOf('class _GuideRatingBadge');

      expect(bodyStart, isNonNegative);
      expect(bodyEnd, greaterThan(bodyStart));
      expect(heroStart, isNonNegative);
      expect(heroEnd, greaterThan(heroStart));

      final bodySource = source.substring(bodyStart, bodyEnd);
      final heroSource = source.substring(heroStart, heroEnd);
      final actionsIndex = heroSource.indexOf('if (actions != null)');
      final aboutIndex = heroSource.indexOf('child: Text(\n            bio,');

      expect(bodySource, contains('actions: !isOwnProfile'));
      expect(bodySource, isNot(contains('_ForeignProfileActions(')));
      expect(heroSource, contains('final Widget? actions;'));
      expect(heroSource, contains('if (actions != null) ...['));
      expect(actionsIndex, isNonNegative);
      expect(aboutIndex, isNonNegative);
      expect(actionsIndex, lessThan(aboutIndex));
      expect(source, contains('class _ProfileHeroActions'));
      expect(source, contains('class _ProfileHeroActionButton'));
      expect(source, contains('SingleChildScrollView('));
      expect(source, contains('scrollDirection: Axis.horizontal'));
    },
  );

  test(
    'empty foreign review sections do not render placeholder cards',
    () async {
      final source = await File(
        'lib/screens/profile/profile_screen.dart',
      ).readAsString();

      expect(source, contains('class _ProfileReviewSectionShell'));
      expect(source, contains('return const SizedBox.shrink();'));
      expect(source, contains('bottomSpacing: profileScaled'));
      expect(source, isNot(contains('profileActivityOrganizerReviewsEmpty,')));
      expect(source, isNot(contains('profileActivityReviewsEmpty,')));
      expect(source, isNot(contains('profileDirectGuideReviewsEmpty,')));
    },
  );

  test('profile screen does not cap platform text scaling globally', () async {
    final source = await File(
      'lib/screens/profile/profile_style.dart',
    ).readAsString();
    final scopeStart = source.indexOf('class ProfileResponsiveScope');
    final scaleStart = source.indexOf('double profileUiScale');

    expect(scopeStart, isNonNegative);
    expect(scaleStart, greaterThan(scopeStart));

    final scopeSource = source.substring(scopeStart, scaleStart);

    expect(scopeSource, isNot(contains('copyWith(textScaler')));
    expect(scopeSource, isNot(contains('TextScaler.linear')));
    expect(scopeSource, contains('return child;'));
  });

  test(
    'connections preview exposes any incoming request from first item',
    () async {
      final source = await File(
        'lib/screens/profile/profile_connections_screen.dart',
      ).readAsString();

      expect(source, contains('if (data.items.isNotEmpty)'));
      expect(source, isNot(contains('if (data.nextOffset != null)')));
    },
  );

  test(
    'edit profile keeps save action available outside long scroll content',
    () async {
      final source = await File(
        'lib/screens/profile/edit_profile_screen.dart',
      ).readAsString();

      expect(source, contains('bottomNavigationBar: SafeArea('));
      expect(source, contains('_buildStickySaveButton(l10n)'));
      expect(source, contains('profileSaveChangesButton'));
    },
  );
}
