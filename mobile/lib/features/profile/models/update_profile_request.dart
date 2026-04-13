class UpdateProfileRequest {
  UpdateProfileRequest({
    required this.firstName,
    required this.lastName,
    this.displayName,
    this.bio,
    this.birthDate,
    this.avatarFileId,
    this.countryCode,
    this.locale,
    this.timezone,
    this.currency,
    this.isPublic,
  });

  final String firstName;
  final String lastName;
  final String? displayName;
  final String? bio;
  final DateTime? birthDate;
  final String? avatarFileId;
  final String? countryCode;
  final String? locale;
  final String? timezone;
  final String? currency;
  final bool? isPublic;

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      if ((displayName ?? '').trim().isNotEmpty)
        'displayName': displayName!.trim(),
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
      if (isPublic != null) 'isPublic': isPublic,
    };
  }
}
