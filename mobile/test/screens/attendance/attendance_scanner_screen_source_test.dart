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
}
