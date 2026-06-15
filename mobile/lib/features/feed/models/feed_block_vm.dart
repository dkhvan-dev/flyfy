import '../../stories/models/post_vm.dart';
import '../../stories/models/post_profile_contract.dart';
import '../../stories/models/story_vm.dart';

enum FeedBlockType {
  storiesTray,
  suggestedCommunities,
  mySubscriptions,
  systemPosts,
  postCard,
  tourCard,
  guideCard,
  profileCard,
  officialNewsCard,
  unknown,
}

class FeedPageVm {
  FeedPageVm({
    this.nextCursor,
    this.assignment = const FeedAssignmentVm(),
    List<FeedBlockVm> items = const [],
  }) : items = List<FeedBlockVm>.unmodifiable(items);

  final String? nextCursor;
  final FeedAssignmentVm assignment;
  final List<FeedBlockVm> items;

  factory FeedPageVm.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return FeedPageVm(
      nextCursor: _trimmedStringOrNull(json['nextCursor']),
      assignment: FeedAssignmentVm.fromJson(
        _stringKeyedMap(json['assignment']),
      ),
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(_stringKeyedMap)
                .map(FeedBlockVm.fromJson)
                .toList(growable: false)
          : const [],
    );
  }
}

class FeedAssignmentVm {
  const FeedAssignmentVm({this.rankingExperiment});

  final String? rankingExperiment;

  factory FeedAssignmentVm.fromJson(Map<String, dynamic> json) {
    return FeedAssignmentVm(
      rankingExperiment: _trimmedStringOrNull(json['rankingExperiment']),
    );
  }
}

class CommunityListPageVm {
  CommunityListPageVm({
    List<FeedCommunityVm> items = const [],
    this.limit = 20,
    this.offset = 0,
  }) : items = List<FeedCommunityVm>.unmodifiable(items);

  final List<FeedCommunityVm> items;
  final int limit;
  final int offset;

  bool get hasMore => items.length >= limit && limit > 0;

  factory CommunityListPageVm.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final limit = _parseInt(json['limit']);
    return CommunityListPageVm(
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(_stringKeyedMap)
                .map(FeedCommunityVm.fromJson)
                .toList(growable: false)
          : const [],
      limit: limit <= 0 ? 20 : limit,
      offset: _parseInt(json['offset']),
    );
  }
}

class FeedBlockVm {
  FeedBlockVm({
    required this.id,
    required this.type,
    Map<String, dynamic> data = const {},
    List<StoryVm> stories = const [],
    List<FeedCommunityVm> communities = const [],
    List<FeedPersonVm> people = const [],
    List<PostVm> posts = const [],
    this.post,
  }) : data = Map<String, dynamic>.unmodifiable(data),
       stories = List<StoryVm>.unmodifiable(stories),
       communities = List<FeedCommunityVm>.unmodifiable(communities),
       people = List<FeedPersonVm>.unmodifiable(people),
       posts = List<PostVm>.unmodifiable(posts);

  final String id;
  final FeedBlockType type;
  final Map<String, dynamic> data;
  final List<StoryVm> stories;
  final List<FeedCommunityVm> communities;
  final List<FeedPersonVm> people;
  final List<PostVm> posts;
  final PostVm? post;

  factory FeedBlockVm.fromJson(Map<String, dynamic> json) {
    final type = _parseFeedBlockType(json['type']);
    final data = _stringKeyedMap(json['data']);

    return switch (type) {
      FeedBlockType.storiesTray => FeedBlockVm(
        id: json['id']?.toString() ?? '',
        type: type,
        data: data,
        stories: _parseStories(data['stories'] ?? data['items']),
      ),
      FeedBlockType.suggestedCommunities => FeedBlockVm(
        id: json['id']?.toString() ?? '',
        type: type,
        data: data,
        communities: _parseCommunities(data['communities'] ?? data['items']),
      ),
      FeedBlockType.mySubscriptions => FeedBlockVm(
        id: json['id']?.toString() ?? '',
        type: type,
        data: data,
        communities: _parseCommunities(data['communities']),
        people: _parsePeople(data['people'] ?? data['users']),
      ),
      FeedBlockType.systemPosts => FeedBlockVm(
        id: json['id']?.toString() ?? '',
        type: type,
        data: data,
        posts: _parsePosts(data['posts'] ?? data['items']),
      ),
      FeedBlockType.postCard => FeedBlockVm(
        id: json['id']?.toString() ?? '',
        type: type,
        data: data,
        post: _parsePost(data['post'] ?? data['story'] ?? data),
      ),
      FeedBlockType.tourCard ||
      FeedBlockType.guideCard ||
      FeedBlockType.profileCard ||
      FeedBlockType.officialNewsCard => FeedBlockVm(
        id: json['id']?.toString() ?? '',
        type: type,
        data: data,
      ),
      FeedBlockType.unknown => FeedBlockVm(
        id: json['id']?.toString() ?? '',
        type: FeedBlockType.unknown,
        data: data,
      ),
    };
  }
}

List<FeedBlockVm> mergeFeedBlockPages(
  List<FeedBlockVm> existing,
  List<FeedBlockVm> incoming,
) {
  if (existing.isEmpty) {
    return List<FeedBlockVm>.unmodifiable(incoming);
  }
  if (incoming.isEmpty) {
    return List<FeedBlockVm>.unmodifiable(existing);
  }

  final seenIdentities = <String>{
    for (final block in existing) ?_feedBlockIdentity(block),
  };
  final merged = <FeedBlockVm>[...existing];

  for (final block in incoming) {
    final identity = _feedBlockIdentity(block);
    if (identity != null && !seenIdentities.add(identity)) {
      continue;
    }
    merged.add(block);
  }

  return List<FeedBlockVm>.unmodifiable(merged);
}

String? _feedBlockIdentity(FeedBlockVm block) {
  final id = _trimmedStringOrNull(block.id);
  if (id != null) {
    return id;
  }

  final postID = _trimmedStringOrNull(block.post?.id);
  if (postID != null) {
    return '${block.type.name}:$postID';
  }

  return null;
}

class FeedCommunityVm {
  FeedCommunityVm({
    required this.id,
    required this.title,
    Map<String, String> titleI18n = const {},
    this.subtitle,
    this.description,
    Map<String, String> descriptionI18n = const {},
    this.topic,
    this.avatarFileId,
    this.coverFileId,
    this.visibility = 'PUBLIC',
    this.postingPolicy = 'MEMBERS_AFTER_MODERATION',
    this.status = 'ACTIVE',
    this.defaultPostProfileKey = PostProfileKeys.article,
    List<String> allowedPostProfileKeys = const [],
    List<String> enabledTabs = const [],
    this.languageCode,
    this.countryCode,
    this.cityId,
    this.cityName,
    this.membersCount = 0,
    this.postCount = 0,
    this.followedByViewer = false,
    this.viewerRole,
    this.viewerCanModerate = false,
    this.viewerTrustStatus = 'ACTIVE',
    this.viewerRestrictionId,
    this.mutedByViewer = false,
    List<String> rules = const [],
  }) : allowedPostProfileKeys = List<String>.unmodifiable(
         _normalizePostProfileKeys(
           allowedPostProfileKeys,
           fallback: defaultPostProfileKey,
         ),
       ),
       titleI18n = Map<String, String>.unmodifiable(titleI18n),
       descriptionI18n = Map<String, String>.unmodifiable(descriptionI18n),
       enabledTabs = List<String>.unmodifiable(_parseStringList(enabledTabs)),
       rules = List<String>.unmodifiable(rules);

  final String id;
  final String title;
  final Map<String, String> titleI18n;
  final String? subtitle;
  final String? description;
  final Map<String, String> descriptionI18n;
  final String? topic;
  final String? avatarFileId;
  final String? coverFileId;
  final String visibility;
  final String postingPolicy;
  final String status;
  final String defaultPostProfileKey;
  final List<String> allowedPostProfileKeys;
  final List<String> enabledTabs;
  final String? languageCode;
  final String? countryCode;
  final String? cityId;
  final String? cityName;
  final int membersCount;
  final int postCount;
  final bool followedByViewer;
  final String? viewerRole;
  final bool viewerCanModerate;
  final String viewerTrustStatus;
  final String? viewerRestrictionId;
  final bool mutedByViewer;
  final List<String> rules;

  factory FeedCommunityVm.fromJson(Map<String, dynamic> json) {
    final description = _trimmedStringOrNull(json['description']);
    return FeedCommunityVm(
      id: json['id']?.toString() ?? '',
      title: _trimmedStringOrNull(json['title'] ?? json['name']) ?? '',
      titleI18n: _parseStringMap(json['titleI18n'] ?? json['nameI18n']),
      subtitle: _trimmedStringOrNull(json['subtitle']) ?? description,
      description: description,
      descriptionI18n: _parseStringMap(json['descriptionI18n']),
      topic: _trimmedStringOrNull(json['topic']),
      avatarFileId: _trimmedStringOrNull(json['avatarFileId']),
      coverFileId: _trimmedStringOrNull(json['coverFileId']),
      visibility: _trimmedStringOrNull(json['visibility']) ?? 'PUBLIC',
      postingPolicy:
          _trimmedStringOrNull(json['postingPolicy']) ??
          'MEMBERS_AFTER_MODERATION',
      status: _trimmedStringOrNull(json['status']) ?? 'ACTIVE',
      defaultPostProfileKey:
          _trimmedStringOrNull(json['defaultPostProfileKey']) ??
          _trimmedStringOrNull(json['postProfileKey']) ??
          PostProfileKeys.article,
      allowedPostProfileKeys: _parseStringList(
        json['allowedPostProfileKeys'] ?? json['allowedPostProfiles'],
      ),
      enabledTabs: _parseStringList(json['enabledTabs'] ?? json['tabs']),
      languageCode: _trimmedStringOrNull(json['languageCode']),
      countryCode: _trimmedStringOrNull(json['countryCode']),
      cityId: _trimmedStringOrNull(json['cityId']),
      cityName:
          _trimmedStringOrNull(json['cityName']) ??
          _trimmedStringOrNull(json['city']),
      membersCount: _parseInt(
        json['membersCount'] ?? json['memberCount'] ?? json['followerCount'],
      ),
      postCount: _parseInt(json['postCount'] ?? json['postsCount']),
      followedByViewer: json['followedByViewer'] == true,
      viewerRole: _trimmedStringOrNull(json['viewerRole']),
      viewerCanModerate: json['viewerCanModerate'] == true,
      viewerTrustStatus:
          _trimmedStringOrNull(
            json['viewerTrustStatus'] ??
                json['viewerCommunityStatus'] ??
                json['viewerMemberStatus'],
          ) ??
          'ACTIVE',
      viewerRestrictionId:
          _trimmedStringOrNull(json['viewerRestrictionId']) ??
          _trimmedStringOrNull(
            _stringKeyedMap(json['viewerRestriction'])['id'],
          ),
      mutedByViewer:
          json['mutedByViewer'] == true || json['viewerMuted'] == true,
      rules: _parseStringList(json['rules']),
    );
  }

  PostProfileContract get postProfileContract =>
      PostProfileContract.resolve(defaultPostProfileKey);

  bool get isQuickPostCommunity => postProfileContract.isInlineThread;

  String localizedTitle(String localeCode) {
    return _localizedText(titleI18n, localeCode: localeCode, fallback: title);
  }

  String localizedDescription(String localeCode) {
    return _localizedText(
      descriptionI18n,
      localeCode: localeCode,
      fallback: description ?? subtitle ?? '',
    );
  }

  List<String> get postProfileKeys {
    final keys = _normalizePostProfileKeys(
      allowedPostProfileKeys,
      fallback: defaultPostProfileKey,
    );
    if (keys.isEmpty) {
      return const [PostProfileKeys.article];
    }
    return keys;
  }

  FeedCommunityVm copyWith({
    String? id,
    String? title,
    Map<String, String>? titleI18n,
    Object? subtitle = _sentinel,
    Object? description = _sentinel,
    Map<String, String>? descriptionI18n,
    Object? topic = _sentinel,
    Object? avatarFileId = _sentinel,
    Object? coverFileId = _sentinel,
    String? visibility,
    String? postingPolicy,
    String? status,
    String? defaultPostProfileKey,
    List<String>? allowedPostProfileKeys,
    List<String>? enabledTabs,
    Object? languageCode = _sentinel,
    Object? countryCode = _sentinel,
    Object? cityId = _sentinel,
    Object? cityName = _sentinel,
    int? membersCount,
    int? postCount,
    bool? followedByViewer,
    Object? viewerRole = _sentinel,
    bool? viewerCanModerate,
    String? viewerTrustStatus,
    Object? viewerRestrictionId = _sentinel,
    bool? mutedByViewer,
    List<String>? rules,
  }) {
    return FeedCommunityVm(
      id: id ?? this.id,
      title: title ?? this.title,
      titleI18n: titleI18n ?? this.titleI18n,
      subtitle: identical(subtitle, _sentinel)
          ? this.subtitle
          : subtitle as String?,
      description: identical(description, _sentinel)
          ? this.description
          : description as String?,
      descriptionI18n: descriptionI18n ?? this.descriptionI18n,
      topic: identical(topic, _sentinel) ? this.topic : topic as String?,
      avatarFileId: identical(avatarFileId, _sentinel)
          ? this.avatarFileId
          : avatarFileId as String?,
      coverFileId: identical(coverFileId, _sentinel)
          ? this.coverFileId
          : coverFileId as String?,
      visibility: visibility ?? this.visibility,
      postingPolicy: postingPolicy ?? this.postingPolicy,
      status: status ?? this.status,
      defaultPostProfileKey:
          defaultPostProfileKey ?? this.defaultPostProfileKey,
      allowedPostProfileKeys:
          allowedPostProfileKeys ?? this.allowedPostProfileKeys,
      enabledTabs: enabledTabs ?? this.enabledTabs,
      languageCode: identical(languageCode, _sentinel)
          ? this.languageCode
          : languageCode as String?,
      countryCode: identical(countryCode, _sentinel)
          ? this.countryCode
          : countryCode as String?,
      cityId: identical(cityId, _sentinel) ? this.cityId : cityId as String?,
      cityName: identical(cityName, _sentinel)
          ? this.cityName
          : cityName as String?,
      membersCount: membersCount ?? this.membersCount,
      postCount: postCount ?? this.postCount,
      followedByViewer: followedByViewer ?? this.followedByViewer,
      viewerRole: identical(viewerRole, _sentinel)
          ? this.viewerRole
          : viewerRole as String?,
      viewerCanModerate: viewerCanModerate ?? this.viewerCanModerate,
      viewerTrustStatus: viewerTrustStatus ?? this.viewerTrustStatus,
      viewerRestrictionId: identical(viewerRestrictionId, _sentinel)
          ? this.viewerRestrictionId
          : viewerRestrictionId as String?,
      mutedByViewer: mutedByViewer ?? this.mutedByViewer,
      rules: rules ?? this.rules,
    );
  }
}

class FeedSubscriptionsVm {
  FeedSubscriptionsVm({
    List<FeedCommunityVm> communities = const [],
    List<FeedPersonVm> people = const [],
  }) : communities = List<FeedCommunityVm>.unmodifiable(communities),
       people = List<FeedPersonVm>.unmodifiable(people);

  final List<FeedCommunityVm> communities;
  final List<FeedPersonVm> people;

  bool get isEmpty => communities.isEmpty && people.isEmpty;
}

enum FeedPersonRelationship {
  friend,
  following;

  static FeedPersonRelationship fromWire(Object? raw) {
    final normalized = (raw?.toString() ?? '')
        .trim()
        .replaceAll('-', '_')
        .toLowerCase();
    return switch (normalized) {
      'friend' || 'friends' || 'friendship' => FeedPersonRelationship.friend,
      _ => FeedPersonRelationship.following,
    };
  }
}

class FeedPersonVm {
  const FeedPersonVm({
    required this.userId,
    this.nickname,
    this.avatarFileId,
    this.relationship = FeedPersonRelationship.following,
    this.isOnline = false,
  });

  final String userId;
  final String? nickname;
  final String? avatarFileId;
  final FeedPersonRelationship relationship;
  final bool isOnline;

  factory FeedPersonVm.fromJson(Map<String, dynamic> json) {
    return FeedPersonVm(
      userId: _trimmedStringOrNull(json['userId'] ?? json['id']) ?? '',
      nickname: _trimmedStringOrNull(json['nickname'] ?? json['name']),
      avatarFileId: _trimmedStringOrNull(json['avatarFileId']),
      relationship: FeedPersonRelationship.fromWire(
        json['relationship'] ?? json['relation'] ?? json['type'],
      ),
      isOnline: json['isOnline'] == true,
    );
  }

  String displayName(String fallback) {
    final value = (nickname ?? '').trim();
    return value.isEmpty ? fallback : value;
  }

  String get initials {
    final source = (nickname ?? '').trim();
    if (source.isEmpty) {
      return 'U';
    }
    final parts = source
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }
}

FeedBlockType _parseFeedBlockType(Object? rawType) {
  final normalized = (rawType?.toString() ?? '')
      .trim()
      .replaceAll('-', '_')
      .toLowerCase();

  return switch (normalized) {
    'stories_tray' || 'storiestray' => FeedBlockType.storiesTray,
    'suggested_communities' ||
    'suggestedcommunities' => FeedBlockType.suggestedCommunities,
    'my_subscriptions' ||
    'mysubscriptions' ||
    'subscriptions' => FeedBlockType.mySubscriptions,
    'system_posts' ||
    'systemposts' ||
    'official_posts' ||
    'officialposts' => FeedBlockType.systemPosts,
    'post_card' || 'postcard' => FeedBlockType.postCard,
    'tour_card' || 'tourcard' => FeedBlockType.tourCard,
    'guide_card' || 'guidecard' => FeedBlockType.guideCard,
    'profile_card' || 'profilecard' => FeedBlockType.profileCard,
    'official_news_card' ||
    'officialnewscard' ||
    'official_card' ||
    'officialcard' => FeedBlockType.officialNewsCard,
    _ => FeedBlockType.unknown,
  };
}

List<StoryVm> _parseStories(Object? rawStories) {
  if (rawStories is! List) {
    return const [];
  }

  return rawStories
      .whereType<Map>()
      .map(_stringKeyedMap)
      .map(StoryVm.fromJson)
      .toList(growable: false);
}

PostVm? _parsePost(Object? rawPost) {
  if (rawPost is! Map) {
    return null;
  }

  final json = _stringKeyedMap(rawPost);
  if (json.isEmpty) {
    return null;
  }
  return PostVm.fromJson(json);
}

List<PostVm> _parsePosts(Object? rawPosts) {
  if (rawPosts is! List) {
    return const [];
  }

  return rawPosts
      .whereType<Map>()
      .map(_stringKeyedMap)
      .map(PostVm.fromJson)
      .toList(growable: false);
}

List<FeedCommunityVm> _parseCommunities(Object? rawCommunities) {
  if (rawCommunities is! List) {
    return const [];
  }

  return rawCommunities
      .whereType<Map>()
      .map(_stringKeyedMap)
      .map(FeedCommunityVm.fromJson)
      .toList(growable: false);
}

List<FeedPersonVm> _parsePeople(Object? rawPeople) {
  if (rawPeople is! List) {
    return const [];
  }

  return rawPeople
      .whereType<Map>()
      .map(_stringKeyedMap)
      .map(FeedPersonVm.fromJson)
      .where((person) => person.userId.trim().isNotEmpty)
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

String? _trimmedStringOrNull(Object? value) {
  final trimmed = (value?.toString() ?? '').trim();
  return trimmed.isEmpty ? null : trimmed;
}

List<String> _parseStringList(Object? value) {
  if (value is! Iterable) {
    return const [];
  }
  final items = value
      .map(_trimmedStringOrNull)
      .whereType<String>()
      .toList(growable: false);
  return List<String>.unmodifiable(items);
}

Map<String, String> _parseStringMap(Object? value) {
  final raw = _stringKeyedMap(value);
  if (raw.isEmpty) {
    return const {};
  }
  final result = <String, String>{};
  for (final entry in raw.entries) {
    final key = _trimmedStringOrNull(entry.key)?.toLowerCase();
    final text = _trimmedStringOrNull(entry.value);
    if (key == null || text == null) {
      continue;
    }
    result[key] = text;
  }
  return Map<String, String>.unmodifiable(result);
}

String _localizedText(
  Map<String, String> values, {
  required String localeCode,
  required String fallback,
}) {
  final normalizedLocale = localeCode.trim().toLowerCase();
  final languageCode = normalizedLocale.split(RegExp(r'[-_]')).first;
  for (final key in [normalizedLocale, languageCode, 'en', 'ru', 'kk']) {
    final value = _trimmedStringOrNull(values[key]);
    if (value != null) {
      return value;
    }
  }
  return fallback.trim();
}

List<String> _normalizePostProfileKeys(
  Iterable<String> values, {
  required String fallback,
}) {
  final result = <String>[];
  for (final raw in values) {
    final key = PostProfileContract.normalize(raw);
    if (key == null || !PostProfileKeys.supported.contains(key)) {
      continue;
    }
    if (!result.contains(key)) {
      result.add(key);
    }
  }

  if (result.isEmpty) {
    final fallbackKey = PostProfileContract.normalize(fallback);
    if (fallbackKey != null &&
        PostProfileKeys.supported.contains(fallbackKey)) {
      result.add(fallbackKey);
    }
  }
  return List<String>.unmodifiable(result);
}

int _parseInt(Object? value) {
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

const Object _sentinel = Object();
