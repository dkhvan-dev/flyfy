import 'package:dio/dio.dart';

import '../../features/stories/models/save_story_request.dart';
import '../../features/stories/models/story_vm.dart';
import 'api_client.dart';

class StoryApi {
  StoryApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<StoryListPage> listStoriesPage({
    String? search,
    List<String>? formats,
    List<String>? categories,
    String? place,
    String? countryCode,
    String? cityId,
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
        if (_normalizedCsvOrNull(formats) != null)
          'format': _normalizedCsvOrNull(formats),
        if (_normalizedCsvOrNull(categories) != null)
          'category': _normalizedCsvOrNull(categories),
        if ((place ?? '').trim().isNotEmpty) 'place': place!.trim(),
        if (_normalizeCountryCode(countryCode) != null)
          'countryCode': _normalizeCountryCode(countryCode),
        if ((cityId ?? '').trim().isNotEmpty) 'cityId': cityId!.trim(),
        if ((sort ?? '').trim().isNotEmpty) 'sort': sort!.trim(),
        if ((authorId ?? '').trim().isNotEmpty) 'authorId': authorId!.trim(),
        'limit': pageLimit,
        'offset': pageOffset,
      },
      options: Options(extra: const {'requiresAuth': false}),
    );

    return _parseStoryListPage(
      response.data,
      fallbackLimit: pageLimit,
      fallbackOffset: pageOffset,
    );
  }

  Future<List<StoryVm>> listStories({
    String? search,
    List<String>? formats,
    List<String>? categories,
    String? place,
    String? countryCode,
    String? cityId,
    String? sort,
    int limit = 20,
    int offset = 0,
    String? authorId,
  }) async {
    final page = await listStoriesPage(
      search: search,
      formats: formats,
      categories: categories,
      place: place,
      countryCode: countryCode,
      cityId: cityId,
      sort: sort,
      limit: limit,
      offset: offset,
      authorId: authorId,
    );

    return page.items;
  }

  Future<StoryListPage> getUserStoriesPage(
    String userId, {
    String? search,
    List<String>? formats,
    List<String>? categories,
    String? place,
    String? countryCode,
    String? cityId,
    String? sort,
    int limit = 20,
    int offset = 0,
  }) async {
    final trimmedUserId = userId.trim();
    if (trimmedUserId.isEmpty) {
      return const StoryListPage(items: [], hasMore: false, total: 0);
    }

    return listStoriesPage(
      search: search,
      formats: formats,
      categories: categories,
      place: place,
      countryCode: countryCode,
      cityId: cityId,
      sort: sort,
      limit: limit,
      offset: offset,
      authorId: trimmedUserId,
    );
  }

  Future<List<StoryVm>> getUserPopularStories(
    String userId, {
    int limit = 3,
  }) async {
    final page = await getUserStoriesPage(
      userId,
      sort: 'popular_desc',
      limit: limit,
      offset: 0,
    );

    return page.items;
  }

  Future<StoryListPage> listMyStoriesPage({
    String? search,
    List<String>? formats,
    List<String>? categories,
    String? place,
    String? countryCode,
    String? cityId,
    String? sort,
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    final pageLimit = limit < 1 ? 1 : limit;
    final pageOffset = offset < 0 ? 0 : offset;
    final response = await _apiClient.dio.get(
      '/stories/mine',
      queryParameters: {
        if ((search ?? '').trim().isNotEmpty) 'search': search!.trim(),
        if (_normalizedCsvOrNull(formats) != null)
          'format': _normalizedCsvOrNull(formats),
        if (_normalizedCsvOrNull(categories) != null)
          'category': _normalizedCsvOrNull(categories),
        if ((place ?? '').trim().isNotEmpty) 'place': place!.trim(),
        if (_normalizeCountryCode(countryCode) != null)
          'countryCode': _normalizeCountryCode(countryCode),
        if ((cityId ?? '').trim().isNotEmpty) 'cityId': cityId!.trim(),
        if ((sort ?? '').trim().isNotEmpty) 'sort': sort!.trim(),
        if ((status ?? '').trim().isNotEmpty)
          'status': status!.trim().toUpperCase(),
        'limit': pageLimit,
        'offset': pageOffset,
      },
    );

    return _parseStoryListPage(
      response.data,
      fallbackLimit: pageLimit,
      fallbackOffset: pageOffset,
    );
  }

  Future<List<StoryVm>> listMyStories({
    String? search,
    List<String>? formats,
    List<String>? categories,
    String? place,
    String? countryCode,
    String? cityId,
    String? sort,
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    final page = await listMyStoriesPage(
      search: search,
      formats: formats,
      categories: categories,
      place: place,
      countryCode: countryCode,
      cityId: cityId,
      sort: sort,
      status: status,
      limit: limit,
      offset: offset,
    );

    return page.items;
  }

  Future<StoryDetailVm> getPublicStoryBySlug(String slug) async {
    final response = await _apiClient.dio.get(
      '/public/stories/${Uri.encodeComponent(slug)}',
      options: Options(extra: const {'requiresAuth': false}),
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
      options: Options(extra: const {'requiresAuth': false}),
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
    final response = await _apiClient.dio.post(
      '/stories/$storyId/share',
      options: Options(extra: const {'requiresAuth': false}),
    );
    final data = response.data as Map<String, dynamic>? ?? const {};
    return (
      data['shareUrl']?.toString() ?? '',
      int.tryParse(data['shares']?.toString() ?? '') ?? 0,
    );
  }

  Future<int> countPublishedStoriesForUser(String userId) async {
    final trimmedUserId = userId.trim();
    if (trimmedUserId.isEmpty) {
      return 0;
    }

    final encodedUserId = Uri.encodeComponent(trimmedUserId);
    final response = await _apiClient.dio.get(
      '/stories/users/$encodedUserId/published-count',
      options: Options(extra: const {'requiresAuth': false}),
    );
    final data = response.data as Map<String, dynamic>? ?? const {};
    return int.tryParse(data['publishedStories']?.toString() ?? '') ?? 0;
  }
}

class StoryListPage {
  const StoryListPage({
    required this.items,
    required this.hasMore,
    required this.total,
    this.limit = 0,
    this.offset = 0,
  });

  final List<StoryVm> items;
  final bool hasMore;
  final int total;
  final int limit;
  final int offset;
}

StoryListPage _parseStoryListPage(
  Object? responseData, {
  required int fallbackLimit,
  required int fallbackOffset,
}) {
  final data = responseData as Map<String, dynamic>? ?? const {};
  final rawItems = data['items'];
  if (rawItems is! List) {
    return StoryListPage(
      items: const [],
      hasMore: false,
      total: 0,
      limit: _parseInt(data['limit']) ?? fallbackLimit,
      offset: _parseInt(data['offset']) ?? fallbackOffset,
    );
  }

  final parsedItems = rawItems
      .whereType<Map<String, dynamic>>()
      .map(StoryVm.fromJson)
      .toList(growable: false);
  final hasExtraLegacyItem = parsedItems.length > fallbackLimit;
  final items = hasExtraLegacyItem
      ? parsedItems.take(fallbackLimit).toList(growable: false)
      : parsedItems;
  final limit = _parseInt(data['limit']) ?? fallbackLimit;
  final offset = _parseInt(data['offset']) ?? fallbackOffset;
  final total = _parseInt(data['total']) ?? offset + items.length;
  final hasMore =
      data['hasMore'] == true ||
      hasExtraLegacyItem ||
      total > offset + items.length;

  return StoryListPage(
    items: items,
    hasMore: hasMore,
    total: total,
    limit: limit,
    offset: offset,
  );
}

int? _parseInt(Object? value) {
  return int.tryParse(value?.toString() ?? '');
}

String? _normalizedCsvOrNull(List<String>? values) {
  final normalized = values
      ?.map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .join(',');
  return normalized == null || normalized.isEmpty ? null : normalized;
}

String? _normalizeCountryCode(String? value) {
  final normalized = value?.trim().toUpperCase() ?? '';
  return normalized.isEmpty ? null : normalized;
}
