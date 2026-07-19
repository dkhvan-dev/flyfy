package savedcapability

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

type repositoryStub struct {
	usage Usage
	err   error
	owner uuid.UUID
}

func (stub *repositoryStub) GetUsage(_ context.Context, owner uuid.UUID) (Usage, error) {
	stub.owner = owner
	return stub.usage, stub.err
}

func TestServiceGetReturnsOwnerCapabilitySnapshot(t *testing.T) {
	repository := &repositoryStub{usage: Usage{ActiveSavedItems: 9_950, UsageVersion: 14}}
	service, err := NewService(repository, validTestConfig())
	if err != nil {
		t.Fatalf("NewService() error = %v", err)
	}
	owner := uuid.New()

	snapshot, err := service.Get(context.Background(), owner)
	if err != nil {
		t.Fatalf("Get() error = %v", err)
	}
	if repository.owner != owner || !snapshot.HasConfirmedSavedData {
		t.Fatalf("Get() snapshot = %+v, owner = %s", snapshot, repository.owner)
	}
	if snapshot.QuotaWarning == nil || snapshot.QuotaWarning.Remaining != 50 ||
		snapshot.QuotaWarning.Limit != 10_000 || snapshot.QuotaWarning.Resource != "SAVED_ITEMS" {
		t.Fatalf("Get() quota warning = %+v", snapshot.QuotaWarning)
	}
	snapshot.SupportedEntityTypes[0] = domain.EntityTypeActivity
	second, err := service.Get(context.Background(), owner)
	if err != nil || second.SupportedEntityTypes[0] != domain.EntityTypeAttraction {
		t.Fatalf("Get() leaked mutable config: %+v, %v", second, err)
	}
}

func TestServiceGetOmitsDistantQuotaWarning(t *testing.T) {
	service, err := NewService(&repositoryStub{}, validTestConfig())
	if err != nil {
		t.Fatalf("NewService() error = %v", err)
	}
	snapshot, err := service.Get(context.Background(), uuid.New())
	if err != nil {
		t.Fatalf("Get() error = %v", err)
	}
	if snapshot.HasConfirmedSavedData || snapshot.QuotaWarning != nil {
		t.Fatalf("Get() snapshot = %+v", snapshot)
	}
}

func TestServiceGetKeepsExistingCollectionsDiscoverableDuringRollback(t *testing.T) {
	repository := &repositoryStub{usage: Usage{ActiveCollections: 1, UsageVersion: 2}}
	config := validTestConfig()
	config.ProductFlags = ProductFlags{}
	service, err := NewService(repository, config)
	if err != nil {
		t.Fatalf("NewService() error = %v", err)
	}

	snapshot, err := service.Get(context.Background(), uuid.New())
	if err != nil || !snapshot.HasConfirmedSavedData {
		t.Fatalf("Get() = (%+v, %v)", snapshot, err)
	}
}

func TestServiceRejectsInvalidConfigurationAndOwner(t *testing.T) {
	config := validTestConfig()
	config.SupportedEntityTypes = append(config.SupportedEntityTypes, domain.EntityType("EXCURSION"))
	if _, err := NewService(&repositoryStub{}, config); !errors.Is(err, ErrInvalidConfiguration) {
		t.Fatalf("NewService() error = %v", err)
	}
	service, err := NewService(&repositoryStub{}, validTestConfig())
	if err != nil {
		t.Fatalf("NewService() error = %v", err)
	}
	if _, err := service.Get(context.Background(), uuid.Nil); !errors.Is(err, ErrInvalidRequest) {
		t.Fatalf("Get() error = %v", err)
	}
}

func validTestConfig() Config {
	return Config{
		CapabilityRevision: "saved-v1",
		ProductFlags: ProductFlags{
			SavedItemsEnabled: true,
		},
		SupportedEntityTypes: []domain.EntityType{
			domain.EntityTypeAttraction,
			domain.EntityTypeActivity,
			domain.EntityTypeUser,
		},
		MaxActiveSavedItems:   10_000,
		QuotaWarningRemaining: 100,
	}
}
