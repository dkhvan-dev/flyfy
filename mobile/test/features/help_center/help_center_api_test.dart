import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/api_client.dart';
import 'package:inflap/core/storage/secure_storage.dart';
import 'package:inflap/features/help_center/data/help_center_api.dart';

void main() {
  test('contextualArticles sends a public localized context request', () async {
    final adapter = _HelpCenterAdapter(_contextualArticlesResponse);
    final api = HelpCenterApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final articles = await api.contextualArticles(
      locale: 'ru',
      surface: HelpCenterSurface.activityDetails,
      tags: const ['activities', 'refunds'],
      userState: 'paid',
    );

    expect(adapter.requestPath, '/api/v1/help/articles/contextual');
    expect(adapter.queryParameters, {
      'locale': 'ru',
      'surface': 'activity_details',
      'tags': 'activities,refunds',
      'userState': 'paid',
    });
    expect(adapter.requiresAuth, isFalse);
    expect(articles.single.id, 'activity-cancel-paid');
    expect(articles.single.actions.single.type, HelpArticleActionType.openChat);
  });

  test('contextualArticlePage sends category pagination request', () async {
    final adapter = _HelpCenterAdapter({
      'items': [
        {
          'id': 'tourist-faq-002',
          'slug': 'tourist-faq-002',
          'title': 'Passport validity',
          'shortAnswer': 'Check validity.',
          'body': 'Check destination rules.',
          'tags': ['documents', 'popular'],
          'updatedAt': '2026-06-20T10:00:00Z',
        },
      ],
      'total': 18,
      'limit': 10,
      'offset': 10,
      'hasMore': false,
    });
    final api = HelpCenterApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final page = await api.contextualArticlePage(
      locale: 'ru',
      surface: HelpCenterSurface.helpCenter,
      categoryId: 'documents_visas_entry',
      limit: 10,
      offset: 10,
    );

    expect(adapter.requestPath, '/api/v1/help/articles/contextual');
    expect(adapter.queryParameters, {
      'locale': 'ru',
      'surface': 'help_center',
      'categoryId': 'documents_visas_entry',
      'limit': '10',
      'offset': '10',
    });
    expect(adapter.requiresAuth, isFalse);
    expect(page.items.single.id, 'tourist-faq-002');
    expect(page.total, 18);
    expect(page.hasMore, isFalse);
  });

  test('helpCategories loads public database categories', () async {
    final adapter = _HelpCenterAdapter({
      'items': [
        {
          'id': 'documents_visas_entry',
          'slug': 'documents-visas-entry',
          'title': 'Документы и въезд',
          'sortOrder': 10,
          'articleCount': 18,
        },
        {
          'id': 'booking_accommodation',
          'slug': 'booking-accommodation',
          'title': 'Проживание',
          'sortOrder': 30,
          'articleCount': 10,
        },
      ],
    });
    final api = HelpCenterApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final categories = await api.helpCategories(
      locale: 'ru',
      surface: HelpCenterSurface.helpCenter,
    );

    expect(adapter.requestPath, '/api/v1/help/categories');
    expect(adapter.queryParameters, {'locale': 'ru', 'surface': 'help_center'});
    expect(adapter.requiresAuth, isFalse);
    expect(categories.map((item) => item.id), [
      'documents_visas_entry',
      'booking_accommodation',
    ]);
    expect(categories.first.title, 'Документы и въезд');
    expect(categories.first.articleCount, 18);
  });

  test('searchArticles sends public query and parses ranked results', () async {
    final adapter = _HelpCenterAdapter(_searchArticlesResponse);
    final api = HelpCenterApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final articles = await api.searchArticles(
      locale: 'ru',
      query: ' возврат ',
      surface: HelpCenterSurface.helpCenter,
    );

    expect(adapter.requestPath, '/api/v1/help/articles/search');
    expect(adapter.queryParameters, {
      'locale': 'ru',
      'q': 'возврат',
      'surface': 'help_center',
    });
    expect(adapter.requiresAuth, isFalse);
    expect(articles.single.id, 'refund-timing');
  });

  test(
    'submitArticleFeedback requires auth and does not send userId',
    () async {
      final adapter = _HelpCenterAdapter({'status': 'accepted'});
      final api = HelpCenterApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(accessToken: 'access-token'),
        ),
      );

      await api.submitArticleFeedback(
        articleId: 'activity-cancel-paid',
        locale: 'ru',
        helpful: false,
        reason: 'Need a human',
        escalatedToSupport: true,
      );

      expect(
        adapter.requestPath,
        '/api/v1/help/articles/activity-cancel-paid/feedback',
      );
      expect(adapter.method, 'PUT');
      expect(adapter.requiresAuth, isTrue);
      expect(adapter.body, isNot(contains('userId')));
      expect(adapter.body, {
        'locale': 'ru',
        'helpful': false,
        'reason': 'Need a human',
        'escalatedToSupport': true,
      });
    },
  );

  test(
    'createSupportTicket requires auth and strips untrusted user signals',
    () async {
      final adapter = _HelpCenterAdapter({
        'id': 'support-user-123-20260620',
        'status': 'new',
        'category': 'activities',
        'priority': 'normal',
        'context': {'activity_id': 'activity-456'},
      });
      final api = HelpCenterApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(accessToken: 'access-token'),
        ),
      );

      final ticket = await api.createSupportTicket(
        category: SupportTicketCategory.activities,
        source: 'activity_details',
        locale: 'ru',
        context: const {
          'activity_id': 'activity-456',
          'user_nickname': '@nomad',
          'followers_count': '25000',
          'is_guide': 'true',
          'subscription_tier': 'premium',
          'authorization': 'must-not-be-sent',
        },
      );

      expect(adapter.requestPath, '/api/v1/support/tickets');
      expect(adapter.requiresAuth, isTrue);
      expect(adapter.body, isNot(contains('userId')));
      expect(adapter.body?['context'], {
        'activity_id': 'activity-456',
        'user_nickname': '@nomad',
      });
      expect(ticket.id, 'support-user-123-20260620');
      expect(ticket.status, 'new');
    },
  );

  test('createSupportTicket sends idempotency key as a header only', () async {
    final adapter = _HelpCenterAdapter({
      'id': 'support-user-123-20260620',
      'status': 'new',
      'category': 'technical',
      'priority': 'normal',
      'context': {'article_id': 'refund-timing'},
    });
    final api = HelpCenterApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(accessToken: 'access-token'),
      ),
    );

    await api.createSupportTicket(
      category: SupportTicketCategory.technical,
      source: 'help_center',
      locale: 'en',
      idempotencyKey: 'create-ticket-request-123',
      context: const {'article_id': 'refund-timing'},
    );

    expect(adapter.headers?['idempotency-key'], 'create-ticket-request-123');
    expect(adapter.body, isNot(contains('idempotencyKey')));
  });

  test('listSupportTickets requires auth and parses ticket metadata', () async {
    final adapter = _HelpCenterAdapter({
      'items': [
        {
          'id': 'ticket-user-123',
          'conversationId': 'conversation-123',
          'status': 'waiting_user',
          'category': 'technical',
          'priority': 'normal',
          'source': 'help_center',
          'locale': 'ru',
          'context': {'article_id': 'refund-timing'},
          'lastMessageAt': '2026-06-20T11:45:00Z',
          'createdAt': '2026-06-20T11:00:00Z',
          'updatedAt': '2026-06-20T11:45:00Z',
        },
      ],
    });
    final api = HelpCenterApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(accessToken: 'access-token'),
      ),
    );

    final tickets = await api.listSupportTickets(status: 'waiting_user');

    expect(adapter.requestPath, '/api/v1/support/tickets');
    expect(adapter.queryParameters, {'status': 'waiting_user'});
    expect(adapter.requiresAuth, isTrue);
    expect(tickets.single.id, 'ticket-user-123');
    expect(tickets.single.conversationId, 'conversation-123');
    expect(
      tickets.single.lastMessageAt?.toUtc().toIso8601String(),
      '2026-06-20T11:45:00.000Z',
    );
  });

  test('getSupportTicket requires auth and parses audit events', () async {
    final adapter = _HelpCenterAdapter({
      'ticket': {
        'id': 'ticket-user-123',
        'conversationId': 'conversation-123',
        'status': 'waiting_support',
        'category': 'technical',
        'priority': 'normal',
        'context': <String, dynamic>{},
      },
      'events': [
        {
          'ticketId': 'ticket-user-123',
          'actorId': 'user-123',
          'actorType': 'user',
          'eventType': 'user_replied',
          'payload': {'message_id': 'chat-message-user-1'},
          'createdAt': '2026-06-20T12:00:00Z',
        },
      ],
    });
    final api = HelpCenterApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(accessToken: 'access-token'),
      ),
    );

    final detail = await api.getSupportTicket(' ticket-user-123 ');

    expect(adapter.requestPath, '/api/v1/support/tickets/ticket-user-123');
    expect(adapter.requiresAuth, isTrue);
    expect(detail.ticket.id, 'ticket-user-123');
    expect(detail.events.single.eventType, 'user_replied');
    expect(detail.events.single.payload['message_id'], 'chat-message-user-1');
  });

  test(
    'getSupportConversation opens the single support chat context',
    () async {
      final adapter = _HelpCenterAdapter({
        'ticket': {
          'id': 'ticket-user-123',
          'conversationId': 'conversation-123',
          'status': 'waiting_support',
          'category': 'technical',
          'priority': 'normal',
          'source': 'support_chat',
          'locale': 'ru',
          'context': <String, dynamic>{},
        },
        'events': [
          {
            'ticketId': 'ticket-user-123',
            'actorId': 'user-123',
            'actorType': 'user',
            'eventType': 'user_replied',
            'payload': {'message_preview': 'Нужна помощь.'},
            'createdAt': '2026-06-20T12:00:00Z',
          },
        ],
      });
      final api = HelpCenterApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(accessToken: 'access-token'),
        ),
      );

      final detail = await api.getSupportConversation(locale: 'ru-KZ');

      expect(adapter.requestPath, '/api/v1/support/conversation');
      expect(adapter.queryParameters, {'locale': 'ru'});
      expect(adapter.requiresAuth, isTrue);
      expect(detail.ticket.source, 'support_chat');
      expect(detail.events.single.payload['message_preview'], 'Нужна помощь.');
    },
  );

  test(
    'replyToSupportTicket sends user message with idempotency header',
    () async {
      final adapter = _HelpCenterAdapter({
        'ticket': {
          'id': 'ticket-user-123',
          'status': 'waiting_support',
          'category': 'technical',
          'priority': 'normal',
          'context': <String, dynamic>{},
        },
      });
      final api = HelpCenterApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(accessToken: 'access-token'),
        ),
      );

      final ticket = await api.replyToSupportTicket(
        ticketId: ' ticket-user-123 ',
        message: '  Я отправил чек, проверьте, пожалуйста.  ',
        actorNickname: '  @nomad  ',
        fileIds: const [' receipt-1 ', '', 'receipt-2'],
        idempotencyKey: ' user-reply-request-123 ',
      );

      expect(
        adapter.requestPath,
        '/api/v1/support/tickets/ticket-user-123/reply',
      );
      expect(adapter.requiresAuth, isTrue);
      expect(adapter.headers?['idempotency-key'], 'user-reply-request-123');
      expect(adapter.body, {
        'message': 'Я отправил чек, проверьте, пожалуйста.',
        'fileIds': ['receipt-1', 'receipt-2'],
        'actorNickname': '@nomad',
      });
      expect(adapter.body, isNot(contains('userId')));
      expect(adapter.body, isNot(contains('idempotencyKey')));
      expect(ticket.id, 'ticket-user-123');
      expect(ticket.status, 'waiting_support');
    },
  );

  test('closeSupportTicket sends reason and parses wrapped ticket', () async {
    final adapter = _HelpCenterAdapter({
      'ticket': {
        'id': 'ticket-user-123',
        'status': 'closed',
        'category': 'technical',
        'priority': 'normal',
        'context': <String, dynamic>{},
      },
    });
    final api = HelpCenterApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(accessToken: 'access-token'),
      ),
    );

    final ticket = await api.closeSupportTicket(
      ticketId: ' ticket-user-123 ',
      reason: '  Спасибо, вопрос решен.  ',
    );

    expect(
      adapter.requestPath,
      '/api/v1/support/tickets/ticket-user-123/close',
    );
    expect(adapter.requiresAuth, isTrue);
    expect(adapter.body, {'reason': 'Спасибо, вопрос решен.'});
    expect(ticket.status, 'closed');
  });

  test('submitSupportTicketCSAT requires auth and sends rating data', () async {
    final adapter = _HelpCenterAdapter({'status': 'accepted'});
    final api = HelpCenterApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(accessToken: 'access-token'),
      ),
    );

    await api.submitSupportTicketCSAT(
      ticketId: ' ticket-user-123 ',
      rating: 5,
      comment: '  Быстро помогли.  ',
    );

    expect(adapter.requestPath, '/api/v1/support/tickets/ticket-user-123/csat');
    expect(adapter.requiresAuth, isTrue);
    expect(adapter.body, {'rating': 5, 'comment': 'Быстро помогли.'});
  });

  test('supportTicketIdempotencyKey canonicalizes safe context', () {
    final key = HelpCenterApi.supportTicketIdempotencyKey(
      source: ' activity_details ',
      intent: ' article-help ',
      context: const {
        'article_id': 'refund-timing',
        'authorization': 'must-not-be-used',
        'activity_id': 'activity-456',
      },
    );

    expect(
      key,
      'support-ticket|activity_details|article-help|activity_id=activity-456|article_id=refund-timing',
    );
    expect(key.length, lessThanOrEqualTo(180));
  });
}

const _contextualArticlesResponse = {
  'items': [
    {
      'id': 'activity-cancel-paid',
      'slug': 'activity-cancel-paid',
      'title': 'Как отменить оплаченную активность?',
      'shortAnswer': 'Проверьте срок бесплатной отмены.',
      'body': 'Если отмена доступна, возврат запускается автоматически.',
      'actions': [
        {'type': 'open_chat', 'target': 'activity_organizer'},
      ],
      'relatedArticleIds': ['refund-timing'],
      'tags': ['activities', 'refunds'],
      'updatedAt': '2026-06-20T09:00:00Z',
    },
  ],
};

const _searchArticlesResponse = {
  'items': [
    {
      'id': 'refund-timing',
      'slug': 'refund-timing',
      'title': 'Когда вернутся деньги?',
      'shortAnswer': 'Возврат обычно занимает несколько банковских дней.',
      'body': 'Проверьте статус платежа.',
      'actions': [
        {'type': 'contact_support', 'target': 'support'},
      ],
      'relatedArticleIds': <String>[],
      'tags': ['payments', 'refunds'],
      'updatedAt': '2026-06-20T09:00:00Z',
    },
  ],
};

class _FakeSecureStorage extends SecureStorage {
  _FakeSecureStorage({this.accessToken});

  final String? accessToken;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => null;
}

class _HelpCenterAdapter implements HttpClientAdapter {
  _HelpCenterAdapter(this.responseBody);

  final Map<String, dynamic> responseBody;
  String? requestPath;
  String? method;
  Map<String, dynamic>? queryParameters;
  bool? requiresAuth;
  Map<String, dynamic>? body;
  Map<String, String>? headers;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestPath = options.uri.path;
    method = options.method;
    queryParameters = Map<String, dynamic>.from(options.uri.queryParameters);
    requiresAuth = options.extra['requiresAuth'] as bool?;
    headers = options.headers.map(
      (key, value) => MapEntry(key.toLowerCase(), value.toString()),
    );
    final requestBytes = await requestStream?.expand((chunk) => chunk).toList();
    if (requestBytes != null && requestBytes.isNotEmpty) {
      body = jsonDecode(utf8.decode(requestBytes)) as Map<String, dynamic>;
    }
    return ResponseBody.fromString(
      jsonEncode(responseBody),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
