package place

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(r *http.Request) (*http.Response, error) {
	return f(r)
}

func TestStartMediaBackfillPostsCountryCode(t *testing.T) {
	t.Parallel()

	client := NewClient("http://place-service", time.Second, "internal-token")
	client.httpClient.Transport = roundTripFunc(func(r *http.Request) (*http.Response, error) {
		if r.Method != http.MethodPost {
			t.Fatalf("method = %s, want POST", r.Method)
		}
		if r.URL.Path != "/internal/v1/admin/places/media/backfill" {
			t.Fatalf("path = %s", r.URL.Path)
		}
		if got := r.Header.Get("X-Internal-Service-Token"); got != "internal-token" {
			t.Fatalf("X-Internal-Service-Token = %q", got)
		}

		var request struct {
			CountryCode string `json:"countryCode"`
		}
		if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
			t.Fatalf("decode request: %v", err)
		}
		if request.CountryCode != "KZ" {
			t.Fatalf("countryCode = %q, want KZ", request.CountryCode)
		}

		return &http.Response{
			StatusCode: http.StatusAccepted,
			Body:       io.NopCloser(strings.NewReader(`{"jobId":"job-123","countryCode":"KZ","status":"STARTED"}`)),
		}, nil
	})

	job, err := client.StartMediaBackfill(context.Background(), "kz")
	if err != nil {
		t.Fatalf("StartMediaBackfill() error = %v", err)
	}
	if job.JobID != "job-123" || job.CountryCode != "KZ" || job.Status != "STARTED" {
		t.Fatalf("unexpected job: %#v", job)
	}
}

func TestListPlacesAcceptsOpeningHoursObject(t *testing.T) {
	t.Parallel()

	client := NewClient("http://place-service", time.Second, "internal-token")
	client.httpClient.Transport = roundTripFunc(func(r *http.Request) (*http.Response, error) {
		if r.Method != http.MethodGet {
			t.Fatalf("method = %s, want GET", r.Method)
		}
		if r.URL.Path != "/internal/v1/admin/places" {
			t.Fatalf("path = %s", r.URL.Path)
		}

		body := `{
			"items": [{
				"id": "6a8c779b-d407-444d-8e83-721584858516",
				"defaultLocale": "ru",
				"title": "Крест Магеллана",
				"description": "Историческая часовня",
				"countryCode": "PH",
				"cityId": "cebu-city",
				"category": "ARCHITECTURE",
				"status": "PUBLISHED",
				"visitInfo": {
					"openingHours": {
						"is24Hours": false,
						"summary": "Ежедневно 10:00-18:00"
					}
				},
				"translations": {},
				"media": [],
				"createdAt": "2026-06-22T13:58:42Z",
				"updatedAt": "2026-06-24T02:04:16Z"
			}],
			"total": 1
		}`
		return &http.Response{
			StatusCode: http.StatusOK,
			Body:       io.NopCloser(strings.NewReader(body)),
		}, nil
	})

	items, total, err := client.ListPlaces(context.Background(), model.AdminPlaceFilter{Limit: 25})
	if err != nil {
		t.Fatalf("ListPlaces() error = %v", err)
	}
	if total != 1 || len(items) != 1 {
		t.Fatalf("total/items = %d/%d, want 1/1", total, len(items))
	}
	if got := items[0].VisitInfo.OpeningHours; got != "Ежедневно 10:00-18:00" {
		t.Fatalf("opening hours = %q", got)
	}
}

func TestCreatePlaceSendsOpeningHoursObject(t *testing.T) {
	t.Parallel()

	client := NewClient("http://place-service", time.Second, "internal-token")
	client.httpClient.Transport = roundTripFunc(func(r *http.Request) (*http.Response, error) {
		if r.Method != http.MethodPost {
			t.Fatalf("method = %s, want POST", r.Method)
		}
		if r.URL.Path != "/internal/v1/admin/places" {
			t.Fatalf("path = %s", r.URL.Path)
		}
		var request struct {
			VisitInfo *struct {
				OpeningHours *struct {
					Summary map[string]string `json:"summary"`
				} `json:"openingHours"`
			} `json:"visitInfo"`
		}
		if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
			t.Fatalf("decode request: %v", err)
		}
		if request.VisitInfo == nil || request.VisitInfo.OpeningHours == nil {
			t.Fatalf("openingHours object was not sent: %#v", request.VisitInfo)
		}
		if got := request.VisitInfo.OpeningHours.Summary["ru"]; got != "Ежедневно 10:00-18:00" {
			t.Fatalf("openingHours.summary.ru = %q", got)
		}

		return &http.Response{
			StatusCode: http.StatusCreated,
			Body: io.NopCloser(strings.NewReader(`{
				"id": "6a8c779b-d407-444d-8e83-721584858516",
				"defaultLocale": "ru",
				"title": "Крест Магеллана",
				"description": "Историческая часовня",
				"countryCode": "PH",
				"cityId": "cebu-city",
				"category": "ARCHITECTURE",
				"status": "PUBLISHED",
				"visitInfo": {},
				"translations": {},
				"media": [],
				"createdAt": "2026-06-22T13:58:42Z",
				"updatedAt": "2026-06-24T02:04:16Z"
			}`)),
		}, nil
	})

	_, err := client.CreatePlace(context.Background(), model.PlaceInput{
		DefaultLocale: "ru",
		VisitInfo: &model.PlaceVisitInfo{
			OpeningHours: "Ежедневно 10:00-18:00",
		},
	})
	if err != nil {
		t.Fatalf("CreatePlace() error = %v", err)
	}
}
