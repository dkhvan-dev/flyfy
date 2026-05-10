import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/features/tours/models/tour_vm.dart';

void main() {
  test('parses public tour list fields from tour-service response', () {
    final tour = TourVm.fromJson(const {
      'id': 'tour-1',
      'landmarkName': 'Medeu',
      'title': 'Almaty Mountain Escape',
      'summary': 'Private mountain route',
      'categorySlug': 'adventure',
      'tags': ['mountains', 'photo'],
      'durationMinutes': 240,
      'maxGroupSize': 8,
      'languageCodes': ['en', 'ru'],
      'status': 'PUBLISHED',
      'visibility': 'PUBLIC',
      'priceAmount': 120,
      'currency': 'USD',
      'cityName': 'Almaty',
      'coverFileId': 'cover-file-id',
    });

    expect(tour.id, 'tour-1');
    expect(tour.landmarkName, 'Medeu');
    expect(tour.categorySlug, 'adventure');
    expect(tour.durationMinutes, 240);
    expect(tour.maxGroupSize, 8);
    expect(tour.languageCodes, ['en', 'ru']);
    expect(tour.tags, ['mountains', 'photo']);
  });
}
