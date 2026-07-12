import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/activities/models/activity_list_item_vm.dart';
import 'package:inflap/features/activities/models/create_activity_request.dart';
import 'package:inflap/features/activities/models/update_activity_request.dart';

void main() {
  group('activity translations', () {
    test('selects translated copy for the app language', () {
      final activity = ActivityListItemVm.fromJson(
        _activityJson(
          translationStatus: 'COMPLETED',
          translations: {
            'ru': {
              'title': 'Поход в горы',
              'description': 'Подробное описание похода в горы.',
            },
            'en': {
              'title': 'Mountain hike',
              'description': 'Detailed mountain hike description.',
            },
          },
        ),
      );

      expect(activity.localizedCopy('en-US').title, 'Mountain hike');
      expect(
        activity.translationNoticeState('en'),
        ActivityTranslationNoticeState.translated,
      );
      expect(
        activity.translationNoticeState('ru'),
        ActivityTranslationNoticeState.none,
      );
    });

    test('keeps original while translation is pending or unavailable', () {
      final pending = ActivityListItemVm.fromJson(
        _activityJson(
          translationStatus: 'PENDING',
          translations: const <String, Object>{},
        ),
      );
      final failed = ActivityListItemVm.fromJson(
        _activityJson(
          translationStatus: 'FAILED',
          translations: const <String, Object>{},
        ),
      );

      expect(pending.localizedCopy('kk').title, 'Поход в горы');
      expect(
        pending.translationNoticeState('kk'),
        ActivityTranslationNoticeState.pending,
      );
      expect(
        failed.translationNoticeState('en'),
        ActivityTranslationNoticeState.unavailable,
      );
    });

    test('create and update contracts send source language explicitly', () {
      final create = CreateActivityRequest(
        title: 'Mountain hike',
        description: 'Detailed mountain hike description.',
        sourceLanguage: 'en',
        format: 'OFFLINE',
        visibility: 'PUBLIC',
        categorySlug: 'nature',
        languageCode: 'ru',
        timezone: 'Asia/Almaty',
        startAt: DateTime.utc(2026, 7, 20, 10),
        endAt: DateTime.utc(2026, 7, 20, 12),
        capacityType: 'LIMITED',
        priceType: 'FREE',
      );
      final update = UpdateActivityRequest(sourceLanguage: 'kk');

      expect(create.toJson()['sourceLanguage'], 'en');
      expect(update.toJson()['sourceLanguage'], 'kk');
    });
  });
}

Map<String, dynamic> _activityJson({
  required String translationStatus,
  required Map<String, Object> translations,
}) {
  return {
    'id': 'activity-id',
    'hostUserId': 'host-id',
    'title': 'Поход в горы',
    'description': 'Подробное описание похода в горы.',
    'sourceLanguage': 'ru',
    'translationStatus': translationStatus,
    'translations': translations,
    'format': 'OFFLINE',
    'status': 'ENROLLMENT_OPEN',
    'moderationStatus': 'APPROVED',
    'visibility': 'PUBLIC',
    'joinMode': 'AUTO_APPROVE',
    'categorySlug': 'nature',
    'languageCode': 'ru',
    'timezone': 'Asia/Almaty',
    'startAt': '2026-07-20T10:00:00Z',
    'endAt': '2026-07-20T12:00:00Z',
    'capacityType': 'LIMITED',
    'priceType': 'FREE',
    'requiresProfileCompletion': true,
    'requiresAttendanceConfirmation': false,
  };
}
