import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/update_profile_request.dart';
import '../models/user_profile_vm.dart';

class ProfileApi {
  ProfileApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<UserProfileVm> getMe() async {
    final data = await _apiClient.getMe();
    return UserProfileVm.fromJson(data);
  }

  Future<UserProfileVm> getOrInitMe({
    String? primaryPhoneHint,
    String? primaryEmailHint,
  }) async {
    try {
      return await getMe();
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;

      final errorMessage = data is Map<String, dynamic>
          ? data['error']?.toString()
          : null;

      final isUserNotFound =
          statusCode == 404 && errorMessage == 'user not found';

      if (!isUserNotFound) rethrow;

      final initData = await _apiClient.initMe(
        primaryPhone: primaryPhoneHint,
        primaryEmail: primaryEmailHint,
      );
      return UserProfileVm.fromJson(initData);
    }
  }

  Future<UserProfileVm> updateMeProfile(UpdateProfileRequest request) async {
    final data = await _apiClient.updateMeProfile(request.toJson());
    return UserProfileVm.fromJson(data);
  }
}