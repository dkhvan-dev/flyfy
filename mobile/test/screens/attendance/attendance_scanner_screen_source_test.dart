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
    'attendance scanner uses fullscreen camera with transparent overlay controls',
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
      expect(source, contains('StackFit.expand'));
      expect(source, contains('Positioned.fill('));
      expect(source, contains('key: const ValueKey('));
      expect(source, contains("'qr-scanner-transparent-fullscreen-overlay'"));
      expect(source, contains('MobileScanner('));
      expect(source, contains('overlayBuilder:'));
      expect(source, contains('Positioned('));
      expect(source, contains('l10n.qrScannerSubtitle'));
      expect(source, isNot(contains('l10n.qrScannerTitle')));
      expect(source, contains('if (_feedbackMessage != null)'));
      expect(source, contains('if (_pendingCount > 0)'));
      expect(
        source,
        isNot(contains('_feedbackMessage ?? l10n.qrScannerReady')),
      );
      expect(source, isNot(contains(': l10n.qrScannerNoPending')));
      expect(source, contains('AppButtonStyles.secondary(colors)'));
      expect(source, isNot(contains('AppButtonStyles.primary(colors)')));
      expect(source, isNot(contains('color: AppPalette.primary')));
      expect(source, isNot(contains('AppPalette.primary.withValues')));
      expect(
        source,
        isNot(contains('borderRadius: AppBorderRadius.circular(30)')),
      );
      expect(source, isNot(contains('AppPalette.warmInk')));
      expect(source, isNot(contains('AppPalette.warmOverlay')));
      expect(source, isNot(contains('AppPalette.white')));
    },
  );

  test(
    'attendance scanner keeps camera active and uses idempotent scan ids',
    () async {
      final source = await File(
        'lib/screens/attendance/attendance_scanner_screen.dart',
      ).readAsString();

      expect(source, contains('scanIdForProof('));
      expect(source, isNot(contains('_stopScanner')));
      expect(source, isNot(contains('_restartScanner')));
      expect(source, isNot(contains('_isScannerStopped')));
      expect(source, isNot(contains('l10n.qrScannerScanAgain')));
    },
  );

  test('attendance scanner short QR prompt is localized', () async {
    final ruArb = await File('lib/l10n/app_ru.arb').readAsString();
    final enArb = await File('lib/l10n/app_en.arb').readAsString();
    final kkArb = await File('lib/l10n/app_kk.arb').readAsString();

    expect(ruArb, contains('"qrScannerSubtitle": "Наведите камеру на QR"'));
    expect(
      enArb,
      contains('"qrScannerSubtitle": "Point the camera at the QR"'),
    );
    expect(kkArb, contains('"qrScannerSubtitle": "Камераны QR-ға бағыттаңыз"'));
  });
}
