import 'package:dio/dio.dart';

import '../../features/attendance/models/activity_attendance_qr_vm.dart';
import '../../features/attendance/models/attendance_queue_item.dart';
import '../../features/attendance/models/attendance_sync_result_vm.dart';
import 'api_client.dart';

class AttendanceApi {
  AttendanceApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ActivityAttendanceQrVm> getActivityAttendanceQr(
      String activityId) async {
    final response =
        await _apiClient.dio.get('/me/activities/$activityId/attendance-qr');
    return ActivityAttendanceQrVm.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<List<AttendanceSyncResultVm>> syncAttendanceProofs(
    List<AttendanceQueueItem> items,
  ) async {
    final response = await _apiClient.dio.post(
      '/me/attendance/sync',
      data: {
        'items': items
            .map(
              (item) => {
                'scanId': item.scanId,
                'qrToken': item.qrToken,
                'installationId': item.installationId,
                'scannedAtDevice':
                    item.scannedAtDevice.toUtc().toIso8601String(),
              },
            )
            .toList(growable: false),
      },
      options: Options(sendTimeout: const Duration(seconds: 20)),
    );

    final data = response.data;
    final itemsJson = (data is Map<String, dynamic>
            ? data['items'] as List<dynamic>?
            : null) ??
        const [];
    return itemsJson
        .whereType<Map<String, dynamic>>()
        .map(AttendanceSyncResultVm.fromJson)
        .toList(growable: false);
  }
}
