package model

import (
	"errors"
	"time"

	"github.com/google/uuid"
)

var ErrInvalidSavedLifecycleState = errors.New("invalid Saved lifecycle state")

type SavedLifecycleEventKind string

const (
	SavedLifecycleEventPublished         SavedLifecycleEventKind = "PUBLISHED"
	SavedLifecycleEventUpdated           SavedLifecycleEventKind = "UPDATED"
	SavedLifecycleEventUnavailable       SavedLifecycleEventKind = "UNAVAILABLE"
	SavedLifecycleEventDeleted           SavedLifecycleEventKind = "DELETED"
	SavedLifecycleEventVisibilityChanged SavedLifecycleEventKind = "VISIBILITY_CHANGED"
)

func (k SavedLifecycleEventKind) IsValid() bool {
	switch k {
	case SavedLifecycleEventPublished,
		SavedLifecycleEventUpdated,
		SavedLifecycleEventUnavailable,
		SavedLifecycleEventDeleted,
		SavedLifecycleEventVisibilityChanged:
		return true
	default:
		return false
	}
}

type SavedLifecycleVisibility string

const (
	SavedLifecycleVisibilityPublic      SavedLifecycleVisibility = "PUBLIC"
	SavedLifecycleVisibilityUnavailable SavedLifecycleVisibility = "UNAVAILABLE"
	SavedLifecycleVisibilityDeleted     SavedLifecycleVisibility = "DELETED"
)

func (v SavedLifecycleVisibility) IsValid() bool {
	switch v {
	case SavedLifecycleVisibilityPublic,
		SavedLifecycleVisibilityUnavailable,
		SavedLifecycleVisibilityDeleted:
		return true
	default:
		return false
	}
}

type SavedLifecycleOutboxMessage struct {
	EventID            uuid.UUID
	Kind               SavedLifecycleEventKind
	TargetUserID       uuid.UUID
	SourceRevision     uint64
	ProjectionRevision uint64
	VisibilityRevision uint64
	OccurredAt         time.Time
	Visibility         SavedLifecycleVisibility
	PublicProjection   []byte
	AttemptCount       int
	MaxAttempts        int
	LeaseToken         uuid.UUID
}

func (m SavedLifecycleOutboxMessage) Validate() error {
	if m.EventID == uuid.Nil || !m.Kind.IsValid() || m.TargetUserID == uuid.Nil ||
		m.SourceRevision == 0 || m.ProjectionRevision == 0 || m.VisibilityRevision == 0 ||
		m.OccurredAt.IsZero() || !m.Visibility.IsValid() || m.AttemptCount < 1 ||
		m.MaxAttempts < 1 || m.AttemptCount > m.MaxAttempts || m.LeaseToken == uuid.Nil {
		return ErrInvalidSavedLifecycleState
	}
	if m.Visibility != SavedLifecycleVisibilityPublic && len(m.PublicProjection) != 0 {
		return ErrInvalidSavedLifecycleState
	}
	return nil
}

type SavedGuideUserReconcileLease struct {
	GuideProfileID uuid.UUID
	UserID         uuid.UUID
	LeaseToken     uuid.UUID
	FailureCount   int
}

func (l SavedGuideUserReconcileLease) Validate() error {
	if l.GuideProfileID == uuid.Nil || l.UserID == uuid.Nil || l.LeaseToken == uuid.Nil || l.FailureCount < 0 {
		return ErrInvalidSavedLifecycleState
	}
	return nil
}

type SavedGuideExternalUserState struct {
	AccountStatus         string
	IsDeleted             bool
	AccountUpdatedAt      time.Time
	ProfileUpdatedAt      *time.Time
	ProjectionFingerprint []byte
	AvatarFileID          *uuid.UUID
	ObservedAt            time.Time
}

func (s SavedGuideExternalUserState) Validate() error {
	if s.AccountStatus != "ACTIVE" && s.AccountStatus != "BLOCKED" && s.AccountStatus != "DELETED" {
		return ErrInvalidSavedLifecycleState
	}
	if s.AccountUpdatedAt.IsZero() || s.ObservedAt.IsZero() || s.AccountUpdatedAt.After(s.ObservedAt.Add(time.Minute)) {
		return ErrInvalidSavedLifecycleState
	}
	if s.ProfileUpdatedAt == nil {
		if (s.AccountStatus == "ACTIVE" && !s.IsDeleted) || len(s.ProjectionFingerprint) != 0 || s.AvatarFileID != nil {
			return ErrInvalidSavedLifecycleState
		}
	} else if s.ProfileUpdatedAt.IsZero() || len(s.ProjectionFingerprint) != 32 ||
		s.ProfileUpdatedAt.After(s.ObservedAt.Add(time.Minute)) {
		return ErrInvalidSavedLifecycleState
	}
	if s.AvatarFileID != nil && *s.AvatarFileID == uuid.Nil {
		return ErrInvalidSavedLifecycleState
	}
	return nil
}
