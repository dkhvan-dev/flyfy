import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/guide_application_vm.dart';
import '../models/guide_profile_vm.dart';
import '../models/submit_guide_application_request.dart';

class GuideApi {
  GuideApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<GuideProfileVm?> getMyGuideProfileOrNull() async {
    try {
      final data = await _apiClient.getMyGuideProfile();
      return GuideProfileVm.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<GuideApplicationVm?> getMyGuideApplicationOrNull() async {
    try {
      final data = await _apiClient.getMyGuideProfile();
      return GuideApplicationVm.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<GuideProfileVm?> getGuideProfileByUserIdOrNull(String userId) async {
    final trimmed = userId.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    try {
      final data = await _apiClient.getGuideProfileByUserId(trimmed);
      return GuideProfileVm.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<GuideProfileVm?> getPublicGuideProfileByUserIdOrNull(
    String userId,
  ) async {
    final trimmed = userId.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    try {
      final data = await _apiClient.getPublicGuideProfileByUserId(trimmed);
      return GuideProfileVm.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<GuideApplicationVm> submitMyGuideApplication(
    SubmitGuideApplicationRequest request,
  ) async {
    final data = await _apiClient.submitMyGuideApplication(request.toJson());
    return GuideApplicationVm.fromJson(data);
  }
}
