import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/network/activity_api.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/error_dialog.dart';
import '../../core/ui/error_view.dart';
import '../../features/activities/activity_cover_url.dart';
import '../../features/activities/activity_formatters.dart';
import '../../features/activities/models/activity_category_vm.dart';
import '../../features/activities/models/activity_list_item_vm.dart';
import '../../features/activities/models/activity_participant_vm.dart';
import '../../features/profile/profile_completion_gate.dart';
import '../../features/profile/profile_guard_result.dart';
import '../../features/profile/data/profile_api.dart';
import '../../features/profile/models/user_profile_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import 'activity_payment_screen.dart';

class ActivityDetailsScreen extends StatefulWidget {
  const ActivityDetailsScreen({super.key, required this.activityId});

  final String activityId;

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

enum _FooterAction { join, leave, publish, cancel }

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  final ActivityApi _activityApi = ActivityApi();
  final ProfileApi _profileApi = ProfileApi();

  bool _participantsLoading = true;
  String? _participantsError;
  List<ActivityParticipantVm> _participants = const [];
  Map<String, UserProfileVm> _resolvedProfiles = const {};
  _FooterAction? _pendingAction;
  bool _isPaymentSuccessful = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshScreen();
    });
  }

  @override
  void dispose() {
    final provider = context.read<ActivityProvider>();
    provider.clearSelectedActivity();
    provider.resetActionState();
    super.dispose();
  }

  Future<void> _refreshScreen() async {
    final provider = context.read<ActivityProvider>();
    await Future.wait<void>([
      provider.loadActivityDetails(widget.activityId),
      provider.loadActivityCategories(),
      _loadParticipants(),
    ]);
    await _loadVisibleProfiles(provider.selectedActivity);
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

    final activity = context.read<ActivityProvider>().selectedActivity;
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

  Future<void> _reloadAfterAction({required bool includeJoined}) async {
    final provider = context.read<ActivityProvider>();
    final authProvider = context.read<AuthProvider>();
    final futures = <Future<void>>[
      provider.loadActivityDetails(widget.activityId),
      _loadParticipants(),
    ];

    if (authProvider.state == AuthState.authenticated) {
      futures.add(provider.loadMyActivities());
      if (includeJoined) {
        futures.add(provider.loadJoinedActivities());
      }
    }

    await Future.wait<void>(futures);
    await _loadVisibleProfiles(provider.selectedActivity);
    provider.resetActionState();
  }

  Future<String?> _showCancelActivitySheet(AppLocalizations l10n) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CancelActivitySheet(l10n: l10n),
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

  Future<void> _copyValue(String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showParticipantsSheet(
    List<ActivityParticipantVm> participants,
    AppLocalizations l10n,
  ) async {
    if (participants.isEmpty) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final locale = Localizations.localeOf(sheetContext).toString();
        final dateFormat = DateFormat.MMMd(locale).add_Hm();

        return SafeArea(
          top: false,
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
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.activityGoingTitle(participants.length),
                            style: const TextStyle(
                              color: _DetailsColors.text,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.03,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: _DetailsColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0x14FFFFFF)),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
                      itemCount: participants.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final participant = participants[index];
                        return Row(
                          children: [
                            _ParticipantAvatar(
                              seed: participant.userId,
                              radius: 24,
                              borderColor: _DetailsColors.sheet,
                            ),
                            const SizedBox(width: 14),
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
                                      fontSize: 15,
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
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _StatusPill(
                              label: _prettyToken(participant.status),
                              backgroundColor: _statusPillColor(
                                participant.status,
                              ),
                              textColor: _statusTextColor(participant.status),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<ActivityProvider>();
    final session = context.watch<SessionProvider>();
    final activity = provider.selectedActivity;
    final currentUserId = (session.profile?.userId ?? '').trim();

    if (provider.state == ActivitiesState.loading && activity == null) {
      return const Scaffold(
        backgroundColor: _DetailsColors.base,
        body: Stack(
          children: [
            Positioned.fill(child: _DetailsBackdrop()),
            Center(child: CircularProgressIndicator(color: AppColors.accent)),
          ],
        ),
      );
    }

    if (provider.state == ActivitiesState.error && activity == null) {
      return Scaffold(
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
      );
    }

    if (activity == null) {
      return Scaffold(
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
    final status = activity.status.toUpperCase();
    final isDraft = status == 'DRAFT';
    final showPublish = isOwner && isDraft;
    final canCancelActivity = _canCancelActivity(activity, isOwner: isOwner);
    final canShowAttendanceQr =
        isOwner &&
        !const {'CANCELLED', 'COMPLETED', 'ARCHIVED'}.contains(status);
    final categoryLabel = _resolveLocalizedCategoryLabel(
      activity.categorySlug,
      provider.categoryItems,
      Localizations.localeOf(context).languageCode,
    );
    final hostName = _resolveHostName(
      activity.hostUserId,
      session.profile,
      resolvedProfiles: _resolvedProfiles,
      l10n: l10n,
    );

    return Scaffold(
      backgroundColor: _DetailsColors.base,
      extendBody: true,
      bottomNavigationBar: _DetailsActionBar(
        activity: activity,
        l10n: l10n,
        isOwner: isOwner,
        isJoined: isJoined,
        isPaid: _isPaymentSuccessful,
        showPublish: showPublish,
        isBusy: provider.actionState == ActivityActionState.loading,
        pendingAction: _pendingAction,
        onJoin: _handleJoin,
        onPublish: _handlePublish,
        onEdit: () => _openEdit(activity),
        onPay: isJoined && !isOwner && !activity.isFree
            ? () => _openPayment(activity, hostName: hostName)
            : null,
        onOpenChat: isJoined
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
                final horizontalPadding = width < 360 ? 16.0 : 22.0;
                final heroHeight = width < 360
                    ? 332.0
                    : width > 430
                    ? 392.0
                    : 368.0;
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
                      12,
                      horizontalPadding,
                      158 + MediaQuery.paddingOf(context).bottom,
                    ),
                    children: [
                      _DetailsTopBar(
                        title: l10n.activityDetailsTitle,
                        status: formatActivityStatus(activity.status, l10n),
                        statusColor: _activityStatusColor(activity.status),
                        compact: compact,
                        onBack: () => context.pop(),
                        onShare: () => _copyValue(
                          '/activities/${activity.id}',
                          l10n.activityDetailsLinkCopied,
                        ),
                      ),
                      SizedBox(height: compact ? 14 : 18),
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
                      SizedBox(height: compact ? 18 : 20),
                      _HeadingSection(
                        title: activity.title,
                        description: activity.description,
                        compact: compact,
                      ),
                      const SizedBox(height: 24),
                      _HostCard(
                        hostName: hostName,
                        subtitle: _resolveHostSubtitle(
                          activity: activity,
                          l10n: l10n,
                        ),
                        buttonLabel: l10n.profileTitle,
                        onPressed: () {
                          if (isOwner) {
                            context.push('/profile');
                            return;
                          }
                          final hostUserId = activity.hostUserId.trim();
                          if (hostUserId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.profileNotAvailable)),
                            );
                            return;
                          }
                          context.push(
                            '/users/$hostUserId/profile',
                            extra: _resolvedProfiles[hostUserId],
                          );
                        },
                      ),
                      const SizedBox(height: 26),
                      _StatsGrid(
                        activity: activity,
                        l10n: l10n,
                        compact: compact,
                      ),
                      const SizedBox(height: 26),
                      _ParticipantsSection(
                        l10n: l10n,
                        participants: activeParticipants,
                        compact: compact,
                        isLoading: _participantsLoading,
                        loadFailed: _participantsError != null,
                        onViewAll: activeParticipants.isNotEmpty
                            ? () => _showParticipantsSheet(
                                activeParticipants,
                                l10n,
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
                        canLeaveActivity: isJoined && !isOwner,
                        canCancelActivity: canCancelActivity,
                        isLeaving:
                            provider.actionState ==
                                ActivityActionState.loading &&
                            _pendingAction == _FooterAction.leave,
                        isCancelling:
                            provider.actionState ==
                                ActivityActionState.loading &&
                            _pendingAction == _FooterAction.cancel,
                        onLeaveTap: _handleLeave,
                        onCancelTap: _handleCancel,
                        onShowAttendanceQrTap: () {
                          context.push(
                            '/activities/${activity.id}/attendance-qr',
                          );
                        },
                        onActionTap: () {
                          final copyValue = _resolveMeetingActionCopyValue(
                            activity,
                          );
                          if (copyValue == null || copyValue.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.notSpecified)),
                            );
                            return;
                          }
                          _copyValue(copyValue, l10n.activityDetailsLinkCopied);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
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
            height: 260,
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
            height: 220,
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

    return GestureDetector(
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
                                color: AppColors.accent.withValues(alpha: 0.42),
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
                              width: compact ? 76 : 84,
                              height: compact ? 76 : 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accent.withValues(alpha: 0.14),
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
                                size: 34,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              widget.l10n.activityPrivateJoinTitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _DetailsColors.text,
                                fontSize: compact ? 28 : 32,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1.3,
                              ),
                            ),
                            const SizedBox(height: 18),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: Text(
                                widget.l10n.activityPrivateJoinDescription,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFFB7B2BD),
                                  fontSize: compact ? 16 : 18,
                                  height: 1.45,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            SizedBox(height: compact ? 36 : 56),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                widget.l10n.activityPrivateJoinPasswordLabel,
                                style: const TextStyle(
                                  color: _DetailsColors.text,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
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
                                  fontSize: compact ? 18 : 20,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                                decoration: InputDecoration(
                                  hintText: widget
                                      .l10n
                                      .activityPrivateJoinPasswordPlaceholder,
                                  hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.72),
                                    fontSize: compact ? 17 : 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: compact ? 18 : 20,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: _isSubmitting
                                        ? null
                                        : () => setState(
                                            () => _obscureText = !_obscureText,
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
                                    height: compact ? 64 : 70,
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
                                                fontSize: compact ? 18 : 20,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: -0.4,
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
    );
  }
}

class _CancelActivitySheet extends StatefulWidget {
  const _CancelActivitySheet({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_CancelActivitySheet> createState() => _CancelActivitySheetState();
}

class _CancelActivitySheetState extends State<_CancelActivitySheet> {
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
      setState(() => _errorText = widget.l10n.activityCancelReasonRequired);
      _reasonFocusNode.requestFocus();
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final compact = mediaQuery.size.width < 390;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
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
          child: Align(
            alignment: Alignment.bottomCenter,
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
                    compact ? 18 : 22,
                    16,
                    compact ? 18 : 22,
                    compact ? 20 : 24,
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
                          width: compact ? 66 : 72,
                          height: compact ? 66 : 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent.withValues(alpha: 0.12),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.26),
                            ),
                          ),
                          child: const Icon(
                            Icons.event_busy_rounded,
                            color: AppColors.accent,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          widget.l10n.activityCancelConfirmTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _DetailsColors.text,
                            fontSize: compact ? 25 : 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: Text(
                            widget.l10n.activityCancelConfirmDescription,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _DetailsColors.muted,
                              fontSize: compact ? 15 : 16,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        widget.l10n.activityCancelReasonLabel,
                        style: const TextStyle(
                          color: _DetailsColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
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
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                widget.l10n.activityCancelReasonPlaceholder,
                            hintStyle: TextStyle(
                              color: _DetailsColors.muted.withValues(
                                alpha: 0.72,
                              ),
                              fontSize: 15,
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
                            label: widget.l10n.activityCancelKeepButton,
                            icon: Icons.arrow_back_rounded,
                            isPrimary: false,
                            onTap: () => Navigator.of(context).pop(),
                          );
                          final confirmButton = _SheetActionButton(
                            label: widget.l10n.activityCancelConfirmButton,
                            icon: Icons.event_busy_rounded,
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
    final backgroundColor = isPrimary
        ? AppColors.accent
        : Colors.white.withValues(alpha: 0.06);
    final foregroundColor = isPrimary ? Colors.white : _DetailsColors.text;
    final borderColor = isPrimary
        ? AppColors.accent
        : Colors.white.withValues(alpha: 0.1);

    return SizedBox(
      height: 58,
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
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
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
    return Row(
      children: [
        _CircleIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: onBack,
        ),
        SizedBox(width: compact ? 10 : 12),
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
                  fontSize: compact ? 16 : 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.03,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
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
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _DetailsColors.subtle,
                        fontSize: compact ? 10 : 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: compact ? 10 : 12),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Icon(icon, color: _DetailsColors.text, size: 20),
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
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: -36,
          right: -18,
          child: Container(
            width: 188,
            height: 188,
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
            width: 132,
            height: 132,
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
                    width: 112,
                    height: 112,
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
          height: 118,
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
          height: 150,
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
            fontSize: compact ? 28 : 31,
            fontWeight: FontWeight.w800,
            height: 1.0,
            letterSpacing: -1.4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: TextStyle(
            color: _DetailsColors.muted,
            fontSize: compact ? 15 : 17,
            height: 1.55,
            letterSpacing: -0.18,
          ),
        ),
      ],
    );
  }
}

class _HostCard extends StatelessWidget {
  const _HostCard({
    required this.hostName,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String hostName;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
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
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Colors.white,
                    size: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hostName,
                  style: const TextStyle(
                    color: _DetailsColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                if (subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(999),
              child: Ink(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Center(
                  child: Text(
                    buttonLabel,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.22,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
    final dateFormat = DateFormat.MMMd(locale).add_Hm();
    final startText = dateFormat.format(activity.startAt.toLocal());
    final endText = dateFormat.format(activity.endAt.toLocal());
    final pricingText = activity.isFree
        ? l10n.freeLabel
        : '${activity.priceLabel} ${l10n.activityPerPerson}';
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
        icon: Icons.calendar_today_outlined,
        label: l10n.createStartAtLabel,
        value: startText,
      ),
      _DetailsStatItem(
        icon: Icons.event_available_rounded,
        label: l10n.createEndAtLabel,
        value: endText,
      ),
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

    final horizontalSpacing = compact ? 14.0 : 16.0;
    final verticalSpacing = compact ? 10.0 : 12.0;
    final cardAspectRatio = compact ? 1.0 : 1.06;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - horizontalSpacing) / 2;
        final itemHeight = itemWidth / cardAspectRatio;

        Widget buildRow(int startIndex) {
          return SizedBox(
            height: itemHeight,
            child: Row(
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
              SizedBox(height: verticalSpacing),
              buildRow(4),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
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
        children: [
          Icon(item.icon, color: AppColors.accent, size: 24),
          const Spacer(),
          Text(
            item.label.toUpperCase(),
            style: const TextStyle(
              color: _DetailsColors.subtle,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _DetailsColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.32,
              letterSpacing: -0.25,
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
    required this.isLeaving,
    required this.isCancelling,
    required this.onLeaveTap,
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
  final bool isLeaving;
  final bool isCancelling;
  final VoidCallback onLeaveTap;
  final VoidCallback onCancelTap;
  final VoidCallback onShowAttendanceQrTap;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
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
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.activityMeetingPoint,
                style: const TextStyle(
                  color: _DetailsColors.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.25,
                ),
              ),
            ),
            TextButton(
              onPressed: onActionTap,
              child: Text(
                actionLabel,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          height: 248,
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
                  _MeetingMapCard(
                    point: meetingPoint,
                    showProtectedNotice: showProtectedNotice,
                  )
                else
                  _MeetingLocationFallbackCard(
                    label: locationLine.isNotEmpty
                        ? locationLine
                        : l10n.notSpecified,
                  ),
                if (showProtectedNotice)
                  Container(
                    color: Colors.black.withValues(alpha: 0.26),
                    padding: const EdgeInsets.all(20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_outline_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 16),
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
                  ),
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
              child: Text(
                showProtectedNotice
                    ? l10n.activitySensitiveDetailsHint
                    : (locationLine.isNotEmpty
                          ? locationLine
                          : l10n.notSpecified),
                style: const TextStyle(
                  color: _DetailsColors.muted,
                  fontSize: 15,
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

class _MeetingMapCard extends StatelessWidget {
  const _MeetingMapCard({
    required this.point,
    required this.showProtectedNotice,
  });

  final LatLng point;
  final bool showProtectedNotice;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: point,
            initialZoom: 15.4,
            backgroundColor: const Color(0xFFB3A28D),
            interactionOptions: InteractionOptions(
              flags: showProtectedNotice
                  ? InteractiveFlag.none
                  : InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'dev.dkhvan.flyfy.superapp',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 66,
                  height: 66,
                  alignment: Alignment.topCenter,
                  child: const _MeetingPointMarker(),
                ),
              ],
            ),
          ],
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0x1F25160B),
                    Colors.transparent,
                    const Color(0x33140B04),
                  ],
                  stops: const [0, 0.48, 1],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MeetingPointMarker extends StatelessWidget {
  const _MeetingPointMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.26),
                blurRadius: 16,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        ),
        Container(
          width: 2,
          height: 18,
          color: Colors.white.withValues(alpha: 0.88),
        ),
      ],
    );
  }
}

class _MeetingLocationFallbackCard extends StatelessWidget {
  const _MeetingLocationFallbackCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
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
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.34),
                  ),
                ),
                child: const Icon(
                  Icons.place_rounded,
                  color: AppColors.accent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                label,
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                  size: 17,
                  color: AppColors.accent.withValues(alpha: 0.9),
                ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.accent.withValues(alpha: 0.94),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.18,
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
                      color: AppColors.accent,
                    ),
                  )
                else
                  Icon(
                    Icons.event_busy_rounded,
                    size: 18,
                    color: AppColors.accent.withValues(alpha: 0.94),
                  ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.accent.withValues(alpha: 0.96),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.18,
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.qr_code_2_rounded,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.18,
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

class _ParticipantsSection extends StatelessWidget {
  const _ParticipantsSection({
    required this.l10n,
    required this.participants,
    required this.compact,
    required this.isLoading,
    required this.loadFailed,
    this.onViewAll,
  });

  final AppLocalizations l10n;
  final List<ActivityParticipantVm> participants;
  final bool compact;
  final bool isLoading;
  final bool loadFailed;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.activityGoingTitle(participants.length),
                style: const TextStyle(
                  color: _DetailsColors.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.25,
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
        ),
        const SizedBox(height: 12),
        if (participants.isNotEmpty)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (var i = 0; i < math.min(participants.length, 6); i++)
                        Positioned(
                          left: i * 30,
                          child: _ParticipantAvatar(
                            seed: participants[i].userId,
                            radius: 21,
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
                    fontSize: 15,
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
    required this.radius,
    required this.borderColor,
  });

  final String seed;
  final double radius;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final colors = _seedGradient(seed);
    final initials = _seedInitials(seed);

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 3),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.62,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
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
    final priceLabel = activity.isFree ? l10n.freeLabel : activity.priceLabel;
    final shouldShowPaymentAction =
        isJoined && !isOwner && !activity.isFree && !isPaid && onPay != null;
    final secondaryAction = showPublish
        ? _FooterButtonSpec(
            label: l10n.activityPublishButton,
            icon: Icons.publish_rounded,
            onTap: onPublish,
            style: _FooterButtonStyle.secondary,
            action: _FooterAction.publish,
          )
        : shouldShowPaymentAction
        ? _FooterButtonSpec(
            label: l10n.activityDetailsChatButton,
            icon: Icons.forum_rounded,
            onTap: onOpenChat ?? () {},
            style: _FooterButtonStyle.secondary,
            action: null,
          )
        : null;
    final primaryAction = isOwner
        ? _FooterButtonSpec(
            label: l10n.editActivityButton,
            icon: Icons.edit_outlined,
            onTap: onEdit,
            style: _FooterButtonStyle.primary,
            action: null,
          )
        : isJoined
        ? shouldShowPaymentAction
              ? _FooterButtonSpec(
                  label: l10n.activityPaymentPayButton,
                  icon: Icons.payments_rounded,
                  onTap: onPay ?? () {},
                  style: _FooterButtonStyle.primary,
                  action: null,
                )
              : _FooterButtonSpec(
                  label: l10n.activityDetailsChatButton,
                  icon: Icons.forum_rounded,
                  onTap: onOpenChat ?? () {},
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
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
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
                secondaryAction != null && constraints.maxWidth < 360;
            if (stackVertically) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _FooterPriceBlock(
                    label: priceBlockLabel,
                    value: priceBlockValue,
                    labelColor: priceBlockLabelColor,
                    valueColor: priceBlockValueColor,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _FooterButton(
                          spec: secondaryAction,
                          isBusy:
                              isBusy && pendingAction == secondaryAction.action,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FooterButton(
                          spec: primaryAction,
                          isBusy:
                              isBusy && pendingAction == primaryAction.action,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                _FooterPriceBlock(
                  label: priceBlockLabel,
                  value: priceBlockValue,
                  labelColor: priceBlockLabelColor,
                  valueColor: priceBlockValueColor,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: secondaryAction == null
                      ? _FooterButton(
                          spec: primaryAction,
                          isBusy:
                              isBusy && pendingAction == primaryAction.action,
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _FooterButton(
                                spec: secondaryAction,
                                isBusy:
                                    isBusy &&
                                    pendingAction == secondaryAction.action,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _FooterButton(
                                spec: primaryAction,
                                isBusy:
                                    isBusy &&
                                    pendingAction == primaryAction.action,
                              ),
                            ),
                          ],
                        ),
                ),
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
      constraints: const BoxConstraints(minWidth: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: labelColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: valueColor,
                fontSize: 24,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
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
  final VoidCallback onTap;
  final _FooterButtonStyle style;
  final _FooterAction? action;
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({required this.spec, required this.isBusy});

  final _FooterButtonSpec spec;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final isPrimary = spec.style == _FooterButtonStyle.primary;
    final backgroundColor = isPrimary
        ? AppColors.accent
        : Colors.white.withValues(alpha: 0.08);
    final borderColor = isPrimary
        ? AppColors.accent
        : Colors.white.withValues(alpha: 0.1);
    final foreground = isPrimary ? Colors.white : _DetailsColors.text;

    return SizedBox(
      height: 62,
      child: ElevatedButton(
        onPressed: isBusy ? null : spec.onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foreground,
          disabledBackgroundColor: backgroundColor,
          disabledForegroundColor: foreground,
          elevation: isPrimary ? 0 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
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
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(spec.icon, size: 20),
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
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
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
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
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

String _prettyCategory(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return 'Activity';
  }

  return normalized
      .split(RegExp(r'[_\-\s]+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}

String _resolveLocalizedCategoryLabel(
  String rawSlug,
  List<ActivityCategoryVm> categories,
  String languageCode,
) {
  final normalizedSlug = rawSlug.trim().toLowerCase();
  if (normalizedSlug.isNotEmpty) {
    for (final category in categories) {
      if (category.slug == normalizedSlug) {
        return category.localizedName(languageCode);
      }
    }
  }
  return _prettyCategory(rawSlug);
}

String _prettyToken(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return value;
  }
  return normalized
      .split('_')
      .where((part) => part.isNotEmpty)
      .map(
        (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
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

  final parsedUri = Uri.tryParse(mapUrl);
  final mlat = double.tryParse(parsedUri?.queryParameters['mlat'] ?? '');
  final mlon = double.tryParse(parsedUri?.queryParameters['mlon'] ?? '');
  if (_isValidMeetingPoint(mlat, mlon)) {
    return LatLng(mlat!, mlon!);
  }

  final fragment = parsedUri?.fragment ?? '';
  final fragmentMatch = RegExp(
    r'map=\d+(?:\.\d+)?/(-?\d+(?:\.\d+)?)/(-?\d+(?:\.\d+)?)',
  ).firstMatch(fragment);
  if (fragmentMatch != null) {
    final fragmentLat = double.tryParse(fragmentMatch.group(1) ?? '');
    final fragmentLon = double.tryParse(fragmentMatch.group(2) ?? '');
    if (_isValidMeetingPoint(fragmentLat, fragmentLon)) {
      return LatLng(fragmentLat!, fragmentLon!);
    }
  }

  return null;
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

Color _activityStatusColor(String status) {
  switch (status.toUpperCase()) {
    case 'PUBLISHED':
    case 'ENROLLMENT_OPEN':
      return _DetailsColors.success;
    case 'FULL':
      return const Color(0xFFF7B955);
    case 'REVIEW_REQUIRED':
      return const Color(0xFFF6A63D);
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
