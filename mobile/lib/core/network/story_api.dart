import '../../features/stories/models/save_story_request.dart';
import '../../features/stories/models/story_vm.dart';
import 'api_client.dart';

class StoryApi {
  StoryApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<StoryListPage> listStoriesPage({
    String? search,
    List<String>? categories,
    String? place,
    String? sort,
    int limit = 20,
    int offset = 0,
    String? authorId,
  }) async {
    final pageLimit = limit < 1 ? 1 : limit;
    final pageOffset = offset < 0 ? 0 : offset;
    final response = await _apiClient.dio.get(
      '/stories',
      queryParameters: {
        if ((search ?? '').trim().isNotEmpty) 'search': search!.trim(),
        if (categories != null && categories.isNotEmpty)
          'category': categories.join(','),
        if ((place ?? '').trim().isNotEmpty) 'place': place!.trim(),
        if ((sort ?? '').trim().isNotEmpty) 'sort': sort!.trim(),
        if ((authorId ?? '').trim().isNotEmpty) 'authorId': authorId!.trim(),
        'limit': pageLimit + 1,
        'offset': pageOffset,
      },
    );

    final data = response.data as Map<String, dynamic>? ?? const {};
    final rawItems = data['items'];
    if (rawItems is! List) {
      return const StoryListPage(items: [], hasMore: false);
    }
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(StoryVm.fromJson)
        .toList(growable: false);
    final hasMore = items.length > pageLimit;

    return StoryListPage(
      items: hasMore ? items.take(pageLimit).toList(growable: false) : items,
      hasMore: hasMore,
    );
  }

  Future<List<StoryVm>> listStories({
    String? search,
    List<String>? categories,
    String? place,
    String? sort,
    int limit = 20,
    int offset = 0,
    String? authorId,
  }) async {
    final page = await listStoriesPage(
      search: search,
      categories: categories,
      place: place,
      sort: sort,
      limit: limit,
      offset: offset,
      authorId: authorId,
    );

    return page.items;
  }

  Future<StoryListPage> listMyStoriesPage({
    String? search,
    List<String>? categories,
    String? place,
    String? sort,
    int limit = 20,
    int offset = 0,
  }) async {
    final pageLimit = limit < 1 ? 1 : limit;
    final pageOffset = offset < 0 ? 0 : offset;
    final response = await _apiClient.dio.get(
      '/stories/mine',
      queryParameters: {
        if ((search ?? '').trim().isNotEmpty) 'search': search!.trim(),
        if (categories != null && categories.isNotEmpty)
          'category': categories.join(','),
        if ((place ?? '').trim().isNotEmpty) 'place': place!.trim(),
        if ((sort ?? '').trim().isNotEmpty) 'sort': sort!.trim(),
        'limit': pageLimit + 1,
        'offset': pageOffset,
      },
    );

    final data = response.data as Map<String, dynamic>? ?? const {};
    final rawItems = data['items'];
    if (rawItems is! List) {
      return const StoryListPage(items: [], hasMore: false);
    }
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(StoryVm.fromJson)
        .toList(growable: false);
    final hasMore = items.length > pageLimit;

    return StoryListPage(
      items: hasMore ? items.take(pageLimit).toList(growable: false) : items,
      hasMore: hasMore,
    );
  }

  Future<List<StoryVm>> listMyStories({
    String? search,
    List<String>? categories,
    String? place,
    String? sort,
    int limit = 20,
    int offset = 0,
  }) async {
    final page = await listMyStoriesPage(
      search: search,
      categories: categories,
      place: place,
      sort: sort,
      limit: limit,
      offset: offset,
    );

    return page.items;
  }

  Future<StoryDetailVm> getPublicStoryBySlug(String slug) async {
    final response = await _apiClient.dio.get(
      '/public/stories/${Uri.encodeComponent(slug)}',
    );
    return StoryDetailVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StoryVm> getStoryById(String storyId) async {
    final response = await _apiClient.dio.get('/stories/$storyId');
    return StoryVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StoryVm> createStory(SaveStoryRequest request) async {
    final response = await _apiClient.dio.post(
      '/stories',
      data: request.toJson(),
    );
    return StoryVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StoryVm> updateStory(String storyId, SaveStoryRequest request) async {
    final response = await _apiClient.dio.patch(
      '/stories/$storyId',
      data: request.toJson(),
    );
    return StoryVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteStory(String storyId) async {
    await _apiClient.dio.delete('/stories/$storyId');
  }

  Future<int> trackView(String storyId) async {
    final response = await _apiClient.dio.post('/stories/$storyId/views');
    final data = response.data as Map<String, dynamic>? ?? const {};
    return int.tryParse(data['views']?.toString() ?? '') ?? 0;
  }

  Future<int> likeStory(String storyId) async {
    final response = await _apiClient.dio.post('/stories/$storyId/likes');
    final data = response.data as Map<String, dynamic>? ?? const {};
    return int.tryParse(data['likes']?.toString() ?? '') ?? 0;
  }

  Future<int> unlikeStory(String storyId) async {
    final response = await _apiClient.dio.delete('/stories/$storyId/likes');
    final data = response.data as Map<String, dynamic>? ?? const {};
    return int.tryParse(data['likes']?.toString() ?? '') ?? 0;
  }

  Future<List<StoryCommentVm>> listComments(
    String storyId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _apiClient.dio.get(
      '/stories/$storyId/comments',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final data = response.data as Map<String, dynamic>? ?? const {};
    final rawItems = data['items'];
    if (rawItems is! List) {
      return const [];
    }
    return rawItems
        .whereType<Map<String, dynamic>>()
        .map(StoryCommentVm.fromJson)
        .toList(growable: false);
  }

  Future<StoryCommentVm> createComment(String storyId, String body) async {
    final response = await _apiClient.dio.post(
      '/stories/$storyId/comments',
      data: {'body': body.trim()},
    );
    return StoryCommentVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StoryCommentVm> updateComment(
    String storyId,
    String commentId,
    String body,
  ) async {
    final response = await _apiClient.dio.patch(
      '/stories/$storyId/comments/$commentId',
      data: {'body': body.trim()},
    );
    return StoryCommentVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteComment(String storyId, String commentId) async {
    await _apiClient.dio.delete('/stories/$storyId/comments/$commentId');
  }

  Future<(int likes, bool likedByMe)> likeComment(
    String storyId,
    String commentId,
  ) async {
    final response = await _apiClient.dio.post(
      '/stories/$storyId/comments/$commentId/likes',
    );
    final data = response.data as Map<String, dynamic>? ?? const {};
    return (
      int.tryParse(data['likes']?.toString() ?? '') ?? 0,
      data['likedByMe'] == true,
    );
  }

  Future<(int likes, bool likedByMe)> unlikeComment(
    String storyId,
    String commentId,
  ) async {
    final response = await _apiClient.dio.delete(
      '/stories/$storyId/comments/$commentId/likes',
    );
    final data = response.data as Map<String, dynamic>? ?? const {};
    return (
      int.tryParse(data['likes']?.toString() ?? '') ?? 0,
      data['likedByMe'] == true,
    );
  }

  Future<(String shareUrl, int shares)> shareStory(String storyId) async {
    final response = await _apiClient.dio.post('/stories/$storyId/share');
    final data = response.data as Map<String, dynamic>? ?? const {};
    return (
      data['shareUrl']?.toString() ?? '',
      int.tryParse(data['shares']?.toString() ?? '') ?? 0,
    );
  }
}

class StoryListPage {
  const StoryListPage({required this.items, required this.hasMore});

  final List<StoryVm> items;
  final bool hasMore;
}
