import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/activities/models/activity_participant_vm.dart';

void main() {
  group('ActivityParticipantVm status helpers', () {
    test('separates active participation from confirmed access', () {
      final requested = _participant(' requested ');
      final waitlisted = _participant('WAITLISTED');
      final pendingPayment = _participant('pending_payment');
      final approved = _participant('APPROVED');
      final confirmed = _participant('CONFIRMED');
      final checkedIn = _participant('CHECKED_IN');

      expect(requested.isActive, isTrue);
      expect(waitlisted.isActive, isTrue);
      expect(pendingPayment.isActive, isTrue);

      expect(requested.hasConfirmedAccess, isFalse);
      expect(waitlisted.hasConfirmedAccess, isFalse);
      expect(pendingPayment.hasConfirmedAccess, isFalse);
      expect(approved.hasConfirmedAccess, isTrue);
      expect(confirmed.hasConfirmedAccess, isTrue);
      expect(checkedIn.hasConfirmedAccess, isTrue);
    });

    test('marks pending payment as payable but not chat-ready', () {
      final participant = _participant('PENDING_PAYMENT');

      expect(participant.requiresPayment, isTrue);
      expect(participant.hasConfirmedAccess, isFalse);
      expect(participant.isPendingDecision, isFalse);
      expect(participant.canLeaveBeforeStart, isTrue);
    });

    test('marks requested and waitlisted as pending decisions', () {
      expect(_participant('REQUESTED').isPendingDecision, isTrue);
      expect(_participant('WAITLISTED').isPendingDecision, isTrue);
      expect(_participant('APPROVED').isPendingDecision, isFalse);
    });
  });
}

ActivityParticipantVm _participant(String status) {
  return ActivityParticipantVm(
    id: 'participant-$status',
    activityId: 'activity-1',
    userId: 'user-1',
    status: status,
    joinedAt: DateTime.parse('2026-01-01T10:00:00Z'),
  );
}
