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
      fileIds: (json['fileIds'] as List<dynamic>?)
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
      sentAt: DateTime.parse(json['sentAt'] as String),
    );
  }
}
