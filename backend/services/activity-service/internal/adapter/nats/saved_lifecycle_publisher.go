package nats

import (
	"context"
	"fmt"
	"sync"
	"time"

	gonats "github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/jetstream"

	"kz/inflap/backend/services/activity-service/internal/adapter/savedcontract"
	"kz/inflap/backend/services/activity-service/internal/domain/model"
)

const (
	activitySavedLifecycleStream         = "SAVED_SOURCE"
	activitySavedLifecycleSubjectPattern = "saved.source.>"
	activitySavedLifecycleStreamMaxBytes = 4 * 1024 * 1024 * 1024
)

type ActivitySavedLifecyclePublisher struct {
	js          jetstream.JetStream
	streamMu    sync.Mutex
	streamReady bool
}

func NewActivitySavedLifecyclePublisher(
	connection *gonats.Conn,
) (*ActivitySavedLifecyclePublisher, error) {
	if connection == nil {
		return nil, fmt.Errorf("NATS connection is required")
	}
	js, err := jetstream.New(connection)
	if err != nil {
		return nil, fmt.Errorf("create activity Saved lifecycle JetStream context: %w", err)
	}
	return &ActivitySavedLifecyclePublisher{js: js}, nil
}

func (publisher *ActivitySavedLifecyclePublisher) PublishActivitySavedLifecycle(
	ctx context.Context,
	event model.ActivitySavedLifecycleOutboxEvent,
) error {
	if publisher == nil || publisher.js == nil {
		return fmt.Errorf("activity Saved lifecycle publisher is unavailable")
	}
	payload, err := savedcontract.EncodeActivityLifecycleBinary(event)
	if err != nil {
		return fmt.Errorf("invalid activity Saved lifecycle event")
	}
	if err := publisher.ensureStream(ctx); err != nil {
		return err
	}
	if _, err := publisher.js.Publish(
		ctx,
		event.Subject,
		payload,
		jetstream.WithMsgID(event.ID.String()),
	); err != nil {
		publisher.streamMu.Lock()
		publisher.streamReady = false
		publisher.streamMu.Unlock()
		return fmt.Errorf("publish activity Saved lifecycle event: %w", err)
	}
	return nil
}

func (publisher *ActivitySavedLifecyclePublisher) ensureStream(ctx context.Context) error {
	publisher.streamMu.Lock()
	defer publisher.streamMu.Unlock()
	if publisher.streamReady {
		return nil
	}
	if _, err := publisher.js.CreateOrUpdateStream(ctx, jetstream.StreamConfig{
		Name:       activitySavedLifecycleStream,
		Subjects:   []string{activitySavedLifecycleSubjectPattern},
		Storage:    jetstream.FileStorage,
		Retention:  jetstream.LimitsPolicy,
		MaxAge:     14 * 24 * time.Hour,
		MaxBytes:   activitySavedLifecycleStreamMaxBytes,
		Discard:    jetstream.DiscardOld,
		Duplicates: 10 * time.Minute,
	}); err != nil {
		return fmt.Errorf("ensure activity Saved lifecycle stream: %w", err)
	}
	publisher.streamReady = true
	return nil
}
