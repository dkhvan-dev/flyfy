class UserProfileVm {
  UserProfileVm({
    required this.userId,
    required this.status,
    required this.locale,
    required this.timezone,
    required this.isPublic,
    required this.isProfileCompleted,
    required this.roles,
    required this.followersCount,
    required this.isFollowedByMe,
    this.primaryPhone,
    this.primaryEmail,
    this.firstName,
    this.lastName,
    this.displayName,
    this.bio,
    this.birthDate,
    this.avatarFileId,
    this.countryCode,
    this.currency,
    this.settings,
    this.reputation,
  });

  final String userId;
  final String status;
  final String locale;
  final String timezone;
  final bool isPublic;
  final bool isProfileCompleted;
  final List<String> roles;
  final int followersCount;
  final bool isFollowedByMe;

  final String? primaryPhone;
  final String? primaryEmail;
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final String? bio;
  final DateTime? birthDate;
  final String? avatarFileId;
  final String? countryCode;
  final String? currency;
  final UserSettingsVm? settings;
  final UserReputationVm? reputation;

  factory UserProfileVm.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    final profile = json['profile'] as Map<String, dynamic>? ?? const {};
    final settings = json['settings'] as Map<String, dynamic>?;
    final reputation = json['reputation'] as Map<String, dynamic>?;
    final rawRoles = json['roles'];
    final followers = json['followers'] as Map<String, dynamic>? ?? const {};

    return UserProfileVm(
      userId: user['id']?.toString() ?? '',
      status: user['status']?.toString() ?? '',
      primaryPhone: user['primaryPhone']?.toString(),
      primaryEmail: user['primaryEmail']?.toString(),
      firstName: profile['firstName']?.toString(),
      lastName: profile['lastName']?.toString(),
      displayName: profile['displayName']?.toString(),
      bio: profile['bio']?.toString(),
      birthDate: DateTime.tryParse(profile['birthDate']?.toString() ?? ''),
      avatarFileId: profile['avatarFileId']?.toString(),
      countryCode: profile['countryCode']?.toString(),
      locale: profile['locale']?.toString() ?? 'ru',
      timezone: profile['timezone']?.toString() ?? 'Asia/Almaty',
      currency: profile['currency']?.toString(),
      isPublic: profile['isPublic'] == true,
      isProfileCompleted: profile['isProfileCompleted'] == true,
      roles: rawRoles is List
          ? rawRoles.map((item) => item.toString()).toList(growable: false)
          : const [],
      followersCount: int.tryParse(followers['count']?.toString() ?? '') ?? 0,
      isFollowedByMe: followers['isFollowedByMe'] == true,
      settings: settings == null ? null : UserSettingsVm.fromJson(settings),
      reputation: reputation == null
          ? null
          : UserReputationVm.fromJson(reputation),
    );
  }

  UserProfileVm copyWith({int? followersCount, bool? isFollowedByMe}) {
    return UserProfileVm(
      userId: userId,
      status: status,
      locale: locale,
      timezone: timezone,
      isPublic: isPublic,
      isProfileCompleted: isProfileCompleted,
      roles: roles,
      followersCount: followersCount ?? this.followersCount,
      isFollowedByMe: isFollowedByMe ?? this.isFollowedByMe,
      primaryPhone: primaryPhone,
      primaryEmail: primaryEmail,
      firstName: firstName,
      lastName: lastName,
      displayName: displayName,
      bio: bio,
      birthDate: birthDate,
      avatarFileId: avatarFileId,
      countryCode: countryCode,
      currency: currency,
      settings: settings,
      reputation: reputation,
    );
  }

  bool get isGuide {
    return roles.any((role) => role.trim().toUpperCase() == 'GUIDE');
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
    final parts = source
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.length >= 2) {
      return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
          .toUpperCase();
    }
    return parts.first.substring(0, 1).toUpperCase();
  }

  String _maskPhone(String phone) {
    if (phone.length < 4) return phone;
    return '${phone.substring(0, phone.length - 4)}****';
  }
}

class UserSettingsVm {
  UserSettingsVm({
    required this.userId,
    required this.notificationsPushEnabled,
    required this.notificationsEmailEnabled,
    required this.notificationsSmsEnabled,
    required this.marketingEnabled,
    required this.darkModeEnabled,
  });

  final String userId;
  final bool notificationsPushEnabled;
  final bool notificationsEmailEnabled;
  final bool notificationsSmsEnabled;
  final bool marketingEnabled;
  final bool darkModeEnabled;

  factory UserSettingsVm.fromJson(Map<String, dynamic> json) {
    return UserSettingsVm(
      userId: json['userId']?.toString() ?? '',
      notificationsPushEnabled: json['notificationsPushEnabled'] == true,
      notificationsEmailEnabled: json['notificationsEmailEnabled'] == true,
      notificationsSmsEnabled: json['notificationsSmsEnabled'] == true,
      marketingEnabled: json['marketingEnabled'] == true,
      darkModeEnabled: json['darkModeEnabled'] == true,
    );
  }

  UserSettingsVm copyWith({
    bool? notificationsPushEnabled,
    bool? notificationsEmailEnabled,
    bool? notificationsSmsEnabled,
    bool? marketingEnabled,
    bool? darkModeEnabled,
  }) {
    return UserSettingsVm(
      userId: userId,
      notificationsPushEnabled:
          notificationsPushEnabled ?? this.notificationsPushEnabled,
      notificationsEmailEnabled:
          notificationsEmailEnabled ?? this.notificationsEmailEnabled,
      notificationsSmsEnabled:
          notificationsSmsEnabled ?? this.notificationsSmsEnabled,
      marketingEnabled: marketingEnabled ?? this.marketingEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
    );
  }
}

class UserReputationVm {
  UserReputationVm({
    required this.userId,
    required this.trustScore,
    required this.riskScore,
    required this.completedBookings,
    required this.completedActivities,
    required this.cancellationsCount,
    required this.reportsCount,
  });

  final String userId;
  final int trustScore;
  final int riskScore;
  final int completedBookings;
  final int completedActivities;
  final int cancellationsCount;
  final int reportsCount;

  factory UserReputationVm.fromJson(Map<String, dynamic> json) {
    int parseInt(String key) => int.tryParse(json[key]?.toString() ?? '') ?? 0;

    return UserReputationVm(
      userId: json['userId']?.toString() ?? '',
      trustScore: parseInt('trustScore'),
      riskScore: parseInt('riskScore'),
      completedBookings: parseInt('completedBookings'),
      completedActivities: parseInt('completedActivities'),
      cancellationsCount: parseInt('cancellationsCount'),
      reportsCount: parseInt('reportsCount'),
    );
  }
}
