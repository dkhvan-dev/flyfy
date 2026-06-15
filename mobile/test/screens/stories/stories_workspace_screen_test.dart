import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inflap/core/network/post_api.dart';
import 'package:inflap/core/storage/secure_storage.dart';
import 'package:inflap/features/stories/models/post_vm.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/providers/auth_provider.dart';
import 'package:inflap/providers/session_provider.dart';
import 'package:inflap/screens/stories/stories_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('my stories ignores stale tab responses after switching status', (
    tester,
  ) async {
    final api = _FakePostApi(
      myPostsByStatus: {
        'DRAFT': [_story(id: 'draft', title: 'Saved draft', status: 'DRAFT')],
      },
      pendingMyStoryStatuses: {'PUBLISHED'},
    );

    await tester.pumpWidget(await _app(api: api, myOnly: true));
    await tester.pump();

    expect(find.text('Published'), findsOneWidget);
    expect(api.hasPendingMyPosts('PUBLISHED'), isTrue);

    await tester.tap(find.text('Drafts'));
    await tester.pumpAndSettle();

    expect(find.text('Saved draft'), findsOneWidget);

    api.completeMyPosts(
      'PUBLISHED',
      PostListPage(
        items: [
          _story(id: 'published', title: 'Live story', status: 'PUBLISHED'),
        ],
        hasMore: false,
        total: 1,
        limit: 8,
        offset: 0,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Saved draft'), findsOneWidget);
    expect(find.text('Live story'), findsNothing);
  });

  testWidgets(
    'my stories workspace exposes status tabs and filters API calls',
    (tester) async {
      final api = _FakePostApi(
        myPostsByStatus: {
          'DRAFT': [_story(id: 'draft', title: 'Saved draft', status: 'DRAFT')],
          'PUBLISHED': [
            _story(id: 'published', title: 'Live story', status: 'PUBLISHED'),
          ],
          'PUBLISHED|PENDING': [
            _story(
              id: 'pending',
              title: 'Pending review',
              status: 'PUBLISHED',
              moderationStatus: 'PENDING',
            ),
          ],
          'ARCHIVED': [
            _story(id: 'archived', title: 'Archived note', status: 'ARCHIVED'),
          ],
        },
      );

      await tester.pumpWidget(await _app(api: api, myOnly: true));
      await tester.pumpAndSettle();

      expect(find.text('Drafts'), findsOneWidget);
      expect(find.text('In review'), findsOneWidget);
      expect(find.text('Published'), findsOneWidget);
      expect(find.text('Archived'), findsOneWidget);
      expect(find.text('Live story'), findsOneWidget);
      expect(api.myStoryStatuses, contains('PUBLISHED'));
      expect(
        api.myPostModerationStatuses,
        contains(equals(['NOT_REQUIRED', 'APPROVED'])),
      );

      await tester.tap(find.text('Drafts'));
      await tester.pumpAndSettle();

      expect(find.text('Saved draft'), findsOneWidget);
      expect(api.myStoryStatuses, contains('DRAFT'));

      await tester.tap(find.text('In review'));
      await tester.pumpAndSettle();

      expect(find.text('Pending review'), findsWidgets);
      expect(api.myPostModerationStatuses, contains(equals(['PENDING'])));

      await tester.tap(find.text('Archived'));
      await tester.pumpAndSettle();

      expect(find.text('Archived note'), findsOneWidget);
      expect(api.myStoryStatuses, contains('ARCHIVED'));
    },
  );

  testWidgets('pagination uses total and limit metadata for total pages', (
    tester,
  ) async {
    final api = _FakePostApi(
      publicPosts: [
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
    final api = _FakePostApi(
      myPostsByStatus: const {'DRAFT': []},
      holdMyPostsRefreshAfterFirstCall: true,
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
    expect(find.text('No published posts yet'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Return saved draft'));
    await tester.pump();

    expect(find.text('Fresh draft'), findsOneWidget);
    expect(api.myStoryStatuses.last, 'DRAFT');
  });

  testWidgets('inserted draft respects the visible page cap', (tester) async {
    final api = _FakePostApi(
      myPostsByStatus: {
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
      myPostsTotalByStatus: const {'DRAFT': 8},
      holdMyPostsRefreshAfterFirstCall: true,
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
  });

  testWidgets('immediate insert switches to the returned post status tab', (
    tester,
  ) async {
    final api = _FakePostApi(
      myPostsByStatus: const {'PUBLISHED': [], 'ARCHIVED': []},
      holdMyPostsRefreshAfterFirstCall: true,
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

    expect(find.text('Fresh draft'), findsOneWidget);
    expect(api.myStoryStatuses.last, 'DRAFT');

    await tester.tap(find.text('Archived'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Return saved draft'));
    await tester.pump();

    expect(find.text('Fresh published'), findsOneWidget);
    expect(api.myStoryStatuses.last, 'PUBLISHED');
  });

  testWidgets('immediate insert skips posts outside active filters', (
    tester,
  ) async {
    final api = _FakePostApi(
      publicPosts: const [],
      holdPublicPostsRefreshAfterFirstCall: true,
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
    expect(find.text('No posts match your filters'), findsOneWidget);
  });

  testWidgets('public feed empty state offers authenticated users creation', (
    tester,
  ) async {
    final api = _FakePostApi(publicPosts: const []);

    await tester.pumpWidget(await _app(api: api));
    await tester.pumpAndSettle();

    expect(find.text('No posts yet'), findsOneWidget);
    expect(find.text('Create the first post'), findsOneWidget);
  });

  testWidgets(
    'story list shows reusable state affordances and disables blocked entries',
    (tester) async {
      tester.view.physicalSize = const Size(430, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final api = _FakePostApi(
        publicPosts: [
          _story(id: 'seen-story', title: 'Seen story', seenByViewer: true),
          _story(
            id: 'expired-story',
            title: 'Expired story',
            expiresAt: DateTime.utc(2020),
          ),
          _story(
            id: 'pending-story',
            title: 'Pending story',
            moderationStatus: 'PENDING',
          ),
          _story(id: 'hidden-story', title: 'Hidden story', status: 'HIDDEN'),
        ],
      );

      await tester.pumpWidget(await _app(api: api));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('story-state-pill-seen')), findsOne);
      expect(
        find.byKey(const ValueKey('story-state-pill-expired')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('story-state-pill-pending')), findsOne);
      expect(find.byKey(const ValueKey('story-state-pill-hidden')), findsOne);

      await tester.tap(find.text('Seen story'));
      await tester.pumpAndSettle();
      expect(find.text('Opened seen-story'), findsOneWidget);

      await tester.tap(find.text('Back to posts'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Expired story'));
      await tester.pumpAndSettle();
      expect(find.text('Opened expired-story'), findsOneWidget);

      await tester.tap(find.text('Back to posts'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pending story'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hidden story'));
      await tester.pumpAndSettle();

      expect(find.text('Opened pending-story'), findsNothing);
      expect(find.text('Opened hidden-story'), findsNothing);
    },
  );

  testWidgets('filtered empty state offers reset filters action', (
    tester,
  ) async {
    final api = _FakePostApi(publicPosts: const []);

    await tester.pumpWidget(await _app(api: api));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'hidden place');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('No posts match your filters'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('Create the first post'), findsOneWidget);
    expect(find.text('Clear'), findsNothing);
  });
}

Future<Widget> _app({
  required _FakePostApi api,
  bool myOnly = false,
  PostVm? createResult,
  List<PostVm?>? createResults,
}) async {
  final secureStorage = _FakeSecureStorage();
  final authProvider = AuthProvider(secureStorage: secureStorage);
  final sessionProvider = SessionProvider(secureStorage: secureStorage);
  await authProvider.checkAuthStatus();

  late final GoRouter router;
  final queuedCreateResults = List<PostVm?>.of(createResults ?? [createResult]);
  router = GoRouter(
    initialLocation: myOnly ? '/me/posts' : '/posts',
    routes: [
      GoRoute(
        path: '/posts',
        builder: (context, state) => StoriesScreen(postApi: api),
      ),
      GoRoute(
        path: '/me/posts',
        builder: (context, state) => StoriesScreen(myOnly: true, postApi: api),
      ),
      GoRoute(
        path: '/posts/create',
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
        path: '/posts/:slug',
        builder: (context, state) => Scaffold(
          body: Column(
            children: [
              Text('Opened ${state.pathParameters['slug']}'),
              TextButton(
                onPressed: () => context.go('/posts'),
                child: const Text('Back to posts'),
              ),
            ],
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

class _FakePostApi extends PostApi {
  _FakePostApi({
    this.publicPosts = const [],
    this.publicTotal,
    this.publicHasMore = false,
    this.myPostsByStatus = const {},
    this.myPostsTotalByStatus = const {},
    this.pendingMyStoryStatuses = const {},
    this.holdMyPostsRefreshAfterFirstCall = false,
    this.holdPublicPostsRefreshAfterFirstCall = false,
  });

  final List<PostVm> publicPosts;
  final int? publicTotal;
  final bool publicHasMore;
  final Map<String, List<PostVm>> myPostsByStatus;
  final Map<String, int> myPostsTotalByStatus;
  final Set<String> pendingMyStoryStatuses;
  final bool holdMyPostsRefreshAfterFirstCall;
  final bool holdPublicPostsRefreshAfterFirstCall;
  final myStoryStatuses = <String?>[];
  final myPostModerationStatuses = <List<String>?>[];
  final _pendingMyPosts = <String, Completer<PostListPage>>{};
  int _myPostsCallCount = 0;
  Completer<PostListPage>? _heldMyPostsRefresh;
  int _publicPostsCallCount = 0;
  Completer<PostListPage>? _heldPublicPostsRefresh;

  bool hasPendingMyPosts(String status) =>
      _pendingMyPosts[status]?.isCompleted == false;

  void completeMyPosts(String status, PostListPage page) {
    final pending = _pendingMyPosts.remove(status);
    if (pending == null || pending.isCompleted) {
      return;
    }
    pending.complete(page);
  }

  @override
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
    _publicPostsCallCount += 1;
    if (holdPublicPostsRefreshAfterFirstCall && _publicPostsCallCount > 1) {
      _heldPublicPostsRefresh ??= Completer<PostListPage>();
      return _heldPublicPostsRefresh!.future;
    }

    final filtered = search == null || search.trim().isEmpty
        ? publicPosts
        : const <PostVm>[];
    return PostListPage(
      items: filtered,
      hasMore: publicHasMore,
      total: publicTotal ?? filtered.length,
      limit: limit,
      offset: offset,
    );
  }

  @override
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
    myStoryStatuses.add(status);
    myPostModerationStatuses.add(moderationStatuses);
    _myPostsCallCount += 1;
    final normalizedStatus = _myPostsKey(status, moderationStatuses);
    if (pendingMyStoryStatuses.contains(status ?? '') ||
        pendingMyStoryStatuses.contains(normalizedStatus)) {
      final pending = _pendingMyPosts.putIfAbsent(
        status ?? normalizedStatus,
        Completer<PostListPage>.new,
      );
      return pending.future;
    }

    if (holdMyPostsRefreshAfterFirstCall && _myPostsCallCount > 1) {
      _heldMyPostsRefresh ??= Completer<PostListPage>();
      return _heldMyPostsRefresh!.future;
    }

    final items =
        myPostsByStatus[normalizedStatus] ??
        myPostsByStatus[status] ??
        const <PostVm>[];
    return PostListPage(
      items: items,
      hasMore: false,
      total:
          myPostsTotalByStatus[normalizedStatus] ??
          myPostsTotalByStatus[status] ??
          items.length,
      limit: limit,
      offset: offset,
    );
  }

  String _myPostsKey(String? status, List<String>? moderationStatuses) {
    final normalizedStatus = status ?? '';
    final normalizedModeration = (moderationStatuses ?? const <String>[])
        .map((value) => value.trim().toUpperCase())
        .where((value) => value.isNotEmpty)
        .join(',');
    if (normalizedModeration.isEmpty) {
      return normalizedStatus;
    }
    return '$normalizedStatus|$normalizedModeration';
  }
}

class _FakeSecureStorage extends SecureStorage {
  @override
  Future<String?> getAccessToken() async => 'access-token';

  @override
  Future<String?> getRefreshToken() async => null;
}

PostVm _story({
  required String id,
  required String title,
  String status = 'PUBLISHED',
  String moderationStatus = 'NOT_REQUIRED',
  bool seenByViewer = false,
  DateTime? expiresAt,
  DateTime? publishedAt,
  DateTime? createdAt,
}) {
  return PostVm(
    id: id,
    slug: id,
    title: title,
    excerpt: 'Excerpt',
    category: 'JOURNAL',
    status: status,
    moderationStatus: moderationStatus,
    tags: const [],
    stats: PostStatsVm(views: 1, likes: 0, comments: 0, shares: 0),
    author: PostAuthorVm(
      userId: 'user-1',
      locale: 'en',
      timezone: 'Asia/Almaty',
    ),
    likedByViewer: false,
    seenByViewer: seenByViewer,
    shareUrl: '',
    publishedAt: publishedAt ?? DateTime.utc(2026, 6, 8),
    expiresAt: expiresAt,
    createdAt: createdAt ?? DateTime.utc(2026, 6, 8),
    updatedAt: createdAt ?? DateTime.utc(2026, 6, 8),
  );
}
