import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_colors.dart';
import '../../features/attendance/attendance_qr_token.dart';
import '../../features/attendance/attendance_queue_repository.dart';
import '../../features/attendance/attendance_sync_manager.dart';
import '../../features/attendance/models/attendance_queue_item.dart';
import '../../features/attendance/models/attendance_sync_result_vm.dart';
import '../../l10n/generated/app_localizations.dart';
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
          l10n.qrScannerSessionUnavailable, _ScannerFeedbackTone.error);
      return;
    }

    _isHandlingScan = true;
    try {
      final existing = await _queueRepository.findPendingForActivity(
        participantUserId: participantUserId,
        activityId: payload.activityId,
      );
      if (existing != null) {
        final outcome = await AttendanceSyncManager.instance.syncPendingForUser(
          participantUserId,
        );
        if (!mounted) return;
        setState(() => _pendingCount = outcome.remainingPendingCount);
        _setFeedback(l10n.qrScannerAlreadyQueued, _ScannerFeedbackTone.warning);
        return;
      }

      final installationId = await _queueRepository.getOrCreateInstallationId();
      final scanId = _queueRepository.generateScanId();
      final item = AttendanceQueueItem(
        scanId: scanId,
        participantUserId: participantUserId,
        activityId: payload.activityId,
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
    } finally {
      _isHandlingScan = false;
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
        return l10n.qrScannerActivityUnavailable;
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
    setState(() {
      _feedbackMessage = message;
      _feedbackTone = tone;
    });
  }

  Color _feedbackColor() {
    switch (_feedbackTone) {
      case _ScannerFeedbackTone.success:
        return const Color(0xFF1DBF73);
      case _ScannerFeedbackTone.warning:
        return AppColors.accent;
      case _ScannerFeedbackTone.error:
        return const Color(0xFFFF6B57);
      case _ScannerFeedbackTone.neutral:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF140901),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: Colors.white,
                  ),
                  Expanded(
                    child: Text(
                      l10n.qrScannerTitle,
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
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
              child: Text(
                l10n.qrScannerSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: _controller,
                        onDetect: _handleDetect,
                        errorBuilder: (context, error) {
                          return DecoratedBox(
                            decoration: const BoxDecoration(
                              color: Color(0xFF221109),
                            ),
                            child: Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  l10n.qrScannerCameraUnavailable,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        overlayBuilder: (context, constraints) {
                          final frameWidth = constraints.maxWidth * 0.72;
                          final frameHeight = constraints.maxHeight * 0.38;
                          return Center(
                            child: Container(
                              width: frameWidth,
                              height: frameHeight,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: AppColors.accent,
                                  width: 2.4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent
                                        .withValues(alpha: 0.22),
                                    blurRadius: 28,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        left: 18,
                        right: 18,
                        bottom: 18,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xD91D1009),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _feedbackMessage ?? l10n.qrScannerReady,
                                style: TextStyle(
                                  color: _feedbackMessage == null
                                      ? Colors.white
                                      : _feedbackColor(),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _pendingCount > 0
                                    ? l10n.qrScannerPendingCount(
                                        _pendingCount.toString(),
                                      )
                                    : l10n.qrScannerNoPending,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _refreshPendingState,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: BorderSide(
                                          color: Colors.white
                                              .withValues(alpha: 0.14),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                      child: Text(l10n.qrScannerSyncNow),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: () => _setFeedback(
                                        l10n.qrScannerReady,
                                        _ScannerFeedbackTone.neutral,
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.accent,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                      child: Text(l10n.qrScannerScanAgain),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}
