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

  test('parses public tour detail fields from tour-service response', () {
    final tour = TourVm.fromJson(const {
      'id': 'tour-1',
      'guideProfileId': 'guide-profile-1',
      'guideUserId': 'guide-user-1',
      'landmarkName': 'Medeu',
      'title': 'Almaty Mountain Escape',
      'summary': 'Private mountain route',
      'description': 'A private alpine route through Shymbulak and Medeu.',
      'categorySlug': 'adventure',
      'tags': ['mountains', 'photo'],
      'durationMinutes': 480,
      'maxGroupSize': 4,
      'languageCodes': ['en', 'ru'],
      'status': 'PUBLISHED',
      'visibility': 'PUBLIC',
      'meetingPoint': 'Hotel pickup',
      'countryCode': 'KZ',
      'cityName': 'Almaty',
      'latitude': 43.238949,
      'longitude': 76.889709,
      'mapUrl': 'https://maps.example.test/medeu',
      'priceAmount': 240,
      'currency': 'USD',
      'coverFileId': 'cover-file-id',
      'coverImageUrl': 'https://cdn.example.test/cover.jpg',
      'includedItems': ['Private SUV', 'Gourmet picnic'],
      'itinerary': [
        {
          'id': 'step-1',
          'sortOrder': 0,
          'startOffsetMinutes': 0,
          'durationMinutes': 45,
          'title': 'Hotel departure',
          'description': 'Luxury SUV pickup from your hotel.',
        },
      ],
    });

    expect(tour.guideProfileId, 'guide-profile-1');
    expect(tour.guideUserId, 'guide-user-1');
    expect(tour.description, contains('private alpine route'));
    expect(tour.meetingPoint, 'Hotel pickup');
    expect(tour.countryCode, 'KZ');
    expect(tour.latitude, 43.238949);
    expect(tour.longitude, 76.889709);
    expect(tour.mapUrl, 'https://maps.example.test/medeu');
    expect(tour.coverImageUrl, 'https://cdn.example.test/cover.jpg');
    expect(tour.includedItems, ['Private SUV', 'Gourmet picnic']);
    expect(tour.itinerary, hasLength(1));
    expect(tour.itinerary.first.title, 'Hotel departure');
    expect(tour.itinerary.first.durationMinutes, 45);
  });
}
