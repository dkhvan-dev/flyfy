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

  test(
    'activity details meeting card disables native map on mobile read-only view',
    () async {
      final source = await File(
        'lib/screens/activities/activity_details_screen.dart',
      ).readAsString();

      final helperStart = source.indexOf(
        'bool _shouldUseNativeReadOnlyMeetingMap',
      );
      expect(helperStart, isNonNegative);
      final helperEnd = source.indexOf('class ', helperStart);
      expect(helperEnd, greaterThan(helperStart));

      final helperSource = source.substring(helperStart, helperEnd);
      expect(helperSource, contains('TargetPlatform.iOS'));
      expect(helperSource, contains('TargetPlatform.android'));
      expect(helperSource, contains('Theme.of(context).platform'));

      final mapCardStart = source.indexOf('class _MeetingMapCard');
      final fallbackCardStart = source.indexOf(
        'class _MeetingLocationFallbackCard',
        mapCardStart,
      );
      expect(mapCardStart, isNonNegative);
      expect(fallbackCardStart, greaterThan(mapCardStart));

      final mapCardSource = source.substring(mapCardStart, fallbackCardStart);
      expect(mapCardSource, contains('nativeMapEnabled:'));
      expect(
        mapCardSource,
        contains('_shouldUseNativeReadOnlyMeetingMap(context)'),
      );
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

  test(
    'activity details shows trip preparation for participants and host',
    () async {
      final source = await File(
        'lib/screens/activities/activity_details_screen.dart',
      ).readAsString();

      expect(
        source,
        contains(
          'final canPrepareTrip = isOwner || currentParticipant != null;',
        ),
      );

      final statsStart = source.indexOf('_StatsGrid(');
      final participantsStart = source.indexOf('_ParticipantsSection(');
      expect(statsStart, isNonNegative);
      expect(participantsStart, greaterThan(statsStart));

      final betweenStatsAndParticipants = source.substring(
        statsStart,
        participantsStart,
      );
      expect(betweenStatsAndParticipants, contains('if (canPrepareTrip) ...['));
      expect(betweenStatsAndParticipants, contains('TripPreparationCta('));
    },
  );

  test(
    'leaving activity removes cached activity checklist after successful leave',
    () async {
      final source = await File(
        'lib/screens/activities/activity_details_screen.dart',
      ).readAsString();

      expect(
        source,
        contains(
          "import '../../features/checklists/data/checklist_offline_cache.dart';",
        ),
      );
      expect(source, contains('final ChecklistOfflineCache _checklistCache'));

      final leaveStart = source.indexOf('Future<void> _handleLeave() async');
      final paymentStart = source.indexOf(
        'Future<void> _openPayment',
        leaveStart,
      );
      expect(leaveStart, isNonNegative);
      expect(paymentStart, greaterThan(leaveStart));

      final leaveSource = source.substring(leaveStart, paymentStart);
      expect(
        leaveSource,
        contains(
          'final success = await provider.leaveActivity(widget.activityId);',
        ),
      );
      expect(leaveSource, contains('await _removeCachedActivityChecklist();'));
      expect(
        leaveSource.indexOf('await _removeCachedActivityChecklist();'),
        greaterThan(leaveSource.indexOf('if (!success)')),
      );

      expect(
        source,
        contains('Future<void> _removeCachedActivityChecklist() async'),
      );
      expect(source, contains('_checklistCache.removeTripChecklist('));
      expect(source, contains('_activityChecklistTripId(widget.activityId),'));
    },
  );

  test(
    'trip preparation cta action matches join button icon and foreground',
    () async {
      final source = await File(
        'lib/shared/widgets/trip_preparation_cta.dart',
      ).readAsString();

      expect(source, contains('Icons.chevron_right_rounded'));
      expect(source, isNot(contains('Icons.arrow_forward_rounded')));
      expect(source, contains('foregroundColor: AppColors.textPrimary'));
      expect(source, contains('iconAlignment: IconAlignment.end'));
    },
  );

  test('details footer hides total price block for free activities', () async {
    final source = await File(
      'lib/screens/activities/activity_details_screen.dart',
    ).readAsString();

    final actionBarStart = source.indexOf('class _DetailsActionBar');
    final priceBlockStart = source.indexOf('class _FooterPriceBlock');
    expect(actionBarStart, isNonNegative);
    expect(priceBlockStart, greaterThan(actionBarStart));

    final actionBarSource = source.substring(actionBarStart, priceBlockStart);

    expect(actionBarSource, contains('final showPriceBlock ='));
    expect(actionBarSource, contains('!activity.isFree'));
    expect(actionBarSource, contains('if (!showPriceBlock)'));
    expect(actionBarSource, contains('width: double.infinity'));
    expect(actionBarSource, contains('if (showPriceBlock) ...['));
    expect(
      actionBarSource,
      isNot(contains('activity.isFree\n        ? l10n.freeLabel')),
    );
  });

  test(
    'details screen shows reviews section only for completed activities',
    () async {
      final source = await File(
        'lib/screens/activities/activity_details_screen.dart',
      ).readAsString();

      expect(source, contains('final showReviewsSection ='));
      expect(source, contains("status == 'COMPLETED';"));

      final meetingSectionStart = source.indexOf('_MeetingSection(');
      final reviewsSectionStart = source.indexOf('_ActivityReviewsSection(');
      expect(meetingSectionStart, isNonNegative);
      expect(reviewsSectionStart, greaterThan(meetingSectionStart));

      final betweenMeetingAndReviews = source.substring(
        meetingSectionStart,
        reviewsSectionStart,
      );
      expect(
        betweenMeetingAndReviews,
        contains('if (showReviewsSection) ...['),
      );
    },
  );

  test(
    'meeting directions build internal route preview before opening map',
    () async {
      final source = await File(
        'lib/screens/activities/activity_details_screen.dart',
      ).readAsString();

      expect(
        source,
        contains("import '../../providers/routing_provider.dart';"),
      );
      expect(source, contains("import '../map/map_screen.dart';"));
      expect(source, contains('bool _isBuildingMeetingRoute = false;'));
      expect(source, contains('Future<void> _handleMeetingAction('));
      expect(source, contains('Future<void> _openMeetingRoute('));
      expect(source, contains('context.read<RoutingProvider>()'));
      expect(source, contains('detectCoordinates('));
      expect(source, contains('RouteRequestVm('));
      expect(source, contains('RouteProfile.touristWalk'));
      expect(source, contains('MapRoutePreview('));
      expect(source, contains('final origin = RoutePointVm('));
      expect(source, contains('origin: origin'));
      expect(source, contains('extra: routePreview'));
      expect(source, contains('isBuildingRoute: _isBuildingMeetingRoute'));
      expect(source, contains('_openMeetingRoute(activity);'));
    },
  );

  test(
    'meeting section omits ETA reachability claims and keeps route action only',
    () async {
      final source = await File(
        'lib/screens/activities/activity_details_screen.dart',
      ).readAsString();

      expect(
        source,
        isNot(
          contains(
            "import '../../features/routing/widgets/reachability_badge.dart';",
          ),
        ),
      );
      expect(
        source,
        isNot(
          contains(
            "import '../../features/routing/widgets/travel_time_badge.dart';",
          ),
        ),
      );
      expect(source, isNot(contains('EtaResponseVm? _meetingEta;')));
      expect(source, isNot(contains('bool _isCheckingMeetingEta = false;')));
      expect(
        source,
        isNot(contains('Future<void> _checkMeetingReachability(')),
      );
      expect(source, isNot(contains('routingProvider.getEta(')));
      expect(source, isNot(contains('EtaRequestVm(')));
      expect(source, isNot(contains('_MeetingReachabilityCard(')));
      expect(source, isNot(contains('_MeetingReachabilityAction(')));
      expect(source, isNot(contains('activityReachabilityTitle')));
      expect(source, isNot(contains('ReachabilityBadge(')));
      expect(source, isNot(contains('TravelTimeBadge(')));
      expect(source, contains('_openMeetingRoute(activity);'));
    },
  );

  test('meeting route and ETA location lookup have timeout guard', () async {
    final source = await File(
      'lib/screens/activities/activity_details_screen.dart',
    ).readAsString();

    expect(
      source,
      contains(
        'static const Duration _meetingLocationTimeout = Duration(seconds: 8);',
      ),
    );
    expect(
      source,
      contains('Future<DeviceCoordinates?> _detectMeetingCoordinates()'),
    );
    expect(source, contains('.timeout('));
    expect(source, contains('_meetingLocationTimeout,'));
    expect(source, contains("TimeoutException('meeting_location_timeout')"));
    expect(source, contains('l10n.locationDetectionTimedOut'));
  });

  test('details reviews section displays organizer reviews', () async {
    final source = await File(
      'lib/screens/activities/activity_details_screen.dart',
    ).readAsString();

    final usageStart = source.indexOf('_ActivityReviewsSection(');
    final usageEnd = source.indexOf('),', usageStart);
    expect(usageStart, isNonNegative);
    expect(usageEnd, greaterThan(usageStart));

    final usageSource = source.substring(usageStart, usageEnd);
    expect(usageSource, contains('activityReviews: _activityReviews'));
    expect(usageSource, contains('organizerReviews: _organizerReviews'));
    expect(usageSource, contains('hasMyReview:'));

    final sectionStart = source.indexOf('class _ActivityReviewsSection');
    final nextSectionStart = source.indexOf(
      'class _ActivityReviewGroupTitle',
      sectionStart,
    );
    expect(sectionStart, isNonNegative);
    expect(nextSectionStart, greaterThan(sectionStart));

    final sectionSource = source.substring(sectionStart, nextSectionStart);
    expect(sectionSource, contains('final List<ActivityReviewVm>'));
    expect(
      sectionSource,
      contains('final List<ActivityOrganizerReviewVm> organizerReviews;'),
    );
    expect(sectionSource, contains('final bool hasMyReview;'));
    expect(sectionSource, contains('activityReviews.isNotEmpty ||'));
    expect(sectionSource, contains('organizerReviews.isNotEmpty'));
    expect(sectionSource, contains('activityOrganizerReviewsTitle'));
    expect(sectionSource, contains('activityReviewOrganizerLabel'));
  });

  test(
    'host card opens profile from the card and shows activity rating',
    () async {
      final source = await File(
        'lib/screens/activities/activity_details_screen.dart',
      ).readAsString();

      final hostCardStart = source.indexOf('class _HostCard');
      final nextClassStart = source.indexOf('class _StatsGrid', hostCardStart);
      expect(hostCardStart, isNonNegative);
      expect(nextClassStart, greaterThan(hostCardStart));

      final hostCardSource = source.substring(hostCardStart, nextClassStart);
      expect(hostCardSource, contains('required this.activityRating'));
      expect(hostCardSource, contains('onTap: onTap'));
      expect(hostCardSource, contains("_formatRating(activityRating)"));
      expect(hostCardSource, isNot(contains('profileButton')));
      expect(hostCardSource, isNot(contains('buttonLabel')));

      final hostCardUsageStart = source.indexOf('_HostCard(');
      final statsStart = source.indexOf('_StatsGrid(', hostCardUsageStart);
      expect(hostCardUsageStart, isNonNegative);
      expect(statsStart, greaterThan(hostCardUsageStart));

      final usageSource = source.substring(hostCardUsageStart, statsStart);
      expect(
        usageSource,
        contains('activityRating: activity.hostActivityRating'),
      );
      expect(usageSource, contains('onTap: ()'));
      expect(usageSource, isNot(contains('buttonLabel: l10n.profileTitle')));
    },
  );

  test('details screen separates schedule from compact stats grid', () async {
    final source = await File(
      'lib/screens/activities/activity_details_screen.dart',
    ).readAsString();

    final scheduleStart = source.indexOf('class _ActivityScheduleCard');
    expect(scheduleStart, isNonNegative);
    final scheduleEnd = source.indexOf('class _ScheduleTimeRow', scheduleStart);
    expect(scheduleEnd, greaterThan(scheduleStart));

    final scheduleSource = source.substring(scheduleStart, scheduleEnd);
    expect(scheduleSource, contains('l10n.activityDateAndTime'));
    expect(scheduleSource, contains('l10n.createStartAtLabel'));
    expect(scheduleSource, contains('l10n.createEndAtLabel'));
    expect(scheduleSource, contains('timeDisplayYourTime(startUserTime)'));
    expect(scheduleSource, contains('timeDisplayYourTime(endUserTime)'));
    expect(scheduleSource, contains('userTimeText:'));

    final statsStart = source.indexOf('class _StatsGrid');
    final statsEnd = source.indexOf('class _DetailsStatItem', statsStart);
    expect(statsStart, isNonNegative);
    expect(statsEnd, greaterThan(statsStart));

    final statsSource = source.substring(statsStart, statsEnd);
    expect(statsSource, isNot(contains('timeDisplayYourTime')));
    expect(statsSource, isNot(contains('createStartAtLabel')));
    expect(statsSource, isNot(contains('createEndAtLabel')));
    expect(statsSource, contains('activityPrice'));
    expect(statsSource, contains('activityFormatLabel'));
    expect(statsSource, contains('activityCapacity'));
    expect(statsSource, contains('activitiesFilterVisibility'));
  });

  test(
    'details schedule prefers device timezone before profile timezone',
    () async {
      final source = await File(
        'lib/screens/activities/activity_details_screen.dart',
      ).readAsString();

      expect(
        source,
        contains("import '../../core/device/device_context_service.dart';"),
      );
      expect(
        source,
        contains('final DeviceContextService _deviceContextService'),
      );
      expect(source, contains('String? _deviceTimezone;'));
      expect(source, contains('Future<void> _loadDeviceTimezone() async'));
      expect(source, contains('_deviceContextService.getLocalTimezone()'));

      final helperStart = source.indexOf(
        'String? _resolveActivityScheduleUserTimezone',
      );
      final scheduleStart = source.indexOf('class _ActivityScheduleCard');
      expect(helperStart, isNonNegative);
      expect(scheduleStart, greaterThan(helperStart));

      final helperSource = source.substring(helperStart, scheduleStart);
      expect(helperSource, contains('deviceTimezone'));
      expect(helperSource, contains('profileTimezone'));
      expect(
        helperSource,
        contains(
          'return _normalizeActivityScheduleTimezone(deviceTimezone) ??',
        ),
      );
      expect(
        helperSource,
        contains('_normalizeActivityScheduleTimezone(profileTimezone);'),
      );

      final usageStart = source.indexOf('_ActivityScheduleCard(');
      final statsStart = source.indexOf('_StatsGrid(', usageStart);
      expect(usageStart, isNonNegative);
      expect(statsStart, greaterThan(usageStart));

      final usageSource = source.substring(usageStart, statsStart);
      expect(usageSource, contains('userTimezone: scheduleUserTimezone'));

      final scheduleEnd = source.indexOf(
        'class _ScheduleTimeRow',
        scheduleStart,
      );
      expect(scheduleEnd, greaterThan(scheduleStart));

      final scheduleSource = source.substring(scheduleStart, scheduleEnd);
      expect(scheduleSource, contains('required this.userTimezone'));
      expect(
        scheduleSource,
        isNot(contains('context.watch<SessionProvider>().profile?.timezone')),
      );
    },
  );

  test(
    'activity review skeleton cards grow from content instead of fixed height',
    () async {
      final source = await File(
        'lib/screens/activities/activity_details_screen.dart',
      ).readAsString();

      final skeletonStart = source.indexOf('class _ActivityReviewSkeletonCard');
      final nextClassStart = source.indexOf('class ', skeletonStart + 1);
      expect(skeletonStart, isNonNegative);
      expect(nextClassStart, greaterThan(skeletonStart));

      final skeletonSource = source.substring(skeletonStart, nextClassStart);
      expect(skeletonSource, contains('padding:'));
      expect(skeletonSource, contains('Column('));
      expect(skeletonSource, isNot(contains('height: 116')));
    },
  );

  test(
    'meeting protected notice overlay scrolls within constrained map height',
    () async {
      final source = await File(
        'lib/screens/activities/activity_details_screen.dart',
      ).readAsString();

      final overlayStart = source.indexOf(
        'class _ProtectedMeetingNoticeOverlay',
      );
      final nextClassStart = source.indexOf('class ', overlayStart + 1);
      expect(overlayStart, isNonNegative);
      expect(nextClassStart, greaterThan(overlayStart));

      final overlaySource = source.substring(overlayStart, nextClassStart);
      expect(overlaySource, contains('LayoutBuilder('));
      expect(overlaySource, contains('SingleChildScrollView('));
      expect(overlaySource, contains('ConstrainedBox('));
      expect(overlaySource, contains('constraints.hasBoundedHeight'));
      expect(overlaySource, contains('minHeight: minHeight'));
      expect(overlaySource, contains('mainAxisSize: MainAxisSize.min'));
      expect(overlaySource, contains('activitySensitiveDetailsProtected'));

      final sectionStart = source.indexOf('class _MeetingSection');
      final mapCardStart = source.indexOf(
        'class _MeetingMapCard',
        sectionStart,
      );
      expect(sectionStart, isNonNegative);
      expect(mapCardStart, greaterThan(sectionStart));

      final sectionSource = source.substring(sectionStart, mapCardStart);
      expect(sectionSource, contains('_ProtectedMeetingNoticeOverlay('));
    },
  );
}
