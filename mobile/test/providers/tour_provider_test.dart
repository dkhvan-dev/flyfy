import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/core/network/tour_api.dart';
import 'package:superapp/features/tours/models/create_tour_request.dart';
import 'package:superapp/features/tours/models/tour_vm.dart';
import 'package:superapp/providers/tour_provider.dart';

void main() {
  test('createAndPublishTour inserts published tour into cached list',
      () async {
    final api = _FakeTourApi(
      initialTours: const [_existingTour],
      createdTour: _createdDraft,
      publishedTour: _publishedTour,
    );
    final provider = TourProvider(tourApi: api);

    await provider.loadTours();
    final created = await provider.createAndPublishTour(_request);

    expect(created?.id, 'tour-new');
    expect(provider.tours.map((tour) => tour.id), ['tour-new', 'tour-old']);
    expect(provider.lastCreatedTour?.id, 'tour-new');
  });
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
  priceAmount: 120,
  currency: 'KZT',
  coverFileId: 'cover-file-id',
);

const _request = CreateTourRequest(
  title: 'New Tour',
  summary: 'Draft route',
  description: 'Detailed route description for a guided tour.',
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
    required this.initialTours,
    required this.createdTour,
    required this.publishedTour,
  });

  final List<TourVm> initialTours;
  final TourVm createdTour;
  final TourVm publishedTour;

  @override
  Future<List<TourVm>> getTours({
    int limit = 50,
    int offset = 0,
    String? query,
    String? categorySlug,
    String? cityName,
  }) async {
    return initialTours;
  }

  @override
  Future<TourVm> createTour(CreateTourRequest request) async {
    return createdTour;
  }

  @override
  Future<TourVm> publishTour(String tourId) async {
    return publishedTour;
  }
}
