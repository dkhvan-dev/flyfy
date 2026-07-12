import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/network/attendance_api.dart';
import '../../features/activities/models/activity_list_item_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart';

class ActivityAttendanceQrScreen extends StatefulWidget {
  const ActivityAttendanceQrScreen({super.key, required this.activityId});

  final String activityId;

  @override
  State<ActivityAttendanceQrScreen> createState() =>
      _ActivityAttendanceQrScreenState();
}

class _ActivityAttendanceQrScreenState
    extends State<ActivityAttendanceQrScreen> {
  final AttendanceApi _attendanceApi = AttendanceApi();

  Timer? _refreshTimer;
  Timer? _countdownTimer;
  bool _isLoading = true;
  String? _error;
  String? _token;
  DateTime? _refreshAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQr();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadQr() async {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final qr = await _attendanceApi.getActivityAttendanceQr(
        widget.activityId,
      );
      if (!mounted) return;
      setState(() {
        _token = qr.token;
        _refreshAt = qr.refreshAt;
        _isLoading = false;
      });
      _scheduleRefresh(qr.refreshAt);
      _restartCountdownTicker();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'failed';
        _refreshAt = null;
        _isLoading = false;
      });
    }
  }

  void _scheduleRefresh(DateTime refreshAt) {
    _refreshTimer?.cancel();
    final delay = refreshAt.difference(DateTime.now().toUtc());
    final effectiveDelay = delay.isNegative
        ? const Duration(seconds: 1)
        : delay;
    _refreshTimer = Timer(effectiveDelay, _loadQr);
  }

  void _restartCountdownTicker() {
    _countdownTimer?.cancel();
    if (_refreshAt == null) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  String _countdownLabel(AppLocalizations l10n) {
    final refreshAt = _refreshAt;
    if (refreshAt == null) return '';
    final remaining = refreshAt.difference(DateTime.now().toUtc());
    if (remaining.isNegative) {
      return l10n.activityAttendanceQrRefreshing;
    }
    return l10n.activityAttendanceQrExpiresIn(
      remaining.inSeconds.clamp(0, 999).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activity = context.select<ActivityProvider, ActivityListItemVm?>(
      (provider) => provider.selectedActivity?.id == widget.activityId
          ? provider.selectedActivity
          : null,
    );
    final colors = AppDesignSystem.colorsFor(context);
    final compact = MediaQuery.sizeOf(context).width < 360;

    return Theme(
      data: AppDesignSystem.themeFor(context),
      child: Scaffold(
        backgroundColor: colors.background,
        body: DecoratedBox(
          decoration: AppBoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors.screenGradientColors,
            ),
          ),
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadQr,
              color: colors.primary,
              backgroundColor: colors.surface,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const AppEdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: colors.textPrimary,
                      ),
                      Expanded(
                        child: Text(
                          l10n.activityAttendanceQrTitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyle(
                            color: colors.textPrimary,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    activity?.title ?? l10n.activityAttendanceQrFallbackTitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle(
                      color: colors.textPrimary,
                      fontSize: compact ? 24 : 28,
                      fontWeight: FontWeight.w900,
                      height: 1.06,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.activityAttendanceQrSubtitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const AppEdgeInsets.all(22),
                    decoration: _attendanceQrCardDecoration(
                      context,
                      colors,
                      highlighted: true,
                    ),
                    child: _buildQrBody(context, l10n),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const AppEdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: _attendanceQrCardDecoration(context, colors),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: AppBoxDecoration(
                            color: colors.primarySoft,
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.borderPrimary),
                          ),
                          child: Icon(
                            Icons.timelapse_rounded,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _countdownLabel(l10n),
                                style: AppTextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.activityAttendanceQrRefreshHint,
                                style: AppTextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQrBody(BuildContext context, AppLocalizations l10n) {
    final colors = AppDesignSystem.colorsFor(context);

    if (_isLoading) {
      return SizedBox(
        height: _qrBodyHeight(context),
        child: Center(child: CircularProgressIndicator(color: colors.primary)),
      );
    }

    if (_error != null || (_token ?? '').isEmpty) {
      return SizedBox(
        height: _qrBodyHeight(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_2_rounded, color: colors.danger, size: 42),
            const SizedBox(height: 14),
            Text(
              l10n.activityAttendanceQrLoadFailed,
              textAlign: TextAlign.center,
              style: AppTextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadQr,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
              ),
              child: Text(l10n.retryButton),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: AppBoxDecoration(
              color: colors.white,
              borderRadius: AppBorderRadius.circular(28),
              border: Border.all(color: colors.borderSoft),
            ),
            padding: const AppEdgeInsets.all(18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final qrSize = constraints.biggest.shortestSide;
                return Center(
                  child: QrImageView(
                    data: _token!,
                    backgroundColor: colors.white,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: colors.black,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      color: colors.black,
                      dataModuleShape: QrDataModuleShape.square,
                    ),
                    size: qrSize,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.activityAttendanceQrHelper,
          textAlign: TextAlign.center,
          style: AppTextStyle(
            color: colors.textSecondary,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  double _qrBodyHeight(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return (screenHeight * 0.42).clamp(260.0, 360.0);
  }
}

BoxDecoration _attendanceQrCardDecoration(
  BuildContext context,
  AppColors colors, {
  bool highlighted = false,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return AppBoxDecoration(
    color: highlighted ? colors.surface : colors.surfaceRaised,
    borderRadius: AppBorderRadius.circular(highlighted ? 32 : 22),
    border: Border.all(
      color: highlighted ? colors.borderPrimary : colors.border,
    ),
    boxShadow: isDark && highlighted
        ? [
            BoxShadow(
              color: colors.black.withValues(alpha: 0.24),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ]
        : const [],
  );
}
