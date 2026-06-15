import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/feed_block_vm.dart';

class FeedApi {
  FeedApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  String? _lastRankingExperiment;

  Future<FeedPageVm> getFeed({
    String surface = 'home',
    String tab = 'for_you',
    String? cursor,
    String? countryCode,
    String? cityId,
    int limit = 20,
  }) async {
    final pageLimit = limit < 1 ? 1 : limit;
    final response = await _apiClient.dio.get(
      '/feed',
      queryParameters: {
        if (_trimmedOrNull(surface) != null) 'surface': surface.trim(),
        if (_trimmedOrNull(tab) != null) 'tab': tab.trim(),
        if (_trimmedOrNull(cursor) != null) 'cursor': cursor!.trim(),
        if (_trimmedOrNull(countryCode) != null)
          'countryCode': countryCode!.trim(),
        if (_trimmedOrNull(cityId) != null) 'cityId': cityId!.trim(),
        'limit': pageLimit,
      },
      options: Options(extra: const {'optionalAuth': true}),
    );

    final page = FeedPageVm.fromJson(
      response.data as Map<String, dynamic>? ?? const {},
    );
    _lastRankingExperiment = page.assignment.rankingExperiment;
    return page;
  }

  Future<CommunityListPageVm> listCommunities({
    String? topic,
    String? countryCode,
    String? cityId,
    String? search,
    bool excludeFollowed = false,
    bool onlyFollowed = false,
    int limit = 20,
    int offset = 0,
  }) async {
    final pageLimit = limit < 1 ? 1 : limit;
    final pageOffset = offset < 0 ? 0 : offset;
    final response = await _apiClient.dio.get(
      '/communities',
      queryParameters: {
        if (_trimmedOrNull(topic) != null) 'topic': topic!.trim(),
        if (_trimmedOrNull(countryCode) != null)
          'countryCode': countryCode!.trim(),
        if (_trimmedOrNull(cityId) != null) 'cityId': cityId!.trim(),
        if (_trimmedOrNull(search) != null) 'search': search!.trim(),
        if (onlyFollowed)
          'onlyFollowed': true
        else if (excludeFollowed)
          'excludeFollowed': true,
        'limit': pageLimit,
        'offset': pageOffset,
      },
      options: Options(
        extra: onlyFollowed
            ? const {'requiresAuth': true}
            : const {'optionalAuth': true},
      ),
    );

    return CommunityListPageVm.fromJson(
      response.data as Map<String, dynamic>? ?? const {},
    );
  }

  Future<FeedCommunityVm> getCommunity(String communityId) async {
    final normalizedCommunityId = _trimmedOrNull(communityId);
    if (normalizedCommunityId == null) {
      throw ArgumentError.value(
        communityId,
        'communityId',
        'must not be empty',
      );
    }

    final response = await _apiClient.dio.get(
      '/communities/${Uri.encodeComponent(normalizedCommunityId)}',
      options: Options(extra: const {'optionalAuth': true}),
    );

    return FeedCommunityVm.fromJson(
      response.data as Map<String, dynamic>? ?? const {},
    );
  }

  Future<FeedCommunityVm> followCommunity(String communityId) {
    return _updateCommunityFollow(communityId: communityId, follow: true);
  }

  Future<FeedCommunityVm> unfollowCommunity(String communityId) {
    return _updateCommunityFollow(communityId: communityId, follow: false);
  }

  Future<int> trackFeedEvents(List<FeedEventRequest> events) async {
    final payload = [
      for (final event in events) _eventJsonWithAssignment(event),
    ];
    if (payload.isEmpty) {
      return 0;
    }

    final response = await _apiClient.dio.post(
      '/feed/events',
      data: {'events': payload},
      options: Options(extra: const {'optionalAuth': true}),
    );
    final data = response.data as Map<String, dynamic>? ?? const {};
    final accepted = data['accepted'];
    return accepted is num ? accepted.toInt() : 0;
  }

  Map<String, Object?> _eventJsonWithAssignment(FeedEventRequest event) {
    final json = event.toJson();
    final rankingExperiment = _trimmedOrNull(_lastRankingExperiment);
    if (rankingExperiment == null) {
      return json;
    }

    final rawMetadata = json['metadata'];
    final metadata = <String, Object?>{
      if (rawMetadata is Map)
        for (final entry in rawMetadata.entries)
          entry.key.toString(): entry.value,
    };
    metadata.putIfAbsent('rankingExperiment', () => rankingExperiment);
    json['metadata'] = metadata;
    return json;
  }

  Future<FeedCommunityVm> _updateCommunityFollow({
    required String communityId,
    required bool follow,
  }) async {
    final normalizedCommunityId = _trimmedOrNull(communityId);
    if (normalizedCommunityId == null) {
      throw ArgumentError.value(
        communityId,
        'communityId',
        'must not be empty',
      );
    }

    final path =
        '/communities/${Uri.encodeComponent(normalizedCommunityId)}/follow';
    final response = follow
        ? await _apiClient.dio.post(
            path,
            options: Options(extra: const {'requiresAuth': true}),
          )
        : await _apiClient.dio.delete(
            path,
            options: Options(extra: const {'requiresAuth': true}),
          );

    return FeedCommunityVm.fromJson(
      response.data as Map<String, dynamic>? ?? const {},
    );
  }
}

class FeedEventRequest {
  const FeedEventRequest({
    required this.eventId,
    required this.eventType,
    required this.surface,
    required this.tab,
    required this.blockId,
    required this.blockType,
    this.postId,
    this.communityId,
    this.rank = 0,
    this.occurredAt,
    this.requestId,
    this.metadata = const {},
  });

  final String eventId;
  final String eventType;
  final String surface;
  final String tab;
  final String blockId;
  final String blockType;
  final String? postId;
  final String? communityId;
  final int rank;
  final DateTime? occurredAt;
  final String? requestId;
  final Map<String, Object?> metadata;

  Map<String, Object?> toJson() {
    return {
      'eventId': eventId.trim(),
      'type': eventType.trim(),
      'surface': surface.trim(),
      'tab': tab.trim(),
      'blockId': blockId.trim(),
      'blockType': blockType.trim(),
      if (_trimmedOrNull(postId) != null) 'postId': postId!.trim(),
      if (_trimmedOrNull(communityId) != null)
        'communityId': communityId!.trim(),
      'rank': rank < 0 ? 0 : rank,
      if (occurredAt != null)
        'occurredAt': occurredAt!.toUtc().toIso8601String(),
      if (_trimmedOrNull(requestId) != null) 'requestId': requestId!.trim(),
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }
}

String? _trimmedOrNull(String? value) {
  final trimmed = (value ?? '').trim();
  return trimmed.isEmpty ? null : trimmed;
}
