import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:superapp/l10n/generated/app_localizations.dart';
import 'package:superapp/providers/tour_provider.dart';
import 'package:superapp/screens/tours/create_tour_screen.dart';

void main() {
  testWidgets('renders the create tour landmark step', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TourProvider(),
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: CreateTourScreen(),
        ),
      ),
    );

    expect(find.text('Create Tour'), findsOneWidget);
    expect(find.text('Selected Landmark'), findsOneWidget);
    expect(find.text('Tour Cover'), findsOneWidget);
    expect(find.text('Next Step'), findsOneWidget);
    expect(
      find.text('Travel Categorization', skipOffstage: false),
      findsOneWidget,
    );
  });
}
