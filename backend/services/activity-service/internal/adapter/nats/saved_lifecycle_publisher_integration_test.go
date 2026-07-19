package nats

import (
	"context"
	"os"
	"slices"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	gonats "github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/jetstream"
	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/types/known/timestamppb"

	"kz/inflap/backend/services/activity-service/internal/domain/model"
	contentv1 "kz/inflap/proto/gen/go/content/v1"
)

const activitySavedLifecycleNATSTestURLEnv = "ACTIVITY_SAVED_LIFECYCLE_NATS_TEST_URL"

func TestActivitySavedLifecyclePublisherUsesSharedJetStreamContract(t *testing.T) {
	url := strings.TrimSpace(os.Getenv(activitySavedLifecycleNATSTestURLEnv))
	if url == "" {
		t.Skip(activitySavedLifecycleNATSTestURLEnv + " is not set")
	}

	connection, err := gonats.Connect(url, gonats.Timeout(3*time.Second))
	if err != nil {
		t.Fatalf("connect NATS: %v", err)
	}
	defer connection.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	publisher, err := NewActivitySavedLifecyclePublisher(connection)
	if err != nil {
		t.Fatalf("NewActivitySavedLifecyclePublisher() error = %v", err)
	}
	if err = publisher.ensureStream(ctx); err != nil {
		t.Fatalf("ensureStream() error = %v", err)
	}
	stream, err := publisher.js.Stream(ctx, activitySavedLifecycleStream)
	if err != nil {
		t.Fatalf("load shared Saved source stream: %v", err)
	}
	info, err := stream.Info(ctx)
	if err != nil {
		t.Fatalf("load shared Saved source stream info: %v", err)
	}
	config := info.Config
	if !slices.Equal(config.Subjects, []string{activitySavedLifecycleSubjectPattern}) ||
		config.Storage != jetstream.FileStorage ||
		config.Retention != jetstream.LimitsPolicy ||
		config.MaxAge != 14*24*time.Hour ||
		config.MaxBytes != activitySavedLifecycleStreamMaxBytes ||
		config.Discard != jetstream.DiscardOld ||
		config.Duplicates != 10*time.Minute {
		t.Fatalf("shared Saved source stream config = %+v", config)
	}

	eventID := uuid.New()
	activityID := uuid.New()
	occurredAt := time.Now().UTC()
	payload, err := protojson.Marshal(&contentv1.SavedSourceLifecycleEvent{
		EventId: eventID.String(),
		Kind:    contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_UNAVAILABLE,
		Target: &contentv1.SavedTarget{
			EntityType: contentv1.SavedEntityType_SAVED_ENTITY_TYPE_ACTIVITY,
			EntityId:   activityID.String(),
		},
		Revisions: &contentv1.SavedSourceRevisions{
			SourceRevision:     1,
			ProjectionRevision: 1,
			VisibilityRevision: 1,
		},
		OccurredAt: timestamppb.New(occurredAt),
		Visibility: contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_UNAVAILABLE,
	})
	if err != nil {
		t.Fatalf("marshal lifecycle payload: %v", err)
	}
	event := model.ActivitySavedLifecycleOutboxEvent{
		ID: eventID, ActivityID: activityID,
		Subject: model.ActivitySavedLifecycleSubjectV1, SchemaVersion: 1,
		Kind: model.ActivitySavedLifecycleUnavailable, Visibility: "UNAVAILABLE",
		SourceRevision: 1, ProjectionRevision: 1, VisibilityRevision: 1,
		Payload: payload, OccurredAt: occurredAt,
	}
	for range 2 {
		if err = publisher.PublishActivitySavedLifecycle(ctx, event); err != nil {
			t.Fatalf("PublishActivitySavedLifecycle() error = %v", err)
		}
	}
	after, err := stream.Info(ctx)
	if err != nil {
		t.Fatalf("reload shared Saved source stream info: %v", err)
	}
	if after.State.Msgs != info.State.Msgs+1 {
		t.Fatalf("stable Activity message ID added %d messages, want one", after.State.Msgs-info.State.Msgs)
	}
}
