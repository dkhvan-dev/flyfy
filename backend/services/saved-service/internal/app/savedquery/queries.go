package savedquery

import (
	"math"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

var minimumQueryTime = time.Unix(0, 0).UTC()

type StatusQuery struct {
	OwnerUserID uuid.UUID
	Target      domain.SavedTarget
}

func (q StatusQuery) Validate() error {
	if q.OwnerUserID == uuid.Nil || q.Target.IsZero() {
		return ErrInvalidQuery
	}
	return nil
}

type BatchStatusQuery struct {
	OwnerUserID uuid.UUID
	Targets     []domain.SavedTarget
}

func (q BatchStatusQuery) Validate() error {
	if q.OwnerUserID == uuid.Nil || len(q.Targets) == 0 || len(q.Targets) > MaxBatchTargets {
		return ErrInvalidQuery
	}
	seen := make(map[string]struct{}, len(q.Targets))
	for _, target := range q.Targets {
		if target.IsZero() {
			return ErrInvalidQuery
		}
		key := string(target.EntityType()) + "\x00" + target.EntityID()
		if _, exists := seen[key]; exists {
			return ErrInvalidQuery
		}
		seen[key] = struct{}{}
	}
	return nil
}

type ListInput struct {
	OwnerUserID uuid.UUID
	Locale      Locale
	EntityType  *domain.EntityType
	Collection  *uuid.UUID
	Uncollected bool
	After       *Keyset
	Limit       int
}

// ListQuery is the repository boundary. ReadAt is server-owned and controls
// time-bounded projection fields such as media references.
type ListQuery struct {
	OwnerUserID uuid.UUID
	Locale      Locale
	EntityType  *domain.EntityType
	Collection  *uuid.UUID
	Uncollected bool
	After       *Keyset
	Limit       int
	ReadAt      time.Time
}

func (q ListQuery) Validate() error {
	if q.OwnerUserID == uuid.Nil || !q.Locale.IsValid() || q.Limit < 1 || q.Limit > MaxPageLimit ||
		q.ReadAt.IsZero() || q.ReadAt.Before(minimumQueryTime) || q.ReadAt.UnixMicro() <= 0 {
		return ErrInvalidQuery
	}
	if q.EntityType != nil && !q.EntityType.IsValid() {
		return ErrInvalidQuery
	}
	if q.Collection != nil && (*q.Collection == uuid.Nil || q.Uncollected) {
		return ErrInvalidQuery
	}
	if q.After != nil {
		if q.After.ItemID == uuid.Nil || q.After.SavedAt.IsZero() ||
			q.After.SavedAt.Before(minimumQueryTime) || q.After.SavedAt.UnixMicro() <= 0 {
			return ErrInvalidQuery
		}
	}
	return nil
}

// ComposeResourceVersion provides one monotonic status version while keeping
// relationship and membership versions independent in persistence.
func ComposeResourceVersion(relationshipVersion, membershipVersion uint64) (uint64, error) {
	if relationshipVersion == 0 || relationshipVersion > math.MaxInt64 || membershipVersion > math.MaxInt64 ||
		relationshipVersion > math.MaxInt64-membershipVersion {
		return 0, ErrDataInvariant
	}
	return relationshipVersion + membershipVersion, nil
}
