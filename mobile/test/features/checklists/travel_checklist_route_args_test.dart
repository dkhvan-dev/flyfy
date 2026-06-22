import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/checklist_api.dart';
import 'package:inflap/features/checklists/models/travel_checklist_route_args.dart';
import 'package:inflap/features/excursions/models/excursion_booking_vm.dart';
import 'package:inflap/features/excursions/models/excursion_vm.dart';

void main() {
  test('builds exact trip checklist context from excursion booking', () {
    final args = TravelChecklistRouteArgs.fromExcursionBooking(
      booking: ExcursionBookingVm(
        id: 'booking-42',
        productId: 'product-1',
        offerId: 'offer-1',
        scheduleSlotId: 'slot-1',
        touristUserId: 'tourist-1',
        guideUserId: 'guide-1',
        guideProfileId: 'guide-profile-1',
        guideDisplayName: 'Aruzhan',
        title: 'Bosphorus walk',
        summary: 'City walk',
        scheduledFor: DateTime.utc(2026, 11, 9, 9),
        adults: 2,
        children: 1,
        totalSeats: 3,
        totalPriceAmount: 90000,
        currency: 'KZT',
        status: 'REQUESTED',
        categorySlug: 'culture',
        countryCode: 'TR',
        cityName: 'Istanbul',
      ),
      excursion: const ExcursionVm(
        id: 'product-1',
        title: 'Bosphorus walk',
        summary: 'City walk',
        status: 'PUBLISHED',
        visibility: 'PUBLIC',
        priceAmount: 30000,
        currency: 'KZT',
        categorySlug: 'city_walk',
        routeKind: 'MULTI_PLACE',
        routeTheme: 'history',
        transportMode: 'WALKING',
        durationMinutes: 180,
        tags: ['Old town', 'History'],
        countryCode: 'TR',
        cityName: 'Istanbul',
        itinerary: [
          ExcursionItineraryItemVm(
            id: 'stop-1',
            sortOrder: 0,
            startOffsetMinutes: 0,
            durationMinutes: 45,
            title: 'Galata',
            description: 'Start here',
            placeName: 'Galata Tower',
            latitude: 41.0256,
            longitude: 28.9742,
          ),
          ExcursionItineraryItemVm(
            id: 'stop-2',
            sortOrder: 1,
            startOffsetMinutes: 60,
            durationMinutes: 45,
            title: 'Pier',
            description: 'Continue here',
            placeName: 'Karakoy Pier',
            latitude: 41.0221,
            longitude: 28.9784,
          ),
        ],
      ),
    );

    final request = args.toRequest(preferredLanguage: 'en');

    expect(request.tripId, 'excursion_booking:booking-42');
    expect(request.destination.countryCode, 'TR');
    expect(request.destination.cityName, 'Istanbul');
    expect(request.startAt, DateTime.utc(2026, 11, 9, 9));
    expect(request.endAt, DateTime.utc(2026, 11, 9, 12));
    expect(request.hasChildren, isTrue);
    expect(request.transportModes, ['flight', 'walking']);
    expect(request.activitySlugs, [
      'culture',
      'multi_place',
      'history',
      'walking',
      'old_town',
      'city_walk',
    ]);
    expect(args.routeStops, hasLength(2));
    expect(args.routeStops.first.name, 'Galata Tower');
    expect(args.routeStops.first.latitude, 41.0256);
  });

  test('builds read-only preview checklist context from excursion details', () {
    final args = TravelChecklistRouteArgs.fromExcursionPreview(
      excursion: const ExcursionVm(
        id: 'product-1',
        title: 'Bosphorus walk',
        summary: 'City walk',
        status: 'PUBLISHED',
        visibility: 'PUBLIC',
        priceAmount: 30000,
        currency: 'KZT',
        categorySlug: 'city_walk',
        routeKind: 'MULTI_PLACE',
        routeTheme: 'history',
        transportMode: 'WALKING',
        durationMinutes: 180,
        tags: ['Old town', 'History'],
        countryCode: 'TR',
        cityName: 'Istanbul',
        itinerary: [
          ExcursionItineraryItemVm(
            id: 'stop-1',
            sortOrder: 0,
            startOffsetMinutes: 0,
            durationMinutes: 45,
            title: 'Galata',
            description: 'Start here',
            placeName: 'Galata Tower',
            latitude: 41.0256,
            longitude: 28.9742,
          ),
        ],
      ),
      selectedOffer: const ExcursionOfferVm(
        id: 'offer-1',
        productId: 'product-1',
        guideProfileId: 'guide-profile-1',
        guideUserId: 'guide-1',
        status: 'PUBLISHED',
        visibility: 'PUBLIC',
        durationMinutes: 240,
        maxGroupSize: 10,
        meetingPoint: 'Pier',
        priceAmount: 30000,
        currency: 'KZT',
        itinerary: [
          ExcursionItineraryItemVm(
            id: 'offer-stop-1',
            sortOrder: 0,
            startOffsetMinutes: 0,
            durationMinutes: 45,
            title: 'Pier',
            description: 'Start at the pier',
            placeName: 'Karakoy Pier',
            latitude: 41.0221,
            longitude: 28.9784,
          ),
        ],
      ),
      now: DateTime.utc(2026, 6, 21, 8),
    );

    final request = args.toRequest(preferredLanguage: 'ru');

    expect(args.isPreview, isTrue);
    expect(request.tripId, 'excursion_preview:product-1:offer-1');
    expect(request.destination.countryCode, 'TR');
    expect(request.destination.cityName, 'Istanbul');
    expect(request.startAt, DateTime.utc(2026, 6, 22, 10));
    expect(request.endAt, DateTime.utc(2026, 6, 22, 14));
    expect(request.hasChildren, isFalse);
    expect(request.transportModes, ['flight', 'walking']);
    expect(request.activitySlugs, [
      'city_walk',
      'multi_place',
      'history',
      'walking',
      'old_town',
    ]);
    expect(args.routeStops, hasLength(1));
    expect(args.routeStops.single.name, 'Karakoy Pier');
  });

  test('preserves localized country name and route stops for checklist UI', () {
    final args = TravelChecklistRouteArgs(
      tripId: 'quick-prep:tr:istanbul:2026-07-10',
      destination: const TripChecklistDestinationRequest(
        countryCode: 'TR',
        cityName: 'Стамбул',
        cityId: 'istanbul',
      ),
      destinationCountryName: 'Турция',
      startAt: DateTime.utc(2026, 7, 10, 9),
      endAt: DateTime.utc(2026, 7, 17, 18),
      routeStops: const [
        TravelChecklistRouteStop(
          latitude: 41.0256,
          longitude: 28.9742,
          name: 'Galata Tower',
        ),
      ],
    );

    final restored = TravelChecklistRouteArgs.fromJson(args.toJson());
    final request = restored.toRequest(preferredLanguage: 'ru');

    expect(restored.destinationCountryName, 'Турция');
    expect(restored.routeStops.single.name, 'Galata Tower');
    expect(request.destination.countryCode, 'TR');
    expect(request.destination.cityName, 'Стамбул');
  });
}
