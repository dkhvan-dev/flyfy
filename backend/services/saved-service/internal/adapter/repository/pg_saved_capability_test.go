package repository

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"

	savedcapabilityapp "kz/inflap/backend/services/saved-service/internal/app/savedcapability"
)

func TestNewPGSavedCapabilityRepositoryRejectsNilPool(t *testing.T) {
	if _, err := NewPGSavedCapabilityRepository(nil); !errors.Is(err, savedcapabilityapp.ErrInvalidConfiguration) {
		t.Fatalf("NewPGSavedCapabilityRepository() error = %v", err)
	}
}

func TestPGSavedCapabilityRepositoryGetUsageAgainstPostgres(t *testing.T) {
	pool, _, _ := openSavedItemKernelIntegration(t)
	repository, err := NewPGSavedCapabilityRepository(pool)
	if err != nil {
		t.Fatalf("NewPGSavedCapabilityRepository() error = %v", err)
	}
	owner := uuid.New()

	empty, err := repository.GetUsage(context.Background(), owner)
	if err != nil || empty.ActiveSavedItems != 0 || empty.ActiveCollections != 0 || empty.UsageVersion != 0 {
		t.Fatalf("GetUsage(empty) = (%+v, %v)", empty, err)
	}
	if _, err := pool.Exec(context.Background(), `
        INSERT INTO saved_user_usage (
            owner_user_id, active_saved_items_count, usage_version
        ) VALUES ($1, 47, 9)`, owner); err != nil {
		t.Fatalf("insert saved usage: %v", err)
	}
	if _, err := pool.Exec(context.Background(), `
        INSERT INTO saved_collection_usage (
            owner_user_id, active_collections_count, active_memberships_count, usage_version
        ) VALUES ($1, 3, 0, 11)`, owner); err != nil {
		t.Fatalf("insert collection usage: %v", err)
	}

	usage, err := repository.GetUsage(context.Background(), owner)
	if err != nil || usage.ActiveSavedItems != 47 || usage.ActiveCollections != 3 ||
		usage.UsageVersion != 11 {
		t.Fatalf("GetUsage() = (%+v, %v)", usage, err)
	}
}
