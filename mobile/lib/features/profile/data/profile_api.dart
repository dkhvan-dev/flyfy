import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/profile_follower_vm.dart';
import '../models/update_profile_request.dart';
import '../models/user_profile_vm.dart';

class ProfileApi {
  ProfileApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<UserProfileVm> getMe() async {
    final data = await _apiClient.getMe();
    return UserProfileVm.fromJson(data);
  }

  Future<UserProfileVm> getUserById(String userId) async {
    final data = await _apiClient.getUserById(userId);
    return UserProfileVm.fromJson(data);
  }

  Future<void> updatePresence() async {
    await _apiClient.updatePresence();
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

      final errorMessage =
          data is Map<String, dynamic> ? data['error']?.toString() : null;

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

  Future<void> followUser(String userId) async {
    await _apiClient.followUser(userId);
  }

  Future<void> unfollowUser(String userId) async {
    await _apiClient.unfollowUser(userId);
  }

  Future<UserFriendshipStatus> sendFriendRequest(String userId) async {
    final data = await _apiClient.sendFriendRequest(userId);
    return UserFriendshipStatus.fromWire(data['status']?.toString());
  }

  Future<UserFriendshipStatus> cancelFriendRequest(String userId) async {
    final data = await _apiClient.cancelFriendRequest(userId);
    return UserFriendshipStatus.fromWire(data['status']?.toString());
  }

  Future<UserFriendshipStatus> declineFriendRequest(String userId) async {
    final data = await _apiClient.declineFriendRequest(userId);
    return UserFriendshipStatus.fromWire(data['status']?.toString());
  }

  Future<UserFriendshipStatus> acceptFriendRequest(String userId) async {
    final data = await _apiClient.acceptFriendRequest(userId);
    return UserFriendshipStatus.fromWire(data['status']?.toString());
  }

  Future<UserFriendshipStatus> removeFriend(String userId) async {
    final data = await _apiClient.removeFriend(userId);
    return UserFriendshipStatus.fromWire(data['status']?.toString());
  }

  Future<ProfileFollowersPageVm> getFollowers(
    String userId, {
    int limit = 20,
    int offset = 0,
    String? query,
  }) async {
    final data = await _apiClient.getUserFollowers(
      userId,
      limit: limit,
      offset: offset,
      query: query,
    );
    return ProfileFollowersPageVm.fromJson(data);
  }

  Future<UserSettingsVm> updateMeSettings({
    bool? notificationsPushEnabled,
    bool? notificationsEmailEnabled,
    bool? notificationsSmsEnabled,
    bool? marketingEnabled,
    bool? darkModeEnabled,
  }) async {
    final body = <String, dynamic>{};

    if (notificationsPushEnabled != null) {
      body['notificationsPushEnabled'] = notificationsPushEnabled;
    }
    if (notificationsEmailEnabled != null) {
      body['notificationsEmailEnabled'] = notificationsEmailEnabled;
    }
    if (notificationsSmsEnabled != null) {
      body['notificationsSmsEnabled'] = notificationsSmsEnabled;
    }
    if (marketingEnabled != null) {
      body['marketingEnabled'] = marketingEnabled;
    }
    if (darkModeEnabled != null) {
      body['darkModeEnabled'] = darkModeEnabled;
    }

    final data = await _apiClient.updateMeSettings(body);
    return UserSettingsVm.fromJson(data);
  }
}
