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

  test(
    'participants sheet starts from bottom without transparent safe-area gap',
    () async {
      final source = await File(
        'lib/screens/activities/activity_details_screen.dart',
      ).readAsString();

      final sheetStart = source.indexOf('Future<void> _showParticipantsSheet');
      final nextBuildStart = source.indexOf('@override', sheetStart);
      expect(sheetStart, isNonNegative);
      expect(nextBuildStart, greaterThan(sheetStart));

      final sheetSource = source.substring(sheetStart, nextBuildStart);
      expect(sheetSource, contains('SafeArea('));
      expect(sheetSource, contains('bottom: false'));
      expect(
        sheetSource,
        contains('MediaQuery.viewPaddingOf(sheetContext).bottom'),
      );
    },
  );

  test(
    'meeting section localizes address text below map',
    () async {
      final source = await File(
        'lib/screens/activities/activity_details_screen.dart',
      ).readAsString();

      final sectionStart = source.indexOf('class _MeetingSection');
      final nextSectionStart = source.indexOf('class _MeetingMapCard');
      expect(sectionStart, isNonNegative);
      expect(nextSectionStart, greaterThan(sectionStart));

      final sectionSource = source.substring(sectionStart, nextSectionStart);
      expect(sectionSource, contains('AppLocalizedLocationText('));
      expect(sectionSource, contains('addressText: activity.addressText'));
      expect(sectionSource,
          isNot(contains('child: Text(\n                showProtectedNotice')));
    },
  );

  test(
    'details screen does not look up providers from dispose',
    () async {
      final source = await File(
        'lib/screens/activities/activity_details_screen.dart',
      ).readAsString();

      final stateStart = source.indexOf('class _ActivityDetailsScreenState');
      final disposeStart = source.indexOf('void dispose()', stateStart);
      final disposeEnd =
          source.indexOf('Future<void> _refreshScreen', disposeStart);

      expect(stateStart, isNonNegative);
      expect(disposeStart, greaterThan(stateStart));
      expect(disposeEnd, greaterThan(disposeStart));

      final disposeSource = source.substring(disposeStart, disposeEnd);
      expect(
        disposeSource,
        isNot(contains('context.read<ActivityProvider>()')),
      );
      expect(source, contains('ActivityProvider? _activityProvider;'));
      expect(source, contains('void didChangeDependencies()'));
      expect(source,
          contains('_activityProvider = context.read<ActivityProvider>();'));
    },
  );
}
