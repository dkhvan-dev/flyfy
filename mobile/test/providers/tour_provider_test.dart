import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/core/network/tour_api.dart';
import 'package:superapp/features/tours/models/create_tour_request.dart';
import 'package:superapp/features/tours/models/tour_vm.dart';
import 'package:superapp/providers/tour_provider.dart';

void main() {
  test(
    'createAndPublishTour returns refreshed marketplace product details',
    () async {
      final api = _FakeTourApi(
        tourBatches: const [
          [_existingTour],
          [_publishedProduct, _existingTour],
        ],
        createdTour: _createdDraft,
        publishedTour: _publishedTour,
        tourDetails: const {'product-new': _publishedProductDetails},
      );
      final provider = TourProvider(tourApi: api);

      await provider.loadTours();
      final created = await provider.createAndPublishTour(_request);

      expect(created?.id, 'product-new');
      expect(created?.offers.single.legacyTourId, 'tour-new');
      expect(api.getToursCallCount, 2);
      expect(api.getTourByIdCalls, ['product-new']);
      expect(provider.tours.map((tour) => tour.id), [
        'product-new',
        'tour-old',
      ]);
      expect(provider.lastCreatedTour?.id, 'product-new');
    },
  );

  test(
    'createAndPublishTour retries marketplace refresh until product offers appear',
    () async {
      final api = _FakeTourApi(
        tourBatches: const [
          [],
          [],
          [_publishedProduct],
        ],
        createdTour: _createdDraft,
        publishedTour: _publishedTour,
        tourDetails: const {'product-new': _publishedProductDetails},
      );
      final provider = TourProvider(tourApi: api);

      await provider.loadTours();
      final created = await provider.createAndPublishTour(_request);

      expect(created?.id, 'product-new');
      expect(created?.offers.single.legacyTourId, 'tour-new');
      expect(api.getToursCallCount, 3);
      expect(api.getTourByIdCalls, ['product-new']);
      expect(provider.lastCreatedTour?.id, 'product-new');
    },
  );

  test(
    'updateTourOffer refreshes selected product details after edit',
    () async {
      final api = _FakeTourApi(
        tourBatches: const [
          [_publishedProduct, _existingTour],
        ],
        createdTour: _createdDraft,
        publishedTour: _publishedTour,
        updatedTour: _updatedLegacyTour,
        tourDetails: const {
          'product-new': _publishedProductDetails,
          'product-new-updated': _updatedProductDetails,
        },
      );
      final provider = TourProvider(tourApi: api);

      await provider.loadTourDetails('product-new-updated');
      final updated = await provider.updateTourOffer('tour-new', _request);

      expect(updated?.id, 'product-new-updated');
      expect(updated?.offers.single.priceAmount, 150);
      expect(provider.selectedTour?.id, 'product-new-updated');
      expect(provider.selectedTour?.offers.single.priceAmount, 150);
      expect(api.getTourByIdCalls, [
        'product-new-updated',
        'product-new-updated',
      ]);
    },
  );
}

const _existingTour = TourVm(
  id: 'tour-old',
  title: 'Old Tour',
  summary: 'Existing route',
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  priceAmount: 100,
  currency: 'KZT',
);

const _createdDraft = TourVm(
  id: 'tour-new',
  title: 'New Tour',
  summary: 'Draft route',
  status: 'DRAFT',
  visibility: 'PUBLIC',
  priceAmount: 120,
  currency: 'KZT',
);

const _publishedTour = TourVm(
  id: 'tour-new',
  title: 'New Tour',
  summary: 'Published route',
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  landmarkId: 'attraction-1',
  priceAmount: 120,
  currency: 'KZT',
  coverFileId: 'cover-file-id',
);

const _publishedProduct = TourVm(
  id: 'product-new',
  title: 'New Tour',
  summary: 'Published route',
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  landmarkId: 'attraction-1',
  priceAmount: 120,
  currency: 'KZT',
  coverFileId: 'cover-file-id',
  publishedOffersCount: 1,
);

const _publishedProductDetails = TourVm(
  id: 'product-new',
  title: 'New Tour',
  summary: 'Published route',
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  landmarkId: 'attraction-1',
  priceAmount: 120,
  currency: 'KZT',
  coverFileId: 'cover-file-id',
  publishedOffersCount: 1,
  offers: [
    TourOfferVm(
      id: 'offer-new',
      productId: 'product-new',
      legacyTourId: 'tour-new',
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

const _updatedLegacyTour = TourVm(
  id: 'tour-new',
  title: 'New Tour',
  summary: 'Updated legacy route',
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  landmarkId: 'attraction-1',
  priceAmount: 150,
  currency: 'KZT',
);

const _updatedProductDetails = TourVm(
  id: 'product-new-updated',
  title: 'New Tour',
  summary: 'Updated product route',
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  landmarkId: 'attraction-1',
  priceAmount: 150,
  currency: 'KZT',
  publishedOffersCount: 1,
  offers: [
    TourOfferVm(
      id: 'offer-new',
      productId: 'product-new-updated',
      legacyTourId: 'tour-new',
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

const _request = CreateTourRequest(
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
    CreateTourItineraryItemRequest(
      startOffsetMinutes: 0,
      title: 'Meet guide',
      description: 'Meet the guide and begin.',
    ),
  ],
);

class _FakeTourApi extends TourApi {
  _FakeTourApi({
    required this.tourBatches,
    required this.createdTour,
    required this.publishedTour,
    this.updatedTour,
    this.tourDetails = const {},
  });

  final List<List<TourVm>> tourBatches;
  final TourVm createdTour;
  final TourVm publishedTour;
  final TourVm? updatedTour;
  final Map<String, TourVm> tourDetails;
  int getToursCallCount = 0;
  final List<String> getTourByIdCalls = [];

  @override
  Future<List<TourVm>> getTours({
    int limit = 50,
    int offset = 0,
    String? query,
    String? categorySlug,
    String? cityName,
  }) async {
    final index = getToursCallCount;
    getToursCallCount++;
    if (index >= tourBatches.length) {
      return tourBatches.last;
    }
    return tourBatches[index];
  }

  @override
  Future<TourVm> createTour(CreateTourRequest request) async {
    return createdTour;
  }

  @override
  Future<TourVm> publishTour(String tourId) async {
    return publishedTour;
  }

  @override
  Future<TourVm> getTourById(String tourId) async {
    getTourByIdCalls.add(tourId);
    return tourDetails[tourId] ?? publishedTour;
  }

  @override
  Future<TourVm> updateTourOffer(
    String legacyTourId,
    CreateTourRequest request,
  ) async {
    return updatedTour ?? publishedTour;
  }
}
