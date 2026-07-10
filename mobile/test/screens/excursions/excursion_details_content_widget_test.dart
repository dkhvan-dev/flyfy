import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:inflap/features/profile/models/user_profile_vm.dart';
import 'package:inflap/features/excursions/models/excursion_vm.dart';
import 'package:inflap/features/places/models/place_vm.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/screens/excursions/excursion_details_screen.dart';
import 'package:inflap/shared/reference/app_location_label_resolver.dart';

void main() {
  testWidgets('renders excursion details content and booking CTA', (
    tester,
  ) async {
    ExcursionOfferVm? selectedOffer = _excursion.offers.first;

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
          body: ExcursionDetailsContent(
            excursion: _excursion,
            selectedOffer: selectedOffer,
            offerProfiles: {
              'guide-user-1': _guideProfile1,
              'guide-user-2': _guideProfile2,
            },
            onBookTap: () {},
            onEditOfferTap: () {},
            onMessageGuideTap: () {},
            onOfferSelected: (offer) => selectedOffer = offer,
            onOfferProfileTap: (_) {},
            showMessageGuide: true,
            showBookingAction: true,
          ),
        ),
      ),
    );

    expect(find.text('Almaty Mountain Escape'), findsWidgets);
    expect(
      find.text('A private alpine route through Shymbulak and Medeu.'),
      findsOneWidget,
    );
    expect(find.text('English', findRichText: true), findsWidgets);
    expect(find.text('Sadykova A.', skipOffstage: false), findsOneWidget);
    expect(find.text('Baimukhan N.', skipOffstage: false), findsOneWidget);
    expect(find.text('Guide #1'), findsNothing);
    expect(find.text('Guide #2'), findsNothing);
    expect(find.text('Message Guide'), findsOneWidget);
    expect(find.text('Available guides'), findsOneWidget);
    expect(find.text('Private SUV'), findsOneWidget);
    expect(find.text('Hotel departure'), findsOneWidget);
    expect(find.text('Book'), findsOneWidget);

    final profileButtonFinder = find.byKey(
      const ValueKey('excursion-guide-profile-action'),
    );
    expect(profileButtonFinder, findsOneWidget);
    final profileButton = tester.widget<OutlinedButton>(profileButtonFinder);
    final profileBorder = profileButton.style?.side?.resolve(
      const <WidgetState>{},
    );
    final profileButtonColors = AppDesignSystem.colorsFor(
      tester.element(profileButtonFinder),
    );
    expect(profileBorder?.color, profileButtonColors.border);
    expect(profileBorder?.width, 1.2);

    await tester.ensureVisible(find.text('Baimukhan N.', skipOffstage: false));
    await tester.tap(find.text('Baimukhan N.', skipOffstage: false));
    expect(selectedOffer?.id, 'offer-2');
  });

  testWidgets('renders title below the cover and metadata as image badges', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
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
          body: ExcursionDetailsContent(
            excursion: _excursion,
            selectedOffer: _excursion.offers.first,
            offerProfiles: {'guide-user-1': _guideProfile1},
            onBookTap: () {},
            onEditOfferTap: () {},
            onMessageGuideTap: () {},
            onOfferSelected: (_) {},
            showMessageGuide: false,
            showBookingAction: false,
          ),
        ),
      ),
    );

    final media = find.byKey(const ValueKey('excursion-hero-media'));
    final badges = find.byKey(const ValueKey('excursion-hero-badges'));
    final metadata = find.byKey(const ValueKey('excursion-hero-metadata'));
    final title = find.descendant(
      of: metadata,
      matching: find.text('Almaty Mountain Escape'),
    );

    expect(media, findsOneWidget);
    expect(badges, findsOneWidget);
    expect(metadata, findsOneWidget);
    expect(title, findsOneWidget);
    expect(
      find.descendant(of: metadata, matching: find.text('Adventure')),
      findsNothing,
    );
    expect(
      find.descendant(of: media, matching: find.text('Almaty Mountain Escape')),
      findsNothing,
    );
    expect(
      find.descendant(of: badges, matching: find.text('Almaty')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: badges, matching: find.text('8 h')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: metadata, matching: find.text('Almaty')),
      findsNothing,
    );
    expect(
      find.descendant(of: metadata, matching: find.text('8 h')),
      findsNothing,
    );
    expect(tester.getTopLeft(metadata).dy, tester.getBottomLeft(media).dy);
    expect(
      tester.getTopLeft(title).dy,
      greaterThan(tester.getBottomLeft(media).dy),
    );
    expect(find.text('Almaty'), findsOneWidget);
    expect(find.text('4.9'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not render redundant lead guide block', (tester) async {
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
          body: ExcursionDetailsContent(
            excursion: _excursion,
            selectedOffer: _excursion.offers.first,
            offerProfiles: {'guide-user-1': _guideProfile1},
            onBookTap: () {},
            onEditOfferTap: () {},
            onMessageGuideTap: () {},
            onOfferSelected: (_) {},
            showMessageGuide: false,
            showBookingAction: false,
          ),
        ),
      ),
    );

    expect(find.text('Your Lead Guide'), findsNothing);
    expect(find.text('Verified local expert'), findsNothing);
    expect(find.text('Sadykova A.', skipOffstage: false), findsOneWidget);
    expect(find.text('Message Guide'), findsNothing);
    expect(find.text('Book'), findsNothing);
  });

  testWidgets('shows included items only for the selected guide offer', (
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
          body: ExcursionDetailsContent(
            excursion: _excursion,
            selectedOffer: _excursion.offers.last,
            offerProfiles: {
              'guide-user-1': _guideProfile1,
              'guide-user-2': _guideProfile2,
            },
            onBookTap: () {},
            onEditOfferTap: () {},
            onMessageGuideTap: () {},
            onOfferSelected: (_) {},
            showMessageGuide: true,
            showBookingAction: true,
          ),
        ),
      ),
    );

    expect(find.text('Included with selected guide'), findsOneWidget);
    expect(find.text('Tickets'), findsOneWidget);
    expect(find.text('Private SUV'), findsNothing);
  });

  testWidgets('renders no-offers state without booking CTA', (tester) async {
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
          body: ExcursionDetailsContent(
            excursion: _excursionWithoutOffers,
            selectedOffer: null,
            offerProfiles: const {},
            onBookTap: () {},
            onEditOfferTap: () {},
            onMessageGuideTap: () {},
            onOfferSelected: (_) {},
            showMessageGuide: false,
            showBookingAction: false,
          ),
        ),
      ),
    );

    expect(find.text('No guides available yet'), findsOneWidget);
    expect(find.text('Book'), findsNothing);
  });

  testWidgets('offers filter sheet exposes available date filter', (
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
          body: ExcursionDetailsContent(
            excursion: _excursion,
            selectedOffer: _excursion.offers.first,
            offerProfiles: {'guide-user-1': _guideProfile1},
            onBookTap: () {},
            onEditOfferTap: () {},
            onMessageGuideTap: () {},
            onOfferSelected: (_) {},
            showMessageGuide: false,
            showBookingAction: false,
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.byIcon(Icons.tune_rounded));
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Available date'), findsOneWidget);
    expect(find.text('dd.mm.yyyy'), findsOneWidget);
  });

  testWidgets('renders unavailable schedule notice instead of booking CTA', (
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
          body: ExcursionDetailsContent(
            excursion: _excursion,
            selectedOffer: _excursion.offers.first,
            offerProfiles: {'guide-user-1': _guideProfile1},
            onBookTap: () {},
            onEditOfferTap: () {},
            onMessageGuideTap: () {},
            onOfferSelected: (_) {},
            showMessageGuide: true,
            showBookingAction: false,
            bookingUnavailableMessage:
                'This guide has no available time slots yet.',
          ),
        ),
      ),
    );

    expect(find.text('Book'), findsNothing);
    expect(
      find.text('This guide has no available time slots yet.'),
      findsOneWidget,
    );
  });

  testWidgets('renders full-width edit CTA without price for guide authors', (
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
          body: ExcursionDetailsContent(
            excursion: _excursion,
            selectedOffer: _excursion.offers.first,
            offerProfiles: {'guide-user-1': _guideProfile1},
            onBookTap: () {},
            onEditOfferTap: () {},
            onMessageGuideTap: () {},
            onOfferSelected: (_) {},
            showMessageGuide: false,
            showBookingAction: false,
            showEditOfferAction: true,
          ),
        ),
      ),
    );

    expect(find.text('Edit offer'), findsOneWidget);
    expect(find.text('TOTAL'), findsNothing);
    expect(find.text('Book'), findsNothing);
  });

  testWidgets('pins current guide offer first and hides its profile action', (
    tester,
  ) async {
    final selectedOffers = <String>[];

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
          body: ExcursionDetailsContent(
            excursion: _excursion,
            offers: _excursion.offers,
            selectedOffer: _excursion.offers.last,
            currentUserId: 'guide-user-2',
            isCurrentUserGuide: true,
            offerProfiles: {
              'guide-user-1': _guideProfile1,
              'guide-user-2': _guideProfile2,
            },
            onBookTap: () {},
            onEditOfferTap: () {},
            onMessageGuideTap: () {},
            onOfferSelected: (offer) => selectedOffers.add(offer.id),
            showMessageGuide: false,
            showBookingAction: false,
          ),
        ),
      ),
    );

    await tester.pump();

    final ownGuide = find.text('Baimukhan N.', skipOffstage: false);
    final otherGuide = find.text('Sadykova A.', skipOffstage: false);
    expect(ownGuide, findsOneWidget);
    expect(otherGuide, findsOneWidget);
    expect(
      tester.getTopLeft(ownGuide).dy,
      lessThan(tester.getTopLeft(otherGuide).dy),
    );
    expect(find.text('This is you'), findsOneWidget);
    expect(find.text('Profile'), findsNothing);
    expect(selectedOffers, isEmpty);
  });

  testWidgets(
    'filters guide offers by full name display name and localized data',
    (tester) async {
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
            body: ExcursionDetailsContent(
              excursion: _excursion,
              selectedOffer: _excursion.offers.first,
              offerProfiles: {
                'guide-user-1': _guideProfile1,
                'guide-user-2': _guideProfile2,
              },
              onBookTap: () {},
              onEditOfferTap: () {},
              onMessageGuideTap: () {},
              onOfferSelected: (_) {},
              showMessageGuide: true,
              showBookingAction: true,
            ),
          ),
        ),
      );

      await tester.ensureVisible(find.byType(TextField).first);
      await tester.enterText(find.byType(TextField).first, 'nurlan');
      await tester.pump();

      expect(find.text('Baimukhan N.', skipOffstage: false), findsOneWidget);
      expect(find.text('Sadykova A.', skipOffstage: false), findsNothing);

      await tester.enterText(find.byType(TextField).first, 'aru guide');
      await tester.pump();

      expect(find.text('Sadykova A.', skipOffstage: false), findsOneWidget);
      expect(find.text('Baimukhan N.', skipOffstage: false), findsNothing);
    },
  );

  testWidgets(
    'shows itinerary source text when requested translation is missing',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ExcursionDetailsContent(
              excursion: _excursionWithRussianGuideCopy,
              selectedOffer: _excursionWithRussianGuideCopy.offers.first,
              offerProfiles: {'guide-user-1': _guideProfile1},
              onBookTap: () {},
              onEditOfferTap: () {},
              onMessageGuideTap: () {},
              onOfferSelected: (_) {},
              showMessageGuide: true,
              showBookingAction: true,
            ),
          ),
        ),
      );

      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Имеется'), findsNothing);
      expect(find.text('Step 1 of 1'), findsNothing);
      expect(find.text('Тест'), findsOneWidget);
      expect(find.text('Возможно стоит изменить'), findsOneWidget);
    },
  );

  testWidgets('renders included item type keys as localized labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ExcursionDetailsContent(
            excursion: _excursionWithIncludedTypeKeys,
            selectedOffer: _excursionWithIncludedTypeKeys.offers.first,
            offerProfiles: {'guide-user-1': _guideProfile1},
            onBookTap: () {},
            onEditOfferTap: () {},
            onMessageGuideTap: () {},
            onOfferSelected: (_) {},
            showMessageGuide: true,
            showBookingAction: true,
          ),
        ),
      ),
    );

    expect(find.text('Transport'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('transport'), findsNothing);
    expect(find.text('food'), findsNothing);
  });

  testWidgets('shows itinerary translation notice and toggles only itinerary', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ExcursionDetailsContent(
            excursion: _machineTranslatedExcursion,
            selectedOffer: null,
            offerProfiles: const {},
            onBookTap: () {},
            onEditOfferTap: () {},
            onMessageGuideTap: () {},
            onOfferSelected: (_) {},
            showMessageGuide: false,
            showBookingAction: false,
          ),
        ),
      ),
    );

    expect(
      find.text('Itinerary was automatically translated from Russian'),
      findsOneWidget,
    );
    expect(find.text('Show original'), findsOneWidget);
    expect(find.text('·'), findsOneWidget);
    expect(find.text('Charyn Canyon sunrise'), findsWidgets);
    expect(find.text('English translated detail text.'), findsOneWidget);
    expect(find.text('English translated itinerary'), findsOneWidget);
    expect(find.text('Чарынский каньон на рассвете'), findsNothing);
    expect(find.text('Русское исходное описание.'), findsNothing);

    await tester.ensureVisible(find.text('Show original'));
    await tester.tap(find.text('Show original'));
    await tester.pumpAndSettle();

    expect(find.text('Show translation'), findsOneWidget);
    expect(find.text('Charyn Canyon sunrise'), findsWidgets);
    expect(find.text('English translated detail text.'), findsOneWidget);
    expect(find.text('Русский исходный маршрут'), findsOneWidget);
    expect(find.text('Чарынский каньон на рассвете'), findsNothing);
    expect(find.text('Русское исходное описание.'), findsNothing);
  });

  testWidgets('shows pending notice while rendering source itinerary', (
    tester,
  ) async {
    await _pumpTranslationStateExcursion(
      tester,
      excursion: _pendingTranslationExcursion,
      locale: const Locale('en'),
    );

    expect(
      find.text('Showing original itinerary · Translation is being prepared'),
      findsOneWidget,
    );
    expect(find.text('Show original'), findsNothing);
    expect(find.text('Русское исходное описание.'), findsOneWidget);
  });

  testWidgets('shows a localized title for combined route details', (
    tester,
  ) async {
    await _pumpTranslationStateExcursion(
      tester,
      excursion: _combinedRouteExcursion,
      locale: const Locale('en'),
      localizedPlacesById: _localizedCombinedRoutePlaces,
    );

    expect(find.text('Bozjyra Tract + Charyn Canyon'), findsOneWidget);
    expect(find.text(_combinedRouteExcursion.title), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the departure city in the app locale', (tester) async {
    await _pumpTranslationStateExcursion(
      tester,
      excursion: _detailsWithRussianCity,
      locale: const Locale('en'),
      locationLabelResolver: _EnglishAlmatyResolver(),
    );

    expect(find.text('Almaty'), findsWidgets);
    expect(find.text('Алматы'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resolves the city when only departureCityId is stored', (
    tester,
  ) async {
    await _pumpTranslationStateExcursion(
      tester,
      excursion: _detailsWithCityIdOnly,
      locale: const Locale('en'),
      locationLabelResolver: _EnglishAlmatyResolver(),
    );

    expect(find.text('Almaty'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'keeps landmark and included content localized while itinerary is pending',
    (tester) async {
      await _pumpTranslationStateExcursion(
        tester,
        excursion: _pendingItineraryWithLocalizedCatalogContent,
        locale: const Locale('en'),
        selectedOffer:
            _pendingItineraryWithLocalizedCatalogContent.offers.first,
        localizedLandmark: _localizedLandmark,
      );

      expect(find.text('Localized attraction'), findsWidgets);
      expect(find.text('Localized attraction description.'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Транспорт'), findsNothing);
      expect(find.text('Русский этап маршрута'), findsOneWidget);
      expect(find.text('Русское описание этапа.'), findsOneWidget);
      expect(find.text('English itinerary step'), findsNothing);
    },
  );

  testWidgets('shows unavailable notice without overflow for long Kazakh copy', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpTranslationStateExcursion(
      tester,
      excursion: _unavailableTranslationExcursion,
      locale: const Locale('kk'),
      textScaler: const TextScaler.linear(1.3),
    );

    expect(
      find.text(
        'Маршруттың түпнұсқасы көрсетіліп тұр · Автоматты аударма уақытша қолжетімсіз',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpTranslationStateExcursion(
  WidgetTester tester, {
  required ExcursionVm excursion,
  required Locale locale,
  ExcursionOfferVm? selectedOffer,
  PlaceVm? localizedLandmark,
  Map<String, PlaceVm> localizedPlacesById = const {},
  AppLocationLabelResolver? locationLabelResolver,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: Scaffold(
        body: ExcursionDetailsContent(
          excursion: excursion,
          selectedOffer: selectedOffer,
          localizedLandmark: localizedLandmark,
          localizedPlacesById: localizedPlacesById,
          locationLabelResolver: locationLabelResolver,
          offerProfiles: const {},
          onBookTap: () {},
          onEditOfferTap: () {},
          onMessageGuideTap: () {},
          onOfferSelected: (_) {},
          showMessageGuide: false,
          showBookingAction: false,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final _guideProfile1 = UserProfileVm(
  userId: 'guide-user-1',
  status: 'ACTIVE',
  locale: 'ru',
  timezone: 'Asia/Almaty',
  isProfileCompleted: true,
  roles: ['GUIDE'],
  followersCount: 0,
  isFollowedByMe: false,
  friendshipStatus: UserFriendshipStatus.none,
  firstName: 'Aruzhan',
  lastName: 'Sadykova',
  nickname: '@aru_guide',
);

final _guideProfile2 = UserProfileVm(
  userId: 'guide-user-2',
  status: 'ACTIVE',
  locale: 'ru',
  timezone: 'Asia/Almaty',
  isProfileCompleted: true,
  roles: ['GUIDE'],
  followersCount: 0,
  isFollowedByMe: false,
  friendshipStatus: UserFriendshipStatus.none,
  firstName: 'Nurlan',
  lastName: 'Baimukhan',
);

const _excursion = ExcursionVm(
  id: 'excursion-1',
  title: 'Almaty Mountain Escape',
  summary: 'Private mountain route',
  description: 'A private alpine route through Shymbulak and Medeu.',
  categorySlug: 'adventure',
  durationMinutes: 480,
  maxGroupSize: 4,
  languageCodes: ['en'],
  includedItems: ['Private SUV'],
  itinerary: [
    ExcursionItineraryItemVm(
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
  publishedOffersCount: 2,
  offers: [
    ExcursionOfferVm(
      id: 'offer-1',
      productId: 'excursion-1',
      guideProfileId: 'guide-profile-1',
      guideUserId: 'guide-user-1',
      status: 'PUBLISHED',
      visibility: 'PUBLIC',
      durationMinutes: 480,
      maxGroupSize: 4,
      meetingPoint: 'Hotel pickup',
      priceAmount: 240,
      currency: 'USD',
      languageCodes: ['en'],
      includedItems: ['Private SUV'],
    ),
    ExcursionOfferVm(
      id: 'offer-2',
      productId: 'excursion-1',
      guideProfileId: 'guide-profile-2',
      guideUserId: 'guide-user-2',
      status: 'PUBLISHED',
      visibility: 'PUBLIC',
      durationMinutes: 420,
      maxGroupSize: 6,
      meetingPoint: 'Medeu entrance',
      priceAmount: 180,
      currency: 'USD',
      languageCodes: ['ru'],
      includedItems: ['Tickets'],
    ),
  ],
);

const _excursionWithoutOffers = ExcursionVm(
  id: 'excursion-empty',
  title: 'Empty Excursion',
  summary: 'No guide yet',
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  priceAmount: 0,
  currency: 'KZT',
);

const _excursionWithRussianGuideCopy = ExcursionVm(
  id: 'excursion-russian-copy',
  title: 'Bozjyra Tract',
  summary: 'Shared route',
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  priceAmount: 50000,
  currency: 'KZT',
  itinerary: [
    ExcursionItineraryItemVm(
      id: 'step-ru-1',
      sortOrder: 0,
      startOffsetMinutes: 0,
      title: 'Тест',
      description: 'Возможно стоит изменить',
      translations: {
        'ru': ExcursionItineraryLocalizedCopyVm(
          title: 'Тест',
          description: 'Возможно стоит изменить',
        ),
      },
    ),
  ],
  offers: [
    ExcursionOfferVm(
      id: 'offer-russian-copy',
      productId: 'excursion-russian-copy',
      guideProfileId: 'guide-profile-1',
      guideUserId: 'guide-user-1',
      status: 'PUBLISHED',
      visibility: 'PUBLIC',
      durationMinutes: 480,
      maxGroupSize: 4,
      meetingPoint: 'Hotel pickup',
      priceAmount: 50000,
      currency: 'KZT',
      languageCodes: ['ru'],
      includedItems: ['transport: Имеется'],
      includedItemTranslations: {
        'en': ['Transport: Имеется'],
        'ru': ['Транспорт: Имеется'],
      },
    ),
  ],
);

const _excursionWithIncludedTypeKeys = ExcursionVm(
  id: 'excursion-type-keys',
  title: 'Bozjyra Tract',
  summary: 'Shared route',
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  priceAmount: 50000,
  currency: 'KZT',
  offers: [
    ExcursionOfferVm(
      id: 'offer-type-keys',
      productId: 'excursion-type-keys',
      guideProfileId: 'guide-profile-1',
      guideUserId: 'guide-user-1',
      status: 'PUBLISHED',
      visibility: 'PUBLIC',
      durationMinutes: 480,
      maxGroupSize: 4,
      meetingPoint: 'Hotel pickup',
      priceAmount: 50000,
      currency: 'KZT',
      languageCodes: ['en'],
      includedItems: ['transport', 'food'],
    ),
  ],
);

const _machineTranslatedExcursion = ExcursionVm(
  id: 'excursion-machine-translated',
  title: 'Чарынский каньон на рассвете',
  summary: 'Русское исходное краткое описание.',
  description: 'Русское исходное описание.',
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  priceAmount: 50000,
  currency: 'KZT',
  durationMinutes: 180,
  maxGroupSize: 4,
  languageCodes: ['ru'],
  translations: {
    'en': ExcursionLocalizedCopyVm(
      title: 'Charyn Canyon sunrise',
      summary: 'English translated summary.',
      description: 'English translated detail text.',
    ),
  },
  translationInfo: ExcursionTranslationInfoVm(
    translated: true,
    sourceLanguage: 'ru',
    targetLanguages: ['en'],
    provider: 'azure_translator',
  ),
  itinerary: [
    ExcursionItineraryItemVm(
      id: 'step-1',
      sortOrder: 0,
      startOffsetMinutes: 0,
      title: 'Русский исходный маршрут',
      description: 'Русский исходный этап.',
      translations: {
        'en': ExcursionItineraryLocalizedCopyVm(
          title: 'English translated itinerary',
          description: 'English translated step.',
        ),
      },
    ),
  ],
);

const _pendingTranslationExcursion = ExcursionVm(
  id: 'excursion-translation-pending',
  title: 'Русский исходный заголовок',
  summary: 'Русское исходное краткое описание.',
  description: 'Русское исходное описание.',
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  priceAmount: 50000,
  currency: 'KZT',
  durationMinutes: 180,
  maxGroupSize: 4,
  itinerary: [
    ExcursionItineraryItemVm(
      id: 'pending-step-1',
      sortOrder: 0,
      startOffsetMinutes: 0,
      title: 'Русский этап маршрута',
      description: 'Русское описание этапа.',
    ),
  ],
  translationInfo: ExcursionTranslationInfoVm(
    status: 'PENDING',
    sourceLanguage: 'ru',
    currentLanguage: 'en',
    availableLanguages: ['ru'],
    pendingLanguages: ['en', 'kk'],
  ),
);

const _pendingItineraryWithLocalizedCatalogContent = ExcursionVm(
  id: 'excursion-pending-localized-catalog',
  landmarkId: 'place-1',
  landmarkName: 'Исходная достопримечательность',
  title: 'Исходная достопримечательность',
  summary: 'Исходное краткое описание.',
  description: 'Исходное описание достопримечательности.',
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  priceAmount: 50000,
  currency: 'KZT',
  durationMinutes: 180,
  maxGroupSize: 4,
  itinerary: [
    ExcursionItineraryItemVm(
      id: 'pending-localized-step-1',
      sortOrder: 0,
      startOffsetMinutes: 0,
      title: 'Русский этап маршрута',
      description: 'Русское описание этапа.',
    ),
  ],
  offers: [
    ExcursionOfferVm(
      id: 'pending-localized-offer',
      productId: 'excursion-pending-localized-catalog',
      guideProfileId: 'guide-profile-1',
      guideUserId: 'guide-user-1',
      status: 'PUBLISHED',
      visibility: 'PUBLIC',
      durationMinutes: 180,
      maxGroupSize: 4,
      meetingPoint: 'Meeting point',
      priceAmount: 50000,
      currency: 'KZT',
      includedItems: ['transport'],
      includedItemTranslations: {
        'en': ['Transport'],
        'ru': ['Транспорт'],
        'kk': ['Көлік'],
      },
    ),
  ],
  translationInfo: ExcursionTranslationInfoVm(
    status: 'PENDING',
    sourceLanguage: 'ru',
    currentLanguage: 'en',
    availableLanguages: ['ru'],
    pendingLanguages: ['en', 'kk'],
  ),
);

final _localizedLandmark = PlaceVm.fromJson(const {
  'id': 'place-1',
  'locale': 'en',
  'defaultLocale': 'ru',
  'title': 'Localized attraction',
  'description': 'Localized attraction description.',
  'countryCode': 'KZ',
  'cityId': 'almaty',
  'category': 'NATURE',
  'rating': 0,
  'reviewCount': 0,
  'source': 'SYSTEM',
  'status': 'PUBLISHED',
  'translations': {
    'en': {
      'title': 'Localized attraction',
      'description': 'Localized attraction description.',
    },
    'ru': {
      'title': 'Исходная достопримечательность',
      'description': 'Исходное описание достопримечательности.',
    },
  },
});

const _combinedRouteExcursion = ExcursionVm(
  id: 'combined-route-details',
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
  durationMinutes: 240,
  maxGroupSize: 6,
);

const _detailsWithRussianCity = ExcursionVm(
  id: 'localized-city-details',
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
  maxGroupSize: 6,
);

const _detailsWithCityIdOnly = ExcursionVm(
  id: 'localized-city-id-only-details',
  title: 'Mountain trail',
  summary: 'Scenic route',
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  priceAmount: 12000,
  currency: 'KZT',
  countryCode: 'KZ',
  departureCityId: 'almaty',
  durationMinutes: 180,
  maxGroupSize: 6,
);

final _localizedCombinedRoutePlaces = <String, PlaceVm>{
  'bozjyra': PlaceVm.fromJson(const {
    'id': 'bozjyra',
    'locale': 'en',
    'defaultLocale': 'ru',
    'title': 'Bozjyra Tract',
    'description': '',
    'translations': {
      'en': {'title': 'Bozjyra Tract', 'description': ''},
    },
  }),
  'charyn': PlaceVm.fromJson(const {
    'id': 'charyn',
    'locale': 'en',
    'defaultLocale': 'ru',
    'title': 'Charyn Canyon',
    'description': '',
    'translations': {
      'en': {'title': 'Charyn Canyon', 'description': ''},
    },
  }),
};

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

const _unavailableTranslationExcursion = ExcursionVm(
  id: 'excursion-translation-unavailable',
  title: 'Русский исходный заголовок',
  summary: 'Русское исходное краткое описание.',
  description: 'Русское исходное описание.',
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  priceAmount: 50000,
  currency: 'KZT',
  durationMinutes: 180,
  maxGroupSize: 4,
  itinerary: [
    ExcursionItineraryItemVm(
      id: 'unavailable-step-1',
      sortOrder: 0,
      startOffsetMinutes: 0,
      title: 'Орыс тіліндегі маршрут кезеңі',
      description: 'Маршрут кезеңінің түпнұсқа сипаттамасы.',
    ),
  ],
  translationInfo: ExcursionTranslationInfoVm(
    status: 'FAILED',
    sourceLanguage: 'ru',
    currentLanguage: 'kk',
    availableLanguages: ['ru'],
    failedLanguages: ['kk'],
  ),
);
