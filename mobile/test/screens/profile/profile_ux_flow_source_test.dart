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
    'every foreign profile saves its user id from the DETAIL surface',
    () async {
      final source = await File(
        'lib/screens/profile/profile_screen.dart',
      ).readAsString();
      final topBarBuilderStart = source.indexOf('Widget _buildProfileTopBar');
      final topBarClassStart = source.indexOf('class _ProfileTopBar');

      expect(topBarBuilderStart, isNonNegative);
      expect(topBarClassStart, greaterThan(topBarBuilderStart));

      final topBarBuilderSource = source.substring(
        topBarBuilderStart,
        topBarClassStart,
      );

      expect(source, contains("saved_operation.dart';"));
      expect(source, contains("saved_target.dart';"));
      expect(source, contains('app_saved_bookmark_button.dart'));
      expect(
        topBarBuilderSource,
        isNot(contains("guide?.status.trim().toUpperCase() == 'ACTIVE'")),
      );
      expect(topBarBuilderSource, contains('!isOwnProfile'));
      expect(topBarBuilderSource, contains('SavedTarget.tryCreate('));
      expect(topBarBuilderSource, contains('AppSavedBookmarkButton('));
      expect(topBarBuilderSource, contains('entityType: SavedEntityType.user'));
      expect(topBarBuilderSource, contains('entityId: profile.userId'));
      expect(topBarBuilderSource, isNot(contains('entityId: guide.id')));
      expect(
        topBarBuilderSource,
        contains('sourceSurface: SavedSourceSurface.detail'),
      );
      expect(topBarBuilderSource, contains('dimension: AppSizes.minTapTarget'));
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
    'own profile quick action rows use visible V2 borders without heavy card fill',
    () async {
      final source = await File(
        'lib/screens/profile/profile_screen.dart',
      ).readAsString();
      final tileStart = source.indexOf('class _ProfileQuickActionTile');
      final tileEnd = source.indexOf('class _IncomingFriendRequestsBadge');

      expect(tileStart, isNonNegative);
      expect(tileEnd, greaterThan(tileStart));

      final tileSource = source.substring(tileStart, tileEnd);
      final inkStart = tileSource.indexOf('child: Ink(');
      final rowStart = tileSource.indexOf('child: Row(', inkStart);

      expect(inkStart, isNonNegative);
      expect(rowStart, greaterThan(inkStart));

      final rowShellSource = tileSource.substring(inkStart, rowStart);

      expect(tileSource, contains('Material('));
      expect(tileSource, contains('color: context.profileColors.transparent'));
      expect(tileSource, contains('InkWell('));
      expect(tileSource, contains('Ink('));
      expect(tileSource, isNot(contains('profileCardDecoration(')));
      expect(rowShellSource, contains('decoration: AppBoxDecoration('));
      expect(rowShellSource, contains('color: context.profileColors.surface'));
      expect(rowShellSource, contains('borderRadius:'));
      expect(rowShellSource, contains('border: Border.all('));
      expect(rowShellSource, contains('color: context.profileColors.border'));
      expect(tileSource, contains('AppEdgeInsets.symmetric('));
    },
  );

  test(
    'profile hero action buttons keep visible borders on light V2 surfaces',
    () async {
      final source = await File(
        'lib/screens/profile/profile_screen.dart',
      ).readAsString();
      final actionStart = source.indexOf('class _ProfileHeroActionButton');
      final sectionsStart = source.indexOf('class _OwnProfileSections');

      expect(actionStart, isNonNegative);
      expect(sectionsStart, greaterThan(actionStart));

      final actionSource = source.substring(actionStart, sectionsStart);

      expect(actionSource, contains('final isLight ='));
      expect(actionSource, contains('context.profileColors.surface'));
      expect(actionSource, contains('context.profileColors.border'));
      expect(actionSource, contains('final borderColor ='));
      expect(actionSource, contains('color: borderColor'));
      expect(
        actionSource,
        isNot(
          contains(
            'effectiveColor.withValues(\n                        alpha: enabled ? 0.46 : 0.22',
          ),
        ),
      );
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
    'profile completion banner keeps edit action inside flexible text column',
    () async {
      final source = await File(
        'lib/screens/profile/profile_screen.dart',
      ).readAsString();
      final bannerStart = source.indexOf('class _ProfileBanner');
      final nextClassStart = source.indexOf('class ', bannerStart + 1);

      expect(bannerStart, isNonNegative);
      expect(nextClassStart, greaterThan(bannerStart));

      final bannerSource = source.substring(bannerStart, nextClassStart);
      final expandedStart = bannerSource.indexOf('Expanded(');
      final buttonStart = bannerSource.indexOf('TextButton(');
      final rowSiblingButtonStart = bannerSource.indexOf(
        'if (onTap != null)\n            TextButton(',
      );

      expect(expandedStart, isNonNegative);
      expect(buttonStart, greaterThan(expandedStart));
      expect(rowSiblingButtonStart, isNegative);
      expect(bannerSource, contains('AlignmentDirectional.centerStart'));
    },
  );

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
