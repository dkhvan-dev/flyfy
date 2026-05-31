import 'dart:convert';

class AttendanceQrTokenPayload {
  AttendanceQrTokenPayload({
    required this.type,
    required this.subjectId,
    required this.activityId,
    required this.hostId,
    required this.qrJti,
    required this.issuedAt,
    required this.expiresAt,
    required this.version,
    required this.audience,
  });

  static const prefix = 'ffatt1';
  static const excursionPrefix = 'ffexatt1';
  static const typeActivity = 'activity';
  static const typeExcursion = 'excursion';

  final String type;
  final String subjectId;
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
    final tokenPrefix = parts.isEmpty ? '' : parts.first;
    if (parts.length != 3 ||
        (tokenPrefix != prefix && tokenPrefix != excursionPrefix)) {
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
      final isExcursion = tokenPrefix == excursionPrefix;
      final subjectId = payload[isExcursion ? 'slotId' : 'activityId']
          ?.toString();
      final hostId = payload[isExcursion ? 'guideId' : 'hostId']?.toString();
      final qrJti = payload['jti']?.toString();
      final issuedAt = (payload['iat'] as num?)?.toInt();
      final expiresAt = (payload['exp'] as num?)?.toInt();
      if (version == null ||
          audience == null ||
          subjectId == null ||
          hostId == null ||
          qrJti == null ||
          issuedAt == null ||
          expiresAt == null) {
        return null;
      }

      return AttendanceQrTokenPayload(
        type: isExcursion ? typeExcursion : typeActivity,
        subjectId: subjectId,
        activityId: subjectId,
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
