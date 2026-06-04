class UserBlockStatusVm {
  const UserBlockStatusVm({
    required this.userId,
    required this.isBlockedByMe,
    required this.hasBlockedMe,
  });

  final String userId;
  final bool isBlockedByMe;
  final bool hasBlockedMe;

  factory UserBlockStatusVm.fromJson(Map<String, dynamic> json) {
    return UserBlockStatusVm(
      userId: json['userId']?.toString() ?? '',
      isBlockedByMe: json['isBlockedByMe'] == true,
      hasBlockedMe: json['hasBlockedMe'] == true,
    );
  }
}
