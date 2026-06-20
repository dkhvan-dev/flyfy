package switches

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"slices"
	"testing"
	"time"
)

func TestHTTPClientHasActiveTechBreakSendsContract(t *testing.T) {
	t.Parallel()

	var gotToken string
	var gotDomain string
	var gotScopes []string
	var gotEmail string
	var gotNickname string

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/api/v1/internal/tech-breaks/has-active" {
			t.Fatalf("path = %q, want tech-break contract path", r.URL.Path)
		}
		gotToken = r.Header.Get("X-Internal-Service-Token")
		gotDomain = r.URL.Query().Get("domainCode")
		gotScopes = r.URL.Query()["scopeCodes"]
		gotEmail = r.URL.Query().Get("email")
		gotNickname = r.URL.Query().Get("nickname")
		_ = json.NewEncoder(w).Encode(true)
	}))
	defer server.Close()

	client, err := NewHTTPClient(HTTPClientConfig{
		BaseURL:              server.URL,
		InternalServiceToken: "internal-token",
		Timeout:              time.Second,
	})
	if err != nil {
		t.Fatalf("NewHTTPClient() error = %v", err)
	}

	active, err := client.HasActiveTechBreak(context.Background(), TechBreakCheck{
		DomainCode: "ACTIVITY",
		ScopeCodes: []string{"CREATE", "JOIN"},
		Email:      "user@example.com",
		Nickname:   "flyfy",
	})
	if err != nil {
		t.Fatalf("HasActiveTechBreak() error = %v", err)
	}
	if !active {
		t.Fatal("HasActiveTechBreak() = false, want true")
	}
	if gotToken != "internal-token" {
		t.Fatalf("token header = %q, want internal-token", gotToken)
	}
	if gotDomain != "ACTIVITY" {
		t.Fatalf("domainCode = %q, want ACTIVITY", gotDomain)
	}
	if !slices.Equal(gotScopes, []string{"CREATE", "JOIN"}) {
		t.Fatalf("scopeCodes = %#v, want CREATE/JOIN", gotScopes)
	}
	if gotEmail != "user@example.com" {
		t.Fatalf("email = %q, want user@example.com", gotEmail)
	}
	if gotNickname != "flyfy" {
		t.Fatalf("nickname = %q, want flyfy", gotNickname)
	}
}

func TestHTTPClientHasActiveTechBreakRejectsEmptyDomain(t *testing.T) {
	t.Parallel()

	client, err := NewHTTPClient(HTTPClientConfig{
		BaseURL: "http://switches-service:8096",
		Timeout: time.Second,
	})
	if err != nil {
		t.Fatalf("NewHTTPClient() error = %v", err)
	}

	if _, err := client.HasActiveTechBreak(context.Background(), TechBreakCheck{}); err == nil {
		t.Fatal("HasActiveTechBreak() error = nil, want validation error")
	}
}

func TestEffectiveInternalServiceToken(t *testing.T) {
	t.Parallel()

	if got := EffectiveInternalServiceToken(" switches ", " fallback "); got != "switches" {
		t.Fatalf("preferred token = %q, want switches", got)
	}
	if got := EffectiveInternalServiceToken("   ", " fallback "); got != "fallback" {
		t.Fatalf("fallback token = %q, want fallback", got)
	}
}
