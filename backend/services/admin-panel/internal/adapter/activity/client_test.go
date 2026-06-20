package activity

import "testing"

func TestActivityResponseToModelPreservesHostFullName(t *testing.T) {
	t.Parallel()

	item := activityResponse{
		HostDisplayName: "@nomad_aru",
		HostFullName:    "Аружан Тулегенова",
	}

	got := item.toModel()

	if got.HostDisplayName != item.HostDisplayName {
		t.Fatalf("HostDisplayName = %q, want %q", got.HostDisplayName, item.HostDisplayName)
	}
	if got.HostFullName != item.HostFullName {
		t.Fatalf("HostFullName = %q, want %q", got.HostFullName, item.HostFullName)
	}
}
