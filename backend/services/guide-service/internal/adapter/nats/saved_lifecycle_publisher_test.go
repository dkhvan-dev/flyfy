package natsadapter

import (
	"bytes"
	"context"
	"errors"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/jetstream"
	"google.golang.org/protobuf/proto"

	"kz/inflap/backend/services/guide-service/internal/domain/model"
	contentv1 "kz/inflap/proto/gen/go/content/v1"
)

func TestEncodeSavedLifecycleEventIsDeterministicAndCanonical(t *testing.T) {
	t.Parallel()
	now := time.Date(2026, 7, 16, 12, 0, 0, 123000000, time.UTC)
	message := &model.SavedLifecycleOutboxMessage{
		EventID: uuid.New(), TargetUserID: uuid.New(),
		Kind:           model.SavedLifecycleEventPublished,
		SourceRevision: 101, ProjectionRevision: 97, VisibilityRevision: 100,
		OccurredAt: now, Visibility: model.SavedLifecycleVisibilityPublic,
		AttemptCount: 1, MaxAttempts: 12, LeaseToken: uuid.New(),
	}

	first, err := EncodeSavedLifecycleEvent(message)
	if err != nil {
		t.Fatalf("EncodeSavedLifecycleEvent() error = %v", err)
	}
	second, err := EncodeSavedLifecycleEvent(message)
	if err != nil {
		t.Fatalf("second EncodeSavedLifecycleEvent() error = %v", err)
	}
	if !bytes.Equal(first, second) {
		t.Fatal("identical outbox semantics produced different redelivery bytes")
	}

	event := &contentv1.SavedSourceLifecycleEvent{}
	if err = proto.Unmarshal(first, event); err != nil {
		t.Fatalf("unmarshal event: %v", err)
	}
	if event.GetEventId() != message.EventID.String() ||
		event.GetTarget().GetEntityId() != message.TargetUserID.String() ||
		event.GetTarget().GetEntityType() != contentv1.SavedEntityType_SAVED_ENTITY_TYPE_GUIDE ||
		event.GetRevisions().GetSourceRevision() != message.SourceRevision ||
		event.GetPublicProjection() != nil {
		t.Fatalf("event = %+v", event)
	}
}

func TestEncodeSavedLifecycleEventRejectsPayloadOnDeny(t *testing.T) {
	t.Parallel()
	message := &model.SavedLifecycleOutboxMessage{
		EventID: uuid.New(), TargetUserID: uuid.New(),
		Kind:           model.SavedLifecycleEventUnavailable,
		SourceRevision: 2, ProjectionRevision: 1, VisibilityRevision: 2,
		OccurredAt: time.Now().UTC(), Visibility: model.SavedLifecycleVisibilityUnavailable,
		PublicProjection: []byte{1}, AttemptCount: 1, MaxAttempts: 12, LeaseToken: uuid.New(),
	}
	if _, err := EncodeSavedLifecycleEvent(message); err == nil {
		t.Fatal("deny event with projection payload was accepted")
	}
}

func TestEncodeSavedLifecycleDenyEventsArePayloadFree(t *testing.T) {
	t.Parallel()
	tests := []struct {
		name       string
		kind       model.SavedLifecycleEventKind
		visibility model.SavedLifecycleVisibility
	}{
		{
			name:       "unavailable",
			kind:       model.SavedLifecycleEventUnavailable,
			visibility: model.SavedLifecycleVisibilityUnavailable,
		},
		{
			name:       "deleted",
			kind:       model.SavedLifecycleEventDeleted,
			visibility: model.SavedLifecycleVisibilityDeleted,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			message := &model.SavedLifecycleOutboxMessage{
				EventID: uuid.New(), TargetUserID: uuid.New(), Kind: tt.kind,
				SourceRevision: 5, ProjectionRevision: 3, VisibilityRevision: 4,
				OccurredAt: time.Now().UTC(), Visibility: tt.visibility,
				AttemptCount: 1, MaxAttempts: 20, LeaseToken: uuid.New(),
			}
			payload, err := EncodeSavedLifecycleEvent(message)
			if err != nil {
				t.Fatalf("EncodeSavedLifecycleEvent() error = %v", err)
			}
			event := &contentv1.SavedSourceLifecycleEvent{}
			if err = proto.Unmarshal(payload, event); err != nil {
				t.Fatalf("unmarshal deny event: %v", err)
			}
			if event.GetPublicProjection() != nil {
				t.Fatalf("deny event leaked projection/media: %+v", event.GetPublicProjection())
			}
		})
	}
}

func TestSavedLifecyclePublisherAgainstNATS(t *testing.T) {
	url := strings.TrimSpace(os.Getenv("GUIDE_SERVICE_NATS_TEST_URL"))
	if url == "" {
		t.Skip("set GUIDE_SERVICE_NATS_TEST_URL to run the NATS integration test")
	}
	connection, err := nats.Connect(url, nats.Timeout(3*time.Second))
	if err != nil {
		t.Fatalf("connect NATS: %v", err)
	}
	defer connection.Close()
	js, err := jetstream.New(connection)
	if err != nil {
		t.Fatalf("create JetStream context: %v", err)
	}
	_, streamErr := js.Stream(context.Background(), SavedSourceStreamName)
	createdStream := errors.Is(streamErr, jetstream.ErrStreamNotFound)
	if streamErr != nil && !createdStream {
		t.Fatalf("inspect Saved source stream: %v", streamErr)
	}
	if createdStream {
		defer func() {
			_ = js.DeleteStream(context.Background(), SavedSourceStreamName)
		}()
	}
	subject := "saved.source.guide.lifecycle.test." + strings.ReplaceAll(uuid.NewString(), "-", "")
	subscription, err := connection.SubscribeSync(subject)
	if err != nil {
		t.Fatalf("subscribe lifecycle subject: %v", err)
	}
	if err = connection.Flush(); err != nil {
		t.Fatalf("flush subscription: %v", err)
	}
	publisher, err := NewSavedLifecyclePublisher(context.Background(), connection, subject)
	if err != nil {
		t.Fatalf("NewSavedLifecyclePublisher() error = %v", err)
	}
	now := time.Now().UTC()
	message := &model.SavedLifecycleOutboxMessage{
		EventID: uuid.New(), TargetUserID: uuid.New(),
		Kind:           model.SavedLifecycleEventUnavailable,
		SourceRevision: 9, ProjectionRevision: 7, VisibilityRevision: 8,
		OccurredAt: now, Visibility: model.SavedLifecycleVisibilityUnavailable,
		AttemptCount: 1, MaxAttempts: 12, LeaseToken: uuid.New(),
	}
	want, err := EncodeSavedLifecycleEvent(message)
	if err != nil {
		t.Fatalf("encode expected event: %v", err)
	}
	stream, err := js.Stream(context.Background(), SavedSourceStreamName)
	if err != nil {
		t.Fatalf("load Saved source stream: %v", err)
	}
	before, err := stream.Info(context.Background())
	if err != nil {
		t.Fatalf("load Saved source stream info: %v", err)
	}
	for range 2 {
		if err = publisher.PublishSavedLifecycle(context.Background(), message); err != nil {
			t.Fatalf("PublishSavedLifecycle() error = %v", err)
		}
	}
	received, err := subscription.NextMsg(3 * time.Second)
	if err != nil {
		t.Fatalf("receive lifecycle event: %v", err)
	}
	if !bytes.Equal(received.Data, want) {
		t.Fatal("NATS payload differs from deterministic event bytes")
	}
	after, err := stream.Info(context.Background())
	if err != nil {
		t.Fatalf("reload Saved source stream info: %v", err)
	}
	if after.State.Msgs != before.State.Msgs+1 {
		t.Fatalf("stable Guide message ID added %d messages, want one", after.State.Msgs-before.State.Msgs)
	}
}
