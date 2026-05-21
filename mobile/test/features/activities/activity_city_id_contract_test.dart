import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/features/activities/models/activity_list_item_vm.dart';
import 'package:superapp/features/activities/models/create_activity_request.dart';
import 'package:superapp/features/activities/models/update_activity_request.dart';

void main() {
  test(
      'activity response model keeps canonical city id with city name fallback',
      () {
    final activity = ActivityListItemVm.fromJson({
      'id': 'activity-1',
      'hostUserId': 'host-1',
      'title': 'Coffee walk',
      'description': 'Walk and talk',
      'format': 'OFFLINE',
      'status': 'ENROLLMENT_OPEN',
      'moderationStatus': 'APPROVED',
      'visibility': 'PUBLIC',
      'joinMode': 'AUTO_APPROVE',
      'categorySlug': 'social-nightlife',
      'subcategorySlug': 'social-meetup',
      'languageCode': 'ru',
      'timezone': 'Asia/Almaty',
      'startAt': '2026-06-01T10:00:00Z',
      'endAt': '2026-06-01T12:00:00Z',
      'capacityType': 'LIMITED',
      'priceType': 'FREE',
      'requiresProfileCompletion': true,
      'requiresAttendanceConfirmation': false,
      'countryCode': 'KZ',
      'cityId': 'almaty',
      'cityName': 'Almaty',
    });

    expect(activity.cityId, 'almaty');
    expect(activity.cityName, 'Almaty');
    expect(activity.subcategorySlug, 'social-meetup');
  });

  test('create and update requests send city and taxonomy fields', () {
    final createJson = CreateActivityRequest(
      title: 'Coffee walk',
      description: 'Walk and talk around the city',
      format: 'OFFLINE',
      visibility: 'PUBLIC',
      categorySlug: 'social-nightlife',
      subcategorySlug: 'social-meetup',
      languageCode: 'ru',
      timezone: 'Asia/Almaty',
      startAt: DateTime.utc(2026, 6, 1, 10),
      endAt: DateTime.utc(2026, 6, 1, 12),
      capacityType: 'LIMITED',
      priceType: 'FREE',
      countryCode: 'KZ',
      cityId: 'almaty',
      cityName: 'Almaty',
    ).toJson();

    expect(createJson['cityId'], 'almaty');
    expect(createJson['cityName'], 'Almaty');
    expect(createJson['subcategorySlug'], 'social-meetup');

    final updateJson = UpdateActivityRequest(
      subcategorySlug: 'social-meetup',
      hasSubcategorySlug: true,
      cityId: 'almaty',
      hasCityId: true,
      cityName: 'Almaty',
      hasCityName: true,
    ).toJson();

    expect(updateJson['hasSubcategorySlug'], isTrue);
    expect(updateJson['subcategorySlug'], 'social-meetup');
    expect(updateJson['hasCityId'], isTrue);
    expect(updateJson['cityId'], 'almaty');
    expect(updateJson['cityName'], 'Almaty');
  });
}
