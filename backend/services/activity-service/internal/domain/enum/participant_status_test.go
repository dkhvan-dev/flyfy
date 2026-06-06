package enum

import "testing"

func TestParticipantStatusAttendedIsNotValid(t *testing.T) {
	if ParticipantStatus("ATTENDED").IsValid() {
		t.Fatal("legacy ATTENDED participant status must not be valid")
	}
}
