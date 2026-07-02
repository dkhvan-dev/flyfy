import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('my subscriptions block uses adaptive V2 colors only', () async {
    final source = await File(
      'lib/features/feed/widgets/my_subscriptions_block.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.background'));
    expect(source, contains('colors.surface'));
    expect(source, contains('colors.surfaceHigh'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, contains('colors.textSecondary'));
    expect(source, contains('colors.textMuted'));
    expect(source, contains('colors.border'));
    expect(source, contains('colors.transparent'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test(
    'my subscriptions rail cards use visible V2 surface and outline',
    () async {
      final source = await File(
        'lib/features/feed/widgets/my_subscriptions_block.dart',
      ).readAsString();

      final pillStart = source.indexOf('class _SubscriptionPill');
      final listStart = source.indexOf('class _CommunitySubscriptionList');
      expect(pillStart, isNonNegative);
      expect(listStart, greaterThan(pillStart));

      final pillSource = source.substring(pillStart, listStart);
      expect(pillSource, contains('color: colors.surfaceHigh,'));
      expect(pillSource, contains('shape: RoundedRectangleBorder('));
      expect(pillSource, contains('side: BorderSide('));
      expect(
        pillSource,
        contains('color: colors.primary.withValues(alpha: 0.42),'),
      );
      expect(pillSource, contains('width: 1.2,'));
      expect(pillSource, contains('clipBehavior: Clip.antiAlias'));
    },
  );
}
