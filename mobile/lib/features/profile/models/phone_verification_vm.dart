class PhoneVerificationVm {
  const PhoneVerificationVm({
    required this.verified,
    this.challengeId,
    this.maskedPhone,
    this.resendAfterSeconds = 0,
    this.expiresAt,
    this.verifiedAt,
  });

  final String? challengeId;
  final String? maskedPhone;
  final int resendAfterSeconds;
  final DateTime? expiresAt;
  final bool verified;
  final DateTime? verifiedAt;

  factory PhoneVerificationVm.fromJson(Map<String, dynamic> json) {
    return PhoneVerificationVm(
      challengeId: _stringOrNull(json['challengeId']),
      maskedPhone: _stringOrNull(json['maskedPhone']),
      resendAfterSeconds:
          int.tryParse(json['resendAfterSeconds']?.toString() ?? '') ?? 0,
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
      verified: json['verified'] == true,
      verifiedAt: DateTime.tryParse(json['verifiedAt']?.toString() ?? ''),
    );
  }

  static String? _stringOrNull(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
