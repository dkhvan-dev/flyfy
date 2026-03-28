class AttendanceSyncResultVm {
  AttendanceSyncResultVm({
    required this.scanId,
    required this.status,
    required this.code,
    required this.message,
    required this.syncedAt,
    this.activityId,
    this.checkedInAt,
  });

  final String scanId;
  final String? activityId;
  final String status;
  final String code;
  final String message;
  final DateTime syncedAt;
  final DateTime? checkedInAt;

  bool get isSynced => status == 'SYNCED';
  bool get isAlreadySynced => status == 'ALREADY_SYNCED';
  bool get isRejected => status == 'REJECTED';
  bool get isRetryable => status == 'RETRYABLE';

  factory AttendanceSyncResultVm.fromJson(Map<String, dynamic> json) {
    return AttendanceSyncResultVm(
      scanId: json['scanId']?.toString() ?? '',
      activityId: json['activityId']?.toString(),
      status: json['status']?.toString() ?? 'RETRYABLE',
      code: json['code']?.toString() ?? 'server_error',
      message: json['message']?.toString() ?? '',
      syncedAt:
          DateTime.tryParse(json['syncedAt']?.toString() ?? '')?.toUtc() ??
              DateTime.now().toUtc(),
      checkedInAt:
          DateTime.tryParse(json['checkedInAt']?.toString() ?? '')?.toUtc(),
    );
  }
}
