class AuthResult {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final bool isNewUser;

  AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.isNewUser,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      tokenType: json['token_type'] ?? '',
      expiresIn: json['expires_in'] ?? 0,
      isNewUser: json['is_new_user'] ?? false,
    );
  }
}
