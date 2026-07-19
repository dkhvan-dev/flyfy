package model

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

const ActivitySavedLifecycleSubjectV1 = "saved.source.activity.lifecycle.v1"

type ActivitySavedLifecycleEventKind string

const (
	ActivitySavedLifecyclePublished         ActivitySavedLifecycleEventKind = "PUBLISHED"
	ActivitySavedLifecycleUpdated           ActivitySavedLifecycleEventKind = "UPDATED"
	ActivitySavedLifecycleUnavailable       ActivitySavedLifecycleEventKind = "UNAVAILABLE"
	ActivitySavedLifecycleDeleted           ActivitySavedLifecycleEventKind = "DELETED"
	ActivitySavedLifecycleVisibilityChanged ActivitySavedLifecycleEventKind = "VISIBILITY_CHANGED"
)

func (kind ActivitySavedLifecycleEventKind) IsValid() bool {
	switch kind {
	case ActivitySavedLifecyclePublished,
		ActivitySavedLifecycleUpdated,
		ActivitySavedLifecycleUnavailable,
		ActivitySavedLifecycleDeleted,
		ActivitySavedLifecycleVisibilityChanged:
		return true
	default:
		return false
	}
}

type ActivitySavedLifecycleOutboxStatus string

const (
	ActivitySavedLifecyclePending         ActivitySavedLifecycleOutboxStatus = "PENDING"
	ActivitySavedLifecycleProcessing      ActivitySavedLifecycleOutboxStatus = "PROCESSING"
	ActivitySavedLifecyclePublishedStatus ActivitySavedLifecycleOutboxStatus = "PUBLISHED"
	ActivitySavedLifecycleDead            ActivitySavedLifecycleOutboxStatus = "DEAD"
)

type ActivitySavedLifecycleOutboxEvent struct {
	ID                  uuid.UUID
	ActivityID          uuid.UUID
	Subject             string
	SchemaVersion       uint32
	Kind                ActivitySavedLifecycleEventKind
	Visibility          string
	SourceRevision      uint64
	ProjectionRevision  uint64
	VisibilityRevision  uint64
	HasPublicProjection bool
	Payload             []byte
	Status              ActivitySavedLifecycleOutboxStatus
	AttemptCount        int
	MaxAttempts         int
	NextAttemptAt       *time.Time
	LockedAt            *time.Time
	LockedBy            *string
	LastErrorCode       *string
	OccurredAt          time.Time
	CreatedAt           time.Time
	PublishedAt         *time.Time
	DeadAt              *time.Time
	RetentionExpiresAt  *time.Time
	RecoveredLease      bool
}

var ErrInvalidActivitySavedLifecycleEvent = errors.New("invalid activity Saved lifecycle event")

func (event ActivitySavedLifecycleOutboxEvent) ValidateSemanticEnvelope() error {
	if event.ID == uuid.Nil || event.ID.Version() != 4 || event.ActivityID == uuid.Nil {
		return ErrInvalidActivitySavedLifecycleEvent
	}
	if event.Subject != ActivitySavedLifecycleSubjectV1 || event.SchemaVersion != 1 || !event.Kind.IsValid() {
		return ErrInvalidActivitySavedLifecycleEvent
	}
	switch event.Visibility {
	case "PUBLIC", "PRIVATE", "UNAVAILABLE", "DELETED", "RESTRICTED":
	default:
		return ErrInvalidActivitySavedLifecycleEvent
	}
	if event.Visibility != "PUBLIC" && event.HasPublicProjection {
		return ErrInvalidActivitySavedLifecycleEvent
	}
	if event.SourceRevision == 0 || event.ProjectionRevision == 0 || event.VisibilityRevision == 0 {
		return ErrInvalidActivitySavedLifecycleEvent
	}
	if len(event.Payload) < 2 || len(event.Payload) > 64*1024 || event.OccurredAt.IsZero() {
		return ErrInvalidActivitySavedLifecycleEvent
	}
	return nil
}

type ActivitySavedLifecycleQueueStats struct {
	PendingCount            int64
	ProcessingCount         int64
	DeadCount               int64
	OldestPendingAgeSeconds float64
}

func NormalizeActivitySavedLifecycleErrorCode(code string) string {
	code = strings.ToUpper(strings.TrimSpace(code))
	if code == "" || len(code) > 64 {
		return "PUBLISH_FAILED"
	}
	for index, char := range code {
		if (char >= 'A' && char <= 'Z') || (index > 0 && char >= '0' && char <= '9') || (index > 0 && char == '_') {
			continue
		}
		return "PUBLISH_FAILED"
	}
	return code
}
