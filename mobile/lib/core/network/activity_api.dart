import 'package:dio/dio.dart';

import '../../features/activities/models/activity_category_vm.dart';
import '../../features/activities/models/activity_list_item_vm.dart';
import '../../features/activities/models/activity_participant_vm.dart';
import '../../features/activities/models/create_activity_request.dart';
import '../../features/activities/models/update_activity_request.dart';
import 'api_client.dart';

class ActivityApi {
  ActivityApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<ActivityCategoryVm>> getActivityCategories() async {
    final response = await _apiClient.dio.get(
      '/activity-categories',
      options: Options(extra: const {'requiresAuth': false}),
    );

    final data = response.data;
    final items = (data is Map<String, dynamic>
            ? data['items'] as List<dynamic>?
            : null) ??
        const [];

    return items
        .whereType<Map<String, dynamic>>()
        .map(ActivityCategoryVm.fromJson)
        .toList();
  }

  Future<List<ActivityListItemVm>> getMyHostedActivities({
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _apiClient.dio.get(
      '/me/activities/hosted',
      queryParameters: {'limit': limit, 'offset': offset},
    );

    final data = response.data;
    final items = (data is Map<String, dynamic>
            ? data['items'] as List<dynamic>?
            : null) ??
        const [];

    return items
        .whereType<Map<String, dynamic>>()
        .map(ActivityListItemVm.fromJson)
        .toList();
  }

  Future<List<ActivityListItemVm>> getMyJoinedActivities({
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _apiClient.dio.get(
      '/me/activities/joined',
      queryParameters: {'limit': limit, 'offset': offset},
    );

    final data = response.data;
    final items = (data is Map<String, dynamic>
            ? data['items'] as List<dynamic>?
            : null) ??
        const [];

    return items
        .whereType<Map<String, dynamic>>()
        .map(ActivityListItemVm.fromJson)
        .toList();
  }

  Future<List<ActivityListItemVm>> getActivities({
    int limit = 20,
    int offset = 0,
    String? hostUserId,
    String? status,
    String? categorySlug,
    String? cityName,
    String? query,
  }) async {
    final response = await _apiClient.dio.get(
      '/activities',
      queryParameters: {
        'limit': limit,
        'offset': offset,
        if ((hostUserId ?? '').trim().isNotEmpty) 'hostUserId': hostUserId,
        if ((status ?? '').trim().isNotEmpty) 'status': status,
        if ((categorySlug ?? '').trim().isNotEmpty)
          'categorySlug': categorySlug,
        if ((cityName ?? '').trim().isNotEmpty) 'cityName': cityName,
        if ((query ?? '').trim().isNotEmpty) 'q': query,
      },
      options: Options(extra: const {'requiresAuth': false}),
    );

    final data = response.data;
    final items = (data is Map<String, dynamic>
            ? data['items'] as List<dynamic>?
            : null) ??
        const [];

    return items
        .whereType<Map<String, dynamic>>()
        .map(ActivityListItemVm.fromJson)
        .toList();
  }

  Future<ActivityListItemVm> getActivityById(String activityId) async {
    final response = await _apiClient.dio.get('/activities/$activityId');

    return ActivityListItemVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ActivityParticipantVm>> getActivityParticipants(
    String activityId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _apiClient.dio.get(
      '/activities/$activityId/participants',
      queryParameters: {'limit': limit, 'offset': offset},
      options: Options(extra: const {'requiresAuth': false}),
    );

    final data = response.data;
    final items = (data is Map<String, dynamic>
            ? data['items'] as List<dynamic>?
            : null) ??
        const [];

    return items
        .whereType<Map<String, dynamic>>()
        .map(ActivityParticipantVm.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> joinActivity(
    String activityId, {
    String? visibilityPassword,
  }) async {
    final response = await _apiClient.dio.post(
      '/me/activities/$activityId/join',
      data: visibilityPassword == null || visibilityPassword.trim().isEmpty
          ? null
          : {'password': visibilityPassword.trim()},
    );

    return response.data as Map<String, dynamic>;
  }

  Future<ActivityListItemVm> createActivity(
    CreateActivityRequest request,
  ) async {
    final response = await _apiClient.dio.post(
      '/me/activities',
      data: request.toJson(),
    );

    return ActivityListItemVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> leaveActivity(String activityId, {String? reason}) async {
    await _apiClient.dio.post(
      '/me/activities/$activityId/leave',
      data: {if (reason != null && reason.trim().isNotEmpty) 'reason': reason},
    );
  }

  Future<ActivityListItemVm> cancelActivity(
    String activityId, {
    String? reason,
  }) async {
    final trimmedReason = reason?.trim() ?? '';
    final response = await _apiClient.dio.post(
      '/me/activities/$activityId/cancel',
      data: {if (trimmedReason.isNotEmpty) 'reason': trimmedReason},
    );

    return ActivityListItemVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ActivityListItemVm> completeActivity(
    String activityId, {
    String? reason,
  }) async {
    final trimmedReason = reason?.trim() ?? '';
    final response = await _apiClient.dio.post(
      '/me/activities/$activityId/complete',
      data: {if (trimmedReason.isNotEmpty) 'reason': trimmedReason},
    );

    return ActivityListItemVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ActivityListItemVm> extendActivity(
    String activityId, {
    required int minutes,
  }) async {
    final response = await _apiClient.dio.post(
      '/me/activities/$activityId/extend',
      data: {'minutes': minutes},
    );

    return ActivityListItemVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ActivityListItemVm> updateActivity(
    String activityId,
    UpdateActivityRequest request,
  ) async {
    final response = await _apiClient.dio.patch(
      '/me/activities/$activityId',
      data: request.toJson(),
    );

    return ActivityListItemVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ActivityListItemVm> publishActivity(String activityId) async {
    final response = await _apiClient.dio.post(
      '/me/activities/$activityId/publish',
    );

    return ActivityListItemVm.fromJson(response.data as Map<String, dynamic>);
  }

  /// Count completed hosted activities for any user via the public endpoint.
  Future<int> countCompletedActivitiesForUser(String userId) async {
    var offset = 0;
    var total = 0;
    var hasMore = true;

    while (hasMore) {
      final response = await _apiClient.dio.get(
        '/activities',
        queryParameters: {
          'hostUserId': userId,
          'status': 'COMPLETED',
          'limit': 100,
          'offset': offset,
        },
        options: Options(extra: const {'requiresAuth': false}),
      );

      final data = response.data;
      final items = (data is Map<String, dynamic>
              ? data['items'] as List<dynamic>?
              : null) ??
          const [];
      total += items.length;
      hasMore = data is Map<String, dynamic> && data['hasMore'] == true;
      offset += items.length;
    }

    return total;
  }

  Future<ActivityCompletionStatsVm> getMyCompletionStats({
    required String actorUserId,
  }) async {
    Future<int> countHostedCompleted() async {
      var offset = 0;
      var total = 0;
      var hasMore = true;

      while (hasMore) {
        final page = await _getMyActivitiesPage(
          path: '/me/activities/hosted',
          limit: 100,
          offset: offset,
        );
        total += page.items
            .where((item) => item.status.trim().toUpperCase() == 'COMPLETED')
            .length;
        hasMore = page.hasMore;
        offset += page.items.length;
      }

      return total;
    }

    Future<int> countJoinedCompleted() async {
      var offset = 0;
      var total = 0;
      var hasMore = true;

      while (hasMore) {
        final page = await _getMyActivitiesPage(
          path: '/me/activities/joined',
          limit: 100,
          offset: offset,
        );
        total += page.items
            .where(
              (item) =>
                  item.status.trim().toUpperCase() == 'COMPLETED' &&
                  item.hostUserId.trim() != actorUserId.trim(),
            )
            .length;
        hasMore = page.hasMore;
        offset += page.items.length;
      }

      return total;
    }

    final results = await Future.wait<int>([
      countHostedCompleted(),
      countJoinedCompleted(),
    ]);

    return ActivityCompletionStatsVm(
      hostedCompleted: results[0],
      joinedCompleted: results[1],
    );
  }

  Future<_ActivityListPage> _getMyActivitiesPage({
    required String path,
    required int limit,
    required int offset,
  }) async {
    final response = await _apiClient.dio.get(
      path,
      queryParameters: {'limit': limit, 'offset': offset},
    );

    final data = response.data;
    final items = (data is Map<String, dynamic>
            ? data['items'] as List<dynamic>?
            : null) ??
        const [];
    final hasMore = data is Map<String, dynamic> && data['hasMore'] == true;

    return _ActivityListPage(
      items: items
          .whereType<Map<String, dynamic>>()
          .map(ActivityListItemVm.fromJson)
          .toList(),
      hasMore: hasMore,
    );
  }
}

class ActivityCompletionStatsVm {
  const ActivityCompletionStatsVm({
    required this.hostedCompleted,
    required this.joinedCompleted,
  });

  final int hostedCompleted;
  final int joinedCompleted;
}

class _ActivityListPage {
  const _ActivityListPage({required this.items, required this.hasMore});

  final List<ActivityListItemVm> items;
  final bool hasMore;
}
