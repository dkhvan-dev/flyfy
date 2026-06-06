import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'activity attendance QR countdown ticks every second until refresh',
    () async {
      final source = await File(
        'lib/screens/activities/activity_attendance_qr_screen.dart',
      ).readAsString();

      expect(source, contains('Timer? _countdownTimer'));
      expect(source, contains('DateTime? _refreshAt'));
      expect(source, contains('_refreshAt = qr.refreshAt'));
      expect(source, contains('_restartCountdownTicker()'));
      expect(source, contains('Timer.periodic(const Duration(seconds: 1)'));
      expect(source, contains('final refreshAt = _refreshAt'));
      expect(source, contains('refreshAt.difference(DateTime.now().toUtc())'));
    },
  );

  test(
    'activity attendance QR screen constrains long titles and loading states',
    () async {
      final source = await File(
        'lib/screens/activities/activity_attendance_qr_screen.dart',
      ).readAsString();

      expect(source, contains('maxLines: 2'));
      expect(source, contains('overflow: TextOverflow.ellipsis'));
      expect(source, contains('_qrBodyHeight(context)'));
      expect(
        source,
        contains('final screenHeight = MediaQuery.sizeOf(context).height'),
      );
      expect(source, isNot(contains('height: 360')));
    },
  );
}
