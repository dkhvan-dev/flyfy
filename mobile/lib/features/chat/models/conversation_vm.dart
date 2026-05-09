class ConversationVm {
  final String id;
  final String type;
  final String? title;
  final String? avatarFileId;
  final String? activityId;
  final List<ParticipantInfo> participants;
  final LastMessagePreview? lastMessage;
  final int unreadCount;
  final int participantCount;
  final String? mutedUntil;
  final DateTime? messagingAvailableUntil;
  final bool canSendMessages;
  final DateTime lastActivityAt;

  const ConversationVm({
    required this.id,
    required this.type,
    this.title,
    this.avatarFileId,
    this.activityId,
    this.participants = const [],
    this.lastMessage,
    this.unreadCount = 0,
    this.participantCount = 0,
    this.mutedUntil,
    this.messagingAvailableUntil,
    this.canSendMessages = true,
    required this.lastActivityAt,
  });

  bool get isGroup => type == 'group';
  bool get isDirect => type == 'direct';
  bool get isActivity => activityId != null && activityId!.trim().isNotEmpty;
  bool get canSendNow =>
      canSendMessages &&
      (messagingAvailableUntil == null ||
          DateTime.now().toUtc().isBefore(messagingAvailableUntil!.toUtc()));

  ParticipantInfo? directPeer(String currentUserId) {
    final current = currentUserId.trim();
    if (participants.isEmpty) return null;
    return participants.where((p) => p.userId.trim() != current).firstOrNull ??
        participants.first;
  }

  String displayTitle(String currentUserId) {
    if (isDirect) {
      final peerName = directPeer(currentUserId)?.displayName.trim() ?? '';
      if (peerName.isNotEmpty) return peerName;
    }
    final value = title?.trim() ?? '';
    return value.isEmpty ? 'Chat' : value;
  }

  String? displayAvatarFileId(String currentUserId) {
    if (isDirect) {
      return directPeer(currentUserId)?.avatarFileId;
    }
    return avatarFileId;
  }

  ConversationVm copyWith({
    int? unreadCount,
    LastMessagePreview? lastMessage,
    List<ParticipantInfo>? participants,
  }) {
    return ConversationVm(
      id: id,
      type: type,
      title: title,
      avatarFileId: avatarFileId,
      activityId: activityId,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      participantCount: participantCount,
      mutedUntil: mutedUntil,
      messagingAvailableUntil: messagingAvailableUntil,
      canSendMessages: canSendMessages,
      lastActivityAt: lastActivityAt,
    );
  }

  factory ConversationVm.fromJson(Map<String, dynamic> json) {
    return ConversationVm(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String?,
      avatarFileId: json['avatarFileId'] as String?,
      activityId: json['activityId'] as String?,
      participants: (json['participants'] as List<dynamic>?)
              ?.map((e) => ParticipantInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      lastMessage: json['lastMessage'] != null
          ? LastMessagePreview.fromJson(
              json['lastMessage'] as Map<String, dynamic>,
            )
          : null,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      participantCount: (json['participantCount'] as num?)?.toInt() ?? 0,
      mutedUntil: json['mutedUntil'] as String?,
      messagingAvailableUntil: _parseDateTimeOrNull(
        json['messagingAvailableUntil'],
      ),
      canSendMessages: json['canSendMessages'] != false,
      lastActivityAt: DateTime.parse(json['lastActivityAt'] as String),
    );
  }
}

class LastMessagePreview {
  final String id;
  final String senderUserId;
  final String senderDisplayName;
  final String type;
  final String contentPreview;
  final List<String> fileIds;
  final String? stickerId;
  final String? stickerFileId;
  final DateTime? deletedAt;
  final DateTime sentAt;

  const LastMessagePreview({
    required this.id,
    required this.senderUserId,
    required this.senderDisplayName,
    required this.type,
    required this.contentPreview,
    this.fileIds = const [],
    this.stickerId,
    this.stickerFileId,
    this.deletedAt,
    required this.sentAt,
  });

  bool get isDeleted => deletedAt != null;
  bool get isSticker =>
      type == 'sticker' &&
      ((stickerFileId?.trim().isNotEmpty ?? false) || fileIds.length == 1);
  bool get hasFiles => fileIds.isNotEmpty;

  factory LastMessagePreview.fromJson(Map<String, dynamic> json) {
    return LastMessagePreview(
      id: json['id'] as String,
      senderUserId: json['senderUserId'] as String,
      senderDisplayName: json['senderDisplayName'] as String,
      type: json['type']?.toString() ?? 'text',
      contentPreview: json['contentPreview'] as String,
      fileIds: (json['fileIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((id) => id.trim().isNotEmpty)
              .toList(growable: false) ??
          const [],
      stickerId: json['stickerId']?.toString(),
      stickerFileId: json['stickerFileId']?.toString(),
      deletedAt: _parseDateTimeOrNull(json['deletedAt']),
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
  final List<PinnedMessageInfo> pinnedMessages;
  final int unreadCount;
  final String? mutedUntil;
  final DateTime? messagingAvailableUntil;
  final bool canSendMessages;
  final DateTime lastActivityAt;

  const ConversationDetail({
    required this.id,
    required this.type,
    this.title,
    this.avatarFileId,
    required this.createdAt,
    this.activityId,
    this.participants = const [],
    this.pinnedMessages = const [],
    this.unreadCount = 0,
    this.mutedUntil,
    this.messagingAvailableUntil,
    this.canSendMessages = true,
    required this.lastActivityAt,
  });

  bool get isGroup => type == 'group';
  bool get isDirect => type == 'direct';
  bool get isActivity => activityId != null && activityId!.trim().isNotEmpty;
  bool get canSendNow =>
      canSendMessages &&
      (messagingAvailableUntil == null ||
          DateTime.now().toUtc().isBefore(messagingAvailableUntil!.toUtc()));

  ParticipantInfo? directPeer(String currentUserId) {
    final current = currentUserId.trim();
    if (participants.isEmpty) return null;
    return participants.where((p) => p.userId.trim() != current).firstOrNull ??
        participants.first;
  }

  String displayTitle(String currentUserId) {
    if (isDirect) {
      final peerName = directPeer(currentUserId)?.displayName.trim() ?? '';
      if (peerName.isNotEmpty) return peerName;
    }
    final value = title?.trim() ?? '';
    return value.isEmpty ? 'Chat' : value;
  }

  ConversationDetail copyWith({
    List<ParticipantInfo>? participants,
    List<PinnedMessageInfo>? pinnedMessages,
    int? unreadCount,
  }) {
    return ConversationDetail(
      id: id,
      type: type,
      title: title,
      avatarFileId: avatarFileId,
      createdAt: createdAt,
      activityId: activityId,
      participants: participants ?? this.participants,
      pinnedMessages: pinnedMessages ?? this.pinnedMessages,
      unreadCount: unreadCount ?? this.unreadCount,
      mutedUntil: mutedUntil,
      messagingAvailableUntil: messagingAvailableUntil,
      canSendMessages: canSendMessages,
      lastActivityAt: lastActivityAt,
    );
  }

  factory ConversationDetail.fromJson(Map<String, dynamic> json) {
    return ConversationDetail(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String?,
      avatarFileId: json['avatarFileId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      activityId: json['activityId'] as String?,
      participants: (json['participants'] as List<dynamic>?)
              ?.map((e) => ParticipantInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      pinnedMessages: (json['pinnedMessages'] as List<dynamic>?)
              ?.map(
                (e) => PinnedMessageInfo.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      mutedUntil: json['mutedUntil'] as String?,
      messagingAvailableUntil: _parseDateTimeOrNull(
        json['messagingAvailableUntil'],
      ),
      canSendMessages: json['canSendMessages'] != false,
      lastActivityAt: DateTime.parse(json['lastActivityAt'] as String),
    );
  }
}

DateTime? _parseDateTimeOrNull(Object? value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

class ParticipantInfo {
  final String userId;
  final String displayName;
  final String? avatarFileId;
  final String role;
  final DateTime joinedAt;
  final String? lastReadMessageId;
  final bool isOnline;
  final DateTime? lastSeenAt;

  const ParticipantInfo({
    required this.userId,
    required this.displayName,
    this.avatarFileId,
    required this.role,
    required this.joinedAt,
    this.lastReadMessageId,
    this.isOnline = false,
    this.lastSeenAt,
  });

  factory ParticipantInfo.fromJson(Map<String, dynamic> json) {
    return ParticipantInfo(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      avatarFileId: json['avatarFileId'] as String?,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      lastReadMessageId: json['lastReadMessageId'] as String?,
      isOnline: json['isOnline'] == true,
      lastSeenAt: _parseDateTimeOrNull(json['lastSeenAt']),
    );
  }

  ParticipantInfo copyWith({String? lastReadMessageId}) {
    return ParticipantInfo(
      userId: userId,
      displayName: displayName,
      avatarFileId: avatarFileId,
      role: role,
      joinedAt: joinedAt,
      lastReadMessageId: lastReadMessageId ?? this.lastReadMessageId,
      isOnline: isOnline,
      lastSeenAt: lastSeenAt,
    );
  }
}

class PinnedMessageInfo {
  final String id;
  final String senderUserId;
  final String senderDisplayName;
  final String? senderAvatarFileId;
  final String type;
  final String content;
  final List<String> fileIds;
  final String? stickerId;
  final String? stickerFileId;
  final DateTime sentAt;
  final DateTime pinnedAt;

  const PinnedMessageInfo({
    required this.id,
    required this.senderUserId,
    required this.senderDisplayName,
    this.senderAvatarFileId,
    required this.type,
    required this.content,
    this.fileIds = const [],
    this.stickerId,
    this.stickerFileId,
    required this.sentAt,
    required this.pinnedAt,
  });

  factory PinnedMessageInfo.fromJson(Map<String, dynamic> json) {
    return PinnedMessageInfo(
      id: json['id'] as String,
      senderUserId: json['senderUserId'] as String,
      senderDisplayName: json['senderDisplayName'] as String,
      senderAvatarFileId: json['senderAvatarFileId'] as String?,
      type: (json['type'] as String?) ?? 'text',
      content: json['content'] as String,
      fileIds: (json['fileIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      stickerId: json['stickerId']?.toString(),
      stickerFileId: json['stickerFileId']?.toString(),
      sentAt: DateTime.parse(json['sentAt'] as String),
      pinnedAt: DateTime.parse(json['pinnedAt'] as String),
    );
  }
}
