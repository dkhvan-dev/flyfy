import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'details route forwards initial activity from navigation extra',
    () async {
      final routerSource = await File(
        'lib/core/router/app_router.dart',
      ).readAsString();

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
      expect(detailsRouteSource, contains('initialActivity: initialActivity'));
    },
  );

  test(
    'details screen keeps first load pending instead of flashing not found',
    () async {
      final source = await File(
        'lib/screens/activities/activity_details_screen.dart',
      ).readAsString();

      expect(source, contains('this.initialActivity'));
      expect(source, contains('final ActivityListItemVm? initialActivity;'));
      expect(source, contains('bool _isInitialLoadPending = true;'));
      expect(
        source,
        contains(
          '_isInitialLoadPending || provider.state == ActivitiesState.loading',
        ),
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

  test('meeting section localizes address text below map', () async {
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
    expect(
      sectionSource,
      isNot(contains('child: Text(\n                showProtectedNotice')),
    );
  });

  test(
    'activity details uses shared MapLibre meeting map and app map links',
    () async {
      final source = await File(
        'lib/screens/activities/activity_details_screen.dart',
      ).readAsString();

      expect(source, contains("import '../../shared/map/app_map_links.dart';"));
      expect(
        source,
        contains("import '../../shared/widgets/app_map_card.dart';"),
      );
      expect(source, contains('AppMapCard('));
      expect(source, contains('target: point'));
      expect(source, contains('hasMarker: true'));
      expect(source, contains('AppMapLinks.buildUrl('));
      expect(source, isNot(contains("package:flutter_map/flutter_map.dart")));
      expect(source, isNot(contains('FlutterMap(')));
      expect(source, isNot(contains('TileLayer(')));
      expect(source, isNot(contains('MarkerLayer(')));
      expect(source, isNot(contains('tile.openstreetmap.org')));
    },
  );

  test('details screen does not look up providers from dispose', () async {
    final source = await File(
      'lib/screens/activities/activity_details_screen.dart',
    ).readAsString();

    final stateStart = source.indexOf('class _ActivityDetailsScreenState');
    final disposeStart = source.indexOf('void dispose()', stateStart);
    final disposeEnd = source.indexOf(
      'Future<void> _refreshScreen',
      disposeStart,
    );

    expect(stateStart, isNonNegative);
    expect(disposeStart, greaterThan(stateStart));
    expect(disposeEnd, greaterThan(disposeStart));

    final disposeSource = source.substring(disposeStart, disposeEnd);
    expect(disposeSource, isNot(contains('context.read<ActivityProvider>()')));
    expect(source, contains('ActivityProvider? _activityProvider;'));
    expect(source, contains('void didChangeDependencies()'));
    expect(
      source,
      contains('_activityProvider = context.read<ActivityProvider>();'),
    );
  });

  test('details screen defers provider notifications from dispose', () async {
    final source = await File(
      'lib/screens/activities/activity_details_screen.dart',
    ).readAsString();
    final providerSource = await File(
      'lib/providers/activity_provider.dart',
    ).readAsString();

    final stateStart = source.indexOf('class _ActivityDetailsScreenState');
    final disposeStart = source.indexOf('void dispose()', stateStart);
    final disposeEnd = source.indexOf(
      'Future<void> _refreshScreen',
      disposeStart,
    );

    expect(stateStart, isNonNegative);
    expect(disposeStart, greaterThan(stateStart));
    expect(disposeEnd, greaterThan(disposeStart));

    final disposeSource = source.substring(disposeStart, disposeEnd);
    expect(
      disposeSource,
      contains('WidgetsBinding.instance.addPostFrameCallback'),
    );
    expect(
      disposeSource,
      contains('clearSelectedActivity(activityId: activityId)'),
    );
    expect(disposeSource, contains('resetActionState()'));
    expect(
      disposeSource,
      isNot(contains('activityProvider?.clearSelectedActivity();')),
    );
    expect(
      disposeSource,
      isNot(contains('activityProvider?.resetActionState();')),
    );
    expect(
      providerSource,
      contains('void clearSelectedActivity({String? activityId})'),
    );
    expect(
      providerSource,
      contains('if (activityId != null && selectedActivity.id != activityId)'),
    );
  });

  test(
    'details footer does not grant chat access for pending participation',
    () async {
      final source = await File(
        'lib/screens/activities/activity_details_screen.dart',
      ).readAsString();

      expect(source, contains('final canOpenParticipantChat ='));
      expect(
        source,
        contains('currentParticipant?.hasConfirmedAccess == true'),
      );
      expect(source, contains('currentParticipant?.requiresPayment == true'));
      expect(source, contains('currentParticipant?.isPendingDecision == true'));
      expect(source, contains('participantStatusLabel:'));
      expect(source, contains('canOpenChat: canOpenParticipantChat'));
      expect(
        source,
        contains('isParticipationPending: isParticipationPending'),
      );
    },
  );
}
