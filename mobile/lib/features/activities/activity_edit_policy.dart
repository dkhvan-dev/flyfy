class ActivityEditPolicy {
  const ActivityEditPolicy._();

  static const meetingAddressEditCutoff = Duration(hours: 1);

  static bool canEditMeetingAddress({
    required DateTime startAt,
    required DateTime now,
  }) {
    return startAt.difference(now) > meetingAddressEditCutoff;
  }
}
