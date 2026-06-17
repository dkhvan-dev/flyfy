import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/providers/auth_provider.dart';
import 'package:inflap/providers/session_provider.dart';
import 'package:inflap/screens/auth/login_screen.dart';
import 'package:provider/provider.dart';

void main() {
  Widget buildTestApp() {
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
        home: const LoginScreen(),
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
}
