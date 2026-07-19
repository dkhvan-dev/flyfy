package savedcapability

import "kz/inflap/backend/services/saved-service/internal/domain"

type ProductFlags struct {
	SavedItemsEnabled  bool
	SearchEnabled      bool
	CollectionsEnabled bool
}

type Usage struct {
	ActiveSavedItems  uint64
	ActiveCollections uint64
	UsageVersion      uint64
}

type QuotaWarning struct {
	Resource  string
	Limit     uint64
	Remaining uint64
}

type Snapshot struct {
	CapabilityRevision    string
	ProductFlags          ProductFlags
	HasConfirmedSavedData bool
	SupportedEntityTypes  []domain.EntityType
	QuotaWarning          *QuotaWarning
}

type Config struct {
	CapabilityRevision    string
	ProductFlags          ProductFlags
	SupportedEntityTypes  []domain.EntityType
	MaxActiveSavedItems   uint64
	QuotaWarningRemaining uint64
}

const quotaResourceSavedItems = "SAVED_ITEMS"
