import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tours screen loads public tours and guards guide-only creation',
      () async {
    final source =
        await File('lib/screens/tours/tours_screen.dart').readAsString();

    expect(source, contains('class ToursScreen'));
    expect(source, contains('loadTours('));
    expect(source, contains('refreshTours('));
    expect(source, contains('profile?.isGuide == true'));
    expect(source, contains('ToursBottomNavigation'));
    expect(source, contains('CreateActionBottomNavigationBar'));
    expect(source, contains('CommonBottomNavigationBar'));
    expect(source, contains("context.push('/tours/create')"));
    expect(source, contains("context.push('/map')"));
  });

  test('router exposes tours list as a public route', () async {
    final routerSource =
        await File('lib/core/router/app_router.dart').readAsString();

    expect(routerSource, contains("path: '/tours'"));
    expect(routerSource, contains('ToursScreen'));
    expect(routerSource, contains("location == '/tours'"));
  });

  test('tour provider has list loading and refresh states', () async {
    final providerSource =
        await File('lib/providers/tour_provider.dart').readAsString();

    expect(providerSource, contains('Future<void> loadTours'));
    expect(providerSource, contains('Future<void> refreshTours'));
    expect(providerSource, contains('List<TourVm>'));
  });
}
