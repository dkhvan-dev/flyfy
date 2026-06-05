class ProfileFollowerVm {
  const ProfileFollowerVm({
    required this.userId,
    this.nickname,
    this.avatarFileId,
    this.isOnline = false,
    this.lastSeenAt,
    this.requestedAt,
  });

  final String userId;
  final String? nickname;
  final String? avatarFileId;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final DateTime? requestedAt;

  factory ProfileFollowerVm.fromJson(Map<String, dynamic> json) {
    return ProfileFollowerVm(
      userId: json['userId']?.toString() ?? '',
      nickname: json['nickname']?.toString(),
      avatarFileId: json['avatarFileId']?.toString(),
      isOnline: json['isOnline'] == true,
      lastSeenAt: DateTime.tryParse(json['lastSeenAt']?.toString() ?? ''),
      requestedAt: DateTime.tryParse(json['requestedAt']?.toString() ?? ''),
    );
  }

  String nicknameOrFallback(String fallback) {
    final value = (nickname ?? '').trim();
    return value.isEmpty ? fallback : value;
  }

  String get initials {
    final source = (nickname ?? '').trim();
    if (source.isEmpty) return 'U';

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
}

class ProfileFollowersPageVm {
  const ProfileFollowersPageVm({required this.items, this.nextOffset});

  final List<ProfileFollowerVm> items;
  final int? nextOffset;

  factory ProfileFollowersPageVm.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>?) ?? const [];
    return ProfileFollowersPageVm(
      items: items
          .whereType<Map<String, dynamic>>()
          .map(ProfileFollowerVm.fromJson)
          .toList(growable: false),
      nextOffset: (json['nextOffset'] as num?)?.toInt(),
    );
  }
}
