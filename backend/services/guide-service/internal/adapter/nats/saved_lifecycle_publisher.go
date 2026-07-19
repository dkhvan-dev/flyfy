package natsadapter

import (
	"context"
	"fmt"
	"strings"
	"sync"
	"time"

	"github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/jetstream"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/timestamppb"

	"kz/inflap/backend/services/guide-service/internal/domain/model"
	contentv1 "kz/inflap/proto/gen/go/content/v1"
)

const (
	DefaultSavedLifecycleSubject = "saved.source.guide.lifecycle.v1"
	SavedSourceStreamName        = "SAVED_SOURCE"
	savedSourceStreamMaxBytes    = 4 * 1024 * 1024 * 1024
)

type SavedLifecyclePublisher struct {
	connection  *nats.Conn
	jetStream   jetstream.JetStream
	subject     string
	streamMu    sync.Mutex
	streamReady bool
}

func NewSavedLifecyclePublisher(
	ctx context.Context,
	connection *nats.Conn,
	subject string,
) (*SavedLifecyclePublisher, error) {
	if connection == nil || connection.IsClosed() {
		return nil, model.ErrInvalidSavedLifecycleState
	}
	subject = strings.TrimSpace(subject)
	if subject == "" || !strings.HasPrefix(subject, "saved.source.") ||
		strings.ContainsAny(subject, " \t\r\n*>") {
		return nil, model.ErrInvalidSavedLifecycleState
	}
	js, err := jetstream.New(connection)
	if err != nil {
		return nil, fmt.Errorf("create Saved lifecycle JetStream context: %w", err)
	}
	publisher := &SavedLifecyclePublisher{
		connection: connection,
		jetStream:  js,
		subject:    subject,
	}
	if !connection.IsConnected() {
		return publisher, nil
	}
	if err = publisher.ensureStream(ctx); err != nil {
		if !connection.IsConnected() {
			return publisher, nil
		}
		return nil, err
	}
	return publisher, nil
}

func (p *SavedLifecyclePublisher) ensureStream(ctx context.Context) error {
	if p == nil || p.jetStream == nil || p.connection == nil || p.connection.IsClosed() {
		return model.ErrInvalidSavedLifecycleState
	}
	p.streamMu.Lock()
	defer p.streamMu.Unlock()
	if p.streamReady {
		return nil
	}
	streamCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()
	if _, err := p.jetStream.CreateOrUpdateStream(streamCtx, jetstream.StreamConfig{
		Name:       SavedSourceStreamName,
		Subjects:   []string{"saved.source.>"},
		Storage:    jetstream.FileStorage,
		Retention:  jetstream.LimitsPolicy,
		MaxAge:     14 * 24 * time.Hour,
		MaxBytes:   savedSourceStreamMaxBytes,
		Discard:    jetstream.DiscardOld,
		Duplicates: 10 * time.Minute,
	}); err != nil {
		return fmt.Errorf("create/update Saved lifecycle stream: %w", err)
	}
	p.streamReady = true
	return nil
}

func (p *SavedLifecyclePublisher) markStreamUnready() {
	if p == nil {
		return
	}
	p.streamMu.Lock()
	p.streamReady = false
	p.streamMu.Unlock()
}

func (p *SavedLifecyclePublisher) PublishSavedLifecycle(
	ctx context.Context,
	message *model.SavedLifecycleOutboxMessage,
) error {
	if p == nil || p.jetStream == nil || strings.TrimSpace(p.subject) == "" || message == nil {
		return model.ErrInvalidSavedLifecycleState
	}
	if err := p.ensureStream(ctx); err != nil {
		return err
	}
	payload, err := EncodeSavedLifecycleEvent(message)
	if err != nil {
		return err
	}
	if _, err = p.jetStream.Publish(
		ctx,
		p.subject,
		payload,
		jetstream.WithMsgID(message.EventID.String()),
	); err != nil {
		p.markStreamUnready()
		return fmt.Errorf("publish Saved guide lifecycle event: %w", err)
	}
	return nil
}

func EncodeSavedLifecycleEvent(message *model.SavedLifecycleOutboxMessage) ([]byte, error) {
	if message == nil {
		return nil, model.ErrInvalidSavedLifecycleState
	}
	if err := message.Validate(); err != nil {
		return nil, err
	}
	kind, ok := savedLifecycleProtoKind(message.Kind)
	if !ok {
		return nil, model.ErrInvalidSavedLifecycleState
	}
	visibility, ok := savedLifecycleProtoVisibility(message.Visibility)
	if !ok {
		return nil, model.ErrInvalidSavedLifecycleState
	}
	occurredAt := timestamppb.New(message.OccurredAt.UTC())
	if err := occurredAt.CheckValid(); err != nil {
		return nil, model.ErrInvalidSavedLifecycleState
	}

	event := &contentv1.SavedSourceLifecycleEvent{
		EventId: message.EventID.String(),
		Kind:    kind,
		Target: &contentv1.SavedTarget{
			EntityType: contentv1.SavedEntityType_SAVED_ENTITY_TYPE_GUIDE,
			EntityId:   message.TargetUserID.String(),
		},
		Revisions: &contentv1.SavedSourceRevisions{
			SourceRevision:     message.SourceRevision,
			ProjectionRevision: message.ProjectionRevision,
			VisibilityRevision: message.VisibilityRevision,
		},
		OccurredAt: occurredAt,
		Visibility: visibility,
	}
	if len(message.PublicProjection) > 0 {
		if message.Visibility != model.SavedLifecycleVisibilityPublic {
			return nil, model.ErrInvalidSavedLifecycleState
		}
		projection := &contentv1.SavedPublicCardProjection{}
		if err := proto.Unmarshal(message.PublicProjection, projection); err != nil {
			return nil, model.ErrInvalidSavedLifecycleState
		}
		event.PublicProjection = projection
	}
	return proto.MarshalOptions{Deterministic: true}.Marshal(event)
}

func savedLifecycleProtoKind(
	kind model.SavedLifecycleEventKind,
) (contentv1.SavedLifecycleEventKind, bool) {
	switch kind {
	case model.SavedLifecycleEventPublished:
		return contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_PUBLISHED, true
	case model.SavedLifecycleEventUpdated:
		return contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_UPDATED, true
	case model.SavedLifecycleEventUnavailable:
		return contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_UNAVAILABLE, true
	case model.SavedLifecycleEventDeleted:
		return contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_DELETED, true
	case model.SavedLifecycleEventVisibilityChanged:
		return contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_VISIBILITY_CHANGED, true
	default:
		return contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_UNSPECIFIED, false
	}
}

func savedLifecycleProtoVisibility(
	visibility model.SavedLifecycleVisibility,
) (contentv1.SavedTargetVisibility, bool) {
	switch visibility {
	case model.SavedLifecycleVisibilityPublic:
		return contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_PUBLIC, true
	case model.SavedLifecycleVisibilityUnavailable:
		return contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_UNAVAILABLE, true
	case model.SavedLifecycleVisibilityDeleted:
		return contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_DELETED, true
	default:
		return contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_UNSPECIFIED, false
	}
}
