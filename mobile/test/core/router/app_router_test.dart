import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/auth/auth_session_events.dart';
import 'package:inflap/core/navigation/android_back_swipe_scope.dart';
import 'package:inflap/core/router/app_router.dart';
import 'package:inflap/core/storage/secure_storage.dart';
import 'package:inflap/features/feed/models/feed_block_vm.dart';
import 'package:inflap/features/feed/presentation/community_discovery_screen.dart';
import 'package:inflap/features/feed/presentation/community_members_screen.dart';
import 'package:inflap/features/feed/presentation/community_moderation_screen.dart';
import 'package:inflap/features/feed/presentation/community_profile_screen.dart';
import 'package:inflap/features/profile/models/user_profile_vm.dart';
import 'package:inflap/features/settings/presentation/app_settings_screen.dart';
import 'package:inflap/features/stories/editor/presentation/story_editor_trust_context.dart';
import 'package:inflap/features/stories/models/story_vm.dart';
import 'package:inflap/features/trust/providers/trust_access_provider.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/providers/activity_provider.dart';
import 'package:inflap/providers/auth_provider.dart';
import 'package:inflap/providers/locale_provider.dart';
import 'package:inflap/providers/session_provider.dart';
import 'package:inflap/providers/theme_mode_provider.dart';
import 'package:inflap/screens/activities/activity_details_screen.dart';
import 'package:inflap/screens/activities/create_activity_screen.dart';
import 'package:inflap/screens/stories/story_tray_viewer_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('keyboard focus is cleared when navigator route changes', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TextField(focusNode: focusNode)),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);

    KeyboardDismissRouteObserver().didPush(
      MaterialPageRoute<void>(builder: (_) => const SizedBox.shrink()),
      null,
    );
    await tester.pump();

    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets('activity details route keeps android back-swipe wrapper', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      secureStorage: _AuthenticatedSecureStorage(),
    );
    final sessionProvider = SessionProvider(
      secureStorage: _UnauthenticatedSecureStorage(),
    );
    final activityProvider = _NoopActivityProvider();
    await authProvider.checkAuthStatus();
    final router = AppRouter.router(authProvider);
    addTearDown(() {
      router.dispose();
      authProvider.dispose();
      sessionProvider.dispose();
      activityProvider.dispose();
    });

    router.go('/activities/activity-42');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<SessionProvider>.value(value: sessionProvider),
          ChangeNotifierProvider<ActivityProvider>.value(
            value: activityProvider,
          ),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AndroidBackSwipeScope),
        matching: find.byType(ActivityDetailsScreen),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'activity edit route without navigation extra falls back to details',
    (tester) async {
      final authProvider = AuthProvider(
        secureStorage: _AuthenticatedSecureStorage(),
      );
      final sessionProvider = SessionProvider(
        secureStorage: _UnauthenticatedSecureStorage(),
      );
      final activityProvider = _NoopActivityProvider();
      await authProvider.checkAuthStatus();
      final router = AppRouter.router(authProvider);
      addTearDown(() {
        router.dispose();
        authProvider.dispose();
        sessionProvider.dispose();
        activityProvider.dispose();
      });

      router.go('/activities/activity-42/edit');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<SessionProvider>.value(
              value: sessionProvider,
            ),
            ChangeNotifierProvider<ActivityProvider>.value(
              value: activityProvider,
            ),
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ActivityDetailsScreen), findsOneWidget);
      expect(find.byType(CreateActivityScreen), findsNothing);
    },
  );

  testWidgets('chat list route redirects unauthenticated users to login', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      secureStorage: _UnauthenticatedSecureStorage(),
    );
    await authProvider.checkAuthStatus();
    final router = AppRouter.router(authProvider);
    addTearDown(() {
      router.dispose();
      authProvider.dispose();
    });

    router.go('/chats');

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('login-form')), findsOneWidget);
  });

  testWidgets('app settings route is public for unauthenticated users', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final authProvider = AuthProvider(
      secureStorage: _UnauthenticatedSecureStorage(),
    );
    final localeProvider = LocaleProvider(systemLocales: const [Locale('en')]);
    final themeModeProvider = ThemeModeProvider();
    await authProvider.checkAuthStatus();
    await localeProvider.load();
    await themeModeProvider.load();
    final router = AppRouter.router(authProvider);
    addTearDown(() {
      router.dispose();
      authProvider.dispose();
      localeProvider.dispose();
      themeModeProvider.dispose();
    });

    router.go('/app-settings');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
          ChangeNotifierProvider<ThemeModeProvider>.value(
            value: themeModeProvider,
          ),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AndroidBackSwipeScope),
        matching: find.byType(AppSettingsScreen),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('login-form')), findsNothing);
  });

  testWidgets('community discovery and profile routes are public', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      secureStorage: _UnauthenticatedSecureStorage(),
    );
    await authProvider.checkAuthStatus();
    final router = AppRouter.router(authProvider);
    addTearDown(() {
      router.dispose();
      authProvider.dispose();
    });

    router.go('/communities');

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.descendant(
        of: find.byType(AndroidBackSwipeScope),
        matching: find.byType(CommunityDiscoveryScreen),
      ),
      findsOneWidget,
    );

    router.go('/communities/community-42', extra: _community('community-42'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.descendant(
        of: find.byType(AndroidBackSwipeScope),
        matching: find.byType(CommunityProfileScreen),
      ),
      findsOneWidget,
    );
  });

  testWidgets('community management routes stay protected', (tester) async {
    final authProvider = AuthProvider(
      secureStorage: _UnauthenticatedSecureStorage(),
    );
    await authProvider.checkAuthStatus();
    final router = AppRouter.router(authProvider);
    addTearDown(() {
      router.dispose();
      authProvider.dispose();
    });

    router.go('/communities/community-42/moderation?title=Community');

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('login-form')), findsOneWidget);
    expect(find.byType(CommunityModerationScreen), findsNothing);

    router.go('/communities/community-42/members?title=Community');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('login-form')), findsOneWidget);
    expect(find.byType(CommunityMembersScreen), findsNothing);
  });

  testWidgets('post create route forwards optional community id', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      secureStorage: _AuthenticatedSecureStorage(),
    );
    await authProvider.checkAuthStatus();
    final router = AppRouter.router(authProvider);
    addTearDown(() {
      router.dispose();
      authProvider.dispose();
    });

    router.go('/posts/create?communityId=community-42');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider(create: (_) => TrustAccessProvider()),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('create-story-screen-community-community-42')),
      findsOneWidget,
    );
  });

  testWidgets('post create route forwards community trust context', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      secureStorage: _AuthenticatedSecureStorage(),
    );
    await authProvider.checkAuthStatus();
    final router = AppRouter.router(authProvider);
    addTearDown(() {
      router.dispose();
      authProvider.dispose();
    });

    router.go(
      '/posts/create?communityId=community-42',
      extra: const StoryEditorTrustContext(
        kind: StoryEditorTrustBannerKind.blocked,
        title: 'Posting blocked',
        message: 'Moderator review is required before posting.',
        blocksPublishing: true,
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider(create: (_) => TrustAccessProvider()),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Posting blocked'), findsOneWidget);
    expect(
      find.text('Moderator review is required before posting.'),
      findsOneWidget,
    );
  });

  testWidgets('story tray viewer route opens publicly as the viewer', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      secureStorage: _UnauthenticatedSecureStorage(),
    );
    await authProvider.checkAuthStatus();
    final router = AppRouter.router(authProvider);
    addTearDown(() {
      router.dispose();
      authProvider.dispose();
    });

    router.go(
      '/stories/viewer',
      extra: StoryTrayViewerRouteData(
        stories: [_story('route-viewer')],
        initialIndex: 0,
      ),
    );

    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('story-sequence-viewer')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('story-sequence-title-route-viewer')),
      findsOneWidget,
    );
  });

  testWidgets('foreign profile is public but follower list is protected', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      secureStorage: _UnauthenticatedSecureStorage(),
    );
    final sessionProvider = SessionProvider(
      secureStorage: _UnauthenticatedSecureStorage(),
    );
    await authProvider.checkAuthStatus();
    final router = AppRouter.router(authProvider);
    addTearDown(() {
      router.dispose();
      authProvider.dispose();
      sessionProvider.dispose();
    });

    router.go('/users/foreign-user/profile', extra: _profile('foreign-user'));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<SessionProvider>.value(value: sessionProvider),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('profile-screen-foreign-user')),
      findsOneWidget,
    );

    router.go('/users/foreign-user/followers');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('login-form')), findsOneWidget);
  });

  testWidgets('services route opens the real services grid screen', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      secureStorage: _UnauthenticatedSecureStorage(),
    );
    await authProvider.checkAuthStatus();
    final router = AppRouter.router(authProvider);
    addTearDown(() {
      router.dispose();
      authProvider.dispose();
    });

    router.go('/services');

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('services-screen')), findsOneWidget);
  });

  testWidgets('expired session redirects from a public route to login', (
    tester,
  ) async {
    final events = AuthSessionEvents();
    final authProvider = AuthProvider(
      secureStorage: _AuthenticatedSecureStorage(),
      authSessionEvents: events,
    );
    await authProvider.checkAuthStatus();
    final router = AppRouter.router(authProvider);
    addTearDown(() async {
      router.dispose();
      authProvider.dispose();
      await events.dispose();
    });

    router.go('/services');

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('services-screen')), findsOneWidget);

    events.notifySessionExpired();
    await tester.pumpAndSettle();

    expect(authProvider.state, AuthState.sessionExpired);
    expect(find.byKey(const ValueKey('login-form')), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.queryParameters,
      containsPair('from', '/services'),
    );
    expect(
      router.routeInformationProvider.value.uri.queryParameters,
      containsPair('reason', 'session-expired'),
    );
  });
}

class _UnauthenticatedSecureStorage extends SecureStorage {
  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<String?> getRefreshToken() async => null;
}

class _AuthenticatedSecureStorage extends SecureStorage {
  @override
  Future<String?> getAccessToken() async => 'access-token';

  @override
  Future<String?> getRefreshToken() async => null;
}

class _NoopActivityProvider extends ActivityProvider {
  @override
  Future<void> loadActivityDetails(String activityId) async {}

  @override
  Future<void> loadActivityCategories({bool force = false}) async {}

  @override
  void clearSelectedActivity({String? activityId}) {}

  @override
  void resetActionState() {}
}

FeedCommunityVm _community(String id) {
  return FeedCommunityVm(
    id: id,
    title: 'Community $id',
    subtitle: 'Travel community',
    description: 'A community for route testing',
    topic: 'travel',
    membersCount: 12,
    postCount: 3,
  );
}

StoryVm _story(String id) {
  final now = DateTime.utc(2026, 1, 1);
  return StoryVm(
    id: id,
    slug: id,
    title: id,
    excerpt: 'Story $id',
    category: 'JOURNAL',
    status: 'PUBLISHED',
    tags: const ['travel'],
    stats: StoryStatsVm(views: 1, likes: 0, comments: 0, shares: 0),
    author: StoryAuthorVm(
      userId: 'user-$id',
      locale: 'en',
      timezone: 'Asia/Almaty',
      nickname: 'Author $id',
    ),
    likedByViewer: false,
    expiresAt: DateTime.utc(2027),
    shareUrl: 'https://inflap.test/stories/$id',
    createdAt: now,
    updatedAt: now,
  );
}

UserProfileVm _profile(String id) {
  return UserProfileVm(
    userId: id,
    status: 'ACTIVE',
    locale: 'en',
    timezone: 'Asia/Almaty',
    isProfileCompleted: true,
    roles: const [],
    followersCount: 0,
    isFollowedByMe: false,
    friendshipStatus: UserFriendshipStatus.none,
    nickname: 'User $id',
  );
}
