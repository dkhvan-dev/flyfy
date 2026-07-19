package savedoutbox

import (
	"fmt"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

const SchemaVersionV1 uint16 = 1

type EventKind string

const (
	EventSavedItemActivated EventKind = "SAVED_ITEM_ACTIVATED"
	EventSavedItemRemoved   EventKind = "SAVED_ITEM_REMOVED"
)

func (kind EventKind) IsValid() bool {
	return kind == EventSavedItemActivated || kind == EventSavedItemRemoved
}

// Event is the complete broker contract. Deliberately absent are owner,
// account, target, relationship, and attribution identifiers.
type Event struct {
	EventID       uuid.UUID         `json:"event_id"`
	Kind          EventKind         `json:"kind"`
	EntityType    domain.EntityType `json:"entity_type"`
	OccurredAt    time.Time         `json:"occurred_at"`
	SchemaVersion uint16            `json:"schema_version"`
}

func (event Event) Validate() error {
	if event.EventID == uuid.Nil || !event.Kind.IsValid() || !event.EntityType.IsValid() ||
		event.SchemaVersion != SchemaVersionV1 || !validOutboxTime(event.OccurredAt) {
		return ErrInvalidRecord
	}
	return nil
}

// Lease is a fencing token. Attempt is incremented atomically by claim, so a
// reclaimed row cannot be acknowledged by a worker holding an older lease.
type Lease struct {
	EventID    uuid.UUID
	AcquiredAt time.Time
	Attempt    int
}

func (lease Lease) Validate() error {
	if !validOutboxTime(lease.AcquiredAt) || lease.Attempt < 1 ||
		lease.Attempt > MaxDeliveryAttempts {
		return ErrInvalidRecord
	}
	return nil
}

// ClaimedRecord mirrors only privacy-safe outbox columns plus the lease.
// Repository implementations must not hydrate owner_user_id or entity_id.
type ClaimedRecord struct {
	Lease         Lease
	Kind          EventKind
	EntityType    domain.EntityType
	SchemaVersion int32
	OccurredAt    time.Time
}

func (record ClaimedRecord) ValidateClaim() error {
	if err := record.Lease.Validate(); err != nil || !validOutboxTime(record.OccurredAt) ||
		record.OccurredAt.After(record.Lease.AcquiredAt) {
		return ErrInvalidRecord
	}
	return nil
}

func MapClaimedRecord(record ClaimedRecord) (Event, error) {
	if err := record.ValidateClaim(); err != nil || record.SchemaVersion != int32(SchemaVersionV1) {
		return Event{}, fmt.Errorf("%w: unsupported or malformed claimed record", ErrInvalidRecord)
	}
	event := Event{
		EventID:       record.Lease.EventID,
		Kind:          record.Kind,
		EntityType:    record.EntityType,
		OccurredAt:    record.OccurredAt.UTC(),
		SchemaVersion: SchemaVersionV1,
	}
	if err := event.Validate(); err != nil {
		return Event{}, err
	}
	return event, nil
}

func validOutboxTime(value time.Time) bool {
	return !value.IsZero() && !value.Before(time.Unix(0, 0).UTC())
}
