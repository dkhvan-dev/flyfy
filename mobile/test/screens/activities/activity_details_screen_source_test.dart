import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'details route forwards initial activity from navigation extra',
    () async {
      final routerSource =
          await File('lib/core/router/app_router.dart').readAsString();

      final detailsRouteStart = routerSource.indexOf(
        "path: '/activities/:activityId'",
      );
      final attendanceRouteStart = routerSource.indexOf(
        "path: '/activities/:activityId/attendance-qr'",
      );
      expect(detailsRouteStart, isNonNegative);
      expect(attendanceRouteStart, greaterThan(detailsRouteStart));

      final detailsRouteSource = routerSource.substring(
        detailsRouteStart,
        attendanceRouteStart,
      );

      expect(
        detailsRouteSource,
        contains('final initialActivity = state.extra is ActivityListItemVm'),
      );
      expect(
        detailsRouteSource,
        contains('initialActivity: initialActivity'),
      );
    },
  );

  test(
    'details screen keeps first load pending instead of flashing not found',
    () async {
      final source = await File(
        'lib/screens/activities/activity_details_screen.dart',
      ).readAsString();

      expect(
        source,
        contains('this.initialActivity'),
      );
      expect(
        source,
        contains('final ActivityListItemVm? initialActivity;'),
      );
      expect(source, contains('bool _isInitialLoadPending = true;'));
      expect(
        source,
        contains(
            '_isInitialLoadPending || provider.state == ActivitiesState.loading'),
      );
      expect(source, contains('activity == null)'));
    },
  );
}
