package domain

import (
	"errors"
	"testing"
	"time"
)

func TestSavedContentProjectionVisibility(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 10, 0, 0, 0, time.UTC)
	activity, _ := NewSavedTarget(EntityTypeActivity, "activity-42")
	payload := &PublicProjectionPayload{Title: "Public activity", CanonicalDetailRoute: "/activities/42"}
	projection, err := NewSavedContentProjection(activity, VisibilityPublic, 1, now, payload)
	if err != nil {
		t.Fatalf("NewSavedContentProjection() error = %v", err)
	}

	payload.Title = "mutated outside aggregate"
	if got := projection.PublicPayload().Title; got != "Public activity" {
		t.Fatalf("payload aliases input: got %q", got)
	}
	if err := projection.SetVisibility(VisibilityPrivate, 2, now.Add(time.Minute), nil); err != nil {
		t.Fatalf("SetVisibility(PRIVATE) error = %v", err)
	}
	if projection.PublicPayload() != nil {
		t.Fatal("PRIVATE projection retained public payload")
	}
}

func TestSavedContentProjectionRejectsInvalidVisibility(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 10, 0, 0, 0, time.UTC)
	attraction, _ := NewSavedTarget(EntityTypeAttraction, "attraction-42")

	tests := []struct {
		name       string
		visibility VisibilityStatus
		payload    *PublicProjectionPayload
		wantErr    error
	}{
		{name: "PRIVATE only applies to activity", visibility: VisibilityPrivate, wantErr: ErrTargetUnavailable},
		{name: "deny visibility rejects public payload", visibility: VisibilityDeleted, payload: &PublicProjectionPayload{Title: "leak"}, wantErr: ErrTargetUnavailable},
		{name: "PUBLIC requires its safe payload", visibility: VisibilityPublic, wantErr: ErrMutationStale},
		{name: "unknown visibility is payload free", visibility: VisibilityUnknown},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			projection, err := NewSavedContentProjection(attraction, test.visibility, 1, now, test.payload)
			if !errors.Is(err, test.wantErr) {
				t.Fatalf("NewSavedContentProjection() error = %v, want %v", err, test.wantErr)
			}
			if test.wantErr == nil && projection.PublicPayload() != nil {
				t.Fatal("non-PUBLIC projection retained payload")
			}
		})
	}
}
