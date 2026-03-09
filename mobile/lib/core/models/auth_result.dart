class AuthResult {
  AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.isNewUser,
    this.primaryPhoneHint,
    this.primaryEmailHint,
  });

  final String accessToken;
  final String refreshToken;
  final bool isNewUser;
  final String? primaryPhoneHint;
  final String? primaryEmailHint;

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      accessToken: json['access_token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString() ?? '',
      isNewUser: json['is_new_user'] == true,
      primaryPhoneHint: json['primary_phone_hint']?.toString(),
      primaryEmailHint: json['primary_email_hint']?.toString(),
    );
  }
}