import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/features/tours/models/create_tour_request.dart';

void main() {
  test('serializes guide tour creation payload for tour-service', () {
    final request = CreateTourRequest(
      landmarkName: 'Medeu',
      title: 'Almaty Mountain Escape',
      summary: 'Private mountain route',
      description:
          'A guided route through the most scenic mountain stops around Almaty.',
      categorySlug: 'adventure',
      tags: const ['mountains', 'photo'],
      durationMinutes: 240,
      maxGroupSize: 8,
      languageCodes: const ['en', 'ru'],
      visibility: 'UNLISTED',
      meetingPoint: 'Hotel pickup',
      countryCode: 'KZ',
      cityName: 'Almaty',
      latitude: 43.238949,
      longitude: 76.889709,
      mapUrl: 'https://maps.example.test/medeu',
      priceAmount: 120,
      currency: 'USD',
      includedItems: const ['Private SUV', 'Gourmet picnic'],
      itinerary: const [
        CreateTourItineraryItemRequest(
          startOffsetMinutes: 0,
          durationMinutes: 45,
          title: 'Hotel departure',
          description: 'Meet your guide and start the route.',
        ),
      ],
      coverFileId: 'cover-file-id',
    );

    expect(request.toJson(), {
      'landmarkName': 'Medeu',
      'title': 'Almaty Mountain Escape',
      'summary': 'Private mountain route',
      'description':
          'A guided route through the most scenic mountain stops around Almaty.',
      'categorySlug': 'adventure',
      'tags': ['mountains', 'photo'],
      'durationMinutes': 240,
      'maxGroupSize': 8,
      'languageCodes': ['en', 'ru'],
      'visibility': 'UNLISTED',
      'meetingPoint': 'Hotel pickup',
      'countryCode': 'KZ',
      'cityName': 'Almaty',
      'latitude': 43.238949,
      'longitude': 76.889709,
      'mapUrl': 'https://maps.example.test/medeu',
      'priceAmount': 120.0,
      'currency': 'USD',
      'includedItems': ['Private SUV', 'Gourmet picnic'],
      'itinerary': [
        {
          'startOffsetMinutes': 0,
          'durationMinutes': 45,
          'title': 'Hotel departure',
          'description': 'Meet your guide and start the route.',
        },
      ],
      'coverFileId': 'cover-file-id',
    });
  });

  test('omits optional blank fields from tour payload', () {
    final request = CreateTourRequest(
      title: 'City Walk',
      summary: 'Compact city walk',
      description: 'A compact guided walk through a memorable city route.',
      categorySlug: 'cultural',
      durationMinutes: 90,
      maxGroupSize: 6,
      languageCodes: const ['en'],
      meetingPoint: 'Main square',
      priceAmount: 0,
      currency: 'KZT',
      itinerary: const [
        CreateTourItineraryItemRequest(
          startOffsetMinutes: 0,
          title: 'Meet and greet',
          description: 'Meet the guide and start exploring.',
        ),
      ],
    );

    final json = request.toJson();

    expect(json, isNot(contains('landmarkName')));
    expect(json, isNot(contains('tags')));
    expect(json, isNot(contains('includedItems')));
    expect(json, isNot(contains('coverFileId')));
    expect(json['visibility'], 'PUBLIC');
    expect(json['priceAmount'], 0.0);
  });
}
