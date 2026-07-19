package natsadapter

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"slices"
	"strings"
	"sync"
	"time"

	gonats "github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/jetstream"

	"kz/inflap/backend/services/saved-service/internal/app/savedoutbox"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

const (
	SavedDomainStreamName       = "SAVED_DOMAIN"
	SavedDomainSubjectV1        = "saved.domain.lifecycle.v1"
	SavedDomainContentType      = "application/json"
	SavedDomainStreamMaxAge     = 14 * 24 * time.Hour
	SavedDomainDuplicateWindow  = 10 * time.Minute
	SavedDomainStreamMaxMsgs    = 10_000_000
	SavedDomainStreamMaxBytes   = 2 * 1024 * 1024 * 1024
	SavedDomainStreamMaxMsgSize = 2 * 1024
	SavedDomainMaxConsumers     = 64
)

var (
	errSavedOutboxPublisherUnavailable = errors.New("Saved outbox publisher is unavailable")
	errSavedDomainStreamContract       = errors.New("SAVED_DOMAIN stream contract mismatch")
)

type savedDomainBroker interface {
	EnsureStream(context.Context, jetstream.StreamConfig) (jetstream.StreamConfig, error)
	Publish(context.Context, *gonats.Msg) (*jetstream.PubAck, error)
}

type jetStreamSavedDomainBroker struct {
	jetStream jetstream.JetStream
}

func (broker *jetStreamSavedDomainBroker) EnsureStream(
	ctx context.Context,
	config jetstream.StreamConfig,
) (jetstream.StreamConfig, error) {
	stream, err := broker.jetStream.CreateOrUpdateStream(ctx, config)
	if err != nil {
		return jetstream.StreamConfig{}, fmt.Errorf("provision SAVED_DOMAIN stream: %w", err)
	}
	if stream == nil {
		return jetstream.StreamConfig{}, errSavedDomainStreamContract
	}
	info, err := stream.Info(ctx)
	if err != nil {
		return jetstream.StreamConfig{}, fmt.Errorf("read SAVED_DOMAIN stream contract: %w", err)
	}
	if info == nil {
		return jetstream.StreamConfig{}, errSavedDomainStreamContract
	}
	return info.Config, nil
}

func (broker *jetStreamSavedDomainBroker) Publish(
	ctx context.Context,
	message *gonats.Msg,
) (*jetstream.PubAck, error) {
	return broker.jetStream.PublishMsg(ctx, message)
}

// SavedOutboxPublisher publishes only the privacy-safe Saved domain contract.
// Stream provisioning is serialized; publishing itself remains concurrent.
type SavedOutboxPublisher struct {
	broker      savedDomainBroker
	streamSpec  jetstream.StreamConfig
	streamMu    sync.Mutex
	streamReady bool
}

func NewSavedOutboxPublisher(
	connection *gonats.Conn,
	streamReplicas int,
) (*SavedOutboxPublisher, error) {
	if connection == nil || connection.IsClosed() {
		return nil, errSavedOutboxPublisherUnavailable
	}
	jetStream, err := jetstream.New(connection)
	if err != nil {
		return nil, fmt.Errorf("create Saved outbox JetStream context: %w", err)
	}
	return newSavedOutboxPublisher(
		&jetStreamSavedDomainBroker{jetStream: jetStream},
		streamReplicas,
	)
}

func newSavedOutboxPublisher(
	broker savedDomainBroker,
	streamReplicas int,
) (*SavedOutboxPublisher, error) {
	if broker == nil || !validStreamReplicas(streamReplicas) {
		return nil, errSavedOutboxPublisherUnavailable
	}
	return &SavedOutboxPublisher{
		broker:     broker,
		streamSpec: savedDomainStreamConfig(streamReplicas),
	}, nil
}

func (publisher *SavedOutboxPublisher) EnsureStream(ctx context.Context) error {
	if ctx == nil || publisher == nil || publisher.broker == nil {
		return errSavedOutboxPublisherUnavailable
	}
	if err := ctx.Err(); err != nil {
		return err
	}

	publisher.streamMu.Lock()
	defer publisher.streamMu.Unlock()
	if publisher.streamReady {
		return nil
	}

	actual, err := publisher.broker.EnsureStream(ctx, cloneStreamConfig(publisher.streamSpec))
	if err != nil {
		return err
	}
	if !savedDomainStreamConfigMatches(actual, publisher.streamSpec) {
		return errSavedDomainStreamContract
	}
	publisher.streamReady = true
	return nil
}

func (publisher *SavedOutboxPublisher) Publish(
	ctx context.Context,
	event savedoutbox.Event,
) error {
	if ctx == nil || publisher == nil || publisher.broker == nil {
		return errSavedOutboxPublisherUnavailable
	}
	if err := ctx.Err(); err != nil {
		return err
	}
	payload, err := encodeSavedDomainEvent(event)
	if err != nil {
		return err
	}
	if err = publisher.EnsureStream(ctx); err != nil {
		return err
	}

	message := gonats.NewMsg(SavedDomainSubjectV1)
	message.Header = make(gonats.Header, 3)
	message.Header.Set("Content-Type", SavedDomainContentType)
	message.Header.Set(jetstream.MsgIDHeader, event.EventID.String())
	message.Header.Set(jetstream.ExpectedStreamHeader, SavedDomainStreamName)
	message.Data = payload

	ack, err := publisher.broker.Publish(ctx, message)
	if err != nil {
		publisher.invalidateStream()
		return fmt.Errorf("publish Saved domain event: %w", err)
	}
	if ack == nil || ack.Stream != SavedDomainStreamName || ack.Sequence == 0 {
		publisher.invalidateStream()
		return errors.New("publish Saved domain event: invalid JetStream acknowledgement")
	}
	return nil
}

func (publisher *SavedOutboxPublisher) invalidateStream() {
	publisher.streamMu.Lock()
	publisher.streamReady = false
	publisher.streamMu.Unlock()
}

type savedDomainEventV1 struct {
	EventID       string                `json:"event_id"`
	Kind          savedoutbox.EventKind `json:"kind"`
	EntityType    domain.EntityType     `json:"entity_type"`
	OccurredAt    time.Time             `json:"occurred_at"`
	SchemaVersion uint16                `json:"schema_version"`
}

func encodeSavedDomainEvent(event savedoutbox.Event) ([]byte, error) {
	if err := event.Validate(); err != nil {
		return nil, errors.New("invalid Saved domain event")
	}
	payload, err := json.Marshal(savedDomainEventV1{
		EventID:       event.EventID.String(),
		Kind:          event.Kind,
		EntityType:    event.EntityType,
		OccurredAt:    event.OccurredAt.UTC(),
		SchemaVersion: event.SchemaVersion,
	})
	if err != nil {
		return nil, errors.New("encode Saved domain event")
	}
	if len(payload) == 0 || len(payload) > SavedDomainStreamMaxMsgSize {
		return nil, errors.New("Saved domain event payload exceeds contract bounds")
	}
	return payload, nil
}

func savedDomainStreamConfig(replicas int) jetstream.StreamConfig {
	return jetstream.StreamConfig{
		Name:                 SavedDomainStreamName,
		Description:          "saved-service privacy-safe domain events v1",
		Subjects:             []string{SavedDomainSubjectV1},
		Retention:            jetstream.LimitsPolicy,
		MaxConsumers:         SavedDomainMaxConsumers,
		MaxMsgs:              SavedDomainStreamMaxMsgs,
		MaxBytes:             SavedDomainStreamMaxBytes,
		Discard:              jetstream.DiscardOld,
		MaxAge:               SavedDomainStreamMaxAge,
		MaxMsgsPerSubject:    SavedDomainStreamMaxMsgs,
		MaxMsgSize:           SavedDomainStreamMaxMsgSize,
		Storage:              jetstream.FileStorage,
		Replicas:             replicas,
		NoAck:                false,
		Duplicates:           SavedDomainDuplicateWindow,
		DiscardNewPerSubject: false,
		Sealed:               false,
		AllowRollup:          false,
		AllowDirect:          false,
	}
}

func savedDomainStreamConfigMatches(
	actual jetstream.StreamConfig,
	expected jetstream.StreamConfig,
) bool {
	return actual.Name == expected.Name &&
		actual.Description == expected.Description &&
		slices.Equal(actual.Subjects, expected.Subjects) &&
		actual.Retention == expected.Retention &&
		actual.MaxConsumers == expected.MaxConsumers &&
		actual.MaxMsgs == expected.MaxMsgs &&
		actual.MaxBytes == expected.MaxBytes &&
		actual.Discard == expected.Discard &&
		actual.MaxAge == expected.MaxAge &&
		actual.MaxMsgsPerSubject == expected.MaxMsgsPerSubject &&
		actual.MaxMsgSize == expected.MaxMsgSize &&
		actual.Storage == expected.Storage &&
		actual.Replicas == expected.Replicas &&
		!actual.NoAck &&
		actual.Duplicates == expected.Duplicates &&
		actual.FirstSeq == expected.FirstSeq &&
		!actual.DiscardNewPerSubject &&
		!actual.Sealed &&
		!actual.DenyDelete &&
		!actual.DenyPurge &&
		!actual.AllowRollup &&
		actual.Compression == jetstream.NoCompression &&
		actual.Placement == nil &&
		actual.Mirror == nil &&
		len(actual.Sources) == 0 &&
		actual.SubjectTransform == nil &&
		actual.RePublish == nil &&
		!actual.AllowDirect &&
		!actual.MirrorDirect &&
		actual.ConsumerLimits == (jetstream.StreamConsumerLimits{}) &&
		validServerManagedMetadata(actual.Metadata) &&
		actual.Template == "" &&
		!actual.AllowMsgTTL &&
		actual.SubjectDeleteMarkerTTL == 0 &&
		!actual.AllowMsgCounter &&
		!actual.AllowAtomicPublish &&
		!actual.AllowMsgSchedules &&
		actual.PersistMode == jetstream.DefaultPersistMode
}

func validServerManagedMetadata(metadata map[string]string) bool {
	for key := range metadata {
		if !strings.HasPrefix(key, "_nats.") {
			return false
		}
	}
	return true
}

func cloneStreamConfig(config jetstream.StreamConfig) jetstream.StreamConfig {
	config.Subjects = append([]string(nil), config.Subjects...)
	return config
}

func validStreamReplicas(replicas int) bool {
	return replicas == 1 || replicas == 3 || replicas == 5
}
