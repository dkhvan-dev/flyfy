package platformpolicy

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestHTTPClientFetchDecisionContract(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 7, 16, 11, 0, 0, 0, time.UTC)
	want := testDecision(now, 21, StateAvailable)
	var gotMethod string
	var gotPath string
	var gotQuery string
	var gotAuthorization string

	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		gotMethod = request.Method
		gotPath = request.URL.Path
		gotQuery = request.URL.RawQuery
		gotAuthorization = request.Header.Get(HeaderAuthorization)
		writer.Header().Set("Content-Type", "application/json; charset=utf-8")
		if err := json.NewEncoder(writer).Encode(want); err != nil {
			t.Errorf("encode response: %v", err)
		}
	}))
	defer server.Close()

	client, err := NewHTTPClient(HTTPClientConfig{
		BaseURL:           server.URL,
		Timeout:           time.Second,
		AllowInsecureHTTP: true,
		TokenHeaderProvider: tokenHeaderProviderFunc(func(context.Context) (TokenHeader, error) {
			return TokenHeader{Name: HeaderAuthorization, Value: "Bearer request-token"}, nil
		}),
	})
	if err != nil {
		t.Fatalf("NewHTTPClient() error = %v", err)
	}

	got, err := client.FetchDecision(context.Background())
	if err != nil {
		t.Fatalf("FetchDecision() error = %v", err)
	}
	if !decisionsEqual(got, want) {
		t.Fatalf("FetchDecision() = %#v, want %#v", got, want)
	}
	if gotMethod != http.MethodGet {
		t.Fatalf("method = %q, want GET", gotMethod)
	}
	if gotPath != EndpointPath {
		t.Fatalf("path = %q, want %q", gotPath, EndpointPath)
	}
	if gotQuery != "" {
		t.Fatalf("query = %q, want empty", gotQuery)
	}
	if gotAuthorization != "Bearer request-token" {
		t.Fatalf("authorization = %q, want injected bearer token", gotAuthorization)
	}
}

func TestHTTPClientRejectsUnsafeBaseURLs(t *testing.T) {
	t.Parallel()

	tests := map[string]HTTPClientConfig{
		"plaintext without opt-in": {BaseURL: "http://policy.internal"},
		"credentials":              {BaseURL: "https://user:secret@policy.internal"},
		"path":                     {BaseURL: "https://policy.internal/prefix"},
		"query":                    {BaseURL: "https://policy.internal?target=other"},
		"unsupported scheme":       {BaseURL: "file:///tmp/policy"},
	}
	for name, cfg := range tests {
		cfg := cfg
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			if _, err := NewHTTPClient(cfg); err == nil {
				t.Fatal("NewHTTPClient() error = nil, want validation error")
			}
		})
	}
}

func TestHTTPClientRejectsMalformedResponse(t *testing.T) {
	t.Parallel()

	server := newJSONServer(t, `{
		"revision": 22,
		"state": "AVAILABLE",
		"issued_at": "2026-07-16T11:00:00Z",
		"valid_until": "2026-07-16T11:00:20Z",
		"subject_id": "must-not-be-accepted"
	}`)
	defer server.Close()

	client := newTestHTTPClient(t, server.URL, DefaultMaxResponseBytes, 0)
	_, err := client.FetchDecision(context.Background())
	requireFetchFailure(t, err, FetchFailureMalformed)
}

func TestHTTPClientRejectsOversizedResponse(t *testing.T) {
	t.Parallel()

	server := newJSONServer(t, `{"padding":"`+strings.Repeat("x", 256)+`"}`)
	defer server.Close()

	client := newTestHTTPClient(t, server.URL, 64, 0)
	_, err := client.FetchDecision(context.Background())
	requireFetchFailure(t, err, FetchFailureOversized)
}

func TestHTTPClientTimeout(t *testing.T) {
	t.Parallel()

	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		select {
		case <-request.Context().Done():
			return
		case <-time.After(time.Second):
			writer.Header().Set("Content-Type", "application/json")
			_, _ = writer.Write([]byte(`{}`))
		}
	}))
	defer server.Close()

	client := newTestHTTPClient(t, server.URL, DefaultMaxResponseBytes, 20*time.Millisecond)
	_, err := client.FetchDecision(context.Background())
	requireFetchFailure(t, err, FetchFailureTransport)
	if !errors.Is(err, context.DeadlineExceeded) {
		t.Fatalf("errors.Is(error, context.DeadlineExceeded) = false: %v", err)
	}
}

func newJSONServer(t *testing.T, body string) *httptest.Server {
	t.Helper()
	return httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		writer.Header().Set("Content-Type", "application/json")
		_, _ = writer.Write([]byte(body))
	}))
}

func newTestHTTPClient(t *testing.T, baseURL string, maxResponseBytes int64, timeout time.Duration) *HTTPClient {
	t.Helper()
	client, err := NewHTTPClient(HTTPClientConfig{
		BaseURL:           baseURL,
		Timeout:           timeout,
		MaxResponseBytes:  maxResponseBytes,
		AllowInsecureHTTP: true,
	})
	if err != nil {
		t.Fatalf("NewHTTPClient() error = %v", err)
	}
	return client
}

func requireFetchFailure(t *testing.T, err error, want FetchFailure) {
	t.Helper()
	if err == nil {
		t.Fatalf("error = nil, want fetch failure %s", want)
	}
	var fetchErr *FetchError
	if !errors.As(err, &fetchErr) {
		t.Fatalf("error type = %T, want *FetchError", err)
	}
	if fetchErr.Kind() != want {
		t.Fatalf("fetch failure = %s, want %s", fetchErr.Kind(), want)
	}
}

type tokenHeaderProviderFunc func(context.Context) (TokenHeader, error)

func (provider tokenHeaderProviderFunc) TokenHeader(ctx context.Context) (TokenHeader, error) {
	return provider(ctx)
}
