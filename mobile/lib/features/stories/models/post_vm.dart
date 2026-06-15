import '../../../core/network/file_api.dart';
import 'post_profile_contract.dart';

class PostStatsVm {
  PostStatsVm({
    required this.views,
    required this.likes,
    required this.comments,
    required this.shares,
  });

  final int views;
  final int likes;
  final int comments;
  final int shares;

  factory PostStatsVm.fromJson(Map<String, dynamic> json) {
    int parse(String key) => int.tryParse(json[key]?.toString() ?? '') ?? 0;

    return PostStatsVm(
      views: parse('views'),
      likes: parse('likes'),
      comments: parse('comments'),
      shares: parse('shares'),
    );
  }

  PostStatsVm copyWith({int? views, int? likes, int? comments, int? shares}) {
    return PostStatsVm(
      views: views ?? this.views,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
    );
  }
}

class PostAuthorVm {
  PostAuthorVm({
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

  factory PostAuthorVm.fromJson(Map<String, dynamic> json) {
    return PostAuthorVm(
      userId: json['userId']?.toString() ?? '',
      nickname: json['nickname']?.toString(),
      avatarFileId: json['avatarFileId']?.toString(),
      countryCode: json['countryCode']?.toString(),
      locale: json['locale']?.toString() ?? 'ru',
      timezone: json['timezone']?.toString() ?? 'Asia/Almaty',
    );
  }

  String get preferredName {
    final value = (nickname ?? '').trim();
    if (value.isNotEmpty) {
      return value;
    }
    if (userId.trim().isNotEmpty) {
      final compact = userId.replaceAll('-', '');
      final short = compact.substring(
        0,
        compact.length >= 8 ? 8 : compact.length,
      );
      return 'user_$short';
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
        .where((e) => e.isNotEmpty)
        .toList();
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

class PostVm {
  PostVm({
    required this.id,
    required this.slug,
    required this.title,
    required this.excerpt,
    required this.category,
    required this.status,
    required this.tags,
    required this.stats,
    required this.author,
    required this.likedByViewer,
    required this.shareUrl,
    required this.createdAt,
    required this.updatedAt,
    this.editable = false,
    this.seenByViewer = false,
    this.format = 'ARTICLE',
    this.postProfileKey,
    this.contentBlocks = const [],
    this.contentSchemaVersion = 1,
    this.revision = 1,
    this.moderationStatus = 'NOT_REQUIRED',
    this.content,
    this.coverFileId,
    this.coverImageUrl,
    this.communityId,
    this.placeName,
    this.placeCountryCode,
    this.placeCityId,
    this.publishedAt,
    this.expiresAt,
    this.seenAt,
    this.lastAutosavedAt,
    this.archivedAt,
  });

  final String id;
  final String slug;
  final String title;
  final String excerpt;
  final String? content;
  final String format;
  final String? postProfileKey;
  final List<Map<String, dynamic>> contentBlocks;
  final int contentSchemaVersion;
  final int revision;
  final String category;
  final String status;
  final String moderationStatus;
  final String? coverFileId;
  final String? coverImageUrl;
  final String? communityId;
  final String? placeName;
  final String? placeCountryCode;
  final String? placeCityId;
  final List<String> tags;
  final PostStatsVm stats;
  final PostAuthorVm author;
  final bool likedByViewer;
  final bool editable;
  final bool seenByViewer;
  final String shareUrl;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final DateTime? seenAt;
  final DateTime? lastAutosavedAt;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PostVm.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    final contentBlocks = _parseContentBlocks(json['contentBlocks']);
    return PostVm(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      excerpt: json['excerpt']?.toString() ?? '',
      content: json['content']?.toString(),
      format: json['format']?.toString() ?? 'ARTICLE',
      postProfileKey: _trimmedStringOrNull(json['postProfileKey']),
      contentBlocks: contentBlocks,
      contentSchemaVersion:
          int.tryParse(json['contentSchemaVersion']?.toString() ?? '') ?? 1,
      revision: int.tryParse(json['revision']?.toString() ?? '') ?? 1,
      category: json['category']?.toString() ?? 'JOURNAL',
      status: json['status']?.toString() ?? 'DRAFT',
      moderationStatus: json['moderationStatus']?.toString() ?? 'NOT_REQUIRED',
      coverFileId: json['coverFileId']?.toString(),
      coverImageUrl: _trimmedStringOrNull(json['coverImageUrl']),
      communityId: _trimmedStringOrNull(json['communityId']),
      placeName: json['placeName']?.toString(),
      placeCountryCode: json['placeCountryCode']?.toString(),
      placeCityId: json['placeCityId']?.toString(),
      tags: rawTags is List
          ? rawTags
                .map((item) => item.toString())
                .where((e) => e.trim().isNotEmpty)
                .toList(growable: false)
          : const [],
      stats: PostStatsVm.fromJson(
        json['stats'] as Map<String, dynamic>? ?? const {},
      ),
      author: PostAuthorVm.fromJson(
        json['author'] as Map<String, dynamic>? ?? const {},
      ),
      likedByViewer: json['likedByViewer'] == true,
      editable: json['editable'] == true,
      seenByViewer: json['seenByViewer'] == true,
      shareUrl: json['shareUrl']?.toString() ?? '',
      publishedAt: DateTime.tryParse(json['publishedAt']?.toString() ?? ''),
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
      seenAt: DateTime.tryParse(json['seenAt']?.toString() ?? ''),
      lastAutosavedAt: DateTime.tryParse(
        json['lastAutosavedAt']?.toString() ?? '',
      ),
      archivedAt: DateTime.tryParse(json['archivedAt']?.toString() ?? ''),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  bool get isPublished => status.trim().toUpperCase() == 'PUBLISHED';

  PostProfileContract get postProfileContract =>
      PostProfileContract.resolve(postProfileKey);

  bool get isQuickPost =>
      postProfileContract.presentationMode == PostPresentationMode.inlineThread;

  bool get opensDetailPage => postProfileContract.opensDetailPage;

  bool get isSeenByViewer => seenByViewer || seenAt != null;

  DateTime? get editedAt => wasEditedAfterPublish ? updatedAt : null;

  bool get wasEditedAfterPublish {
    final base = publishedAt ?? createdAt;
    if (!updatedAt.isAfter(base)) {
      return false;
    }
    return updatedAt.difference(base) >= const Duration(minutes: 1);
  }

  bool get isExpired {
    final value = expiresAt;
    if (value == null) {
      return false;
    }
    return !value.isAfter(DateTime.now().toUtc());
  }

  bool isOwnedBy(String? userId) {
    final current = (userId ?? '').trim();
    if (current.isEmpty) {
      return false;
    }
    return author.userId.trim() == current;
  }

  DateTime get sortDate => publishedAt ?? createdAt;

  String? get coverUrl {
    return resolvePublicFileContentUrlFromResponse(
      fileId: coverFileId,
      contentUrl: coverImageUrl,
    );
  }

  PostVm copyWith({
    PostStatsVm? stats,
    bool? likedByViewer,
    bool? editable,
    bool? seenByViewer,
    String? shareUrl,
    String? title,
    String? excerpt,
    String? content,
    String? format,
    String? postProfileKey,
    List<Map<String, dynamic>>? contentBlocks,
    int? contentSchemaVersion,
    int? revision,
    String? category,
    String? status,
    String? moderationStatus,
    String? coverFileId,
    String? coverImageUrl,
    String? placeName,
    String? placeCountryCode,
    String? placeCityId,
    List<String>? tags,
    DateTime? publishedAt,
    DateTime? expiresAt,
    DateTime? seenAt,
    DateTime? lastAutosavedAt,
    DateTime? archivedAt,
    DateTime? updatedAt,
  }) {
    return PostVm(
      id: id,
      slug: slug,
      title: title ?? this.title,
      excerpt: excerpt ?? this.excerpt,
      content: content ?? this.content,
      format: format ?? this.format,
      postProfileKey: postProfileKey ?? this.postProfileKey,
      contentBlocks: contentBlocks ?? this.contentBlocks,
      contentSchemaVersion: contentSchemaVersion ?? this.contentSchemaVersion,
      revision: revision ?? this.revision,
      category: category ?? this.category,
      status: status ?? this.status,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      coverFileId: coverFileId ?? this.coverFileId,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      placeName: placeName ?? this.placeName,
      placeCountryCode: placeCountryCode ?? this.placeCountryCode,
      placeCityId: placeCityId ?? this.placeCityId,
      tags: tags ?? this.tags,
      stats: stats ?? this.stats,
      author: author,
      likedByViewer: likedByViewer ?? this.likedByViewer,
      editable: editable ?? this.editable,
      seenByViewer: seenByViewer ?? this.seenByViewer,
      shareUrl: shareUrl ?? this.shareUrl,
      publishedAt: publishedAt ?? this.publishedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      seenAt: seenAt ?? this.seenAt,
      lastAutosavedAt: lastAutosavedAt ?? this.lastAutosavedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

List<Map<String, dynamic>> _parseContentBlocks(Object? rawContentBlocks) {
  final rawBlocks = switch (rawContentBlocks) {
    final List<dynamic> blocks => blocks,
    final Map<String, dynamic> document when document['blocks'] is List =>
      document['blocks'] as List<dynamic>,
    _ => const <dynamic>[],
  };

  return rawBlocks
      .whereType<Map<String, dynamic>>()
      .map(Map<String, dynamic>.unmodifiable)
      .toList(growable: false);
}

class PostCommentVm {
  PostCommentVm({
    required this.id,
    required this.postId,
    required this.body,
    required this.editable,
    required this.deletable,
    required this.edited,
    required this.likes,
    required this.likedByMe,
    required this.shareUrl,
    required this.author,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String postId;
  final String body;
  final bool editable;
  final bool deletable;
  final bool edited;
  final int likes;
  final bool likedByMe;
  final String shareUrl;
  final PostAuthorVm author;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PostCommentVm.fromJson(Map<String, dynamic> json) {
    return PostCommentVm(
      id: json['id']?.toString() ?? '',
      postId: json['postId']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      editable: json['editable'] == true,
      deletable: json['deletable'] == true,
      edited: json['edited'] == true,
      likes: int.tryParse(json['likes']?.toString() ?? '') ?? 0,
      likedByMe: json['likedByMe'] == true,
      shareUrl: json['shareUrl']?.toString() ?? '',
      author: PostAuthorVm.fromJson(
        json['author'] as Map<String, dynamic>? ?? const {},
      ),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  PostCommentVm copyWith({
    String? body,
    bool? editable,
    bool? deletable,
    bool? edited,
    int? likes,
    bool? likedByMe,
    String? shareUrl,
    PostAuthorVm? author,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostCommentVm(
      id: id,
      postId: postId,
      body: body ?? this.body,
      editable: editable ?? this.editable,
      deletable: deletable ?? this.deletable,
      edited: edited ?? this.edited,
      likes: likes ?? this.likes,
      likedByMe: likedByMe ?? this.likedByMe,
      shareUrl: shareUrl ?? this.shareUrl,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PostDetailVm {
  PostDetailVm({
    required this.post,
    required this.related,
    required this.comments,
  });

  final PostVm post;
  final List<PostVm> related;
  final List<PostCommentVm> comments;

  factory PostDetailVm.fromJson(Map<String, dynamic> json) {
    final rawRelated = json['related'];
    final rawComments = json['comments'];

    return PostDetailVm(
      post: PostVm.fromJson(json['post'] as Map<String, dynamic>? ?? const {}),
      related: rawRelated is List
          ? rawRelated
                .whereType<Map<String, dynamic>>()
                .map(PostVm.fromJson)
                .toList(growable: false)
          : const [],
      comments: rawComments is List
          ? rawComments
                .whereType<Map<String, dynamic>>()
                .map(PostCommentVm.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  PostDetailVm copyWith({
    PostVm? post,
    List<PostVm>? related,
    List<PostCommentVm>? comments,
  }) {
    return PostDetailVm(
      post: post ?? this.post,
      related: related ?? this.related,
      comments: comments ?? this.comments,
    );
  }
}

class PostReportSubmissionVm {
  PostReportSubmissionVm({
    required this.openReportsCount,
    required this.autoHidden,
    this.reportId,
    this.reportStatus,
    this.post,
  });

  final String? reportId;
  final String? reportStatus;
  final int openReportsCount;
  final bool autoHidden;
  final PostVm? post;

  factory PostReportSubmissionVm.fromJson(Map<String, dynamic> json) {
    final rawReport = json['report'];
    final rawPost = json['post'];
    return PostReportSubmissionVm(
      reportId: rawReport is Map<String, dynamic>
          ? _trimmedStringOrNull(rawReport['id'])
          : null,
      reportStatus: rawReport is Map<String, dynamic>
          ? _trimmedStringOrNull(rawReport['status'])
          : null,
      openReportsCount:
          int.tryParse(json['openReportsCount']?.toString() ?? '') ?? 0,
      autoHidden: json['autoHidden'] == true,
      post: rawPost is Map<String, dynamic> ? PostVm.fromJson(rawPost) : null,
    );
  }
}

String? _trimmedStringOrNull(Object? value) {
  final trimmed = (value?.toString() ?? '').trim();
  return trimmed.isEmpty ? null : trimmed;
}
