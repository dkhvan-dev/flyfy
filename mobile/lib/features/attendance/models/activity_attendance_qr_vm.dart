class ActivityAttendanceQrVm {
  ActivityAttendanceQrVm({
    required this.activityId,
    required this.token,
    required this.expiresAt,
    required this.refreshAt,
  });

  final String activityId;
  final String token;
  final DateTime expiresAt;
  final DateTime refreshAt;

  factory ActivityAttendanceQrVm.fromJson(Map<String, dynamic> json) {
    return ActivityAttendanceQrVm(
      activityId: json['activityId']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      expiresAt:
          DateTime.tryParse(json['expiresAt']?.toString() ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      refreshAt:
          DateTime.tryParse(json['refreshAt']?.toString() ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}
