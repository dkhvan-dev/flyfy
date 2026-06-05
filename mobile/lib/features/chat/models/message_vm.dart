class MessageVm {
  final String id;
  final String? clientMessageId;
  final String senderUserId;
  final String senderDisplayName;
  final String? senderAvatarFileId;
  final String type;
  final String content;
  final List<String> fileIds;
  final String? stickerId;
  final String? stickerFileId;
  final String? replyToMessageId;
  final String? forwardedFromMessageId;
  final String? forwardedFromSenderUserId;
  final String? forwardedFromSenderName;
  final int forwardCount;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final String moderationStatus;
  final String? moderationPublicComment;
  final List<MessageReactionVm> reactions;
  final List<MessageReadReceiptVm> readReceipts;
  final DateTime sentAt;

  const MessageVm({
    required this.id,
    this.clientMessageId,
    required this.senderUserId,
    required this.senderDisplayName,
    this.senderAvatarFileId,
    required this.type,
    required this.content,
    this.fileIds = const [],
    this.stickerId,
    this.stickerFileId,
    this.replyToMessageId,
    this.forwardedFromMessageId,
    this.forwardedFromSenderUserId,
    this.forwardedFromSenderName,
    this.forwardCount = 0,
    this.editedAt,
    this.deletedAt,
    this.moderationStatus = '',
    this.moderationPublicComment,
    this.reactions = const [],
    this.readReceipts = const [],
    required this.sentAt,
  });

  bool get isDeleted => deletedAt != null;
  bool get isHiddenByModerator =>
      moderationStatus.trim().toUpperCase() == 'HIDDEN_BY_MODERATION';
  bool get isEdited => editedAt != null;
  bool get hasFiles => fileIds.isNotEmpty;
  bool get isSystem => type == 'system';
  bool get isForwarded =>
      (forwardedFromMessageId?.trim().isNotEmpty ?? false) ||
      (forwardedFromSenderName?.trim().isNotEmpty ?? false);
  bool get isSticker => type == 'sticker' && stickerImageFileId != null;
  String? get stickerImageFileId {
    final normalized = stickerFileId?.trim() ?? '';
    if (normalized.isNotEmpty) return normalized;
    if (type == 'sticker' && fileIds.length == 1) return fileIds.first;
    return null;
  }

  MessageVm copyWith({
    String? senderDisplayName,
    String? senderAvatarFileId,
    String? type,
    String? content,
    List<String>? fileIds,
    String? stickerId,
    String? stickerFileId,
    String? replyToMessageId,
    String? forwardedFromMessageId,
    String? forwardedFromSenderUserId,
    String? forwardedFromSenderName,
    int? forwardCount,
    DateTime? editedAt,
    DateTime? deletedAt,
    String? moderationStatus,
    String? moderationPublicComment,
    List<MessageReactionVm>? reactions,
    List<MessageReadReceiptVm>? readReceipts,
  }) {
    return MessageVm(
      id: id,
      clientMessageId: clientMessageId,
      senderUserId: senderUserId,
      senderDisplayName: senderDisplayName ?? this.senderDisplayName,
      senderAvatarFileId: senderAvatarFileId ?? this.senderAvatarFileId,
      type: type ?? this.type,
      content: content ?? this.content,
      fileIds: fileIds ?? this.fileIds,
      stickerId: stickerId ?? this.stickerId,
      stickerFileId: stickerFileId ?? this.stickerFileId,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      forwardedFromMessageId:
          forwardedFromMessageId ?? this.forwardedFromMessageId,
      forwardedFromSenderUserId:
          forwardedFromSenderUserId ?? this.forwardedFromSenderUserId,
      forwardedFromSenderName:
          forwardedFromSenderName ?? this.forwardedFromSenderName,
      forwardCount: forwardCount ?? this.forwardCount,
      editedAt: editedAt ?? this.editedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      moderationPublicComment:
          moderationPublicComment ?? this.moderationPublicComment,
      reactions: reactions ?? this.reactions,
      readReceipts: readReceipts ?? this.readReceipts,
      sentAt: sentAt,
    );
  }

  factory MessageVm.fromJson(Map<String, dynamic> json) {
    return MessageVm(
      id: (json['id'] ?? json['messageId']) as String,
      clientMessageId: json['clientMessageId']?.toString(),
      senderUserId: json['senderUserId'] as String,
      senderDisplayName: json['senderDisplayName'] as String,
      senderAvatarFileId: json['senderAvatarFileId'] as String?,
      type: json['type'] as String,
      content: json['content'] as String,
      fileIds:
          (json['fileIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      stickerId: json['stickerId']?.toString(),
      stickerFileId: json['stickerFileId']?.toString(),
      replyToMessageId: json['replyToMessageId'] as String?,
      forwardedFromMessageId: json['forwardedFromMessageId']?.toString(),
      forwardedFromSenderUserId: json['forwardedFromSenderUserId']?.toString(),
      forwardedFromSenderName: json['forwardedFromSenderName']?.toString(),
      forwardCount: (json['forwardCount'] as num?)?.toInt() ?? 0,
      editedAt: json['editedAt'] != null
          ? DateTime.parse(json['editedAt'] as String)
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      moderationStatus: json['moderationStatus']?.toString() ?? '',
      moderationPublicComment: _trimmedStringOrNull(
        json['moderationPublicComment'],
      ),
      reactions:
          (json['reactions'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(MessageReactionVm.fromJson)
              .toList(growable: false) ??
          const [],
      readReceipts:
          (json['readReceipts'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(MessageReadReceiptVm.fromJson)
              .toList(growable: false) ??
          const [],
      sentAt: DateTime.parse(json['sentAt'] as String),
    );
  }
}

String? _trimmedStringOrNull(Object? value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty || raw.toLowerCase() == 'null') return null;
  return raw;
}

class MessageReadReceiptVm {
  const MessageReadReceiptVm({required this.userId, required this.readAt});

  final String userId;
  final DateTime readAt;

  factory MessageReadReceiptVm.fromJson(Map<String, dynamic> json) {
    return MessageReadReceiptVm(
      userId: json['userId']?.toString() ?? '',
      readAt: DateTime.parse(json['readAt'] as String),
    );
  }
}

class MessageReactionVm {
  const MessageReactionVm({
    required this.emoji,
    required this.count,
    required this.reactedByMe,
    this.userIds = const [],
    this.users = const [],
  });

  final String emoji;
  final int count;
  final bool reactedByMe;
  final List<String> userIds;
  final List<MessageReactionUserVm> users;

  MessageReactionVm copyWith({
    int? count,
    bool? reactedByMe,
    List<String>? userIds,
    List<MessageReactionUserVm>? users,
  }) {
    return MessageReactionVm(
      emoji: emoji,
      count: count ?? this.count,
      reactedByMe: reactedByMe ?? this.reactedByMe,
      userIds: userIds ?? this.userIds,
      users: users ?? this.users,
    );
  }

  factory MessageReactionVm.fromJson(Map<String, dynamic> json) {
    final userIds =
        (json['userIds'] as List<dynamic>?)
            ?.map((id) => id.toString())
            .where((id) => id.trim().isNotEmpty)
            .toList(growable: false) ??
        const [];
    final users =
        (json['users'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(MessageReactionUserVm.fromJson)
            .where((user) => user.userId.trim().isNotEmpty)
            .toList(growable: false) ??
        const [];
    return MessageReactionVm(
      emoji: json['emoji']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      reactedByMe: json['reactedByMe'] == true,
      userIds: userIds,
      users: users,
    );
  }
}

class MessageReactionUserVm {
  const MessageReactionUserVm({required this.userId, required this.reactedAt});

  final String userId;
  final DateTime reactedAt;

  factory MessageReactionUserVm.fromJson(Map<String, dynamic> json) {
    return MessageReactionUserVm(
      userId: json['userId']?.toString() ?? '',
      reactedAt:
          DateTime.tryParse(json['reactedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}
