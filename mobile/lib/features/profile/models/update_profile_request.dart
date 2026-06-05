class UpdateProfileRequest {
  UpdateProfileRequest({
    required this.firstName,
    required this.lastName,
    this.nickname,
    this.bio,
    this.birthDate,
    this.avatarFileId,
    this.countryCode,
    this.locale,
    this.timezone,
    this.currency,
  });

  final String firstName;
  final String lastName;
  final String? nickname;
  final String? bio;
  final DateTime? birthDate;
  final String? avatarFileId;
  final String? countryCode;
  final String? locale;
  final String? timezone;
  final String? currency;

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      if ((nickname ?? '').trim().isNotEmpty) 'nickname': nickname!.trim(),
      if ((bio ?? '').trim().isNotEmpty) 'bio': bio!.trim(),
      if (birthDate != null)
        'birthDate':
            '${birthDate!.year.toString().padLeft(4, '0')}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.day.toString().padLeft(2, '0')}',
      if ((avatarFileId ?? '').trim().isNotEmpty)
        'avatarFileId': avatarFileId!.trim(),
      if ((countryCode ?? '').trim().isNotEmpty)
        'countryCode': countryCode!.trim(),
      if ((locale ?? '').trim().isNotEmpty) 'locale': locale!.trim(),
      if ((timezone ?? '').trim().isNotEmpty) 'timezone': timezone!.trim(),
      if ((currency ?? '').trim().isNotEmpty) 'currency': currency!.trim(),
    };
  }
}
