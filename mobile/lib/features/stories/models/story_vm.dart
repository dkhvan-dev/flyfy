// Compatibility constructor normalizes legacy post fixtures and true story API
// payloads while the editor/post UI finishes moving to PostVm.
// ignore_for_file: prefer_initializing_formals

import '../../../core/network/file_api.dart';

class StoryStatsVm {
  StoryStatsVm({
    required this.views,
    required this.likes,
    int? replies,
    int? comments,
    int? shares,
  }) : replies = replies ?? comments ?? 0,
       shares = shares ?? 0;

  final int views;
  final int likes;
  final int replies;
  final int shares;

  int get comments => replies;

  factory StoryStatsVm.fromJson(Map<String, dynamic> json) {
    int parse(String key) => int.tryParse(json[key]?.toString() ?? '') ?? 0;

    return StoryStatsVm(
      views: parse('views'),
      likes: parse('likes'),
      replies: parse('replies') > 0 ? parse('replies') : parse('comments'),
    );
  }

  StoryStatsVm copyWith({int? views, int? likes, int? replies}) {
    return StoryStatsVm(
      views: views ?? this.views,
      likes: likes ?? this.likes,
      replies: replies ?? this.replies,
    );
  }
}

class StoryAuthorVm {
  const StoryAuthorVm({
    required this.userId,
    required this.locale,
    required this.timezone,
    this.nickname,
    this.avatarFileId,
    this.countryCode,
  });

  final String userId;
  final String locale;
  final String timezone;
  final String? nickname;
  final String? avatarFileId;
  final String? countryCode;

  factory StoryAuthorVm.fromJson(Map<String, dynamic> json) {
    return StoryAuthorVm(
      userId: json['userId']?.toString() ?? '',
      nickname: _trimmedStringOrNull(json['nickname'] ?? json['displayName']),
      avatarFileId: _trimmedStringOrNull(json['avatarFileId']),
      countryCode: _trimmedStringOrNull(json['countryCode']),
      locale: _trimmedStringOrNull(json['locale']) ?? 'ru',
      timezone: _trimmedStringOrNull(json['timezone']) ?? 'Asia/Almaty',
    );
  }

  String get preferredName {
    final value = (nickname ?? '').trim();
    if (value.isNotEmpty) {
      return value;
    }
    final compact = userId.replaceAll('-', '');
    if (compact.isNotEmpty) {
      return 'user_${compact.substring(0, compact.length >= 8 ? 8 : compact.length)}';
    }
    return 'Inflap';
  }

  String get initials {
    final source = preferredName.trim();
    if (source.isEmpty) {
      return 'F';
    }
    final parts = source
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  String? get avatarUrl {
    final trimmed = (avatarFileId ?? '').trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return resolvePublicFileContentUrl(trimmed);
  }
}

class StoryVm {
  StoryVm({
    required this.id,
    String? caption,
    String? mediaFileId,
    String? mediaType,
    StoryStatsVm? stats,
    StoryAuthorVm? author,
    bool seenByViewer = false,
    String shareUrl = '',
    DateTime? expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.mediaUrl,
    this.coverFileId,
    this.coverImageUrl,
    this.seenAt,
    String? slug,
    String? title,
    String? excerpt,
    String? content,
    String? format,
    String? category,
    String? status,
    String? moderationStatus,
    List<String>? tags,
    bool likedByViewer = false,
    DateTime? publishedAt,
    DateTime? lastAutosavedAt,
    DateTime? archivedAt,
    int revision = 1,
    int contentSchemaVersion = 1,
    List<Map<String, dynamic>> contentBlocks = const [],
    String? communityId,
    String? placeName,
    String? placeCountryCode,
    String? placeCityId,
  }) : caption = caption ?? excerpt ?? title ?? '',
       mediaFileId = mediaFileId ?? coverFileId ?? '',
       mediaType = mediaType ?? 'IMAGE',
       stats = stats ?? StoryStatsVm(views: 0, likes: 0),
       author =
           author ??
           const StoryAuthorVm(
             userId: '',
             locale: 'ru',
             timezone: 'Asia/Almaty',
           ),
       seenByViewer = seenByViewer,
       shareUrl = shareUrl,
       expiresAt =
           expiresAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
       _slug = slug,
       _title = title,
       _excerpt = excerpt,
       _content = content,
       _format = format,
       _category = category,
       _status = status,
       _moderationStatus = moderationStatus,
       _tags = tags == null ? null : List<String>.unmodifiable(tags),
       _likedByViewer = likedByViewer,
       _publishedAt = publishedAt,
       _lastAutosavedAt = lastAutosavedAt,
       _archivedAt = archivedAt,
       _revision = revision,
       _contentSchemaVersion = contentSchemaVersion,
       _contentBlocks = List<Map<String, dynamic>>.unmodifiable(contentBlocks),
       _communityId = communityId,
       _placeName = placeName,
       _placeCountryCode = placeCountryCode,
       _placeCityId = placeCityId;

  final String id;
  final String caption;
  final String mediaFileId;
  final String? mediaUrl;
  final String? coverFileId;
  final String? coverImageUrl;
  final String mediaType;
  final StoryStatsVm stats;
  final StoryAuthorVm author;
  final bool seenByViewer;
  final DateTime? seenAt;
  final String shareUrl;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? _slug;
  final String? _title;
  final String? _excerpt;
  final String? _content;
  final String? _format;
  final String? _category;
  final String? _status;
  final String? _moderationStatus;
  final List<String>? _tags;
  final bool _likedByViewer;
  final DateTime? _publishedAt;
  final DateTime? _lastAutosavedAt;
  final DateTime? _archivedAt;
  final int _revision;
  final int _contentSchemaVersion;
  final List<Map<String, dynamic>> _contentBlocks;
  final String? _communityId;
  final String? _placeName;
  final String? _placeCountryCode;
  final String? _placeCityId;

  factory StoryVm.fromJson(Map<String, dynamic> json) {
    final statsJson = _stringKeyedMap(json['stats']);
    return StoryVm(
      id: json['id']?.toString() ?? '',
      caption:
          _trimmedStringOrNull(json['caption']) ??
          _trimmedStringOrNull(json['title']) ??
          '',
      mediaFileId:
          _trimmedStringOrNull(json['mediaFileId']) ??
          _trimmedStringOrNull(json['coverFileId']) ??
          '',
      mediaUrl: _trimmedStringOrNull(json['mediaUrl']),
      coverFileId:
          _trimmedStringOrNull(json['coverFileId']) ??
          _trimmedStringOrNull(json['mediaFileId']),
      coverImageUrl:
          _trimmedStringOrNull(json['coverImageUrl']) ??
          _trimmedStringOrNull(json['mediaUrl']),
      mediaType: _trimmedStringOrNull(json['mediaType']) ?? 'IMAGE',
      stats: StoryStatsVm.fromJson(statsJson),
      author: StoryAuthorVm.fromJson(_stringKeyedMap(json['author'])),
      seenByViewer: json['seenByViewer'] == true,
      seenAt: DateTime.tryParse(json['seenAt']?.toString() ?? ''),
      shareUrl: json['shareUrl']?.toString() ?? '',
      expiresAt:
          DateTime.tryParse(json['expiresAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  String get slug => _slug ?? id;

  String get title {
    final explicit = (_title ?? '').trim();
    if (explicit.isNotEmpty) {
      return explicit;
    }
    final value = caption.trim();
    return value.isEmpty ? author.preferredName : value;
  }

  String get excerpt => _excerpt ?? caption;

  String? get content => _content ?? caption;

  String get format => _format ?? 'STORY';

  String get category => _category ?? 'STORY';

  String get status => _status ?? 'PUBLISHED';

  String get moderationStatus => _moderationStatus ?? 'NOT_REQUIRED';

  List<String> get tags => _tags ?? const ['story'];

  bool get likedByViewer => _likedByViewer;

  bool get isPublished => status.trim().toUpperCase() == 'PUBLISHED';

  DateTime? get publishedAt => _publishedAt ?? createdAt;

  DateTime? get lastAutosavedAt => _lastAutosavedAt;

  DateTime? get archivedAt => _archivedAt;

  int get revision => _revision;

  int get contentSchemaVersion => _contentSchemaVersion;

  List<Map<String, dynamic>> get contentBlocks => _contentBlocks;

  String? get communityId => _communityId;

  String? get placeName => _placeName;

  String? get placeCountryCode => _placeCountryCode;

  String? get placeCityId => _placeCityId;

  String? get coverUrl {
    return resolvePublicFileContentUrlFromResponse(
      fileId: coverFileId ?? mediaFileId,
      contentUrl: coverImageUrl ?? mediaUrl,
    );
  }

  bool get isSeenByViewer => seenByViewer || seenAt != null;

  bool get isExpired => !expiresAt.isAfter(DateTime.now().toUtc());

  DateTime get sortDate => createdAt;

  bool isOwnedBy(String? userId) {
    final current = (userId ?? '').trim();
    return current.isNotEmpty && author.userId.trim() == current;
  }

  StoryVm copyWith({
    String? caption,
    String? mediaFileId,
    String? mediaUrl,
    String? coverFileId,
    String? coverImageUrl,
    String? mediaType,
    StoryStatsVm? stats,
    bool? seenByViewer,
    String? shareUrl,
    DateTime? expiresAt,
    DateTime? seenAt,
    DateTime? updatedAt,
  }) {
    return StoryVm(
      id: id,
      caption: caption ?? this.caption,
      mediaFileId: mediaFileId ?? this.mediaFileId,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      coverFileId: coverFileId ?? this.coverFileId,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      mediaType: mediaType ?? this.mediaType,
      stats: stats ?? this.stats,
      author: author,
      seenByViewer: seenByViewer ?? this.seenByViewer,
      shareUrl: shareUrl ?? this.shareUrl,
      expiresAt: expiresAt ?? this.expiresAt,
      seenAt: seenAt ?? this.seenAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      slug: _slug,
      title: _title,
      excerpt: _excerpt,
      content: _content,
      format: _format,
      category: _category,
      status: _status,
      moderationStatus: _moderationStatus,
      tags: _tags,
      likedByViewer: _likedByViewer,
      publishedAt: _publishedAt,
      lastAutosavedAt: _lastAutosavedAt,
      archivedAt: _archivedAt,
      revision: _revision,
      contentSchemaVersion: _contentSchemaVersion,
      contentBlocks: _contentBlocks,
      communityId: _communityId,
      placeName: _placeName,
      placeCountryCode: _placeCountryCode,
      placeCityId: _placeCityId,
    );
  }
}

Map<String, dynamic> _stringKeyedMap(Object? rawMap) {
  if (rawMap is! Map) {
    return const {};
  }

  return Map<String, dynamic>.unmodifiable({
    for (final entry in rawMap.entries) entry.key.toString(): entry.value,
  });
}

String? _trimmedStringOrNull(Object? value) {
  final trimmed = (value?.toString() ?? '').trim();
  return trimmed.isEmpty ? null : trimmed;
}
