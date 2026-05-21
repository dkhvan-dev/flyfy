import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/features/activities/activity_edit_policy.dart';

void main() {
  test(
    'allows meeting address edits only when start is more than one hour away',
    () {
      final now = DateTime(2026, 5, 21, 12);

      expect(
        ActivityEditPolicy.canEditMeetingAddress(
          startAt: now.add(const Duration(hours: 1, minutes: 1)),
          now: now,
        ),
        isTrue,
      );
    },
  );

  test('blocks meeting address edits exactly one hour before start', () {
    final now = DateTime(2026, 5, 21, 12);

    expect(
      ActivityEditPolicy.canEditMeetingAddress(
        startAt: now.add(const Duration(hours: 1)),
        now: now,
      ),
      isFalse,
    );
  });

  test('blocks meeting address edits less than one hour before start', () {
    final now = DateTime(2026, 5, 21, 12);

    expect(
      ActivityEditPolicy.canEditMeetingAddress(
        startAt: now.add(const Duration(minutes: 59, seconds: 59)),
        now: now,
      ),
      isFalse,
    );
  });

  test('blocks meeting address edits after activity start', () {
    final now = DateTime(2026, 5, 21, 12);

    expect(
      ActivityEditPolicy.canEditMeetingAddress(
        startAt: now.subtract(const Duration(minutes: 1)),
        now: now,
      ),
      isFalse,
    );
  });
}
