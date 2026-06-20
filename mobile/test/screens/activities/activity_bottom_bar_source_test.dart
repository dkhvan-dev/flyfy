import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'activity screens use the shared localized create action bottom bar',
    () async {
      final legacyBottomBar = File(
        'lib/screens/activities/widgets/activities_bottom_bar.dart',
      );
      final activitiesSource = await File(
        'lib/screens/activities/activities_screen.dart',
      ).readAsString();
      final myActivitiesSource = await File(
        'lib/screens/activities/my_activities_screen.dart',
      ).readAsString();
      final sharedBottomBarSource = await File(
        'lib/core/ui/app_bottom_navigation_bars.dart',
      ).readAsString();

      expect(legacyBottomBar.existsSync(), isFalse);
      expect(activitiesSource, contains('CreateActionBottomNavigationBar'));
      expect(myActivitiesSource, contains('CreateActionBottomNavigationBar'));
      expect(sharedBottomBarSource, contains('l10n.homeNavHome'));
      expect(sharedBottomBarSource, contains('l10n.homeNavQr'));
      expect(sharedBottomBarSource, contains('l10n.servicesSectionTitle'));
      expect(sharedBottomBarSource, contains('l10n.homeNavChats'));
      expect(sharedBottomBarSource, contains('l10n.createActivityFab'));
      expect(sharedBottomBarSource, contains('_BottomNavPaintedSafeArea'));
      expect(sharedBottomBarSource, contains('safeBottom: safeBottom'));
    },
  );
}
