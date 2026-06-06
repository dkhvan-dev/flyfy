import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/activities/models/activity_list_item_vm.dart';

void main() {
  test('activity view model defaults host activity rating to 5.0', () {
    final item = ActivityListItemVm.fromJson(_activityPayload());

    expect(item.hostActivityRating, 5.0);
  });

  test('activity view model parses host activity rating separately', () {
    final item = ActivityListItemVm.fromJson(
      _activityPayload(hostActivityRating: 4.25),
    );

    expect(item.hostActivityRating, 4.25);
  });
}

Map<String, Object?> _activityPayload({double? hostActivityRating}) {
  final payload = {
    'id': 'activity-1',
    'hostUserId': 'host-user',
    'title': 'Morning walk',
    'description': 'Easy city walk',
    'format': 'OFFLINE',
    'status': 'PUBLISHED',
    'moderationStatus': 'APPROVED',
    'visibility': 'PUBLIC',
    'joinMode': 'OPEN',
    'categorySlug': 'walks',
    'languageCode': 'ru',
    'timezone': 'Asia/Almaty',
    'startAt': '2026-01-09T10:00:00Z',
    'endAt': '2026-01-09T12:00:00Z',
    'capacityType': 'LIMITED',
    'priceType': 'FREE',
    'requiresProfileCompletion': false,
    'requiresAttendanceConfirmation': false,
  };
  if (hostActivityRating != null) {
    payload['hostActivityRating'] = hostActivityRating;
  }
  return payload;
}
