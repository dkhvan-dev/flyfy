import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'activity details wires translation notice, toggle, and bounded refresh',
    () {
      final source = File(
        'lib/screens/activities/activity_details_screen.dart',
      ).readAsStringSync();

      expect(source, contains('_ActivityTranslationNotice'));
      expect(source, contains('_showOriginalActivityCopy'));
      expect(source, contains('activity.localizedCopy(appLanguageCode)'));
      expect(source, contains('ActivityTranslationNoticeState.pending'));
      expect(source, contains('_translationRefreshAttempts >= 10'));
      expect(source, contains('Timer(const Duration(seconds: 3)'));
    },
  );

  test('activity cards select copy using the active app locale', () {
    final sources = [
      File('lib/screens/activities/activities_screen.dart').readAsStringSync(),
      File(
        'lib/screens/activities/my_activities_screen.dart',
      ).readAsStringSync(),
      File('lib/screens/home/home_screen.dart').readAsStringSync(),
      File(
        'lib/screens/profile/widgets/profile_activity_card.dart',
      ).readAsStringSync(),
    ];

    for (final source in sources) {
      expect(source, contains('.localizedCopy('));
    }
  });
}
