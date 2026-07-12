import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:inflap/core/network/excursion_api.dart';
import 'package:inflap/core/network/reference_api.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:inflap/features/currency/data/currency_api.dart';
import 'package:inflap/features/currency/data/currency_catalog_repository.dart';
import 'package:inflap/features/currency/models/currency_conversion_result.dart';
import 'package:inflap/features/places/data/place_api.dart';
import 'package:inflap/features/places/models/place_vm.dart';
import 'package:inflap/features/excursions/models/create_excursion_request.dart';
import 'package:inflap/features/excursions/models/excursion_vm.dart';
import 'package:inflap/features/trust/providers/trust_access_provider.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/providers/excursion_provider.dart';
import 'package:inflap/providers/home_location_provider.dart';
import 'package:inflap/shared/reference/app_location_label_resolver.dart';
import 'package:inflap/screens/excursions/create_excursion_screen.dart';
import 'package:inflap/screens/excursions/excursion_select_location_screen.dart';

void main() {
  testWidgets('renders the create excursion landmark step', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ExcursionProvider()),
          ChangeNotifierProvider(create: (_) => HomeLocationProvider()),
          ChangeNotifierProvider(create: (_) => TrustAccessProvider()),
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
    expect(find.text('Place'), findsOneWidget);
    expect(find.text('Country'), findsNothing);
    expect(find.text('Select place'), findsOneWidget);
    expect(find.text('Next Step'), findsOneWidget);
  });

  testWidgets(
    'itinerary sheet reaches screen bottom and keeps confirm above Android navigation',
    (tester) async {
      const navigationBarHeight = 48.0;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ExcursionProvider()),
            ChangeNotifierProvider(create: (_) => HomeLocationProvider()),
            ChangeNotifierProvider(create: (_) => TrustAccessProvider()),
          ],
          child: MaterialApp(
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  padding: const EdgeInsets.only(bottom: navigationBarHeight),
                  viewPadding: const EdgeInsets.only(
                    bottom: navigationBarHeight,
                  ),
                ),
                child: child!,
              );
            },
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const CreateExcursionScreen(),
          ),
        ),
      );
      await tester.pump();

      final addSlot = find.text('Add Time Slot');
      await tester.drag(find.byType(ListView).first, const Offset(0, -700));
      await tester.pump();
      expect(addSlot, findsOneWidget);
      await tester.tap(addSlot);
      await tester.pumpAndSettle();

      final surface = find.byKey(
        const ValueKey('app-modal-custom-sheet-surface'),
      );
      final confirm = find.byKey(
        const ValueKey('excursion-itinerary-slot-confirm'),
      );
      expect(surface, findsOneWidget);
      expect(confirm, findsOneWidget);
      expect(tester.getBottomRight(surface).dy, closeTo(844, 0.1));
      expect(
        tester.getBottomRight(confirm).dy,
        lessThanOrEqualTo(844 - navigationBarHeight),
      );
    },
  );

  testWidgets(
    'currency and included sheets reach bottom while content clears Android navigation',
    (tester) async {
      const navigationBarHeight = 48.0;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final currencyCatalogRepository = CurrencyCatalogRepository(
        api: _FakeCurrencyApi(),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => ExcursionProvider(
                excursionApi: _FakeExcursionApi(_editableExcursion),
              ),
            ),
            ChangeNotifierProvider(create: (_) => HomeLocationProvider()),
            ChangeNotifierProvider(create: (_) => TrustAccessProvider()),
          ],
          child: MaterialApp(
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  padding: const EdgeInsets.only(bottom: navigationBarHeight),
                  viewPadding: const EdgeInsets.only(
                    bottom: navigationBarHeight,
                  ),
                ),
                child: child!,
              );
            },
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: CreateExcursionScreen(
              excursionId: 'excursion-edit',
              initialExcursion: _editableExcursion,
              currencyCatalogRepository: currencyCatalogRepository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next Step'));
      await tester.pumpAndSettle();
      expect(find.text('Max Group Size'), findsOneWidget);
      await tester.tap(find.text('Next Step'));
      await tester.pumpAndSettle();
      expect(find.text('Investment Per Person'), findsOneWidget);

      final storyAndPriceList = find.ancestor(
        of: find.text('Investment Per Person'),
        matching: find.byType(ListView),
      );
      expect(storyAndPriceList, findsOneWidget);
      await tester.drag(storyAndPriceList, const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.text('Currency'), findsOneWidget);
      await tester.tap(find.text('tenge'));
      await tester.pumpAndSettle();

      final currencySurface = find.byKey(
        const ValueKey('app-modal-custom-sheet-surface'),
      );
      expect(currencySurface, findsOneWidget);
      expect(tester.getBottomRight(currencySurface).dy, closeTo(844, 0.1));
      expect(
        tester.getBottomRight(find.byType(ListTile).last).dy,
        lessThanOrEqualTo(844 - navigationBarHeight),
      );

      await tester.tap(find.text('US dollar'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Included Items'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();

      final includedSurface = find.byKey(
        const ValueKey('app-modal-custom-sheet-surface'),
      );
      final includedSave = find.byKey(
        const ValueKey('excursion-included-items-save'),
      );
      expect(includedSurface, findsOneWidget);
      expect(includedSave, findsOneWidget);
      expect(tester.getBottomRight(includedSurface).dy, closeTo(844, 0.1));
      expect(
        tester.getBottomRight(includedSave).dy,
        lessThanOrEqualTo(844 - navigationBarHeight),
      );
    },
  );

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
            ChangeNotifierProvider(create: (_) => TrustAccessProvider()),
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

  testWidgets('place selector cards do not overflow on compact width', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ExcursionSelectLocationScreen(
          countryCode: 'KZ',
          api: _FakePlaceApi([
            _place(
              id: 'place-short',
              title: 'Чарынский каньон',
              category: 'NATURE',
            ),
            _place(
              id: 'place-long',
              title: 'Национальный парк\nАлтын-Эмель',
              category: 'TEMPLE',
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Национальный парк'), findsOneWidget);
    expect(find.text('ПРИРОДА'), findsOneWidget);
    expect(find.text('ХРАМЫ'), findsOneWidget);
    expect(find.text('NATURE'), findsNothing);
    expect(find.text('TEMPLE'), findsNothing);
    expect(find.text('Выбрать'), findsNWidgets(2));

    final cardFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Material && widget.color == AppColorSchemes.light.surface,
    );
    expect(cardFinder, findsNWidgets(2));

    final selectButtons = find.text('Выбрать');
    final firstButton = find.ancestor(
      of: selectButtons.at(0),
      matching: find.byType(AnimatedContainer),
    );
    final secondButton = find.ancestor(
      of: selectButtons.at(1),
      matching: find.byType(AnimatedContainer),
    );
    expect(firstButton, findsOneWidget);
    expect(secondButton, findsOneWidget);

    final firstButtonTop = tester.getTopLeft(firstButton).dy;
    final secondButtonTop = tester.getTopLeft(secondButton).dy;
    expect((firstButtonTop - secondButtonTop).abs(), lessThanOrEqualTo(1));

    final firstTitleTop = tester.getTopLeft(find.text('Чарынский каньон')).dy;
    final secondTitleTop = tester
        .getTopLeft(find.textContaining('Национальный парк'))
        .dy;
    expect((firstTitleTop - secondTitleTop).abs(), lessThanOrEqualTo(1));
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Align && widget.alignment == Alignment.bottomLeft,
      ),
      findsNothing,
    );

    final firstTitleBottom = tester
        .getBottomLeft(find.text('Чарынский каньон'))
        .dy;
    final secondTitleBottom = tester
        .getBottomLeft(find.textContaining('Национальный парк'))
        .dy;
    expect(firstButtonTop - firstTitleBottom, lessThanOrEqualTo(24));
    expect(secondButtonTop - secondTitleBottom, lessThanOrEqualTo(24));

    final firstBottomGap =
        tester.getBottomLeft(cardFinder.at(0)).dy -
        tester.getBottomLeft(firstButton).dy;
    final secondBottomGap =
        tester.getBottomLeft(cardFinder.at(1)).dy -
        tester.getBottomLeft(secondButton).dy;
    expect(firstBottomGap, lessThanOrEqualTo(14));
    expect(secondBottomGap, lessThanOrEqualTo(14));

    final firstCardTop = tester.getTopLeft(cardFinder.at(0)).dy;
    final firstCardHeight = tester.getSize(cardFinder.at(0)).height;
    final secondCardTop = tester.getTopLeft(cardFinder.at(1)).dy;
    final secondCardHeight = tester.getSize(cardFinder.at(1)).height;
    final firstCategoryTop = tester.getTopLeft(find.text('ПРИРОДА')).dy;
    final secondCategoryTop = tester.getTopLeft(find.text('ХРАМЫ')).dy;

    expect(firstCategoryTop, lessThan(firstTitleTop));
    expect(secondCategoryTop, lessThan(secondTitleTop));
    expect(firstCategoryTop, lessThan(firstCardTop + firstCardHeight * 0.5));
    expect(secondCategoryTop, lessThan(secondCardTop + secondCardHeight * 0.5));
  });

  testWidgets('place selector two-column cards fit on 360dp Android width', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);

    final flutterErrors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = flutterErrors.add;
    addTearDown(() => FlutterError.onError = previousOnError);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ExcursionSelectLocationScreen(
          countryCode: 'KZ',
          api: _FakePlaceApi([
            _place(
              id: 'place-long-first',
              title: 'Национальный парк Алтын-Эмель',
              category: 'historical_site',
            ),
            _place(
              id: 'place-long-second',
              title: 'Большое Алматинское озеро',
              category: 'nature',
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    FlutterError.onError = previousOnError;
    final overflowErrors = flutterErrors.where(
      (details) => details.exceptionAsString().contains('overflowed'),
    );
    expect(overflowErrors, isEmpty);
    expect(find.text('Выбрать'), findsNWidgets(2));
  });

  testWidgets('location selector returns localized city name for place', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    ExcursionLocationSelection? selectedLocation;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            return Material(
              child: Center(
                child: FilledButton(
                  onPressed: () async {
                    selectedLocation = await context
                        .push<ExcursionLocationSelection>('/select');
                  },
                  child: const Text('Open selector'),
                ),
              ),
            );
          },
        ),
        GoRoute(
          path: '/select',
          builder: (context, state) {
            return ExcursionSelectLocationScreen(
              countryCode: 'KZ',
              api: _FakePlaceApi([
                _place(
                  id: 'place-short',
                  title: 'Чарынский каньон',
                  category: 'NATURE',
                ),
              ]),
              locationLabelResolver: AppLocationLabelResolver(
                api: _FakeReferenceApi(),
              ),
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('ru'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open selector'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Выбрать'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ПОДТВЕРДИТЬ'));
    await tester.pumpAndSettle();

    expect(selectedLocation?.cityId, 'almaty');
    expect(selectedLocation?.cityName, 'Алматы');
  });
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

class _FakePlaceApi extends PlaceApi {
  _FakePlaceApi(this.items);

  final List<PlaceVm> items;

  @override
  Future<({List<PlaceVm> items, int total})> getPlaces({
    String? search,
    String? category,
    String? countryCode,
    String? cityId,
    String? accessCityId,
    double? priceMin,
    double? priceMax,
    int? durationMin,
    int? durationMax,
    String? durationUnit,
    int? spotsMin,
    double? minRating,
    String? sort,
    String? locale,
    double? latitude,
    double? longitude,
    int limit = 20,
    int offset = 0,
  }) async {
    return (items: items, total: items.length);
  }
}

class _FakeReferenceApi extends ReferenceApi {
  @override
  Future<ReferenceCity?> getCity(String id, {String lang = 'en'}) async {
    if (id.trim() != 'almaty') return null;
    return ReferenceCity(
      id: 'almaty',
      countryCode: 'KZ',
      name: lang == 'ru' ? 'Алматы' : 'Almaty',
    );
  }
}

class _FakeCurrencyApi extends CurrencyApi {
  @override
  Future<List<CurrencyOption>> listCurrencies({String? locale}) async {
    return defaultCurrencyOptions;
  }
}

const _editableExcursion = ExcursionVm(
  id: 'excursion-edit',
  title: 'Charyn Canyon',
  summary: 'Shared route',
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  landmarkId: 'place-1',
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
    ExcursionItineraryItemVm(
      id: 'step-2',
      sortOrder: 1,
      startOffsetMinutes: 30,
      durationMinutes: 90,
      title: 'Canyon walk',
      description: 'Explore the canyon with your guide.',
    ),
  ],
);

PlaceVm _place({
  String id = 'place-compact',
  required String title,
  String category = 'nature',
}) {
  return PlaceVm(
    id: id,
    locale: 'en',
    defaultLocale: 'en',
    title: title,
    description: 'A compact selector test place.',
    countryCode: 'KZ',
    cityId: 'almaty',
    latitude: 43.238,
    longitude: 76.945,
    locationSourceUrl: 'https://maps.example.test/place-compact',
    category: category,
    rating: 4.8,
    reviewCount: 12,
    source: 'manual',
    status: 'published',
    tags: const [],
    visitInfo: PlaceVisitInfoVm.empty,
    translations: const {},
    media: const [],
    author: const PlaceAuthorVm(userId: 'author-1'),
    createdAt: '2026-06-17T00:00:00Z',
    updatedAt: '2026-06-17T00:00:00Z',
  );
}
