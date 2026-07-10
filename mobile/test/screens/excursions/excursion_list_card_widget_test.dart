import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/excursions/models/excursion_vm.dart';
import 'package:inflap/features/places/models/place_vm.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/screens/excursions/excursions_screen.dart';
import 'package:inflap/shared/reference/app_location_label_resolver.dart';

void main() {
  testWidgets(
    'excursion list card stays within compact grid cell and exposes semantics',
    (tester) async {
      var tapped = false;

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
            body: Center(
              child: SizedBox(
                width: 160,
                height: 236,
                child: ExcursionListCard(
                  excursion: _longExcursion,
                  languageCode: 'en',
                  seed: 7,
                  onTap: () => tapped = true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ExcursionListCard));
      expect(tapped, isTrue);

      final semanticsData = tester
          .getSemantics(find.byType(ExcursionListCard))
          .getSemanticsData();
      expect(semanticsData.hasAction(SemanticsAction.tap), isTrue);
      expect(semanticsData.label, contains('Long compact-grid excursion'));
    },
  );

  testWidgets('shows the real excursion rating when reviews exist', (
    tester,
  ) async {
    await _pumpCard(tester, ratingAvg: 4.6, reviewsCount: 8);

    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.text('4.6'), findsOneWidget);
    expect(find.text('4.9'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides rating badge when the excursion has no reviews', (
    tester,
  ) async {
    await _pumpCard(tester, ratingAvg: 4.9, reviewsCount: 0);

    expect(find.byIcon(Icons.star_rounded), findsNothing);
    expect(find.text('4.9'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a localized title for a combined route', (tester) async {
    await _pumpCard(
      tester,
      ratingAvg: 0,
      reviewsCount: 0,
      excursion: _combinedRoute,
      localizedPlacesById: {
        'bozjyra': _routePlace('bozjyra', 'Bozjyra Tract'),
        'charyn': _routePlace('charyn', 'Charyn Canyon'),
      },
    );

    expect(find.text('Bozjyra Tract + Charyn Canyon'), findsOneWidget);
    expect(find.text(_combinedRoute.title), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the departure city in the app locale', (tester) async {
    await _pumpCard(
      tester,
      ratingAvg: 0,
      reviewsCount: 0,
      excursion: _excursionWithRussianCity,
      locationLabelResolver: _EnglishAlmatyResolver(),
    );

    expect(find.text('Almaty'), findsOneWidget);
    expect(find.text('Алматы'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resolves the city when only departureCityId is stored', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      ratingAvg: 0,
      reviewsCount: 0,
      excursion: _excursionWithCityIdOnly,
      locationLabelResolver: _EnglishAlmatyResolver(),
    );

    expect(find.text('Almaty'), findsOneWidget);
    expect(find.text('Adventure'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpCard(
  WidgetTester tester, {
  required double ratingAvg,
  required int reviewsCount,
  ExcursionVm? excursion,
  Map<String, PlaceVm> localizedPlacesById = const {},
  AppLocationLabelResolver? locationLabelResolver,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));

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
        body: Center(
          child: SizedBox(
            width: 220,
            height: 320,
            child: ExcursionListCard(
              excursion:
                  excursion ??
                  ExcursionVm(
                    id: 'product-1',
                    title: 'Mountain trail',
                    summary: 'Scenic route',
                    status: 'PUBLISHED',
                    visibility: 'PUBLIC',
                    priceAmount: 12000,
                    currency: 'KZT',
                    cityName: 'Almaty',
                    durationMinutes: 180,
                    ratingAvg: ratingAvg,
                    reviewsCount: reviewsCount,
                  ),
              languageCode: 'en',
              localizedPlacesById: localizedPlacesById,
              locationLabelResolver: locationLabelResolver,
              seed: 0,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _longExcursion = ExcursionVm(
  id: 'excursion-compact-card',
  title: 'Long compact-grid excursion through old city and mountain viewpoints',
  summary: 'Compact responsive card regression fixture',
  categorySlug: 'culture',
  durationMinutes: 480,
  maxGroupSize: 12,
  languageCodes: ['en', 'ru', 'kk'],
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  priceAmount: 250000,
  currency: 'KZT',
  cityName: 'Almaty',
  landmarkName: 'Long compact-grid excursion',
);

const _combinedRoute = ExcursionVm(
  id: 'combined-route',
  title: 'Урочище Бозжыра + Чарынский каньон',
  summary: 'Составной маршрут',
  routeKind: 'COMBINED_ROUTE',
  placeIds: ['bozjyra', 'charyn'],
  placeNames: ['Урочище Бозжыра', 'Чарынский каньон'],
  stopCount: 2,
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  priceAmount: 12000,
  currency: 'KZT',
  cityName: 'Almaty',
  durationMinutes: 240,
);

const _excursionWithRussianCity = ExcursionVm(
  id: 'localized-city',
  title: 'Mountain trail',
  summary: 'Scenic route',
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  priceAmount: 12000,
  currency: 'KZT',
  countryCode: 'KZ',
  cityName: 'Алматы',
  departureCityId: 'almaty',
  durationMinutes: 180,
);

const _excursionWithCityIdOnly = ExcursionVm(
  id: 'localized-city-id-only',
  title: 'Mountain trail',
  summary: 'Scenic route',
  categorySlug: 'adventure',
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  priceAmount: 12000,
  currency: 'KZT',
  countryCode: 'KZ',
  departureCityId: 'almaty',
  durationMinutes: 180,
);

PlaceVm _routePlace(String id, String title) {
  return PlaceVm.fromJson({
    'id': id,
    'locale': 'en',
    'defaultLocale': 'ru',
    'title': title,
    'description': '',
    'translations': {
      'en': {'title': title, 'description': ''},
    },
  });
}

class _EnglishAlmatyResolver extends AppLocationLabelResolver {
  @override
  Future<String> resolve({
    String? countryCode,
    String? cityId,
    String? cityName,
    required String localeName,
  }) async {
    return 'Almaty, Kazakhstan';
  }
}
