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
    'own profile exposes personal workspace actions moved from drawer',
    () async {
      final source = await File(
        'lib/screens/profile/profile_screen.dart',
      ).readAsString();
      final bodyStart = source.indexOf('class _ProfileBody');
      final sectionsStart = source.indexOf('class _OwnProfileSections');
      final quickActionsStart = source.indexOf('class _OwnProfileQuickActions');
      final quickActionsEnd = source.indexOf('class _ProfileQuickActionTile');

      expect(bodyStart, isNonNegative);
      expect(sectionsStart, greaterThan(bodyStart));
      expect(quickActionsStart, greaterThan(sectionsStart));
      expect(quickActionsEnd, greaterThan(quickActionsStart));

      final bodySource = source.substring(bodyStart, sectionsStart);
      final sectionsSource = source.substring(sectionsStart, quickActionsStart);
      final quickActionsSource = source.substring(
        quickActionsStart,
        quickActionsEnd,
      );
      final workspaceIndex = sectionsSource.indexOf(
        '_OwnProfileQuickActions()',
      );
      final journeyIndex = sectionsSource.indexOf('l10n.profileJourneyTitle');

      expect(bodySource, isNot(contains('_OwnProfileQuickActions()')));
      expect(workspaceIndex, isNonNegative);
      expect(journeyIndex, isNonNegative);
      expect(workspaceIndex, lessThan(journeyIndex));
      expect(quickActionsSource, contains('l10n.profileMyContentTitle'));
      expect(quickActionsSource, contains('Column('));
      expect(quickActionsSource, isNot(contains('Wrap(')));
      expect(quickActionsSource, isNot(contains('LayoutBuilder(')));
      expect(quickActionsSource, isNot(contains('itemWidth')));
      expect(quickActionsSource, contains('l10n.myActivitiesTitle'));
      expect(quickActionsSource, contains("context.push('/me/activities')"));
      expect(quickActionsSource, contains('l10n.myExcursionsTitle'));
      expect(quickActionsSource, contains("context.push('/me/excursions')"));
      expect(quickActionsSource, contains('l10n.travelChecklistRecentTitle'));
      expect(quickActionsSource, contains("context.push('/me/checklists')"));
      expect(quickActionsSource, contains('l10n.myStoriesTitle'));
      expect(quickActionsSource, contains("context.push('/me/posts')"));
      expect(quickActionsSource, contains('l10n.myStoryArchiveTitle'));
      expect(quickActionsSource, contains("context.push('/me/stories')"));
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

  test('empty profile bio prompt is warm and localized', () async {
    final source = await File(
      'lib/screens/profile/profile_screen.dart',
    ).readAsString();
    final ruArb = await File('lib/l10n/app_ru.arb').readAsString();
    final enArb = await File('lib/l10n/app_en.arb').readAsString();
    final kkArb = await File('lib/l10n/app_kk.arb').readAsString();

    expect(source, contains('l10n.profileEmptyBioPlaceholder'));
    expect(
      ruArb,
      contains(
        '"profileEmptyBioPlaceholder": "Несколько слов о себе помогут другим узнать вас лучше"',
      ),
    );
    expect(
      enArb,
      contains(
        '"profileEmptyBioPlaceholder": "A few words about yourself help others get to know you better"',
      ),
    );
    expect(
      kkArb,
      contains(
        '"profileEmptyBioPlaceholder": "Өзіңіз туралы бірнеше сөз басқаларға сізді жақсырақ тануға көмектеседі"',
      ),
    );
  });

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
