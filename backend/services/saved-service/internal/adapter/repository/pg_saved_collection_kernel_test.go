package repository

import (
	"testing"

	"github.com/google/uuid"

	savedcollectionapp "kz/inflap/backend/services/saved-service/internal/app/savedcollection"
)

func TestClassifyDesiredCollectionSet(t *testing.T) {
	first := uuid.New()
	second := uuid.New()
	tests := []struct {
		name          string
		current       []uuid.UUID
		desired       []uuid.UUID
		createsInline bool
		want          savedcollectionapp.DesiredSetChange
	}{
		{name: "no-op", current: []uuid.UUID{first}, desired: []uuid.UUID{first}, want: savedcollectionapp.DesiredSetNoOp},
		{name: "reduction", current: []uuid.UUID{first, second}, desired: []uuid.UUID{first}, want: savedcollectionapp.DesiredSetReduction},
		{name: "expansion", current: []uuid.UUID{first}, desired: []uuid.UUID{first, second}, want: savedcollectionapp.DesiredSetExpansion},
		{name: "mixed", current: []uuid.UUID{first}, desired: []uuid.UUID{second}, want: savedcollectionapp.DesiredSetMixed},
		{name: "inline expansion", current: []uuid.UUID{first}, desired: []uuid.UUID{first}, createsInline: true, want: savedcollectionapp.DesiredSetExpansion},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if got := classifyDesiredCollectionSet(test.current, test.desired, test.createsInline); got != test.want {
				t.Fatalf("classifyDesiredCollectionSet() = %s, want %s", got, test.want)
			}
		})
	}
}

func TestCollectionSetDifferenceIsDeterministic(t *testing.T) {
	first := uuid.MustParse("10000000-0000-4000-8000-000000000001")
	second := uuid.MustParse("20000000-0000-4000-8000-000000000002")
	third := uuid.MustParse("30000000-0000-4000-8000-000000000003")
	removals, additions := collectionSetDifference(
		uuidSet([]uuid.UUID{second, first}),
		uuidSet([]uuid.UUID{third, second}),
	)
	if len(removals) != 1 || removals[0] != first || len(additions) != 1 || additions[0] != third {
		t.Fatalf("difference = removals=%v additions=%v", removals, additions)
	}
}

func TestSavedCollectionOwnerLockKeyIsStableAndScoped(t *testing.T) {
	owner := uuid.New()
	if savedCollectionOwnerLockKey(owner) != savedCollectionOwnerLockKey(owner) {
		t.Fatal("owner lock key is not stable")
	}
	if savedCollectionOwnerLockKey(owner) == savedCollectionOwnerLockKey(uuid.New()) {
		t.Fatal("distinct owners received the same test lock key")
	}
}
