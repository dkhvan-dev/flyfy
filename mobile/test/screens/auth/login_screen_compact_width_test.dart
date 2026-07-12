import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/providers/auth_provider.dart';
import 'package:inflap/providers/session_provider.dart';
import 'package:inflap/screens/auth/login_screen.dart';
import 'package:provider/provider.dart';

void main() {
  Widget buildTestApp({bool initialRegister = false}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: LoginScreen(initialRegister: initialRegister),
      ),
    );
  }

  testWidgets('auth form does not use horizontal scrolling on compact width', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildTestApp());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.horizontal,
      ),
      findsNothing,
    );
  });

  testWidgets('auth form titles do not show subtitle text', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();

    final l10n = AppLocalizations.of(tester.element(find.byType(LoginScreen)))!;

    expect(find.text(l10n.authLoginTitle), findsOneWidget);
    expect(find.text(l10n.welcomeDescription), findsNothing);

    await tester.tap(find.text(l10n.authRegisterTab));
    await tester.pumpAndSettle();

    expect(find.text(l10n.authRegisterTitle), findsOneWidget);
    expect(find.text(l10n.welcomeDescription), findsNothing);
  });

  testWidgets('registration deep link opens the registration tab', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp(initialRegister: true));
    await tester.pump();

    final l10n = AppLocalizations.of(tester.element(find.byType(LoginScreen)))!;
    expect(find.text(l10n.authRegisterTitle), findsOneWidget);
    expect(find.text(l10n.authLoginTitle), findsNothing);
  });

  testWidgets('auth header settings button opens public app settings', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/app-settings',
          builder: (context, state) =>
              const Scaffold(body: Text('Public app settings')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => SessionProvider()),
        ],
        child: MaterialApp.router(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('auth-app-settings-button')));
    await tester.pumpAndSettle();

    expect(find.text('Public app settings'), findsOneWidget);
  });
}
