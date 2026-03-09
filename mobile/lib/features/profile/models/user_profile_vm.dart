class UserProfileVm {
  UserProfileVm({
    required this.userId,
    required this.status,
    required this.locale,
    required this.timezone,
    required this.isPublic,
    this.primaryPhone,
    this.primaryEmail,
    this.firstName,
    this.lastName,
    this.displayName,
    this.bio,
    this.avatarFileId,
    this.countryCode,
    this.currency,
  });

  final String userId;
  final String status;
  final String locale;
  final String timezone;
  final bool isPublic;

  final String? primaryPhone;
  final String? primaryEmail;
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final String? bio;
  final String? avatarFileId;
  final String? countryCode;
  final String? currency;

  factory UserProfileVm.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    final profile = json['profile'] as Map<String, dynamic>? ?? const {};

    return UserProfileVm(
      userId: user['id']?.toString() ?? '',
      status: user['status']?.toString() ?? '',
      primaryPhone: user['primaryPhone']?.toString(),
      primaryEmail: user['primaryEmail']?.toString(),
      firstName: profile['firstName']?.toString(),
      lastName: profile['lastName']?.toString(),
      displayName: profile['displayName']?.toString(),
      bio: profile['bio']?.toString(),
      avatarFileId: profile['avatarFileId']?.toString(),
      countryCode: profile['countryCode']?.toString(),
      locale: profile['locale']?.toString() ?? 'ru',
      timezone: profile['timezone']?.toString() ?? 'Asia/Almaty',
      currency: profile['currency']?.toString(),
      isPublic: profile['isPublic'] == true,
    );
  }

  String get preferredName {
    final display = (displayName ?? '').trim();
    if (display.isNotEmpty) return display;

    final first = (firstName ?? '').trim();
    final last = (lastName ?? '').trim();
    final fullName = [first, last].where((e) => e.isNotEmpty).join(' ');
    if (fullName.isNotEmpty) return fullName;

    final phone = (primaryPhone ?? '').trim();
    if (phone.isNotEmpty) return _maskPhone(phone);

    if (userId.isNotEmpty) {
      final shortId = userId.replaceAll('-', '');
      return 'user_${shortId.substring(0, shortId.length >= 8 ? 8 : shortId.length)}';
    }

    return 'FlyFy';
  }

  String get initials {
    final source = preferredName.trim();
    if (source.isEmpty) return 'F';
    return source.substring(0, 1).toUpperCase();
  }

  bool get isProfileCompleted {
    return (firstName ?? '').trim().isNotEmpty &&
        (lastName ?? '').trim().isNotEmpty;
  }

  String _maskPhone(String phone) {
    if (phone.length < 4) return phone;
    return '${phone.substring(0, phone.length - 4)}****';
  }
}