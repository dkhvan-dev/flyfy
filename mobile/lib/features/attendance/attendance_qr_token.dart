import 'dart:convert';

class AttendanceQrTokenPayload {
  AttendanceQrTokenPayload({
    required this.activityId,
    required this.hostId,
    required this.qrJti,
    required this.issuedAt,
    required this.expiresAt,
    required this.version,
    required this.audience,
  });

  static const prefix = 'ffatt1';

  final String activityId;
  final String hostId;
  final String qrJti;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final int version;
  final String audience;

  static AttendanceQrTokenPayload? tryParse(String rawToken) {
    final token = rawToken.trim();
    if (token.isEmpty) return null;

    final parts = token.split('.');
    if (parts.length != 3 || parts.first != prefix) {
      return null;
    }

    try {
      final payloadBytes = base64Url.decode(base64Url.normalize(parts[1]));
      final payload = jsonDecode(utf8.decode(payloadBytes));
      if (payload is! Map<String, dynamic>) {
        return null;
      }

      final version = (payload['v'] as num?)?.toInt();
      final audience = payload['aud']?.toString();
      final activityId = payload['activityId']?.toString();
      final hostId = payload['hostId']?.toString();
      final qrJti = payload['jti']?.toString();
      final issuedAt = (payload['iat'] as num?)?.toInt();
      final expiresAt = (payload['exp'] as num?)?.toInt();
      if (version == null ||
          audience == null ||
          activityId == null ||
          hostId == null ||
          qrJti == null ||
          issuedAt == null ||
          expiresAt == null) {
        return null;
      }

      return AttendanceQrTokenPayload(
        activityId: activityId,
        hostId: hostId,
        qrJti: qrJti,
        issuedAt: DateTime.fromMillisecondsSinceEpoch(
          issuedAt * 1000,
          isUtc: true,
        ),
        expiresAt: DateTime.fromMillisecondsSinceEpoch(
          expiresAt * 1000,
          isUtc: true,
        ),
        version: version,
        audience: audience,
      );
    } catch (_) {
      return null;
    }
  }
}
