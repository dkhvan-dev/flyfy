import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Future<String> _read(String path) => File(path).readAsString();

void main() {
  test('list screens use the shared list screen header', () async {
    final files = <String>[
      'lib/screens/activities/activities_screen.dart',
      'lib/screens/activities/my_activities_screen.dart',
      'lib/screens/attractions/attractions_screen.dart',
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

  test('bottom navigation can render without an active item off home',
      () async {
    final bottomNavSource = await _read(
      'lib/core/ui/app_bottom_navigation_bars.dart',
    );
    final attractionsSource = await _read(
      'lib/screens/attractions/attractions_screen.dart',
    );
    final homeSource = await _read('lib/screens/home/home_screen.dart');

    expect(bottomNavSource, contains('final AppBottomNavItem? activeItem;'));
    expect(attractionsSource,
        isNot(contains('activeItem: AppBottomNavItem.home')));
    expect(homeSource, contains('activeItem: AppBottomNavItem.home'));
  });
}
