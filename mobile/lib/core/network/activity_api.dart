import 'package:dio/dio.dart';

import '../../features/activities/models/activity_list_item_vm.dart';
import '../../features/activities/models/create_activity_request.dart';
import '../../features/activities/models/update_activity_request.dart';
import 'api_client.dart';

class ActivityApi {
  ActivityApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<ActivityListItemVm>> getMyHostedActivities({
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _apiClient.dio.get(
      '/me/activities/hosted',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
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
        if ((status ?? '').trim().isNotEmpty) 'status': status,
        if ((categorySlug ?? '').trim().isNotEmpty)
          'categorySlug': categorySlug,
        if ((cityName ?? '').trim().isNotEmpty) 'cityName': cityName,
        if ((query ?? '').trim().isNotEmpty) 'q': query,
      },
      options: Options(
        extra: const {
          'requiresAuth': false,
        },
      ),
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
    final response = await _apiClient.dio.get(
      '/activities/$activityId',
      options: Options(
        extra: const {
          'requiresAuth': false,
        },
      ),
    );

    return ActivityListItemVm.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> joinActivity(String activityId) async {
    final response = await _apiClient.dio.post(
      '/me/activities/$activityId/join',
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

    return ActivityListItemVm.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<void> leaveActivity(String activityId, {String? reason}) async {
    await _apiClient.dio.post(
      '/me/activities/$activityId/leave',
      data: {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason,
      },
    );
  }

  Future<ActivityListItemVm> updateActivity(
    String activityId,
    UpdateActivityRequest request,
  ) async {
    final response = await _apiClient.dio.patch(
      '/me/activities/$activityId',
      data: request.toJson(),
    );

    return ActivityListItemVm.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<ActivityListItemVm> publishActivity(String activityId) async {
    final response = await _apiClient.dio.post(
      '/me/activities/$activityId/publish',
    );

    return ActivityListItemVm.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}