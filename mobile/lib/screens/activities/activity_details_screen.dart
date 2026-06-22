import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/device/device_context_service.dart';
import '../../core/network/activity_api.dart';
import '../../core/network/checklist_api.dart';
import '../../core/network/file_api.dart';
import '../../core/time/app_time.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/error_dialog.dart';
import '../../core/ui/error_view.dart';
import '../../core/ui/filter_sheet_chrome.dart';
import '../../features/activities/activity_cover_url.dart';
import '../../features/activities/activity_formatters.dart';
import '../../features/activities/activity_taxonomy_resolver.dart';
import '../../features/activities/models/activity_category_vm.dart';
import '../../features/activities/models/activity_list_item_vm.dart';
import '../../features/activities/models/activity_participant_vm.dart';
import '../../features/activities/models/activity_review_vm.dart';
import '../../features/checklists/data/checklist_offline_cache.dart';
import '../../features/checklists/models/travel_checklist_route_args.dart';
import '../../features/profile/profile_completion_gate.dart';
import '../../features/profile/profile_guard_result.dart';
import '../../features/profile/data/profile_api.dart';
import '../../features/profile/models/profile_follower_vm.dart';
import '../../features/profile/models/user_profile_vm.dart';
import '../../features/routing/models/routing_models.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/routing_provider.dart';
import '../../providers/session_provider.dart';
import '../../shared/map/app_map_links.dart';
import '../../shared/widgets/app_localized_location_text.dart';
import '../../shared/widgets/app_map_card.dart';
import '../../shared/widgets/trip_preparation_cta.dart';
import '../map/map_screen.dart';
import 'activity_payment_screen.dart';
import 'widgets/activity_review_sheet.dart';

class ActivityDetailsScreen extends StatefulWidget {
  const ActivityDetailsScreen({
    super.key,
    required this.activityId,
    this.initialActivity,
  });

  final String activityId;
  final ActivityListItemVm? initialActivity;

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

enum _FooterAction {
  join,
  leave,
  publish,
  cancel,
  extend30,
  extend60,
  complete,
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  static const double _backSwipeMinDistance = 56;
  static const double _backSwipeMinVelocity = 700;
  static const Duration _meetingLocationTimeout = Duration(seconds: 8);

  final ActivityApi _activityApi = ActivityApi();
  final ChecklistOfflineCache _checklistCache = ChecklistOfflineCache();
  final DeviceContextService _deviceContextService =
      const DeviceContextService();
  final ProfileApi _profileApi = ProfileApi();

  bool _participantsLoading = true;
  String? _participantsError;
  List<ActivityParticipantVm> _participants = const [];
  bool _reviewsLoading = true;
  String? _reviewsError;
  List<ActivityReviewVm> _activityReviews = const [];
  List<ActivityOrganizerReviewVm> _organizerReviews = const [];
  Map<String, UserProfileVm> _resolvedProfiles = const {};
  _FooterAction? _pendingAction;
  bool _isPaymentSuccessful = false;
  bool _isSavingReviews = false;
  bool _isBuildingMeetingRoute = false;
  bool _isTrackingBackSwipe = false;
  bool _isInitialLoadPending = true;
  double _backSwipeDistance = 0;
  String? _deviceTimezone;
  ActivityProvider? _activityProvider;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDeviceTimezone());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshScreen();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _activityProvider = context.read<ActivityProvider>();
  }

  @override
  void dispose() {
    _scheduleActivityProviderCleanup();
    super.dispose();
  }

  void _scheduleActivityProviderCleanup() {
    final provider = _activityProvider;
    final activityId = widget.activityId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider?.clearSelectedActivity(activityId: activityId);
      provider?.resetActionState();
    });
  }

  Future<void> _loadDeviceTimezone() async {
    final timezone = await _deviceContextService.getLocalTimezone();
    if (!mounted) return;

    final normalized = _normalizeActivityScheduleTimezone(timezone);
    if (normalized == null || normalized == _deviceTimezone) return;

    setState(() => _deviceTimezone = normalized);
  }

  Future<void> _refreshScreen() async {
    final provider = context.read<ActivityProvider>();
    await Future.wait<void>([
      provider.loadActivityDetails(widget.activityId),
      provider.loadActivityCategories(),
      _loadParticipants(),
      _loadReviews(),
    ]);
    if (!mounted) return;
    setState(() => _isInitialLoadPending = false);
    await _loadVisibleProfiles(_visibleActivity(provider));
  }

  ActivityListItemVm? _visibleActivity(ActivityProvider provider) {
    final selectedActivity = provider.selectedActivity;
    if (selectedActivity?.id == widget.activityId) {
      return selectedActivity;
    }

    final initialActivity = widget.initialActivity;
    if (initialActivity?.id == widget.activityId) {
      return initialActivity;
    }

    return null;
  }

  Future<void> _loadParticipants() async {
    if (mounted) {
      setState(() {
        _participantsLoading = true;
        _participantsError = null;
      });
    }

    try {
      final items = await _activityApi.getActivityParticipants(
        widget.activityId,
      );
      if (!mounted) return;
      setState(() {
        _participants = items;
        _participantsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _participantsLoading = false;
        _participantsError = 'failed';
      });
    }
  }

  Future<void> _loadReviews() async {
    if (mounted) {
      setState(() {
        _reviewsLoading = true;
        _reviewsError = null;
      });
    }

    try {
      final results = await Future.wait<Object>([
        _activityApi.getActivityReviews(activityId: widget.activityId),
        _activityApi.getActivityOrganizerReviews(activityId: widget.activityId),
      ]);
      if (!mounted) return;
      setState(() {
        _activityReviews = (results[0] as ActivityReviewsPage).items;
        _organizerReviews = (results[1] as ActivityOrganizerReviewsPage).items;
        _reviewsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _reviewsLoading = false;
        _reviewsError = 'failed';
      });
    }
  }

  void _resetBackSwipe() {
    _isTrackingBackSwipe = false;
    _backSwipeDistance = 0;
  }

  double _backSwipeEdgeWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width <= 393 ? 68.0 : 76.0;
  }

  void _handleBackSwipeStart(DragStartDetails details) {
    if (!Navigator.of(context).canPop()) {
      _resetBackSwipe();
      return;
    }

    final edgeWidth = _backSwipeEdgeWidth(context);
    _isTrackingBackSwipe = details.localPosition.dx <= edgeWidth;
    _backSwipeDistance = 0;
  }

  void _handleBackSwipeUpdate(DragUpdateDetails details) {
    if (!_isTrackingBackSwipe) return;

    final delta = details.primaryDelta ?? 0;
    if (delta < 0 && _backSwipeDistance <= 0) {
      _resetBackSwipe();
      return;
    }

    _backSwipeDistance += delta;
  }

  void _handleBackSwipeEnd(DragEndDetails details) {
    final primaryVelocity = details.primaryVelocity ?? 0;
    final shouldGoBack =
        _isTrackingBackSwipe &&
        Navigator.of(context).canPop() &&
        (_backSwipeDistance >= _backSwipeMinDistance ||
            primaryVelocity >= _backSwipeMinVelocity);

    _resetBackSwipe();
    if (!shouldGoBack) return;

    FocusScope.of(context).unfocus();
    context.pop();
  }

  Future<void> _handleJoin() async {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.read<AuthProvider>();

    if (authProvider.state != AuthState.authenticated) {
      context.push(
        Uri(
          path: '/login',
          queryParameters: {'from': '/activities/${widget.activityId}'},
        ).toString(),
      );
      return;
    }

    final gateResult = await ProfileCompletionGate.ensureCompleted(context);
    if (gateResult == ProfileGuardResult.cancelled) {
      return;
    }
    if (!mounted) return;

    final activity = _visibleActivity(context.read<ActivityProvider>());
    if (_isPrivateActivity(activity)) {
      final joined = await _showPrivateJoinDialog(l10n);
      if (!mounted || joined != true) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.activityJoinSuccess)));
      return;
    }

    final success = await _submitJoin(showSuccessFeedback: true);
    if (!mounted || success) {
      return;
    }

    final provider = context.read<ActivityProvider>();
    await showErrorDialog(
      context,
      title: l10n.error,
      message: _mapJoinError(provider.actionErrorMessage, l10n),
    );
  }

  bool _isPrivateActivity(ActivityListItemVm? activity) =>
      activity?.visibility.toUpperCase() == 'PRIVATE';

  Future<bool> _submitJoin({
    String? visibilityPassword,
    required bool showSuccessFeedback,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    final provider = context.read<ActivityProvider>();
    setState(() => _pendingAction = _FooterAction.join);
    final success = await provider.joinActivity(
      widget.activityId,
      visibilityPassword: visibilityPassword,
    );

    if (!mounted) return success;

    if (!success) {
      setState(() => _pendingAction = null);
      return false;
    }

    await _reloadAfterAction(includeJoined: true);
    if (!mounted) return true;
    setState(() => _pendingAction = null);
    if (showSuccessFeedback) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.activityJoinSuccess)));
    }
    return true;
  }

  Future<bool?> _showPrivateJoinDialog(AppLocalizations l10n) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, _) {
        return _PrivateActivityPasswordDialog(
          l10n: l10n,
          onSubmit: (password) async {
            final success = await _submitJoin(
              visibilityPassword: password,
              showSuccessFeedback: false,
            );
            if (success) {
              return null;
            }
            if (!mounted) {
              return l10n.activityJoinFailed;
            }
            return _mapPrivateJoinError(
              context.read<ActivityProvider>().actionErrorMessage,
              l10n,
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(opacity: curve, child: child);
      },
    );
  }

  String _mapPrivateJoinError(
    String? actionErrorMessage,
    AppLocalizations l10n,
  ) {
    final raw = (actionErrorMessage ?? '').trim();
    if (raw.isEmpty) {
      return l10n.activityJoinFailed;
    }

    final normalized = raw.toLowerCase();
    if (normalized.contains('invalid activity visibility password')) {
      return l10n.activityPrivateJoinInvalidPassword;
    }
    if (normalized.contains('overlapping time')) {
      return l10n.activityJoinScheduleConflict;
    }
    if (normalized.contains('already joined activity')) {
      return l10n.activityJoinAlreadyJoined;
    }

    return raw;
  }

  String _mapJoinError(String? actionErrorMessage, AppLocalizations l10n) {
    final raw = (actionErrorMessage ?? '').trim();
    if (raw.isEmpty) {
      return l10n.activityJoinFailed;
    }

    final normalized = raw.toLowerCase();
    if (normalized.contains('overlapping time')) {
      return l10n.activityJoinScheduleConflict;
    }
    if (normalized.contains('already joined activity')) {
      return l10n.activityJoinAlreadyJoined;
    }

    return raw;
  }

  Future<void> _handleLeave() async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<ActivityProvider>();

    setState(() => _pendingAction = _FooterAction.leave);
    final success = await provider.leaveActivity(widget.activityId);

    if (!mounted) return;

    if (!success) {
      setState(() => _pendingAction = null);
      await showErrorDialog(
        context,
        title: l10n.error,
        message: provider.actionErrorMessage ?? l10n.activityLeaveFailed,
      );
      return;
    }

    await _removeCachedActivityChecklist();
    await _reloadAfterAction(includeJoined: true);
    if (!mounted) return;
    setState(() {
      _pendingAction = null;
      _isPaymentSuccessful = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.activityLeaveSuccess)));
  }

  Future<void> _removeCachedActivityChecklist() async {
    await _checklistCache.removeTripChecklist(
      _activityChecklistTripId(widget.activityId),
    );
  }

  Future<void> _openPayment(
    ActivityListItemVm activity, {
    required String hostName,
  }) async {
    if (_isPaymentSuccessful || activity.isFree) {
      return;
    }

    final success = await context.push<bool>(
      '/activities/${activity.id}/payment',
      extra: ActivityPaymentRouteArgs(activity: activity, hostName: hostName),
    );

    if (!mounted || success != true) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    setState(() => _isPaymentSuccessful = true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.activityPaymentSuccess)));
  }

  Future<void> _handlePublish() async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<ActivityProvider>();

    setState(() => _pendingAction = _FooterAction.publish);
    final success = await provider.publishActivity(widget.activityId);

    if (!mounted) return;

    if (!success) {
      setState(() => _pendingAction = null);
      await showErrorDialog(
        context,
        title: l10n.error,
        message: provider.actionErrorMessage ?? l10n.activityPublishFailed,
      );
      return;
    }

    await _reloadAfterAction(includeJoined: false);
    if (!mounted) return;
    setState(() => _pendingAction = null);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.activityPublishSuccess)));
  }

  Future<void> _handleCancel() async {
    final l10n = AppLocalizations.of(context)!;
    final reason = await _showCancelActivitySheet(l10n);
    if (!mounted || reason == null) {
      return;
    }

    await _submitCancel(reason, l10n: l10n);
  }

  Future<void> _submitCancel(
    String reason, {
    required AppLocalizations l10n,
  }) async {
    final provider = context.read<ActivityProvider>();
    setState(() => _pendingAction = _FooterAction.cancel);
    final updated = await provider.cancelActivity(
      widget.activityId,
      reason: reason,
    );

    if (!mounted) return;

    if (updated == null) {
      setState(() => _pendingAction = null);
      await showErrorDialog(
        context,
        title: l10n.error,
        message: _mapCancelError(provider.actionErrorMessage, l10n),
      );
      return;
    }

    await _reloadAfterAction(includeJoined: false);
    if (!mounted) return;
    setState(() => _pendingAction = null);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.activityCancelSuccess)));
  }

  Future<void> _handleExtend(int minutes) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<ActivityProvider>();
    setState(
      () => _pendingAction = minutes == 30
          ? _FooterAction.extend30
          : _FooterAction.extend60,
    );
    final updated = await provider.extendActivity(
      widget.activityId,
      minutes: minutes,
    );

    if (!mounted) return;

    if (updated == null) {
      setState(() => _pendingAction = null);
      await showErrorDialog(
        context,
        title: l10n.error,
        message: _mapExtendError(provider.actionErrorMessage, l10n),
      );
      return;
    }

    await _reloadAfterAction(includeJoined: false);
    if (!mounted) return;
    setState(() => _pendingAction = null);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.activityExtendSuccess)));
  }

  Future<void> _handleCompleteNow(ActivityListItemVm activity) async {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now().toUtc();
    final totalDurationMs = activity.endAt
        .toUtc()
        .difference(activity.startAt.toUtc())
        .inMilliseconds;

    if (totalDurationMs <= 0 || now.isBefore(activity.startAt.toUtc())) {
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.activityCompleteTooEarly,
      );
      return;
    }

    final remainingMs = activity.endAt.toUtc().difference(now).inMilliseconds;
    if (remainingMs > totalDurationMs / 2) {
      final reason = await _showCancelInsteadSheet(l10n);
      if (!mounted || reason == null) {
        return;
      }
      await _submitCancel(reason, l10n: l10n);
      return;
    }

    if (remainingMs > totalDurationMs / 4) {
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.activityCompleteTooEarly,
      );
      return;
    }

    final reason = await _showCompleteActivitySheet(l10n);
    if (!mounted || reason == null) {
      return;
    }

    final provider = context.read<ActivityProvider>();
    setState(() => _pendingAction = _FooterAction.complete);
    final updated = await provider.completeActivity(
      widget.activityId,
      reason: reason,
    );

    if (!mounted) return;

    if (updated == null) {
      setState(() => _pendingAction = null);
      await showErrorDialog(
        context,
        title: l10n.error,
        message: _mapCompleteError(provider.actionErrorMessage, l10n),
      );
      return;
    }

    await _reloadAfterAction(includeJoined: false);
    if (!mounted) return;
    setState(() => _pendingAction = null);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.activityCompleteEarlySuccess)));
  }

  Future<void> _reloadAfterAction({required bool includeJoined}) async {
    final provider = context.read<ActivityProvider>();
    final authProvider = context.read<AuthProvider>();
    final futures = <Future<void>>[
      provider.loadActivityDetails(widget.activityId),
      _loadParticipants(),
      _loadReviews(),
    ];

    if (authProvider.state == AuthState.authenticated) {
      futures.add(provider.loadMyActivities());
      if (includeJoined) {
        futures.add(provider.loadJoinedActivities());
      }
    }

    await Future.wait<void>(futures);
    await _loadVisibleProfiles(_visibleActivity(provider));
    provider.resetActionState();
  }

  Future<String?> _showCancelActivitySheet(AppLocalizations l10n) {
    return showModalBottomSheet<String>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CancelActivitySheet(l10n: l10n),
    );
  }

  Future<String?> _showCompleteActivitySheet(AppLocalizations l10n) {
    return showModalBottomSheet<String>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CompleteActivitySheet(l10n: l10n),
    );
  }

  Future<String?> _showCancelInsteadSheet(AppLocalizations l10n) {
    return showModalBottomSheet<String>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CancelInsteadSheet(l10n: l10n),
    );
  }

  String _mapCancelError(String? actionErrorMessage, AppLocalizations l10n) {
    final raw = (actionErrorMessage ?? '').trim();
    if (raw.isEmpty) {
      return l10n.activityCancelFailed;
    }

    final normalized = raw.toLowerCase();
    if (normalized.contains('already cancelled')) {
      return l10n.activityCancelAlreadyCancelled;
    }
    if (normalized.contains('not cancellable')) {
      return l10n.activityCancelNotAllowed;
    }
    if (normalized.contains('cancellation reason is required')) {
      return l10n.activityCancelReasonRequired;
    }

    return raw;
  }

  String _mapExtendError(String? actionErrorMessage, AppLocalizations l10n) {
    final raw = (actionErrorMessage ?? '').trim();
    if (raw.isEmpty) {
      return l10n.activityExtendFailed;
    }

    final normalized = raw.toLowerCase();
    if (normalized.contains('not extendable')) {
      return l10n.activityExtendNotAllowed;
    }

    return raw;
  }

  String _mapCompleteError(String? actionErrorMessage, AppLocalizations l10n) {
    final raw = (actionErrorMessage ?? '').trim();
    if (raw.isEmpty) {
      return l10n.activityCompleteFailed;
    }

    final normalized = raw.toLowerCase();
    if (normalized.contains('final 25 percent')) {
      return l10n.activityCompleteTooEarly;
    }
    if (normalized.contains('should be cancelled instead')) {
      return l10n.activityCompleteCancelInsteadDescription;
    }
    if (normalized.contains('completion reason is required')) {
      return l10n.activityCompleteReasonRequired;
    }
    if (normalized.contains('already completed')) {
      return l10n.activityCompleteAlreadyCompleted;
    }
    if (normalized.contains('not completable')) {
      return l10n.activityCompleteNotAllowed;
    }

    return raw;
  }

  bool _canCancelActivity(
    ActivityListItemVm activity, {
    required bool isOwner,
  }) {
    if (!isOwner) {
      return false;
    }

    switch (activity.status.toUpperCase()) {
      case 'DRAFT':
      case 'COMPLETED':
      case 'CANCELLED':
      case 'ARCHIVED':
        return false;
      default:
        return true;
    }
  }

  bool _canLeaveActivity(
    ActivityListItemVm activity, {
    required ActivityParticipantVm? currentParticipant,
    required bool isOwner,
  }) {
    if (currentParticipant == null ||
        isOwner ||
        !currentParticipant.canLeaveBeforeStart) {
      return false;
    }

    return DateTime.now().toUtc().isBefore(activity.startAt.toUtc());
  }

  String _participantStatusLabel(
    ActivityParticipantVm participant,
    AppLocalizations l10n,
  ) {
    switch (participant.normalizedStatus) {
      case 'INVITED':
        return l10n.participantStatusInvited;
      case 'REQUESTED':
        return l10n.participantStatusRequested;
      case 'APPROVED':
        return l10n.participantStatusApproved;
      case 'WAITLISTED':
        return l10n.participantStatusWaitlisted;
      case 'PENDING_PAYMENT':
        return l10n.participantStatusPendingPayment;
      case 'CONFIRMED':
        return l10n.participantStatusConfirmed;
      case 'CHECKED_IN':
        return l10n.participantStatusCheckedIn;
      default:
        return participant.status.trim().isEmpty
            ? l10n.participantStatusRequested
            : participant.status.trim();
    }
  }

  bool _canExtendActivity(
    ActivityListItemVm activity, {
    required bool isOwner,
  }) {
    if (!isOwner) {
      return false;
    }

    switch (activity.status.toUpperCase()) {
      case 'DRAFT':
      case 'COMPLETED':
      case 'CANCELLED':
      case 'ARCHIVED':
        return false;
      default:
        final now = DateTime.now().toUtc();
        return !now.isBefore(activity.startAt.toUtc()) &&
            now.isBefore(activity.endAt.toUtc());
    }
  }

  bool _canCompleteActivity(
    ActivityListItemVm activity, {
    required bool isOwner,
  }) {
    if (!isOwner) {
      return false;
    }

    switch (activity.status.toUpperCase()) {
      case 'DRAFT':
      case 'COMPLETED':
      case 'CANCELLED':
      case 'ARCHIVED':
        return false;
      default:
        final now = DateTime.now().toUtc();
        return !now.isBefore(activity.startAt.toUtc()) &&
            now.isBefore(activity.endAt.toUtc());
    }
  }

  Future<void> _loadVisibleProfiles(ActivityListItemVm? activity) async {
    final session = context.read<SessionProvider>();
    final authProvider = context.read<AuthProvider>();
    final currentProfile = session.profile;

    if (activity == null) {
      if (!mounted) return;
      setState(() {
        _resolvedProfiles = currentProfile == null
            ? const {}
            : {currentProfile.userId: currentProfile};
      });
      return;
    }

    final nextProfiles = <String, UserProfileVm>{};
    if (currentProfile != null) {
      nextProfiles[currentProfile.userId] = currentProfile;
    }

    if (authProvider.state != AuthState.authenticated) {
      if (!mounted) return;
      setState(() => _resolvedProfiles = nextProfiles);
      return;
    }

    final ids = <String>{activity.hostUserId};
    for (final participant in _participants) {
      ids.add(participant.userId);
    }
    ids.removeWhere((id) => id.trim().isEmpty || nextProfiles.containsKey(id));

    if (ids.isNotEmpty) {
      final entries = await Future.wait(
        ids.map((userId) async {
          try {
            final profile = await _profileApi.getUserById(userId);
            return MapEntry(userId, profile);
          } catch (_) {
            return null;
          }
        }),
      );

      for (final entry in entries) {
        if (entry == null) continue;
        nextProfiles[entry.key] = entry.value;
      }
    }

    if (!mounted) return;
    setState(() => _resolvedProfiles = nextProfiles);
  }

  void _openEdit(ActivityListItemVm activity) {
    context.push('/activities/${widget.activityId}/edit', extra: activity);
  }

  void _openRepeat(ActivityListItemVm activity) {
    context.push('/activities/create', extra: activity);
  }

  Future<void> _copyValue(String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleMeetingAction(
    ActivityListItemVm activity, {
    required bool canUseMeetingLink,
  }) async {
    final meetingUrl = (activity.meetingUrl ?? '').trim();
    if (canUseMeetingLink && meetingUrl.isNotEmpty) {
      await _copyValue(
        meetingUrl,
        AppLocalizations.of(context)!.activityDetailsLinkCopied,
      );
      return;
    }

    await _openMeetingRoute(activity);
  }

  Future<void> _openMeetingRoute(ActivityListItemVm activity) async {
    if (_isBuildingMeetingRoute) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final meetingPoint = _resolveMeetingPoint(activity);
    if (meetingPoint == null) {
      await _copyMeetingFallback(activity, l10n);
      return;
    }

    if (context.read<AuthProvider>().state != AuthState.authenticated) {
      context.push(
        Uri(
          path: '/login',
          queryParameters: {'from': '/activities/${widget.activityId}'},
        ).toString(),
      );
      return;
    }

    final destination = _activityMeetingMapTarget(activity, meetingPoint);
    final routingProvider = context.read<RoutingProvider>();

    setState(() => _isBuildingMeetingRoute = true);
    try {
      final coordinates = await _detectMeetingCoordinates();
      if (!mounted) return;

      if (coordinates == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.locationPermissionDenied)));
        context.push('/map', extra: destination);
        return;
      }

      final origin = RoutePointVm(
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        name: l10n.homeNavMap,
      );

      final route = await routingProvider.buildRoute(
        RouteRequestVm(
          profile: RouteProfile.touristWalk,
          points: [
            origin,
            RoutePointVm(
              latitude: meetingPoint.latitude,
              longitude: meetingPoint.longitude,
              name: activity.title,
            ),
          ],
        ),
      );
      if (!mounted) return;

      if (route == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              routingProvider.errorMessage ?? l10n.mapUsingFallbackLocation,
            ),
          ),
        );
        context.push('/map', extra: destination);
        return;
      }

      final routePreview = MapRoutePreview(
        route: route,
        origin: origin,
        destination: destination,
      );
      context.push('/map', extra: routePreview);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_resolveLocationErrorMessage(error, l10n))),
      );
      context.push('/map', extra: destination);
    } finally {
      if (mounted) {
        setState(() => _isBuildingMeetingRoute = false);
      }
    }
  }

  Future<DeviceCoordinates?> _detectMeetingCoordinates() {
    return _deviceContextService
        .detectCoordinates(requestPermission: true)
        .timeout(
          _meetingLocationTimeout,
          onTimeout: () => throw TimeoutException('meeting_location_timeout'),
        );
  }

  String _resolveLocationErrorMessage(Object error, AppLocalizations l10n) {
    final code = error.toString();
    if (code.contains('meeting_location_timeout') ||
        code.contains('TimeoutException')) {
      return l10n.locationDetectionTimedOut;
    }
    if (code.contains('location_services_disabled')) {
      return l10n.locationServicesDisabled;
    }
    if (code.contains('location_permission_denied_forever')) {
      return l10n.locationPermissionDeniedForever;
    }
    if (code.contains('location_permission_denied')) {
      return l10n.locationPermissionDenied;
    }
    return l10n.mapUsingFallbackLocation;
  }

  Future<void> _copyMeetingFallback(
    ActivityListItemVm activity,
    AppLocalizations l10n,
  ) async {
    final copyValue = _resolveMeetingActionCopyValue(activity);
    if (copyValue == null || copyValue.isEmpty) {
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.notSpecified,
      );
      return;
    }
    await _copyValue(copyValue, l10n.activityDetailsLinkCopied);
  }

  Future<void> _showParticipantsSheet(
    List<ActivityParticipantVm> participants,
    AppLocalizations l10n,
    String hostUserId,
    bool canInviteFriends,
  ) async {
    if (participants.isEmpty) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final locale = Localizations.localeOf(sheetContext).toString();
        final dateFormat = DateFormat.MMMd(locale).add_Hm();
        final bottomSafePadding = MediaQuery.viewPaddingOf(sheetContext).bottom;

        return _DetailsResponsiveTextScope(
          child: SafeArea(
            top: false,
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72,
                ),
                decoration: BoxDecoration(
                  color: _DetailsColors.sheet,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.activityGoingTitle(participants.length),
                                  style: const TextStyle(
                                    color: _DetailsColors.text,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    Navigator.of(sheetContext).pop(),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: _DetailsColors.text,
                                ),
                              ),
                            ],
                          ),
                          if (canInviteFriends) ...[
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                unawaited(_showInviteFriendsSheet(l10n));
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.accent,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 40),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Icon(
                                Icons.person_add_alt_1_rounded,
                                size: 19,
                              ),
                              label: Text(
                                l10n.activityInviteFriendsButton,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0x14FFFFFF)),
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          22,
                          14,
                          22,
                          24 + bottomSafePadding,
                        ),
                        itemCount: participants.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final participant = participants[index];
                          final displayStatus = participant.userId == hostUserId
                              ? 'CHECKED_IN'
                              : participant.status;
                          return Row(
                            children: [
                              _ParticipantAvatar(
                                seed: participant.userId,
                                imageUrl: _resolveUserAvatarUrl(
                                  participant.userId,
                                  resolvedProfiles: _resolvedProfiles,
                                  currentProfile: context
                                      .read<SessionProvider>()
                                      .profile,
                                ),
                                radius: 21,
                                borderColor: _DetailsColors.sheet,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _resolveUserName(
                                        participant.userId,
                                        l10n,
                                        resolvedProfiles: _resolvedProfiles,
                                      ),
                                      style: const TextStyle(
                                        color: _DetailsColors.text,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dateFormat.format(
                                        participant.joinedAt.toLocal(),
                                      ),
                                      style: const TextStyle(
                                        color: _DetailsColors.muted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _StatusPill(
                                label: formatParticipantStatus(
                                  displayStatus,
                                  l10n,
                                ),
                                backgroundColor: _statusPillColor(
                                  displayStatus,
                                ),
                                textColor: _statusTextColor(displayStatus),
                                maxWidth: 136,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showInviteFriendsSheet(AppLocalizations l10n) async {
    if (context.read<AuthProvider>().state != AuthState.authenticated) {
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.activityInviteFriendsAuthRequired,
      );
      return;
    }

    final currentUserId =
        (context.read<SessionProvider>().profile?.userId ?? '').trim();
    final excludedUserIds = <String>{
      if (currentUserId.isNotEmpty) currentUserId,
      for (final participant in _participants)
        if (participant.userId.trim().isNotEmpty) participant.userId.trim(),
    };

    final invited = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _DetailsResponsiveTextScope(
          child: _InviteFriendsSheet(
            activityId: widget.activityId,
            activityApi: _activityApi,
            profileApi: _profileApi,
            excludedUserIds: excludedUserIds,
          ),
        );
      },
    );

    if (invited != true || !mounted) {
      return;
    }

    await _loadParticipants();
    if (!mounted) return;
    await _loadVisibleProfiles(
      _visibleActivity(context.read<ActivityProvider>()),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.activityInviteFriendsSuccess)));
  }

  ActivityParticipantVm? _reviewParticipantForCurrentUser(
    String currentUserId,
  ) {
    if (currentUserId.trim().isEmpty) {
      return null;
    }
    for (final participant in _participants) {
      if (participant.userId.trim() == currentUserId.trim()) {
        return participant;
      }
    }
    return null;
  }

  ActivityReviewVm? _myActivityReview(String currentUserId) {
    for (final review in _activityReviews) {
      if (review.author.userId.trim() == currentUserId ||
          review.authorUserId.trim() == currentUserId) {
        return review;
      }
    }
    return null;
  }

  ActivityOrganizerReviewVm? _myOrganizerReview(String currentUserId) {
    for (final review in _organizerReviews) {
      if (review.author.userId.trim() == currentUserId ||
          review.authorUserId.trim() == currentUserId) {
        return review;
      }
    }
    return null;
  }

  Future<void> _openActivityReviewsSheet({
    required ActivityListItemVm activity,
    required String currentUserId,
    required bool canWriteReview,
    required bool allowOrganizerReview,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (context.read<AuthProvider>().state != AuthState.authenticated) {
      context.push(
        Uri(
          path: '/login',
          queryParameters: {'from': '/activities/${widget.activityId}'},
        ).toString(),
      );
      return;
    }
    if (!canWriteReview) {
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.activityReviewUnavailable,
      );
      return;
    }

    final request = await showActivityReviewSheet(
      context,
      activityReview: _myActivityReview(currentUserId),
      organizerReview: _myOrganizerReview(currentUserId),
      allowOrganizerReview: allowOrganizerReview,
    );
    if (request == null || !mounted) {
      return;
    }

    setState(() => _isSavingReviews = true);
    try {
      await _activityApi.saveActivityReviews(activity.id, request);
      await _loadReviews();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.activityReviewSaved)));
    } catch (_) {
      if (!mounted) return;
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.activityReviewSaveFailed,
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingReviews = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<ActivityProvider>();
    final session = context.watch<SessionProvider>();
    final activity = _visibleActivity(provider);
    final currentUserId = (session.profile?.userId ?? '').trim();
    final scheduleUserTimezone = _resolveActivityScheduleUserTimezone(
      deviceTimezone: _deviceTimezone,
      profileTimezone: session.profile?.timezone,
    );

    if ((_isInitialLoadPending || provider.state == ActivitiesState.loading) &&
        activity == null) {
      return const _DetailsResponsiveTextScope(
        child: Scaffold(
          backgroundColor: _DetailsColors.base,
          body: Stack(
            children: [
              Positioned.fill(child: _DetailsBackdrop()),
              Center(child: CircularProgressIndicator(color: AppColors.accent)),
            ],
          ),
        ),
      );
    }

    if (provider.state == ActivitiesState.error && activity == null) {
      return _DetailsResponsiveTextScope(
        child: Scaffold(
          backgroundColor: _DetailsColors.base,
          body: Stack(
            children: [
              const Positioned.fill(child: _DetailsBackdrop()),
              SafeArea(
                child: ErrorView(
                  message:
                      provider.errorMessage ?? l10n.activityDetailsLoadFailed,
                  onRetry: _refreshScreen,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (activity == null) {
      return _DetailsResponsiveTextScope(
        child: Scaffold(
          backgroundColor: _DetailsColors.base,
          body: Stack(
            children: [
              const Positioned.fill(child: _DetailsBackdrop()),
              SafeArea(
                child: ErrorView(
                  message: l10n.activityNotFound,
                  onRetry: _refreshScreen,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final activeParticipants =
        _participants.where((participant) => participant.isActive).toList()
          ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
    final occupyingCount = _participants
        .where((participant) => participant.occupiesSlot)
        .length;
    final isOwner =
        currentUserId.isNotEmpty && currentUserId == activity.hostUserId;
    final canInviteFriends =
        context.read<AuthProvider>().state == AuthState.authenticated &&
        (isOwner || activity.allowsParticipantInvites);
    ActivityParticipantVm? currentParticipant;
    if (!isOwner && currentUserId.isNotEmpty) {
      for (final participant in activeParticipants) {
        if (participant.userId == currentUserId) {
          currentParticipant = participant;
          break;
        }
      }
    }

    final isJoined = currentParticipant != null;
    final canPrepareTrip = isOwner || currentParticipant != null;
    final canOpenParticipantChat =
        currentParticipant?.hasConfirmedAccess == true;
    final requiresParticipantPayment =
        currentParticipant?.requiresPayment == true;
    final isParticipationPending =
        currentParticipant?.isPendingDecision == true;
    final participantStatusLabel = currentParticipant == null
        ? null
        : _participantStatusLabel(currentParticipant, l10n);
    final status = activity.status.toUpperCase();
    final showReviewsSection = status == 'COMPLETED';
    final reviewParticipant = _reviewParticipantForCurrentUser(currentUserId);
    final canWriteActivityReview =
        status == 'COMPLETED' &&
        reviewParticipant?.normalizedStatus == 'CHECKED_IN';
    final canWriteOrganizerReview =
        canWriteActivityReview && currentUserId != activity.hostUserId.trim();
    final isDraft = status == 'DRAFT';
    final showPublish = isOwner && isDraft;
    final canLeaveActivity = _canLeaveActivity(
      activity,
      currentParticipant: currentParticipant,
      isOwner: isOwner,
    );
    final canCancelActivity = _canCancelActivity(activity, isOwner: isOwner);
    final canExtendActivity = _canExtendActivity(activity, isOwner: isOwner);
    final canCompleteActivity = _canCompleteActivity(
      activity,
      isOwner: isOwner,
    );
    final canShowAttendanceQr =
        isOwner &&
        !const {'CANCELLED', 'COMPLETED', 'ARCHIVED'}.contains(status);
    final lifecycleReason = activity.isCompletedEarly
        ? (activity.completionReason ?? '').trim()
        : status == 'CANCELLED'
        ? (activity.cancellationReason ?? '').trim()
        : '';
    final lifecycleReasonTitle = activity.isCompletedEarly
        ? l10n.activityCompleteReasonLabel
        : l10n.activityCancelReasonLabel;
    final lifecycleReasonIcon = activity.isCompletedEarly
        ? Icons.task_alt_rounded
        : Icons.event_busy_rounded;
    final lifecycleReasonColor = activity.isCompletedEarly
        ? _DetailsColors.success
        : AppColors.accent;
    final baseCategoryLabel = _resolveLocalizedCategoryLabel(
      activity.categorySlug,
      provider.categoryItems,
      Localizations.localeOf(context).languageCode,
    );
    final subcategoryLabel = localizedActivitySubcategoryLabel(
      categories: provider.categoryItems,
      categorySlug: activity.categorySlug,
      subcategorySlug: activity.subcategorySlug,
      languageCode: Localizations.localeOf(context).languageCode,
    );
    final categoryLabel = subcategoryLabel.isEmpty
        ? baseCategoryLabel
        : '$baseCategoryLabel / $subcategoryLabel';
    final hostName = _resolveHostName(
      activity.hostUserId,
      session.profile,
      resolvedProfiles: _resolvedProfiles,
      l10n: l10n,
    );
    final hostAvatarUrl = _resolveUserAvatarUrl(
      activity.hostUserId,
      resolvedProfiles: _resolvedProfiles,
      currentProfile: session.profile,
    );
    final hostAvatarFallback = _displayInitials(hostName);

    return _DetailsResponsiveTextScope(
      child: Scaffold(
        backgroundColor: _DetailsColors.base,
        extendBody: true,
        bottomNavigationBar: _DetailsActionBar(
          activity: activity,
          l10n: l10n,
          isOwner: isOwner,
          isJoined: isJoined,
          canOpenChat: canOpenParticipantChat,
          isParticipationPending: isParticipationPending,
          participantStatusLabel: participantStatusLabel,
          isPaid: _isPaymentSuccessful,
          showPublish: showPublish,
          isBusy: provider.actionState == ActivityActionState.loading,
          pendingAction: _pendingAction,
          onJoin: _handleJoin,
          onPublish: _handlePublish,
          onEdit: () => const {'CANCELLED', 'COMPLETED'}.contains(status)
              ? _openRepeat(activity)
              : _openEdit(activity),
          onPay: requiresParticipantPayment && !isOwner && !activity.isFree
              ? () => _openPayment(activity, hostName: hostName)
              : null,
          onOpenChat: canOpenParticipantChat
              ? () => context.push('/activities/${activity.id}/chat')
              : null,
        ),
        body: Stack(
          children: [
            const Positioned.fill(child: _DetailsBackdrop()),
            SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final horizontalPadding = width < 360 ? 14.0 : 18.0;
                  final heroHeight = width < 360
                      ? 292.0
                      : width > 430
                      ? 348.0
                      : 326.0;
                  final compact = width < 360;

                  return RefreshIndicator(
                    onRefresh: _refreshScreen,
                    color: AppColors.accent,
                    backgroundColor: _DetailsColors.sheet,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        10,
                        horizontalPadding,
                        132 + MediaQuery.paddingOf(context).bottom,
                      ),
                      children: [
                        _DetailsTopBar(
                          title: l10n.activityDetailsTitle,
                          status: formatActivityDisplayStatus(activity, l10n),
                          statusColor: _activityStatusColor(activity.status),
                          compact: compact,
                          onBack: () => context.pop(),
                          onShare: () => _copyValue(
                            '/activities/${activity.id}',
                            l10n.activityDetailsLinkCopied,
                          ),
                        ),
                        SizedBox(height: compact ? 12 : 14),
                        _DetailsHero(
                          height: heroHeight,
                          categorySlug: activity.categorySlug,
                          categoryLabel: categoryLabel,
                          contextLabel: _resolveHeroContextLabel(
                            activity: activity,
                            l10n: l10n,
                            isOwner: isOwner,
                            isJoined: isJoined,
                            occupyingCount: occupyingCount,
                          ),
                          imageUrl: resolveActivityCoverUrl(activity),
                        ),
                        SizedBox(height: compact ? 14 : 16),
                        _HeadingSection(
                          title: activity.title,
                          description: activity.description,
                          compact: compact,
                        ),
                        if (lifecycleReason.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _LifecycleReasonCard(
                            title: lifecycleReasonTitle,
                            reason: lifecycleReason,
                            icon: lifecycleReasonIcon,
                            accentColor: lifecycleReasonColor,
                          ),
                        ],
                        const SizedBox(height: 20),
                        _HostCard(
                          hostName: hostName,
                          avatarUrl: hostAvatarUrl,
                          avatarFallbackText: hostAvatarFallback,
                          activityRating: activity.hostActivityRating,
                          subtitle: _resolveHostSubtitle(
                            activity: activity,
                            l10n: l10n,
                          ),
                          onTap: () {
                            if (isOwner) {
                              context.push('/profile');
                              return;
                            }
                            final hostUserId = activity.hostUserId.trim();
                            if (hostUserId.isEmpty) {
                              unawaited(
                                showErrorDialog(
                                  context,
                                  title: l10n.error,
                                  message: l10n.profileNotAvailable,
                                ),
                              );
                              return;
                            }
                            context.push(
                              '/users/$hostUserId/profile',
                              extra: _resolvedProfiles[hostUserId],
                            );
                          },
                        ),
                        const SizedBox(height: 22),
                        _ActivityScheduleCard(
                          activity: activity,
                          l10n: l10n,
                          compact: compact,
                          userTimezone: scheduleUserTimezone,
                        ),
                        SizedBox(height: compact ? 10 : 12),
                        _StatsGrid(
                          activity: activity,
                          l10n: l10n,
                          compact: compact,
                        ),
                        if (canPrepareTrip) ...[
                          const SizedBox(height: 22),
                          TripPreparationCta(
                            title: l10n.travelChecklistCtaTitle,
                            subtitle: l10n.travelChecklistCtaSubtitle,
                            actionLabel: l10n.travelChecklistOpen,
                            onTap: () => context.push(
                              '/travel-checklist',
                              extra: _activityChecklistRouteArgs(activity),
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        _ParticipantsSection(
                          l10n: l10n,
                          participants: activeParticipants,
                          resolvedProfiles: _resolvedProfiles,
                          currentProfile: session.profile,
                          compact: compact,
                          isLoading: _participantsLoading,
                          loadFailed: _participantsError != null,
                          onViewAll: activeParticipants.isNotEmpty
                              ? () => _showParticipantsSheet(
                                  activeParticipants,
                                  l10n,
                                  activity.hostUserId,
                                  canInviteFriends,
                                )
                              : null,
                        ),
                        const SizedBox(height: 8),
                        _MeetingSection(
                          activity: activity,
                          l10n: l10n,
                          isJoined: isJoined,
                          isOwner: isOwner,
                          canShowAttendanceQr: canShowAttendanceQr,
                          canLeaveActivity: canLeaveActivity,
                          canCancelActivity: canCancelActivity,
                          canExtendActivity: canExtendActivity,
                          canCompleteActivity: canCompleteActivity,
                          isLeaving:
                              provider.actionState ==
                                  ActivityActionState.loading &&
                              _pendingAction == _FooterAction.leave,
                          isExtending30:
                              provider.actionState ==
                                  ActivityActionState.loading &&
                              _pendingAction == _FooterAction.extend30,
                          isExtending60:
                              provider.actionState ==
                                  ActivityActionState.loading &&
                              _pendingAction == _FooterAction.extend60,
                          isCompleting:
                              provider.actionState ==
                                  ActivityActionState.loading &&
                              _pendingAction == _FooterAction.complete,
                          isCancelling:
                              provider.actionState ==
                                  ActivityActionState.loading &&
                              _pendingAction == _FooterAction.cancel,
                          isBuildingRoute: _isBuildingMeetingRoute,
                          onLeaveTap: _handleLeave,
                          onExtend30Tap: () => _handleExtend(30),
                          onExtend60Tap: () => _handleExtend(60),
                          onCompleteTap: () => _handleCompleteNow(activity),
                          onCancelTap: _handleCancel,
                          onShowAttendanceQrTap: () {
                            context.push(
                              '/activities/${activity.id}/attendance-qr',
                            );
                          },
                          onActionTap: () => unawaited(
                            _handleMeetingAction(
                              activity,
                              canUseMeetingLink: isJoined || isOwner,
                            ),
                          ),
                        ),
                        if (showReviewsSection) ...[
                          const SizedBox(height: 22),
                          _ActivityReviewsSection(
                            activityReviews: _activityReviews,
                            organizerReviews: _organizerReviews,
                            isLoading: _reviewsLoading,
                            loadFailed: _reviewsError != null,
                            canWriteReview: canWriteActivityReview,
                            isSavingReview: _isSavingReviews,
                            hasMyReview:
                                _myActivityReview(currentUserId) != null ||
                                _myOrganizerReview(currentUserId) != null,
                            onWriteReviewTap: canWriteActivityReview
                                ? () => _openActivityReviewsSheet(
                                    activity: activity,
                                    currentUserId: currentUserId,
                                    canWriteReview: canWriteActivityReview,
                                    allowOrganizerReview:
                                        canWriteOrganizerReview,
                                  )
                                : null,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: _backSwipeEdgeWidth(context),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragStart: _handleBackSwipeStart,
                onHorizontalDragUpdate: _handleBackSwipeUpdate,
                onHorizontalDragEnd: _handleBackSwipeEnd,
                onHorizontalDragCancel: _resetBackSwipe,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsResponsiveTextScope extends StatelessWidget {
  const _DetailsResponsiveTextScope({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final shortSide = mediaQuery.size.shortestSide;
    final baseScale = mediaQuery.textScaler.scale(1);

    double widthScale;
    if (shortSide <= 320) {
      widthScale = 0.84;
    } else if (shortSide <= 360) {
      widthScale = 0.88;
    } else if (shortSide <= 390) {
      widthScale = 0.92;
    } else if (shortSide >= 430) {
      widthScale = 0.96;
    } else {
      widthScale = 0.94;
    }

    final effectiveScale = (baseScale * widthScale).clamp(0.84, 1.12);

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: TextScaler.linear(effectiveScale)),
      child: child,
    );
  }
}

double _detailsUiScale(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final shortSide = mediaQuery.size.shortestSide;
  final height = mediaQuery.size.height;

  double scale;
  if (shortSide <= 320) {
    scale = 0.82;
  } else if (shortSide <= 360) {
    scale = 0.86;
  } else if (shortSide <= 390) {
    scale = 0.9;
  } else if (shortSide >= 430) {
    scale = 0.96;
  } else {
    scale = 0.93;
  }

  if (height < 700) {
    scale *= 0.96;
  } else if (height > 920) {
    scale *= 1.02;
  }

  return scale.clamp(0.8, 1.0);
}

double _detailsScaled(
  BuildContext context,
  double value, {
  double? min,
  double? max,
}) {
  final scaled = value * _detailsUiScale(context);
  final lower = min ?? 0;
  final upper = max ?? double.infinity;
  return scaled.clamp(lower, upper);
}

abstract final class _DetailsColors {
  static const base = Color(0xFF140901);
  static const sheet = Color(0xFF1A0F08);
  static const text = Color(0xFFF4F1EB);
  static const muted = Color(0xFFB8B3B4);
  static const subtle = Color(0xFF97929A);
  static const success = Color(0xFF18C26E);
  static const mutedPill = Color(0xB4959A96);
}

class _DetailsBackdrop extends StatelessWidget {
  const _DetailsBackdrop();

  @override
  Widget build(BuildContext context) {
    final topGlowHeight = _detailsScaled(context, 260, min: 210, max: 300);
    final bottomGlowHeight = _detailsScaled(context, 220, min: 180, max: 260);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF1B0F07), _DetailsColors.base],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -40,
            right: -40,
            height: topGlowHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 0.8,
                  colors: [
                    AppColors.accent.withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -20,
            right: -20,
            height: bottomGlowHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.bottomCenter,
                  radius: 0.9,
                  colors: [
                    AppColors.accent.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivateActivityPasswordDialog extends StatefulWidget {
  const _PrivateActivityPasswordDialog({
    required this.l10n,
    required this.onSubmit,
  });

  final AppLocalizations l10n;
  final Future<String?> Function(String password) onSubmit;

  @override
  State<_PrivateActivityPasswordDialog> createState() =>
      _PrivateActivityPasswordDialogState();
}

class _PrivateActivityPasswordDialogState
    extends State<_PrivateActivityPasswordDialog> {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _obscureText = true;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _passwordFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  String? _validatePassword(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 4 || trimmed.length > 64) {
      return widget.l10n.activityPrivateJoinPasswordValidation;
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final password = _passwordController.text.trim();
    final validationError = _validatePassword(password);
    if (validationError != null) {
      setState(() => _errorText = validationError);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final submitError = await widget.onSubmit(password);
      if (!mounted) return;
      if (submitError == null) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(() {
        _isSubmitting = false;
        _errorText = submitError;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorText = widget.l10n.activityJoinFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final compact = width < 390;

    return _DetailsResponsiveTextScope(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0x6605060A),
                        const Color(0xC2080A12),
                        const Color(0xEB090B12),
                      ],
                    ),
                  ),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.only(
                      left: 12,
                      right: 12,
                      bottom: mediaQuery.viewInsets.bottom,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(34),
                          ),
                          border: Border.all(color: const Color(0x2EFFAB4F)),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xF029190A), Color(0xFA170E08)],
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x47000000),
                              blurRadius: 60,
                              offset: Offset(0, -28),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            compact ? 18 : 20,
                            18,
                            compact ? 18 : 20,
                            compact ? 20 : 24,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 58,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.42,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x14FFFFFF),
                                      blurRadius: 1,
                                      offset: Offset(0, 1),
                                      spreadRadius: -0.4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 22),
                              Container(
                                width: compact ? 64 : 70,
                                height: compact ? 64 : 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.accent.withValues(
                                    alpha: 0.14,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x1F000000),
                                      blurRadius: 16,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 28,
                                  color: AppColors.accent,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                widget.l10n.activityPrivateJoinTitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _DetailsColors.text,
                                  fontSize: compact ? 23 : 26,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: 14),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 320,
                                ),
                                child: Text(
                                  widget.l10n.activityPrivateJoinDescription,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFFB7B2BD),
                                    fontSize: compact ? 14 : 15,
                                    height: 1.4,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                              SizedBox(height: compact ? 26 : 34),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  widget.l10n.activityPrivateJoinPasswordLabel,
                                  style: const TextStyle(
                                    color: _DetailsColors.text,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(0xC21F130A),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: _errorText == null
                                        ? const Color(0x57FF9900)
                                        : const Color(0xCCFF7A59),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _errorText == null
                                          ? const Color(0x0DFFB854)
                                          : const Color(0x14FF7A59),
                                      blurRadius: 0,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  enabled: !_isSubmitting,
                                  obscureText: _obscureText,
                                  obscuringCharacter: '*',
                                  keyboardType: TextInputType.visiblePassword,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.password],
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: compact ? 16 : 17,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: widget
                                        .l10n
                                        .activityPrivateJoinPasswordPlaceholder,
                                    hintStyle: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.72,
                                      ),
                                      fontSize: compact ? 15 : 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 22,
                                      vertical: compact ? 14 : 16,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: _isSubmitting
                                          ? null
                                          : () => setState(
                                              () =>
                                                  _obscureText = !_obscureText,
                                            ),
                                      icon: Icon(
                                        _obscureText
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ),
                                  onTapOutside: (_) =>
                                      FocusScope.of(context).unfocus(),
                                  onChanged: (_) {
                                    if (_errorText == null) {
                                      return;
                                    }
                                    setState(() => _errorText = null);
                                  },
                                  onSubmitted: _isSubmitting
                                      ? null
                                      : (_) => _submit(),
                                ),
                              ),
                              if (_errorText != null) ...[
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Text(
                                      _errorText!,
                                      style: const TextStyle(
                                        color: Color(0xFFFF8A65),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 26),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFFFF9900),
                                      Color(0xFFFF9300),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accent.withValues(
                                        alpha: 0.28,
                                      ),
                                      blurRadius: 28,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(999),
                                    onTap: _isSubmitting ? null : _submit,
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: compact ? 54 : 58,
                                      child: Center(
                                        child: _isSubmitting
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.6,
                                                  valueColor:
                                                      AlwaysStoppedAnimation(
                                                        Colors.white,
                                                      ),
                                                ),
                                              )
                                            : Text(
                                                widget
                                                    .l10n
                                                    .activityPrivateJoinSubmit,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: compact ? 16 : 17,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CancelActivitySheet extends StatelessWidget {
  const _CancelActivitySheet({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _ReasonActionSheet(
      title: l10n.activityCancelConfirmTitle,
      description: l10n.activityCancelConfirmDescription,
      reasonLabel: l10n.activityCancelReasonLabel,
      reasonPlaceholder: l10n.activityCancelReasonPlaceholder,
      reasonRequiredText: l10n.activityCancelReasonRequired,
      confirmLabel: l10n.activityCancelConfirmButton,
      confirmIcon: Icons.event_busy_rounded,
    );
  }
}

class _CompleteActivitySheet extends StatelessWidget {
  const _CompleteActivitySheet({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _ReasonActionSheet(
      title: l10n.activityCompleteConfirmTitle,
      description: l10n.activityCompleteConfirmDescription,
      reasonLabel: l10n.activityCompleteReasonLabel,
      reasonPlaceholder: l10n.activityCompleteReasonPlaceholder,
      reasonRequiredText: l10n.activityCompleteReasonRequired,
      confirmLabel: l10n.activityCompleteConfirmButton,
      confirmIcon: Icons.task_alt_rounded,
    );
  }
}

class _CancelInsteadSheet extends StatelessWidget {
  const _CancelInsteadSheet({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _ReasonActionSheet(
      title: l10n.activityCompleteCancelInsteadTitle,
      description: l10n.activityCompleteCancelInsteadDescription,
      reasonLabel: l10n.activityCancelReasonLabel,
      reasonPlaceholder: l10n.activityCancelReasonPlaceholder,
      reasonRequiredText: l10n.activityCancelReasonRequired,
      confirmLabel: l10n.activityCancelConfirmButton,
      confirmIcon: Icons.warning_amber_rounded,
    );
  }
}

class _ReasonActionSheet extends StatefulWidget {
  const _ReasonActionSheet({
    required this.title,
    required this.description,
    required this.reasonLabel,
    required this.reasonPlaceholder,
    required this.reasonRequiredText,
    required this.confirmLabel,
    required this.confirmIcon,
  });

  final String title;
  final String description;
  final String reasonLabel;
  final String reasonPlaceholder;
  final String reasonRequiredText;
  final String confirmLabel;
  final IconData confirmIcon;

  @override
  State<_ReasonActionSheet> createState() => _ReasonActionSheetState();
}

class _ReasonActionSheetState extends State<_ReasonActionSheet> {
  final TextEditingController _reasonController = TextEditingController();
  final FocusNode _reasonFocusNode = FocusNode();
  String? _errorText;

  @override
  void dispose() {
    _reasonController.dispose();
    _reasonFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _errorText = widget.reasonRequiredText);
      _reasonFocusNode.requestFocus();
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final compact = mediaQuery.size.width < 390;

    return _DetailsResponsiveTextScope(
      child: AppDismissibleModalSheet(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: mediaQuery.viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xF92A190D), Color(0xFA180E08)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.34),
                      blurRadius: 36,
                      offset: const Offset(0, -18),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 16 : 18,
                    14,
                    compact ? 16 : 18,
                    compact ? 18 : 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 52,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Center(
                        child: Container(
                          width: compact ? 58 : 62,
                          height: compact ? 58 : 62,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent.withValues(alpha: 0.12),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.26),
                            ),
                          ),
                          child: Icon(
                            widget.confirmIcon,
                            color: AppColors.accent,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _DetailsColors.text,
                            fontSize: compact ? 21 : 23,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: Text(
                            widget.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _DetailsColors.muted,
                              fontSize: compact ? 13.5 : 14,
                              height: 1.42,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        widget.reasonLabel,
                        style: const TextStyle(
                          color: _DetailsColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: _errorText == null
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0x88FF8A65),
                          ),
                        ),
                        child: TextField(
                          controller: _reasonController,
                          focusNode: _reasonFocusNode,
                          maxLines: 4,
                          minLines: 3,
                          maxLength: 160,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(
                            color: _DetailsColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                          decoration: InputDecoration(
                            hintText: widget.reasonPlaceholder,
                            hintStyle: TextStyle(
                              color: _DetailsColors.muted.withValues(
                                alpha: 0.72,
                              ),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            border: InputBorder.none,
                            counterStyle: const TextStyle(
                              color: _DetailsColors.subtle,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            contentPadding: const EdgeInsets.fromLTRB(
                              16,
                              14,
                              16,
                              10,
                            ),
                          ),
                          onChanged: (_) {
                            if (_errorText == null) {
                              return;
                            }
                            if (_reasonController.text.trim().isNotEmpty) {
                              setState(() => _errorText = null);
                            }
                          },
                          onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        ),
                      ),
                      if (_errorText != null) ...[
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            _errorText!,
                            style: const TextStyle(
                              color: Color(0xFFFF8A65),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final stackVertically = constraints.maxWidth < 360;
                          final keepButton = _SheetActionButton(
                            label: l10n.activityCancelKeepButton,
                            icon: Icons.arrow_back_rounded,
                            isPrimary: false,
                            onTap: () => Navigator.of(context).pop(),
                          );
                          final confirmButton = _SheetActionButton(
                            label: widget.confirmLabel,
                            icon: widget.confirmIcon,
                            isPrimary: true,
                            onTap: _submit,
                          );

                          if (stackVertically) {
                            return Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: keepButton,
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: confirmButton,
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: keepButton),
                              const SizedBox(width: 12),
                              Expanded(child: confirmButton),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetActionButton extends StatelessWidget {
  const _SheetActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final minHeight = _detailsScaled(context, 52, min: 48, max: 54);
    final iconSize = _detailsScaled(context, 16, min: 15, max: 18);

    final backgroundColor = isPrimary
        ? AppColors.accent
        : Colors.white.withValues(alpha: 0.06);
    final foregroundColor = isPrimary ? Colors.white : _DetailsColors.text;
    final borderColor = isPrimary
        ? AppColors.accent
        : Colors.white.withValues(alpha: 0.1);

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: borderColor),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize),
            SizedBox(width: _detailsScaled(context, 8, min: 6, max: 9)),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsTopBar extends StatelessWidget {
  const _DetailsTopBar({
    required this.title,
    required this.status,
    required this.statusColor,
    required this.compact,
    required this.onBack,
    required this.onShare,
  });

  final String title;
  final String status;
  final Color statusColor;
  final bool compact;
  final VoidCallback onBack;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final scale = _detailsUiScale(context);
    final sideSpacing = _detailsScaled(context, compact ? 10 : 12, min: 8);
    final titleFontSize = (compact ? 16 : 18) * scale;
    final statusFontSize = (compact ? 10 : 11) * scale;
    final statusDotSize = _detailsScaled(context, 9, min: 7, max: 10);

    return Row(
      children: [
        _CircleIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: onBack,
        ),
        SizedBox(width: sideSpacing),
        Expanded(
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _DetailsColors.text,
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: _detailsScaled(context, 4, min: 3, max: 5)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: statusDotSize,
                    height: statusDotSize,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.42),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: _detailsScaled(context, 7, min: 5, max: 8)),
                  Flexible(
                    child: Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _DetailsColors.subtle,
                        fontSize: statusFontSize,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: sideSpacing),
        _CircleIconButton(icon: Icons.share_outlined, onTap: onShare),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final side = _detailsScaled(context, 40, min: 36, max: 44);
    final iconSize = _detailsScaled(context, 20, min: 18, max: 22);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: side,
          height: side,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Icon(icon, color: _DetailsColors.text, size: iconSize),
        ),
      ),
    );
  }
}

class _DetailsHero extends StatelessWidget {
  const _DetailsHero({
    required this.height,
    required this.categorySlug,
    required this.categoryLabel,
    required this.contextLabel,
    this.imageUrl,
  });

  final double height;
  final String categorySlug;
  final String categoryLabel;
  final String contextLabel;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final visual = _detailsHeroVisual(categorySlug);

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.36),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: visual.backgroundColors,
                  stops: const [0, 0.32, 0.58, 0.82, 1],
                ),
              ),
            ),
            Positioned.fill(child: _DetailsHeroArtwork(visual: visual)),
            if (imageUrl?.trim().isNotEmpty == true)
              Image.network(
                imageUrl!.trim(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.16),
                      Colors.black.withValues(alpha: 0.48),
                      Colors.black.withValues(alpha: 0.72),
                    ],
                    stops: const [0, 0.28, 0.68, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -18,
              right: -18,
              bottom: -10,
              height: height * 0.42,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.white.withValues(alpha: 0.01),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -24,
              right: -24,
              bottom: 24,
              height: height * 0.22,
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002)
                  ..rotateX(1.18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: List.generate(
                        10,
                        (index) => index.isEven
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: height * 0.38,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.34),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _StatusPill(
                    label: categoryLabel,
                    backgroundColor: AppColors.accent,
                    textColor: Colors.white,
                  ),
                  _StatusPill(
                    label: contextLabel,
                    backgroundColor: _DetailsColors.mutedPill,
                    textColor: _DetailsColors.text,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsHeroArtwork extends StatelessWidget {
  const _DetailsHeroArtwork({required this.visual});

  final _DetailsHeroVisualSpec visual;

  @override
  Widget build(BuildContext context) {
    final glowSizeLarge = _detailsScaled(context, 188, min: 148, max: 208);
    final glowSizeSmall = _detailsScaled(context, 132, min: 108, max: 150);
    final centerOrb = _detailsScaled(context, 112, min: 90, max: 122);
    final ridgeHeight = _detailsScaled(context, 118, min: 96, max: 132);
    final baseHeight = _detailsScaled(context, 150, min: 122, max: 168);

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: -36,
          right: -18,
          child: Container(
            width: glowSizeLarge,
            height: glowSizeLarge,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  visual.glowColor.withValues(alpha: 0.48),
                  visual.glowColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: -26,
          top: 72,
          child: Container(
            width: glowSizeSmall,
            height: glowSizeSmall,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.18),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          top: 28,
          bottom: 98,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 18,
                  right: 18,
                  top: 14,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      4,
                      (index) => Container(
                        width: 30 + (index * 10),
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: index.isEven ? 0.14 : 0.08,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: centerOrb,
                    height: centerOrb,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.28),
                          Colors.white.withValues(alpha: 0.08),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 1.4,
                      ),
                    ),
                    child: Icon(visual.icon, color: Colors.white, size: 48),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: -18,
          right: -18,
          bottom: 64,
          height: ridgeHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  visual.ridgeColor.withValues(alpha: 0.0),
                  visual.ridgeColor.withValues(alpha: 0.74),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: -24,
          right: -24,
          bottom: -18,
          height: baseHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  visual.baseColor.withValues(alpha: 0.0),
                  visual.baseColor.withValues(alpha: 0.88),
                  visual.baseColor,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeadingSection extends StatelessWidget {
  const _HeadingSection({
    required this.title,
    required this.description,
    required this.compact,
  });

  final String title;
  final String description;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: _DetailsColors.text,
            fontSize: compact ? 24 : 27,
            fontWeight: FontWeight.w800,
            height: 1.08,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: TextStyle(
            color: _DetailsColors.muted,
            fontSize: compact ? 14 : 15,
            height: 1.48,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _LifecycleReasonCard extends StatelessWidget {
  const _LifecycleReasonCard({
    required this.title,
    required this.reason,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String reason;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final badgeSize = _detailsScaled(context, 38, min: 34, max: 40);
    final iconSize = _detailsScaled(context, 18, min: 16, max: 19);
    final gap = _detailsScaled(context, 12, min: 9, max: 13);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: accentColor.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, color: accentColor, size: iconSize),
          ),
          SizedBox(width: gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  reason,
                  style: const TextStyle(
                    color: _DetailsColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.42,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HostCard extends StatelessWidget {
  const _HostCard({
    required this.hostName,
    required this.avatarUrl,
    required this.avatarFallbackText,
    required this.activityRating,
    required this.subtitle,
    required this.onTap,
  });

  final String hostName;
  final String? avatarUrl;
  final String avatarFallbackText;
  final double activityRating;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final avatarSize = _detailsScaled(context, 50, min: 44, max: 54);
        final avatarIcon = _detailsScaled(context, 23, min: 20, max: 25);
        final badgeSize = _detailsScaled(context, 20, min: 17, max: 21);
        final gap = _detailsScaled(context, 12, min: 9, max: 14);
        final compact = constraints.maxWidth < 360;
        final avatar = Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2A9EA4), Color(0xFF2D7478)],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: avatarUrl == null
                    ? Center(
                        child: Text(
                          avatarFallbackText,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: avatarIcon * 0.72,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                      )
                    : Image.network(
                        avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Center(
                          child: Text(
                            avatarFallbackText,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: avatarIcon * 0.72,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.star_rounded,
                  color: Colors.white,
                  size: _detailsScaled(context, 13, min: 11, max: 14),
                ),
              ),
            ),
          ],
        );
        final textBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    hostName,
                    maxLines: compact ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _DetailsColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _HostRatingPill(label: _formatRating(activityRating)),
              ],
            ),
            if (subtitle.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: compact ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ],
        );

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.05),
                    Colors.white.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  avatar,
                  SizedBox(width: gap),
                  Expanded(child: textBlock),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.accent.withValues(alpha: 0.76),
                    size: _detailsScaled(context, 22, min: 20, max: 24),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HostRatingPill extends StatelessWidget {
  const _HostRatingPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 26),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            color: AppColors.accent,
            size: _detailsScaled(context, 14, min: 12, max: 15),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatRating(double value) {
  if (value <= 0) return '5.0';
  return value.toStringAsFixed(1);
}

String? _resolveActivityScheduleUserTimezone({
  required String? deviceTimezone,
  required String? profileTimezone,
}) {
  return _normalizeActivityScheduleTimezone(deviceTimezone) ??
      _normalizeActivityScheduleTimezone(profileTimezone);
}

String? _normalizeActivityScheduleTimezone(String? timezone) {
  final normalized = timezone?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  return normalized;
}

class _ActivityScheduleCard extends StatelessWidget {
  const _ActivityScheduleCard({
    required this.activity,
    required this.l10n,
    required this.compact,
    required this.userTimezone,
  });

  final ActivityListItemVm activity;
  final AppLocalizations l10n;
  final bool compact;
  final String? userTimezone;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final dense = compact || textScale > 1.1;
    final startText = formatEventDateTime(
      activity.startAt,
      timezoneId: activity.timezone,
      localeName: locale,
    );
    final endText = formatEventDateTime(
      activity.endAt,
      timezoneId: activity.timezone,
      localeName: locale,
    );
    final startUserTime = formatUserTimezoneHint(
      instant: activity.startAt,
      eventTimezoneId: activity.timezone,
      userTimezoneId: userTimezone,
      localeName: locale,
    );
    final endUserTime = formatUserTimezoneHint(
      instant: activity.endAt,
      eventTimezoneId: activity.timezone,
      userTimezoneId: userTimezone,
      localeName: locale,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, dense ? 15 : 17, 16, dense ? 15 : 17),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.18),
                  ),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.accent,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.activityDateAndTime,
                  style: const TextStyle(
                    color: _DetailsColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: dense ? 14 : 16),
          _ScheduleTimeRow(
            label: l10n.createStartAtLabel,
            timeText: startText,
            userTimeText: startUserTime == null
                ? null
                : l10n.timeDisplayYourTime(startUserTime),
            icon: Icons.play_arrow_rounded,
            dense: dense,
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: dense ? 10 : 12),
            child: Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          _ScheduleTimeRow(
            label: l10n.createEndAtLabel,
            timeText: endText,
            userTimeText: endUserTime == null
                ? null
                : l10n.timeDisplayYourTime(endUserTime),
            icon: Icons.flag_rounded,
            dense: dense,
          ),
        ],
      ),
    );
  }
}

class _ScheduleTimeRow extends StatelessWidget {
  const _ScheduleTimeRow({
    required this.label,
    required this.timeText,
    required this.userTimeText,
    required this.icon,
    required this.dense,
  });

  final String label;
  final String timeText;
  final String? userTimeText;
  final IconData icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final userTime = userTimeText;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(icon, color: AppColors.accent, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: _DetailsColors.subtle,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                timeText,
                style: TextStyle(
                  color: _DetailsColors.text,
                  fontSize: dense ? 14 : 15,
                  fontWeight: FontWeight.w800,
                  height: 1.28,
                  letterSpacing: 0,
                ),
              ),
              if (userTime != null) ...[
                const SizedBox(height: 7),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                    child: Text(
                      userTime,
                      style: const TextStyle(
                        color: _DetailsColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.activity,
    required this.l10n,
    required this.compact,
  });

  final ActivityListItemVm activity;
  final AppLocalizations l10n;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final pricingText = activity.isFree
        ? l10n.freeLabel
        : '${activity.formattedPriceLabel(locale)} ${l10n.activityPerPerson}';
    final formatText = formatActivityFormat(activity.format, l10n);
    final capacityText =
        activity.capacityType.toUpperCase() == 'LIMITED' &&
            activity.maxParticipants != null
        ? l10n.activityPeopleMax(activity.maxParticipants!)
        : l10n.activityUnlimitedSpots;
    final visibilityText = activity.visibility.toUpperCase() == 'PRIVATE'
        ? l10n.createVisibilityPrivate
        : l10n.createVisibilityPublic;

    final items = [
      _DetailsStatItem(
        icon: Icons.payments_outlined,
        label: l10n.activityPrice,
        value: pricingText,
      ),
      _DetailsStatItem(
        icon: Icons.language_rounded,
        label: l10n.activityFormatLabel,
        value: formatText,
      ),
      _DetailsStatItem(
        icon: Icons.people_outline_rounded,
        label: l10n.activityCapacity,
        value: capacityText,
      ),
      _DetailsStatItem(
        icon: activity.visibility.toUpperCase() == 'PRIVATE'
            ? Icons.lock_outline_rounded
            : Icons.public_rounded,
        label: l10n.activitiesFilterVisibility,
        value: visibilityText,
      ),
    ];

    final horizontalSpacing = compact ? 10.0 : 12.0;
    final verticalSpacing = compact ? 8.0 : 10.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        Widget buildRow(int startIndex) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _DetailsStatCard(item: items[startIndex])),
                SizedBox(width: horizontalSpacing),
                Expanded(child: _DetailsStatCard(item: items[startIndex + 1])),
              ],
            ),
          );
        }

        return Container(
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildRow(0),
              SizedBox(height: verticalSpacing),
              buildRow(2),
            ],
          ),
        );
      },
    );
  }
}

class _DetailsStatItem {
  const _DetailsStatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _DetailsStatCard extends StatelessWidget {
  const _DetailsStatCard({required this.item});

  final _DetailsStatItem item;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final dense = textScale > 1.1;

    return Container(
      padding: EdgeInsets.fromLTRB(14, dense ? 13 : 15, 14, dense ? 12 : 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.045),
            Colors.white.withValues(alpha: 0.035),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, color: AppColors.accent, size: 21),
          SizedBox(height: dense ? 12 : 15),
          Text(
            item.label.toUpperCase(),
            style: const TextStyle(
              color: _DetailsColors.subtle,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: dense ? 5 : 6),
          Text(
            item.value,
            style: const TextStyle(
              color: _DetailsColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.32,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _MeetingSection extends StatelessWidget {
  const _MeetingSection({
    required this.activity,
    required this.l10n,
    required this.isJoined,
    required this.isOwner,
    required this.canShowAttendanceQr,
    required this.canLeaveActivity,
    required this.canCancelActivity,
    required this.canExtendActivity,
    required this.canCompleteActivity,
    required this.isLeaving,
    required this.isExtending30,
    required this.isExtending60,
    required this.isCompleting,
    required this.isCancelling,
    required this.isBuildingRoute,
    required this.onLeaveTap,
    required this.onExtend30Tap,
    required this.onExtend60Tap,
    required this.onCompleteTap,
    required this.onCancelTap,
    required this.onShowAttendanceQrTap,
    required this.onActionTap,
  });

  final ActivityListItemVm activity;
  final AppLocalizations l10n;
  final bool isJoined;
  final bool isOwner;
  final bool canShowAttendanceQr;
  final bool canLeaveActivity;
  final bool canCancelActivity;
  final bool canExtendActivity;
  final bool canCompleteActivity;
  final bool isLeaving;
  final bool isExtending30;
  final bool isExtending60;
  final bool isCompleting;
  final bool isCancelling;
  final bool isBuildingRoute;
  final VoidCallback onLeaveTap;
  final VoidCallback onExtend30Tap;
  final VoidCallback onExtend60Tap;
  final VoidCallback onCompleteTap;
  final VoidCallback onCancelTap;
  final VoidCallback onShowAttendanceQrTap;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    final mapHeight = _detailsScaled(context, 220, min: 190, max: 236);

    final hasMeetingLink = (activity.meetingUrl ?? '').trim().isNotEmpty;
    final hasLocation =
        (activity.addressText ?? '').trim().isNotEmpty ||
        activity.shortLocation.isNotEmpty;
    if (!hasMeetingLink && !hasLocation) {
      return const SizedBox.shrink();
    }

    final showProtectedNotice = hasMeetingLink && !(isJoined || isOwner);
    final actionLabel = hasMeetingLink && (isJoined || isOwner)
        ? l10n.createMeetingUrlLabel
        : l10n.activityGetDirections;
    final locationLine = (activity.addressText ?? '').trim().isNotEmpty
        ? activity.addressText!.trim()
        : activity.shortLocation;
    final meetingPoint = _resolveMeetingPoint(activity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final stackHeader = constraints.maxWidth < 370;
            if (stackHeader) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.activityMeetingPoint,
                    style: const TextStyle(
                      color: _DetailsColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: isBuildingRoute ? null : onActionTap,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: isBuildingRoute
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.accent,
                            ),
                          )
                        : Text(
                            actionLabel,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.activityMeetingPoint,
                    style: const TextStyle(
                      color: _DetailsColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: isBuildingRoute ? null : onActionTap,
                  child: isBuildingRoute
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        )
                      : Text(
                          actionLabel,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        Container(
          height: mapHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (meetingPoint != null)
                  _MeetingMapCard(point: meetingPoint)
                else
                  _MeetingLocationFallbackCard(
                    label: locationLine.isNotEmpty
                        ? locationLine
                        : l10n.notSpecified,
                    activity: activity,
                  ),
                if (showProtectedNotice)
                  _ProtectedMeetingNoticeOverlay(l10n: l10n),
                Positioned(
                  left: 16,
                  top: 16,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A0F08).withValues(alpha: 0.86),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.place_rounded,
                            size: 15,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.activityMeetingPoint,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.place_outlined,
                color: _DetailsColors.subtle,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: showProtectedNotice
                  ? Text(
                      l10n.activitySensitiveDetailsHint,
                      style: const TextStyle(
                        color: _DetailsColors.muted,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    )
                  : AppLocalizedLocationText(
                      countryCode: activity.countryCode,
                      cityId: activity.cityId,
                      cityName: activity.cityName,
                      addressText: activity.addressText,
                      fallbackText: locationLine.isNotEmpty
                          ? locationLine
                          : l10n.notSpecified,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _DetailsColors.muted,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
            ),
          ],
        ),
        if (canLeaveActivity) ...[
          const SizedBox(height: 18),
          Center(
            child: _MeetingLeaveAction(
              label: l10n.activityLeaveInlineButton,
              isBusy: isLeaving,
              onTap: onLeaveTap,
            ),
          ),
        ],
        if (canShowAttendanceQr) ...[
          const SizedBox(height: 18),
          Center(
            child: _MeetingOwnerQrAction(
              label: l10n.activityAttendanceQrButton,
              onTap: onShowAttendanceQrTap,
            ),
          ),
        ],
        if (canExtendActivity) ...[
          const SizedBox(height: 18),
          _MeetingOwnerExtendRow(
            extend30Label: l10n.activityExtend30MinutesButton,
            extend60Label: l10n.activityExtend60MinutesButton,
            isExtending30: isExtending30,
            isExtending60: isExtending60,
            onExtend30Tap: onExtend30Tap,
            onExtend60Tap: onExtend60Tap,
          ),
        ],
        if (canCompleteActivity) ...[
          const SizedBox(height: 14),
          Center(
            child: _MeetingOwnerCompleteAction(
              label: l10n.activityCompleteNowButton,
              isBusy: isCompleting,
              onTap: onCompleteTap,
            ),
          ),
        ],
        if (canCancelActivity) ...[
          const SizedBox(height: 18),
          Center(
            child: _MeetingOwnerCancelAction(
              label: l10n.activityCancelButton,
              isBusy: isCancelling,
              onTap: onCancelTap,
            ),
          ),
        ],
      ],
    );
  }
}

class _ProtectedMeetingNoticeOverlay extends StatelessWidget {
  const _ProtectedMeetingNoticeOverlay({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.26),
      padding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final minHeight = constraints.hasBoundedHeight
                  ? constraints.maxHeight
                  : 0.0;

              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minHeight),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.activitySensitiveDetailsProtected,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MeetingMapCard extends StatelessWidget {
  const _MeetingMapCard({required this.point});

  final LatLng point;

  @override
  Widget build(BuildContext context) {
    return AppMapCard(
      target: point,
      hasMarker: true,
      initialZoom: 15.4,
      // Read-only native map platform views can be unstable when Android/iOS
      // recreate surfaces after app backgrounding. Keep details cards static.
      nativeMapEnabled: _shouldUseNativeReadOnlyMeetingMap(context),
    );
  }
}

bool _shouldUseNativeReadOnlyMeetingMap(BuildContext context) {
  final platform = Theme.of(context).platform;
  return platform != TargetPlatform.iOS && platform != TargetPlatform.android;
}

class _MeetingLocationFallbackCard extends StatelessWidget {
  const _MeetingLocationFallbackCard({
    required this.label,
    required this.activity,
  });

  final String label;
  final ActivityListItemVm activity;

  @override
  Widget build(BuildContext context) {
    final iconWrap = _detailsScaled(context, 66, min: 56, max: 72);
    final iconSize = _detailsScaled(context, 32, min: 26, max: 34);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2D1C0F), Color(0xFF1C110A)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: iconWrap,
                height: iconWrap,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.34),
                  ),
                ),
                child: Icon(
                  Icons.place_rounded,
                  color: AppColors.accent,
                  size: iconSize,
                ),
              ),
              const SizedBox(height: 18),
              AppLocalizedLocationText(
                countryCode: activity.countryCode,
                cityId: activity.cityId,
                cityName: activity.cityName,
                addressText: activity.addressText,
                fallbackText: label,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeetingLeaveAction extends StatelessWidget {
  const _MeetingLeaveAction({
    required this.label,
    required this.isBusy,
    required this.onTap,
  });

  final String label;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: isBusy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isBusy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.1,
                    color: AppColors.accent,
                  ),
                )
              else
                Icon(
                  Icons.logout_rounded,
                  size: 16,
                  color: AppColors.accent.withValues(alpha: 0.9),
                ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.accent.withValues(alpha: 0.94),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeetingOwnerCancelAction extends StatelessWidget {
  const _MeetingOwnerCancelAction({
    required this.label,
    required this.isBusy,
    required this.onTap,
  });

  final String label;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: isBusy ? null : onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.24)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isBusy)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.1,
                      color: AppColors.accent,
                    ),
                  )
                else
                  Icon(
                    Icons.event_busy_rounded,
                    size: 16,
                    color: AppColors.accent.withValues(alpha: 0.94),
                  ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.accent.withValues(alpha: 0.96),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MeetingOwnerExtendRow extends StatelessWidget {
  const _MeetingOwnerExtendRow({
    required this.extend30Label,
    required this.extend60Label,
    required this.isExtending30,
    required this.isExtending60,
    required this.onExtend30Tap,
    required this.onExtend60Tap,
  });

  final String extend30Label;
  final String extend60Label;
  final bool isExtending30;
  final bool isExtending60;
  final VoidCallback onExtend30Tap;
  final VoidCallback onExtend60Tap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackVertically = constraints.maxWidth < 370;
        if (stackVertically) {
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: _MeetingOwnerTonalAction(
                  label: extend30Label,
                  icon: Icons.add_alarm_rounded,
                  isBusy: isExtending30,
                  onTap: onExtend30Tap,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: _MeetingOwnerTonalAction(
                  label: extend60Label,
                  icon: Icons.schedule_rounded,
                  isBusy: isExtending60,
                  onTap: onExtend60Tap,
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _MeetingOwnerTonalAction(
                label: extend30Label,
                icon: Icons.add_alarm_rounded,
                isBusy: isExtending30,
                onTap: onExtend30Tap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MeetingOwnerTonalAction(
                label: extend60Label,
                icon: Icons.schedule_rounded,
                isBusy: isExtending60,
                onTap: onExtend60Tap,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MeetingOwnerTonalAction extends StatelessWidget {
  const _MeetingOwnerTonalAction({
    required this.label,
    required this.icon,
    required this.isBusy,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: isBusy ? null : onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isBusy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.1,
                    color: AppColors.accent,
                  ),
                )
              else
                Icon(
                  icon,
                  size: 16,
                  color: AppColors.accent.withValues(alpha: 0.96),
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _DetailsColors.text.withValues(alpha: 0.96),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeetingOwnerCompleteAction extends StatelessWidget {
  const _MeetingOwnerCompleteAction({
    required this.label,
    required this.isBusy,
    required this.onTap,
  });

  final String label;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: isBusy ? null : onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accent,
                AppColors.accent.withValues(alpha: 0.84),
              ],
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.2),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isBusy)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.1,
                      color: AppColors.textPrimary,
                    ),
                  )
                else
                  const Icon(
                    Icons.task_alt_rounded,
                    size: 16,
                    color: AppColors.textPrimary,
                  ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MeetingOwnerQrAction extends StatelessWidget {
  const _MeetingOwnerQrAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accent,
                AppColors.accent.withValues(alpha: 0.84),
              ],
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.2),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.qr_code_2_rounded,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InviteFriendsSheet extends StatefulWidget {
  const _InviteFriendsSheet({
    required this.activityId,
    required this.activityApi,
    required this.profileApi,
    required this.excludedUserIds,
  });

  final String activityId;
  final ActivityApi activityApi;
  final ProfileApi profileApi;
  final Set<String> excludedUserIds;

  @override
  State<_InviteFriendsSheet> createState() => _InviteFriendsSheetState();
}

class _InviteFriendsSheetState extends State<_InviteFriendsSheet> {
  static const int _pageSize = 20;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<String> _selectedFriendIds = <String>{};
  final Set<String> _invitedFriendIds = <String>{};

  Timer? _searchDebounce;
  List<ProfileFollowerVm> _friends = const [];
  int? _nextOffset = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _submitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    _scrollController.addListener(_handleScroll);
    unawaited(_reload());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 320),
      () => unawaited(_reload()),
    );
  }

  void _handleScroll() {
    if (_loading || _loadingMore || _nextOffset == null) {
      return;
    }
    if (_scrollController.position.extentAfter < 260) {
      unawaited(_loadMore());
    }
  }

  Future<void> _reload() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadingMore = false;
        _errorText = null;
        _nextOffset = 0;
      });
    }
    await _fetchFriends(append: false);
  }

  Future<void> _loadMore() async {
    if (_nextOffset == null) {
      return;
    }
    if (mounted) {
      setState(() {
        _loadingMore = true;
        _errorText = null;
      });
    }
    await _fetchFriends(append: true);
  }

  Future<void> _fetchFriends({required bool append}) async {
    final offset = append ? _nextOffset : 0;
    if (offset == null) {
      return;
    }

    try {
      final page = await widget.profileApi.getMyFriends(
        limit: _pageSize,
        offset: offset,
        query: _searchController.text.trim(),
        sort: 'name',
        sortDirection: 'asc',
      );
      if (!mounted) return;

      final incoming = page.items
          .where(_canInviteFriend)
          .toList(growable: false);
      final merged = <String, ProfileFollowerVm>{
        if (append)
          for (final friend in _friends) friend.userId: friend,
        for (final friend in incoming) friend.userId: friend,
      };

      setState(() {
        _friends = merged.values.toList(growable: false);
        _nextOffset = page.nextOffset;
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _errorText = 'failed';
      });
    }
  }

  bool _canInviteFriend(ProfileFollowerVm friend) {
    final userId = friend.userId.trim();
    return userId.isNotEmpty &&
        !widget.excludedUserIds.contains(userId) &&
        !_invitedFriendIds.contains(userId);
  }

  void _toggleFriend(String userId) {
    setState(() {
      if (!_selectedFriendIds.add(userId)) {
        _selectedFriendIds.remove(userId);
      }
    });
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (_selectedFriendIds.isEmpty || _submitting) {
      return;
    }

    final userIds = _selectedFriendIds.toList(growable: false);
    setState(() => _submitting = true);
    try {
      await widget.activityApi.inviteFriends(widget.activityId, userIds);
      if (!mounted) return;
      setState(() {
        _invitedFriendIds.addAll(userIds);
        _selectedFriendIds.clear();
        _friends = _friends.where(_canInviteFriend).toList(growable: false);
        _submitting = false;
      });
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.activityInviteFriendsFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomSafePadding = MediaQuery.viewPaddingOf(context).bottom;
    final selectedCount = _selectedFriendIds.length;
    final canSubmit = selectedCount > 0 && !_submitting;

    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.82,
            ),
            decoration: BoxDecoration(
              color: _DetailsColors.sheet,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 10, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.activityInviteFriendsTitle,
                          style: const TextStyle(
                            color: _DetailsColors.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: _DetailsColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                  child: _InviteFriendSearchField(
                    controller: _searchController,
                    hintText: l10n.activityInviteFriendsSearchHint,
                  ),
                ),
                const Divider(height: 1, color: Color(0x14FFFFFF)),
                Expanded(child: _buildBody(l10n)),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    22,
                    12,
                    22,
                    18 + bottomSafePadding,
                  ),
                  child: IgnorePointer(
                    ignoring: !canSubmit,
                    child: Opacity(
                      opacity: canSubmit ? 1 : 0.48,
                      child: AppFilterApplyButton(
                        label: l10n.activityInviteFriendsSend(selectedCount),
                        icon: Icons.send_rounded,
                        isLoading: _submitting,
                        onTap: () => unawaited(_submit(l10n)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading && _friends.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (_errorText != null && _friends.isEmpty) {
      return _InviteFriendsMessage(
        icon: Icons.wifi_off_rounded,
        title: l10n.activityInviteFriendsLoadFailed,
        subtitle: l10n.activityInviteFriendsRetryHint,
        onRetry: () => unawaited(_reload()),
      );
    }

    if (_friends.isEmpty) {
      return _InviteFriendsMessage(
        icon: Icons.group_add_rounded,
        title: l10n.activityInviteFriendsEmptyTitle,
        subtitle: l10n.activityInviteFriendsEmptySubtitle,
        onRetry: null,
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
      itemCount: _friends.length + (_loadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index >= _friends.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.accent,
                ),
              ),
            ),
          );
        }

        final friend = _friends[index];
        final selected = _selectedFriendIds.contains(friend.userId);
        return _InviteFriendRow(
          friend: friend,
          selected: selected,
          onTap: () => _toggleFriend(friend.userId),
        );
      },
    );
  }
}

class _InviteFriendSearchField extends StatelessWidget {
  const _InviteFriendSearchField({
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      decoration: BoxDecoration(
        color: const Color(0xFF2B1F14),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(15, 0, 14, 0),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.accent, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              cursorColor: AppColors.accent,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: const TextStyle(color: Color(0xFF9F8B7D)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteFriendRow extends StatelessWidget {
  const _InviteFriendRow({
    required this.friend,
    required this.selected,
    required this.onTap,
  });

  final ProfileFollowerVm friend;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = friend.nicknameOrFallback('user_${friend.userId}');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.accent.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              _InviteFriendAvatar(friend: friend),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    if (friend.isOnline) ...[
                      const SizedBox(height: 3),
                      Text(
                        l10n.chatPresenceOnline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Checkbox(
                value: selected,
                onChanged: (_) => onTap(),
                activeColor: AppColors.accent,
                checkColor: AppColors.textPrimary,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.32)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InviteFriendAvatar extends StatelessWidget {
  const _InviteFriendAvatar({required this.friend});

  final ProfileFollowerVm friend;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolvePublicFileContentUrl(friend.avatarFileId ?? '');
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ClipOval(
        child: ColoredBox(
          color: const Color(0xFF171009),
          child: imageUrl == null
              ? Center(
                  child: Text(
                    friend.initials,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Center(
                    child: Text(
                      friend.initials,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _InviteFriendsMessage extends StatelessWidget {
  const _InviteFriendsMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.accent, size: 34),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _DetailsColors.muted,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              TextButton(
                onPressed: onRetry,
                child: Text(
                  MaterialLocalizations.of(
                    context,
                  ).refreshIndicatorSemanticLabel,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ParticipantsSection extends StatelessWidget {
  const _ParticipantsSection({
    required this.l10n,
    required this.participants,
    required this.resolvedProfiles,
    required this.currentProfile,
    required this.compact,
    required this.isLoading,
    required this.loadFailed,
    this.onViewAll,
  });

  final AppLocalizations l10n;
  final List<ActivityParticipantVm> participants;
  final Map<String, UserProfileVm> resolvedProfiles;
  final UserProfileVm? currentProfile;
  final bool compact;
  final bool isLoading;
  final bool loadFailed;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final rowHeight = _detailsScaled(context, 44, min: 40, max: 46);
    final overlap = _detailsScaled(context, 26, min: 22, max: 28);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final stackHeader = constraints.maxWidth < 360 && onViewAll != null;
            if (stackHeader) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.activityGoingTitle(participants.length),
                    style: const TextStyle(
                      color: _DetailsColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: onViewAll,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.activityDetailsViewAll,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.activityGoingTitle(participants.length),
                    style: const TextStyle(
                      color: _DetailsColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: Text(
                      l10n.activityDetailsViewAll,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        if (participants.isNotEmpty)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: rowHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (var i = 0; i < math.min(participants.length, 6); i++)
                        Positioned(
                          left: i * overlap,
                          child: _ParticipantAvatar(
                            seed: participants[i].userId,
                            imageUrl: _resolveUserAvatarUrl(
                              participants[i].userId,
                              resolvedProfiles: resolvedProfiles,
                              currentProfile: currentProfile,
                            ),
                            radius: 19,
                            borderColor: _DetailsColors.base,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (participants.length > 6)
                Text(
                  '+${participants.length - 6}',
                  style: const TextStyle(
                    color: _DetailsColors.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          )
        else if (isLoading)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: const Center(
              child: SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppColors.accent,
                ),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 16 : 18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Text(
              loadFailed
                  ? l10n.activityParticipantsLoadFailed
                  : l10n.activityParticipantsEmpty,
              style: const TextStyle(
                color: _DetailsColors.muted,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
      ],
    );
  }
}

class _ParticipantAvatar extends StatelessWidget {
  const _ParticipantAvatar({
    required this.seed,
    this.imageUrl,
    required this.radius,
    required this.borderColor,
  });

  final String seed;
  final String? imageUrl;
  final double radius;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final borderWidth = _detailsScaled(context, 3, min: 2.2, max: 3.2);
    final colors = _seedGradient(seed);
    final initials = _seedInitials(seed);

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: borderWidth),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: ClipOval(
        child: imageUrl == null
            ? Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: radius * 0.62,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              )
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: radius * 0.62,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _ActivityReviewsSection extends StatelessWidget {
  const _ActivityReviewsSection({
    required this.activityReviews,
    required this.organizerReviews,
    required this.isLoading,
    required this.loadFailed,
    required this.canWriteReview,
    required this.isSavingReview,
    required this.hasMyReview,
    required this.onWriteReviewTap,
  });

  final List<ActivityReviewVm> activityReviews;
  final List<ActivityOrganizerReviewVm> organizerReviews;
  final bool isLoading;
  final bool loadFailed;
  final bool canWriteReview;
  final bool isSavingReview;
  final bool hasMyReview;
  final VoidCallback? onWriteReviewTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasReviews =
        activityReviews.isNotEmpty || organizerReviews.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                l10n.activityReviewsSectionTitle,
                style: const TextStyle(
                  color: _DetailsColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
            if (canWriteReview && onWriteReviewTap != null) ...[
              const SizedBox(width: 10),
              TextButton.icon(
                onPressed: isSavingReview ? null : onWriteReviewTap,
                icon: isSavingReview
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.rate_review_rounded, size: 18),
                label: Text(
                  hasMyReview
                      ? l10n.activityReviewEditButton
                      : l10n.activityReviewWriteButton,
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        if (isLoading)
          const _ActivityReviewSkeletonList()
        else if (loadFailed)
          _ActivityReviewInfoCard(message: l10n.activityReviewsLoadFailed)
        else if (!hasReviews)
          _ActivityReviewInfoCard(message: l10n.activityReviewsEmpty)
        else ...[
          if (activityReviews.isNotEmpty) ...[
            _ActivityReviewGroupTitle(label: l10n.activityReviewsTitle),
            const SizedBox(height: 10),
            for (var i = 0; i < activityReviews.length; i++) ...[
              _ActivityReviewCard(
                author: activityReviews[i].author,
                rating: activityReviews[i].rating,
                comment: activityReviews[i].comment,
                createdAt: activityReviews[i].createdAt,
                subtitle: l10n.activityReviewActivityLabel,
              ),
              if (i != activityReviews.length - 1) const SizedBox(height: 12),
            ],
          ],
          if (activityReviews.isNotEmpty && organizerReviews.isNotEmpty)
            const SizedBox(height: 16),
          if (organizerReviews.isNotEmpty) ...[
            _ActivityReviewGroupTitle(
              label: l10n.activityOrganizerReviewsTitle,
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < organizerReviews.length; i++) ...[
              _ActivityReviewCard(
                author: organizerReviews[i].author,
                rating: organizerReviews[i].rating,
                comment: organizerReviews[i].comment,
                createdAt: organizerReviews[i].createdAt,
                subtitle: l10n.activityReviewOrganizerLabel,
              ),
              if (i != organizerReviews.length - 1) const SizedBox(height: 12),
            ],
          ],
        ],
      ],
    );
  }
}

class _ActivityReviewGroupTitle extends StatelessWidget {
  const _ActivityReviewGroupTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _DetailsColors.muted,
        fontSize: 13,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }
}

class _ActivityReviewCard extends StatelessWidget {
  const _ActivityReviewCard({
    required this.author,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.subtitle,
  });

  final ActivityReviewAuthorVm author;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final authorName = author.resolvedDisplayName.isEmpty
        ? l10n.placeTravelerFallback
        : author.resolvedDisplayName;
    final avatarUrl = author.resolvedAvatarFileId.isEmpty
        ? null
        : resolvePublicFileContentUrl(author.resolvedAvatarFileId);
    final dateText = DateFormat.yMMMd(locale).format(createdAt.toLocal());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF25160B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                backgroundImage: avatarUrl == null
                    ? null
                    : NetworkImage(avatarUrl),
                child: avatarUrl == null
                    ? Text(
                        _displayInitials(authorName, fallback: 'F'),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _DetailsColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$subtitle · $dateText',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _DetailsColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _ActivityReviewRating(value: rating),
            ],
          ),
          if (comment.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comment.trim(),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFD7BFAA),
                fontSize: 14,
                height: 1.48,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityReviewRating extends StatelessWidget {
  const _ActivityReviewRating({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: AppColors.accent, size: 15),
            const SizedBox(width: 3),
            Text(
              value.toStringAsFixed(1),
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityReviewInfoCard extends StatelessWidget {
  const _ActivityReviewInfoCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _DetailsColors.muted,
          fontSize: 13,
          height: 1.42,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ActivityReviewSkeletonList extends StatelessWidget {
  const _ActivityReviewSkeletonList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _ActivityReviewSkeletonCard(),
        SizedBox(height: 12),
        _ActivityReviewSkeletonCard(),
      ],
    );
  }
}

class _ActivityReviewSkeletonCard extends StatelessWidget {
  const _ActivityReviewSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Flexible(flex: 1, child: _ActivityReviewSkeletonDot()),
              const SizedBox(width: 10),
              Expanded(
                flex: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _ActivityReviewSkeletonLine(widthFactor: 0.52),
                    SizedBox(height: 6),
                    _ActivityReviewSkeletonLine(widthFactor: 0.34),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _ActivityReviewSkeletonLine(widthFactor: 0.92),
          const SizedBox(height: 8),
          const _ActivityReviewSkeletonLine(widthFactor: 0.72),
        ],
      ),
    );
  }
}

class _ActivityReviewSkeletonDot extends StatelessWidget {
  const _ActivityReviewSkeletonDot();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
    );
  }
}

class _ActivityReviewSkeletonLine extends StatelessWidget {
  const _ActivityReviewSkeletonLine({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const SizedBox(width: double.infinity, height: 10),
      ),
    );
  }
}

class _DetailsActionBar extends StatelessWidget {
  const _DetailsActionBar({
    required this.activity,
    required this.l10n,
    required this.isOwner,
    required this.isJoined,
    required this.canOpenChat,
    required this.isParticipationPending,
    required this.participantStatusLabel,
    required this.isPaid,
    required this.showPublish,
    required this.isBusy,
    required this.pendingAction,
    required this.onJoin,
    required this.onPublish,
    required this.onEdit,
    required this.onPay,
    required this.onOpenChat,
  });

  final ActivityListItemVm activity;
  final AppLocalizations l10n;
  final bool isOwner;
  final bool isJoined;
  final bool canOpenChat;
  final bool isParticipationPending;
  final String? participantStatusLabel;
  final bool isPaid;
  final bool showPublish;
  final bool isBusy;
  final _FooterAction? pendingAction;
  final VoidCallback onJoin;
  final VoidCallback onPublish;
  final VoidCallback onEdit;
  final VoidCallback? onPay;
  final VoidCallback? onOpenChat;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final showPriceBlock = !activity.isFree;
    final priceLabel = activity.formattedPriceLabel(locale);
    final shouldShowPaymentAction =
        isJoined && !isOwner && !activity.isFree && !isPaid && onPay != null;
    final canShowChatAction = isJoined && canOpenChat && onOpenChat != null;
    final secondaryAction = showPublish
        ? _FooterButtonSpec(
            label: l10n.activityPublishButton,
            icon: Icons.publish_rounded,
            onTap: onPublish,
            style: _FooterButtonStyle.secondary,
            action: _FooterAction.publish,
          )
        : shouldShowPaymentAction && canShowChatAction
        ? _FooterButtonSpec(
            label: l10n.activityDetailsChatButton,
            icon: Icons.forum_rounded,
            onTap: onOpenChat,
            style: _FooterButtonStyle.secondary,
            action: null,
          )
        : null;
    final isRepeatableOwnerActivity =
        isOwner &&
        const {
          'CANCELLED',
          'COMPLETED',
        }.contains(activity.status.toUpperCase());
    final primaryAction = isOwner
        ? _FooterButtonSpec(
            label: isRepeatableOwnerActivity
                ? l10n.myActivitiesRecreateButton
                : l10n.editActivityButton,
            icon: isRepeatableOwnerActivity
                ? Icons.refresh_rounded
                : Icons.edit_outlined,
            onTap: onEdit,
            style: _FooterButtonStyle.primary,
            action: null,
          )
        : isJoined
        ? shouldShowPaymentAction
              ? _FooterButtonSpec(
                  label: l10n.activityPaymentPayButton,
                  icon: Icons.payments_rounded,
                  onTap: onPay,
                  style: _FooterButtonStyle.primary,
                  action: null,
                )
              : canShowChatAction
              ? _FooterButtonSpec(
                  label: l10n.activityDetailsChatButton,
                  icon: Icons.forum_rounded,
                  onTap: onOpenChat,
                  style: _FooterButtonStyle.primary,
                  action: null,
                )
              : _FooterButtonSpec(
                  label:
                      participantStatusLabel ?? l10n.participantStatusRequested,
                  icon: isParticipationPending
                      ? Icons.hourglass_top_rounded
                      : Icons.lock_outline_rounded,
                  onTap: null,
                  style: _FooterButtonStyle.primary,
                  action: null,
                )
        : _FooterButtonSpec(
            label: l10n.activityJoinActivity,
            icon: Icons.chevron_right_rounded,
            onTap: onJoin,
            style: _FooterButtonStyle.primary,
            action: _FooterAction.join,
          );
    final priceBlockLabel = isPaid
        ? l10n.activityPaymentStatusLabel
        : l10n.activityDetailsTotalLabel;
    final priceBlockValue = isPaid ? l10n.activityPaymentPaidValue : priceLabel;
    final priceBlockLabelColor = isPaid
        ? _DetailsColors.success.withValues(alpha: 0.72)
        : const Color(0xFF9C9695);
    final priceBlockValueColor = isPaid ? _DetailsColors.success : Colors.white;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xE02F1809), const Color(0xF51D0E06)],
          ),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stackVertically =
                constraints.maxWidth < 390 ||
                (secondaryAction != null && constraints.maxWidth < 430);
            Widget primaryButton() {
              return _FooterButton(
                spec: primaryAction,
                isBusy: isBusy && pendingAction == primaryAction.action,
              );
            }

            Widget secondaryButton() {
              final action = secondaryAction;
              if (action == null) {
                return const SizedBox.shrink();
              }
              return _FooterButton(
                spec: action,
                isBusy: isBusy && pendingAction == action.action,
              );
            }

            Widget footerActions() {
              if (secondaryAction == null) {
                return SizedBox(width: double.infinity, child: primaryButton());
              }

              if (stackVertically) {
                return Column(
                  children: [
                    SizedBox(width: double.infinity, child: secondaryButton()),
                    const SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: primaryButton()),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: secondaryButton()),
                  const SizedBox(width: 8),
                  Expanded(child: primaryButton()),
                ],
              );
            }

            if (!showPriceBlock) {
              return footerActions();
            }

            if (stackVertically) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showPriceBlock) ...[
                    _FooterPriceBlock(
                      label: priceBlockLabel,
                      value: priceBlockValue,
                      labelColor: priceBlockLabelColor,
                      valueColor: priceBlockValueColor,
                    ),
                    const SizedBox(height: 10),
                  ],
                  footerActions(),
                ],
              );
            }

            return Row(
              children: [
                if (showPriceBlock) ...[
                  _FooterPriceBlock(
                    label: priceBlockLabel,
                    value: priceBlockValue,
                    labelColor: priceBlockLabelColor,
                    valueColor: priceBlockValueColor,
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(child: footerActions()),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FooterPriceBlock extends StatelessWidget {
  const _FooterPriceBlock({
    required this.label,
    required this.value,
    this.labelColor = const Color(0xFF9C9695),
    this.valueColor = Colors.white,
  });

  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 84),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: labelColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: valueColor,
                fontSize: 20,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _FooterButtonStyle { primary, secondary }

class _FooterButtonSpec {
  const _FooterButtonSpec({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.style,
    required this.action,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final _FooterButtonStyle style;
  final _FooterAction? action;
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({required this.spec, required this.isBusy});

  final _FooterButtonSpec spec;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final minHeight = _detailsScaled(context, 54, min: 50, max: 56);
    final iconSize = _detailsScaled(context, 18, min: 16, max: 19);

    final isPrimary = spec.style == _FooterButtonStyle.primary;
    final backgroundColor = isPrimary
        ? AppColors.accent
        : Colors.white.withValues(alpha: 0.08);
    final borderColor = isPrimary
        ? AppColors.accent
        : Colors.white.withValues(alpha: 0.1);
    final foreground = isPrimary ? Colors.white : _DetailsColors.text;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: ElevatedButton(
        onPressed: isBusy || spec.onTap == null ? null : spec.onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foreground,
          disabledBackgroundColor: backgroundColor,
          disabledForegroundColor: foreground,
          elevation: isPrimary ? 0 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: borderColor),
          ),
        ),
        child: isBusy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      spec.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  SizedBox(width: _detailsScaled(context, 6, min: 4, max: 7)),
                  Icon(spec.icon, size: iconSize),
                ],
              ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.maxWidth,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final horizontal = _detailsScaled(context, 14, min: 10, max: 15);
    final vertical = _detailsScaled(context, 7, min: 6, max: 8);
    final fontSize = _detailsScaled(context, 12, min: 11, max: 12.5);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        boxShadow: backgroundColor == AppColors.accent
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ConstrainedBox(
        constraints: maxWidth == null
            ? const BoxConstraints()
            : BoxConstraints(maxWidth: maxWidth!),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _DetailsHeroVisualSpec {
  const _DetailsHeroVisualSpec({
    required this.icon,
    required this.backgroundColors,
    required this.glowColor,
    required this.ridgeColor,
    required this.baseColor,
  });

  final IconData icon;
  final List<Color> backgroundColors;
  final Color glowColor;
  final Color ridgeColor;
  final Color baseColor;
}

String _resolveHeroContextLabel({
  required ActivityListItemVm activity,
  required AppLocalizations l10n,
  required bool isOwner,
  required bool isJoined,
  required int occupyingCount,
}) {
  if (isOwner) {
    return l10n.activityDetailsHostedBadge;
  }
  if (isJoined) {
    return l10n.activityDetailsJoinedBadge;
  }
  if (activity.capacityType.toUpperCase() == 'LIMITED' &&
      activity.maxParticipants != null) {
    final spotsLeft = math.max(activity.maxParticipants! - occupyingCount, 0);
    return l10n.activitySpotsLeft(spotsLeft);
  }
  return l10n.activityUnlimitedSpots;
}

_DetailsHeroVisualSpec _detailsHeroVisual(String rawSlug) {
  final slug = rawSlug.trim().toLowerCase();

  if (slug.contains('wellness') || slug.contains('health')) {
    return const _DetailsHeroVisualSpec(
      icon: Icons.spa_rounded,
      backgroundColors: [
        Color(0xFF9EDFD3),
        Color(0xFF74CBB5),
        Color(0xFF357B70),
        Color(0xFF1D4B45),
        Color(0xFF10211E),
      ],
      glowColor: Color(0xFFB8F6DF),
      ridgeColor: Color(0xFF1B6258),
      baseColor: Color(0xFF0C1816),
    );
  }
  if (slug.contains('nature') ||
      slug.contains('outdoor') ||
      slug.contains('hiking')) {
    return const _DetailsHeroVisualSpec(
      icon: Icons.forest_rounded,
      backgroundColors: [
        Color(0xFFB8DB95),
        Color(0xFF7BBE6D),
        Color(0xFF3C7B42),
        Color(0xFF1D4726),
        Color(0xFF0E1D13),
      ],
      glowColor: Color(0xFFD6F2B8),
      ridgeColor: Color(0xFF2A5F31),
      baseColor: Color(0xFF101A10),
    );
  }
  if (slug.contains('food')) {
    return const _DetailsHeroVisualSpec(
      icon: Icons.restaurant_rounded,
      backgroundColors: [
        Color(0xFFFFD0A1),
        Color(0xFFFFA65F),
        Color(0xFFB95D28),
        Color(0xFF5A2F13),
        Color(0xFF231108),
      ],
      glowColor: Color(0xFFFFD9A8),
      ridgeColor: Color(0xFF7A3B18),
      baseColor: Color(0xFF211109),
    );
  }
  if (slug.contains('culture') ||
      slug.contains('art') ||
      slug.contains('history')) {
    return const _DetailsHeroVisualSpec(
      icon: Icons.palette_outlined,
      backgroundColors: [
        Color(0xFFE0C3EF),
        Color(0xFFC58EDC),
        Color(0xFF7A4D94),
        Color(0xFF3F264F),
        Color(0xFF190E22),
      ],
      glowColor: Color(0xFFF0D4FF),
      ridgeColor: Color(0xFF5A356D),
      baseColor: Color(0xFF170F1F),
    );
  }
  if (slug.contains('sport') || slug.contains('adventure')) {
    return const _DetailsHeroVisualSpec(
      icon: Icons.kayaking_rounded,
      backgroundColors: [
        Color(0xFFF4C07D),
        Color(0xFFE48D44),
        Color(0xFF9E5523),
        Color(0xFF4F2914),
        Color(0xFF1D1008),
      ],
      glowColor: Color(0xFFFFD09A),
      ridgeColor: Color(0xFF6E3717),
      baseColor: Color(0xFF1C1109),
    );
  }
  if (slug.contains('workshop') ||
      slug.contains('learning') ||
      slug.contains('education')) {
    return const _DetailsHeroVisualSpec(
      icon: Icons.auto_stories_rounded,
      backgroundColors: [
        Color(0xFFD7D2FF),
        Color(0xFFAAA0F0),
        Color(0xFF665CB6),
        Color(0xFF342E63),
        Color(0xFF161329),
      ],
      glowColor: Color(0xFFE2DDFF),
      ridgeColor: Color(0xFF4A418D),
      baseColor: Color(0xFF171428),
    );
  }
  if (slug.contains('night') || slug.contains('social')) {
    return const _DetailsHeroVisualSpec(
      icon: Icons.celebration_rounded,
      backgroundColors: [
        Color(0xFFF5BEDD),
        Color(0xFFE58BBE),
        Color(0xFF9A3F75),
        Color(0xFF501D3D),
        Color(0xFF1F0A17),
      ],
      glowColor: Color(0xFFFFD1EC),
      ridgeColor: Color(0xFF712651),
      baseColor: Color(0xFF1D0B17),
    );
  }

  return const _DetailsHeroVisualSpec(
    icon: Icons.travel_explore_rounded,
    backgroundColors: [
      Color(0xFFB7D2E7),
      Color(0xFF7AA4C9),
      Color(0xFF47698A),
      Color(0xFF263C53),
      Color(0xFF101A25),
    ],
    glowColor: Color(0xFFD3E8FA),
    ridgeColor: Color(0xFF33516E),
    baseColor: Color(0xFF101923),
  );
}

String _resolveHostName(
  String hostUserId,
  UserProfileVm? profile, {
  required Map<String, UserProfileVm> resolvedProfiles,
  required AppLocalizations l10n,
}) {
  if (profile != null && profile.userId == hostUserId) {
    return profile.preferredName;
  }
  final hostProfile = resolvedProfiles[hostUserId];
  if (hostProfile != null) {
    return hostProfile.preferredName;
  }
  return l10n.activityDetailsHostFallbackName;
}

String _resolveHostSubtitle({
  required ActivityListItemVm activity,
  required AppLocalizations l10n,
}) {
  return '';
}

String _resolveLocalizedCategoryLabel(
  String rawSlug,
  List<ActivityCategoryVm> categories,
  String languageCode,
) {
  return localizedActivityCategoryLabel(
    categories: categories,
    slug: rawSlug,
    languageCode: languageCode,
  );
}

LatLng? _resolveMeetingPoint(ActivityListItemVm activity) {
  final latitude = activity.latitude;
  final longitude = activity.longitude;
  if (_isValidMeetingPoint(latitude, longitude)) {
    return LatLng(latitude!, longitude!);
  }

  final mapUrl = (activity.mapUrl ?? '').trim();
  if (mapUrl.isEmpty) {
    return null;
  }

  return AppMapLinks.tryParseCoordinates(mapUrl);
}

bool _isValidMeetingPoint(double? latitude, double? longitude) {
  if (latitude == null || longitude == null) {
    return false;
  }
  return latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

String _resolveUserName(
  String userId,
  AppLocalizations l10n, {
  Map<String, UserProfileVm> resolvedProfiles = const {},
}) {
  final profile = resolvedProfiles[userId];
  if (profile != null) {
    return profile.preferredName;
  }
  return l10n.activityParticipantFallbackName;
}

String? _resolveUserAvatarUrl(
  String userId, {
  Map<String, UserProfileVm> resolvedProfiles = const {},
  UserProfileVm? currentProfile,
}) {
  UserProfileVm? profile;
  if (currentProfile != null && currentProfile.userId == userId) {
    profile = currentProfile;
  } else {
    profile = resolvedProfiles[userId];
  }

  final avatarFileId = (profile?.avatarFileId ?? '').trim();
  return resolvePublicFileContentUrl(avatarFileId);
}

String _displayInitials(String value, {String fallback = 'F'}) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return fallback;
  }
  if (parts.length >= 2) {
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
  final normalized = parts.first.replaceAll(
    RegExp(r'[^A-Za-zА-Яа-яӘәҒғҚқҢңӨөҰұҮүҺһІі0-9]'),
    '',
  );
  if (normalized.length >= 2) {
    return normalized.substring(0, 2).toUpperCase();
  }
  if (normalized.isNotEmpty) {
    return normalized[0].toUpperCase();
  }
  return fallback;
}

Color _activityStatusColor(String status) {
  switch (status.toUpperCase()) {
    case 'PUBLISHED':
    case 'ENROLLMENT_OPEN':
      return _DetailsColors.success;
    case 'FULL':
      return const Color(0xFFF7B955);
    case 'DRAFT':
      return const Color(0xFF8C8582);
    case 'COMPLETED':
      return const Color(0xFF80B7FF);
    case 'CANCELLED':
      return const Color(0xFFFF6B6B);
    case 'ARCHIVED':
      return const Color(0xFFC9AF89);
    default:
      return const Color(0xFF8C8582);
  }
}

Color _statusPillColor(String status) {
  switch (status.toUpperCase()) {
    case 'INVITED':
      return const Color(0x2280B7FF);
    case 'APPROVED':
    case 'CONFIRMED':
    case 'CHECKED_IN':
      return _DetailsColors.success.withValues(alpha: 0.18);
    case 'WAITLISTED':
      return AppColors.accent.withValues(alpha: 0.18);
    case 'REQUESTED':
      return const Color(0x2280B7FF);
    default:
      return Colors.white.withValues(alpha: 0.08);
  }
}

Color _statusTextColor(String status) {
  switch (status.toUpperCase()) {
    case 'INVITED':
      return const Color(0xFF80B7FF);
    case 'APPROVED':
    case 'CONFIRMED':
    case 'CHECKED_IN':
      return _DetailsColors.success;
    case 'WAITLISTED':
      return AppColors.accent;
    case 'REQUESTED':
      return const Color(0xFF80B7FF);
    default:
      return _DetailsColors.text;
  }
}

List<Color> _seedGradient(String seed) {
  const palettes = <List<Color>>[
    [Color(0xFF2A7A6E), Color(0xFF7ABDA9)],
    [Color(0xFFC8CDB5), Color(0xFFF3EFE2)],
    [Color(0xFFA6B686), Color(0xFF6F8E55)],
    [Color(0xFF3A302C), Color(0xFFC9B09B)],
    [Color(0xFF6CB5B1), Color(0xFF5F9E98)],
    [Color(0xFF6E78A6), Color(0xFFA6ABD8)],
  ];

  final hash = seed.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
  return palettes[hash % palettes.length];
}

String _seedInitials(String seed) {
  final compact = seed.replaceAll('-', '');
  if (compact.length >= 2) {
    return compact.substring(0, 2).toUpperCase();
  }
  if (compact.isNotEmpty) {
    return compact[0].toUpperCase();
  }
  return 'F';
}

String? _resolveMeetingActionCopyValue(ActivityListItemVm activity) {
  final meetingUrl = (activity.meetingUrl ?? '').trim();
  if (meetingUrl.isNotEmpty) {
    return meetingUrl;
  }
  final meetingPoint = _resolveMeetingPoint(activity);
  if (meetingPoint != null) {
    return AppMapLinks.buildUrl(
      latitude: meetingPoint.latitude,
      longitude: meetingPoint.longitude,
      title: activity.title,
      subtitle: activity.addressText ?? activity.shortLocation,
    );
  }
  final mapUrl = (activity.mapUrl ?? '').trim();
  if (mapUrl.isNotEmpty) {
    return mapUrl;
  }
  final address = (activity.addressText ?? '').trim();
  if (address.isNotEmpty) {
    return address;
  }
  if (activity.shortLocation.isNotEmpty) {
    return activity.shortLocation;
  }
  return null;
}

MapTarget _activityMeetingMapTarget(
  ActivityListItemVm activity,
  LatLng meetingPoint,
) {
  final subtitle = (activity.addressText ?? '').trim().isNotEmpty
      ? activity.addressText!.trim()
      : activity.shortLocation;

  return MapTarget(
    title: activity.title,
    subtitle: subtitle,
    latitude: meetingPoint.latitude,
    longitude: meetingPoint.longitude,
    sourceUrl: AppMapLinks.buildUrl(
      latitude: meetingPoint.latitude,
      longitude: meetingPoint.longitude,
      title: activity.title,
      subtitle: subtitle,
    ),
  );
}

TravelChecklistRouteArgs _activityChecklistRouteArgs(
  ActivityListItemVm activity,
) {
  final startAt = activity.startAt.toUtc();
  final endAt = activity.endAt.toUtc().isAfter(startAt)
      ? activity.endAt.toUtc()
      : startAt.add(const Duration(hours: 2));
  final meetingPoint = _resolveMeetingPoint(activity);

  return TravelChecklistRouteArgs(
    tripId: _activityChecklistTripId(activity.id),
    destination: TripChecklistDestinationRequest(
      countryCode: (activity.countryCode ?? '').trim(),
      cityName: (activity.cityName ?? '').trim(),
      cityId: _trimmedOrNull(activity.cityId),
    ),
    startAt: startAt,
    endAt: endAt,
    transportModes: const ['flight'],
    activitySlugs: _activityChecklistSlugs(activity),
    routeStops: [
      if (meetingPoint != null)
        TravelChecklistRouteStop(
          latitude: meetingPoint.latitude,
          longitude: meetingPoint.longitude,
          name: activity.title,
          sourceId: activity.id,
        ),
    ],
  );
}

String _activityChecklistTripId(String activityId) {
  return 'activity:${activityId.trim()}';
}

List<String> _activityChecklistSlugs(ActivityListItemVm activity) {
  return TravelChecklistRouteArgs.normalizedTokens([
    activity.categorySlug,
    activity.subcategorySlug,
    activity.format,
    ...activity.tags,
  ]);
}

String? _trimmedOrNull(String? value) {
  final trimmed = (value ?? '').trim();
  return trimmed.isEmpty ? null : trimmed;
}
