package savedquery

import (
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestBatchStatusQueryRejectsDuplicatesAndBounds(t *testing.T) {
	owner := uuid.New()
	target := savedQueryTestTarget(t, domain.EntityTypeActivity)

	tests := []BatchStatusQuery{
		{OwnerUserID: owner},
		{OwnerUserID: owner, Targets: []domain.SavedTarget{target, target}},
		{OwnerUserID: uuid.Nil, Targets: []domain.SavedTarget{target}},
	}
	tooMany := BatchStatusQuery{OwnerUserID: owner, Targets: make([]domain.SavedTarget, MaxBatchTargets+1)}
	for index := range tooMany.Targets {
		tooMany.Targets[index] = savedQueryTestTarget(t, domain.EntityTypeAttraction)
	}
	tests = append(tests, tooMany)

	for index, query := range tests {
		if err := query.Validate(); !errors.Is(err, ErrInvalidQuery) {
			t.Fatalf("case %d error = %v, want %v", index, err, ErrInvalidQuery)
		}
	}
}

func TestListQueryValidation(t *testing.T) {
	now := time.Now().UTC()
	owner := uuid.New()
	collection := uuid.New()
	after := &Keyset{SavedAt: now.Add(-time.Minute), ItemID: uuid.New()}
	valid := ListQuery{
		OwnerUserID: owner,
		Locale:      LocaleRU,
		Collection:  &collection,
		After:       after,
		Limit:       MaxPageLimit,
		ReadAt:      now,
	}
	if err := valid.Validate(); err != nil {
		t.Fatalf("valid query error = %v", err)
	}

	invalid := []ListQuery{
		{},
		{OwnerUserID: owner, Locale: Locale("DE"), Limit: 1, ReadAt: now},
		{OwnerUserID: owner, Locale: LocaleEN, Collection: &collection, Uncollected: true, Limit: 1, ReadAt: now},
		{OwnerUserID: owner, Locale: LocaleEN, Limit: MaxPageLimit + 1, ReadAt: now},
		{OwnerUserID: owner, Locale: LocaleEN, Limit: 1, ReadAt: now, After: &Keyset{}},
	}
	for index, query := range invalid {
		if err := query.Validate(); !errors.Is(err, ErrInvalidQuery) {
			t.Fatalf("invalid case %d error = %v, want %v", index, err, ErrInvalidQuery)
		}
	}
}

func TestResourceVersionIsMonotonicAndBounded(t *testing.T) {
	version, err := ComposeResourceVersion(7, 9)
	if err != nil || version != 16 {
		t.Fatalf("ComposeResourceVersion() = (%d, %v), want (16, nil)", version, err)
	}
	if _, err := ComposeResourceVersion(0, 1); !errors.Is(err, ErrDataInvariant) {
		t.Fatalf("zero relationship version error = %v", err)
	}
}

func savedQueryTestTarget(t testing.TB, entityType domain.EntityType) domain.SavedTarget {
	t.Helper()
	target, err := domain.NewSavedTarget(entityType, uuid.NewString())
	if err != nil {
		t.Fatalf("NewSavedTarget() error = %v", err)
	}
	return target
}
