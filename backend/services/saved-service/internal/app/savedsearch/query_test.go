package savedsearch

import (
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	savedqueryapp "kz/inflap/backend/services/saved-service/internal/app/savedquery"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestQueryValidationOwnsDecodedKeysetAndFilters(t *testing.T) {
	t.Parallel()

	term, err := Normalize("Museum")
	if err != nil {
		t.Fatalf("Normalize() error = %v", err)
	}
	now := time.Now().UTC()
	collectionID := uuid.New()
	entityType := domain.EntityTypeAttraction
	valid := Query{
		OwnerUserID: uuid.New(),
		Locale:      savedqueryapp.LocaleRU,
		EntityType:  &entityType,
		Collection:  &collectionID,
		Term:        term,
		After: &Keyset{
			MatchRank: MatchRankTitleToken,
			SavedAt:   now.Add(-time.Minute),
			ItemID:    uuid.New(),
		},
		Limit:  MaxPageLimit,
		ReadAt: now,
	}
	if err := valid.Validate(); err != nil {
		t.Fatalf("valid Query error = %v", err)
	}

	invalid := []Query{
		{},
		{
			OwnerUserID: uuid.New(), Locale: savedqueryapp.LocaleEN, Term: term,
			Collection: &collectionID, Uncollected: true, Limit: 1, ReadAt: now,
		},
		{
			OwnerUserID: uuid.New(), Locale: savedqueryapp.Locale("DE"), Term: term,
			Limit: 1, ReadAt: now,
		},
		{
			OwnerUserID: uuid.New(), Locale: savedqueryapp.LocaleEN, Term: term,
			After: &Keyset{MatchRank: 9, SavedAt: now, ItemID: uuid.New()}, Limit: 1, ReadAt: now,
		},
		{
			OwnerUserID: uuid.New(), Locale: savedqueryapp.LocaleEN,
			Limit: 1, ReadAt: now,
		},
	}
	for index, query := range invalid {
		if err := query.Validate(); !errors.Is(err, ErrInvalidQuery) {
			t.Fatalf("invalid Query %d error = %v, want %v", index, err, ErrInvalidQuery)
		}
	}
}
