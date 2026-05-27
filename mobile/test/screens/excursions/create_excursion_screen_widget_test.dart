import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:superapp/core/network/excursion_api.dart';
import 'package:superapp/features/excursions/models/create_excursion_request.dart';
import 'package:superapp/features/excursions/models/excursion_vm.dart';
import 'package:superapp/l10n/generated/app_localizations.dart';
import 'package:superapp/providers/excursion_provider.dart';
import 'package:superapp/providers/home_location_provider.dart';
import 'package:superapp/screens/excursions/create_excursion_screen.dart';

void main() {
  testWidgets('renders the create excursion landmark step', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ExcursionProvider()),
          ChangeNotifierProvider(create: (_) => HomeLocationProvider()),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: CreateExcursionScreen(),
        ),
      ),
    );

    expect(find.text('Create Excursion'), findsOneWidget);
    expect(find.text('Attraction'), findsOneWidget);
    expect(find.text('Country'), findsNothing);
    expect(find.text('Select Attraction'), findsOneWidget);
    expect(find.text('Next Step'), findsOneWidget);
  });

  testWidgets(
    'opens edit mode with initial excursion after localizations are ready',
    (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => ExcursionProvider(
                excursionApi: _FakeExcursionApi(_editableExcursion),
              ),
            ),
            ChangeNotifierProvider(create: (_) => HomeLocationProvider()),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: CreateExcursionScreen(
              excursionId: 'excursion-edit',
              initialExcursion: _editableExcursion,
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

class _FakeExcursionApi extends ExcursionApi {
  _FakeExcursionApi(this.excursion);

  final ExcursionVm excursion;

  @override
  Future<ExcursionVm> getMyExcursion(String excursionId) async {
    return excursion;
  }

  @override
  Future<ExcursionVm> updateExcursionOffer(
    String legacyExcursionId,
    CreateExcursionRequest request,
  ) async {
    return excursion;
  }
}

const _editableExcursion = ExcursionVm(
  id: 'excursion-edit',
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
    ExcursionItineraryItemVm(
      id: 'step-1',
      sortOrder: 0,
      startOffsetMinutes: 0,
      durationMinutes: 30,
      title: 'Hotel pickup',
      description: 'Meet your guide.',
    ),
  ],
);
