import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Future<String> _read(String path) => File(path).readAsString();

void main() {
  test('shared list screen header uses compact V2 navigation sizing', () async {
    final source = await _read('lib/core/ui/app_list_screen_header.dart');

    expect(source, contains('height ?? (64 * scale).clamp(58.0, 66.0)'));
    expect(
      source,
      contains('horizontalPadding ?? (20 * scale).clamp(16.0, 22.0)'),
    );
    expect(source, contains('topPadding ?? (10 * scale).clamp(8.0, 11.0)'));
    expect(source, contains('bottomPadding ?? (10 * scale).clamp(8.0, 11.0)'));
    expect(source, contains('buttonSize = (42 * scale).clamp(38.0, 44.0)'));
    expect(source, contains('backIconSize = (24 * scale).clamp(22.0, 25.0)'));
    expect(
      source,
      contains('notificationButtonSize = (40 * scale).clamp(38.0, 40.0)'),
    );
    expect(
      source,
      contains('notificationIconSize = (20 * scale).clamp(18.0, 20.0)'),
    );
    expect(source, contains('titleSize = (24 * scale).clamp(20.0, 24.0)'));
    expect(source, isNot(contains('(76 * scale).clamp(68.0, 84.0)')));
    expect(source, isNot(contains('(28 * scale).clamp(22.0, 30.0)')));
  });

  test(
    'shared list header notification button matches the home header style',
    () async {
      final source = await _read('lib/core/ui/app_list_screen_header.dart');
      final sharedSource = await _read(
        'lib/core/ui/app_notification_header_button.dart',
      );
      final notificationStart = source.indexOf('AppNotificationHeaderButton(');

      expect(notificationStart, isNonNegative);

      expect(sharedSource, contains('class AppNotificationHeaderButton'));
      expect(sharedSource, contains('NotificationUnreadBadge('));
      expect(sharedSource, contains('Icons.notifications_none_rounded'));
      expect(
        sharedSource,
        contains('color: colors.primary.withValues(alpha: 0.12)'),
      );
      expect(sharedSource, contains('border: Border.all('));
      expect(sharedSource, contains('colors.primary.withValues(alpha: 0.24)'));
      expect(source, contains('size: notificationButtonSize'));
      expect(source, contains('iconSize: notificationIconSize'));
    },
  );

  test('main notification headers reuse the shared V2 button', () async {
    final files = <String>[
      'lib/screens/home/home_screen.dart',
      'lib/core/ui/app_list_screen_header.dart',
      'lib/features/feed/presentation/feed_screen.dart',
      'lib/screens/excursions/excursion_details_screen.dart',
    ];

    for (final path in files) {
      final source = await _read(path);

      expect(
        source,
        contains('AppNotificationHeaderButton('),
        reason: '$path should reuse the shared notification header button',
      );
    }
  });

  test('list screens use the shared list screen header', () async {
    final files = <String>[
      'lib/screens/activities/activities_screen.dart',
      'lib/screens/activities/my_activities_screen.dart',
      'lib/screens/places/places_screen.dart',
      'lib/screens/guides/guides_screen.dart',
      'lib/screens/stories/stories_screen.dart',
    ];

    for (final path in files) {
      final source = await _read(path);

      expect(
        source,
        contains('AppListScreenHeader'),
        reason: '$path should use the shared list header chrome',
      );
    }
  });

  test(
    'bottom navigation can render without an active item off home',
    () async {
      final bottomNavSource = await _read(
        'lib/core/ui/app_bottom_navigation_bars.dart',
      );
      final placesSource = await _read('lib/screens/places/places_screen.dart');
      final homeSource = await _read('lib/screens/home/home_screen.dart');

      expect(bottomNavSource, contains('final AppBottomNavItem? activeItem;'));
      expect(
        placesSource,
        isNot(contains('activeItem: AppBottomNavItem.home')),
      );
      expect(homeSource, contains('activeItem: AppBottomNavItem.home'));
    },
  );
}
