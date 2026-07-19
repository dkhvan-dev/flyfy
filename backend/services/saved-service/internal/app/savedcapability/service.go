package savedcapability

import (
	"context"
	"strings"
	"unicode"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

type Service struct {
	repository Repository
	config     Config
}

func NewService(repository Repository, config Config) (*Service, error) {
	if repository == nil || !validConfig(config) {
		return nil, ErrInvalidConfiguration
	}
	config.SupportedEntityTypes = append([]domain.EntityType(nil), config.SupportedEntityTypes...)
	return &Service{repository: repository, config: config}, nil
}

func (s *Service) Get(ctx context.Context, ownerUserID uuid.UUID) (Snapshot, error) {
	if ctx == nil || ownerUserID == uuid.Nil {
		return Snapshot{}, ErrInvalidRequest
	}
	if err := ctx.Err(); err != nil {
		return Snapshot{}, err
	}
	usage, err := s.repository.GetUsage(ctx, ownerUserID)
	if err != nil {
		return Snapshot{}, err
	}

	remaining := uint64(0)
	if usage.ActiveSavedItems < s.config.MaxActiveSavedItems {
		remaining = s.config.MaxActiveSavedItems - usage.ActiveSavedItems
	}
	result := Snapshot{
		CapabilityRevision:    s.config.CapabilityRevision,
		ProductFlags:          s.config.ProductFlags,
		HasConfirmedSavedData: usage.ActiveSavedItems > 0 || usage.ActiveCollections > 0,
		SupportedEntityTypes:  append([]domain.EntityType(nil), s.config.SupportedEntityTypes...),
	}
	if remaining <= s.config.QuotaWarningRemaining {
		result.QuotaWarning = &QuotaWarning{
			Resource:  quotaResourceSavedItems,
			Limit:     s.config.MaxActiveSavedItems,
			Remaining: remaining,
		}
	}
	return result, nil
}

func validConfig(config Config) bool {
	if config.CapabilityRevision == "" || len(config.CapabilityRevision) > 128 ||
		config.CapabilityRevision != strings.TrimSpace(config.CapabilityRevision) ||
		strings.IndexFunc(config.CapabilityRevision, unicode.IsControl) >= 0 ||
		config.MaxActiveSavedItems == 0 ||
		config.QuotaWarningRemaining > config.MaxActiveSavedItems ||
		(!config.ProductFlags.SavedItemsEnabled &&
			(config.ProductFlags.SearchEnabled || config.ProductFlags.CollectionsEnabled)) ||
		len(config.SupportedEntityTypes) == 0 || len(config.SupportedEntityTypes) > 4 {
		return false
	}
	seen := make(map[domain.EntityType]struct{}, len(config.SupportedEntityTypes))
	for _, entityType := range config.SupportedEntityTypes {
		if !entityType.IsValid() {
			return false
		}
		if _, exists := seen[entityType]; exists {
			return false
		}
		seen[entityType] = struct{}{}
	}
	return true
}
