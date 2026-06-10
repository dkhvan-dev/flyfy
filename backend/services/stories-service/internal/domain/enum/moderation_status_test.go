package enum

import "testing"

func TestModerationStatusIsValid(t *testing.T) {
	tests := map[ModerationStatus]bool{
		ModerationStatusNotRequired: true,
		ModerationStatusPending:     true,
		ModerationStatusApproved:    true,
		ModerationStatusRejected:    true,
		ModerationStatusHidden:      true,
		ModerationStatus("BLOCKED"): false,
		ModerationStatus(""):        false,
	}

	for status, expected := range tests {
		t.Run(string(status), func(t *testing.T) {
			if got := status.IsValid(); got != expected {
				t.Fatalf("IsValid() = %v, want %v", got, expected)
			}
		})
	}
}

func TestNormalizeModerationStatus(t *testing.T) {
	tests := map[ModerationStatus]ModerationStatus{
		ModerationStatus(""):                 ModerationStatusNotRequired,
		ModerationStatus(" pending "):        ModerationStatusPending,
		ModerationStatus("approved"):         ModerationStatusApproved,
		ModerationStatus("REJECTED"):         ModerationStatusRejected,
		ModerationStatus("hidden"):           ModerationStatusHidden,
		ModerationStatus("unsupported_kind"): ModerationStatus("UNSUPPORTED_KIND"),
	}

	for input, expected := range tests {
		t.Run(string(input), func(t *testing.T) {
			if got := NormalizeModerationStatus(input); got != expected {
				t.Fatalf("NormalizeModerationStatus() = %q, want %q", got, expected)
			}
		})
	}
}
