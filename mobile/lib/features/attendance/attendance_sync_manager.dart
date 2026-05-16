import 'package:dio/dio.dart';

import '../../core/network/attendance_api.dart';
import 'attendance_queue_repository.dart';
import 'models/attendance_queue_item.dart';
import 'models/attendance_sync_result_vm.dart';

class AttendanceSyncOutcome {
  AttendanceSyncOutcome({
    required this.resultsByScanId,
    required this.remainingPendingCount,
  });

  final Map<String, AttendanceSyncResultVm> resultsByScanId;
  final int remainingPendingCount;

  AttendanceSyncResultVm? resultFor(String scanId) => resultsByScanId[scanId];
}

class AttendanceSyncManager {
  AttendanceSyncManager._();

  static final AttendanceSyncManager instance = AttendanceSyncManager._();

  final AttendanceApi _attendanceApi = AttendanceApi();
  final AttendanceQueueRepository _queueRepository =
      AttendanceQueueRepository();

  bool _isSyncing = false;

  Future<AttendanceSyncOutcome> syncPendingForUser(
    String participantUserId, {
    bool force = false,
  }) async {
    if (_isSyncing || participantUserId.trim().isEmpty) {
      final allItems = await _queueRepository.readAll();
      return AttendanceSyncOutcome(
        resultsByScanId: const {},
        remainingPendingCount: allItems
            .where((item) => item.participantUserId == participantUserId)
            .length,
      );
    }

    _isSyncing = true;
    try {
      final allItems = await _queueRepository.readAll();
      final now = DateTime.now().toUtc();
      final readyItems = allItems
          .where(
            (item) =>
                item.participantUserId == participantUserId &&
                (force ||
                    item.nextRetryAt == null ||
                    !item.nextRetryAt!.isAfter(now)),
          )
          .toList(growable: false);

      if (readyItems.isEmpty) {
        return AttendanceSyncOutcome(
          resultsByScanId: const {},
          remainingPendingCount: allItems
              .where((item) => item.participantUserId == participantUserId)
              .length,
        );
      }

      try {
        final results = await _attendanceApi.syncAttendanceProofs(readyItems);
        final resultsByScanId = {
          for (final result in results) result.scanId: result,
        };

        final updatedQueue = <AttendanceQueueItem>[];
        for (final item in allItems) {
          if (item.participantUserId != participantUserId) {
            updatedQueue.add(item);
            continue;
          }

          final result = resultsByScanId[item.scanId];
          if (result == null) {
            updatedQueue.add(item);
            continue;
          }

          if (result.isRetryable) {
            updatedQueue.add(
              item.copyWith(
                retryCount: item.retryCount + 1,
                nextRetryAt: _nextRetryAt(now, item.retryCount + 1),
                lastErrorCode: result.code,
                lastErrorMessage: result.message,
              ),
            );
          }
        }

        await _queueRepository.writeAll(updatedQueue);
        return AttendanceSyncOutcome(
          resultsByScanId: resultsByScanId,
          remainingPendingCount: updatedQueue
              .where((item) => item.participantUserId == participantUserId)
              .length,
        );
      } on DioException catch (error) {
        final updatedQueue = <AttendanceQueueItem>[];
        final resultsByScanId = <String, AttendanceSyncResultVm>{};
        final errorCode = _retryErrorCode(error);
        final errorMessage = _retryErrorMessage(error);

        final readyScanIds = {for (final item in readyItems) item.scanId: item};

        for (final item in allItems) {
          if (item.participantUserId != participantUserId ||
              !readyScanIds.containsKey(item.scanId)) {
            updatedQueue.add(item);
            continue;
          }

          final retryCount = item.retryCount + 1;
          updatedQueue.add(
            item.copyWith(
              retryCount: retryCount,
              nextRetryAt: _nextRetryAt(now, retryCount),
              lastErrorCode: errorCode,
              lastErrorMessage: errorMessage,
            ),
          );
          resultsByScanId[item.scanId] = AttendanceSyncResultVm(
            scanId: item.scanId,
            activityId: item.activityId,
            status: 'RETRYABLE',
            code: errorCode,
            message: errorMessage,
            syncedAt: now,
          );
        }

        await _queueRepository.writeAll(updatedQueue);
        return AttendanceSyncOutcome(
          resultsByScanId: resultsByScanId,
          remainingPendingCount: updatedQueue
              .where((item) => item.participantUserId == participantUserId)
              .length,
        );
      }
    } finally {
      _isSyncing = false;
    }
  }

  DateTime _nextRetryAt(DateTime now, int retryCount) {
    final seconds = retryCount <= 1
        ? 15
        : retryCount == 2
            ? 30
            : retryCount == 3
                ? 60
                : retryCount == 4
                    ? 120
                    : retryCount == 5
                        ? 300
                        : 900;
    return now.add(Duration(seconds: seconds));
  }

  bool _isOfflineError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return false;
    }
  }

  String _retryErrorCode(DioException error) {
    if (_isOfflineError(error)) {
      return 'offline';
    }

    final statusCode = error.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      return 'auth_required';
    }

    return 'server_error';
  }

  String _retryErrorMessage(DioException error) {
    final statusCode = error.response?.statusCode;
    if (_isOfflineError(error)) {
      return 'offline';
    }
    if (statusCode == 401 || statusCode == 403) {
      return 'auth_required';
    }
    return 'server_error';
  }
}
