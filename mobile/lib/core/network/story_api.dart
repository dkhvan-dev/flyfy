import 'package:dio/dio.dart';

import '../../features/stories/models/story_vm.dart';
import 'api_client.dart';

enum StoryMediaType {
  image('IMAGE'),
  video('VIDEO');

  const StoryMediaType(this.wireValue);

  final String wireValue;
}

class CreateStoryRequest {
  const CreateStoryRequest({
    required this.caption,
    required this.mediaFileId,
    required this.coverFileId,
    required this.mediaType,
    this.expiresAt,
  });

  final String caption;
  final String mediaFileId;
  final String coverFileId;
  final StoryMediaType mediaType;
  final DateTime? expiresAt;

  Map<String, dynamic> toJson() {
    return {
      'caption': caption.trim(),
      'mediaFileId': mediaFileId.trim(),
      'coverFileId': coverFileId.trim(),
      'mediaType': mediaType.wireValue,
      if (expiresAt != null) 'expiresAt': expiresAt!.toUtc().toIso8601String(),
    };
  }
}

class StoryListPage {
  const StoryListPage({
    required this.items,
    required this.limit,
    required this.offset,
    required this.hasMore,
  });

  final List<StoryVm> items;
  final int limit;
  final int offset;
  final bool hasMore;

  factory StoryListPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return StoryListPage(
      items: rawItems is List
          ? rawItems
                .whereType<Map<String, dynamic>>()
                .map(StoryVm.fromJson)
                .toList(growable: false)
          : const [],
      limit: int.tryParse(json['limit']?.toString() ?? '') ?? 20,
      offset: int.tryParse(json['offset']?.toString() ?? '') ?? 0,
      hasMore: json['hasMore'] == true,
    );
  }
}

class StoryApi {
  StoryApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<StoryVm> createStory(CreateStoryRequest request) async {
    final response = await _apiClient.dio.post(
      '/stories',
      data: request.toJson(),
      options: Options(extra: const {'requiresAuth': true}),
    );
    return StoryVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DateTime?> markStorySeen(String circleId) async {
    final response = await _apiClient.dio.post(
      '/stories/$circleId/seen',
      options: Options(extra: const {'requiresAuth': true}),
    );
    final data = response.data as Map<String, dynamic>? ?? const {};
    return DateTime.tryParse(data['seenAt']?.toString() ?? '');
  }

  Future<StoryListPage> listMyArchivedStories({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _apiClient.dio.get(
      '/stories/mine/archive',
      queryParameters: {'limit': limit, 'offset': offset},
      options: Options(extra: const {'requiresAuth': true}),
    );
    return StoryListPage.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StoryListPage> listMyActiveStories({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _apiClient.dio.get(
      '/stories/mine/active',
      queryParameters: {'limit': limit, 'offset': offset},
      options: Options(extra: const {'requiresAuth': true}),
    );
    return StoryListPage.fromJson(response.data as Map<String, dynamic>);
  }

  Future<int> likeStory(String storyId) async {
    final response = await _apiClient.dio.post(
      '/stories/${Uri.encodeComponent(storyId.trim())}/likes',
      options: Options(extra: const {'requiresAuth': true}),
    );
    final data = response.data as Map<String, dynamic>? ?? const {};
    return int.tryParse(data['likes']?.toString() ?? '') ?? 0;
  }
}
