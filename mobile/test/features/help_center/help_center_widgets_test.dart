import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:inflap/features/help_center/data/help_center_api.dart';
import 'package:inflap/features/help_center/presentation/help_center_screen.dart';
import 'package:inflap/features/help_center/widgets/contextual_help_section.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';

void main() {
  test('ContextualHelpSection uses V2 design colors only', () {
    final source = File(
      'lib/features/help_center/widgets/contextual_help_section.dart',
    ).readAsStringSync();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.secondaryContainer'));
    expect(source, contains('colors.borderSecondary'));
    expect(source, contains('colors.secondary'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test('HelpArticleTile uses V2 design colors only', () {
    final source = File(
      'lib/features/help_center/widgets/help_article_tile.dart',
    ).readAsStringSync();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.secondaryContainer'));
    expect(source, contains('colors.borderSecondary'));
    expect(source, contains('colors.secondary'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test('HelpCenterScreen uses V2 design colors only', () {
    final source = File(
      'lib/features/help_center/presentation/help_center_screen.dart',
    ).readAsStringSync();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.screenGradientColors'));
    expect(source, contains('colors.surface'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.secondaryContainer'));
    expect(source, contains('colors.borderSecondary'));
    expect(source, contains('colors.secondary'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test('HelpCenterScreen category picker closes when tapping outside', () {
    final source = File(
      'lib/features/help_center/presentation/help_center_screen.dart',
    ).readAsStringSync();

    final pickerStart = source.indexOf('Future<void> _openCategoryPicker');
    final contentStart = source.indexOf('Widget _buildContent');

    expect(pickerStart, isNonNegative);
    expect(contentStart, greaterThan(pickerStart));

    final pickerSource = source.substring(pickerStart, contentStart);

    expect(pickerSource, contains('AppModalSheetFrame('));
    expect(
      pickerSource,
      contains('onTapOutside: () => Navigator.of(context).maybePop(),'),
    );
  });

  testWidgets(
    'HelpCenterScreen loads popular articles and searches on submit',
    (tester) async {
      final api = _FakeHelpCenterApi(
        pages: [
          HelpArticlePageVm(
            items: [_article(id: 'popular', title: 'Popular help')],
            total: 1,
            limit: 10,
            offset: 0,
            hasMore: false,
          ),
        ],
        searchItems: [_article(id: 'refund', title: 'Refund rules')],
      );

      await tester.pumpWidget(_testApp(HelpCenterScreen(api: api)));
      await tester.pumpAndSettle();

      expect(find.text('Popular help'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('help-center-search-field')),
        ' refund ',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(api.lastSearchQuery, ' refund ');
      expect(find.text('Refund rules'), findsOneWidget);
    },
  );

  testWidgets('HelpCenterScreen searches typed Q&A query after debounce', (
    tester,
  ) async {
    final api = _FakeHelpCenterApi(
      pages: [
        HelpArticlePageVm(
          items: [_article(id: 'popular', title: 'Popular help')],
          total: 1,
          limit: 10,
          offset: 0,
          hasMore: false,
        ),
      ],
      searchItems: [_article(id: 'passport', title: 'Passport answer')],
    );

    await tester.pumpWidget(_testApp(HelpCenterScreen(api: api)));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('help-center-search-field')),
      ' паспорт ',
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(api.lastSearchQuery, isNull);
    expect(find.text('Popular help'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(api.lastSearchQuery, ' паспорт ');
    expect(find.text('Passport answer'), findsOneWidget);
    expect(find.text('Popular help'), findsNothing);
  });

  testWidgets('HelpCenterScreen filters popular help by category chips', (
    tester,
  ) async {
    final api = _FakeHelpCenterApi(
      categories: const [
        HelpCategoryVm(
          id: 'documents_visas_entry',
          slug: 'documents-visas-entry',
          title: 'Documents and entry',
          sortOrder: 10,
          articleCount: 18,
        ),
      ],
      pages: [
        HelpArticlePageVm(
          items: [_article(id: 'activity-help', title: 'Activity help')],
          total: 1,
          limit: 10,
          offset: 0,
          hasMore: false,
        ),
      ],
    );

    await tester.pumpWidget(_testApp(HelpCenterScreen(api: api)));
    await tester.pumpAndSettle();

    expect(api.lastCategoryId, isNull);
    expect(
      find.byKey(const ValueKey('help-center-category-documents')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('help-center-category-flights')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('help-center-category-documents')),
    );
    await tester.pumpAndSettle();

    expect(api.lastCategoryId, 'documents_visas_entry');
    expect(find.text('Activity help'), findsOneWidget);
  });

  testWidgets('HelpCenterScreen renders category titles from backend', (
    tester,
  ) async {
    final api = _FakeHelpCenterApi(
      categories: const [
        HelpCategoryVm(
          id: 'travel_connectivity',
          slug: 'travel-connectivity',
          title: 'Connection & SIM',
          sortOrder: 50,
          articleCount: 4,
        ),
      ],
      pages: [
        HelpArticlePageVm(
          items: [_article(id: 'sim-help', title: 'eSIM help')],
          total: 1,
          limit: 10,
          offset: 0,
          hasMore: false,
        ),
      ],
    );

    await tester.pumpWidget(_testApp(HelpCenterScreen(api: api)));
    await tester.pumpAndSettle();

    expect(find.text('Connection & SIM'), findsOneWidget);
    expect(find.text('Travel Connectivity'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('help-center-category-travel-connectivity')),
    );
    await tester.pumpAndSettle();

    expect(api.lastCategoryId, 'travel_connectivity');
  });

  testWidgets(
    'HelpCenterScreen keeps compact category row short and selects hidden category from sheet',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final api = _FakeHelpCenterApi(
        categories: const [
          HelpCategoryVm(
            id: 'documents_visas_entry',
            slug: 'documents-visas-entry',
            title: 'Documents',
            sortOrder: 10,
            articleCount: 18,
          ),
          HelpCategoryVm(
            id: 'airport_flights_baggage',
            slug: 'airport-flights-baggage',
            title: 'Flights',
            sortOrder: 20,
            articleCount: 19,
          ),
          HelpCategoryVm(
            id: 'booking_accommodation',
            slug: 'booking-accommodation',
            title: 'Stay',
            sortOrder: 30,
            articleCount: 8,
          ),
          HelpCategoryVm(
            id: 'health_safety_insurance',
            slug: 'health-safety-insurance',
            title: 'Safety',
            sortOrder: 40,
            articleCount: 7,
          ),
          HelpCategoryVm(
            id: 'money_cards_connectivity',
            slug: 'money-cards-connectivity',
            title: 'Money & SIM',
            sortOrder: 50,
            articleCount: 12,
          ),
          HelpCategoryVm(
            id: 'local_transport',
            slug: 'local-transport',
            title: 'Transport',
            sortOrder: 60,
            articleCount: 6,
          ),
        ],
        pages: [
          HelpArticlePageVm(
            items: [_article(id: 'popular', title: 'Popular help')],
            total: 1,
            limit: 10,
            offset: 0,
            hasMore: false,
          ),
          HelpArticlePageVm(
            items: [_article(id: 'money', title: 'Money answer')],
            total: 1,
            limit: 10,
            offset: 0,
            hasMore: false,
          ),
        ],
      );

      await tester.pumpWidget(_testApp(HelpCenterScreen(api: api)));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('help-center-category-money')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('help-center-category-more')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('help-center-category-more')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('help-center-category-sheet')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('help-center-category-sheet-money')),
      );
      await tester.pumpAndSettle();

      expect(api.lastCategoryId, 'money_cards_connectivity');
      expect(find.text('Money answer'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('help-center-category-money')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('help-center-category-sheet')),
        findsNothing,
      );
    },
  );

  testWidgets('HelpCenterScreen paginates all Q&A from API pages', (
    tester,
  ) async {
    final api = _FakeHelpCenterApi(
      pages: [
        HelpArticlePageVm(
          items: [_article(id: 'page-1', title: 'First page answer')],
          total: 2,
          limit: 1,
          offset: 0,
          nextOffset: 1,
          hasMore: true,
        ),
        HelpArticlePageVm(
          items: [_article(id: 'page-2', title: 'Second page answer')],
          total: 2,
          limit: 1,
          offset: 1,
          hasMore: false,
        ),
      ],
    );

    await tester.pumpWidget(_testApp(HelpCenterScreen(api: api)));
    await tester.pumpAndSettle();

    expect(find.text('First page answer'), findsOneWidget);
    expect(find.text('Second page answer'), findsNothing);
    expect(api.lastOffset, 0);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('help-center-load-more')));
    await tester.pumpAndSettle();

    expect(api.lastOffset, 1);
    expect(find.text('First page answer'), findsOneWidget);
    expect(find.text('Second page answer'), findsOneWidget);
  });

  testWidgets(
    'HelpCenterScreen uses amber search icon and primary category text',
    (tester) async {
      final api = _FakeHelpCenterApi(
        pages: [
          HelpArticlePageVm(
            items: [_article(id: 'popular', title: 'Popular help')],
            total: 1,
            limit: 10,
            offset: 0,
            hasMore: false,
          ),
        ],
      );

      await tester.pumpWidget(_testApp(HelpCenterScreen(api: api)));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(
        find.byKey(const ValueKey('help-center-search-field')),
      );
      final prefixIcon = textField.decoration?.prefixIcon;
      expect(prefixIcon, isA<Icon>());
      expect((prefixIcon! as Icon).color, AppColorSchemes.light.primary);
      final suffixIcon = textField.decoration?.suffixIcon;
      expect(suffixIcon, isA<IconButton>());
      expect((suffixIcon! as IconButton).color, AppColorSchemes.light.primary);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Support requests'), findsNothing);

      final allChip = tester.widget<ChoiceChip>(
        find.byKey(const ValueKey('help-center-category-all')),
      );
      final flightsChip = tester.widget<ChoiceChip>(
        find.byKey(const ValueKey('help-center-category-flights')),
      );
      expect(allChip.labelStyle?.color, AppColorSchemes.light.textPrimary);
      expect(flightsChip.labelStyle?.color, AppColorSchemes.light.textPrimary);
    },
  );

  testWidgets(
    'HelpCenterScreen does not show built-in popular answers when API is empty',
    (tester) async {
      final api = _FakeHelpCenterApi();

      await tester.pumpWidget(_testApp(HelpCenterScreen(api: api)));
      await tester.pumpAndSettle();

      expect(find.text('How do I create a support request?'), findsNothing);
      expect(find.text('No answer found'), findsOneWidget);
      expect(find.text('Contact support'), findsNothing);
    },
  );

  testWidgets(
    'HelpCenterScreen does not resubmit the same article feedback selection',
    (tester) async {
      final api = _FakeHelpCenterApi(
        pages: [
          HelpArticlePageVm(
            items: [_article(id: 'app-help', title: 'How Inflap works')],
            total: 1,
            limit: 10,
            offset: 0,
            hasMore: false,
          ),
        ],
      );

      await tester.pumpWidget(_testApp(HelpCenterScreen(api: api)));
      await tester.pumpAndSettle();

      final helpfulButton = find.byKey(
        const ValueKey('help-article-feedback-helpful'),
      );
      final notHelpfulButton = find.byKey(
        const ValueKey('help-article-feedback-not-helpful'),
      );
      await tester.ensureVisible(helpfulButton);
      await tester.pumpAndSettle();

      await tester.tap(helpfulButton);
      await tester.pumpAndSettle();

      expect(api.feedbackHelpfulValues, [true]);
      expect(api.lastFeedbackArticleId, 'app-help');

      await tester.tap(helpfulButton);
      await tester.pumpAndSettle();

      expect(api.feedbackHelpfulValues, [true]);

      await tester.tap(notHelpfulButton);
      await tester.pumpAndSettle();

      expect(api.feedbackHelpfulValues, [true, false]);
    },
  );

  testWidgets(
    'HelpCenterScreen reloads popular answers when selected All chip is tapped after empty search',
    (tester) async {
      final api = _FakeHelpCenterApi(
        pages: [
          HelpArticlePageVm(
            items: [_article(id: 'popular', title: 'Popular help')],
            total: 1,
            limit: 10,
            offset: 0,
            hasMore: false,
          ),
        ],
        searchItems: const [],
      );

      await tester.pumpWidget(_testApp(HelpCenterScreen(api: api)));
      await tester.pumpAndSettle();

      expect(find.text('Popular help'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('help-center-search-field')),
        'unknown question',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.text('No answer found'), findsOneWidget);
      expect(find.text('Popular help'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('help-center-category-all')));
      await tester.pumpAndSettle();

      expect(api.lastTags, isEmpty);
      expect(find.text('Popular help'), findsOneWidget);
      expect(find.text('No answer found'), findsNothing);
    },
  );

  testWidgets(
    'HelpCenterScreen opens support chat with failed search context from no results state',
    (tester) async {
      final api = _FakeHelpCenterApi(searchItems: const []);
      SupportChatOpenIntent? receivedIntent;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => HelpCenterScreen(api: api),
          ),
          GoRoute(
            path: '/help/support',
            builder: (_, state) {
              final extra = state.extra;
              if (extra is SupportChatOpenIntent) {
                receivedIntent = extra;
              }
              return const Scaffold(body: Text('Support chat'));
            },
          ),
        ],
      );

      await tester.pumpWidget(_routerTestApp(router));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('help-center-search-field')),
        'unknown question',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.text('No answer found'), findsOneWidget);
      expect(find.text('Contact support'), findsNothing);

      await tester.ensureVisible(find.text('Open chat'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open chat'));
      await tester.pumpAndSettle();

      expect(find.text('Support chat'), findsOneWidget);
      expect(api.createTicketCalls, 0);
      expect(receivedIntent?.category, SupportTicketCategory.technical);
      expect(receivedIntent?.source, HelpCenterSurface.helpCenter.wireValue);
      expect(receivedIntent?.intent, 'failed_search:unknown question');
      expect(receivedIntent?.context['failed_search'], 'unknown question');
      expect(receivedIntent?.context['search_query'], 'unknown question');
      expect(receivedIntent?.context['screen'], 'help_center');
      expect(receivedIntent?.context['source_route'], '/help');
      expect(receivedIntent?.context['locale'], 'en');
    },
  );

  testWidgets('ContextualHelpSection shows help and reports selected actions', (
    tester,
  ) async {
    final api = _FakeHelpCenterApi(
      pages: [
        HelpArticlePageVm(
          items: [
            _article(
              id: 'activity-chat',
              title: 'Ask the organizer',
              action: const HelpArticleActionVm(
                type: HelpArticleActionType.openChat,
                target: 'activity_organizer',
                label: 'Open activity chat',
              ),
            ),
          ],
          total: 1,
          limit: 10,
          offset: 0,
          hasMore: false,
        ),
      ],
    );
    HelpArticleVm? selectedArticle;
    HelpArticleActionVm? selectedAction;

    await tester.pumpWidget(
      _testApp(
        Scaffold(
          body: ContextualHelpSection(
            api: api,
            surface: HelpCenterSurface.activityDetails,
            tags: const ['activities', 'refunds'],
            supportContext: const {'activity_id': 'activity-123'},
            onActionSelected: (article, action) {
              selectedArticle = article;
              selectedAction = action;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(api.lastSurface, HelpCenterSurface.activityDetails);
    expect(api.lastTags, ['activities', 'refunds']);
    expect(find.text('Ask the organizer'), findsOneWidget);

    await tester.tap(find.text('Open activity chat'));
    await tester.pump();

    expect(selectedArticle?.id, 'activity-chat');
    expect(selectedAction?.type, HelpArticleActionType.openChat);
  });

  testWidgets('ContextualHelpSection opens support chat with article context', (
    tester,
  ) async {
    final api = _FakeHelpCenterApi(
      pages: [
        HelpArticlePageVm(
          items: [_article(id: 'payment-help', title: 'Payment help')],
          total: 1,
          limit: 10,
          offset: 0,
          hasMore: false,
        ),
      ],
    );
    SupportChatOpenIntent? receivedIntent;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: ContextualHelpSection(
              api: api,
              surface: HelpCenterSurface.activityDetails,
              supportContext: const {'activity_id': 'activity-123'},
            ),
          ),
        ),
        GoRoute(
          path: '/help/support',
          builder: (_, state) {
            final extra = state.extra;
            if (extra is SupportChatOpenIntent) {
              receivedIntent = extra;
            }
            return const Scaffold(body: Text('Support chat'));
          },
        ),
      ],
    );

    await tester.pumpWidget(_routerTestApp(router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Contact support'));
    await tester.pumpAndSettle();

    expect(find.text('Support chat'), findsOneWidget);
    expect(api.createTicketCalls, 0);
    expect(receivedIntent?.category, SupportTicketCategory.activities);
    expect(receivedIntent?.source, HelpCenterSurface.activityDetails.wireValue);
    expect(receivedIntent?.intent, 'article:payment-help');
    expect(receivedIntent?.context['activity_id'], 'activity-123');
    expect(receivedIntent?.context['article_id'], 'payment-help');
  });
}

Widget _testApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

Widget _routerTestApp(GoRouter router) {
  return MaterialApp.router(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  );
}

HelpArticleVm _article({
  required String id,
  required String title,
  HelpArticleActionVm action = const HelpArticleActionVm(
    type: HelpArticleActionType.contactSupport,
    target: 'support',
    label: 'Contact support',
  ),
}) {
  return HelpArticleVm(
    id: id,
    slug: id,
    title: title,
    shortAnswer: 'Short practical answer',
    body: 'Detailed explanation with next steps.',
    actions: [action],
    relatedArticleIds: const [],
    tags: const ['activities'],
    updatedAt: DateTime.utc(2026, 6, 20),
  );
}

class _FakeHelpCenterApi extends HelpCenterApi {
  _FakeHelpCenterApi({
    this.categories = _defaultHelpCategories,
    this.pages = const [],
    this.searchItems = const [],
  });

  final List<HelpCategoryVm> categories;
  final List<HelpArticlePageVm> pages;
  final List<HelpArticleVm> searchItems;
  String? lastSearchQuery;
  HelpCenterSurface? lastSurface;
  List<String>? lastTags;
  String? lastCategoryId;
  int? lastOffset;
  String? lastFeedbackArticleId;
  final feedbackHelpfulValues = <bool>[];
  var _pageCallCount = 0;
  int createTicketCalls = 0;

  @override
  Future<List<HelpCategoryVm>> helpCategories({
    required String locale,
    required HelpCenterSurface surface,
  }) async {
    return categories;
  }

  @override
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
    lastSurface = surface;
    lastTags = tags.toList(growable: false);
    lastCategoryId = categoryId;
    lastOffset = offset ?? 0;
    if (pages.isEmpty) {
      return const HelpArticlePageVm(
        items: [],
        total: 0,
        limit: 0,
        offset: 0,
        hasMore: false,
      );
    }
    final index = _pageCallCount >= pages.length
        ? pages.length - 1
        : _pageCallCount;
    _pageCallCount += 1;
    return pages[index];
  }

  @override
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

  @override
  Future<List<HelpArticleVm>> searchArticles({
    required String locale,
    required String query,
    HelpCenterSurface? surface,
    int? limit,
  }) async {
    lastSearchQuery = query;
    return searchItems;
  }

  @override
  Future<void> submitArticleFeedback({
    required String articleId,
    required String locale,
    required bool helpful,
    String? reason,
    bool escalatedToSupport = false,
  }) async {
    lastFeedbackArticleId = articleId;
    feedbackHelpfulValues.add(helpful);
  }

  @override
  Future<SupportTicketVm> createSupportTicket({
    required SupportTicketCategory category,
    required String source,
    required String locale,
    Map<String, String> context = const {},
    String? idempotencyKey,
  }) async {
    createTicketCalls += 1;
    return SupportTicketVm(
      id: 'ticket-created',
      status: 'new',
      category: category,
      priority: 'normal',
      source: source,
      locale: locale,
      context: context,
    );
  }
}

const _defaultHelpCategories = [
  HelpCategoryVm(
    id: 'documents_visas_entry',
    slug: 'documents-visas-entry',
    title: 'Documents and entry',
    sortOrder: 10,
    articleCount: 18,
  ),
  HelpCategoryVm(
    id: 'airport_flights_baggage',
    slug: 'airport-flights-baggage',
    title: 'Flights, airport and baggage',
    sortOrder: 20,
    articleCount: 19,
  ),
];
