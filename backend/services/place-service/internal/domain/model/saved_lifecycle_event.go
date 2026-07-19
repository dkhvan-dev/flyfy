package model

import (
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
)

type SavedLifecycleEventType string

const (
	SavedLifecyclePublished         SavedLifecycleEventType = "content.published"
	SavedLifecycleUpdated           SavedLifecycleEventType = "content.updated"
	SavedLifecycleUnavailable       SavedLifecycleEventType = "content.unavailable"
	SavedLifecycleDeleted           SavedLifecycleEventType = "content.deleted"
	SavedLifecycleVisibilityChanged SavedLifecycleEventType = "content.visibility_changed"
)

type SavedLifecycleVisibility string

const (
	SavedLifecycleVisibilityPublic      SavedLifecycleVisibility = "PUBLIC"
	SavedLifecycleVisibilityUnavailable SavedLifecycleVisibility = "UNAVAILABLE"
	SavedLifecycleVisibilityDeleted     SavedLifecycleVisibility = "DELETED"
	SavedLifecycleVisibilityRestricted  SavedLifecycleVisibility = "RESTRICTED"
)

type SavedLifecycleDeliveryState string

const (
	SavedLifecycleDeliveryPending   SavedLifecycleDeliveryState = "PENDING"
	SavedLifecycleDeliveryDelivered SavedLifecycleDeliveryState = "DELIVERED"
	SavedLifecycleDeliveryDead      SavedLifecycleDeliveryState = "DEAD"
)

var ErrInvalidSavedLifecycleEvent = errors.New("invalid Saved lifecycle event")

// SavedLifecycleEvent contains only the source-owned immutable envelope state.
// PUBLIC card projection is intentionally optional and omitted by place-service;
// deny events therefore have no field in which source or draft payload can leak.
type SavedLifecycleEvent struct {
	EventID            uuid.UUID
	SchemaVersion      uint16
	EventType          SavedLifecycleEventType
	EntityID           uuid.UUID
	SourceRevision     uint64
	ProjectionRevision uint64
	VisibilityRevision uint64
	Visibility         SavedLifecycleVisibility
	OccurredAt         time.Time
}

func (event SavedLifecycleEvent) Validate() error {
	if event.EventID == uuid.Nil ||
		event.EventID.Version() != 4 ||
		event.EventID.Variant() != uuid.RFC4122 {
		return fmt.Errorf("%w: event id must be an RFC 4122 UUIDv4", ErrInvalidSavedLifecycleEvent)
	}
	if event.SchemaVersion != 1 {
		return fmt.Errorf("%w: unsupported schema version", ErrInvalidSavedLifecycleEvent)
	}
	if event.EntityID == uuid.Nil || event.EntityID.String() == "" {
		return fmt.Errorf("%w: canonical attraction id is required", ErrInvalidSavedLifecycleEvent)
	}
	if event.SourceRevision == 0 || event.ProjectionRevision == 0 || event.VisibilityRevision == 0 {
		return fmt.Errorf("%w: source revisions must be positive", ErrInvalidSavedLifecycleEvent)
	}
	if event.OccurredAt.IsZero() {
		return fmt.Errorf("%w: occurred_at is required", ErrInvalidSavedLifecycleEvent)
	}

	validPair := false
	switch event.EventType {
	case SavedLifecyclePublished, SavedLifecycleUpdated:
		validPair = event.Visibility == SavedLifecycleVisibilityPublic
	case SavedLifecycleUnavailable:
		validPair = event.Visibility == SavedLifecycleVisibilityUnavailable
	case SavedLifecycleDeleted:
		validPair = event.Visibility == SavedLifecycleVisibilityDeleted
	case SavedLifecycleVisibilityChanged:
		validPair = event.Visibility == SavedLifecycleVisibilityRestricted
	}
	if !validPair {
		return fmt.Errorf("%w: event kind and visibility do not match", ErrInvalidSavedLifecycleEvent)
	}
	return nil
}

type ClaimedSavedLifecycleEvent struct {
	Event         SavedLifecycleEvent
	DeliveryState SavedLifecycleDeliveryState
	AttemptCount  int
	LeaseID       uuid.UUID
}

func (claimed ClaimedSavedLifecycleEvent) Validate() error {
	if err := claimed.Event.Validate(); err != nil {
		return err
	}
	if claimed.DeliveryState != SavedLifecycleDeliveryPending {
		return fmt.Errorf("%w: claimed delivery state is not dispatchable", ErrInvalidSavedLifecycleEvent)
	}
	if claimed.AttemptCount < 0 || claimed.LeaseID == uuid.Nil {
		return fmt.Errorf("%w: invalid delivery metadata", ErrInvalidSavedLifecycleEvent)
	}
	return nil
}
