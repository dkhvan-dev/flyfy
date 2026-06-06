class ActivityReviewMutationRequest {
  const ActivityReviewMutationRequest({
    required this.rating,
    required this.comment,
    this.delete = false,
  });

  final double rating;
  final String comment;
  final bool delete;

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'comment': comment.trim(),
      if (delete) 'delete': true,
    };
  }
}

class SaveActivityReviewsRequest {
  const SaveActivityReviewsRequest({this.activityReview, this.organizerReview});

  final ActivityReviewMutationRequest? activityReview;
  final ActivityReviewMutationRequest? organizerReview;

  Map<String, dynamic> toJson() {
    return {
      if (activityReview != null) 'activityReview': activityReview!.toJson(),
      if (organizerReview != null) 'organizerReview': organizerReview!.toJson(),
    };
  }
}

class ActivityReviewsResultVm {
  const ActivityReviewsResultVm({this.activityReview, this.organizerReview});

  final ActivityReviewVm? activityReview;
  final ActivityOrganizerReviewVm? organizerReview;

  factory ActivityReviewsResultVm.fromJson(Map<String, dynamic> json) {
    return ActivityReviewsResultVm(
      activityReview: json['activityReview'] is Map<String, dynamic>
          ? ActivityReviewVm.fromJson(
              json['activityReview'] as Map<String, dynamic>,
            )
          : null,
      organizerReview: json['organizerReview'] is Map<String, dynamic>
          ? ActivityOrganizerReviewVm.fromJson(
              json['organizerReview'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class ActivityReviewsPage {
  const ActivityReviewsPage({required this.items, required this.hasMore});

  final List<ActivityReviewVm> items;
  final bool hasMore;
}

class ActivityOrganizerReviewsPage {
  const ActivityOrganizerReviewsPage({
    required this.items,
    required this.hasMore,
  });

  final List<ActivityOrganizerReviewVm> items;
  final bool hasMore;
}

class ActivityReviewVm {
  const ActivityReviewVm({
    required this.id,
    required this.participantId,
    required this.activityId,
    required this.hostUserId,
    required this.authorUserId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.author = const ActivityReviewAuthorVm(userId: ''),
    this.sourceLabel = 'ACTIVITY',
  });

  final String id;
  final String participantId;
  final String activityId;
  final String hostUserId;
  final String authorUserId;
  final ActivityReviewAuthorVm author;
  final double rating;
  final String comment;
  final String sourceLabel;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ActivityReviewVm.fromJson(Map<String, dynamic> json) {
    final authorUserId = _string(json['authorUserId']);
    final author = json['author'] is Map<String, dynamic>
        ? ActivityReviewAuthorVm.fromJson(
            json['author'] as Map<String, dynamic>,
            fallbackUserId: authorUserId,
          )
        : ActivityReviewAuthorVm(userId: authorUserId);

    return ActivityReviewVm(
      id: _string(json['id']),
      participantId: _string(json['participantId']),
      activityId: _string(json['activityId']),
      hostUserId: _string(json['hostUserId']),
      authorUserId: authorUserId,
      author: author,
      rating: _double(json['rating']),
      comment: _string(json['comment']),
      sourceLabel: _string(json['sourceLabel']).isEmpty
          ? 'ACTIVITY'
          : _string(json['sourceLabel']),
      createdAt: _date(json['createdAt']) ?? DateTime.now().toUtc(),
      updatedAt: _date(json['updatedAt']) ?? DateTime.now().toUtc(),
    );
  }
}

class ActivityOrganizerReviewVm {
  const ActivityOrganizerReviewVm({
    required this.id,
    required this.participantId,
    required this.activityId,
    required this.hostUserId,
    required this.authorUserId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.author = const ActivityReviewAuthorVm(userId: ''),
    this.sourceLabel = 'ACTIVITY_ORGANIZER',
  });

  final String id;
  final String participantId;
  final String activityId;
  final String hostUserId;
  final String authorUserId;
  final ActivityReviewAuthorVm author;
  final double rating;
  final String comment;
  final String sourceLabel;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ActivityOrganizerReviewVm.fromJson(Map<String, dynamic> json) {
    final authorUserId = _string(json['authorUserId']);
    final author = json['author'] is Map<String, dynamic>
        ? ActivityReviewAuthorVm.fromJson(
            json['author'] as Map<String, dynamic>,
            fallbackUserId: authorUserId,
          )
        : ActivityReviewAuthorVm(userId: authorUserId);

    return ActivityOrganizerReviewVm(
      id: _string(json['id']),
      participantId: _string(json['participantId']),
      activityId: _string(json['activityId']),
      hostUserId: _string(json['hostUserId']),
      authorUserId: authorUserId,
      author: author,
      rating: _double(json['rating']),
      comment: _string(json['comment']),
      sourceLabel: _string(json['sourceLabel']).isEmpty
          ? 'ACTIVITY_ORGANIZER'
          : _string(json['sourceLabel']),
      createdAt: _date(json['createdAt']) ?? DateTime.now().toUtc(),
      updatedAt: _date(json['updatedAt']) ?? DateTime.now().toUtc(),
    );
  }
}

class ActivityReviewAuthorVm {
  const ActivityReviewAuthorVm({
    required this.userId,
    this.nickname,
    this.avatarFileId,
  });

  final String userId;
  final String? nickname;
  final String? avatarFileId;

  factory ActivityReviewAuthorVm.fromJson(
    Map<String, dynamic> json, {
    String fallbackUserId = '',
  }) {
    final userId = _string(json['userId']);
    return ActivityReviewAuthorVm(
      userId: userId.isEmpty ? fallbackUserId : userId,
      nickname: _nullableString(json['nickname']),
      avatarFileId: _nullableString(json['avatarFileId']),
    );
  }

  String get resolvedDisplayName => (nickname ?? '').trim();
  String get resolvedAvatarFileId => (avatarFileId ?? '').trim();
}

String _string(dynamic value) => value?.toString() ?? '';

String? _nullableString(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

double _double(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _date(dynamic value) {
  final raw = value?.toString() ?? '';
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}
