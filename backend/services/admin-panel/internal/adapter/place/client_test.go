package place

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

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

func TestListVisitReferencesFetchesLocalizedCatalog(t *testing.T) {
	t.Parallel()

	client := NewClient("http://place-service", time.Second, "internal-token")
	client.httpClient.Transport = roundTripFunc(func(r *http.Request) (*http.Response, error) {
		if r.Method != http.MethodGet {
			t.Fatalf("method = %s, want GET", r.Method)
		}
		if r.URL.Path != "/internal/v1/admin/place-visit-references" {
			t.Fatalf("path = %s", r.URL.Path)
		}
		if got := r.URL.Query().Get("locale"); got != "ru" {
			t.Fatalf("locale query = %q, want ru", got)
		}
		if got := r.Header.Get("X-Internal-Service-Token"); got != "internal-token" {
			t.Fatalf("X-Internal-Service-Token = %q", got)
		}

		body := `{
			"categories": {
				"fee_type": [
					{"code":"ENTRANCE","label":"Вход","labels":{"ru":"Вход","en":"Entrance","kk":"Кіру"},"sortOrder":10,"active":true}
				],
				"road_condition": [
					{"code":"PAVED","label":"Асфальт","labels":{"ru":"Асфальт","en":"Paved","kk":"Асфальт"},"sortOrder":10,"active":true}
				]
			}
		}`
		return &http.Response{
			StatusCode: http.StatusOK,
			Body:       io.NopCloser(strings.NewReader(body)),
		}, nil
	})

	catalog, err := client.ListVisitReferences(context.Background(), "ru")
	if err != nil {
		t.Fatalf("ListVisitReferences() error = %v", err)
	}
	if got := catalog.Categories["fee_type"][0].Label; got != "Вход" {
		t.Fatalf("fee_type label = %q, want Вход", got)
	}
	if got := catalog.Categories["road_condition"][0].Labels["en"]; got != "Paved" {
		t.Fatalf("road condition en label = %q, want Paved", got)
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

func TestListPlacesMapsVisitPlanningDetails(t *testing.T) {
	t.Parallel()

	client := NewClient("http://place-service", time.Second, "internal-token")
	client.httpClient.Transport = roundTripFunc(func(r *http.Request) (*http.Response, error) {
		if r.Method != http.MethodGet {
			t.Fatalf("method = %s, want GET", r.Method)
		}
		body := `{
			"items": [{
				"id": "6a8c779b-d407-444d-8e83-721584858516",
				"defaultLocale": "ru",
				"title": "Чарынский каньон",
				"description": "Каньон",
				"countryCode": "KZ",
				"cityId": "almaty",
				"category": "NATURE",
				"status": "PUBLISHED",
				"visitInfo": {
					"priceNote": "Билет и экосбор оплачиваются отдельно",
					"timeOnSite": {"minMinutes": 90, "maxMinutes": 150, "note": "Без трека к реке"},
					"carTravelTime": {"minMinutes": 180, "maxMinutes": 240, "note": "От Алматы"},
					"roadCondition": "PAVED",
					"feeDetails": [{
						"title": "Вход",
						"description": "Базовый билет",
						"amount": 1000,
						"currency": "KZT",
						"unit": "PERSON",
						"isApproximate": true,
						"sortOrder": 10
					}],
					"feeItems": [{
						"type": "ENTRANCE",
						"title": "Вход в парк",
						"minAmount": 1000,
						"maxAmount": 1000,
						"currency": "KZT",
						"unit": "PERSON",
						"required": true,
						"isApproximate": true,
						"note": "Цена может меняться",
						"sortOrder": 10
					}],
					"accessOptions": [{
						"transportType": "CAR",
						"durationMinMinutes": 180,
						"durationMaxMinutes": 240,
						"routeHint": "Трасса на Кеген",
						"roadCondition": "PAVED",
						"requires4x4": false,
						"parkingNote": "Парковка у входа",
						"sortOrder": 10
					}],
					"practicalNotes": [{
						"noteType": "WEATHER",
						"title": "Жара",
						"body": "Летом мало тени",
						"priority": "IMPORTANT",
						"sortOrder": 10
					}],
					"recommendedItems": [{
						"itemType": "WATER",
						"title": "Вода",
						"note": "Минимум 1 литр",
						"importance": "REQUIRED",
						"sortOrder": 10
					}]
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

	items, _, err := client.ListPlaces(context.Background(), model.AdminPlaceFilter{Limit: 25})
	if err != nil {
		t.Fatalf("ListPlaces() error = %v", err)
	}
	info := items[0].VisitInfo
	if info.PriceNote != "Билет и экосбор оплачиваются отдельно" {
		t.Fatalf("price note = %q", info.PriceNote)
	}
	if info.TimeOnSite == nil || *info.TimeOnSite.MinMinutes != 90 || info.TimeOnSite.Note != "Без трека к реке" {
		t.Fatalf("timeOnSite = %+v", info.TimeOnSite)
	}
	if len(info.FeeItems) != 1 || info.FeeItems[0].Title != "Вход в парк" || !info.FeeItems[0].Required {
		t.Fatalf("feeItems = %+v", info.FeeItems)
	}
	if len(info.AccessOptions) != 1 || info.AccessOptions[0].RouteHint != "Трасса на Кеген" {
		t.Fatalf("accessOptions = %+v", info.AccessOptions)
	}
	if len(info.PracticalNotes) != 1 || info.PracticalNotes[0].Body != "Летом мало тени" {
		t.Fatalf("practicalNotes = %+v", info.PracticalNotes)
	}
	if len(info.RecommendedItems) != 1 || info.RecommendedItems[0].Title != "Вода" {
		t.Fatalf("recommendedItems = %+v", info.RecommendedItems)
	}
}

func TestGetPlaceMapsLocalizedVisitPlanningDetails(t *testing.T) {
	t.Parallel()

	client := NewClient("http://place-service", time.Second, "internal-token")
	client.httpClient.Transport = roundTripFunc(func(r *http.Request) (*http.Response, error) {
		if r.Method != http.MethodGet {
			t.Fatalf("method = %s, want GET", r.Method)
		}
		if r.URL.Path != "/internal/v1/admin/places/6a8c779b-d407-444d-8e83-721584858516" {
			t.Fatalf("path = %s", r.URL.Path)
		}

		body := `{
			"id": "6a8c779b-d407-444d-8e83-721584858516",
			"defaultLocale": "ru",
			"title": "Чарынский каньон",
			"description": "Каньон",
			"countryCode": "KZ",
			"cityId": "almaty",
			"category": "NATURE",
			"status": "PUBLISHED",
			"visitInfo": {
				"priceNote": "Билет и экосбор оплачиваются отдельно",
				"timeOnSite": {"minMinutes": 90, "maxMinutes": 150, "note": "Без трека к реке"},
				"feeDetails": [{"title": "Вход", "description": "Базовый билет", "amount": 1000, "currency": "KZT", "unit": "PERSON", "isApproximate": true, "sortOrder": 10}]
			},
			"visitInfoLocales": {
				"openingHours": {"ru": "Ежедневно 09:00-18:00", "en": "Daily 09:00-18:00", "kk": "Күн сайын 09:00-18:00"},
				"priceNote": {"ru": "Билет и экосбор отдельно", "en": "Ticket and eco fee are paid separately", "kk": "Билет пен экоалым бөлек төленеді"},
				"timeOnSite": {"minMinutes": 90, "maxMinutes": 150, "note": {"ru": "Без трека к реке", "en": "Without the river trail", "kk": "Өзен соқпағынсыз"}},
				"feeDetails": [{
					"title": {"ru": "Вход", "en": "Admission", "kk": "Кіру"},
					"description": {"ru": "Базовый билет", "en": "Base ticket", "kk": "Негізгі билет"},
					"amount": 1000,
					"currency": "KZT",
					"unit": "PERSON",
					"isApproximate": true,
					"sortOrder": 10
				}]
			},
			"translations": {},
			"media": [],
			"createdAt": "2026-06-22T13:58:42Z",
			"updatedAt": "2026-06-24T02:04:16Z"
		}`
		return &http.Response{
			StatusCode: http.StatusOK,
			Body:       io.NopCloser(strings.NewReader(body)),
		}, nil
	})

	item, err := client.GetPlace(context.Background(), mustUUIDForPlaceClientTest("6a8c779b-d407-444d-8e83-721584858516"))
	if err != nil {
		t.Fatalf("GetPlace() error = %v", err)
	}
	if got := item.VisitInfo.PriceNoteLocales["en"]; got != "Ticket and eco fee are paid separately" {
		t.Fatalf("PriceNoteLocales.en = %q", got)
	}
	if got := item.VisitInfo.OpeningHoursLocales["kk"]; got != "Күн сайын 09:00-18:00" {
		t.Fatalf("OpeningHoursLocales.kk = %q", got)
	}
	if item.VisitInfo.TimeOnSite == nil || item.VisitInfo.TimeOnSite.NoteLocales["kk"] != "Өзен соқпағынсыз" {
		t.Fatalf("TimeOnSite localized note = %#v", item.VisitInfo.TimeOnSite)
	}
	if len(item.VisitInfo.FeeDetails) != 1 || item.VisitInfo.FeeDetails[0].TitleLocales["en"] != "Admission" {
		t.Fatalf("FeeDetails localized title = %#v", item.VisitInfo.FeeDetails)
	}
}

func TestUpdatePlaceSendsVisitPlanningDetails(t *testing.T) {
	t.Parallel()

	client := NewClient("http://place-service", time.Second, "internal-token")
	client.httpClient.Transport = roundTripFunc(func(r *http.Request) (*http.Response, error) {
		if r.Method != http.MethodPut {
			t.Fatalf("method = %s, want PUT", r.Method)
		}
		var request struct {
			VisitInfo *struct {
				PriceNote        map[string]string `json:"priceNote"`
				TimeOnSite       *visitDuration    `json:"timeOnSite"`
				CarTravelTime    *visitDuration    `json:"carTravelTime"`
				RoadCondition    string            `json:"roadCondition"`
				FeeDetails       []feeDetail       `json:"feeDetails"`
				FeeItems         []feeDetail       `json:"feeItems"`
				AccessOptions    []accessOption    `json:"accessOptions"`
				PracticalNotes   []practicalNote   `json:"practicalNotes"`
				RecommendedItems []recommendedItem `json:"recommendedItems"`
			} `json:"visitInfo"`
		}
		if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
			t.Fatalf("decode request: %v", err)
		}
		if request.VisitInfo == nil {
			t.Fatal("visitInfo was not sent")
		}
		if got := request.VisitInfo.PriceNote["ru"]; got != "Билет и экосбор отдельно" {
			t.Fatalf("priceNote.ru = %q", got)
		}
		if request.VisitInfo.TimeOnSite == nil || *request.VisitInfo.TimeOnSite.MinMinutes != 90 {
			t.Fatalf("timeOnSite = %+v", request.VisitInfo.TimeOnSite)
		}
		if len(request.VisitInfo.FeeItems) != 1 || request.VisitInfo.FeeItems[0].Title["ru"] != "Вход в парк" || !request.VisitInfo.FeeItems[0].Required {
			t.Fatalf("feeItems = %+v", request.VisitInfo.FeeItems)
		}
		if len(request.VisitInfo.AccessOptions) != 1 || request.VisitInfo.AccessOptions[0].RouteHint["ru"] != "Трасса на Кеген" {
			t.Fatalf("accessOptions = %+v", request.VisitInfo.AccessOptions)
		}
		if len(request.VisitInfo.PracticalNotes) != 1 || request.VisitInfo.PracticalNotes[0].Body["ru"] != "Летом мало тени" {
			t.Fatalf("practicalNotes = %+v", request.VisitInfo.PracticalNotes)
		}
		if len(request.VisitInfo.RecommendedItems) != 1 || request.VisitInfo.RecommendedItems[0].Title["ru"] != "Вода" {
			t.Fatalf("recommendedItems = %+v", request.VisitInfo.RecommendedItems)
		}

		return &http.Response{
			StatusCode: http.StatusOK,
			Body: io.NopCloser(strings.NewReader(`{
				"id": "6a8c779b-d407-444d-8e83-721584858516",
				"defaultLocale": "ru",
				"title": "Чарынский каньон",
				"description": "Каньон",
				"countryCode": "KZ",
				"cityId": "almaty",
				"category": "NATURE",
				"status": "PUBLISHED",
				"visitInfo": {},
				"translations": {},
				"media": [],
				"createdAt": "2026-06-22T13:58:42Z",
				"updatedAt": "2026-06-24T02:04:16Z"
			}`)),
		}, nil
	})

	minOnSite := 90
	maxOnSite := 150
	minDrive := 180
	maxDrive := 240
	_, err := client.UpdatePlace(context.Background(), mustUUIDForPlaceClientTest("6a8c779b-d407-444d-8e83-721584858516"), model.PlaceInput{
		DefaultLocale: "ru",
		VisitInfo: &model.PlaceVisitInfo{
			PriceNote:     "Билет и экосбор отдельно",
			TimeOnSite:    &model.PlaceVisitDuration{MinMinutes: &minOnSite, MaxMinutes: &maxOnSite, Note: "Без трека к реке"},
			CarTravelTime: &model.PlaceVisitDuration{MinMinutes: &minDrive, MaxMinutes: &maxDrive, Note: "От Алматы"},
			RoadCondition: "PAVED",
			FeeDetails: []model.PlaceFeeDetail{
				{Title: "Вход", Description: "Базовый билет", Amount: floatPtrForPlaceClientTest(1000), Currency: "KZT", Unit: "PERSON", IsApproximate: true, SortOrder: 10},
			},
			FeeItems: []model.PlaceFeeDetail{
				{Type: "ENTRANCE", Title: "Вход в парк", MinAmount: floatPtrForPlaceClientTest(1000), MaxAmount: floatPtrForPlaceClientTest(1000), Currency: "KZT", Unit: "PERSON", Required: true, IsApproximate: true, Note: "Цена может меняться", SortOrder: 10},
			},
			AccessOptions: []model.PlaceAccessOption{
				{TransportType: "CAR", DurationMinMinutes: &minDrive, DurationMaxMinutes: &maxDrive, RouteHint: "Трасса на Кеген", RoadCondition: "PAVED", ParkingNote: "Парковка у входа", SortOrder: 10},
			},
			PracticalNotes: []model.PlacePracticalNote{
				{NoteType: "WEATHER", Title: "Жара", Body: "Летом мало тени", Priority: "IMPORTANT", SortOrder: 10},
			},
			RecommendedItems: []model.PlaceRecommendedItem{
				{ItemType: "WATER", Title: "Вода", Note: "Минимум 1 литр", Importance: "REQUIRED", SortOrder: 10},
			},
		},
	})
	if err != nil {
		t.Fatalf("UpdatePlace() error = %v", err)
	}
}

func TestUpdatePlaceSendsLocalizedVisitPlanningDetails(t *testing.T) {
	t.Parallel()

	client := NewClient("http://place-service", time.Second, "internal-token")
	client.httpClient.Transport = roundTripFunc(func(r *http.Request) (*http.Response, error) {
		var request struct {
			VisitInfo *struct {
				OpeningHours *struct {
					Summary map[string]string `json:"summary"`
				} `json:"openingHours"`
				PriceNote  map[string]string `json:"priceNote"`
				TimeOnSite *struct {
					Note map[string]string `json:"note"`
				} `json:"timeOnSite"`
				FeeDetails []struct {
					Title       map[string]string `json:"title"`
					Description map[string]string `json:"description"`
				} `json:"feeDetails"`
			} `json:"visitInfo"`
		}
		if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
			t.Fatalf("decode request: %v", err)
		}
		if request.VisitInfo == nil {
			t.Fatal("visitInfo was not sent")
		}
		if got := request.VisitInfo.OpeningHours.Summary["kk"]; got != "Күн сайын 09:00-18:00" {
			t.Fatalf("openingHours.summary.kk = %q", got)
		}
		if got := request.VisitInfo.PriceNote["en"]; got != "Ticket and eco fee are paid separately" {
			t.Fatalf("priceNote.en = %q", got)
		}
		if got := request.VisitInfo.TimeOnSite.Note["kk"]; got != "Өзен соқпағынсыз" {
			t.Fatalf("timeOnSite.note.kk = %q", got)
		}
		if len(request.VisitInfo.FeeDetails) != 1 || request.VisitInfo.FeeDetails[0].Title["ru"] != "Вход" || request.VisitInfo.FeeDetails[0].Description["en"] != "Base ticket" {
			t.Fatalf("localized feeDetails = %#v", request.VisitInfo.FeeDetails)
		}

		return &http.Response{
			StatusCode: http.StatusOK,
			Body: io.NopCloser(strings.NewReader(`{
				"id": "6a8c779b-d407-444d-8e83-721584858516",
				"defaultLocale": "ru",
				"title": "Чарынский каньон",
				"description": "Каньон",
				"countryCode": "KZ",
				"cityId": "almaty",
				"category": "NATURE",
				"status": "PUBLISHED",
				"visitInfo": {},
				"translations": {},
				"media": [],
				"createdAt": "2026-06-22T13:58:42Z",
				"updatedAt": "2026-06-24T02:04:16Z"
			}`)),
		}, nil
	})

	minOnSite := 90
	maxOnSite := 150
	_, err := client.UpdatePlace(context.Background(), mustUUIDForPlaceClientTest("6a8c779b-d407-444d-8e83-721584858516"), model.PlaceInput{
		DefaultLocale: "ru",
		VisitInfo: &model.PlaceVisitInfo{
			OpeningHoursLocales: map[string]string{"ru": "Ежедневно 09:00-18:00", "en": "Daily 09:00-18:00", "kk": "Күн сайын 09:00-18:00"},
			PriceNoteLocales:    map[string]string{"ru": "Билет и экосбор отдельно", "en": "Ticket and eco fee are paid separately", "kk": "Билет пен экоалым бөлек төленеді"},
			TimeOnSite: &model.PlaceVisitDuration{
				MinMinutes: &minOnSite,
				MaxMinutes: &maxOnSite,
				NoteLocales: map[string]string{
					"ru": "Без трека к реке",
					"en": "Without the river trail",
					"kk": "Өзен соқпағынсыз",
				},
			},
			FeeDetails: []model.PlaceFeeDetail{
				{
					TitleLocales:       map[string]string{"ru": "Вход", "en": "Admission", "kk": "Кіру"},
					DescriptionLocales: map[string]string{"ru": "Базовый билет", "en": "Base ticket", "kk": "Негізгі билет"},
					Amount:             floatPtrForPlaceClientTest(1000),
					Currency:           "KZT",
					Unit:               "PERSON",
					IsApproximate:      true,
					SortOrder:          10,
				},
			},
		},
	})
	if err != nil {
		t.Fatalf("UpdatePlace() error = %v", err)
	}
}

func mustUUIDForPlaceClientTest(raw string) uuid.UUID {
	id, err := uuid.Parse(raw)
	if err != nil {
		panic(err)
	}
	return id
}

func floatPtrForPlaceClientTest(value float64) *float64 {
	return &value
}
