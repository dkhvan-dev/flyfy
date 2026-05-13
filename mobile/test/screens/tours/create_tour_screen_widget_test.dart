import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:superapp/core/network/tour_api.dart';
import 'package:superapp/features/tours/models/create_tour_request.dart';
import 'package:superapp/features/tours/models/tour_vm.dart';
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
    expect(find.text('Country'), findsOneWidget);
    expect(find.text('Tour Cover'), findsOneWidget);
    expect(find.text('Next Step'), findsOneWidget);
  });

  testWidgets(
    'opens edit mode with initial tour after localizations are ready',
    (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => TourProvider(tourApi: _FakeTourApi(_editableTour)),
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: CreateTourScreen(
              tourId: 'tour-edit',
              initialTour: _editableTour,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Edit Offer'), findsOneWidget);
    },
  );
}

class _FakeTourApi extends TourApi {
  _FakeTourApi(this.tour);

  final TourVm tour;

  @override
  Future<TourVm> getMyTour(String tourId) async {
    return tour;
  }

  @override
  Future<TourVm> updateTourOffer(
    String legacyTourId,
    CreateTourRequest request,
  ) async {
    return tour;
  }
}

const _editableTour = TourVm(
  id: 'tour-edit',
  title: 'Charyn Canyon',
  summary: 'Shared route',
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  landmarkId: 'attraction-1',
  landmarkName: 'Charyn Canyon',
  categorySlug: 'nature',
  durationMinutes: 240,
  maxGroupSize: 8,
  languageCodes: ['en'],
  countryCode: 'KZ',
  cityName: 'Almaty',
  meetingPoint: 'Hotel pickup',
  priceAmount: 120,
  currency: 'KZT',
  itinerary: [
    TourItineraryItemVm(
      id: 'step-1',
      sortOrder: 0,
      startOffsetMinutes: 0,
      durationMinutes: 30,
      title: 'Hotel pickup',
      description: 'Meet your guide.',
    ),
  ],
);
