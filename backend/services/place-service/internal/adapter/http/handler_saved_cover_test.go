package http

import (
	"context"
	"errors"
	nethttp "net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/place-service/internal/app"
	"kz/inflap/backend/services/place-service/internal/config"
	"kz/inflap/backend/services/place-service/internal/domain/model"
)

func TestPublicSavedAttractionCoverRouteRedirectsWithoutAuthentication(t *testing.T) {
	attractionID := uuid.MustParse("12345678-1234-4234-8234-123456789abc")
	delivery := &savedCoverHTTPDeliveryStub{
		downloadURL: "https://media.example.test/cover?signature=short-lived",
	}
	mux := nethttp.NewServeMux()
	NewHandler(nil, delivery).Register(mux)
	request := httptest.NewRequest(
		nethttp.MethodGet,
		"/v1/places/"+attractionID.String()+"/saved-cover?saved_revision=42",
		nil,
	)
	response := httptest.NewRecorder()

	publicHandler := Chain(&config.Config{Security: config.SecurityConfig{
		InternalServiceToken:       "internal-token",
		RequireAuthenticatedWrites: true,
		TrustedHeaderUserID:        "X-User-Id",
		TrustedHeaderRoles:         "X-User-Roles",
		TrustedHeaderSubject:       "X-Auth-Subject",
	}}, mux)
	publicHandler.ServeHTTP(response, request)

	if response.Code != nethttp.StatusTemporaryRedirect {
		t.Fatalf("status = %d, want %d; body = %s", response.Code, nethttp.StatusTemporaryRedirect, response.Body.String())
	}
	if response.Header().Get("Location") != delivery.downloadURL {
		t.Fatalf("Location = %q, want %q", response.Header().Get("Location"), delivery.downloadURL)
	}
	if response.Body.Len() != 0 || response.Header().Get("Content-Length") != "0" {
		t.Fatalf("redirect body/content length = %q/%q, want empty/0", response.Body.String(), response.Header().Get("Content-Length"))
	}
	if response.Header().Get("Cache-Control") != "no-store" ||
		response.Header().Get("Referrer-Policy") != "no-referrer" ||
		response.Header().Get("Content-Security-Policy") == "" ||
		response.Header().Get("X-Content-Type-Options") != "nosniff" {
		t.Fatalf("strict redirect headers missing: %#v", response.Header())
	}
	if delivery.calls != 1 || delivery.attractionID != attractionID || delivery.savedRevision != 42 {
		t.Fatalf(
			"delivery calls/id/revision = %d/%s/%d",
			delivery.calls,
			delivery.attractionID,
			delivery.savedRevision,
		)
	}
}

func TestPublicSavedAttractionCoverRouteRejectsMalformedInputBeforeRepository(t *testing.T) {
	canonicalID := "12345678-1234-4234-8234-123456789abc"
	tests := []struct {
		name   string
		target string
		body   string
	}{
		{name: "missing revision", target: "/v1/places/" + canonicalID + "/saved-cover"},
		{name: "duplicate revision", target: "/v1/places/" + canonicalID + "/saved-cover?saved_revision=1&saved_revision=2"},
		{name: "unknown query", target: "/v1/places/" + canonicalID + "/saved-cover?saved_revision=1&extra=value"},
		{name: "zero revision", target: "/v1/places/" + canonicalID + "/saved-cover?saved_revision=0"},
		{name: "leading zero", target: "/v1/places/" + canonicalID + "/saved-cover?saved_revision=01"},
		{name: "encoded revision", target: "/v1/places/" + canonicalID + "/saved-cover?saved_revision=%31"},
		{name: "trailing separator", target: "/v1/places/" + canonicalID + "/saved-cover?saved_revision=1&"},
		{name: "malformed encoding", target: "/v1/places/" + canonicalID + "/saved-cover?saved_revision=%zz"},
		{name: "non-canonical UUID", target: "/v1/places/" + strings.ToUpper(canonicalID) + "/saved-cover?saved_revision=1"},
		{name: "nil UUID", target: "/v1/places/00000000-0000-0000-0000-000000000000/saved-cover?saved_revision=1"},
		{name: "request body", target: "/v1/places/" + canonicalID + "/saved-cover?saved_revision=1", body: "{}"},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			repo := &savedCoverHTTPRepositoryStub{}
			files := &savedCoverHTTPFileManagerStub{}
			delivery := app.NewSavedAttractionCoverDeliveryUseCase(repo, files)
			mux := nethttp.NewServeMux()
			NewHandler(nil, delivery).Register(mux)
			response := httptest.NewRecorder()

			mux.ServeHTTP(response, httptest.NewRequest(
				nethttp.MethodGet,
				test.target,
				strings.NewReader(test.body),
			))

			if response.Code != nethttp.StatusBadRequest {
				t.Fatalf("status = %d, want %d; body = %s", response.Code, nethttp.StatusBadRequest, response.Body.String())
			}
			if repo.calls != 0 || files.calls != 0 {
				t.Fatalf("malformed request repository/file calls = %d/%d, want 0/0", repo.calls, files.calls)
			}
		})
	}
}

func TestPublicSavedAttractionCoverRouteRejectsUnsupportedMethods(t *testing.T) {
	attractionID := uuid.MustParse("12345678-1234-4234-8234-123456789abc")
	target := "/v1/places/" + attractionID.String() + "/saved-cover?saved_revision=42"

	for _, method := range []string{nethttp.MethodHead, nethttp.MethodPost, nethttp.MethodOptions} {
		t.Run(method, func(t *testing.T) {
			delivery := &savedCoverHTTPDeliveryStub{}
			mux := nethttp.NewServeMux()
			NewHandler(nil, delivery).Register(mux)
			response := httptest.NewRecorder()

			mux.ServeHTTP(response, httptest.NewRequest(method, target, nil))

			if response.Code != nethttp.StatusMethodNotAllowed {
				t.Fatalf("status = %d, want %d", response.Code, nethttp.StatusMethodNotAllowed)
			}
			if delivery.calls != 0 {
				t.Fatalf("unsupported method made %d delivery calls, want 0", delivery.calls)
			}
		})
	}
}

func TestPublicSavedAttractionCoverRouteMapsNeutralDependencyErrors(t *testing.T) {
	attractionID := uuid.MustParse("12345678-1234-4234-8234-123456789abc")
	tests := []struct {
		name   string
		err    error
		status int
	}{
		{name: "not found", err: app.ErrPublicSavedAttractionCoverNotFound, status: nethttp.StatusNotFound},
		{name: "unavailable", err: app.ErrPublicSavedAttractionCoverUnavailable, status: nethttp.StatusServiceUnavailable},
		{name: "bad gateway", err: app.ErrPublicSavedAttractionCoverBadGateway, status: nethttp.StatusBadGateway},
		{name: "unknown dependency failure", err: errors.New("internal host and token details"), status: nethttp.StatusBadGateway},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			delivery := &savedCoverHTTPDeliveryStub{err: test.err}
			mux := nethttp.NewServeMux()
			NewHandler(nil, delivery).Register(mux)
			response := httptest.NewRecorder()

			mux.ServeHTTP(response, httptest.NewRequest(
				nethttp.MethodGet,
				"/v1/places/"+attractionID.String()+"/saved-cover?saved_revision=42",
				nil,
			))

			if response.Code != test.status {
				t.Fatalf("status = %d, want %d", response.Code, test.status)
			}
			if strings.Contains(response.Body.String(), "internal") ||
				strings.Contains(response.Body.String(), "token") ||
				response.Header().Get("Location") != "" {
				t.Fatalf("dependency internals or Location leaked: headers=%#v body=%s", response.Header(), response.Body.String())
			}
		})
	}
}

func TestSavedAttractionCoverAuditPathRedactsTargetID(t *testing.T) {
	attractionID := "12345678-1234-4234-8234-123456789abc"
	request := httptest.NewRequest(
		nethttp.MethodGet,
		"/v1/places/"+attractionID+"/saved-cover?saved_revision=42",
		nil,
	)

	got := auditLogPath(request)
	if got != "/v1/places/{id}/saved-cover" || strings.Contains(got, attractionID) {
		t.Fatalf("auditLogPath() = %q, want redacted route", got)
	}
}

type savedCoverHTTPDeliveryStub struct {
	downloadURL   string
	err           error
	attractionID  uuid.UUID
	savedRevision uint64
	calls         int
}

func (s *savedCoverHTTPDeliveryStub) CreatePublicSavedAttractionCoverDownloadURL(
	_ context.Context,
	attractionID uuid.UUID,
	savedRevision uint64,
) (string, error) {
	s.calls++
	s.attractionID = attractionID
	s.savedRevision = savedRevision
	return s.downloadURL, s.err
}

type savedCoverHTTPRepositoryStub struct {
	calls int
}

func (s *savedCoverHTTPRepositoryStub) GetSavedAttractionCoverSnapshot(
	context.Context,
	uuid.UUID,
) (*model.SavedAttractionCoverSnapshot, error) {
	s.calls++
	return nil, nil
}

type savedCoverHTTPFileManagerStub struct {
	calls int
}

func (s *savedCoverHTTPFileManagerStub) CreateDownloadURL(
	context.Context,
	uuid.UUID,
) (string, error) {
	s.calls++
	return "", nil
}
