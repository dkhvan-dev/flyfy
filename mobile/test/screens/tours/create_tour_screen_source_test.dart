import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('create tour screen keeps a responsive three-step guide flow', () async {
    final source = await File(
      'lib/screens/tours/create_tour_screen.dart',
    ).readAsString();

    expect(source, contains('class CreateTourScreen'));
    expect(source, contains('PageView('));
    expect(source, contains('_TourStepIndicator'));
    expect(source, contains('_buildStepLandmark'));
    expect(source, contains('_buildStepLogistics'));
    expect(source, contains('_buildStepStoryAndPrice'));
    expect(source, contains('MediaQuery.viewInsetsOf(context).bottom'));
    expect(source, contains('ListView('));
    expect(source, isNot(contains('height: 500')));
  });

  test('router exposes create tour as an authenticated route', () async {
    final routerSource =
        await File('lib/core/router/app_router.dart').readAsString();

    expect(routerSource, contains("path: '/tours/create'"));
    expect(routerSource, contains('CreateTourScreen'));
    expect(routerSource, isNot(contains("location == '/tours/create'")));
  });
}
