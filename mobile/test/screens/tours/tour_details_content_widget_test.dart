import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/features/tours/models/tour_vm.dart';
import 'package:superapp/l10n/generated/app_localizations.dart';
import 'package:superapp/screens/tours/tour_details_screen.dart';

void main() {
  testWidgets('renders tour details content and booking CTA', (tester) async {
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
          body: TourDetailsContent(
            tour: _tour,
            onBookTap: () {},
            onMessageGuideTap: () {},
            guideName: 'Aruzhan Guide',
            guideAvatarFallbackText: 'AG',
            showMessageGuide: true,
            showBookingAction: true,
          ),
        ),
      ),
    );

    expect(find.text('Almaty Mountain Escape'), findsWidgets);
    expect(find.text('A private alpine route through Shymbulak and Medeu.'),
        findsOneWidget);
    expect(find.text('English', findRichText: true), findsOneWidget);
    expect(find.text('Aruzhan Guide'), findsOneWidget);
    expect(find.text('Message Guide'), findsOneWidget);
    expect(find.text('Private SUV'), findsOneWidget);
    expect(find.text('Hotel departure'), findsOneWidget);
    expect(find.text('Book'), findsOneWidget);
  });

  testWidgets('hides guide message action for author view', (tester) async {
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
          body: TourDetailsContent(
            tour: _tour,
            onBookTap: () {},
            onMessageGuideTap: () {},
            guideName: 'Aruzhan Guide',
            guideAvatarFallbackText: 'AG',
            showMessageGuide: false,
            showBookingAction: false,
          ),
        ),
      ),
    );

    expect(find.text('Aruzhan Guide'), findsOneWidget);
    expect(find.text('Message Guide'), findsNothing);
    expect(find.text('Book'), findsNothing);
  });
}

const _tour = TourVm(
  id: 'tour-1',
  title: 'Almaty Mountain Escape',
  summary: 'Private mountain route',
  description: 'A private alpine route through Shymbulak and Medeu.',
  categorySlug: 'adventure',
  durationMinutes: 480,
  maxGroupSize: 4,
  languageCodes: ['en'],
  includedItems: ['Private SUV'],
  itinerary: [
    TourItineraryItemVm(
      id: 'step-1',
      sortOrder: 0,
      startOffsetMinutes: 0,
      durationMinutes: 45,
      title: 'Hotel departure',
      description: 'Luxury SUV pickup from your hotel.',
    ),
  ],
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  priceAmount: 240,
  currency: 'USD',
  cityName: 'Almaty',
  meetingPoint: 'Hotel pickup',
);
