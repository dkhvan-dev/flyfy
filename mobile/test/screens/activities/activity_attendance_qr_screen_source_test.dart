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

  test(
    'activity attendance QR image sizes itself from available space',
    () async {
      final source = await File(
        'lib/screens/activities/activity_attendance_qr_screen.dart',
      ).readAsString();

      final bodyStart = source.indexOf('Widget _buildQrBody');
      expect(bodyStart, isNonNegative);
      final bodySource = source.substring(bodyStart);

      expect(bodySource, contains('LayoutBuilder('));
      expect(bodySource, contains('constraints.biggest.shortestSide'));
      expect(bodySource, isNot(contains('size: 280')));
    },
  );

  test('activity attendance QR screen uses adaptive V2 colors', () async {
    final source = await File(
      'lib/screens/activities/activity_attendance_qr_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.themeFor(context)'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.screenGradientColors'));
    expect(source, contains('_attendanceQrCardDecoration('));
    expect(source, contains('AppColors colors'));
    expect(source, contains('colors.surface'));
    expect(source, contains('colors.surfaceRaised'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, contains('colors.textSecondary'));
    expect(source, contains('colors.danger'));
    expect(source, isNot(contains('AppPalette.')));
  });
}
