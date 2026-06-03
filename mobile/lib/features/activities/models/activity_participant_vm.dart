class ActivityParticipantVm {
  ActivityParticipantVm({
    required this.id,
    required this.activityId,
    required this.userId,
    required this.status,
    required this.joinedAt,
    this.approvedAt,
    this.waitlistedAt,
  });

  final String id;
  final String activityId;
  final String userId;
  final String status;
  final DateTime joinedAt;
  final DateTime? approvedAt;
  final DateTime? waitlistedAt;

  factory ActivityParticipantVm.fromJson(Map<String, dynamic> json) {
    return ActivityParticipantVm(
      id: json['id']?.toString() ?? '',
      activityId: json['activityId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      joinedAt:
          DateTime.tryParse(json['joinedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      approvedAt: DateTime.tryParse(json['approvedAt']?.toString() ?? ''),
      waitlistedAt: DateTime.tryParse(json['waitlistedAt']?.toString() ?? ''),
    );
  }

  String get normalizedStatus => status.trim().toUpperCase();

  bool get isActive {
    switch (normalizedStatus) {
      case 'REQUESTED':
      case 'APPROVED':
      case 'WAITLISTED':
      case 'PENDING_PAYMENT':
      case 'CONFIRMED':
      case 'CHECKED_IN':
        return true;
      default:
        return false;
    }
  }

  bool get occupiesSlot {
    switch (normalizedStatus) {
      case 'APPROVED':
      case 'PENDING_PAYMENT':
      case 'CONFIRMED':
      case 'CHECKED_IN':
        return true;
      default:
        return false;
    }
  }

  bool get hasConfirmedAccess {
    switch (normalizedStatus) {
      case 'APPROVED':
      case 'CONFIRMED':
      case 'CHECKED_IN':
        return true;
      default:
        return false;
    }
  }

  bool get requiresPayment => normalizedStatus == 'PENDING_PAYMENT';

  bool get isPendingDecision {
    switch (normalizedStatus) {
      case 'REQUESTED':
      case 'WAITLISTED':
        return true;
      default:
        return false;
    }
  }

  bool get canLeaveBeforeStart {
    switch (normalizedStatus) {
      case 'REQUESTED':
      case 'APPROVED':
      case 'WAITLISTED':
      case 'PENDING_PAYMENT':
      case 'CONFIRMED':
        return true;
      default:
        return false;
    }
  }

  String get shortHandle {
    final compact = userId.replaceAll('-', '');
    if (compact.isEmpty) {
      return 'Inflap';
    }
    final short = compact.substring(
      0,
      compact.length >= 8 ? 8 : compact.length,
    );
    return 'user_$short';
  }
}
