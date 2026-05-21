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
    final items =
        (data is Map<String, dynamic>
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
    final items =
        (data is Map<String, dynamic>
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
    final items =
        (data is Map<String, dynamic>
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
    String? subcategorySlug,
    String? cityId,
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
        if ((subcategorySlug ?? '').trim().isNotEmpty)
          'subcategorySlug': subcategorySlug,
        if ((cityId ?? '').trim().isNotEmpty) 'cityId': cityId,
        if ((cityName ?? '').trim().isNotEmpty) 'cityName': cityName,
        if ((query ?? '').trim().isNotEmpty) 'q': query,
      },
      options: Options(extra: const {'requiresAuth': false}),
    );

    final data = response.data;
    final items =
        (data is Map<String, dynamic>
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
    final items =
        (data is Map<String, dynamic>
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

  /// Count completed hosted and joined activities for any user via the public endpoint.
  Future<int> countCompletedActivitiesForUser(String userId) async {
    final trimmedUserId = userId.trim();
    if (trimmedUserId.isEmpty) {
      return 0;
    }

    final encodedUserId = Uri.encodeComponent(trimmedUserId);
    final response = await _apiClient.dio.get(
      '/activities/users/$encodedUserId/completion-stats',
      options: Options(extra: const {'requiresAuth': false}),
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      return 0;
    }

    return int.tryParse(data['totalCompleted']?.toString() ?? '') ?? 0;
  }
}
