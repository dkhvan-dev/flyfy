package http

import (
	"context"
	"errors"
	"net/http"
	"strings"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/app/savedcapability"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

var ErrInvalidSavedCapabilitiesHandlerDependencies = errors.New("invalid Saved capabilities handler dependencies")

type SavedCapabilitiesUseCase interface {
	Get(context.Context, uuid.UUID) (savedcapability.Snapshot, error)
}

type SavedCapabilitiesHandler struct {
	useCase SavedCapabilitiesUseCase
}

func NewSavedCapabilitiesHandler(useCase SavedCapabilitiesUseCase) (*SavedCapabilitiesHandler, error) {
	if useCase == nil {
		return nil, ErrInvalidSavedCapabilitiesHandlerDependencies
	}
	return &SavedCapabilitiesHandler{useCase: useCase}, nil
}

func (handler *SavedCapabilitiesHandler) Register(mux *http.ServeMux) error {
	if handler == nil || handler.useCase == nil || mux == nil {
		return ErrInvalidSavedCapabilitiesHandlerDependencies
	}
	mux.HandleFunc("GET /v1/users/me/saved-items/capabilities", handler.Get)
	return nil
}

func (handler *SavedCapabilitiesHandler) Get(w http.ResponseWriter, r *http.Request) {
	principal, ok := PersonalPrincipalFromContext(r.Context())
	if !ok {
		writePersonalAuthError(w, r, "UNAUTHENTICATED")
		return
	}
	if r.URL.RawQuery != "" || RequireEmptyBody(w, r) != nil {
		writeInvalidArgument(w, r)
		return
	}
	snapshot, err := handler.useCase.Get(r.Context(), principal.UserID)
	if err != nil {
		writeDomainError(w, r, domain.ErrTemporarilyUnavailable)
		return
	}

	flags := snapshot.ProductFlags
	supportedEntityTypes := append([]domain.EntityType(nil), snapshot.SupportedEntityTypes...)
	if rollout, evaluated := ProductRolloutDecisionFromContext(r.Context()); evaluated {
		flags.SavedItemsEnabled = flags.SavedItemsEnabled && rollout.SavedCore
		flags.SearchEnabled = flags.SearchEnabled && rollout.SavedSearch
		flags.CollectionsEnabled = flags.CollectionsEnabled && rollout.SavedCollections
		filtered := supportedEntityTypes[:0]
		for _, entityType := range supportedEntityTypes {
			capability := entityRolloutCapability(entityType)
			if capability.IsValid() && rollout.Allows(capability) {
				filtered = append(filtered, entityType)
			}
		}
		supportedEntityTypes = filtered
	}

	response := savedCapabilitiesResponse{
		CapabilityRevision: snapshot.CapabilityRevision,
		ProductFlags: savedProductFlagsResponse{
			SavedItemsEnabled:  flags.SavedItemsEnabled,
			SearchEnabled:      flags.SearchEnabled,
			CollectionsEnabled: flags.CollectionsEnabled,
		},
		HasConfirmedSavedData: snapshot.HasConfirmedSavedData,
		SupportedEntityTypes:  supportedEntityTypes,
		EffectiveLocale:       strings.ToLower(string(effectiveSavedQueryLocale(r.Header.Get("Accept-Language")))),
	}
	if snapshot.QuotaWarning != nil {
		response.QuotaWarning = &quotaWarningResponse{
			Resource:  snapshot.QuotaWarning.Resource,
			Limit:     snapshot.QuotaWarning.Limit,
			Remaining: snapshot.QuotaWarning.Remaining,
		}
	}
	writePersonalJSON(w, r, http.StatusOK, response)
}

type savedCapabilitiesResponse struct {
	CapabilityRevision    string                    `json:"capability_revision"`
	ProductFlags          savedProductFlagsResponse `json:"product_flags"`
	HasConfirmedSavedData bool                      `json:"has_confirmed_saved_data"`
	SupportedEntityTypes  []domain.EntityType       `json:"supported_entity_types"`
	EffectiveLocale       string                    `json:"effective_locale"`
	QuotaWarning          *quotaWarningResponse     `json:"quota_warning,omitempty"`
}

type savedProductFlagsResponse struct {
	SavedItemsEnabled  bool `json:"saved_items_enabled"`
	SearchEnabled      bool `json:"search_enabled"`
	CollectionsEnabled bool `json:"collections_enabled"`
}

type quotaWarningResponse struct {
	Resource  string `json:"resource"`
	Limit     uint64 `json:"limit"`
	Remaining uint64 `json:"remaining"`
}
