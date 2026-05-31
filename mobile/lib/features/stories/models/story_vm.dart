import '../../../core/network/file_api.dart';

class StoryStatsVm {
  StoryStatsVm({
    required this.views,
    required this.likes,
    required this.comments,
    required this.shares,
  });

  final int views;
  final int likes;
  final int comments;
  final int shares;

  factory StoryStatsVm.fromJson(Map<String, dynamic> json) {
    int parse(String key) => int.tryParse(json[key]?.toString() ?? '') ?? 0;

    return StoryStatsVm(
      views: parse('views'),
      likes: parse('likes'),
      comments: parse('comments'),
      shares: parse('shares'),
    );
  }

  StoryStatsVm copyWith({int? views, int? likes, int? comments, int? shares}) {
    return StoryStatsVm(
      views: views ?? this.views,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
    );
  }
}

class StoryAuthorVm {
  StoryAuthorVm({
    required this.userId,
    required this.locale,
    required this.timezone,
    this.displayName,
    this.avatarFileId,
    this.countryCode,
  });

  final String userId;
  final String locale;
  final String timezone;
  final String? displayName;
  final String? avatarFileId;
  final String? countryCode;

  factory StoryAuthorVm.fromJson(Map<String, dynamic> json) {
    return StoryAuthorVm(
      userId: json['userId']?.toString() ?? '',
      displayName: json['displayName']?.toString(),
      avatarFileId: json['avatarFileId']?.toString(),
      countryCode: json['countryCode']?.toString(),
      locale: json['locale']?.toString() ?? 'ru',
      timezone: json['timezone']?.toString() ?? 'Asia/Almaty',
    );
  }

  String get preferredName {
    final value = (displayName ?? '').trim();
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

class StoryVm {
  StoryVm({
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
    this.content,
    this.coverFileId,
    this.placeName,
    this.placeCountryCode,
    this.placeCityId,
    this.publishedAt,
  });

  final String id;
  final String slug;
  final String title;
  final String excerpt;
  final String? content;
  final String category;
  final String status;
  final String? coverFileId;
  final String? placeName;
  final String? placeCountryCode;
  final String? placeCityId;
  final List<String> tags;
  final StoryStatsVm stats;
  final StoryAuthorVm author;
  final bool likedByViewer;
  final String shareUrl;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory StoryVm.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    return StoryVm(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      excerpt: json['excerpt']?.toString() ?? '',
      content: json['content']?.toString(),
      category: json['category']?.toString() ?? 'JOURNAL',
      status: json['status']?.toString() ?? 'DRAFT',
      coverFileId: json['coverFileId']?.toString(),
      placeName: json['placeName']?.toString(),
      placeCountryCode: json['placeCountryCode']?.toString(),
      placeCityId: json['placeCityId']?.toString(),
      tags: rawTags is List
          ? rawTags
                .map((item) => item.toString())
                .where((e) => e.trim().isNotEmpty)
                .toList(growable: false)
          : const [],
      stats: StoryStatsVm.fromJson(
        json['stats'] as Map<String, dynamic>? ?? const {},
      ),
      author: StoryAuthorVm.fromJson(
        json['author'] as Map<String, dynamic>? ?? const {},
      ),
      likedByViewer: json['likedByViewer'] == true,
      shareUrl: json['shareUrl']?.toString() ?? '',
      publishedAt: DateTime.tryParse(json['publishedAt']?.toString() ?? ''),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  bool get isPublished => status.trim().toUpperCase() == 'PUBLISHED';

  bool isOwnedBy(String? userId) {
    final current = (userId ?? '').trim();
    if (current.isEmpty) {
      return false;
    }
    return author.userId.trim() == current;
  }

  DateTime get sortDate => publishedAt ?? createdAt;

  String? get coverUrl {
    final trimmed = (coverFileId ?? '').trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return resolvePublicFileContentUrl(trimmed);
  }

  StoryVm copyWith({
    StoryStatsVm? stats,
    bool? likedByViewer,
    String? shareUrl,
    String? title,
    String? excerpt,
    String? content,
    String? category,
    String? status,
    String? coverFileId,
    String? placeName,
    String? placeCountryCode,
    String? placeCityId,
    List<String>? tags,
    DateTime? publishedAt,
    DateTime? updatedAt,
  }) {
    return StoryVm(
      id: id,
      slug: slug,
      title: title ?? this.title,
      excerpt: excerpt ?? this.excerpt,
      content: content ?? this.content,
      category: category ?? this.category,
      status: status ?? this.status,
      coverFileId: coverFileId ?? this.coverFileId,
      placeName: placeName ?? this.placeName,
      placeCountryCode: placeCountryCode ?? this.placeCountryCode,
      placeCityId: placeCityId ?? this.placeCityId,
      tags: tags ?? this.tags,
      stats: stats ?? this.stats,
      author: author,
      likedByViewer: likedByViewer ?? this.likedByViewer,
      shareUrl: shareUrl ?? this.shareUrl,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class StoryCommentVm {
  StoryCommentVm({
    required this.id,
    required this.storyId,
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
  final String storyId;
  final String body;
  final bool editable;
  final bool deletable;
  final bool edited;
  final int likes;
  final bool likedByMe;
  final String shareUrl;
  final StoryAuthorVm author;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory StoryCommentVm.fromJson(Map<String, dynamic> json) {
    return StoryCommentVm(
      id: json['id']?.toString() ?? '',
      storyId: json['storyId']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      editable: json['editable'] == true,
      deletable: json['deletable'] == true,
      edited: json['edited'] == true,
      likes: int.tryParse(json['likes']?.toString() ?? '') ?? 0,
      likedByMe: json['likedByMe'] == true,
      shareUrl: json['shareUrl']?.toString() ?? '',
      author: StoryAuthorVm.fromJson(
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

  StoryCommentVm copyWith({
    String? body,
    bool? editable,
    bool? deletable,
    bool? edited,
    int? likes,
    bool? likedByMe,
    String? shareUrl,
    StoryAuthorVm? author,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StoryCommentVm(
      id: id,
      storyId: storyId,
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

class StoryDetailVm {
  StoryDetailVm({
    required this.story,
    required this.related,
    required this.comments,
  });

  final StoryVm story;
  final List<StoryVm> related;
  final List<StoryCommentVm> comments;

  factory StoryDetailVm.fromJson(Map<String, dynamic> json) {
    final rawRelated = json['related'];
    final rawComments = json['comments'];

    return StoryDetailVm(
      story: StoryVm.fromJson(
        json['story'] as Map<String, dynamic>? ?? const {},
      ),
      related: rawRelated is List
          ? rawRelated
                .whereType<Map<String, dynamic>>()
                .map(StoryVm.fromJson)
                .toList(growable: false)
          : const [],
      comments: rawComments is List
          ? rawComments
                .whereType<Map<String, dynamic>>()
                .map(StoryCommentVm.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  StoryDetailVm copyWith({
    StoryVm? story,
    List<StoryVm>? related,
    List<StoryCommentVm>? comments,
  }) {
    return StoryDetailVm(
      story: story ?? this.story,
      related: related ?? this.related,
      comments: comments ?? this.comments,
    );
  }
}
