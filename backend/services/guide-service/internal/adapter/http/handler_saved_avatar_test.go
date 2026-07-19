package http

import (
	"context"
	"errors"
	nethttp "net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/guide-service/internal/app"
	"kz/inflap/backend/services/guide-service/internal/domain/model"
)

func TestPublicSavedGuideAvatarRouteRedirectsWithoutAuthOrResponseBody(t *testing.T) {
	userID := uuid.MustParse("12345678-1234-4234-8234-123456789abc")
	delivery := &savedAvatarHTTPDeliveryStub{
		downloadURL: "https://media.example.test/avatar?signature=short-lived",
	}
	mux := nethttp.NewServeMux()
	NewHandler(nil, delivery).Register(mux)
	request := httptest.NewRequest(
		nethttp.MethodGet,
		"/v1/guides/public/by-user/"+userID.String()+"/saved-avatar?saved_revision=42",
		nil,
	)
	response := httptest.NewRecorder()

	mux.ServeHTTP(response, request)

	if response.Code != nethttp.StatusTemporaryRedirect {
		t.Fatalf("status = %d, want %d; body = %s", response.Code, nethttp.StatusTemporaryRedirect, response.Body.String())
	}
	if response.Header().Get("Location") != delivery.downloadURL {
		t.Fatalf("Location = %q, want %q", response.Header().Get("Location"), delivery.downloadURL)
	}
	if response.Body.Len() != 0 {
		t.Fatalf("redirect body = %q, want empty", response.Body.String())
	}
	if response.Header().Get("Cache-Control") != "no-store" ||
		response.Header().Get("Referrer-Policy") != "no-referrer" ||
		response.Header().Get("Content-Security-Policy") == "" ||
		response.Header().Get("X-Content-Type-Options") != "nosniff" {
		t.Fatalf("missing strict redirect headers: %#v", response.Header())
	}
	if delivery.calls != 1 || delivery.userID != userID || delivery.savedRevision != 42 {
		t.Fatalf(
			"delivery calls/user/revision = %d/%s/%d, want 1/%s/42",
			delivery.calls,
			delivery.userID,
			delivery.savedRevision,
			userID,
		)
	}
}

func TestPublicSavedGuideAvatarRouteRejectsMalformedInputBeforeDatabase(t *testing.T) {
	canonicalUserID := "12345678-1234-4234-8234-123456789abc"
	tests := []struct {
		name   string
		target string
		body   string
	}{
		{
			name:   "missing revision",
			target: "/v1/guides/public/by-user/" + canonicalUserID + "/saved-avatar",
		},
		{
			name:   "duplicate revision",
			target: "/v1/guides/public/by-user/" + canonicalUserID + "/saved-avatar?saved_revision=1&saved_revision=2",
		},
		{
			name:   "unknown query",
			target: "/v1/guides/public/by-user/" + canonicalUserID + "/saved-avatar?saved_revision=1&extra=value",
		},
		{
			name:   "zero revision",
			target: "/v1/guides/public/by-user/" + canonicalUserID + "/saved-avatar?saved_revision=0",
		},
		{
			name:   "non-canonical revision",
			target: "/v1/guides/public/by-user/" + canonicalUserID + "/saved-avatar?saved_revision=01",
		},
		{
			name:   "malformed query encoding",
			target: "/v1/guides/public/by-user/" + canonicalUserID + "/saved-avatar?saved_revision=%zz",
		},
		{
			name:   "non-canonical user id",
			target: "/v1/guides/public/by-user/" + strings.ToUpper(canonicalUserID) + "/saved-avatar?saved_revision=1",
		},
		{
			name:   "request body",
			target: "/v1/guides/public/by-user/" + canonicalUserID + "/saved-avatar?saved_revision=1",
			body:   "{}",
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			repo := &savedAvatarHTTPRepositoryStub{}
			files := &savedAvatarHTTPFileManagerStub{}
			source := app.NewSavedGuideSourceUseCase(repo, &savedAvatarHTTPUserSourceStub{})
			delivery := app.NewSavedGuideAvatarDeliveryUseCase(source, files)
			mux := nethttp.NewServeMux()
			NewHandler(nil, delivery).Register(mux)
			request := httptest.NewRequest(
				nethttp.MethodGet,
				test.target,
				strings.NewReader(test.body),
			)
			response := httptest.NewRecorder()

			mux.ServeHTTP(response, request)

			if response.Code != nethttp.StatusBadRequest {
				t.Fatalf("status = %d, want %d; body = %s", response.Code, nethttp.StatusBadRequest, response.Body.String())
			}
			if repo.calls != 0 || files.calls != 0 {
				t.Fatalf("malformed request database/file calls = %d/%d, want 0/0", repo.calls, files.calls)
			}
		})
	}
}

func TestPublicSavedGuideAvatarRouteRejectsUnsupportedMethodsThroughMux(t *testing.T) {
	userID := uuid.MustParse("12345678-1234-4234-8234-123456789abc")
	target := "/v1/guides/public/by-user/" + userID.String() + "/saved-avatar?saved_revision=42"

	for _, method := range []string{nethttp.MethodHead, nethttp.MethodPost, nethttp.MethodOptions} {
		t.Run(method, func(t *testing.T) {
			delivery := &savedAvatarHTTPDeliveryStub{}
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

func TestPublicSavedGuideAvatarRouteUsesNeutralDependencyFailure(t *testing.T) {
	userID := uuid.MustParse("12345678-1234-4234-8234-123456789abc")
	delivery := &savedAvatarHTTPDeliveryStub{err: errors.New("upstream dial failure with internal details")}
	mux := nethttp.NewServeMux()
	NewHandler(nil, delivery).Register(mux)
	response := httptest.NewRecorder()

	mux.ServeHTTP(response, httptest.NewRequest(
		nethttp.MethodGet,
		"/v1/guides/public/by-user/"+userID.String()+"/saved-avatar?saved_revision=42",
		nil,
	))

	if response.Code != nethttp.StatusBadGateway {
		t.Fatalf("status = %d, want %d", response.Code, nethttp.StatusBadGateway)
	}
	if strings.Contains(response.Body.String(), "upstream") ||
		strings.Contains(response.Body.String(), "internal") {
		t.Fatalf("dependency internals leaked in body: %s", response.Body.String())
	}
	if response.Header().Get("Location") != "" {
		t.Fatalf("dependency failure returned Location %q", response.Header().Get("Location"))
	}
}

type savedAvatarHTTPDeliveryStub struct {
	downloadURL   string
	err           error
	calls         int
	userID        uuid.UUID
	savedRevision uint64
}

func (s *savedAvatarHTTPDeliveryStub) CreatePublicSavedGuideAvatarDownloadURL(
	_ context.Context,
	userID uuid.UUID,
	savedRevision uint64,
) (string, error) {
	s.calls++
	s.userID = userID
	s.savedRevision = savedRevision
	return s.downloadURL, s.err
}

type savedAvatarHTTPRepositoryStub struct {
	calls int
}

func (s *savedAvatarHTTPRepositoryStub) GetSavedSourceGuide(
	context.Context,
	uuid.UUID,
) (*model.SavedGuideSnapshot, error) {
	s.calls++
	return nil, nil
}

type savedAvatarHTTPUserSourceStub struct{}

func (*savedAvatarHTTPUserSourceStub) GetSavedGuideUserSnapshot(
	context.Context,
	uuid.UUID,
) (*app.SavedGuideUserSnapshot, error) {
	return nil, nil
}

type savedAvatarHTTPFileManagerStub struct {
	calls int
}

func (s *savedAvatarHTTPFileManagerStub) CreateDownloadURL(
	context.Context,
	uuid.UUID,
) (string, error) {
	s.calls++
	return "", nil
}
