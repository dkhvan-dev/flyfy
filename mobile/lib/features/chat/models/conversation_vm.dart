class ConversationVm {
  final String id;
  final String type;
  final String? title;
  final String? avatarFileId;
  final LastMessagePreview? lastMessage;
  final int unreadCount;
  final int participantCount;
  final String? mutedUntil;
  final DateTime lastActivityAt;

  const ConversationVm({
    required this.id,
    required this.type,
    this.title,
    this.avatarFileId,
    this.lastMessage,
    this.unreadCount = 0,
    this.participantCount = 0,
    this.mutedUntil,
    required this.lastActivityAt,
  });

  bool get isGroup => type == 'group';
  bool get isDirect => type == 'direct';

  factory ConversationVm.fromJson(Map<String, dynamic> json) {
    return ConversationVm(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String?,
      avatarFileId: json['avatarFileId'] as String?,
      lastMessage: json['lastMessage'] != null
          ? LastMessagePreview.fromJson(
              json['lastMessage'] as Map<String, dynamic>)
          : null,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      participantCount: (json['participantCount'] as num?)?.toInt() ?? 0,
      mutedUntil: json['mutedUntil'] as String?,
      lastActivityAt: DateTime.parse(json['lastActivityAt'] as String),
    );
  }
}

class LastMessagePreview {
  final String id;
  final String senderUserId;
  final String senderDisplayName;
  final String contentPreview;
  final DateTime sentAt;

  const LastMessagePreview({
    required this.id,
    required this.senderUserId,
    required this.senderDisplayName,
    required this.contentPreview,
    required this.sentAt,
  });

  factory LastMessagePreview.fromJson(Map<String, dynamic> json) {
    return LastMessagePreview(
      id: json['id'] as String,
      senderUserId: json['senderUserId'] as String,
      senderDisplayName: json['senderDisplayName'] as String,
      contentPreview: json['contentPreview'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
    );
  }
}

class ConversationDetail {
  final String id;
  final String type;
  final String? title;
  final String? avatarFileId;
  final DateTime createdAt;
  final String? activityId;
  final List<ParticipantInfo> participants;
  final PinnedMessageInfo? pinnedMessage;
  final int unreadCount;
  final String? mutedUntil;
  final DateTime lastActivityAt;

  const ConversationDetail({
    required this.id,
    required this.type,
    this.title,
    this.avatarFileId,
    required this.createdAt,
    this.activityId,
    this.participants = const [],
    this.pinnedMessage,
    this.unreadCount = 0,
    this.mutedUntil,
    required this.lastActivityAt,
  });

  bool get isGroup => type == 'group';
  bool get isDirect => type == 'direct';

  factory ConversationDetail.fromJson(Map<String, dynamic> json) {
    return ConversationDetail(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String?,
      avatarFileId: json['avatarFileId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      activityId: json['activityId'] as String?,
      participants: (json['participants'] as List<dynamic>?)
              ?.map((e) =>
                  ParticipantInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      pinnedMessage: json['pinnedMessage'] != null
          ? PinnedMessageInfo.fromJson(
              json['pinnedMessage'] as Map<String, dynamic>)
          : null,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      mutedUntil: json['mutedUntil'] as String?,
      lastActivityAt: DateTime.parse(json['lastActivityAt'] as String),
    );
  }
}

class ParticipantInfo {
  final String userId;
  final String displayName;
  final String? avatarFileId;
  final String role;
  final DateTime joinedAt;

  const ParticipantInfo({
    required this.userId,
    required this.displayName,
    this.avatarFileId,
    required this.role,
    required this.joinedAt,
  });

  factory ParticipantInfo.fromJson(Map<String, dynamic> json) {
    return ParticipantInfo(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      avatarFileId: json['avatarFileId'] as String?,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }
}

class PinnedMessageInfo {
  final String id;
  final String senderUserId;
  final String senderDisplayName;
  final String content;
  final DateTime sentAt;

  const PinnedMessageInfo({
    required this.id,
    required this.senderUserId,
    required this.senderDisplayName,
    required this.content,
    required this.sentAt,
  });

  factory PinnedMessageInfo.fromJson(Map<String, dynamic> json) {
    return PinnedMessageInfo(
      id: json['id'] as String,
      senderUserId: json['senderUserId'] as String,
      senderDisplayName: json['senderDisplayName'] as String,
      content: json['content'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
    );
  }
}
