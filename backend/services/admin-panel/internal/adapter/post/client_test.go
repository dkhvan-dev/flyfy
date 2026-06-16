package post

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
	"kz/inflap/backend/services/admin-panel/internal/domain/port"
)

func TestClientCreateCommunitySendsLocalizedPayload(t *testing.T) {
	t.Parallel()

	actorID := uuid.New()
	communityID := uuid.New()
	var gotPath string
	var gotMethod string
	var gotAuthSubject string
	var gotUserID string
	var gotInternalToken string
	var gotRequestID string
	var gotPayload map[string]any

	client := NewClient("https://posts.internal", time.Second, "internal-token")
	client.httpClient.Transport = roundTripFunc(func(r *http.Request) (*http.Response, error) {
		gotPath = r.URL.Path
		gotMethod = r.Method
		gotAuthSubject = r.Header.Get("X-Auth-Subject")
		gotUserID = r.Header.Get("X-User-Id")
		gotInternalToken = r.Header.Get("X-Internal-Service-Token")
		gotRequestID = r.Header.Get("X-Request-Id")
		if err := json.NewDecoder(r.Body).Decode(&gotPayload); err != nil {
			t.Fatalf("decode request payload: %v", err)
		}
		return &http.Response{
			StatusCode: http.StatusCreated,
			Header:     http.Header{"Content-Type": []string{"application/json"}},
			Body: io.NopCloser(strings.NewReader(`{
				"id":"` + communityID.String() + `",
				"slug":"city-guides",
				"title":"Городские гиды",
				"titleI18n":{"ru":"Городские гиды","en":"City guides","kk":"Қала гидтері"},
				"description":"Лучшие маршруты от местных",
				"descriptionI18n":{"ru":"Лучшие маршруты от местных","en":"Local routes","kk":"Жергілікті маршруттар"},
				"rules":["Без спама"],
				"rulesI18n":{"ru":["Без спама"],"en":["No spam"],"kk":["Спам жоқ"]},
				"topic":"GUIDES",
				"visibility":"PUBLIC",
				"postingPolicy":"MEMBERS_AFTER_MODERATION",
				"status":"ACTIVE",
				"membersCount":0,
				"postCount":0,
				"createdAt":"2026-06-13T08:00:00Z",
				"updatedAt":"2026-06-13T08:00:00Z"
			}`)),
		}, nil
	})

	created, err := client.CreateCommunity(context.Background(), port.CreateCommunityInput{
		ActorStaffID: actorID,
		Slug:         "city-guides",
		TitleI18n: map[string]string{
			"ru": "Городские гиды",
			"en": "City guides",
			"kk": "Қала гидтері",
		},
		DescriptionI18n: map[string]string{
			"ru": "Лучшие маршруты от местных",
			"en": "Local routes",
			"kk": "Жергілікті маршруттар",
		},
		RulesI18n: map[string][]string{
			"ru": []string{"Без спама"},
			"en": []string{"No spam"},
			"kk": []string{"Спам жоқ"},
		},
		Topic:         "GUIDES",
		Visibility:    "PUBLIC",
		PostingPolicy: "MEMBERS_AFTER_MODERATION",
		Status:        "ACTIVE",
		RequestID:     "request-123",
	})

	if err != nil {
		t.Fatalf("CreateCommunity() error = %v", err)
	}
	if created.ID != communityID || created.TitleI18n["en"] != "City guides" || created.RulesI18n["kk"][0] != "Спам жоқ" {
		t.Fatalf("created = %+v, want decoded localized community", created)
	}
	if gotMethod != http.MethodPost || gotPath != "/internal/v1/communities" {
		t.Fatalf("request = %s %s, want POST /internal/v1/communities", gotMethod, gotPath)
	}
	if gotAuthSubject != "admin-panel:"+actorID.String() || gotUserID != actorID.String() {
		t.Fatalf("actor headers = %q %q, want actor staff id", gotAuthSubject, gotUserID)
	}
	if gotInternalToken != "internal-token" || gotRequestID != "request-123" {
		t.Fatalf("internal/request headers = %q/%q", gotInternalToken, gotRequestID)
	}
	if gotPayload["slug"] != "city-guides" || gotPayload["topic"] != "GUIDES" {
		t.Fatalf("payload = %+v, want normalized slug/topic", gotPayload)
	}
	if titleI18n, ok := gotPayload["titleI18n"].(map[string]any); !ok || titleI18n["kk"] != "Қала гидтері" {
		t.Fatalf("titleI18n payload = %#v", gotPayload["titleI18n"])
	}
}

func TestClientListFeedQualityMetricsCallsInternalReadOnlyEndpoint(t *testing.T) {
	t.Parallel()

	var gotPath string
	var gotAuth string
	client := NewClient("https://posts.internal", time.Second, "internal-token")
	client.httpClient.Transport = roundTripFunc(func(r *http.Request) (*http.Response, error) {
		gotPath = r.URL.String()
		gotAuth = r.Header.Get("Authorization")
		if r.Method != http.MethodGet {
			t.Fatalf("method = %s, want GET", r.Method)
		}
		return &http.Response{
			StatusCode: http.StatusOK,
			Header:     http.Header{"Content-Type": []string{"application/json"}},
			Body:       io.NopCloser(strings.NewReader(`{"items":[{"surface":"home","tab":"for_you","blockType":"post_card","rankingExperiment":"rank-v2","candidateSource":"social","communityId":"00000000-0000-4000-8000-000000000222","action":"conversion","postProfile":"event_announcement_v1","eventCount":12,"uniqueViewers":7,"impressionCount":20,"clickCount":8,"dwellCount":5,"avgDwellMs":4200,"likeCount":3,"commentCount":2,"shareCount":1,"subscribeCount":4,"conversionCount":4,"hideCount":1,"notInterestedCount":2,"reportCount":3}]}`)),
		}, nil
	})

	metrics, err := client.ListFeedQualityMetrics(context.Background(), model.FeedQualityMetricFilter{
		Since:   time.Date(2026, 5, 1, 0, 0, 0, 0, time.UTC),
		Until:   time.Date(2026, 5, 8, 0, 0, 0, 0, time.UTC),
		Surface: "home",
		Limit:   25,
	})

	if err != nil {
		t.Fatalf("ListFeedQualityMetrics() error = %v", err)
	}
	if len(metrics) != 1 ||
		metrics[0].Tab != "for_you" ||
		metrics[0].RankingExperiment != "rank-v2" ||
		metrics[0].CandidateSource != "social" ||
		metrics[0].CommunityID != "00000000-0000-4000-8000-000000000222" ||
		metrics[0].PostProfile != "event_announcement_v1" ||
		metrics[0].ImpressionCount != 20 ||
		metrics[0].ClickCount != 8 ||
		metrics[0].DwellCount != 5 ||
		metrics[0].AvgDwellMs != 4200 ||
		metrics[0].LikeCount != 3 ||
		metrics[0].CommentCount != 2 ||
		metrics[0].ShareCount != 1 ||
		metrics[0].SubscribeCount != 4 ||
		metrics[0].ConversionCount != 4 ||
		metrics[0].NotInterestedCount != 2 ||
		metrics[0].ReportCount != 3 {
		t.Fatalf("metrics = %+v, want decoded aggregate", metrics)
	}
	for _, expected := range []string{
		"/internal/v1/feed/quality-metrics?",
		"since=2026-05-01T00%3A00%3A00Z",
		"until=2026-05-08T00%3A00%3A00Z",
		"surface=home",
		"limit=25",
	} {
		if !strings.Contains(gotPath, expected) {
			t.Fatalf("path = %q, missing %q", gotPath, expected)
		}
	}
	if gotAuth != "Bearer internal-token" {
		t.Fatalf("Authorization = %q, want internal bearer token", gotAuth)
	}
}

func TestClientCommunityPlatformCatalogCallsInternalEndpoints(t *testing.T) {
	t.Parallel()

	requests := make([]string, 0, 4)
	client := NewClient("https://posts.internal", time.Second, "internal-token")
	client.httpClient.Transport = roundTripFunc(func(r *http.Request) (*http.Response, error) {
		if r.Method != http.MethodGet {
			t.Fatalf("method = %s, want GET", r.Method)
		}
		if r.Header.Get("Authorization") != "Bearer internal-token" {
			t.Fatalf("Authorization = %q, want bearer internal token", r.Header.Get("Authorization"))
		}
		requests = append(requests, r.URL.String())
		body := `{"items":[]}`
		switch r.URL.Path {
		case "/internal/v1/community-post-profiles":
			body = `{"items":[{"key":"quick_post_v1","version":1,"postKind":"QUICK_POST","composerPreset":"quick_post","renderPreset":"quick_post_card","moderationMode":"PUBLISH_FIRST","activityCreationMode":"DISABLED","createdAt":"2026-06-13T08:00:00Z","updatedAt":"2026-06-13T08:00:00Z"}]}`
		case "/internal/v1/community-blueprints":
			body = `{"items":[{"id":"00000000-0000-4000-8000-000000000014","key":"football","category":"sports","defaultPostProfileKey":"event_announcement_v1","titleI18n":{"ru":"Футбол","en":"Football","kk":"Футбол"},"descriptionI18n":{"ru":"Игры"},"iconKey":"football","rolloutPolicy":"ELIGIBLE_HUBS","allowedScopeTypes":["CITY"],"defaultModerationMode":"TRUSTED_PUBLISH_ELSE_REVIEW","status":"ACTIVE","createdAt":"2026-06-13T08:00:00Z","updatedAt":"2026-06-13T08:00:00Z"}]}`
		case "/internal/v1/community-geo-hubs":
			body = `{"items":[{"countryCode":"VN","cityId":"da-nang","hubTier":"REGIONAL","communityEnabled":true,"reason":"tourist_demand","priority":30,"canMaterialize":true,"effectiveCountryCode":"VN","effectiveCityId":"da-nang","createdBy":"seed","updatedAt":"2026-06-13T08:00:00Z"}]}`
		case "/internal/v1/community-instances":
			body = `{"items":[{"id":"00000000-0000-4000-8000-000000000111","communityId":"00000000-0000-4000-8000-000000000222","blueprintId":"00000000-0000-4000-8000-000000000014","slug":"football-vn-da-nang","countryCode":"VN","cityId":"da-nang","scopeType":"CITY","titleI18n":{"ru":"Футбол · da-nang"},"descriptionI18n":{"ru":"Игры"},"status":"ACTIVE","memberCount":0,"postCount":0,"createdAt":"2026-06-13T08:00:00Z","updatedAt":"2026-06-13T08:00:00Z"}]}`
		default:
			t.Fatalf("unexpected path %s", r.URL.Path)
		}
		return &http.Response{
			StatusCode: http.StatusOK,
			Header:     http.Header{"Content-Type": []string{"application/json"}},
			Body:       io.NopCloser(strings.NewReader(body)),
		}, nil
	})

	catalog, err := client.CommunityPlatformCatalog(context.Background(), port.CommunityPlatformCatalogInput{
		CountryCode: "VN",
		CityID:      "da-nang",
		ScopeType:   "CITY",
		Search:      "foot",
		Limit:       25,
		Offset:      5,
	})
	if err != nil {
		t.Fatalf("CommunityPlatformCatalog() error = %v", err)
	}
	if len(catalog.PostProfiles) != 1 || catalog.PostProfiles[0].Key != "quick_post_v1" ||
		len(catalog.Blueprints) != 1 || catalog.Blueprints[0].Key != "football" ||
		len(catalog.GeoHubs) != 1 || catalog.GeoHubs[0].EffectiveCityID != "da-nang" ||
		len(catalog.Instances) != 1 || catalog.Instances[0].Slug != "football-vn-da-nang" {
		t.Fatalf("catalog = %+v", catalog)
	}
	joined := strings.Join(requests, "\n")
	for _, expected := range []string{
		"/internal/v1/community-post-profiles?limit=25&offset=5",
		"/internal/v1/community-blueprints?limit=25&offset=5&q=foot",
		"/internal/v1/community-geo-hubs?countryCode=VN&includeAliasOnly=true&limit=25&offset=5",
		"/internal/v1/community-instances?cityId=da-nang&countryCode=VN&limit=25&offset=5&q=foot&scopeType=CITY",
	} {
		if !strings.Contains(joined, expected) {
			t.Fatalf("requests = %q, missing %q", joined, expected)
		}
	}
}

func TestClientMaterializeCommunityInstancesPostsInternalPayload(t *testing.T) {
	t.Parallel()

	actorID := uuid.New()
	blueprintID := uuid.New()
	var gotPath string
	var gotMethod string
	var gotUserID string
	var gotRequestID string
	var gotPayload map[string]any

	client := NewClient("https://posts.internal", time.Second, "internal-token")
	client.httpClient.Transport = roundTripFunc(func(r *http.Request) (*http.Response, error) {
		gotPath = r.URL.Path
		gotMethod = r.Method
		gotUserID = r.Header.Get("X-User-Id")
		gotRequestID = r.Header.Get("X-Request-Id")
		if err := json.NewDecoder(r.Body).Decode(&gotPayload); err != nil {
			t.Fatalf("decode materialize payload: %v", err)
		}
		return &http.Response{
			StatusCode: http.StatusOK,
			Header:     http.Header{"Content-Type": []string{"application/json"}},
			Body:       io.NopCloser(strings.NewReader(`{"materializedCount":45}`)),
		}, nil
	})

	result, err := client.MaterializeCommunityInstances(context.Background(), port.MaterializeCommunityInstancesInput{
		ActorStaffID: actorID,
		BlueprintID:  blueprintID,
		CountryCode:  "VN",
		CityID:       "da-nang",
		ScopeType:    "CITY",
		Limit:        50,
		RequestID:    "req-2",
	})
	if err != nil {
		t.Fatalf("MaterializeCommunityInstances() error = %v", err)
	}
	if result.MaterializedCount != 45 {
		t.Fatalf("result = %+v", result)
	}
	if gotMethod != http.MethodPost || gotPath != "/internal/v1/community-instances/materialize" {
		t.Fatalf("request = %s %s", gotMethod, gotPath)
	}
	if gotUserID != actorID.String() || gotRequestID != "req-2" {
		t.Fatalf("headers user/request = %q/%q", gotUserID, gotRequestID)
	}
	if gotPayload["blueprintId"] != blueprintID.String() || gotPayload["countryCode"] != "VN" ||
		gotPayload["cityId"] != "da-nang" || gotPayload["scopeType"] != "CITY" ||
		gotPayload["limit"].(float64) != 50 {
		t.Fatalf("payload = %#v", gotPayload)
	}
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(r *http.Request) (*http.Response, error) {
	return f(r)
}
