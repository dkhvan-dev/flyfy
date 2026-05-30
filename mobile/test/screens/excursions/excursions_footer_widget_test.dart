import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/screens/excursions/excursions_screen.dart';

void main() {
  testWidgets('shows create action in footer only for guide users', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          bottomNavigationBar: ExcursionsBottomNavigation(
            canCreateExcursion: true,
            onCreateExcursionTap: () {},
            onMapTap: () {},
            onHomeTap: () {},
            onQrTap: () {},
            onServicesTap: () {},
            onChatsTap: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.byIcon(Icons.map_outlined), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          bottomNavigationBar: ExcursionsBottomNavigation(
            canCreateExcursion: false,
            onCreateExcursionTap: () {},
            onMapTap: () {},
            onHomeTap: () {},
            onQrTap: () {},
            onServicesTap: () {},
            onChatsTap: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.add_rounded), findsNothing);
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
  });
}
