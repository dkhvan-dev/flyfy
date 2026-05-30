import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/profile/models/user_profile_vm.dart';
import 'package:inflap/features/excursions/models/excursion_vm.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/screens/excursions/excursion_details_screen.dart';

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

    await tester.ensureVisible(find.text('Baimukhan N.', skipOffstage: false));
    await tester.tap(find.text('Baimukhan N.', skipOffstage: false));
    expect(selectedOffer?.id, 'offer-2');
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
  displayName: '@aru_guide',
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
