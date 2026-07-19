package model

import (
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
)

func TestSavedLifecycleEventValidateClosedKindVisibilityPairs(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 10, 0, 0, 0, time.UTC)
	tests := []struct {
		name       string
		eventType  SavedLifecycleEventType
		visibility SavedLifecycleVisibility
	}{
		{name: "published", eventType: SavedLifecyclePublished, visibility: SavedLifecycleVisibilityPublic},
		{name: "updated", eventType: SavedLifecycleUpdated, visibility: SavedLifecycleVisibilityPublic},
		{name: "unavailable", eventType: SavedLifecycleUnavailable, visibility: SavedLifecycleVisibilityUnavailable},
		{name: "deleted", eventType: SavedLifecycleDeleted, visibility: SavedLifecycleVisibilityDeleted},
		{name: "restricted", eventType: SavedLifecycleVisibilityChanged, visibility: SavedLifecycleVisibilityRestricted},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			event := validSavedLifecycleEvent(now)
			event.EventType = test.eventType
			event.Visibility = test.visibility
			if err := event.Validate(); err != nil {
				t.Fatalf("Validate() error = %v", err)
			}
		})
	}
}

func TestSavedLifecycleEventValidateRejectsInvalidEnvelope(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 10, 0, 0, 0, time.UTC)
	tests := []struct {
		name   string
		mutate func(*SavedLifecycleEvent)
	}{
		{name: "non v4 event id", mutate: func(event *SavedLifecycleEvent) {
			event.EventID = uuid.MustParse("018fbb77-2ec8-7e56-8000-000000000001")
		}},
		{name: "nil entity", mutate: func(event *SavedLifecycleEvent) { event.EntityID = uuid.Nil }},
		{name: "unknown schema", mutate: func(event *SavedLifecycleEvent) { event.SchemaVersion = 2 }},
		{name: "zero revision", mutate: func(event *SavedLifecycleEvent) { event.SourceRevision = 0 }},
		{name: "zero time", mutate: func(event *SavedLifecycleEvent) { event.OccurredAt = time.Time{} }},
		{name: "deny with public visibility", mutate: func(event *SavedLifecycleEvent) {
			event.EventType = SavedLifecycleDeleted
			event.Visibility = SavedLifecycleVisibilityPublic
		}},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			event := validSavedLifecycleEvent(now)
			test.mutate(&event)
			if err := event.Validate(); !errors.Is(err, ErrInvalidSavedLifecycleEvent) {
				t.Fatalf("Validate() error = %v, want ErrInvalidSavedLifecycleEvent", err)
			}
		})
	}
}

func validSavedLifecycleEvent(now time.Time) SavedLifecycleEvent {
	return SavedLifecycleEvent{
		EventID:            uuid.MustParse("f1500000-0000-4000-8000-000000000011"),
		SchemaVersion:      1,
		EventType:          SavedLifecycleUpdated,
		EntityID:           uuid.MustParse("f1500000-0000-4000-8000-000000000012"),
		SourceRevision:     11,
		ProjectionRevision: 12,
		VisibilityRevision: 13,
		Visibility:         SavedLifecycleVisibilityPublic,
		OccurredAt:         now,
	}
}
