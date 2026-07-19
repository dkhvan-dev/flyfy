package http

import (
	"context"
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/app/cursor"
	"kz/inflap/backend/services/saved-service/internal/app/savedquery"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

const maxBatchStatusBodyBytes = 32 * 1024

var ErrInvalidSavedQueryHandlerDependencies = errors.New("invalid saved query handler dependencies")

type SavedQueryUseCase interface {
	BatchStatus(context.Context, uuid.UUID, []domain.SavedTarget) ([]savedquery.TargetStatus, error)
	ListItems(context.Context, savedquery.ListInput) (savedquery.Page, error)
}

type CursorCodec interface {
	Encode(cursor.EncodeInput) (string, error)
	Decode(string, cursor.DecodeExpectation) (cursor.Position, error)
}

type ScopeFingerprinter interface {
	Fingerprint(cursor.Scope) ([32]byte, error)
}

type SavedQueryHandler struct {
	useCase       SavedQueryUseCase
	cursors       CursorCodec
	fingerprinter ScopeFingerprinter
}

func NewSavedQueryHandler(
	useCase SavedQueryUseCase,
	cursors CursorCodec,
	fingerprinter ScopeFingerprinter,
) (*SavedQueryHandler, error) {
	if useCase == nil || cursors == nil || fingerprinter == nil {
		return nil, ErrInvalidSavedQueryHandlerDependencies
	}
	return &SavedQueryHandler{
		useCase:       useCase,
		cursors:       cursors,
		fingerprinter: fingerprinter,
	}, nil
}

func (h *SavedQueryHandler) Register(mux *http.ServeMux) error {
	if h == nil || h.useCase == nil || h.cursors == nil || h.fingerprinter == nil || mux == nil {
		return ErrInvalidSavedQueryHandlerDependencies
	}
	mux.HandleFunc("GET /v1/users/me/saved-items", h.List)
	mux.HandleFunc("POST /v1/users/me/saved-items/status:batch", h.BatchStatus)
	return nil
}

func (h *SavedQueryHandler) BatchStatus(w http.ResponseWriter, r *http.Request) {
	principal, ok := PersonalPrincipalFromContext(r.Context())
	if !ok {
		writePersonalAuthError(w, r, "UNAUTHENTICATED")
		return
	}
	var body struct {
		Targets []savedTargetRequest `json:"targets"`
	}
	if err := DecodeBoundedJSON(w, r, maxBatchStatusBodyBytes, &body); err != nil ||
		len(body.Targets) == 0 || len(body.Targets) > savedquery.MaxBatchTargets {
		writeInvalidArgument(w, r)
		return
	}
	targets := make([]domain.SavedTarget, 0, len(body.Targets))
	for _, input := range body.Targets {
		target, err := domain.NewSavedTarget(domain.EntityType(input.EntityType), input.EntityID)
		if err != nil {
			writeInvalidArgument(w, r)
			return
		}
		targets = append(targets, target)
	}
	statuses, err := h.useCase.BatchStatus(r.Context(), principal.UserID, targets)
	if err != nil {
		writeSavedQueryError(w, r, err)
		return
	}
	response := struct {
		Statuses []savedTargetStatusResponse `json:"statuses"`
	}{Statuses: make([]savedTargetStatusResponse, 0, len(statuses))}
	for _, status := range statuses {
		response.Statuses = append(response.Statuses, mapTargetStatus(status))
	}
	writePersonalJSON(w, r, http.StatusOK, response)
}

func (h *SavedQueryHandler) List(w http.ResponseWriter, r *http.Request) {
	principal, ok := PersonalPrincipalFromContext(r.Context())
	if !ok {
		writePersonalAuthError(w, r, "UNAUTHENTICATED")
		return
	}
	parsed, err := parseSavedListQuery(r)
	if err != nil {
		writeInvalidArgument(w, r)
		return
	}
	locale := effectiveSavedQueryLocale(r.Header.Get("Accept-Language"))
	scope := cursor.Scope{
		EntityType:   parsed.EntityType,
		CollectionID: parsed.CollectionID,
		Uncollected:  parsed.Uncollected,
		Locale:       cursor.Locale(locale),
	}
	fingerprint, err := h.fingerprinter.Fingerprint(scope)
	if err != nil {
		writeInvalidArgument(w, r)
		return
	}
	var after *savedquery.Keyset
	if parsed.Cursor != "" {
		position, err := h.cursors.Decode(parsed.Cursor, cursor.DecodeExpectation{
			Subject:          principal.UserID.String(),
			ScopeFingerprint: fingerprint,
			Locale:           cursor.Locale(locale),
		})
		if err != nil || position.MatchRank != nil {
			writeDomainError(w, r, domain.ErrCursorInvalid)
			return
		}
		after = &savedquery.Keyset{SavedAt: position.SavedAt, ItemID: position.ItemID}
	}
	page, err := h.useCase.ListItems(r.Context(), savedquery.ListInput{
		OwnerUserID: principal.UserID,
		Locale:      locale,
		EntityType:  parsed.EntityType,
		Collection:  parsed.CollectionID,
		Uncollected: parsed.Uncollected,
		After:       after,
		Limit:       parsed.Limit,
	})
	if err != nil {
		writeSavedQueryError(w, r, err)
		return
	}
	response := savedItemsPageResponse{
		Items:   make([]savedItemResponse, 0, len(page.Items)),
		HasMore: page.HasMore,
	}
	for _, item := range page.Items {
		mapped, err := mapSavedItem(item)
		if err != nil {
			writeDomainError(w, r, domain.ErrTemporarilyUnavailable)
			return
		}
		response.Items = append(response.Items, mapped)
	}
	if page.Next != nil {
		token, err := h.cursors.Encode(cursor.EncodeInput{
			Subject:          principal.UserID.String(),
			ScopeFingerprint: fingerprint,
			Locale:           cursor.Locale(locale),
			Position: cursor.Position{
				SavedAt: page.Next.SavedAt,
				ItemID:  page.Next.ItemID,
			},
		})
		if err != nil {
			writeDomainError(w, r, domain.ErrTemporarilyUnavailable)
			return
		}
		response.NextCursor = &token
	}
	writePersonalJSON(w, r, http.StatusOK, response)
}

type savedListQuery struct {
	EntityType   *domain.EntityType
	CollectionID *uuid.UUID
	Uncollected  bool
	Cursor       string
	Limit        int
}

func parseSavedListQuery(r *http.Request) (savedListQuery, error) {
	if r == nil {
		return savedListQuery{}, savedquery.ErrInvalidQuery
	}
	values := r.URL.Query()
	allowed := map[string]struct{}{
		"type": {}, "collection_id": {}, "uncollected": {}, "cursor": {}, "limit": {},
	}
	for key, entries := range values {
		if _, ok := allowed[key]; !ok || len(entries) != 1 {
			return savedListQuery{}, savedquery.ErrInvalidQuery
		}
	}
	result := savedListQuery{Limit: savedquery.DefaultPageLimit}
	if entries, exists := values["type"]; exists {
		entityType := domain.EntityType(entries[0])
		if !entityType.IsValid() {
			return savedListQuery{}, savedquery.ErrInvalidQuery
		}
		result.EntityType = &entityType
	}
	if entries, exists := values["collection_id"]; exists {
		collectionID, err := uuid.Parse(entries[0])
		if err != nil || collectionID == uuid.Nil || collectionID.String() != entries[0] {
			return savedListQuery{}, savedquery.ErrInvalidQuery
		}
		result.CollectionID = &collectionID
	}
	if entries, exists := values["uncollected"]; exists {
		if entries[0] != "true" && entries[0] != "false" {
			return savedListQuery{}, savedquery.ErrInvalidQuery
		}
		result.Uncollected = entries[0] == "true"
	}
	if result.CollectionID != nil && result.Uncollected {
		return savedListQuery{}, savedquery.ErrInvalidQuery
	}
	if entries, exists := values["cursor"]; exists {
		if entries[0] == "" || entries[0] != strings.TrimSpace(entries[0]) {
			return savedListQuery{}, savedquery.ErrInvalidQuery
		}
		result.Cursor = entries[0]
	}
	if entries, exists := values["limit"]; exists {
		limit, err := strconv.Atoi(entries[0])
		if err != nil || limit < 1 || limit > savedquery.MaxPageLimit {
			return savedListQuery{}, savedquery.ErrInvalidQuery
		}
		result.Limit = limit
	}
	return result, nil
}

type savedTargetRequest struct {
	EntityType string `json:"entity_type"`
	EntityID   string `json:"entity_id"`
}

type savedTargetResponse struct {
	EntityType domain.EntityType `json:"entity_type"`
	EntityID   string            `json:"entity_id"`
}

type savedTargetStatusResponse struct {
	Target                   savedTargetResponse        `json:"target"`
	SavedState               savedquery.SavedState      `json:"saved_state"`
	EffectiveCollectionCount uint32                     `json:"effective_collection_count"`
	EligibilityHint          savedquery.EligibilityHint `json:"eligibility_hint"`
	RelationshipGeneration   *string                    `json:"relationship_generation,omitempty"`
	ResourceVersion          uint64                     `json:"resource_version"`
}

type savedItemsPageResponse struct {
	Items      []savedItemResponse `json:"items"`
	NextCursor *string             `json:"next_cursor"`
	HasMore    bool                `json:"has_more"`
}

type savedItemResponse struct {
	Target                   savedTargetResponse        `json:"target"`
	Relationship             activeRelationshipResponse `json:"relationship"`
	EffectiveCollectionCount uint32                     `json:"effective_collection_count"`
	Projection               any                        `json:"projection"`
}

type activeRelationshipResponse struct {
	Generation string    `json:"generation"`
	Version    uint64    `json:"version"`
	SavedAt    time.Time `json:"saved_at"`
}

type availableProjectionResponse struct {
	ProjectionVersion    uint64                  `json:"projection_version"`
	ContentState         savedquery.ContentState `json:"content_state"`
	DisplayLocale        string                  `json:"display_locale"`
	Title                string                  `json:"title"`
	Subtitle             *string                 `json:"subtitle,omitempty"`
	ImageURL             *string                 `json:"image_url,omitempty"`
	CanonicalDetailRoute string                  `json:"canonical_detail_route"`
	SourceUpdatedAt      time.Time               `json:"source_updated_at"`
}

type unavailableProjectionResponse struct {
	ProjectionVersion uint64                  `json:"projection_version"`
	ContentState      savedquery.ContentState `json:"content_state"`
}

func mapTargetStatus(status savedquery.TargetStatus) savedTargetStatusResponse {
	response := savedTargetStatusResponse{
		Target:                   mapSavedTarget(status.Target),
		SavedState:               status.SavedState,
		EffectiveCollectionCount: status.EffectiveCollectionCount,
		EligibilityHint:          status.Eligibility,
		ResourceVersion:          status.ResourceVersion,
	}
	if status.RelationshipGeneration != nil {
		generation := status.RelationshipGeneration.String()
		response.RelationshipGeneration = &generation
	}
	return response
}

func mapSavedItem(item savedquery.Item) (savedItemResponse, error) {
	response := savedItemResponse{
		Target: mapSavedTarget(item.Target),
		Relationship: activeRelationshipResponse{
			Generation: item.Relationship.Generation.String(),
			Version:    item.Relationship.Version,
			SavedAt:    item.Relationship.SavedAt.UTC(),
		},
		EffectiveCollectionCount: item.EffectiveCollectionCount,
	}
	switch item.Projection.ContentState {
	case savedquery.ContentStateAvailable:
		if item.Projection.Public == nil {
			return savedItemResponse{}, savedquery.ErrDataInvariant
		}
		response.Projection = availableProjectionResponse{
			ProjectionVersion:    item.Projection.Revisions.Projection,
			ContentState:         savedquery.ContentStateAvailable,
			DisplayLocale:        strings.ToLower(string(item.Projection.Public.DisplayLocale)),
			Title:                item.Projection.Public.Title,
			Subtitle:             item.Projection.Public.Subtitle,
			ImageURL:             item.Projection.Public.ResolvedImageURL,
			CanonicalDetailRoute: item.Projection.Public.CanonicalDetailRoute,
			SourceUpdatedAt:      item.Projection.Public.SourceUpdatedAt.UTC(),
		}
	case savedquery.ContentStateUnavailable:
		response.Projection = unavailableProjectionResponse{
			ProjectionVersion: item.Projection.Revisions.Projection,
			ContentState:      savedquery.ContentStateUnavailable,
		}
	default:
		return savedItemResponse{}, savedquery.ErrDataInvariant
	}
	return response, nil
}

func mapSavedTarget(target domain.SavedTarget) savedTargetResponse {
	return savedTargetResponse{EntityType: target.EntityType(), EntityID: target.EntityID()}
}

func effectiveSavedQueryLocale(value string) savedquery.Locale {
	switch effectiveErrorLocale(value) {
	case "en":
		return savedquery.LocaleEN
	case "kk":
		return savedquery.LocaleKK
	default:
		return savedquery.LocaleRU
	}
}

func writeSavedQueryError(w http.ResponseWriter, r *http.Request, err error) {
	switch {
	case errors.Is(err, savedquery.ErrInvalidQuery):
		writeInvalidArgument(w, r)
	case errors.Is(err, savedquery.ErrCollectionNotFound):
		writeNotFound(w, r)
	default:
		writeDomainError(w, r, domain.ErrTemporarilyUnavailable)
	}
}
