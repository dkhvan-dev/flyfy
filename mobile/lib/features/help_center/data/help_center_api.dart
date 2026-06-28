import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/help_center_models.dart';

export '../models/help_center_models.dart';

class HelpCenterApi {
  HelpCenterApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<HelpArticleVm>> contextualArticles({
    required String locale,
    required HelpCenterSurface surface,
    Iterable<String> tags = const [],
    String? userState,
    String? paymentStatus,
    int? limit,
  }) async {
    final page = await contextualArticlePage(
      locale: locale,
      surface: surface,
      tags: tags,
      userState: userState,
      paymentStatus: paymentStatus,
      limit: limit,
    );
    return page.items;
  }

  Future<HelpArticlePageVm> contextualArticlePage({
    required String locale,
    required HelpCenterSurface surface,
    Iterable<String> tags = const [],
    String? categoryId,
    String? userState,
    String? paymentStatus,
    int? limit,
    int? offset,
  }) async {
    final cleanTags = _cleanList(tags);
    final cleanCategoryId = categoryId?.trim();
    final response = await _apiClient.dio.get(
      '/help/articles/contextual',
      queryParameters: {
        'locale': _normalizeLocale(locale),
        'surface': surface.wireValue,
        if (cleanCategoryId != null && cleanCategoryId.isNotEmpty)
          'categoryId': cleanCategoryId,
        if (cleanTags.isNotEmpty) 'tags': cleanTags.join(','),
        if (_hasText(userState)) 'userState': userState!.trim(),
        if (_hasText(paymentStatus)) 'paymentStatus': paymentStatus!.trim(),
        if (limit != null && limit > 0) 'limit': limit,
        if (offset != null && offset >= 0) 'offset': offset,
      },
      options: Options(extra: const {'requiresAuth': false}),
    );

    return _parseArticlePage(response.data);
  }

  Future<List<HelpCategoryVm>> helpCategories({
    required String locale,
    required HelpCenterSurface surface,
  }) async {
    final response = await _apiClient.dio.get(
      '/help/categories',
      queryParameters: {
        'locale': _normalizeLocale(locale),
        'surface': surface.wireValue,
      },
      options: Options(extra: const {'requiresAuth': false}),
    );

    final data = response.data;
    final items = data is Map<String, dynamic>
        ? data['items'] as List<dynamic>? ?? const []
        : const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(HelpCategoryVm.fromJson)
        .where((category) => category.id.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<List<HelpArticleVm>> searchArticles({
    required String locale,
    required String query,
    HelpCenterSurface? surface,
    int? limit,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return const [];

    final response = await _apiClient.dio.get(
      '/help/articles/search',
      queryParameters: {
        'locale': _normalizeLocale(locale),
        'q': cleanQuery,
        if (surface != null) 'surface': surface.wireValue,
        if (limit != null && limit > 0) 'limit': limit,
      },
      options: Options(extra: const {'requiresAuth': false}),
    );

    return _parseArticles(response.data);
  }

  Future<void> submitArticleFeedback({
    required String articleId,
    required String locale,
    required bool helpful,
    String? reason,
    bool escalatedToSupport = false,
  }) async {
    await _apiClient.dio.put(
      '/help/articles/${Uri.encodeComponent(articleId.trim())}/feedback',
      data: {
        'locale': _normalizeLocale(locale),
        'helpful': helpful,
        'reason': reason?.trim() ?? '',
        'escalatedToSupport': escalatedToSupport,
      },
      options: Options(extra: const {'requiresAuth': true}),
    );
  }

  Future<SupportTicketVm> createSupportTicket({
    required SupportTicketCategory category,
    required String source,
    required String locale,
    Map<String, String> context = const {},
    String? idempotencyKey,
  }) async {
    final cleanIdempotencyKey = idempotencyKey?.trim();
    final response = await _apiClient.dio.post(
      '/support/tickets',
      data: {
        'category': category.wireValue,
        'source': source.trim(),
        'locale': _normalizeLocale(locale),
        'context': sanitizeSupportContext(context),
      },
      options: Options(
        extra: const {'requiresAuth': true},
        headers: {
          if (cleanIdempotencyKey != null && cleanIdempotencyKey.isNotEmpty)
            'Idempotency-Key': cleanIdempotencyKey,
        },
      ),
    );

    final data = response.data;
    return _parseSupportTicket(data);
  }

  Future<List<SupportTicketVm>> listSupportTickets({
    String? status,
    int? limit,
    int? offset,
  }) async {
    final cleanStatus = status?.trim();
    final response = await _apiClient.dio.get(
      '/support/tickets',
      queryParameters: {
        if (cleanStatus != null && cleanStatus.isNotEmpty)
          'status': cleanStatus,
        if (limit != null && limit > 0) 'limit': limit,
        if (offset != null && offset >= 0) 'offset': offset,
      },
      options: Options(extra: const {'requiresAuth': true}),
    );

    final data = response.data;
    final items = data is Map<String, dynamic>
        ? data['items'] as List<dynamic>? ?? const []
        : const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(SupportTicketVm.fromJson)
        .where((ticket) => ticket.id.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<SupportTicketDetailVm> getSupportTicket(String ticketId) async {
    final cleanTicketId = ticketId.trim();
    final response = await _apiClient.dio.get(
      '/support/tickets/${Uri.encodeComponent(cleanTicketId)}',
      options: Options(extra: const {'requiresAuth': true}),
    );

    return _parseSupportTicketDetail(response.data);
  }

  Future<SupportTicketDetailVm> getSupportConversation({
    required String locale,
  }) async {
    final response = await _apiClient.dio.get(
      '/support/conversation',
      queryParameters: {'locale': _normalizeLocale(locale)},
      options: Options(extra: const {'requiresAuth': true}),
    );

    return _parseSupportTicketDetail(response.data);
  }

  Future<SupportTicketVm> replyToSupportTicket({
    required String ticketId,
    required String message,
    String? actorNickname,
    List<String> fileIds = const [],
    String? idempotencyKey,
  }) async {
    final cleanTicketId = ticketId.trim();
    final cleanMessage = message.trim();
    final cleanActorNickname = actorNickname?.trim();
    final cleanIdempotencyKey = idempotencyKey?.trim();
    final cleanFileIds = _cleanList(fileIds);
    final response = await _apiClient.dio.post(
      '/support/tickets/${Uri.encodeComponent(cleanTicketId)}/reply',
      data: {
        'message': cleanMessage,
        if (cleanFileIds.isNotEmpty) 'fileIds': cleanFileIds,
        if (cleanActorNickname != null && cleanActorNickname.isNotEmpty)
          'actorNickname': cleanActorNickname,
      },
      options: Options(
        extra: const {'requiresAuth': true},
        headers: {
          if (cleanIdempotencyKey != null && cleanIdempotencyKey.isNotEmpty)
            'Idempotency-Key': cleanIdempotencyKey,
        },
      ),
    );

    return _parseSupportTicket(response.data);
  }

  Future<SupportTicketVm> closeSupportTicket({
    required String ticketId,
    String? reason,
  }) async {
    final cleanTicketId = ticketId.trim();
    final response = await _apiClient.dio.post(
      '/support/tickets/${Uri.encodeComponent(cleanTicketId)}/close',
      data: {'reason': reason?.trim() ?? ''},
      options: Options(extra: const {'requiresAuth': true}),
    );

    return _parseSupportTicket(response.data);
  }

  Future<void> submitSupportTicketCSAT({
    required String ticketId,
    required int rating,
    String? comment,
  }) async {
    final cleanTicketId = ticketId.trim();
    await _apiClient.dio.post(
      '/support/tickets/${Uri.encodeComponent(cleanTicketId)}/csat',
      data: {'rating': rating, 'comment': comment?.trim() ?? ''},
      options: Options(extra: const {'requiresAuth': true}),
    );
  }

  static Map<String, String> sanitizeSupportContext(
    Map<String, String> context,
  ) {
    final safe = <String, String>{};
    for (final entry in context.entries) {
      final key = entry.key.trim().toLowerCase();
      if (!_safeContextKeys.contains(key)) continue;

      final value = entry.value.trim();
      if (value.isEmpty) continue;
      safe[key] = value.length > _maxContextValueLength
          ? value.substring(0, _maxContextValueLength)
          : value;
    }
    return safe;
  }

  static String supportTicketIdempotencyKey({
    required String source,
    required Map<String, String> context,
    String? intent,
  }) {
    final safeContext = sanitizeSupportContext(context);
    final cleanIntent = intent?.trim();
    final parts = <String>[
      'support-ticket',
      source.trim(),
      if (cleanIntent != null && cleanIntent.isNotEmpty) cleanIntent,
    ];
    for (final key in safeContext.keys.toList()..sort()) {
      parts.add('$key=${safeContext[key]}');
    }
    final key = parts.where((part) => part.trim().isNotEmpty).join('|');
    return key.length > 180 ? key.substring(0, 180) : key;
  }

  List<HelpArticleVm> _parseArticles(Object? data) {
    return _parseArticlePage(data).items;
  }

  HelpArticlePageVm _parseArticlePage(Object? data) {
    if (data is Map<String, dynamic>) {
      return HelpArticlePageVm.fromJson(data);
    }
    return const HelpArticlePageVm(
      items: [],
      total: 0,
      limit: 0,
      offset: 0,
      hasMore: false,
    );
  }

  SupportTicketVm _parseSupportTicket(Object? data) {
    final root = data is Map<String, dynamic>
        ? data
        : const <String, dynamic>{};
    final ticket = root['ticket'];
    return SupportTicketVm.fromJson(
      ticket is Map<String, dynamic> ? ticket : root,
    );
  }

  SupportTicketDetailVm _parseSupportTicketDetail(Object? data) {
    final root = data is Map<String, dynamic>
        ? data
        : const <String, dynamic>{};
    final ticket = root['ticket'];
    final events = root['events'] as List<dynamic>? ?? const [];
    return SupportTicketDetailVm(
      ticket: SupportTicketVm.fromJson(
        ticket is Map<String, dynamic> ? ticket : const <String, dynamic>{},
      ),
      events: events
          .whereType<Map<String, dynamic>>()
          .map(SupportTicketEventVm.fromJson)
          .toList(growable: false),
    );
  }

  List<String> _cleanList(Iterable<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  String _normalizeLocale(String locale) {
    final normalized = locale.trim().toLowerCase().split(RegExp('[-_]')).first;
    return switch (normalized) {
      'en' || 'kk' || 'ru' => normalized,
      _ => 'ru',
    };
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  static const _safeContextKeys = {
    'activity_id',
    'amount',
    'article_id',
    'city_id',
    'city_name',
    'conversation_id',
    'converted_amount',
    'country_code',
    'currency_pair',
    'entity_id',
    'excursion_id',
    'failed_search',
    'from_currency',
    'locale',
    'payment_id',
    'place_id',
    'screen',
    'search_query',
    'sort',
    'source_route',
    'to_currency',
    'user_nickname',
  };

  static const _maxContextValueLength = 256;
}
