package nats

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"time"

	gonats "github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/jetstream"
	"github.com/rs/zerolog/log"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/timestamppb"

	"kz/inflap/backend/services/place-service/internal/domain/model"
	contentv1 "kz/inflap/proto/gen/go/content/v1"
)

const (
	SavedSourceStreamName        = "SAVED_SOURCE"
	SavedSourceSubjectPattern    = "saved.source.>"
	DefaultSavedLifecycleSubject = "saved.source.attraction.lifecycle.v1"
	SavedSourceStreamMaxAge      = 14 * 24 * time.Hour
	SavedSourceStreamMaxBytes    = int64(4 * 1024 * 1024 * 1024)
	SavedSourceDuplicateWindow   = 10 * time.Minute
)

type SavedLifecyclePublisher struct {
	jetStream   jetstream.JetStream
	streamMu    sync.Mutex
	streamReady bool
}

func NewSavedLifecyclePublisher(
	ctx context.Context,
	connection *gonats.Conn,
) (*SavedLifecyclePublisher, error) {
	if connection == nil || connection.IsClosed() {
		return nil, errors.New("NATS connection is unavailable")
	}
	js, err := jetstream.New(connection)
	if err != nil {
		return nil, fmt.Errorf("create Saved lifecycle JetStream context: %w", err)
	}
	publisher := &SavedLifecyclePublisher{jetStream: js}
	if !connection.IsConnected() {
		log.Warn().Msg("Saved lifecycle stream provisioning deferred until NATS reconnects")
		return publisher, nil
	}
	if err = publisher.ensureStream(ctx); err != nil {
		if !connection.IsConnected() {
			log.Warn().Err(err).Msg("Saved lifecycle stream provisioning deferred after NATS disconnect")
			return publisher, nil
		}
		return nil, err
	}
	return publisher, nil
}

func (publisher *SavedLifecyclePublisher) PublishSavedLifecycle(
	ctx context.Context,
	event model.SavedLifecycleEvent,
) error {
	return publisher.publish(ctx, event.EventID.String(), event)
}

func (publisher *SavedLifecyclePublisher) publish(
	ctx context.Context,
	messageID string,
	event model.SavedLifecycleEvent,
) error {
	if publisher == nil || publisher.jetStream == nil {
		return errors.New("Saved lifecycle publisher is unavailable")
	}
	if err := publisher.ensureStream(ctx); err != nil {
		return err
	}
	payload, err := MarshalSavedLifecycleEvent(event)
	if err != nil {
		return err
	}
	if _, err = publisher.jetStream.Publish(
		ctx,
		DefaultSavedLifecycleSubject,
		payload,
		jetstream.WithMsgID(messageID),
	); err != nil {
		publisher.markStreamUnready()
		return fmt.Errorf("publish Saved lifecycle event: %w", err)
	}
	return nil
}

func (publisher *SavedLifecyclePublisher) ensureStream(ctx context.Context) error {
	if publisher == nil || publisher.jetStream == nil {
		return errors.New("Saved lifecycle publisher is unavailable")
	}
	publisher.streamMu.Lock()
	defer publisher.streamMu.Unlock()
	if publisher.streamReady {
		return nil
	}
	if _, err := publisher.jetStream.CreateOrUpdateStream(ctx, savedSourceStreamConfig()); err != nil {
		return fmt.Errorf("create or update Saved lifecycle stream: %w", err)
	}
	publisher.streamReady = true
	return nil
}

func savedSourceStreamConfig() jetstream.StreamConfig {
	return jetstream.StreamConfig{
		Name:       SavedSourceStreamName,
		Subjects:   []string{SavedSourceSubjectPattern},
		Storage:    jetstream.FileStorage,
		Retention:  jetstream.LimitsPolicy,
		MaxAge:     SavedSourceStreamMaxAge,
		MaxBytes:   SavedSourceStreamMaxBytes,
		Discard:    jetstream.DiscardOld,
		Duplicates: SavedSourceDuplicateWindow,
	}
}

func (publisher *SavedLifecyclePublisher) markStreamUnready() {
	if publisher == nil {
		return
	}
	publisher.streamMu.Lock()
	publisher.streamReady = false
	publisher.streamMu.Unlock()
}

func MarshalSavedLifecycleEvent(event model.SavedLifecycleEvent) ([]byte, error) {
	if err := event.Validate(); err != nil {
		return nil, err
	}
	occurredAt := timestamppb.New(event.OccurredAt.UTC())
	if err := occurredAt.CheckValid(); err != nil {
		return nil, fmt.Errorf("invalid Saved lifecycle occurred_at: %w", err)
	}

	envelope := &contentv1.SavedSourceLifecycleEvent{
		EventId: event.EventID.String(),
		Kind:    toProtoSavedLifecycleEventKind(event.EventType),
		Target: &contentv1.SavedTarget{
			EntityType: contentv1.SavedEntityType_SAVED_ENTITY_TYPE_ATTRACTION,
			EntityId:   event.EntityID.String(),
		},
		Revisions: &contentv1.SavedSourceRevisions{
			SourceRevision:     event.SourceRevision,
			ProjectionRevision: event.ProjectionRevision,
			VisibilityRevision: event.VisibilityRevision,
		},
		OccurredAt: occurredAt,
		Visibility: toProtoSavedLifecycleVisibility(event.Visibility),
		// PUBLIC projection is optional. Omitting it keeps outbox rows bounded and
		// makes every non-PUBLIC envelope structurally payload-free.
		PublicProjection: nil,
	}
	if envelope.Kind == contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_UNSPECIFIED ||
		envelope.Visibility == contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_UNSPECIFIED {
		return nil, model.ErrInvalidSavedLifecycleEvent
	}
	return proto.MarshalOptions{Deterministic: true}.Marshal(envelope)
}

func toProtoSavedLifecycleEventKind(
	eventType model.SavedLifecycleEventType,
) contentv1.SavedLifecycleEventKind {
	switch eventType {
	case model.SavedLifecyclePublished:
		return contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_PUBLISHED
	case model.SavedLifecycleUpdated:
		return contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_UPDATED
	case model.SavedLifecycleUnavailable:
		return contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_UNAVAILABLE
	case model.SavedLifecycleDeleted:
		return contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_DELETED
	case model.SavedLifecycleVisibilityChanged:
		return contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_VISIBILITY_CHANGED
	default:
		return contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_UNSPECIFIED
	}
}

func toProtoSavedLifecycleVisibility(
	visibility model.SavedLifecycleVisibility,
) contentv1.SavedTargetVisibility {
	switch visibility {
	case model.SavedLifecycleVisibilityPublic:
		return contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_PUBLIC
	case model.SavedLifecycleVisibilityUnavailable:
		return contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_UNAVAILABLE
	case model.SavedLifecycleVisibilityDeleted:
		return contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_DELETED
	case model.SavedLifecycleVisibilityRestricted:
		return contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_RESTRICTED
	default:
		return contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_UNSPECIFIED
	}
}
