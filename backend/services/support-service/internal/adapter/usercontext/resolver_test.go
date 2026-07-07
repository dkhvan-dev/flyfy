package usercontext

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"kz/inflap/backend/services/support-service/internal/app"
)

func TestResolverCombinesTrustedUserAndGuideContext(t *testing.T) {
	userServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/v1/users/user-123" {
			t.Fatalf("user path = %q", r.URL.Path)
		}
		if r.Header.Get("X-Internal-Service-Token") != "internal-token" {
			t.Fatalf("missing internal token header: %#v", r.Header)
		}
		if r.Header.Get("X-Auth-Subject") != "" {
			t.Fatalf("resolver must not send viewer subject to user-service: %#v", r.Header)
		}
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{
			"profile": {"nickname": "@nomad"},
			"followers": {"count": 150000}
		}`))
	}))
	defer userServer.Close()
	guideServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/v1/guides/by-user/user-123" {
			t.Fatalf("guide path = %q", r.URL.Path)
		}
		if r.Header.Get("X-Internal-Service") != "support-service" {
			t.Fatalf("missing internal service header: %#v", r.Header)
		}
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{
			"profile": {"status": "active", "isActivityHostAvailable": true}
		}`))
	}))
	defer guideServer.Close()
	resolver := NewResolver(userServer.URL, guideServer.URL, "internal-token", time.Second)

	segment, err := resolver.ResolveSupportUserSegment(context.Background(), "user-123")
	if err != nil {
		t.Fatalf("ResolveSupportUserSegment returned error: %v", err)
	}

	if segment.Nickname != "@nomad" ||
		segment.FollowersCount != 150000 ||
		!segment.IsGuide ||
		segment.GuideStatus != "active" ||
		segment.RefreshStatus != app.SupportSegmentRefreshStatusFresh ||
		segment.SourceVersion != "user-service+guide-service" {
		t.Fatalf("segment = %#v", segment)
	}
}

func TestResolverTreatsMissingGuideProfileAsNonGuide(t *testing.T) {
	userServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{
			"profile": {"nickname": "@traveler"},
			"followers": {"count": 42}
		}`))
	}))
	defer userServer.Close()
	guideServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		http.Error(w, "not found", http.StatusNotFound)
	}))
	defer guideServer.Close()
	resolver := NewResolver(userServer.URL, guideServer.URL, "internal-token", time.Second)

	segment, err := resolver.ResolveSupportUserSegment(context.Background(), "user-123")
	if err != nil {
		t.Fatalf("ResolveSupportUserSegment returned error: %v", err)
	}

	if segment.IsGuide || segment.GuideStatus != "" || segment.SourceVersion != "user-service+guide-service:not_found" {
		t.Fatalf("segment = %#v, want non-guide user segment", segment)
	}
}

func TestResolverTreatsPendingGuideApplicationAsNonGuide(t *testing.T) {
	userServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{
			"profile": {"nickname": "@pending_guide"},
			"followers": {"count": 42}
		}`))
	}))
	defer userServer.Close()
	guideServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{
			"profile": {"status": "PENDING_REVIEW"}
		}`))
	}))
	defer guideServer.Close()
	resolver := NewResolver(userServer.URL, guideServer.URL, "internal-token", time.Second)

	segment, err := resolver.ResolveSupportUserSegment(context.Background(), "user-123")
	if err != nil {
		t.Fatalf("ResolveSupportUserSegment returned error: %v", err)
	}

	if segment.IsGuide ||
		segment.GuideStatus != "PENDING_REVIEW" ||
		segment.SourceVersion != "user-service+guide-service" {
		t.Fatalf("segment = %#v, want pending guide application preserved as non-guide", segment)
	}
}

func TestResolverReturnsErrorWhenUserServiceIsUnavailable(t *testing.T) {
	userServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		http.Error(w, "unavailable", http.StatusServiceUnavailable)
	}))
	defer userServer.Close()
	resolver := NewResolver(userServer.URL, "", "internal-token", time.Second)

	_, err := resolver.ResolveSupportUserSegment(context.Background(), "user-123")
	if err == nil {
		t.Fatal("expected user-service error")
	}
}

func TestNewResolverUsesProvidedHTTPClient(t *testing.T) {
	customClient := &http.Client{Timeout: 150 * time.Millisecond}

	resolver := NewResolver(
		"http://user-service:8084",
		"http://guide-service:8085",
		"internal-token",
		time.Second,
		WithHTTPClient(customClient),
	)

	if resolver.httpClient != customClient {
		t.Fatalf("http client = %#v, want provided client", resolver.httpClient)
	}
}
