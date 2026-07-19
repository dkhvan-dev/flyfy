package savedmaintenance

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidSubjectPurge       = errors.New("invalid saved subject purge")
	ErrSubjectPurgeNotFound      = errors.New("saved subject purge not found")
	ErrSubjectPurgeIdentityClash = errors.New("saved subject purge identity conflict")
)

type SubjectPurgePhase string

const (
	SubjectPurgePhaseOutbox          SubjectPurgePhase = "OUTBOX"
	SubjectPurgePhaseCollectionItems SubjectPurgePhase = "COLLECTION_ITEMS"
	SubjectPurgePhaseCollections     SubjectPurgePhase = "COLLECTIONS"
	SubjectPurgePhaseSavedItems      SubjectPurgePhase = "SAVED_ITEMS"
	SubjectPurgePhaseOperations      SubjectPurgePhase = "OPERATIONS"
	SubjectPurgePhaseCollectionUsage SubjectPurgePhase = "COLLECTION_USAGE"
	SubjectPurgePhaseUserUsage       SubjectPurgePhase = "USER_USAGE"
	SubjectPurgePhaseCompleted       SubjectPurgePhase = "COMPLETED"
)

func (p SubjectPurgePhase) IsValid() bool {
	switch p {
	case SubjectPurgePhaseOutbox,
		SubjectPurgePhaseCollectionItems,
		SubjectPurgePhaseCollections,
		SubjectPurgePhaseSavedItems,
		SubjectPurgePhaseOperations,
		SubjectPurgePhaseCollectionUsage,
		SubjectPurgePhaseUserUsage,
		SubjectPurgePhaseCompleted:
		return true
	default:
		return false
	}
}

// SubjectPurgeStart requires the caller to durably fence account/session writes
// before deletion and keep that fence through COMPLETED. Existing mutation paths
// do not acquire the purge job lock, so WritesFenced is an explicit compliance
// precondition, not an advisory hint.
type SubjectPurgeStart struct {
	OperationID  uuid.UUID
	Subject      string
	OwnerUserID  uuid.UUID
	WritesFenced bool
}

func (s SubjectPurgeStart) Validate() error {
	if s.OperationID == uuid.Nil || s.OperationID.Version() != 4 ||
		s.OperationID.Variant() != uuid.RFC4122 || s.OwnerUserID == uuid.Nil ||
		!s.WritesFenced || s.Subject != strings.TrimSpace(s.Subject) ||
		len(s.Subject) < 1 || len(s.Subject) > 255 {
		return ErrInvalidSubjectPurge
	}
	return nil
}

type SubjectPurgeJob struct {
	OperationID        uuid.UUID
	Subject            string
	OwnerUserID        uuid.UUID
	Phase              SubjectPurgePhase
	AttemptCount       int
	NextAttemptAt      *time.Time
	LastErrorCode      string
	CreatedAt          time.Time
	UpdatedAt          time.Time
	CompletedAt        *time.Time
	RetentionExpiresAt *time.Time
}

func (j SubjectPurgeJob) Validate() error {
	if j.OperationID == uuid.Nil || j.OperationID.Version() != 4 ||
		j.OperationID.Variant() != uuid.RFC4122 || j.OwnerUserID == uuid.Nil ||
		j.Subject != strings.TrimSpace(j.Subject) || len(j.Subject) < 1 || len(j.Subject) > 255 ||
		!j.Phase.IsValid() || j.AttemptCount < 0 || j.CreatedAt.IsZero() ||
		j.UpdatedAt.IsZero() || j.UpdatedAt.Before(j.CreatedAt) {
		return ErrInvalidSubjectPurge
	}
	if j.Phase == SubjectPurgePhaseCompleted {
		if j.NextAttemptAt != nil || j.LastErrorCode != "" || j.CompletedAt == nil ||
			j.CompletedAt.Before(j.CreatedAt) || j.RetentionExpiresAt == nil ||
			!j.RetentionExpiresAt.Equal(j.CompletedAt.Add(DefaultOperationRetention)) {
			return ErrInvalidSubjectPurge
		}
		return nil
	}
	if j.NextAttemptAt == nil || j.NextAttemptAt.Before(j.CreatedAt) ||
		j.CompletedAt != nil || j.RetentionExpiresAt != nil {
		return ErrInvalidSubjectPurge
	}
	return nil
}

type SubjectPurgeBatchRequest struct {
	Batch       BatchRequest
	OperationID *uuid.UUID
}

func (r SubjectPurgeBatchRequest) Validate() error {
	if err := r.Batch.Validate(); err != nil {
		return err
	}
	if r.OperationID != nil && *r.OperationID == uuid.Nil {
		return ErrInvalidSubjectPurge
	}
	return nil
}

type SubjectPurgeBatchResult struct {
	Found         bool
	OperationID   uuid.UUID
	PhaseBefore   SubjectPurgePhase
	PhaseAfter    SubjectPurgePhase
	RowsPurged    int64
	PhaseAdvanced bool
	Completed     bool
	HasMore       bool
}

func (r SubjectPurgeBatchResult) Validate(limit int) error {
	if !r.Found {
		if r.OperationID != uuid.Nil || r.RowsPurged != 0 || r.PhaseAdvanced || r.Completed || r.HasMore {
			return ErrInvalidSubjectPurge
		}
		return nil
	}
	if r.OperationID == uuid.Nil || !r.PhaseBefore.IsValid() || !r.PhaseAfter.IsValid() ||
		r.RowsPurged < 0 || r.RowsPurged > int64(limit) ||
		(r.Completed != (r.PhaseAfter == SubjectPurgePhaseCompleted)) ||
		(r.PhaseAdvanced != (r.PhaseBefore != r.PhaseAfter)) ||
		(!r.Completed && !r.HasMore) {
		return ErrInvalidSubjectPurge
	}
	return nil
}

type SubjectPurgeRepository interface {
	StartSubjectPurge(context.Context, SubjectPurgeStart, time.Time) (SubjectPurgeJob, error)
	GetSubjectPurge(context.Context, uuid.UUID) (SubjectPurgeJob, error)
	ProcessSubjectPurge(context.Context, SubjectPurgeBatchRequest) (SubjectPurgeBatchResult, error)
}

type SubjectPurgeStats struct {
	StartedAt      time.Time
	FinishedAt     time.Time
	Ticks          int
	RowsPurged     int64
	PhasesAdvanced int
	Completed      bool
	Capped         bool
	HasMore        bool
}
