package domain

import (
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
)

func TestSavedRelationshipLifecycle(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 10, 0, 0, 0, time.UTC)
	target, err := NewSavedTarget(EntityTypeActivity, "activity-42")
	if err != nil {
		t.Fatalf("NewSavedTarget() error = %v", err)
	}

	initial := activationIdentity("00000000-0000-0000-0000-000000000001", "00000000-0000-0000-0000-000000000002")
	relationship, err := NewActiveRelationship(
		uuid.MustParse("00000000-0000-0000-0000-000000000003"),
		uuid.MustParse("00000000-0000-0000-0000-000000000004"),
		target,
		initial,
		now,
	)
	if err != nil {
		t.Fatalf("NewActiveRelationship() error = %v", err)
	}

	if err := relationship.BumpDependentMembershipVersion(now.Add(time.Minute)); err != nil {
		t.Fatalf("BumpDependentMembershipVersion() error = %v", err)
	}
	if relationship.SavedAt() != now || relationship.RelationshipVersion() != 1 || relationship.DependentMembershipVersion() != 1 {
		t.Fatalf("membership mutation changed lifecycle state: %#v", relationship)
	}

	removedAt := now.Add(2 * time.Minute)
	if err := relationship.Remove(removedAt); err != nil {
		t.Fatalf("Remove() error = %v", err)
	}
	if relationship.State() != RelationshipStateRemoved || relationship.RelationshipVersion() != 2 {
		t.Fatalf("Remove() state/version = %q/%d", relationship.State(), relationship.RelationshipVersion())
	}
	if got := relationship.PurgeEligibleAt(); got == nil || !got.Equal(removedAt.Add(removedRelationshipRetention)) {
		t.Fatalf("PurgeEligibleAt() = %v, want %v", got, removedAt.Add(removedRelationshipRetention))
	}

	reactivatedAt := now.Add(3 * time.Minute)
	next := activationIdentity("00000000-0000-0000-0000-000000000005", "00000000-0000-0000-0000-000000000006")
	if err := relationship.Reactivate(next, reactivatedAt); err != nil {
		t.Fatalf("Reactivate() error = %v", err)
	}
	if relationship.State() != RelationshipStateActive || relationship.SavedAt() != reactivatedAt || relationship.RelationshipVersion() != 3 {
		t.Fatalf("Reactivate() did not create a new activation: %#v", relationship)
	}
	if relationship.StateGeneration() != next.StateGeneration || relationship.RelationshipAttributionID() != next.RelationshipAttributionID {
		t.Fatalf("Reactivate() did not replace activation identity")
	}
	if relationship.RemovedAt() != nil || relationship.PurgeEligibleAt() != nil {
		t.Fatal("Reactivate() retained removed tombstone timestamps")
	}
}

func TestSavedRelationshipRejectsInvalidTransitions(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 10, 0, 0, 0, time.UTC)
	target, _ := NewSavedTarget(EntityTypeGuide, "guide-42")
	relationship, err := NewActiveRelationship(uuid.New(), uuid.New(), target, activationIdentity(uuid.New().String(), uuid.New().String()), now)
	if err != nil {
		t.Fatalf("NewActiveRelationship() error = %v", err)
	}

	if err := relationship.Reactivate(activationIdentity(uuid.New().String(), uuid.New().String()), now); !errors.Is(err, ErrMutationStale) {
		t.Fatalf("Reactivate(active) error = %v, want stale", err)
	}
	if err := relationship.Remove(now.Add(time.Minute)); err != nil {
		t.Fatalf("Remove() error = %v", err)
	}
	version := relationship.RelationshipVersion()
	removedAt := relationship.RemovedAt()
	if err := relationship.Remove(now.Add(2 * time.Minute)); err != nil {
		t.Fatalf("Remove(removed) error = %v, want idempotent no-op", err)
	}
	if relationship.RelationshipVersion() != version || relationship.RemovedAt() == nil || !relationship.RemovedAt().Equal(*removedAt) {
		t.Fatal("Remove(removed) changed the existing tombstone")
	}
}

func activationIdentity(generation string, attribution string) ActivationIdentity {
	return ActivationIdentity{
		StateGeneration:           uuid.MustParse(generation),
		RelationshipAttributionID: uuid.MustParse(attribution),
	}
}
