import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'successful excursion QR sync refreshes excursion booking state',
    () async {
      final source = await File(
        'lib/screens/attendance/attendance_scanner_screen.dart',
      ).readAsString();

      expect(
        source,
        contains("import '../../providers/excursion_provider.dart';"),
      );
      expect(source, contains('_refreshExcursionAttendanceState'));
      expect(source, contains('AttendanceQueueItem.typeExcursion'));
      expect(source, contains('result.isSynced || result.isAlreadySynced'));
      expect(source, contains('refreshMyExcursionBookings'));
      expect(source, contains('refreshGuideDashboardData'));
    },
  );

  test(
    'attendance scanner uses v2 design system around camera surface',
    () async {
      final source = await File(
        'lib/screens/attendance/attendance_scanner_screen.dart',
      ).readAsString();

      expect(source, contains('app_design_system.dart'));
      expect(source, contains('AppDesignSystem.themeFor(context)'));
      expect(
        source,
        contains('final colors = AppDesignSystem.colorsFor(context)'),
      );
      expect(source, contains('backgroundColor: colors.background'));
      expect(source, contains('colors: colors.screenGradientColors'));
      expect(source, contains('AppPalette.primary'));
      expect(
        source,
        matches(
          RegExp(r'AppButtonStyles\.primary\(\s*context\.appColors\s*,?\s*\)'),
        ),
      );
      expect(source, contains('MobileScanner('));
      expect(source, contains('overlayBuilder:'));
      expect(source, isNot(contains('AppPalette.warmInk')));
      expect(source, isNot(contains('AppPalette.warmOverlay')));
      expect(source, isNot(contains('AppPalette.white')));
      expect(source, isNot(contains('AppPalette.primary')));
    },
  );
}
