class AttendanceQueueItem {
  AttendanceQueueItem({
    required this.scanId,
    required this.participantUserId,
    required this.activityId,
    required this.qrJti,
    required this.qrToken,
    required this.installationId,
    required this.scannedAtDevice,
    required this.createdAt,
    this.retryCount = 0,
    this.nextRetryAt,
    this.lastErrorCode,
    this.lastErrorMessage,
  });

  final String scanId;
  final String participantUserId;
  final String activityId;
  final String qrJti;
  final String qrToken;
  final String installationId;
  final DateTime scannedAtDevice;
  final DateTime createdAt;
  final int retryCount;
  final DateTime? nextRetryAt;
  final String? lastErrorCode;
  final String? lastErrorMessage;

  AttendanceQueueItem copyWith({
    int? retryCount,
    DateTime? nextRetryAt,
    String? lastErrorCode,
    String? lastErrorMessage,
    bool clearLastError = false,
  }) {
    return AttendanceQueueItem(
      scanId: scanId,
      participantUserId: participantUserId,
      activityId: activityId,
      qrJti: qrJti,
      qrToken: qrToken,
      installationId: installationId,
      scannedAtDevice: scannedAtDevice,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
      nextRetryAt: nextRetryAt,
      lastErrorCode:
          clearLastError ? null : (lastErrorCode ?? this.lastErrorCode),
      lastErrorMessage:
          clearLastError ? null : (lastErrorMessage ?? this.lastErrorMessage),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scanId': scanId,
      'participantUserId': participantUserId,
      'activityId': activityId,
      'qrJti': qrJti,
      'qrToken': qrToken,
      'installationId': installationId,
      'scannedAtDevice': scannedAtDevice.toUtc().toIso8601String(),
      'createdAt': createdAt.toUtc().toIso8601String(),
      'retryCount': retryCount,
      'nextRetryAt': nextRetryAt?.toUtc().toIso8601String(),
      'lastErrorCode': lastErrorCode,
      'lastErrorMessage': lastErrorMessage,
    };
  }

  factory AttendanceQueueItem.fromJson(Map<String, dynamic> json) {
    return AttendanceQueueItem(
      scanId: json['scanId']?.toString() ?? '',
      participantUserId: json['participantUserId']?.toString() ?? '',
      activityId: json['activityId']?.toString() ?? '',
      qrJti: json['qrJti']?.toString() ?? '',
      qrToken: json['qrToken']?.toString() ?? '',
      installationId: json['installationId']?.toString() ?? '',
      scannedAtDevice:
          DateTime.tryParse(json['scannedAtDevice']?.toString() ?? '')
                  ?.toUtc() ??
              DateTime.now().toUtc(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toUtc() ??
              DateTime.now().toUtc(),
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      nextRetryAt:
          DateTime.tryParse(json['nextRetryAt']?.toString() ?? '')?.toUtc(),
      lastErrorCode: json['lastErrorCode']?.toString(),
      lastErrorMessage: json['lastErrorMessage']?.toString(),
    );
  }
}
