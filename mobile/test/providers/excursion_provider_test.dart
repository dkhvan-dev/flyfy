import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/core/network/excursion_api.dart';
import 'package:superapp/features/excursions/models/create_excursion_request.dart';
import 'package:superapp/features/excursions/models/excursion_vm.dart';
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
      final provider = ExcursionProvider(excursionApi: api);

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
      final updated =
          await provider.updateExcursionOffer('excursion-new', _request);

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
  });

  final List<List<ExcursionVm>> excursionBatches;
  final ExcursionVm createdExcursion;
  final ExcursionVm publishedExcursion;
  final ExcursionVm? updatedExcursion;
  final Map<String, ExcursionVm> excursionDetails;
  int getExcursionsCallCount = 0;
  final List<String> getExcursionByIdCalls = [];

  @override
  Future<List<ExcursionVm>> getExcursions({
    int limit = 50,
    int offset = 0,
    String? query,
    String? categorySlug,
    String? cityName,
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
}
