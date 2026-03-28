import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/network/attendance_api.dart';
import '../../core/ui/app_colors.dart';
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
  bool _isLoading = true;
  String? _error;
  String? _token;
  DateTime? _expiresAt;

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
    super.dispose();
  }

  Future<void> _loadQr() async {
    _refreshTimer?.cancel();
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final qr =
          await _attendanceApi.getActivityAttendanceQr(widget.activityId);
      if (!mounted) return;
      setState(() {
        _token = qr.token;
        _expiresAt = qr.expiresAt;
        _isLoading = false;
      });
      _scheduleRefresh(qr.refreshAt);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'failed';
        _isLoading = false;
      });
    }
  }

  void _scheduleRefresh(DateTime refreshAt) {
    _refreshTimer?.cancel();
    final delay = refreshAt.difference(DateTime.now().toUtc());
    final effectiveDelay =
        delay.isNegative ? const Duration(seconds: 1) : delay;
    _refreshTimer = Timer(effectiveDelay, _loadQr);
  }

  String _countdownLabel(AppLocalizations l10n) {
    final expiresAt = _expiresAt;
    if (expiresAt == null) return '';
    final remaining = expiresAt.difference(DateTime.now().toUtc());
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

    return Scaffold(
      backgroundColor: const Color(0xFF130A03),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadQr,
          color: AppColors.accent,
          backgroundColor: const Color(0xFF221209),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: Colors.white,
                  ),
                  Expanded(
                    child: Text(
                      l10n.activityAttendanceQrTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.06,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.activityAttendanceQrSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF211108),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.26),
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: _buildQrBody(context, l10n),
              ),
              const SizedBox(height: 18),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF26160C),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.timelapse_rounded,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _countdownLabel(l10n),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.activityAttendanceQrRefreshHint,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.66),
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
    );
  }

  Widget _buildQrBody(BuildContext context, AppLocalizations l10n) {
    if (_isLoading) {
      return const SizedBox(
        height: 360,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    if (_error != null || (_token ?? '').isEmpty) {
      return SizedBox(
        height: 360,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_2_rounded,
              color: AppColors.accent,
              size: 42,
            ),
            const SizedBox(height: 14),
            Text(
              l10n.activityAttendanceQrLoadFailed,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadQr,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
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
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.all(18),
            child: Center(
              child: QrImageView(
                data: _token!,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  color: Colors.black,
                  dataModuleShape: QrDataModuleShape.square,
                ),
                size: 280,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.activityAttendanceQrHelper,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
