import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/core/network/excursion_api.dart';
import 'package:superapp/core/network/excursion_schedule_api.dart';
import 'package:superapp/features/excursions/models/create_excursion_request.dart';
import 'package:superapp/features/excursions/models/excursion_booking_vm.dart';
import 'package:superapp/features/excursions/models/excursion_schedule_vm.dart';
import 'package:superapp/features/excursions/models/excursion_vm.dart';
import 'package:superapp/features/profile/data/guide_api.dart';
import 'package:superapp/features/profile/models/guide_profile_vm.dart';
import 'package:superapp/providers/excursion_provider.dart';

void main() {
  test(
    'createAndPublishExcursion returns refreshed marketplace product details',
    () async {
      final api = _FakeExcursionApi(
        excursionBatches: const [
          [_existingExcursion],
          [_publishedProduct, _existingExcursion],
        ],
        createdExcursion: _createdDraft,
        publishedExcursion: _publishedExcursion,
        excursionDetails: const {'product-new': _publishedProductDetails},
      );
      final provider = ExcursionProvider(excursionApi: api);

      await provider.loadExcursions();
      final created = await provider.createAndPublishExcursion(_request);

      expect(created?.id, 'product-new');
      expect(created?.offers.single.legacyExcursionId, 'excursion-new');
      expect(api.getExcursionsCallCount, 2);
      expect(api.getExcursionByIdCalls, ['product-new']);
      expect(provider.excursions.map((excursion) => excursion.id), [
        'product-new',
        'excursion-old',
      ]);
      expect(provider.lastCreatedExcursion?.id, 'product-new');
    },
  );

  test(
    'createAndPublishExcursion retries marketplace refresh until product offers appear',
    () async {
      final api = _FakeExcursionApi(
        excursionBatches: const [
          [],
          [],
          [_publishedProduct],
        ],
        createdExcursion: _createdDraft,
        publishedExcursion: _publishedExcursion,
        excursionDetails: const {'product-new': _publishedProductDetails},
      );
      final provider = ExcursionProvider(
        excursionApi: api,
        guideApi: _FakeGuideApi(profile: null),
      );

      await provider.loadExcursions();
      final created = await provider.createAndPublishExcursion(_request);

      expect(created?.id, 'product-new');
      expect(created?.offers.single.legacyExcursionId, 'excursion-new');
      expect(api.getExcursionsCallCount, 3);
      expect(api.getExcursionByIdCalls, ['product-new']);
      expect(provider.lastCreatedExcursion?.id, 'product-new');
    },
  );

  test(
    'updateExcursionOffer refreshes selected product details after edit',
    () async {
      final api = _FakeExcursionApi(
        excursionBatches: const [
          [_publishedProduct, _existingExcursion],
        ],
        createdExcursion: _createdDraft,
        publishedExcursion: _publishedExcursion,
        updatedExcursion: _updatedLegacyExcursion,
        excursionDetails: const {
          'product-new': _publishedProductDetails,
          'product-new-updated': _updatedProductDetails,
        },
      );
      final provider = ExcursionProvider(excursionApi: api);

      await provider.loadExcursionDetails('product-new-updated');
      final updated = await provider.updateExcursionOffer(
        'excursion-new',
        _request,
      );

      expect(updated?.id, 'product-new-updated');
      expect(updated?.offers.single.priceAmount, 150);
      expect(provider.selectedExcursion?.id, 'product-new-updated');
      expect(provider.selectedExcursion?.offers.single.priceAmount, 150);
      expect(api.getExcursionByIdCalls, [
        'product-new-updated',
        'product-new-updated',
      ]);
    },
  );

  test(
    'loadGuideDashboardData loads guide offers and guide-side bookings',
    () async {
      final api = _FakeExcursionApi(
        excursionBatches: const [],
        createdExcursion: _createdDraft,
        publishedExcursion: _publishedExcursion,
        myExcursions: const [_publishedProductDetails],
        guideBookings: [_upcomingGuideBooking],
      );
      final provider = ExcursionProvider(
        excursionApi: api,
        guideApi: _FakeGuideApi(profile: null),
      );

      await provider.loadGuideDashboardData();

      expect(provider.guideDashboardState, ExcursionListState.success);
      expect(provider.myGuideExcursions, const [_publishedProductDetails]);
      expect(provider.myGuideExcursionBookings, [_upcomingGuideBooking]);
      expect(api.getMyExcursionsCallCount, 1);
      expect(api.getMyExcursionsStatuses.single, contains('DRAFT'));
      expect(api.getMyGuideExcursionBookingsCallCount, 1);
    },
  );

  test(
    'loadGuideDashboardData loads real guide rating from guide profile',
    () async {
      final api = _FakeExcursionApi(
        excursionBatches: const [],
        createdExcursion: _createdDraft,
        publishedExcursion: _publishedExcursion,
        myExcursions: const [_publishedProductDetails],
        guideBookings: [_upcomingGuideBooking],
      );
      final guideApi = _FakeGuideApi(profile: _myGuideProfile);
      final provider = ExcursionProvider(excursionApi: api, guideApi: guideApi);

      await provider.loadGuideDashboardData();

      expect(provider.myGuideProfile?.ratingAvg, 4.8);
      expect(provider.guideDashboardState, ExcursionListState.success);
      expect(guideApi.getMyGuideProfileCallCount, 1);
    },
  );

  test('cancelGuideExcursionSlot cancels related guide dashboard bookings',
      () async {
    final api = _FakeExcursionApi(
      excursionBatches: const [],
      createdExcursion: _createdDraft,
      publishedExcursion: _publishedExcursion,
      myExcursions: const [_publishedProductDetails],
      guideBookings: [
        _upcomingGuideBooking,
        _secondUpcomingGuideBooking,
      ],
    );
    final scheduleApi =
        _FakeExcursionScheduleApi(cancelledSlot: _cancelledSlot);
    final provider = ExcursionProvider(
      excursionApi: api,
      guideApi: _FakeGuideApi(profile: null),
      scheduleApi: scheduleApi,
    );

    await provider.loadGuideDashboardData();
    final cancelled = await provider.cancelGuideExcursionSlot(
      'slot-1',
      reason: 'Guide is sick',
    );

    expect(cancelled, isTrue);
    expect(scheduleApi.cancelSlotCalls, ['slot-1']);
    expect(scheduleApi.cancelReasons, ['Guide is sick']);
    expect(
      provider.myGuideExcursionBookings.map((booking) => booking.status),
      ['CANCELLED', 'CANCELLED'],
    );
  });

  test('loadExcursionDetails keeps details scoped by excursion id', () async {
    final api = _FakeExcursionApi(
      excursionBatches: const [],
      createdExcursion: _createdDraft,
      publishedExcursion: _publishedExcursion,
      excursionDetails: const {
        'product-new': _publishedProductDetails,
        'product-other': _otherProductDetails,
      },
    );
    final provider = ExcursionProvider(excursionApi: api);

    await provider.loadExcursionDetails('product-new');
    await provider.loadExcursionDetails('product-other');

    expect(provider.excursionDetailsFor('product-new')?.id, 'product-new');
    expect(
      provider.excursionDetailsFor('product-new')?.offers.single.id,
      'offer-new',
    );
    expect(provider.excursionDetailsFor('product-other')?.id, 'product-other');
    expect(
      provider.excursionDetailsFor('product-other')?.offers.single.id,
      'offer-other',
    );
    expect(provider.selectedExcursion?.id, 'product-other');
  });
}

const _existingExcursion = ExcursionVm(
  id: 'excursion-old',
  title: 'Old Excursion',
  summary: 'Existing route',
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  priceAmount: 100,
  currency: 'KZT',
);

const _createdDraft = ExcursionVm(
  id: 'excursion-new',
  title: 'New Excursion',
  summary: 'Draft route',
  status: 'DRAFT',
  visibility: 'PUBLIC',
  priceAmount: 120,
  currency: 'KZT',
);

const _publishedExcursion = ExcursionVm(
  id: 'excursion-new',
  title: 'New Excursion',
  summary: 'Published route',
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  landmarkId: 'attraction-1',
  priceAmount: 120,
  currency: 'KZT',
  coverFileId: 'cover-file-id',
);

const _publishedProduct = ExcursionVm(
  id: 'product-new',
  title: 'New Excursion',
  summary: 'Published route',
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  landmarkId: 'attraction-1',
  priceAmount: 120,
  currency: 'KZT',
  coverFileId: 'cover-file-id',
  publishedOffersCount: 1,
);

const _publishedProductDetails = ExcursionVm(
  id: 'product-new',
  title: 'New Excursion',
  summary: 'Published route',
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  landmarkId: 'attraction-1',
  priceAmount: 120,
  currency: 'KZT',
  coverFileId: 'cover-file-id',
  publishedOffersCount: 1,
  offers: [
    ExcursionOfferVm(
      id: 'offer-new',
      productId: 'product-new',
      legacyExcursionId: 'excursion-new',
      guideProfileId: 'guide-profile-1',
      guideUserId: 'guide-user-1',
      status: 'PUBLISHED',
      visibility: 'PUBLIC',
      durationMinutes: 180,
      maxGroupSize: 6,
      meetingPoint: 'Hotel lobby',
      priceAmount: 120,
      currency: 'KZT',
    ),
  ],
);

const _updatedLegacyExcursion = ExcursionVm(
  id: 'excursion-new',
  title: 'New Excursion',
  summary: 'Updated legacy route',
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  landmarkId: 'attraction-1',
  priceAmount: 150,
  currency: 'KZT',
);

const _updatedProductDetails = ExcursionVm(
  id: 'product-new-updated',
  title: 'New Excursion',
  summary: 'Updated product route',
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  landmarkId: 'attraction-1',
  priceAmount: 150,
  currency: 'KZT',
  publishedOffersCount: 1,
  offers: [
    ExcursionOfferVm(
      id: 'offer-new',
      productId: 'product-new-updated',
      legacyExcursionId: 'excursion-new',
      guideProfileId: 'guide-profile-1',
      guideUserId: 'guide-user-1',
      status: 'PUBLISHED',
      visibility: 'PUBLIC',
      durationMinutes: 180,
      maxGroupSize: 6,
      meetingPoint: 'Hotel lobby',
      priceAmount: 150,
      currency: 'KZT',
    ),
  ],
);

const _otherProductDetails = ExcursionVm(
  id: 'product-other',
  title: 'Other Excursion',
  summary: 'Another route',
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  landmarkId: 'attraction-2',
  priceAmount: 200,
  currency: 'KZT',
  publishedOffersCount: 1,
  offers: [
    ExcursionOfferVm(
      id: 'offer-other',
      productId: 'product-other',
      legacyExcursionId: 'excursion-other',
      guideProfileId: 'guide-profile-1',
      guideUserId: 'guide-user-1',
      status: 'PUBLISHED',
      visibility: 'PUBLIC',
      durationMinutes: 120,
      maxGroupSize: 4,
      meetingPoint: 'Museum entrance',
      priceAmount: 200,
      currency: 'KZT',
    ),
  ],
);

final _upcomingGuideBooking = ExcursionBookingVm(
  id: 'booking-guide-1',
  productId: 'product-new',
  offerId: 'offer-new',
  scheduleSlotId: 'slot-1',
  touristUserId: 'tourist-1',
  guideUserId: 'guide-user-1',
  guideProfileId: 'guide-profile-1',
  guideDisplayName: 'Aruzhan',
  title: 'New Excursion',
  summary: 'Published route',
  scheduledFor: DateTime.utc(2026, 6, 1, 10),
  adults: 2,
  children: 0,
  totalSeats: 2,
  totalPriceAmount: 240,
  currency: 'KZT',
  status: 'REQUESTED',
);

final _secondUpcomingGuideBooking = ExcursionBookingVm(
  id: 'booking-guide-2',
  productId: 'product-new',
  offerId: 'offer-new',
  scheduleSlotId: 'slot-1',
  touristUserId: 'tourist-2',
  guideUserId: 'guide-user-1',
  guideProfileId: 'guide-profile-1',
  guideDisplayName: 'Aruzhan',
  title: 'New Excursion',
  summary: 'Published route',
  scheduledFor: DateTime.utc(2026, 6, 1, 10),
  adults: 1,
  children: 1,
  totalSeats: 2,
  totalPriceAmount: 240,
  currency: 'KZT',
  status: 'REQUESTED',
);

final _cancelledSlot = ExcursionScheduleSlotVm(
  id: 'slot-1',
  offerId: 'offer-new',
  productId: 'product-new',
  startAt: DateTime.utc(2026, 6, 1, 10),
  endAt: DateTime.utc(2026, 6, 1, 13),
  timezone: 'Asia/Almaty',
  capacity: 6,
  bookedSeats: 4,
  status: ExcursionScheduleSlotStatus.cancelled,
  cancelReason: 'Guide is sick',
);

final _myGuideProfile = GuideProfileVm(
  id: 'guide-profile-1',
  userId: 'guide-user-1',
  type: 'INDEPENDENT',
  status: 'ACTIVE',
  headline: 'Mountain guide',
  about: 'Almaty mountain routes',
  experienceYears: 5,
  isPrivateGuideAvailable: true,
  isActivityHostAvailable: true,
  isExcursionGuideAvailable: true,
  ratingAvg: 4.8,
  reviewsCount: 32,
  languages: const ['ru', 'en'],
  specializations: const ['mountain_guide'],
);

const _request = CreateExcursionRequest(
  landmarkId: 'attraction-1',
  landmarkName: 'Medeu',
  categorySlug: 'adventure',
  durationMinutes: 180,
  maxGroupSize: 6,
  languageCodes: ['en'],
  meetingPoint: 'Hotel lobby',
  priceAmount: 120,
  currency: 'KZT',
  itinerary: [
    CreateExcursionItineraryItemRequest(
      startOffsetMinutes: 0,
      title: 'Meet guide',
      description: 'Meet the guide and begin.',
    ),
  ],
);

class _FakeExcursionApi extends ExcursionApi {
  _FakeExcursionApi({
    required this.excursionBatches,
    required this.createdExcursion,
    required this.publishedExcursion,
    this.updatedExcursion,
    this.excursionDetails = const {},
    this.myExcursions = const [],
    this.guideBookings = const [],
  });

  final List<List<ExcursionVm>> excursionBatches;
  final ExcursionVm createdExcursion;
  final ExcursionVm publishedExcursion;
  final ExcursionVm? updatedExcursion;
  final Map<String, ExcursionVm> excursionDetails;
  final List<ExcursionVm> myExcursions;
  final List<ExcursionBookingVm> guideBookings;
  int getExcursionsCallCount = 0;
  int getMyExcursionsCallCount = 0;
  final List<List<String>> getMyExcursionsStatuses = [];
  int getMyGuideExcursionBookingsCallCount = 0;
  final List<String> getExcursionByIdCalls = [];

  @override
  Future<List<ExcursionVm>> getExcursions({
    int limit = 50,
    int offset = 0,
    String? query,
    String? landmarkId,
    String? categorySlug,
    String? cityName,
    String? departureCityId,
  }) async {
    final index = getExcursionsCallCount;
    getExcursionsCallCount++;
    if (index >= excursionBatches.length) {
      return excursionBatches.last;
    }
    return excursionBatches[index];
  }

  @override
  Future<ExcursionVm> createExcursion(CreateExcursionRequest request) async {
    return createdExcursion;
  }

  @override
  Future<ExcursionVm> publishExcursion(String excursionId) async {
    return publishedExcursion;
  }

  @override
  Future<ExcursionVm> getExcursionById(String excursionId) async {
    getExcursionByIdCalls.add(excursionId);
    return excursionDetails[excursionId] ?? publishedExcursion;
  }

  @override
  Future<ExcursionVm> updateExcursionOffer(
    String legacyExcursionId,
    CreateExcursionRequest request,
  ) async {
    return updatedExcursion ?? publishedExcursion;
  }

  @override
  Future<ExcursionsPage> getMyExcursions({
    int limit = 50,
    int offset = 0,
    List<String> statuses = const [],
  }) async {
    getMyExcursionsCallCount++;
    getMyExcursionsStatuses.add(List<String>.unmodifiable(statuses));
    return ExcursionsPage(items: myExcursions, hasMore: false);
  }

  @override
  Future<ExcursionBookingsPage> getMyGuideExcursionBookings({
    int limit = 50,
    int offset = 0,
  }) async {
    getMyGuideExcursionBookingsCallCount++;
    return ExcursionBookingsPage(items: guideBookings, hasMore: false);
  }
}

class _FakeGuideApi extends GuideApi {
  _FakeGuideApi({required this.profile});

  final GuideProfileVm? profile;
  int getMyGuideProfileCallCount = 0;

  @override
  Future<GuideProfileVm?> getMyGuideProfileOrNull() async {
    getMyGuideProfileCallCount++;
    return profile;
  }
}

class _FakeExcursionScheduleApi extends ExcursionScheduleApi {
  _FakeExcursionScheduleApi({required this.cancelledSlot});

  final ExcursionScheduleSlotVm cancelledSlot;
  final List<String> cancelSlotCalls = [];
  final List<String> cancelReasons = [];

  @override
  Future<ExcursionScheduleSlotVm> cancelSlot(String id, String reason) async {
    cancelSlotCalls.add(id);
    cancelReasons.add(reason);
    return cancelledSlot;
  }
}
