import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:inflap/features/profile/models/user_profile_vm.dart';
import 'package:inflap/features/trust/providers/trust_access_provider.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/providers/session_provider.dart';
import 'package:inflap/screens/profile/profile_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('My journey Saved tile opens the production Saved route', (
    tester,
  ) async {
    final session = _ProfileSessionProvider(_profile);
    final trust = TrustAccessProvider();
    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
        GoRoute(
          path: '/profile/saved',
          builder: (_, _) => const Scaffold(
            body: SizedBox(key: ValueKey('saved-route-target')),
          ),
        ),
      ],
    );
    addTearDown(() {
      router.dispose();
      session.dispose();
      trust.dispose();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SessionProvider>.value(value: session),
          ChangeNotifierProvider<TrustAccessProvider>.value(value: trust),
        ],
        child: MaterialApp.router(
          theme: AppDesignSystem.lightTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    final tile = find.byKey(const ValueKey('profile-saved-items-tile'));
    await tester.scrollUntilVisible(
      tile,
      420,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(tile, findsOneWidget);
    expect(
      find.descendant(
        of: tile,
        matching: find.text(
          'Activities, people, places, and your private collections',
        ),
      ),
      findsOneWidget,
    );
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('saved-route-target')), findsOneWidget);
  });
}

final class _ProfileSessionProvider extends SessionProvider {
  _ProfileSessionProvider(this._testProfile);

  final UserProfileVm _testProfile;

  @override
  UserProfileVm? get profile => _testProfile;

  @override
  bool get isAuthenticated => true;
}

final _profile = UserProfileVm(
  userId: '11111111-2222-4333-8444-555555555555',
  status: 'ACTIVE',
  locale: 'en',
  timezone: 'Asia/Almaty',
  isProfileCompleted: true,
  roles: const [],
  followersCount: 0,
  isFollowedByMe: false,
  friendshipStatus: UserFriendshipStatus.none,
  nickname: 'Saved Tester',
);
