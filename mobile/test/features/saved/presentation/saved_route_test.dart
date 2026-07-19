import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/navigation/android_back_swipe_scope.dart';
import 'package:inflap/core/router/app_router.dart';
import 'package:inflap/core/storage/secure_storage.dart';
import 'package:inflap/features/saved/presentation/saved_collections_screen.dart';
import 'package:inflap/features/saved/presentation/saved_screen.dart';
import 'package:inflap/features/saved/presentation/state/saved_screen_controller.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/providers/auth_provider.dart';
import 'package:provider/provider.dart';

import '../support/saved_test_fakes.dart';

void main() {
  testWidgets('Saved route is authenticated and keeps Android back wrapper', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      secureStorage: _TestSecureStorage(authenticated: true),
    );
    await authProvider.checkAuthStatus();
    final controller = SavedScreenController(
      repository: FakeSavedFeatureRepository(),
    );
    final router = AppRouter.router(authProvider)..go('/profile/saved');
    addTearDown(() {
      router.dispose();
      authProvider.dispose();
      controller.dispose();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<SavedScreenController>.value(
            value: controller,
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
        matching: find.byType(SavedScreen),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'Collections route is authenticated and keeps Android back wrapper',
    (tester) async {
      final authProvider = AuthProvider(
        secureStorage: _TestSecureStorage(authenticated: true),
      );
      await authProvider.checkAuthStatus();
      final controller = SavedScreenController(
        repository: FakeSavedFeatureRepository(),
      );
      final router = AppRouter.router(authProvider)
        ..go('/profile/saved/collections');
      addTearDown(() {
        router.dispose();
        authProvider.dispose();
        controller.dispose();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<SavedScreenController>.value(
              value: controller,
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
          matching: find.byType(SavedCollectionsScreen),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('unauthenticated deep link redirects to login', (tester) async {
    final authProvider = AuthProvider(
      secureStorage: _TestSecureStorage(authenticated: false),
    );
    await authProvider.checkAuthStatus();
    final controller = SavedScreenController(
      repository: FakeSavedFeatureRepository(),
    );
    final router = AppRouter.router(authProvider)
      ..go('/profile/saved/collections');
    addTearDown(() {
      router.dispose();
      authProvider.dispose();
      controller.dispose();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<SavedScreenController>.value(
            value: controller,
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

    expect(find.byKey(const ValueKey('login-form')), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.queryParameters['from'],
      '/profile/saved/collections',
    );
  });
}

final class _TestSecureStorage extends SecureStorage {
  _TestSecureStorage({required this.authenticated});

  final bool authenticated;

  @override
  Future<String?> getAccessToken() async =>
      authenticated ? 'access-token' : null;

  @override
  Future<String?> getRefreshToken() async => null;
}
