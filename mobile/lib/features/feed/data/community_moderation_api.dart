import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../stories/models/post_vm.dart';
import '../models/community_moderation_vm.dart';

class CommunityModerationApi {
  CommunityModerationApi({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<CommunityModerationPostPageVm> listPendingPosts({
    required String communityId,
    int limit = 20,
    int offset = 0,
  }) async {
    final normalizedCommunityId = _requiredId(communityId, 'communityId');
    final response = await _apiClient.dio.get(
      '/communities/${Uri.encodeComponent(normalizedCommunityId)}/moderation/posts',
      queryParameters: {
        'limit': _normalizeLimit(limit),
        'offset': _normalizeOffset(offset),
      },
      options: Options(extra: const {'requiresAuth': true}),
    );

    return CommunityModerationPostPageVm.fromJson(
      _stringKeyedMap(response.data),
    );
  }

  Future<PostVm> approvePost({
    required String communityId,
    required String postId,
    String? reason,
  }) {
    return _reviewPost(
      communityId: communityId,
      postId: postId,
      action: 'approve',
      reason: reason,
    );
  }

  Future<PostVm> rejectPost({
    required String communityId,
    required String postId,
    String? reason,
  }) {
    return _reviewPost(
      communityId: communityId,
      postId: postId,
      action: 'reject',
      reason: reason,
    );
  }

  Future<PostModerationDecisionPageVm> listPostDecisions({
    required String communityId,
    required String postId,
    int limit = 20,
    int offset = 0,
  }) async {
    final normalizedCommunityId = _requiredId(communityId, 'communityId');
    final normalizedPostId = _requiredId(postId, 'postId');
    final response = await _apiClient.dio.get(
      '/communities/${Uri.encodeComponent(normalizedCommunityId)}'
      '/moderation/posts/${Uri.encodeComponent(normalizedPostId)}'
      '/decisions',
      queryParameters: {
        'limit': _normalizeLimit(limit),
        'offset': _normalizeOffset(offset),
      },
      options: Options(extra: const {'requiresAuth': true}),
    );

    return PostModerationDecisionPageVm.fromJson(
      _stringKeyedMap(response.data),
    );
  }

  Future<CommunityMemberPageVm> listMembers({
    required String communityId,
    String? role,
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    final normalizedCommunityId = _requiredId(communityId, 'communityId');
    final queryParameters = <String, Object>{
      'limit': _normalizeLimit(limit),
      'offset': _normalizeOffset(offset),
    };
    final normalizedRole = _optionalValue(role);
    if (normalizedRole != null) {
      queryParameters['role'] = normalizedRole;
    }
    final normalizedStatus = _optionalValue(status);
    if (normalizedStatus != null) {
      queryParameters['status'] = normalizedStatus;
    }

    final response = await _apiClient.dio.get(
      '/communities/${Uri.encodeComponent(normalizedCommunityId)}/members',
      queryParameters: queryParameters,
      options: Options(extra: const {'requiresAuth': true}),
    );

    return CommunityMemberPageVm.fromJson(_stringKeyedMap(response.data));
  }

  Future<CommunityMembershipVm> updateMemberRole({
    required String communityId,
    required String userId,
    required String role,
  }) async {
    final normalizedCommunityId = _requiredId(communityId, 'communityId');
    final normalizedUserId = _requiredId(userId, 'userId');
    final normalizedRole = _requiredId(role, 'role').toUpperCase();
    final response = await _apiClient.dio.patch(
      '/communities/${Uri.encodeComponent(normalizedCommunityId)}'
      '/members/${Uri.encodeComponent(normalizedUserId)}'
      '/role',
      data: {'role': normalizedRole},
      options: Options(extra: const {'requiresAuth': true}),
    );

    return CommunityMembershipVm.fromJson(_stringKeyedMap(response.data));
  }

  Future<CommunityMembershipVm> updateMemberStatus({
    required String communityId,
    required String userId,
    required String status,
  }) async {
    final normalizedCommunityId = _requiredId(communityId, 'communityId');
    final normalizedUserId = _requiredId(userId, 'userId');
    final normalizedStatus = _requiredId(status, 'status').toUpperCase();
    final response = await _apiClient.dio.patch(
      '/communities/${Uri.encodeComponent(normalizedCommunityId)}'
      '/members/${Uri.encodeComponent(normalizedUserId)}'
      '/status',
      data: {'status': normalizedStatus},
      options: Options(extra: const {'requiresAuth': true}),
    );

    return CommunityMembershipVm.fromJson(_stringKeyedMap(response.data));
  }

  Future<CommunityMemberRoleChangePageVm> listMemberRoleChanges({
    required String communityId,
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    final normalizedCommunityId = _requiredId(communityId, 'communityId');
    final normalizedUserId = _requiredId(userId, 'userId');
    final response = await _apiClient.dio.get(
      '/communities/${Uri.encodeComponent(normalizedCommunityId)}'
      '/members/${Uri.encodeComponent(normalizedUserId)}'
      '/role-changes',
      queryParameters: {
        'limit': _normalizeLimit(limit),
        'offset': _normalizeOffset(offset),
      },
      options: Options(extra: const {'requiresAuth': true}),
    );

    return CommunityMemberRoleChangePageVm.fromJson(
      _stringKeyedMap(response.data),
    );
  }

  Future<PostVm> _reviewPost({
    required String communityId,
    required String postId,
    required String action,
    String? reason,
  }) async {
    final normalizedCommunityId = _requiredId(communityId, 'communityId');
    final normalizedPostId = _requiredId(postId, 'postId');
    final response = await _apiClient.dio.post(
      '/communities/${Uri.encodeComponent(normalizedCommunityId)}'
      '/moderation/posts/${Uri.encodeComponent(normalizedPostId)}'
      '/$action',
      data: _reviewBody(reason),
      options: Options(extra: const {'requiresAuth': true}),
    );

    return PostVm.fromJson(_stringKeyedMap(response.data));
  }
}

String? _optionalValue(String? value) {
  final trimmed = (value ?? '').trim();
  return trimmed.isEmpty ? null : trimmed;
}

Map<String, dynamic> _reviewBody(String? reason) {
  final trimmedReason = (reason ?? '').trim();
  if (trimmedReason.isEmpty) {
    return const {};
  }
  return {'reason': trimmedReason};
}

String _requiredId(String value, String name) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(value, name, 'must not be empty');
  }
  return trimmed;
}

int _normalizeLimit(int value) {
  if (value < 1) {
    return 1;
  }
  if (value > 50) {
    return 50;
  }
  return value;
}

int _normalizeOffset(int value) {
  return value < 0 ? 0 : value;
}

Map<String, dynamic> _stringKeyedMap(Object? rawMap) {
  if (rawMap is! Map) {
    return const {};
  }

  return Map<String, dynamic>.unmodifiable({
    for (final entry in rawMap.entries) entry.key.toString(): entry.value,
  });
}
