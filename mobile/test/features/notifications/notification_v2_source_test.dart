import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('notification presentation widgets use V2 colors', () async {
    final bannerSource = await File(
      'lib/features/notifications/presentation/push_notification_banner.dart',
    ).readAsString();
    final badgeSource = await File(
      'lib/features/notifications/presentation/notification_unread_badge.dart',
    ).readAsString();
    final coordinatorSource = await File(
      'lib/features/notifications/presentation/push_notification_coordinator.dart',
    ).readAsString();

    expect(bannerSource, contains('app_design_system.dart'));
    expect(bannerSource, contains('AppDesignSystem.colorsFor(context)'));
    expect(bannerSource, contains('visual.color(colors)'));
    expect(bannerSource, isNot(contains('AppPalette.')));

    expect(badgeSource, contains('app_design_system.dart'));
    expect(badgeSource, contains('AppDesignSystem.colorsFor(context)'));
    expect(badgeSource, isNot(contains('AppPalette.')));

    expect(coordinatorSource, contains('app_design_system.dart'));
    expect(coordinatorSource, contains('AppPalette.secondary'));
    expect(
      coordinatorSource.replaceAll('AppPalette.secondary', ''),
      isNot(contains('AppPalette.')),
    );
  });

  test('notification unread badge centers text optically', () async {
    final badgeSource = await File(
      'lib/features/notifications/presentation/notification_unread_badge.dart',
    ).readAsString();

    final navBadgeStart = badgeSource.indexOf('class _NavBadge');
    final badgeLabelStart = badgeSource.indexOf('String _badgeLabel');
    expect(navBadgeStart, isNonNegative);
    expect(badgeLabelStart, greaterThan(navBadgeStart));

    final navBadgeSource = badgeSource.substring(
      navBadgeStart,
      badgeLabelStart,
    );
    expect(navBadgeSource, contains('height: 22'));
    expect(navBadgeSource, contains('alignment: Alignment.center'));
    expect(navBadgeSource, contains('TextHeightBehavior('));
    expect(navBadgeSource, contains('StrutStyle('));
    expect(navBadgeSource, isNot(contains('vertical: 2')));
  });
}
