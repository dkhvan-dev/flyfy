import 'package:characters/characters.dart';

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
    this.avatarFileId,
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
  final String? avatarFileId;

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
      avatarFileId: profile['avatarFileId']?.toString(),
      locale: profile['locale']?.toString() ?? 'ru',
      timezone: profile['timezone']?.toString() ?? 'Asia/Almaty',
      isPublic: profile['isPublic'] == true,
    );
  }

  String get preferredName {
    if ((displayName ?? '').trim().isNotEmpty) return displayName!.trim();
    if ((firstName ?? '').trim().isNotEmpty) return firstName!.trim();
    if ((primaryPhone ?? '').trim().isNotEmpty) return primaryPhone!.trim();
    return 'FlyFy';
  }

  String get initials {
    final source = preferredName.trim();
    if (source.isEmpty) return 'F';
    return source.characters.first.toUpperCase();
  }
}