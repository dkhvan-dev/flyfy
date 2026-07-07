package searchindex

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"net/http"
	"testing"
	"time"

	"kz/inflap/backend/services/excursion-service/internal/app"
)

func TestClientUpsertSearchDocumentSendsInternalEventRequest(t *testing.T) {
	t.Parallel()

	var gotPath string
	var gotToken string
	var gotPayload map[string]any
	client := New("http://search-service:8101", "internal-token", 2*time.Second)
	client.httpClient.Transport = roundTripFunc(func(r *http.Request) (*http.Response, error) {
		gotPath = r.URL.EscapedPath()
		gotToken = r.Header.Get("X-Internal-Service-Token")
		if r.Method != http.MethodPost {
			t.Fatalf("method = %s, want POST", r.Method)
		}
		if err := json.NewDecoder(r.Body).Decode(&gotPayload); err != nil {
			t.Fatalf("decode payload: %v", err)
		}
		return acceptedResponse(), nil
	})

	err := client.UpsertSearchDocument(t.Context(), app.SearchIndexDocument{
		Domain:               "excursion",
		EntityID:             "excursion-1",
		Locale:               "ru",
		Title:                map[string]string{"ru": "Медеу"},
		DeepLink:             "/excursions/excursion-1",
		SearchTextNormalized: "медеу",
	})
	if err != nil {
		t.Fatalf("UpsertSearchDocument() error = %v", err)
	}

	if gotPath != "/v1/search/index/events" {
		t.Fatalf("path = %q, want /v1/search/index/events", gotPath)
	}
	if gotToken != "internal-token" {
		t.Fatalf("internal token = %q, want internal-token", gotToken)
	}
	if gotPayload["sourceService"] != "excursion-service" ||
		gotPayload["aggregateType"] != "excursion" ||
		gotPayload["aggregateId"] != "excursion-1" ||
		gotPayload["eventType"] != "search_document_upsert" {
		t.Fatalf("event envelope = %#v", gotPayload)
	}
	if sourceEventID, ok := gotPayload["sourceEventId"].(string); !ok || sourceEventID == "" {
		t.Fatalf("sourceEventId = %#v", gotPayload["sourceEventId"])
	}
	payload, ok := gotPayload["payload"].(map[string]any)
	if !ok {
		t.Fatalf("payload = %#v", gotPayload["payload"])
	}
	if payload["domain"] != "excursion" ||
		payload["entityId"] != "excursion-1" ||
		payload["deepLink"] != "/excursions/excursion-1" {
		t.Fatalf("payload = %#v", gotPayload)
	}
}

func TestClientDeleteSearchDocumentSendsInternalEventRequest(t *testing.T) {
	t.Parallel()

	var gotMethod string
	var gotPath string
	var gotToken string
	var gotPayload map[string]any
	client := New("http://search-service:8101", "internal-token", 2*time.Second)
	client.httpClient.Transport = roundTripFunc(func(r *http.Request) (*http.Response, error) {
		gotMethod = r.Method
		gotPath = r.URL.EscapedPath()
		gotToken = r.Header.Get("X-Internal-Service-Token")
		if err := json.NewDecoder(r.Body).Decode(&gotPayload); err != nil {
			t.Fatalf("decode payload: %v", err)
		}
		return acceptedResponse(), nil
	})

	err := client.DeleteSearchDocument(t.Context(), app.SearchIndexDelete{
		Domain:   "excursion",
		EntityID: "excursion/1",
		Locale:   "kk",
	})
	if err != nil {
		t.Fatalf("DeleteSearchDocument() error = %v", err)
	}

	if gotMethod != http.MethodPost {
		t.Fatalf("method = %s, want POST", gotMethod)
	}
	if gotPath != "/v1/search/index/events" {
		t.Fatalf("path = %q", gotPath)
	}
	if gotToken != "internal-token" {
		t.Fatalf("internal token = %q, want internal-token", gotToken)
	}
	if gotPayload["sourceService"] != "excursion-service" ||
		gotPayload["aggregateType"] != "excursion" ||
		gotPayload["aggregateId"] != "excursion/1" ||
		gotPayload["eventType"] != "search_document_delete" {
		t.Fatalf("event envelope = %#v", gotPayload)
	}
	payload, ok := gotPayload["payload"].(map[string]any)
	if !ok {
		t.Fatalf("payload = %#v", gotPayload["payload"])
	}
	if payload["domain"] != "excursion" ||
		payload["entityId"] != "excursion/1" ||
		payload["locale"] != "kk" {
		t.Fatalf("payload = %#v", payload)
	}
}

func TestClientUsesServiceJWTWhenTokenSourceConfigured(t *testing.T) {
	t.Parallel()

	var gotAuthorization string
	var gotLegacyToken string
	client := New("http://search-service:8101", "legacy-token", 2*time.Second)
	client.httpClient.Transport = roundTripFunc(func(r *http.Request) (*http.Response, error) {
		gotAuthorization = r.Header.Get("Authorization")
		gotLegacyToken = r.Header.Get("X-Internal-Service-Token")
		return acceptedResponse(), nil
	})
	WithServiceTokenSource(staticTokenSource("service-jwt"))(client)

	err := client.UpsertSearchDocument(t.Context(), app.SearchIndexDocument{
		Domain:   "excursion",
		EntityID: "excursion-1",
		Title:    map[string]string{"en": "Excursion"},
		DeepLink: "/excursions/excursion-1",
	})
	if err != nil {
		t.Fatalf("UpsertSearchDocument() error = %v", err)
	}

	if gotAuthorization != "Bearer service-jwt" {
		t.Fatalf("Authorization = %q, want bearer service jwt", gotAuthorization)
	}
	if gotLegacyToken != "" {
		t.Fatalf("legacy token header = %q, want empty", gotLegacyToken)
	}
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(req *http.Request) (*http.Response, error) {
	return f(req)
}

type staticTokenSource string

func (s staticTokenSource) Token(context.Context) (string, error) {
	return string(s), nil
}

func acceptedResponse() *http.Response {
	return &http.Response{
		StatusCode: http.StatusAccepted,
		Body:       io.NopCloser(bytes.NewReader(nil)),
		Header:     make(http.Header),
	}
}
