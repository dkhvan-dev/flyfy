package savedsearch

import (
	"time"

	"github.com/google/uuid"

	savedqueryapp "kz/inflap/backend/services/saved-service/internal/app/savedquery"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

var minimumSearchTime = time.Unix(0, 0).UTC()

type Input struct {
	OwnerUserID uuid.UUID
	Locale      savedqueryapp.Locale
	EntityType  *domain.EntityType
	Collection  *uuid.UUID
	Uncollected bool
	Search      string
	After       *Keyset
	Limit       int
}

// Query is the repository boundary and deliberately contains no raw query.
// ReadAt is server-owned and controls time-bounded projection fields.
type Query struct {
	OwnerUserID uuid.UUID
	Locale      savedqueryapp.Locale
	EntityType  *domain.EntityType
	Collection  *uuid.UUID
	Uncollected bool
	Term        SearchTerm
	After       *Keyset
	Limit       int
	ReadAt      time.Time
}

func (q Query) Validate() error {
	if q.OwnerUserID == uuid.Nil || !q.Locale.IsValid() || q.Limit < 1 || q.Limit > MaxPageLimit ||
		q.ReadAt.IsZero() || q.ReadAt.Before(minimumSearchTime) || q.ReadAt.UnixMicro() <= 0 {
		return ErrInvalidQuery
	}
	if err := q.Term.validate(); err != nil {
		return err
	}
	if q.EntityType != nil && !q.EntityType.IsValid() {
		return ErrInvalidQuery
	}
	if q.Collection != nil && (*q.Collection == uuid.Nil || q.Uncollected) {
		return ErrInvalidQuery
	}
	if q.After != nil && (!q.After.MatchRank.IsValid() || q.After.ItemID == uuid.Nil ||
		q.After.SavedAt.IsZero() || q.After.SavedAt.Before(minimumSearchTime) ||
		q.After.SavedAt.UnixMicro() <= 0) {
		return ErrInvalidQuery
	}
	return nil
}
