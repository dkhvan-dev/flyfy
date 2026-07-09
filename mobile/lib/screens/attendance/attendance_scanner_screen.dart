import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../features/attendance/attendance_qr_token.dart';
import '../../features/attendance/attendance_queue_repository.dart';
import '../../features/attendance/attendance_sync_manager.dart';
import '../../features/attendance/models/attendance_queue_item.dart';
import '../../features/attendance/models/attendance_sync_result_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/excursion_provider.dart';
import '../../providers/session_provider.dart';

class AttendanceScannerScreen extends StatefulWidget {
  const AttendanceScannerScreen({super.key});

  @override
  State<AttendanceScannerScreen> createState() =>
      _AttendanceScannerScreenState();
}

enum _ScannerFeedbackTone { neutral, success, warning, error }

class _AttendanceScannerScreenState extends State<AttendanceScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final AttendanceQueueRepository _queueRepository =
      AttendanceQueueRepository();

  bool _isHandlingScan = false;
  bool _isManualSyncing = false;
  int _pendingCount = 0;
  String? _feedbackMessage;
  _ScannerFeedbackTone _feedbackTone = _ScannerFeedbackTone.neutral;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshPendingState();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refreshPendingState() async {
    final participantUserId =
        context.read<SessionProvider>().profile?.userId ?? '';
    if (participantUserId.isEmpty) {
      return;
    }

    final outcome = await AttendanceSyncManager.instance.syncPendingForUser(
      participantUserId,
    );
    if (!mounted) return;
    setState(() {
      _pendingCount = outcome.remainingPendingCount;
    });
  }

  Future<void> _handleManualSync() async {
    if (_isManualSyncing) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final participantUserId =
        context.read<SessionProvider>().profile?.userId ?? '';
    if (participantUserId.isEmpty) {
      _setFeedback(
        l10n.qrScannerSessionUnavailable,
        _ScannerFeedbackTone.error,
      );
      return;
    }

    final pendingBefore = (await _queueRepository.readAll())
        .where((item) => item.participantUserId == participantUserId)
        .length;
    if (pendingBefore == 0) {
      if (!mounted) return;
      setState(() {
        _pendingCount = 0;
        _feedbackMessage = null;
        _feedbackTone = _ScannerFeedbackTone.neutral;
      });
      return;
    }

    if (mounted) {
      setState(() => _isManualSyncing = true);
    }

    try {
      final outcome = await AttendanceSyncManager.instance.syncPendingForUser(
        participantUserId,
        force: true,
      );
      if (!mounted) return;

      setState(() => _pendingCount = outcome.remainingPendingCount);
      final feedbackResult = _resolveManualSyncFeedback(outcome, l10n);
      _setFeedback(feedbackResult.$1, feedbackResult.$2);
    } finally {
      if (mounted) {
        setState(() => _isManualSyncing = false);
      }
    }
  }

  (String, _ScannerFeedbackTone) _resolveManualSyncFeedback(
    AttendanceSyncOutcome outcome,
    AppLocalizations l10n,
  ) {
    final results = outcome.resultsByScanId.values.toList(growable: false);
    if (results.isEmpty) {
      return ('', _ScannerFeedbackTone.neutral);
    }

    final rejected = results.where((item) => item.isRejected).toList();
    if (rejected.isNotEmpty) {
      return (
        _messageForResult(rejected.first, l10n),
        _ScannerFeedbackTone.error,
      );
    }

    final retryable = results.where((item) => item.isRetryable).toList();
    if (retryable.isNotEmpty) {
      return (l10n.qrScannerQueuedOffline, _ScannerFeedbackTone.warning);
    }

    final synced = results.where((item) => item.isSynced).toList();
    if (synced.isNotEmpty) {
      return (l10n.qrScannerSuccess, _ScannerFeedbackTone.success);
    }

    final alreadySynced = results
        .where((item) => item.isAlreadySynced)
        .toList();
    if (alreadySynced.isNotEmpty) {
      return (l10n.qrScannerAlreadyCheckedIn, _ScannerFeedbackTone.success);
    }

    return (l10n.qrScannerReady, _ScannerFeedbackTone.neutral);
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_isHandlingScan) return;

    final rawValue = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim() ?? '')
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (rawValue.isEmpty) {
      return;
    }

    final payload = AttendanceQrTokenPayload.tryParse(rawValue);
    final l10n = AppLocalizations.of(context)!;
    if (payload == null) {
      _setFeedback(l10n.qrScannerInvalidCode, _ScannerFeedbackTone.error);
      return;
    }

    final participantUserId =
        context.read<SessionProvider>().profile?.userId ?? '';
    if (participantUserId.isEmpty) {
      _setFeedback(
        l10n.qrScannerSessionUnavailable,
        _ScannerFeedbackTone.error,
      );
      return;
    }

    _isHandlingScan = true;
    try {
      final existing = await _queueRepository.findPending(
        participantUserId: participantUserId,
        type: payload.type,
        subjectId: payload.subjectId,
      );
      if (existing != null) {
        final outcome = await AttendanceSyncManager.instance.syncPendingForUser(
          participantUserId,
        );
        if (!mounted) return;
        setState(() => _pendingCount = outcome.remainingPendingCount);
        await _refreshExcursionAttendanceState(
          type: payload.type,
          results: outcome.resultsByScanId.values,
        );
        _setFeedback(l10n.qrScannerAlreadyQueued, _ScannerFeedbackTone.warning);
        return;
      }

      final installationId = await _queueRepository.getOrCreateInstallationId();
      final scanId = _queueRepository.scanIdForProof(
        participantUserId: participantUserId,
        type: payload.type,
        subjectId: payload.subjectId,
        qrJti: payload.qrJti,
      );
      final item = AttendanceQueueItem(
        scanId: scanId,
        participantUserId: participantUserId,
        type: payload.type,
        activityId: payload.subjectId,
        qrJti: payload.qrJti,
        qrToken: rawValue,
        installationId: installationId,
        scannedAtDevice: DateTime.now().toUtc(),
        createdAt: DateTime.now().toUtc(),
      );
      await _queueRepository.enqueue(item);

      final outcome = await AttendanceSyncManager.instance.syncPendingForUser(
        participantUserId,
      );
      if (!mounted) return;

      setState(() => _pendingCount = outcome.remainingPendingCount);
      final result = outcome.resultFor(scanId);
      if (result == null) {
        _setFeedback(l10n.qrScannerQueuedOffline, _ScannerFeedbackTone.warning);
        return;
      }

      _setFeedback(
        _messageForResult(result, l10n),
        result.isSynced || result.isAlreadySynced
            ? _ScannerFeedbackTone.success
            : result.isRejected
            ? _ScannerFeedbackTone.error
            : _ScannerFeedbackTone.warning,
      );
      await _refreshExcursionAttendanceState(
        type: payload.type,
        results: [result],
      );
    } finally {
      _isHandlingScan = false;
    }
  }

  Future<void> _refreshExcursionAttendanceState({
    required String type,
    required Iterable<AttendanceSyncResultVm> results,
  }) async {
    if (!mounted || type != AttendanceQueueItem.typeExcursion) {
      return;
    }
    final hasSuccessfulResult = results.any(
      (result) => result.isSynced || result.isAlreadySynced,
    );
    if (!hasSuccessfulResult) {
      return;
    }

    final excursionProvider = context.read<ExcursionProvider>();
    await excursionProvider.refreshMyExcursionBookings();
    final hasGuideDashboardData =
        excursionProvider.myGuideProfile != null ||
        excursionProvider.myGuideExcursions.isNotEmpty ||
        excursionProvider.myGuideExcursionBookings.isNotEmpty;
    if (hasGuideDashboardData) {
      await excursionProvider.refreshGuideDashboardData();
    }
  }

  String _messageForResult(
    AttendanceSyncResultVm result,
    AppLocalizations l10n,
  ) {
    if (result.isSynced) {
      return l10n.qrScannerSuccess;
    }
    if (result.isAlreadySynced) {
      return l10n.qrScannerAlreadyCheckedIn;
    }

    switch (result.code) {
      case 'not_registered':
        return l10n.qrScannerNotRegistered;
      case 'participant_not_eligible':
        return l10n.qrScannerNotEligible;
      case 'qr_expired':
        return l10n.qrScannerQrExpired;
      case 'host_scan_not_allowed':
        return l10n.qrScannerHostNotAllowed;
      case 'activity_unavailable':
      case 'slot_unavailable':
        return l10n.qrScannerActivityUnavailable;
      case 'auth_required':
        return l10n.qrScannerSessionUnavailable;
      case 'invalid_qr':
      case 'unsupported_qr':
        return l10n.qrScannerInvalidCode;
      case 'offline':
      case 'server_error':
      default:
        return l10n.qrScannerQueuedOffline;
    }
  }

  void _setFeedback(String message, _ScannerFeedbackTone tone) {
    if (!mounted) return;
    if (message.trim().isEmpty) {
      setState(() {
        _feedbackMessage = null;
        _feedbackTone = _ScannerFeedbackTone.neutral;
      });
      return;
    }
    setState(() {
      _feedbackMessage = message;
      _feedbackTone = tone;
    });
  }

  Color _feedbackColor() {
    switch (_feedbackTone) {
      case _ScannerFeedbackTone.success:
        return AppPalette.success;
      case _ScannerFeedbackTone.warning:
        return context.appColors.primary;
      case _ScannerFeedbackTone.error:
        return AppPalette.danger;
      case _ScannerFeedbackTone.neutral:
        return context.appColors.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final safePadding = MediaQuery.viewPaddingOf(context);

    return Theme(
      data: AppDesignSystem.themeFor(context),
      child: Scaffold(
        backgroundColor: colors.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: MobileScanner(
                controller: _controller,
                onDetect: _handleDetect,
                errorBuilder: (context, error) {
                  return DecoratedBox(
                    decoration: AppBoxDecoration(
                      color: colors.surfaceHigh.withValues(alpha: 0.96),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const AppEdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          l10n.qrScannerCameraUnavailable,
                          textAlign: TextAlign.center,
                          style: AppTextStyle(
                            color: colors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                overlayBuilder: (context, constraints) {
                  return SizedBox.expand(
                    key: const ValueKey(
                      'qr-scanner-transparent-fullscreen-overlay',
                    ),
                  );
                },
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: AppBoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colors.scrim.withValues(alpha: 0.48),
                      colors.transparent,
                      colors.scrim.withValues(alpha: 0.68),
                    ],
                    stops: const [0, 0.42, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              top: safePadding.top + 10,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: colors.primary,
                      style: AppButtonStyles.icon(colors).copyWith(
                        backgroundColor: WidgetStateProperty.all(
                          colors.surface.withValues(alpha: 0.86),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const AppEdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: AppBoxDecoration(
                      color: colors.surface.withValues(alpha: 0.78),
                      borderRadius: AppBorderRadius.circular(18),
                      border: Border.all(
                        color: colors.borderPrimary.withValues(alpha: 0.72),
                      ),
                    ),
                    child: Text(
                      l10n.qrScannerSubtitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.28,
                        shadows: [
                          Shadow(
                            color: colors.scrim.withValues(alpha: 0.30),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: safePadding.bottom + 18,
              child: Container(
                padding: const AppEdgeInsets.all(16),
                decoration: AppBoxDecoration(
                  color: colors.surface.withValues(alpha: 0.92),
                  borderRadius: AppBorderRadius.circular(24),
                  border: Border.all(color: colors.borderPrimary),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_feedbackMessage != null)
                      Text(
                        _feedbackMessage!,
                        style: AppTextStyle(
                          color: _feedbackColor(),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (_pendingCount > 0) ...[
                      if (_feedbackMessage != null) const SizedBox(height: 8),
                      Text(
                        l10n.qrScannerPendingCount(_pendingCount.toString()),
                        style: AppTextStyle(
                          color: colors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (_feedbackMessage != null || _pendingCount > 0)
                      const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isManualSyncing ? null : _handleManualSync,
                        style: AppButtonStyles.secondary(colors).copyWith(
                          padding: WidgetStateProperty.all(
                            const AppEdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                        child: _isManualSyncing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppPalette.textPrimary,
                                  ),
                                ),
                              )
                            : Text(l10n.qrScannerSyncNow),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
