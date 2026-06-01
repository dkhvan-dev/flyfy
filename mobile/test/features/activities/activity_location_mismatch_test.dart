import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/activities/activity_location_mismatch.dart';

void main() {
  test(
    'does not warn for the same Kazakhstan city written in another locale',
    () {
      final differs = activityMeetingLocationDiffersFromAuthorLocation(
        format: 'OFFLINE',
        didApplyAuthorLocationSnapshot: true,
        authorCountryCode: 'KZ',
        authorCityName: 'Almaty',
        meetingCountryCode: 'KZ',
        meetingCityName: 'Алматы қаласы',
      );

      expect(differs, isFalse);
    },
  );

  test('warns when country differs', () {
    final differs = activityMeetingLocationDiffersFromAuthorLocation(
      format: 'OFFLINE',
      didApplyAuthorLocationSnapshot: true,
      authorCountryCode: 'KZ',
      authorCityName: 'Almaty',
      meetingCountryCode: 'KG',
      meetingCityName: 'Almaty',
    );

    expect(differs, isTrue);
  });

  test('warns when city differs inside the same country', () {
    final differs = activityMeetingLocationDiffersFromAuthorLocation(
      format: 'OFFLINE',
      didApplyAuthorLocationSnapshot: true,
      authorCountryCode: 'KZ',
      authorCityName: 'Almaty',
      meetingCountryCode: 'KZ',
      meetingCityName: 'Astana',
    );

    expect(differs, isTrue);
  });

  test('does not warn when canonical city ids match', () {
    final differs = activityMeetingLocationDiffersFromAuthorLocation(
      format: 'OFFLINE',
      didApplyAuthorLocationSnapshot: true,
      authorCountryCode: 'KZ',
      authorCityId: 'almaty',
      authorCityName: 'Almaty',
      meetingCountryCode: 'KZ',
      meetingCityId: 'ALMATY',
      meetingCityName: 'Алматы',
    );

    expect(differs, isFalse);
  });

  test('does not warn when city cannot be compared confidently', () {
    final differs = activityMeetingLocationDiffersFromAuthorLocation(
      format: 'OFFLINE',
      didApplyAuthorLocationSnapshot: true,
      authorCountryCode: 'KZ',
      meetingCountryCode: 'KZ',
      meetingCityName: 'Алматы',
    );

    expect(differs, isFalse);
  });
}
