package http

import (
	"context"
	"errors"
	"net/http"
	"strings"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/app/cursor"
	"kz/inflap/backend/services/saved-service/internal/app/productrollout"
	"kz/inflap/backend/services/saved-service/internal/app/savedsearch"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

const maxSavedSearchBodyBytes = 16 * 1024

var ErrInvalidSavedSearchHandlerDependencies = errors.New("invalid saved search handler dependencies")

type SavedSearchUseCase interface {
	Search(context.Context, savedsearch.Input) (savedsearch.Page, error)
}

// SavedSearchObserver receives only bounded operational outcomes. Search text,
// owner identifiers, and result contents are deliberately excluded.
type SavedSearchObserver interface {
	ObserveSavedSearch(zeroResults bool)
}

type SavedSearchHandler struct {
	useCase       SavedSearchUseCase
	cursors       CursorCodec
	fingerprinter ScopeFingerprinter
	observer      SavedSearchObserver
}

func NewSavedSearchHandler(
	useCase SavedSearchUseCase,
	cursors CursorCodec,
	fingerprinter ScopeFingerprinter,
	observers ...SavedSearchObserver,
) (*SavedSearchHandler, error) {
	if useCase == nil || cursors == nil || fingerprinter == nil || len(observers) > 1 {
		return nil, ErrInvalidSavedSearchHandlerDependencies
	}
	var observer SavedSearchObserver
	if len(observers) == 1 {
		observer = observers[0]
	}
	return &SavedSearchHandler{
		useCase:       useCase,
		cursors:       cursors,
		fingerprinter: fingerprinter,
		observer:      observer,
	}, nil
}

func (h *SavedSearchHandler) Register(mux *http.ServeMux) error {
	if h == nil || h.useCase == nil || h.cursors == nil || h.fingerprinter == nil || mux == nil {
		return ErrInvalidSavedSearchHandlerDependencies
	}
	mux.HandleFunc("POST /v1/users/me/saved-items/query", h.Search)
	return nil
}

func (h *SavedSearchHandler) Search(w http.ResponseWriter, r *http.Request) {
	principal, ok := PersonalPrincipalFromContext(r.Context())
	if !ok {
		writePersonalAuthError(w, r, "UNAUTHENTICATED")
		return
	}
	if !productExpansionAllowed(r.Context(), productrollout.CapabilitySavedSearch) {
		writeNotFound(w, r)
		return
	}
	request, term, err := decodeSavedSearchRequest(w, r)
	if err != nil {
		writeInvalidArgument(w, r)
		return
	}
	locale := effectiveSavedQueryLocale(r.Header.Get("Accept-Language"))
	scope := cursor.Scope{
		EntityType:   request.EntityType,
		CollectionID: request.CollectionID,
		Uncollected:  request.Uncollected,
		Search:       term.Normalized(),
		Locale:       cursor.Locale(locale),
	}
	fingerprint, err := h.fingerprinter.Fingerprint(scope)
	if err != nil {
		writeInvalidArgument(w, r)
		return
	}

	var after *savedsearch.Keyset
	if request.Cursor != "" {
		position, decodeErr := h.cursors.Decode(request.Cursor, cursor.DecodeExpectation{
			Subject:          principal.UserID.String(),
			ScopeFingerprint: fingerprint,
			Locale:           cursor.Locale(locale),
		})
		if decodeErr != nil || position.MatchRank == nil ||
			*position.MatchRank < int64(savedsearch.MatchRankTitleExact) ||
			*position.MatchRank > int64(savedsearch.MatchRankLocationPrefix) {
			writeDomainError(w, r, domain.ErrCursorInvalid)
			return
		}
		after = &savedsearch.Keyset{
			MatchRank: savedsearch.MatchRank(*position.MatchRank),
			SavedAt:   position.SavedAt,
			ItemID:    position.ItemID,
		}
	}

	page, err := h.useCase.Search(r.Context(), savedsearch.Input{
		OwnerUserID: principal.UserID,
		Locale:      locale,
		EntityType:  request.EntityType,
		Collection:  request.CollectionID,
		Uncollected: request.Uncollected,
		Search:      term.Normalized(),
		After:       after,
		Limit:       request.Limit,
	})
	if err != nil {
		writeSavedSearchError(w, r, err)
		return
	}

	response := savedItemsSearchPageResponse{
		Items:   make([]savedSearchItemResponse, 0, len(page.Items)),
		HasMore: page.HasMore,
	}
	for _, item := range page.Items {
		base, mapErr := mapSavedItem(item.Item)
		if mapErr != nil {
			writeDomainError(w, r, domain.ErrTemporarilyUnavailable)
			return
		}
		response.Items = append(response.Items, savedSearchItemResponse{
			Target:                   base.Target,
			Relationship:             base.Relationship,
			EffectiveCollectionCount: base.EffectiveCollectionCount,
			Projection:               base.Projection,
			Match: savedSearchMatchResponse{
				MatchRank:                   uint8(item.Match.Rank),
				MatchKind:                   item.Match.Kind,
				MatchedField:                item.Match.Field,
				MatchedLocale:               strings.ToLower(string(item.Match.Locale)),
				AlternatePublicDisplayValue: item.Match.AlternatePublicDisplay,
			},
		})
	}
	if page.Next != nil {
		rank := int64(page.Next.MatchRank)
		token, encodeErr := h.cursors.Encode(cursor.EncodeInput{
			Subject:          principal.UserID.String(),
			ScopeFingerprint: fingerprint,
			Locale:           cursor.Locale(locale),
			Position: cursor.Position{
				SavedAt:   page.Next.SavedAt,
				ItemID:    page.Next.ItemID,
				MatchRank: &rank,
			},
		})
		if encodeErr != nil {
			writeDomainError(w, r, domain.ErrTemporarilyUnavailable)
			return
		}
		response.NextCursor = &token
	}
	if request.Cursor == "" {
		observeSavedSearch(h.observer, len(response.Items) == 0)
	}
	writePersonalJSON(w, r, http.StatusOK, response)
}

func observeSavedSearch(observer SavedSearchObserver, zeroResults bool) {
	if observer == nil {
		return
	}
	defer func() {
		_ = recover()
	}()
	observer.ObserveSavedSearch(zeroResults)
}

type savedSearchRequest struct {
	EntityType   *domain.EntityType
	CollectionID *uuid.UUID
	Uncollected  bool
	Cursor       string
	Limit        int
}

func decodeSavedSearchRequest(
	w http.ResponseWriter,
	r *http.Request,
) (savedSearchRequest, savedsearch.SearchTerm, error) {
	var body struct {
		EntityType   *string `json:"type"`
		CollectionID *string `json:"collection_id"`
		Uncollected  bool    `json:"uncollected"`
		Search       string  `json:"search"`
		Cursor       *string `json:"cursor"`
		Limit        *int    `json:"limit"`
	}
	if err := DecodeBoundedJSON(w, r, maxSavedSearchBodyBytes, &body); err != nil {
		return savedSearchRequest{}, savedsearch.SearchTerm{}, err
	}
	term, err := savedsearch.Normalize(body.Search)
	if err != nil {
		return savedSearchRequest{}, savedsearch.SearchTerm{}, err
	}
	result := savedSearchRequest{Uncollected: body.Uncollected, Limit: savedsearch.DefaultPageLimit}
	if body.EntityType != nil {
		entityType := domain.EntityType(*body.EntityType)
		if !entityType.IsValid() {
			return savedSearchRequest{}, savedsearch.SearchTerm{}, savedsearch.ErrInvalidQuery
		}
		result.EntityType = &entityType
	}
	if body.CollectionID != nil {
		collectionID, parseErr := uuid.Parse(*body.CollectionID)
		if parseErr != nil || collectionID == uuid.Nil || collectionID.String() != *body.CollectionID ||
			body.Uncollected {
			return savedSearchRequest{}, savedsearch.SearchTerm{}, savedsearch.ErrInvalidQuery
		}
		result.CollectionID = &collectionID
	}
	if body.Cursor != nil {
		if *body.Cursor == "" || *body.Cursor != strings.TrimSpace(*body.Cursor) {
			return savedSearchRequest{}, savedsearch.SearchTerm{}, savedsearch.ErrInvalidQuery
		}
		result.Cursor = *body.Cursor
	}
	if body.Limit != nil {
		if *body.Limit < 1 || *body.Limit > savedsearch.MaxPageLimit {
			return savedSearchRequest{}, savedsearch.SearchTerm{}, savedsearch.ErrInvalidQuery
		}
		result.Limit = *body.Limit
	}
	return result, term, nil
}

type savedItemsSearchPageResponse struct {
	Items      []savedSearchItemResponse `json:"items"`
	NextCursor *string                   `json:"next_cursor"`
	HasMore    bool                      `json:"has_more"`
}

type savedSearchItemResponse struct {
	Target                   savedTargetResponse        `json:"target"`
	Relationship             activeRelationshipResponse `json:"relationship"`
	EffectiveCollectionCount uint32                     `json:"effective_collection_count"`
	Projection               any                        `json:"projection"`
	Match                    savedSearchMatchResponse   `json:"match"`
}

type savedSearchMatchResponse struct {
	MatchRank                   uint8                    `json:"match_rank"`
	MatchKind                   savedsearch.MatchKind    `json:"match_kind"`
	MatchedField                savedsearch.MatchedField `json:"matched_field"`
	MatchedLocale               string                   `json:"matched_locale"`
	AlternatePublicDisplayValue *string                  `json:"alternate_public_display_value,omitempty"`
}

func writeSavedSearchError(w http.ResponseWriter, r *http.Request, err error) {
	switch {
	case errors.Is(err, savedsearch.ErrInvalidQuery):
		writeInvalidArgument(w, r)
	case errors.Is(err, savedsearch.ErrCollectionNotFound):
		writeNotFound(w, r)
	default:
		writeDomainError(w, r, domain.ErrTemporarilyUnavailable)
	}
}
