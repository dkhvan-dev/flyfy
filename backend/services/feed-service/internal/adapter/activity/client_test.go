package activity

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"net/http"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/model"
)

func TestBuildCreateActivityFromPostRequestMapsStructuredEvent(t *testing.T) {
	postID := uuid.New()
	authorID := uuid.New()
	coverID := uuid.New()
	startAt := time.Date(2026, 6, 14, 10, 0, 0, 0, time.UTC)
	structured := mustActivityJSON(t, map[string]any{
		"title":        "Йога у моря",
		"description":  "Утренняя практика для новичков",
		"starts_at":    startAt.Format(time.RFC3339),
		"capacity":     12,
		"price":        map[string]any{"amount": 15.0, "currency": "USD"},
		"coverFileId":  coverID.String(),
		"languageCode": "ru",
		"timezone":     "Asia/Almaty",
		"location": map[string]any{
			"addressText": "Da Nang beach",
			"cityId":      "danang",
			"countryCode": "VN",
			"latitude":    16.0471,
			"longitude":   108.2068,
		},
		"tags": []any{"yoga", "morning"},
	})
	event := model.PostActivityIntentEvent{
		ID:             uuid.New(),
		IdempotencyKey: "post:" + postID.String() + ":activity:v1",
		PostID:         postID,
		AuthorUserID:   authorID,
		PostProfileKey: "event_announcement_v1",
		StructuredData: structured,
	}

	req, err := buildCreateActivityFromPostRequest(event)
	if err != nil {
		t.Fatalf("buildCreateActivityFromPostRequest() error = %v", err)
	}

	if req.HostUserID != authorID.String() {
		t.Fatalf("HostUserID = %q, want %q", req.HostUserID, authorID.String())
	}
	if req.Title != "Йога у моря" || req.Description != "Утренняя практика для новичков" {
		t.Fatalf("unexpected title/description: %q / %q", req.Title, req.Description)
	}
	if req.Format != "OFFLINE" {
		t.Fatalf("Format = %q, want OFFLINE", req.Format)
	}
	if req.CategorySlug != "other" || req.SubcategorySlug == nil || *req.SubcategorySlug != "community-event" {
		t.Fatalf("category = %q/%v, want other/community-event", req.CategorySlug, req.SubcategorySlug)
	}
	if req.CapacityType != "LIMITED" || req.MaxParticipants == nil || *req.MaxParticipants != 12 {
		t.Fatalf("capacity = %q/%v, want LIMITED/12", req.CapacityType, req.MaxParticipants)
	}
	if req.PriceType != "PAID" || req.PriceAmount == nil || *req.PriceAmount != 15 || req.Currency == nil || *req.Currency != "USD" {
		t.Fatalf("price = %q/%v/%v, want PAID/15/USD", req.PriceType, req.PriceAmount, req.Currency)
	}
	if req.CoverFileID == nil || *req.CoverFileID != coverID.String() {
		t.Fatalf("CoverFileID = %v, want %s", req.CoverFileID, coverID)
	}
	if req.AddressText == nil || *req.AddressText != "Da Nang beach" {
		t.Fatalf("AddressText = %v, want Da Nang beach", req.AddressText)
	}
	if req.EndAt != startAt.Add(defaultActivityDuration).UTC().Format(time.RFC3339) {
		t.Fatalf("EndAt = %q, want default duration", req.EndAt)
	}
}

func TestClientPublishesActivityIntentWithInternalHeaders(t *testing.T) {
	activityID := uuid.New()
	var gotPath string
	var gotToken string
	var gotService string
	var gotIdempotency string
	var gotPayload createActivityFromPostRequest
	transport := roundTripFunc(func(r *http.Request) (*http.Response, error) {
		gotPath = r.URL.Path
		gotToken = r.Header.Get(internalTokenHeader)
		gotService = r.Header.Get(internalServiceNameHeader)
		gotIdempotency = r.Header.Get("Idempotency-Key")
		if err := json.NewDecoder(r.Body).Decode(&gotPayload); err != nil {
			t.Fatalf("decode request: %v", err)
		}
		return &http.Response{
			StatusCode: http.StatusCreated,
			Header:     http.Header{"Content-Type": []string{"application/json"}},
			Body:       io.NopCloser(bytes.NewBufferString(`{"id":"` + activityID.String() + `"}`)),
		}, nil
	})

	postID := uuid.New()
	event := model.PostActivityIntentEvent{
		ID:             uuid.New(),
		IdempotencyKey: "post:" + postID.String() + ":activity:v1",
		PostID:         postID,
		AuthorUserID:   uuid.New(),
		PostProfileKey: "trip_plan_v1",
		StructuredData: mustActivityJSON(t, map[string]any{
			"title":          "Поездка в горы",
			"route":          "Da Nang -> Ba Na Hills",
			"starts_at":      "2026-06-14T08:00:00Z",
			"meeting_point":  "Dragon Bridge",
			"createActivity": true,
		}),
	}
	client := New("http://activity-service.test", "internal-token", "feed-service", time.Second)
	client.httpClient.Transport = transport

	gotActivityID, err := client.PublishPostActivityIntent(context.Background(), event)
	if err != nil {
		t.Fatalf("PublishPostActivityIntent() error = %v", err)
	}

	if gotActivityID != activityID {
		t.Fatalf("activity id = %s, want %s", gotActivityID, activityID)
	}
	if gotPath != internalCreateActivityFromPostPath {
		t.Fatalf("path = %q, want %q", gotPath, internalCreateActivityFromPostPath)
	}
	if gotToken != "internal-token" || gotService != "feed-service" {
		t.Fatalf("headers token/service = %q/%q, want internal-token/feed-service", gotToken, gotService)
	}
	if gotIdempotency != event.IdempotencyKey || gotPayload.IdempotencyKey != event.IdempotencyKey {
		t.Fatalf("idempotency = %q/%q, want %q", gotIdempotency, gotPayload.IdempotencyKey, event.IdempotencyKey)
	}
	if gotPayload.HostUserID != event.AuthorUserID.String() || gotPayload.SourcePostID != postID.String() {
		t.Fatalf("host/source = %q/%q, want %q/%q", gotPayload.HostUserID, gotPayload.SourcePostID, event.AuthorUserID, postID)
	}
	if gotPayload.CategorySlug != "nature-outdoor" || gotPayload.SubcategorySlug == nil || *gotPayload.SubcategorySlug != "day-trip" {
		t.Fatalf("category = %q/%v, want nature-outdoor/day-trip", gotPayload.CategorySlug, gotPayload.SubcategorySlug)
	}
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(req *http.Request) (*http.Response, error) {
	return f(req)
}

func mustActivityJSON(t *testing.T, value map[string]any) []byte {
	t.Helper()
	raw, err := json.Marshal(value)
	if err != nil {
		t.Fatalf("marshal test json: %v", err)
	}
	return raw
}
