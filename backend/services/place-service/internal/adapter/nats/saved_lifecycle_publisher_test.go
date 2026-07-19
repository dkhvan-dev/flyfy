package nats

import (
	"bytes"
	"context"
	"testing"
	"time"

	"github.com/google/uuid"
	gonats "github.com/nats-io/nats.go"
	"google.golang.org/protobuf/proto"

	"kz/inflap/backend/services/place-service/internal/domain/model"
	contentv1 "kz/inflap/proto/gen/go/content/v1"
)

func TestSavedSourceStreamConfigIsCanonicalAndNotNarrowed(t *testing.T) {
	t.Parallel()

	config := savedSourceStreamConfig()
	assertSavedSourceStreamConfig(t, config)
	if len(config.Subjects) != 1 || config.Subjects[0] == DefaultSavedLifecycleSubject {
		t.Fatalf("shared stream subjects were narrowed to a producer subject: %#v", config.Subjects)
	}
}

func TestNewSavedLifecyclePublisherDefersStreamWhenNATSIsDisconnected(t *testing.T) {
	t.Parallel()

	publisher, err := NewSavedLifecyclePublisher(
		context.Background(),
		&gonats.Conn{},
	)
	if err != nil || publisher == nil {
		t.Fatalf("NewSavedLifecyclePublisher() = %#v, %v, want deferred publisher", publisher, err)
	}
}

func TestMarshalSavedLifecycleEventIsDeterministicAndProtoCompatible(t *testing.T) {
	t.Parallel()

	event := lifecyclePublisherTestEvent(
		model.SavedLifecycleUpdated,
		model.SavedLifecycleVisibilityPublic,
	)
	first, err := MarshalSavedLifecycleEvent(event)
	if err != nil {
		t.Fatalf("MarshalSavedLifecycleEvent() error = %v", err)
	}
	second, err := MarshalSavedLifecycleEvent(event)
	if err != nil {
		t.Fatalf("second MarshalSavedLifecycleEvent() error = %v", err)
	}
	if !bytes.Equal(first, second) {
		t.Fatal("immutable redelivery produced different envelope bytes")
	}

	var envelope contentv1.SavedSourceLifecycleEvent
	if err = proto.Unmarshal(first, &envelope); err != nil {
		t.Fatalf("proto.Unmarshal() error = %v", err)
	}
	if envelope.GetEventId() != event.EventID.String() ||
		envelope.GetKind() != contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_UPDATED ||
		envelope.GetTarget().GetEntityType() != contentv1.SavedEntityType_SAVED_ENTITY_TYPE_ATTRACTION ||
		envelope.GetTarget().GetEntityId() != event.EntityID.String() ||
		envelope.GetVisibility() != contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_PUBLIC {
		t.Fatalf("unexpected lifecycle envelope: %s", envelope.String())
	}
	if envelope.GetRevisions().GetSourceRevision() != event.SourceRevision ||
		envelope.GetRevisions().GetProjectionRevision() != event.ProjectionRevision ||
		envelope.GetRevisions().GetVisibilityRevision() != event.VisibilityRevision {
		t.Fatalf("unexpected revision vector: %s", envelope.GetRevisions().String())
	}
	if envelope.GetOccurredAt() == nil || !envelope.GetOccurredAt().AsTime().Equal(event.OccurredAt) {
		t.Fatalf("occurred_at = %v, want %v", envelope.GetOccurredAt(), event.OccurredAt)
	}
	if envelope.GetPublicProjection() != nil {
		t.Fatal("place lifecycle envelope unexpectedly materialized a PUBLIC projection")
	}
}

func TestMarshalSavedLifecycleDenyEventsArePayloadFree(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name       string
		eventType  model.SavedLifecycleEventType
		visibility model.SavedLifecycleVisibility
		kind       contentv1.SavedLifecycleEventKind
	}{
		{
			name:       "unavailable",
			eventType:  model.SavedLifecycleUnavailable,
			visibility: model.SavedLifecycleVisibilityUnavailable,
			kind:       contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_UNAVAILABLE,
		},
		{
			name:       "deleted",
			eventType:  model.SavedLifecycleDeleted,
			visibility: model.SavedLifecycleVisibilityDeleted,
			kind:       contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_DELETED,
		},
		{
			name:       "restricted",
			eventType:  model.SavedLifecycleVisibilityChanged,
			visibility: model.SavedLifecycleVisibilityRestricted,
			kind:       contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_VISIBILITY_CHANGED,
		},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			payload, err := MarshalSavedLifecycleEvent(lifecyclePublisherTestEvent(test.eventType, test.visibility))
			if err != nil {
				t.Fatalf("MarshalSavedLifecycleEvent() error = %v", err)
			}
			var envelope contentv1.SavedSourceLifecycleEvent
			if err = proto.Unmarshal(payload, &envelope); err != nil {
				t.Fatalf("proto.Unmarshal() error = %v", err)
			}
			if envelope.GetKind() != test.kind || envelope.GetPublicProjection() != nil {
				t.Fatalf("deny envelope = %s", envelope.String())
			}
			if bytes.Contains(payload, []byte("attraction-cover:")) ||
				bytes.Contains(payload, []byte("https://")) ||
				bytes.Contains(payload, []byte("http://")) {
				t.Fatalf("deny envelope leaked projection/media bytes: %x", payload)
			}
		})
	}
}

func lifecyclePublisherTestEvent(
	eventType model.SavedLifecycleEventType,
	visibility model.SavedLifecycleVisibility,
) model.SavedLifecycleEvent {
	return model.SavedLifecycleEvent{
		EventID:            uuid.MustParse("f1500000-0000-4000-8000-000000000021"),
		SchemaVersion:      1,
		EventType:          eventType,
		EntityID:           uuid.MustParse("f1500000-0000-4000-8000-000000000022"),
		SourceRevision:     101,
		ProjectionRevision: 102,
		VisibilityRevision: 103,
		Visibility:         visibility,
		OccurredAt:         time.Date(2026, time.July, 16, 10, 30, 0, 0, time.UTC),
	}
}
