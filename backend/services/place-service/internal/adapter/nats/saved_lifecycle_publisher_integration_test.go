package nats

import (
	"bytes"
	"context"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	gonats "github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/jetstream"
)

func TestSavedLifecyclePublisherUsesPreExistingSharedStreamAndCanonicalSubject(t *testing.T) {
	url := strings.TrimSpace(os.Getenv("PLACE_SERVICE_NATS_TEST_URL"))
	if url == "" {
		t.Skip("set PLACE_SERVICE_NATS_TEST_URL to run Saved lifecycle JetStream integration test")
	}

	connection, err := gonats.Connect(url, gonats.Timeout(3*time.Second))
	if err != nil {
		t.Fatalf("connect NATS: %v", err)
	}
	defer connection.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	js, err := jetstream.New(connection)
	if err != nil {
		t.Fatalf("jetstream.New() error = %v", err)
	}
	activityCompatible := jetstream.StreamConfig{
		Name:       "SAVED_SOURCE",
		Subjects:   []string{"saved.source.>"},
		Storage:    jetstream.FileStorage,
		Retention:  jetstream.LimitsPolicy,
		MaxAge:     14 * 24 * time.Hour,
		MaxBytes:   4 * 1024 * 1024 * 1024,
		Discard:    jetstream.DiscardOld,
		Duplicates: 10 * time.Minute,
	}
	stream, err := js.CreateOrUpdateStream(ctx, activityCompatible)
	if err != nil {
		t.Fatalf("provision Activity-compatible shared stream: %v", err)
	}
	before, err := stream.Info(ctx)
	if err != nil {
		t.Fatalf("load pre-existing shared stream: %v", err)
	}
	assertSavedSourceStreamConfig(t, before.Config)

	publisher, err := NewSavedLifecyclePublisher(ctx, connection)
	if err != nil {
		t.Fatalf("NewSavedLifecyclePublisher() error = %v", err)
	}
	event := lifecyclePublisherTestEvent("content.updated", "PUBLIC")
	event.EventID = uuid.New()
	wantPayload, err := MarshalSavedLifecycleEvent(event)
	if err != nil {
		t.Fatalf("MarshalSavedLifecycleEvent() error = %v", err)
	}
	for range 2 {
		if err = publisher.PublishSavedLifecycle(ctx, event); err != nil {
			t.Fatalf("PublishSavedLifecycle() error = %v", err)
		}
	}

	after, err := stream.Info(ctx)
	if err != nil {
		t.Fatalf("reload shared stream: %v", err)
	}
	assertSavedSourceStreamConfig(t, after.Config)
	if after.State.Msgs != before.State.Msgs+1 {
		t.Fatalf(
			"immutable redelivery added %d messages, want exactly one",
			after.State.Msgs-before.State.Msgs,
		)
	}
	message, err := stream.GetLastMsgForSubject(ctx, DefaultSavedLifecycleSubject)
	if err != nil {
		t.Fatalf("load canonical attraction lifecycle event: %v", err)
	}
	if !bytes.Equal(message.Data, wantPayload) {
		t.Fatal("canonical subject payload differs from deterministic envelope")
	}
}

func assertSavedSourceStreamConfig(t *testing.T, config jetstream.StreamConfig) {
	t.Helper()
	if config.Name != SavedSourceStreamName ||
		len(config.Subjects) != 1 ||
		config.Subjects[0] != SavedSourceSubjectPattern ||
		config.Storage != jetstream.FileStorage ||
		config.Retention != jetstream.LimitsPolicy ||
		config.MaxAge != SavedSourceStreamMaxAge ||
		config.MaxBytes != SavedSourceStreamMaxBytes ||
		config.Discard != jetstream.DiscardOld ||
		config.Duplicates != SavedSourceDuplicateWindow {
		t.Fatalf("incompatible SAVED_SOURCE stream config: %+v", config)
	}
}
