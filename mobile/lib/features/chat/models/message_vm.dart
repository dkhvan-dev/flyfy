class MessageVm {
  final String id;
  final String senderUserId;
  final String senderDisplayName;
  final String? senderAvatarFileId;
  final String type;
  final String content;
  final List<String> fileIds;
  final String? replyToMessageId;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final List<MessageReactionVm> reactions;
  final DateTime sentAt;

  const MessageVm({
    required this.id,
    required this.senderUserId,
    required this.senderDisplayName,
    this.senderAvatarFileId,
    required this.type,
    required this.content,
    this.fileIds = const [],
    this.replyToMessageId,
    this.editedAt,
    this.deletedAt,
    this.reactions = const [],
    required this.sentAt,
  });

  bool get isDeleted => deletedAt != null;
  bool get isEdited => editedAt != null;
  bool get hasFiles => fileIds.isNotEmpty;
  bool get isSystem => type == 'system';

  MessageVm copyWith({
    String? senderDisplayName,
    String? senderAvatarFileId,
    String? type,
    String? content,
    List<String>? fileIds,
    String? replyToMessageId,
    DateTime? editedAt,
    DateTime? deletedAt,
    List<MessageReactionVm>? reactions,
  }) {
    return MessageVm(
      id: id,
      senderUserId: senderUserId,
      senderDisplayName: senderDisplayName ?? this.senderDisplayName,
      senderAvatarFileId: senderAvatarFileId ?? this.senderAvatarFileId,
      type: type ?? this.type,
      content: content ?? this.content,
      fileIds: fileIds ?? this.fileIds,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      editedAt: editedAt ?? this.editedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      reactions: reactions ?? this.reactions,
      sentAt: sentAt,
    );
  }

  factory MessageVm.fromJson(Map<String, dynamic> json) {
    return MessageVm(
      id: (json['id'] ?? json['messageId']) as String,
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
      replyToMessageId: json['replyToMessageId'] as String?,
      editedAt: json['editedAt'] != null
          ? DateTime.parse(json['editedAt'] as String)
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      reactions:
          (json['reactions'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(MessageReactionVm.fromJson)
              .toList(growable: false) ??
          const [],
      sentAt: DateTime.parse(json['sentAt'] as String),
    );
  }
}

class MessageReactionVm {
  const MessageReactionVm({
    required this.emoji,
    required this.count,
    required this.reactedByMe,
  });

  final String emoji;
  final int count;
  final bool reactedByMe;

  MessageReactionVm copyWith({int? count, bool? reactedByMe}) {
    return MessageReactionVm(
      emoji: emoji,
      count: count ?? this.count,
      reactedByMe: reactedByMe ?? this.reactedByMe,
    );
  }

  factory MessageReactionVm.fromJson(Map<String, dynamic> json) {
    return MessageReactionVm(
      emoji: json['emoji']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      reactedByMe: json['reactedByMe'] == true,
    );
  }
}
