import '../../stories/models/post_vm.dart';

class CommunityModerationPostPageVm {
  CommunityModerationPostPageVm({
    List<PostVm> items = const [],
    this.limit = 0,
    this.offset = 0,
    this.hasMore = false,
  }) : items = List<PostVm>.unmodifiable(items);

  final List<PostVm> items;
  final int limit;
  final int offset;
  final bool hasMore;

  factory CommunityModerationPostPageVm.fromJson(Map<String, dynamic> json) {
    return CommunityModerationPostPageVm(
      items: _parsePosts(json['items']),
      limit: _parseInt(json['limit']),
      offset: _parseInt(json['offset']),
      hasMore: json['hasMore'] == true,
    );
  }
}

class PostModerationDecisionPageVm {
  PostModerationDecisionPageVm({
    List<PostModerationDecisionVm> items = const [],
    this.limit = 0,
    this.offset = 0,
    this.hasMore = false,
  }) : items = List<PostModerationDecisionVm>.unmodifiable(items);

  final List<PostModerationDecisionVm> items;
  final int limit;
  final int offset;
  final bool hasMore;

  factory PostModerationDecisionPageVm.fromJson(Map<String, dynamic> json) {
    return PostModerationDecisionPageVm(
      items: _parseDecisions(json['items']),
      limit: _parseInt(json['limit']),
      offset: _parseInt(json['offset']),
      hasMore: json['hasMore'] == true,
    );
  }
}

class PostModerationDecisionVm {
  PostModerationDecisionVm({
    required this.id,
    required this.postId,
    required this.communityId,
    required this.moderatorUserId,
    required this.decision,
    required this.previousStatus,
    required this.nextStatus,
    required this.postRevision,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String communityId;
  final String moderatorUserId;
  final String decision;
  final String previousStatus;
  final String nextStatus;
  final int postRevision;
  final String reason;
  final DateTime? createdAt;

  factory PostModerationDecisionVm.fromJson(Map<String, dynamic> json) {
    return PostModerationDecisionVm(
      id: json['id']?.toString() ?? '',
      postId: json['postId']?.toString() ?? '',
      communityId: json['communityId']?.toString() ?? '',
      moderatorUserId: json['moderatorUserId']?.toString() ?? '',
      decision: json['decision']?.toString() ?? '',
      previousStatus: json['previousStatus']?.toString() ?? '',
      nextStatus: json['nextStatus']?.toString() ?? '',
      postRevision: _parseInt(json['postRevision']),
      reason: json['reason']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

class CommunityMemberPageVm {
  CommunityMemberPageVm({
    List<CommunityMemberVm> items = const [],
    this.limit = 0,
    this.offset = 0,
    this.hasMore = false,
  }) : items = List<CommunityMemberVm>.unmodifiable(items);

  final List<CommunityMemberVm> items;
  final int limit;
  final int offset;
  final bool hasMore;

  factory CommunityMemberPageVm.fromJson(Map<String, dynamic> json) {
    return CommunityMemberPageVm(
      items: _parseMembers(json['items']),
      limit: _parseInt(json['limit']),
      offset: _parseInt(json['offset']),
      hasMore: json['hasMore'] == true,
    );
  }
}

class CommunityMemberRoleChangePageVm {
  CommunityMemberRoleChangePageVm({
    List<CommunityMemberRoleChangeVm> items = const [],
    this.limit = 0,
    this.offset = 0,
    this.hasMore = false,
  }) : items = List<CommunityMemberRoleChangeVm>.unmodifiable(items);

  final List<CommunityMemberRoleChangeVm> items;
  final int limit;
  final int offset;
  final bool hasMore;

  factory CommunityMemberRoleChangePageVm.fromJson(Map<String, dynamic> json) {
    return CommunityMemberRoleChangePageVm(
      items: _parseRoleChanges(json['items']),
      limit: _parseInt(json['limit']),
      offset: _parseInt(json['offset']),
      hasMore: json['hasMore'] == true,
    );
  }
}

class CommunityMemberRoleChangeVm {
  CommunityMemberRoleChangeVm({
    required this.id,
    required this.communityId,
    required this.targetUserId,
    required this.actorUserId,
    required this.actor,
    required this.previousRole,
    required this.nextRole,
    required this.createdAt,
  });

  final String id;
  final String communityId;
  final String targetUserId;
  final String actorUserId;
  final PostAuthorVm actor;
  final String previousRole;
  final String nextRole;
  final DateTime? createdAt;

  factory CommunityMemberRoleChangeVm.fromJson(Map<String, dynamic> json) {
    return CommunityMemberRoleChangeVm(
      id: json['id']?.toString() ?? '',
      communityId: json['communityId']?.toString() ?? '',
      targetUserId: json['targetUserId']?.toString() ?? '',
      actorUserId: json['actorUserId']?.toString() ?? '',
      actor: PostAuthorVm.fromJson(_stringKeyedMap(json['actor'])),
      previousRole: json['previousRole']?.toString() ?? '',
      nextRole: json['nextRole']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

class CommunityMembershipVm {
  CommunityMembershipVm({
    required this.communityId,
    required this.userId,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String communityId;
  final String userId;
  final String role;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CommunityMembershipVm.fromJson(Map<String, dynamic> json) {
    return CommunityMembershipVm(
      communityId: json['communityId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}

class CommunityMemberVm extends CommunityMembershipVm {
  CommunityMemberVm({
    required super.communityId,
    required super.userId,
    required super.role,
    required super.status,
    required this.user,
    required super.createdAt,
    required super.updatedAt,
  });

  final PostAuthorVm user;

  factory CommunityMemberVm.fromJson(Map<String, dynamic> json) {
    return CommunityMemberVm(
      communityId: json['communityId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      user: PostAuthorVm.fromJson(_stringKeyedMap(json['user'])),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  CommunityMemberVm copyWith({
    String? role,
    String? status,
    PostAuthorVm? user,
    DateTime? updatedAt,
  }) {
    return CommunityMemberVm(
      communityId: communityId,
      userId: userId,
      role: role ?? this.role,
      status: status ?? this.status,
      user: user ?? this.user,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

List<PostVm> _parsePosts(Object? rawItems) {
  if (rawItems is! List) {
    return const [];
  }

  return rawItems
      .whereType<Map>()
      .map(_stringKeyedMap)
      .map(PostVm.fromJson)
      .toList(growable: false);
}

List<CommunityMemberVm> _parseMembers(Object? rawItems) {
  if (rawItems is! List) {
    return const [];
  }

  return rawItems
      .whereType<Map>()
      .map(_stringKeyedMap)
      .map(CommunityMemberVm.fromJson)
      .toList(growable: false);
}

List<CommunityMemberRoleChangeVm> _parseRoleChanges(Object? rawItems) {
  if (rawItems is! List) {
    return const [];
  }

  return rawItems
      .whereType<Map>()
      .map(_stringKeyedMap)
      .map(CommunityMemberRoleChangeVm.fromJson)
      .toList(growable: false);
}

List<PostModerationDecisionVm> _parseDecisions(Object? rawItems) {
  if (rawItems is! List) {
    return const [];
  }

  return rawItems
      .whereType<Map>()
      .map(_stringKeyedMap)
      .map(PostModerationDecisionVm.fromJson)
      .toList(growable: false);
}

Map<String, dynamic> _stringKeyedMap(Object? rawMap) {
  if (rawMap is! Map) {
    return const {};
  }

  return Map<String, dynamic>.unmodifiable({
    for (final entry in rawMap.entries) entry.key.toString(): entry.value,
  });
}

int _parseInt(Object? value) {
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
