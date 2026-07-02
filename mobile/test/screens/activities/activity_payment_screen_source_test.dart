import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'activity payment screen uses adaptive V2 colors instead of legacy palette',
    () async {
      final source = await File(
        'lib/screens/activities/activity_payment_screen.dart',
      ).readAsString();

      expect(
        source,
        contains("import 'package:inflap/core/ui/app_design_system.dart';"),
      );
      expect(source, contains('AppDesignSystem.themeFor(context)'));
      expect(source, contains('AppDesignSystem.colorsFor(context)'));
      expect(source, contains('colors.screenGradientColors'));
      expect(source, isNot(contains('AppPalette.')));
    },
  );

  test('activity payment screen is clearly marked as mock checkout', () async {
    final source = await File(
      'lib/screens/activities/activity_payment_screen.dart',
    ).readAsString();
    final enArb = await File('lib/l10n/app_en.arb').readAsString();
    final ruArb = await File('lib/l10n/app_ru.arb').readAsString();
    final kkArb = await File('lib/l10n/app_kk.arb').readAsString();

    expect(source, contains('_PaymentModeNotice('));
    expect(source, contains('activityPaymentMockNoticeTitle'));
    expect(source, contains('activityPaymentMockNoticeBody'));
    expect(source, contains('activityPaymentSandboxMethodLabel'));
    expect(source, contains('activityPaymentMockSecureNote'));
    expect(source, isNot(contains('_PaymentMethod.applePay')));
    expect(source, isNot(contains('_PaymentMethod.googlePay')));
    expect(source, isNot(contains('_SavedCardOption(')));

    for (final arb in [enArb, ruArb, kkArb]) {
      expect(arb, contains('"activityPaymentMockNoticeTitle"'));
      expect(arb, contains('"activityPaymentMockNoticeBody"'));
      expect(arb, contains('"activityPaymentSandboxMethodLabel"'));
      expect(arb, contains('"activityPaymentMockSecureNote"'));
    }
  });

  test('activity payment footer avoids fixed-height text clipping', () async {
    final source = await File(
      'lib/screens/activities/activity_payment_screen.dart',
    ).readAsString();

    final footerStart = source.indexOf('class _PaymentFooter');
    expect(footerStart, isNonNegative);
    final topBarStart = source.indexOf('class _PaymentTopBar');
    expect(topBarStart, greaterThan(footerStart));
    final footerSource = source.substring(footerStart, topBarStart);

    expect(footerSource, contains('ConstrainedBox('));
    expect(footerSource, contains('minHeight: compact ? 64 : 70'));
    expect(footerSource, contains('FittedBox('));
    expect(footerSource, contains('maxLines: 2'));
    expect(footerSource, isNot(contains('height: compact ? 70 : 78')));
  });

  test('activity payment summary media is aspect-ratio based', () async {
    final source = await File(
      'lib/screens/activities/activity_payment_screen.dart',
    ).readAsString();

    final summaryStart = source.indexOf('class _SummaryCard');
    final contentStart = source.indexOf('class _SummaryTextContent');
    expect(summaryStart, isNonNegative);
    expect(contentStart, greaterThan(summaryStart));

    final summarySource = source.substring(summaryStart, contentStart);
    expect(summarySource, contains('AspectRatio('));
    expect(summarySource, isNot(contains('height: compact ? 154 : 126')));
    expect(summarySource, isNot(contains('SizedBox(width: 132')));
  });
}
