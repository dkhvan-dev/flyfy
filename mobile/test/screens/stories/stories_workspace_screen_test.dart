import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inflap/core/network/story_api.dart';
import 'package:inflap/core/storage/secure_storage.dart';
import 'package:inflap/features/stories/models/story_vm.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/providers/auth_provider.dart';
import 'package:inflap/providers/session_provider.dart';
import 'package:inflap/screens/stories/stories_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('my stories ignores stale tab responses after switching status', (
    tester,
  ) async {
    final api = _FakeStoryApi(
      myStoriesByStatus: {
        'PUBLISHED': [
          _story(id: 'published', title: 'Live story', status: 'PUBLISHED'),
        ],
      },
      pendingMyStoryStatuses: {'DRAFT'},
    );

    await tester.pumpWidget(await _app(api: api, myOnly: true));
    await tester.pump();

    expect(find.text('Drafts'), findsOneWidget);
    expect(api.hasPendingMyStories('DRAFT'), isTrue);

    await tester.tap(find.text('Published'));
    await tester.pumpAndSettle();

    expect(find.text('Live story'), findsOneWidget);

    api.completeMyStories(
      'DRAFT',
      StoryListPage(
        items: [_story(id: 'draft', title: 'Slow draft', status: 'DRAFT')],
        hasMore: false,
        total: 1,
        limit: 8,
        offset: 0,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Live story'), findsOneWidget);
    expect(find.text('Slow draft'), findsNothing);
  });

  testWidgets(
    'my stories workspace exposes status tabs and filters API calls',
    (tester) async {
      final api = _FakeStoryApi(
        myStoriesByStatus: {
          'DRAFT': [_story(id: 'draft', title: 'Saved draft', status: 'DRAFT')],
          'PUBLISHED': [
            _story(id: 'published', title: 'Live story', status: 'PUBLISHED'),
          ],
          'ARCHIVED': [
            _story(id: 'archived', title: 'Archived note', status: 'ARCHIVED'),
          ],
        },
      );

      await tester.pumpWidget(await _app(api: api, myOnly: true));
      await tester.pumpAndSettle();

      expect(find.text('Drafts'), findsOneWidget);
      expect(find.text('Published'), findsOneWidget);
      expect(find.text('Archived'), findsOneWidget);
      expect(find.text('Saved draft'), findsOneWidget);
      expect(api.myStoryStatuses, contains('DRAFT'));

      await tester.tap(find.text('Published'));
      await tester.pumpAndSettle();

      expect(find.text('Live story'), findsOneWidget);
      expect(api.myStoryStatuses, contains('PUBLISHED'));

      await tester.tap(find.text('Archived'));
      await tester.pumpAndSettle();

      expect(find.text('Archived note'), findsOneWidget);
      expect(api.myStoryStatuses, contains('ARCHIVED'));
    },
  );

  testWidgets('pagination uses total and limit metadata for total pages', (
    tester,
  ) async {
    final api = _FakeStoryApi(
      publicStories: [
        for (var index = 1; index <= 8; index++)
          _story(id: 'public-$index', title: 'Public story $index'),
      ],
      publicTotal: 24,
      publicHasMore: false,
    );

    await tester.pumpWidget(await _app(api: api));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
    await tester.pumpAndSettle();

    expect(find.text('3'), findsWidgets);
  });

  testWidgets('saved draft is inserted into drafts workspace immediately', (
    tester,
  ) async {
    final api = _FakeStoryApi(
      myStoriesByStatus: const {'DRAFT': []},
      holdMyStoriesRefreshAfterFirstCall: true,
    );
    final draft = _story(
      id: 'new-draft',
      title: 'Fresh draft',
      status: 'DRAFT',
      publishedAt: null,
    );

    await tester.pumpWidget(
      await _app(api: api, myOnly: true, createResult: draft),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fresh draft'), findsNothing);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Return saved draft'));
    await tester.pump();

    expect(find.text('Fresh draft'), findsOneWidget);
    expect(api.myStoryStatuses.last, 'DRAFT');
  });

  testWidgets(
    'inserted draft updates total, pagination, and visible page cap',
    (tester) async {
      final api = _FakeStoryApi(
        myStoriesByStatus: {
          'DRAFT': [
            for (var index = 1; index <= 8; index++)
              _story(
                id: 'draft-$index',
                title: 'Draft $index',
                status: 'DRAFT',
                publishedAt: null,
                createdAt: DateTime.utc(2026, 6, 8 - index),
              ),
          ],
        },
        myStoriesTotalByStatus: const {'DRAFT': 8},
        holdMyStoriesRefreshAfterFirstCall: true,
      );
      final draft = _story(
        id: 'fresh-draft',
        title: 'Fresh draft',
        status: 'DRAFT',
        publishedAt: null,
        createdAt: DateTime.utc(2026, 6, 9),
      );

      await tester.pumpWidget(
        await _app(api: api, myOnly: true, createResults: [draft]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Return saved draft'));
      await tester.pump();

      expect(find.text('Fresh draft'), findsOneWidget);
      expect(find.text('Draft 8'), findsNothing);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
      await tester.pumpAndSettle();

      expect(find.text('2'), findsWidgets);
    },
  );

  testWidgets('immediate insert skips mismatched status tabs', (tester) async {
    final api = _FakeStoryApi(
      myStoriesByStatus: const {'PUBLISHED': [], 'ARCHIVED': []},
      holdMyStoriesRefreshAfterFirstCall: true,
    );
    final draft = _story(
      id: 'new-draft',
      title: 'Fresh draft',
      status: 'DRAFT',
      publishedAt: null,
    );
    final published = _story(
      id: 'new-live',
      title: 'Fresh published',
      status: 'PUBLISHED',
    );

    await tester.pumpWidget(
      await _app(api: api, myOnly: true, createResults: [draft, published]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Published'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Return saved draft'));
    await tester.pump();

    expect(find.text('Fresh draft'), findsNothing);
    expect(find.text('No published stories yet'), findsOneWidget);

    await tester.tap(find.text('Archived'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Return saved draft'));
    await tester.pump();

    expect(find.text('Fresh published'), findsNothing);
    expect(find.text('No archived stories yet'), findsOneWidget);
  });

  testWidgets('immediate insert skips stories outside active filters', (
    tester,
  ) async {
    final api = _FakeStoryApi(
      publicStories: const [],
      holdPublicStoriesRefreshAfterFirstCall: true,
    );
    final story = _story(
      id: 'filtered-out',
      title: 'Visible elsewhere',
      status: 'PUBLISHED',
    );

    await tester.pumpWidget(await _app(api: api, createResults: [story]));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'hidden place');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Return saved draft'));
    await tester.pump();

    expect(find.text('Visible elsewhere'), findsNothing);
    expect(find.text('No stories match your filters'), findsOneWidget);
  });

  testWidgets('public feed empty state offers authenticated users creation', (
    tester,
  ) async {
    final api = _FakeStoryApi(publicStories: const []);

    await tester.pumpWidget(await _app(api: api));
    await tester.pumpAndSettle();

    expect(find.text('No stories yet'), findsOneWidget);
    expect(find.text('Create the first story'), findsOneWidget);
  });

  testWidgets('filtered empty state offers reset filters action', (
    tester,
  ) async {
    final api = _FakeStoryApi(publicStories: const []);

    await tester.pumpWidget(await _app(api: api));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'hidden place');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('No stories match your filters'), findsOneWidget);
    expect(find.text('Reset filters'), findsOneWidget);

    await tester.tap(find.text('Reset filters'));
    await tester.pumpAndSettle();

    expect(find.text('Create the first story'), findsOneWidget);
    expect(find.text('Reset filters'), findsNothing);
  });
}

Future<Widget> _app({
  required _FakeStoryApi api,
  bool myOnly = false,
  StoryVm? createResult,
  List<StoryVm?>? createResults,
}) async {
  final secureStorage = _FakeSecureStorage();
  final authProvider = AuthProvider(secureStorage: secureStorage);
  final sessionProvider = SessionProvider(secureStorage: secureStorage);
  await authProvider.checkAuthStatus();

  late final GoRouter router;
  final queuedCreateResults = List<StoryVm?>.of(
    createResults ?? [createResult],
  );
  router = GoRouter(
    initialLocation: myOnly ? '/me/stories' : '/stories',
    routes: [
      GoRoute(
        path: '/stories',
        builder: (context, state) => StoriesScreen(storyApi: api),
      ),
      GoRoute(
        path: '/me/stories',
        builder: (context, state) => StoriesScreen(myOnly: true, storyApi: api),
      ),
      GoRoute(
        path: '/stories/create',
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => context.pop(
                queuedCreateResults.isEmpty
                    ? null
                    : queuedCreateResults.removeAt(0),
              ),
              child: const Text('Return saved draft'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const Scaffold(body: Text('Login')),
      ),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<SessionProvider>.value(value: sessionProvider),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

class _FakeStoryApi extends StoryApi {
  _FakeStoryApi({
    this.publicStories = const [],
    this.publicTotal,
    this.publicHasMore = false,
    this.myStoriesByStatus = const {},
    this.myStoriesTotalByStatus = const {},
    this.pendingMyStoryStatuses = const {},
    this.holdMyStoriesRefreshAfterFirstCall = false,
    this.holdPublicStoriesRefreshAfterFirstCall = false,
  });

  final List<StoryVm> publicStories;
  final int? publicTotal;
  final bool publicHasMore;
  final Map<String, List<StoryVm>> myStoriesByStatus;
  final Map<String, int> myStoriesTotalByStatus;
  final Set<String> pendingMyStoryStatuses;
  final bool holdMyStoriesRefreshAfterFirstCall;
  final bool holdPublicStoriesRefreshAfterFirstCall;
  final myStoryStatuses = <String?>[];
  final _pendingMyStories = <String, Completer<StoryListPage>>{};
  int _myStoriesCallCount = 0;
  Completer<StoryListPage>? _heldMyStoriesRefresh;
  int _publicStoriesCallCount = 0;
  Completer<StoryListPage>? _heldPublicStoriesRefresh;

  bool hasPendingMyStories(String status) =>
      _pendingMyStories[status]?.isCompleted == false;

  void completeMyStories(String status, StoryListPage page) {
    final pending = _pendingMyStories.remove(status);
    if (pending == null || pending.isCompleted) {
      return;
    }
    pending.complete(page);
  }

  @override
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
    _publicStoriesCallCount += 1;
    if (holdPublicStoriesRefreshAfterFirstCall && _publicStoriesCallCount > 1) {
      _heldPublicStoriesRefresh ??= Completer<StoryListPage>();
      return _heldPublicStoriesRefresh!.future;
    }

    final filtered = search == null || search.trim().isEmpty
        ? publicStories
        : const <StoryVm>[];
    return StoryListPage(
      items: filtered,
      hasMore: publicHasMore,
      total: publicTotal ?? filtered.length,
      limit: limit,
      offset: offset,
    );
  }

  @override
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
    myStoryStatuses.add(status);
    _myStoriesCallCount += 1;
    final normalizedStatus = status ?? '';
    if (pendingMyStoryStatuses.contains(normalizedStatus)) {
      final pending = _pendingMyStories.putIfAbsent(
        normalizedStatus,
        Completer<StoryListPage>.new,
      );
      return pending.future;
    }

    if (holdMyStoriesRefreshAfterFirstCall && _myStoriesCallCount > 1) {
      _heldMyStoriesRefresh ??= Completer<StoryListPage>();
      return _heldMyStoriesRefresh!.future;
    }

    final items = myStoriesByStatus[status] ?? const <StoryVm>[];
    return StoryListPage(
      items: items,
      hasMore: false,
      total: myStoriesTotalByStatus[status] ?? items.length,
      limit: limit,
      offset: offset,
    );
  }
}

class _FakeSecureStorage extends SecureStorage {
  @override
  Future<String?> getAccessToken() async => 'access-token';

  @override
  Future<String?> getRefreshToken() async => null;
}

StoryVm _story({
  required String id,
  required String title,
  String status = 'PUBLISHED',
  DateTime? publishedAt,
  DateTime? createdAt,
}) {
  return StoryVm(
    id: id,
    slug: id,
    title: title,
    excerpt: 'Excerpt',
    category: 'JOURNAL',
    status: status,
    tags: const [],
    stats: StoryStatsVm(views: 1, likes: 0, comments: 0, shares: 0),
    author: StoryAuthorVm(
      userId: 'user-1',
      locale: 'en',
      timezone: 'Asia/Almaty',
    ),
    likedByViewer: false,
    shareUrl: '',
    publishedAt: publishedAt ?? DateTime.utc(2026, 6, 8),
    createdAt: createdAt ?? DateTime.utc(2026, 6, 8),
    updatedAt: createdAt ?? DateTime.utc(2026, 6, 8),
  );
}
