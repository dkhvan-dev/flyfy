package http

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/app/cursor"
	"kz/inflap/backend/services/saved-service/internal/app/productrollout"
	"kz/inflap/backend/services/saved-service/internal/app/savedquery"
	"kz/inflap/backend/services/saved-service/internal/app/savedsearch"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestSavedSearchHandlerReturnsBoundedMatchMetadata(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC().Truncate(time.Microsecond)
	target := mustHTTPQueryTarget(t, domain.EntityTypeAttraction)
	itemID := uuid.New()
	alternate := "Астана"
	useCase := &stubSavedSearchUseCase{page: savedsearch.Page{
		Items: []savedsearch.Item{{
			Item: savedquery.Item{
				ItemID: itemID,
				Target: target,
				Relationship: savedquery.ActiveRelationship{
					Generation: uuid.New(), Version: 2, SavedAt: now, AttributionID: uuid.New(),
				},
				Projection: savedquery.CardProjection{
					ContentState: savedquery.ContentStateAvailable,
					Revisions:    savedquery.SourceRevisions{Source: 1, Projection: 2, Visibility: 3},
					Public: &savedquery.PublicCardProjection{
						DisplayLocale:        savedquery.LocaleRU,
						Title:                "Национальный музей",
						CanonicalDetailRoute: "/attractions/" + target.EntityID(),
						SourceUpdatedAt:      now,
					},
				},
			},
			Match: savedsearch.Match{
				Rank: savedsearch.MatchRankLocationExactOrToken, Kind: savedsearch.MatchKindExact,
				Field: savedsearch.MatchedFieldCity, Locale: savedquery.LocaleRU,
				AlternatePublicDisplay: &alternate,
			},
		}},
		Next:    &savedsearch.Keyset{MatchRank: savedsearch.MatchRankLocationExactOrToken, SavedAt: now, ItemID: itemID},
		HasMore: true,
	}}
	handler := newSavedSearchTestHandler(t, useCase)
	request := queryRequestWithPrincipal(
		http.MethodPost,
		"/v1/users/me/saved-items/query",
		strings.NewReader(`{"type":"ATTRACTION","search":"  АСТАНА!! ","limit":1}`),
	)
	request.Header.Set("Accept-Language", "ru-KZ")
	recorder := httptest.NewRecorder()
	handler.Search(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status=%d body=%s", recorder.Code, recorder.Body.String())
	}
	if useCase.input.Search != "астана" || useCase.input.Locale != savedquery.LocaleRU ||
		useCase.input.EntityType == nil || *useCase.input.EntityType != domain.EntityTypeAttraction {
		t.Fatalf("input = %+v", useCase.input)
	}
	body := recorder.Body.String()
	for _, value := range []string{
		`"match_rank":4`, `"match_kind":"EXACT"`, `"matched_field":"CITY"`,
		`"matched_locale":"ru"`, `"alternate_public_display_value":"Астана"`, `"next_cursor":"`,
	} {
		if !strings.Contains(body, value) {
			t.Errorf("response missing %s: %s", value, body)
		}
	}
	for _, forbidden := range []string{"АСТАНА!!", "opaque_reference", "attribution_id"} {
		if strings.Contains(body, forbidden) {
			t.Errorf("response leaked %q: %s", forbidden, body)
		}
	}
}

func TestSavedSearchHandlerFailsClosedBeforeParsingWhenRolloutIsDisabled(t *testing.T) {
	t.Parallel()

	useCase := &stubSavedSearchUseCase{}
	handler := newSavedSearchTestHandler(t, useCase)
	request := queryRequestWithPrincipal(
		http.MethodPost,
		"/v1/users/me/saved-items/query",
		strings.NewReader(`{"search":"Astana"}`),
	)
	request = request.WithContext(context.WithValue(
		request.Context(),
		productRolloutContextKey{},
		productrollout.Decision{},
	))
	recorder := httptest.NewRecorder()

	handler.Search(recorder, request)

	if recorder.Code != http.StatusNotFound || useCase.calls != 0 {
		t.Fatalf("status=%d calls=%d body=%s", recorder.Code, useCase.calls, recorder.Body.String())
	}
}

func TestSavedSearchHandlerObservesOnlySuccessfulFirstPageOutcome(t *testing.T) {
	t.Parallel()

	observer := &stubSavedSearchObserver{}
	handler := newSavedSearchTestHandler(
		t,
		&stubSavedSearchUseCase{page: savedsearch.Page{}},
		observer,
	)
	request := queryRequestWithPrincipal(
		http.MethodPost,
		"/v1/users/me/saved-items/query",
		strings.NewReader(`{"search":"Astana"}`),
	)
	recorder := httptest.NewRecorder()

	handler.Search(recorder, request)

	if recorder.Code != http.StatusOK || len(observer.zeroResults) != 1 || !observer.zeroResults[0] {
		t.Fatalf("status=%d observations=%v body=%s", recorder.Code, observer.zeroResults, recorder.Body.String())
	}
}

func TestSavedSearchCursorIsBoundToNormalizedSearchAndFilters(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC().Truncate(time.Microsecond)
	target := mustHTTPQueryTarget(t, domain.EntityTypeGuide)
	itemID := uuid.New()
	useCase := &stubSavedSearchUseCase{page: savedsearch.Page{
		Items: []savedsearch.Item{{
			Item: savedquery.Item{
				ItemID: itemID,
				Target: target,
				Relationship: savedquery.ActiveRelationship{
					Generation: uuid.New(), Version: 1, SavedAt: now, AttributionID: uuid.New(),
				},
				Projection: savedquery.CardProjection{
					ContentState: savedquery.ContentStateAvailable,
					Revisions:    savedquery.SourceRevisions{Source: 1, Projection: 1, Visibility: 1},
					Public: &savedquery.PublicCardProjection{
						DisplayLocale:        savedquery.LocaleEN,
						Title:                "Aruzhan",
						CanonicalDetailRoute: "/guides/" + target.EntityID(),
						SourceUpdatedAt:      now,
					},
				},
			},
			Match: savedsearch.Match{Rank: savedsearch.MatchRankTitleExact, Kind: savedsearch.MatchKindExact,
				Field: savedsearch.MatchedFieldTitle, Locale: savedquery.LocaleEN},
		}},
		Next:    &savedsearch.Keyset{MatchRank: savedsearch.MatchRankTitleExact, SavedAt: now, ItemID: itemID},
		HasMore: true,
	}}
	handler := newSavedSearchTestHandler(t, useCase)
	first := httptest.NewRecorder()
	firstRequest := queryRequestWithPrincipal(http.MethodPost, "/v1/users/me/saved-items/query", strings.NewReader(`{"search":"ARUZHAN"}`))
	firstRequest.Header.Set("Accept-Language", "en")
	handler.Search(first, firstRequest)
	if first.Code != http.StatusOK {
		t.Fatalf("first status=%d body=%s", first.Code, first.Body.String())
	}
	var page savedItemsSearchPageResponse
	if err := json.NewDecoder(first.Body).Decode(&page); err != nil || page.NextCursor == nil {
		t.Fatalf("decode first page: cursor=%v err=%v", page.NextCursor, err)
	}

	wrongSearchBody := `{"search":"another","cursor":"` + *page.NextCursor + `"}`
	wrong := httptest.NewRecorder()
	wrongRequest := queryRequestWithPrincipal(http.MethodPost, "/v1/users/me/saved-items/query", strings.NewReader(wrongSearchBody))
	wrongRequest.Header.Set("Accept-Language", "en")
	handler.Search(wrong, wrongRequest)
	if wrong.Code != http.StatusBadRequest || !strings.Contains(wrong.Body.String(), string(domain.ErrorCodeCursorInvalid)) {
		t.Fatalf("wrong-search status=%d body=%s", wrong.Code, wrong.Body.String())
	}
	if useCase.calls != 1 {
		t.Fatalf("search calls=%d, cursor mismatch reached use case", useCase.calls)
	}
}

func TestSavedSearchHandlerRejectsUnknownFieldsAndConflictingScope(t *testing.T) {
	t.Parallel()

	useCase := &stubSavedSearchUseCase{}
	handler := newSavedSearchTestHandler(t, useCase)
	for _, body := range []string{
		`{"search":"museum","owner_id":"forged"}`,
		`{"search":"museum","collection_id":"11111111-1111-4111-8111-111111111111","uncollected":true}`,
		`{"search":"   !!!   "}`,
		`{"search":"museum","limit":101}`,
	} {
		recorder := httptest.NewRecorder()
		handler.Search(recorder, queryRequestWithPrincipal(http.MethodPost, "/v1/users/me/saved-items/query", strings.NewReader(body)))
		if recorder.Code != http.StatusBadRequest {
			t.Errorf("body=%s status=%d response=%s", body, recorder.Code, recorder.Body.String())
		}
	}
	if useCase.calls != 0 {
		t.Fatalf("search calls=%d", useCase.calls)
	}
}

func newSavedSearchTestHandler(
	t *testing.T,
	useCase SavedSearchUseCase,
	observers ...SavedSearchObserver,
) *SavedSearchHandler {
	t.Helper()
	codec, err := cursor.NewCodec([]cursor.Key{{ID: 1, Secret: bytes.Repeat([]byte{0x42}, 32)}}, 1, 15*time.Minute)
	if err != nil {
		t.Fatalf("cursor.NewCodec() error=%v", err)
	}
	fingerprinter, err := cursor.NewFingerprinter(bytes.Repeat([]byte{0x24}, 32))
	if err != nil {
		t.Fatalf("cursor.NewFingerprinter() error=%v", err)
	}
	handler, err := NewSavedSearchHandler(useCase, codec, fingerprinter, observers...)
	if err != nil {
		t.Fatalf("NewSavedSearchHandler() error=%v", err)
	}
	return handler
}

type stubSavedSearchObserver struct {
	zeroResults []bool
}

func (observer *stubSavedSearchObserver) ObserveSavedSearch(zeroResults bool) {
	observer.zeroResults = append(observer.zeroResults, zeroResults)
}

type stubSavedSearchUseCase struct {
	page  savedsearch.Page
	err   error
	input savedsearch.Input
	calls int
}

func (s *stubSavedSearchUseCase) Search(_ context.Context, input savedsearch.Input) (savedsearch.Page, error) {
	s.calls++
	s.input = input
	return s.page, s.err
}

var _ SavedSearchUseCase = (*stubSavedSearchUseCase)(nil)
