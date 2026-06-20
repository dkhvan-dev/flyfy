import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/providers/auth_provider.dart';
import 'package:inflap/providers/session_provider.dart';
import 'package:inflap/screens/auth/otp_screen.dart';

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
        home: const OtpScreen(phone: '+77000000001'),
      ),
    );
  }

  testWidgets('starts countdown on open and stops at zero', (tester) async {
    await tester.pumpWidget(buildTestApp());

    expect(find.text('01:00'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:59'), findsOneWidget);

    await tester.pump(const Duration(seconds: 59));
    expect(find.text('00:00'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    expect(find.text('00:00'), findsOneWidget);
  });

  testWidgets('cancels countdown when screen is disposed', (tester) async {
    await tester.pumpWidget(buildTestApp());
    expect(find.text('01:00'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });
}
