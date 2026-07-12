import 'package:dio/dio.dart';

import '../../features/stories/models/save_post_request.dart';
import '../../features/stories/models/post_vm.dart';
import 'api_client.dart';

class PostApi {
  PostApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<PostListPage> listPostsPage({
    String? search,
    List<String>? formats,
    List<String>? categories,
    List<String>? moderationStatuses,
    String? place,
    String? countryCode,
    String? cityId,
    String? sort,
    int limit = 20,
    int offset = 0,
    String? authorId,
    String? communityId,
  }) async {
    final pageLimit = limit < 1 ? 1 : limit;
    final pageOffset = offset < 0 ? 0 : offset;
    final response = await _apiClient.dio.get(
      '/posts',
      queryParameters: {
        if ((search ?? '').trim().isNotEmpty) 'search': search!.trim(),
        if (_normalizedCsvOrNull(formats) != null)
          'format': _normalizedCsvOrNull(formats),
        if (_normalizedCsvOrNull(categories) != null)
          'category': _normalizedCsvOrNull(categories),
        if (_normalizedCsvOrNull(moderationStatuses) != null)
          'moderationStatus': _normalizedCsvOrNull(moderationStatuses),
        if ((place ?? '').trim().isNotEmpty) 'place': place!.trim(),
        if (_normalizeCountryCode(countryCode) != null)
          'countryCode': _normalizeCountryCode(countryCode),
        if ((cityId ?? '').trim().isNotEmpty) 'cityId': cityId!.trim(),
        if ((sort ?? '').trim().isNotEmpty) 'sort': sort!.trim(),
        if ((authorId ?? '').trim().isNotEmpty) 'authorId': authorId!.trim(),
        if ((communityId ?? '').trim().isNotEmpty)
          'communityId': communityId!.trim(),
        'limit': pageLimit,
        'offset': pageOffset,
      },
      options: Options(extra: const {'optionalAuth': true}),
    );

    return _parsePostListPage(
      response.data,
      fallbackLimit: pageLimit,
      fallbackOffset: pageOffset,
    );
  }

  Future<List<PostVm>> listPosts({
    String? search,
    List<String>? formats,
    List<String>? categories,
    List<String>? moderationStatuses,
    String? place,
    String? countryCode,
    String? cityId,
    String? sort,
    int limit = 20,
    int offset = 0,
    String? authorId,
    String? communityId,
  }) async {
    final page = await listPostsPage(
      search: search,
      formats: formats,
      categories: categories,
      moderationStatuses: moderationStatuses,
      place: place,
      countryCode: countryCode,
      cityId: cityId,
      sort: sort,
      limit: limit,
      offset: offset,
      authorId: authorId,
      communityId: communityId,
    );

    return page.items;
  }

  Future<PostListPage> getUserPostsPage(
    String userId, {
    String? search,
    List<String>? formats,
    List<String>? categories,
    List<String>? moderationStatuses,
    String? place,
    String? countryCode,
    String? cityId,
    String? sort,
    int limit = 20,
    int offset = 0,
  }) async {
    final trimmedUserId = userId.trim();
    if (trimmedUserId.isEmpty) {
      return const PostListPage(items: [], hasMore: false, total: 0);
    }

    return listPostsPage(
      search: search,
      formats: formats,
      categories: categories,
      moderationStatuses: moderationStatuses,
      place: place,
      countryCode: countryCode,
      cityId: cityId,
      sort: sort,
      limit: limit,
      offset: offset,
      authorId: trimmedUserId,
    );
  }

  Future<List<PostVm>> getUserPopularPosts(
    String userId, {
    int limit = 3,
  }) async {
    final page = await getUserPostsPage(
      userId,
      sort: 'popular_desc',
      limit: limit,
      offset: 0,
    );

    return page.items;
  }

  Future<PostListPage> listMyPostsPage({
    String? search,
    List<String>? formats,
    List<String>? categories,
    List<String>? moderationStatuses,
    String? place,
    String? countryCode,
    String? cityId,
    String? sort,
    String? status,
    String? communityId,
    int limit = 20,
    int offset = 0,
  }) async {
    final pageLimit = limit < 1 ? 1 : limit;
    final pageOffset = offset < 0 ? 0 : offset;
    final response = await _apiClient.dio.get(
      '/posts/mine',
      queryParameters: {
        if ((search ?? '').trim().isNotEmpty) 'search': search!.trim(),
        if (_normalizedCsvOrNull(formats) != null)
          'format': _normalizedCsvOrNull(formats),
        if (_normalizedCsvOrNull(categories) != null)
          'category': _normalizedCsvOrNull(categories),
        if (_normalizedCsvOrNull(moderationStatuses) != null)
          'moderationStatus': _normalizedCsvOrNull(moderationStatuses),
        if ((place ?? '').trim().isNotEmpty) 'place': place!.trim(),
        if (_normalizeCountryCode(countryCode) != null)
          'countryCode': _normalizeCountryCode(countryCode),
        if ((cityId ?? '').trim().isNotEmpty) 'cityId': cityId!.trim(),
        if ((sort ?? '').trim().isNotEmpty) 'sort': sort!.trim(),
        if ((status ?? '').trim().isNotEmpty)
          'status': status!.trim().toUpperCase(),
        if ((communityId ?? '').trim().isNotEmpty)
          'communityId': communityId!.trim(),
        'limit': pageLimit,
        'offset': pageOffset,
      },
    );

    return _parsePostListPage(
      response.data,
      fallbackLimit: pageLimit,
      fallbackOffset: pageOffset,
    );
  }

  Future<List<PostVm>> listMyPosts({
    String? search,
    List<String>? formats,
    List<String>? categories,
    List<String>? moderationStatuses,
    String? place,
    String? countryCode,
    String? cityId,
    String? sort,
    String? status,
    String? communityId,
    int limit = 20,
    int offset = 0,
  }) async {
    final page = await listMyPostsPage(
      search: search,
      formats: formats,
      categories: categories,
      moderationStatuses: moderationStatuses,
      place: place,
      countryCode: countryCode,
      cityId: cityId,
      sort: sort,
      status: status,
      communityId: communityId,
      limit: limit,
      offset: offset,
    );

    return page.items;
  }

  Future<PostDetailVm> getPublicPostBySlug(String slug) async {
    final response = await _apiClient.dio.get(
      '/public/posts/${Uri.encodeComponent(slug)}',
      options: Options(extra: const {'optionalAuth': true}),
    );
    return PostDetailVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PostVm> getPostById(String postId) async {
    final response = await _apiClient.dio.get('/posts/$postId');
    return PostVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PostCreateEligibilityVm> checkCreateEligibility() async {
    final response = await _apiClient.dio.get(
      '/posts/create-eligibility',
      options: Options(extra: const {'requiresAuth': true}),
    );
    final data = response.data as Map<String, dynamic>? ?? const {};
    return PostCreateEligibilityVm.fromJson(data);
  }

  Future<PostVm> createPost(SavePostRequest request) async {
    final response = await _apiClient.dio.post(
      '/posts',
      data: request.toJson(),
    );
    return PostVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PostVm> updatePost(String postId, SavePostRequest request) async {
    final response = await _apiClient.dio.patch(
      '/posts/$postId',
      data: request.toJson(),
    );
    return PostVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePost(String postId) async {
    await _apiClient.dio.delete('/posts/$postId');
  }

  Future<DateTime?> markPostSeen(String postId) async {
    final response = await _apiClient.dio.post(
      '/posts/$postId/seen',
      options: Options(extra: const {'requiresAuth': true}),
    );
    final data = response.data as Map<String, dynamic>? ?? const {};
    return DateTime.tryParse(data['seenAt']?.toString() ?? '');
  }

  Future<int> likePost(String postId) async {
    final response = await _apiClient.dio.post('/posts/$postId/likes');
    final data = response.data as Map<String, dynamic>? ?? const {};
    return int.tryParse(data['likes']?.toString() ?? '') ?? 0;
  }

  Future<int> unlikePost(String postId) async {
    final response = await _apiClient.dio.delete('/posts/$postId/likes');
    final data = response.data as Map<String, dynamic>? ?? const {};
    return int.tryParse(data['likes']?.toString() ?? '') ?? 0;
  }

  Future<List<PostCommentVm>> listComments(
    String postId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _apiClient.dio.get(
      '/posts/$postId/comments',
      queryParameters: {'limit': limit, 'offset': offset},
      options: Options(extra: const {'optionalAuth': true}),
    );
    final data = response.data as Map<String, dynamic>? ?? const {};
    final rawItems = data['items'];
    if (rawItems is! List) {
      return const [];
    }
    return rawItems
        .whereType<Map<String, dynamic>>()
        .map(PostCommentVm.fromJson)
        .toList(growable: false);
  }

  Future<PostCommentVm> createComment(String postId, String body) async {
    final response = await _apiClient.dio.post(
      '/posts/$postId/comments',
      data: {'body': body.trim()},
    );
    return PostCommentVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PostCommentVm> updateComment(
    String postId,
    String commentId,
    String body,
  ) async {
    final response = await _apiClient.dio.patch(
      '/posts/$postId/comments/$commentId',
      data: {'body': body.trim()},
    );
    return PostCommentVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _apiClient.dio.delete('/posts/$postId/comments/$commentId');
  }

  Future<(int likes, bool likedByMe)> likeComment(
    String postId,
    String commentId,
  ) async {
    final response = await _apiClient.dio.post(
      '/posts/$postId/comments/$commentId/likes',
    );
    final data = response.data as Map<String, dynamic>? ?? const {};
    return (
      int.tryParse(data['likes']?.toString() ?? '') ?? 0,
      data['likedByMe'] == true,
    );
  }

  Future<(int likes, bool likedByMe)> unlikeComment(
    String postId,
    String commentId,
  ) async {
    final response = await _apiClient.dio.delete(
      '/posts/$postId/comments/$commentId/likes',
    );
    final data = response.data as Map<String, dynamic>? ?? const {};
    return (
      int.tryParse(data['likes']?.toString() ?? '') ?? 0,
      data['likedByMe'] == true,
    );
  }

  Future<(String shareUrl, int shares)> sharePost(String postId) async {
    final response = await _apiClient.dio.post(
      '/posts/$postId/share',
      options: Options(extra: const {'requiresAuth': false}),
    );
    final data = response.data as Map<String, dynamic>? ?? const {};
    return (
      data['shareUrl']?.toString() ?? '',
      int.tryParse(data['shares']?.toString() ?? '') ?? 0,
    );
  }

  Future<PostReportSubmissionVm> reportPost(
    String postId, {
    required String reason,
    String details = '',
  }) async {
    final response = await _apiClient.dio.post(
      '/posts/$postId/report',
      data: {'reason': reason.trim().toUpperCase(), 'details': details.trim()},
      options: Options(extra: const {'requiresAuth': true}),
    );
    return PostReportSubmissionVm.fromJson(
      response.data as Map<String, dynamic>? ?? const {},
    );
  }

  Future<int> countPublishedPostsForUser(String userId) async {
    final trimmedUserId = userId.trim();
    if (trimmedUserId.isEmpty) {
      return 0;
    }

    final encodedUserId = Uri.encodeComponent(trimmedUserId);
    final response = await _apiClient.dio.get(
      '/posts/users/$encodedUserId/published-count',
      options: Options(extra: const {'requiresAuth': false}),
    );
    final data = response.data as Map<String, dynamic>? ?? const {};
    return int.tryParse(data['publishedPosts']?.toString() ?? '') ?? 0;
  }
}

class PostListPage {
  const PostListPage({
    required this.items,
    required this.hasMore,
    required this.total,
    this.limit = 0,
    this.offset = 0,
  });

  final List<PostVm> items;
  final bool hasMore;
  final int total;
  final int limit;
  final int offset;
}

class PostCreateEligibilityVm {
  const PostCreateEligibilityVm({
    required this.canCreate,
    required this.limit,
    required this.remaining,
    required this.window,
    required this.retryAfter,
    this.cooldown = Duration.zero,
    this.blockReason,
    this.nextAvailableAt,
  });

  factory PostCreateEligibilityVm.fromJson(Map<String, dynamic> json) {
    return PostCreateEligibilityVm(
      canCreate: json['canCreate'] == true,
      limit: _parseInt(json['limit']) ?? 0,
      remaining: _parseInt(json['remaining']) ?? 0,
      window: Duration(seconds: _parseInt(json['windowSeconds']) ?? 0),
      cooldown: Duration(seconds: _parseInt(json['cooldownSeconds']) ?? 0),
      blockReason: _normalizeNullableString(json['blockReason']),
      retryAfter: Duration(seconds: _parseInt(json['retryAfterSeconds']) ?? 0),
      nextAvailableAt: DateTime.tryParse(
        json['nextAvailableAt']?.toString() ?? '',
      ),
    );
  }

  final bool canCreate;
  final int limit;
  final int remaining;
  final Duration window;
  final Duration cooldown;
  final String? blockReason;
  final Duration retryAfter;
  final DateTime? nextAvailableAt;
}

PostListPage _parsePostListPage(
  Object? responseData, {
  required int fallbackLimit,
  required int fallbackOffset,
}) {
  final data = responseData as Map<String, dynamic>? ?? const {};
  final rawItems = data['items'];
  if (rawItems is! List) {
    return PostListPage(
      items: const [],
      hasMore: false,
      total: 0,
      limit: _parseInt(data['limit']) ?? fallbackLimit,
      offset: _parseInt(data['offset']) ?? fallbackOffset,
    );
  }

  final parsedItems = rawItems
      .whereType<Map<String, dynamic>>()
      .map(PostVm.fromJson)
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

  return PostListPage(
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

String? _normalizeNullableString(Object? value) {
  final normalized = value?.toString().trim() ?? '';
  return normalized.isEmpty ? null : normalized;
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
