import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'foreign profile renders recent activities and opens paginated tabs',
    () async {
      final profileSource = await File(
        'lib/screens/profile/profile_screen.dart',
      ).readAsString();
      final userActivitiesSource = await File(
        'lib/screens/profile/profile_user_activities_screen.dart',
      ).readAsString();
      final profileActivityCardSource = await File(
        'lib/screens/profile/widgets/profile_activity_card.dart',
      ).readAsString();
      final sharedActivityArtSource = await File(
        'lib/features/activities/activity_category_art.dart',
      ).readAsString();
      final activitiesScreenSource = await File(
        'lib/screens/activities/activities_screen.dart',
      ).readAsString();
      final routerSource = await File(
        'lib/core/router/app_router.dart',
      ).readAsString();
      final apiSource = await File(
        'lib/core/network/activity_api.dart',
      ).readAsString();
      final backendHandlerSource = await File(
        '../backend/services/activity-service/internal/adapter/http/handler.go',
      ).readAsString();
      final backendUseCaseSource = await File(
        '../backend/services/activity-service/internal/app/activity_usecase.go',
      ).readAsString();
      final backendRepositorySource = await File(
        '../backend/services/activity-service/internal/adapter/repository/pg_activity_repository.go',
      ).readAsString();

      expect(
        profileSource,
        contains(
          'Future<List<ActivityListItemVm>>? _foreignRecentActivitiesFuture',
        ),
      );
      expect(profileSource, contains('_recentActivitiesFutureFor'));
      expect(profileSource, contains('getUserRecentActivities('));
      expect(
        profileSource,
        contains(
          'static const int _foreignProfileRecentActivitiesPreviewLimit = 3;',
        ),
      );
      final recentActivitiesFutureSource = profileSource.substring(
        profileSource.indexOf(
          'Future<List<ActivityListItemVm>> _recentActivitiesFutureFor',
        ),
        profileSource.indexOf('Future<int> _publishedStoriesCountFutureFor'),
      );
      expect(
        recentActivitiesFutureSource,
        contains(r'|$_foreignProfileRecentActivitiesPreviewLimit'),
      );
      expect(
        recentActivitiesFutureSource,
        contains('limit: _foreignProfileRecentActivitiesPreviewLimit'),
      );
      expect(recentActivitiesFutureSource, isNot(contains('limit: 10')));
      expect(profileSource, contains('_ForeignRecentActivitiesSection('));
      final recentActivitiesSectionSource = profileSource.substring(
        profileSource.indexOf('class _ForeignRecentActivitiesSection'),
        profileSource.indexOf('class _ForeignRecentActivitiesSkeleton'),
      );
      expect(recentActivitiesSectionSource, isNot(contains('kicker:')));
      expect(
        recentActivitiesSectionSource,
        isNot(contains('profileGuideTitle')),
      );
      expect(
        recentActivitiesSectionSource,
        contains('ProfileCompactActivityCard('),
      );
      expect(profileSource, contains('context.push('));
      expect(
        profileSource,
        contains("'/users/\${Uri.encodeComponent(userId)}/activities'"),
      );
      expect(
        profileSource,
        isNot(contains('profileHostedActivitiesUnavailable')),
      );

      expect(
        userActivitiesSource,
        contains('class ProfileUserActivitiesScreen'),
      );
      expect(userActivitiesSource, contains('DefaultTabController'));
      expect(userActivitiesSource, contains('Expanded('));
      expect(userActivitiesSource, contains('profileUserActivitiesHostedTab'));
      expect(userActivitiesSource, contains('profileUserActivitiesVisitedTab'));
      expect(userActivitiesSource, contains('InflapPaginationBar'));
      expect(userActivitiesSource, contains('getUserHostedActivitiesPage'));
      expect(userActivitiesSource, contains('getUserJoinedActivitiesPage'));
      expect(userActivitiesSource, contains('AppListSearchField('));
      expect(userActivitiesSource, contains('AppInlineSortRow<'));
      expect(
          userActivitiesSource, contains('AlignmentDirectional.centerStart'));
      expect(userActivitiesSource, contains('showModalBottomSheet'));
      expect(userActivitiesSource, contains('AppDismissibleModalSheet('));
      expect(userActivitiesSource, contains('_ProfileActivityFilters'));
      expect(userActivitiesSource, contains('previewCountBuilder'));
      expect(userActivitiesSource, contains('activitiesShowResults('));
      expect(userActivitiesSource, contains('_openFilters'));
      expect(userActivitiesSource, contains('_handleSearchChanged'));
      expect(userActivitiesSource, contains('_activeFilterCount'));
      expect(userActivitiesSource, contains('_sortQueryParam'));
      expect(
        userActivitiesSource,
        contains('categorySlug: _filters.categorySlug'),
      );
      expect(userActivitiesSource, contains('format: _filters.format'));
      expect(userActivitiesSource, contains('priceType: _filters.priceType'));
      expect(userActivitiesSource, contains('query: _searchQuery'));
      expect(userActivitiesSource, isNot(contains('NestedScrollView')));
      expect(userActivitiesSource, isNot(contains('SliverPersistentHeader')));
      expect(
        userActivitiesSource,
        isNot(contains('SliverPersistentHeaderDelegate')),
      );

      expect(
        profileActivityCardSource,
        contains(
          "import '../../../features/activities/activity_category_art.dart';",
        ),
      );
      expect(profileActivityCardSource, contains('ActivityDecorativeCover('));
      expect(
        profileActivityCardSource,
        contains('activityCardArtForItem(item)'),
      );
      expect(
        profileActivityCardSource,
        contains('class ProfileCompactActivityCard'),
      );
      expect(profileActivityCardSource, contains('_compactActivityMetaText'));
      expect(
        profileActivityCardSource,
        isNot(contains('final fallback = DecoratedBox')),
      );

      expect(sharedActivityArtSource, contains('class ActivityCardArtSpec'));
      expect(sharedActivityArtSource, contains('ActivityDecorativeCover'));
      expect(sharedActivityArtSource, contains('activityCardArtForItem'));
      expect(sharedActivityArtSource, contains("slug.contains('nature')"));
      expect(sharedActivityArtSource, contains("slug.contains('sport')"));

      expect(
        activitiesScreenSource,
        contains(
          "import '../../features/activities/activity_category_art.dart';",
        ),
      );
      expect(activitiesScreenSource, contains('activityCardArtForItem(item)'));
      expect(activitiesScreenSource, contains('ActivityDecorativeCover('));
      expect(
        activitiesScreenSource,
        isNot(contains('class _DecorativeActivityCover')),
      );
      expect(activitiesScreenSource, isNot(contains('class _CardArtSpec')));

      expect(routerSource, contains("path: '/users/:userId/activities'"));
      expect(
        routerSource,
        contains('ProfileUserActivitiesScreen(userId: userId)'),
      );

      expect(
        apiSource,
        contains('Future<ActivityListPageVm> getUserHostedActivitiesPage'),
      );
      expect(
        apiSource,
        contains('Future<ActivityListPageVm> getUserJoinedActivitiesPage'),
      );
      expect(apiSource, contains('String? query'));
      expect(apiSource, contains('String? categorySlug'));
      expect(apiSource, contains('String? format'));
      expect(apiSource, contains('String? priceType'));
      expect(apiSource, contains('String? sort'));
      expect(apiSource, contains("if ((query ?? '').trim().isNotEmpty)"));
      expect(apiSource, contains("'categorySlug': categorySlug!.trim()"));
      expect(apiSource, contains("'priceType': priceType!.trim()"));
      expect(apiSource, contains("'sort': sort!.trim()"));
      expect(
        apiSource,
        contains('Future<List<ActivityListItemVm>> getUserRecentActivities'),
      );
      expect(apiSource, contains("'/activities/users/\$encodedUserId/hosted'"));
      expect(apiSource, contains("'/activities/users/\$encodedUserId/joined'"));
      expect(
        apiSource,
        contains("Options(extra: const {'requiresAuth': false})"),
      );

      expect(backendHandlerSource, contains('ListUserHostedActivities'));
      expect(backendHandlerSource, contains('ListUserJoinedActivities'));
      expect(
        backendHandlerSource,
        contains('ListPublicProfileHostedActivities'),
      );
      expect(
        backendHandlerSource,
        contains('ListPublicProfileJoinedActivities'),
      );
      expect(
        backendHandlerSource,
        contains('profileActivityListInputFromRequest'),
      );
      expect(backendHandlerSource, contains('query.Get("q")'));
      expect(backendHandlerSource, contains('query.Get("categorySlug")'));
      expect(backendHandlerSource, contains('query.Get("priceType")'));
      expect(
        backendUseCaseSource,
        contains('type PublicProfileActivityListInput'),
      );
      expect(
        backendUseCaseSource,
        contains('strings.TrimSpace(input.SearchQuery)'),
      );
      expect(
        backendRepositorySource,
        contains('appendPublicProfileActivityFilters'),
      );
      expect(backendRepositorySource, contains('publicProfileActivityOrderBy'));
    },
  );
}
