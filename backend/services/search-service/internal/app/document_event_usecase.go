package app

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"kz/inflap/backend/services/search-service/internal/domain/model"
)

const (
	DocumentEventTypeUpsert = "search_document_upsert"
	DocumentEventTypeDelete = "search_document_delete"
)

var ErrInvalidDocumentEvent = errors.New("invalid document event")

type DocumentEventRepository interface {
	EnqueueDocumentEvent(ctx context.Context, event model.SearchDocumentEvent) error
	ListDueDocumentEvents(ctx context.Context, limit int, now time.Time) ([]model.SearchDocumentEvent, error)
	MarkDocumentEventDelivered(ctx context.Context, eventID string, deliveredAt time.Time) error
	MarkDocumentEventRetry(ctx context.Context, eventID string, reason string, nextAttemptAt time.Time) error
	MarkDocumentEventDead(ctx context.Context, eventID string, reason string, deadAt time.Time) error
}

type DocumentEventUseCase struct {
	events   DocumentEventRepository
	indexing *IndexingUseCase
}

func NewDocumentEventUseCase(events DocumentEventRepository, indexing *IndexingUseCase) *DocumentEventUseCase {
	return &DocumentEventUseCase{events: events, indexing: indexing}
}

type EnqueueDocumentEventInput struct {
	SourceService string
	SourceEventID string
	AggregateType string
	AggregateID   string
	EventType     string
	Payload       json.RawMessage
}

type ProcessDocumentEventOptions struct {
	BatchSize   int
	MaxAttempts int
	BaseBackoff time.Duration
	Now         time.Time
}

type DocumentEventProcessStats struct {
	Scanned            int
	Delivered          int
	RetryScheduled     int
	Dead               int
	FailedEventsTotal  int
	MaxIndexLagSeconds float64
}

func (u *DocumentEventUseCase) EnqueueDocumentEvent(ctx context.Context, input EnqueueDocumentEventInput) error {
	if u == nil || u.events == nil {
		return fmt.Errorf("%w: repository is required", ErrInvalidDocumentEvent)
	}
	event := model.SearchDocumentEvent{
		SourceService: strings.TrimSpace(input.SourceService),
		SourceEventID: strings.TrimSpace(input.SourceEventID),
		AggregateType: strings.TrimSpace(input.AggregateType),
		AggregateID:   strings.TrimSpace(input.AggregateID),
		EventType:     strings.TrimSpace(input.EventType),
		Payload:       cloneRawMessage(input.Payload),
		CreatedAt:     time.Now().UTC(),
	}
	if err := validateDocumentEvent(event); err != nil {
		return err
	}
	return u.events.EnqueueDocumentEvent(ctx, event)
}

func (u *DocumentEventUseCase) ProcessDueDocumentEvents(
	ctx context.Context,
	options ProcessDocumentEventOptions,
) (DocumentEventProcessStats, error) {
	if u == nil || u.events == nil || u.indexing == nil {
		return DocumentEventProcessStats{}, fmt.Errorf("%w: processor dependencies are required", ErrInvalidDocumentEvent)
	}
	options = normalizeDocumentEventProcessOptions(options)
	events, err := u.events.ListDueDocumentEvents(ctx, options.BatchSize, options.Now)
	if err != nil {
		return DocumentEventProcessStats{}, err
	}

	stats := DocumentEventProcessStats{Scanned: len(events)}
	for _, event := range events {
		stats.ObserveIndexLag(event.CreatedAt, options.Now)
		if err = u.processOneDocumentEvent(ctx, event); err != nil {
			nextAttempt := event.AttemptCount + 1
			reason := trimEventError(err)
			if nextAttempt >= options.MaxAttempts {
				if markErr := u.events.MarkDocumentEventDead(ctx, event.ID, reason, options.Now); markErr != nil {
					return stats, markErr
				}
				stats.Dead++
				stats.FailedEventsTotal++
				continue
			}
			nextAttemptAt := options.Now.Add(options.BaseBackoff * time.Duration(nextAttempt))
			if markErr := u.events.MarkDocumentEventRetry(ctx, event.ID, reason, nextAttemptAt); markErr != nil {
				return stats, markErr
			}
			stats.RetryScheduled++
			continue
		}
		if err = u.events.MarkDocumentEventDelivered(ctx, event.ID, options.Now); err != nil {
			return stats, err
		}
		stats.Delivered++
	}

	return stats, nil
}

func (s *DocumentEventProcessStats) ObserveIndexLag(createdAt time.Time, now time.Time) {
	if s == nil || createdAt.IsZero() || now.IsZero() {
		return
	}
	lag := now.Sub(createdAt).Seconds()
	if lag < 0 {
		lag = 0
	}
	if lag > s.MaxIndexLagSeconds {
		s.MaxIndexLagSeconds = lag
	}
}

func (u *DocumentEventUseCase) processOneDocumentEvent(ctx context.Context, event model.SearchDocumentEvent) error {
	switch strings.TrimSpace(event.EventType) {
	case DocumentEventTypeUpsert:
		var input IndexDocumentInput
		if err := json.Unmarshal(event.Payload, &input); err != nil {
			return fmt.Errorf("decode upsert payload: %w", err)
		}
		return u.indexing.UpsertDocument(ctx, input)
	case DocumentEventTypeDelete:
		var input DeleteDocumentInput
		if err := json.Unmarshal(event.Payload, &input); err != nil {
			return fmt.Errorf("decode delete payload: %w", err)
		}
		return u.indexing.DeleteDocument(ctx, input)
	default:
		return fmt.Errorf("%w: unsupported event type %q", ErrInvalidDocumentEvent, event.EventType)
	}
}

func validateDocumentEvent(event model.SearchDocumentEvent) error {
	if event.SourceService == "" {
		return fmt.Errorf("%w: source service is required", ErrInvalidDocumentEvent)
	}
	if event.SourceEventID == "" {
		return fmt.Errorf("%w: source event id is required", ErrInvalidDocumentEvent)
	}
	if event.AggregateType == "" {
		return fmt.Errorf("%w: aggregate type is required", ErrInvalidDocumentEvent)
	}
	if event.AggregateID == "" {
		return fmt.Errorf("%w: aggregate id is required", ErrInvalidDocumentEvent)
	}
	if event.EventType != DocumentEventTypeUpsert && event.EventType != DocumentEventTypeDelete {
		return fmt.Errorf("%w: unsupported event type %q", ErrInvalidDocumentEvent, event.EventType)
	}
	if !json.Valid(event.Payload) || len(event.Payload) == 0 {
		return fmt.Errorf("%w: payload must be valid json", ErrInvalidDocumentEvent)
	}
	return nil
}

func normalizeDocumentEventProcessOptions(options ProcessDocumentEventOptions) ProcessDocumentEventOptions {
	if options.BatchSize <= 0 {
		options.BatchSize = 50
	}
	if options.MaxAttempts <= 0 {
		options.MaxAttempts = 20
	}
	if options.BaseBackoff <= 0 {
		options.BaseBackoff = time.Second
	}
	if options.Now.IsZero() {
		options.Now = time.Now().UTC()
	}
	return options
}

func cloneRawMessage(value json.RawMessage) json.RawMessage {
	if len(value) == 0 {
		return nil
	}
	return append(json.RawMessage(nil), value...)
}

func trimEventError(err error) string {
	if err == nil {
		return ""
	}
	reason := strings.TrimSpace(err.Error())
	if len(reason) > 1000 {
		return reason[:1000]
	}
	return reason
}
