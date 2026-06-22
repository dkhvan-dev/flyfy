package userroute

import (
	"context"
	"errors"
	"io"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/app"
)

func TestValidatePostRouteReferenceAcceptsOwnedPublicRoute(t *testing.T) {
	authorID := uuid.New()
	client := New("http://user-route-service.test", time.Second)
	client.httpClient = &http.Client{Transport: roundTripFunc(func(r *http.Request) (*http.Response, error) {
		if r.Method != http.MethodGet {
			t.Fatalf("method = %q, want GET", r.Method)
		}
		if r.URL.Path != getUserRoutePathPrefix+"route-1" {
			t.Fatalf("path = %q, want %sroute-1", r.URL.Path, getUserRoutePathPrefix)
		}
		if r.Header.Get(trustedUserIDHeader) != authorID.String() {
			t.Fatalf("%s = %q, want %s", trustedUserIDHeader, r.Header.Get(trustedUserIDHeader), authorID)
		}
		return jsonResponse(r, http.StatusOK, `{
			"id":"route-1",
			"ownerUserId":"`+authorID.String()+`",
			"visibility":"public",
			"moderationStatus":"approved"
		}`), nil
	})}

	err := client.ValidatePostRouteReference(context.Background(), app.PostRouteReferenceValidationInput{
		AuthorUserID: authorID,
		RouteID:      "route-1",
	})
	if err != nil {
		t.Fatalf("ValidatePostRouteReference returned error: %v", err)
	}
}

func TestValidatePostRouteReferenceRejectsPrivateOrForeignRoute(t *testing.T) {
	authorID := uuid.New()
	otherID := uuid.New()
	tests := map[string]string{
		"private owned route": `{
			"id":"route-1",
			"ownerUserId":"` + authorID.String() + `",
			"visibility":"private",
			"moderationStatus":"approved"
		}`,
		"foreign public route": `{
			"id":"route-1",
			"ownerUserId":"` + otherID.String() + `",
			"visibility":"public",
			"moderationStatus":"approved"
		}`,
	}

	for name, body := range tests {
		t.Run(name, func(t *testing.T) {
			client := New("http://user-route-service.test", time.Second)
			client.httpClient = &http.Client{Transport: roundTripFunc(func(r *http.Request) (*http.Response, error) {
				return jsonResponse(r, http.StatusOK, body), nil
			})}

			err := client.ValidatePostRouteReference(context.Background(), app.PostRouteReferenceValidationInput{
				AuthorUserID: authorID,
				RouteID:      "route-1",
			})
			if !errors.Is(err, app.ErrInvalidPostRouteReference) {
				t.Fatalf("ValidatePostRouteReference error = %v, want %v", err, app.ErrInvalidPostRouteReference)
			}
		})
	}
}

func TestValidatePostRouteReferenceRejectsUnapprovedRoutes(t *testing.T) {
	authorID := uuid.New()
	tests := map[string]string{
		"pending public route": `{
			"id":"route-1",
			"ownerUserId":"` + authorID.String() + `",
			"visibility":"public",
			"moderationStatus":"pending"
		}`,
		"rejected unlisted route": `{
			"id":"route-1",
			"ownerUserId":"` + authorID.String() + `",
			"visibility":"unlisted",
			"moderationStatus":"rejected"
		}`,
		"hidden public route": `{
			"id":"route-1",
			"ownerUserId":"` + authorID.String() + `",
			"visibility":"public",
			"moderationStatus":"hidden"
		}`,
	}

	for name, body := range tests {
		t.Run(name, func(t *testing.T) {
			client := New("http://user-route-service.test", time.Second)
			client.httpClient = &http.Client{Transport: roundTripFunc(func(r *http.Request) (*http.Response, error) {
				return jsonResponse(r, http.StatusOK, body), nil
			})}

			err := client.ValidatePostRouteReference(context.Background(), app.PostRouteReferenceValidationInput{
				AuthorUserID: authorID,
				RouteID:      "route-1",
			})
			if !errors.Is(err, app.ErrInvalidPostRouteReference) {
				t.Fatalf("ValidatePostRouteReference error = %v, want %v", err, app.ErrInvalidPostRouteReference)
			}
		})
	}
}

func TestValidatePostRouteReferenceMapsNotFoundToInvalidReference(t *testing.T) {
	client := New("http://user-route-service.test", time.Second)
	client.httpClient = &http.Client{Transport: roundTripFunc(func(r *http.Request) (*http.Response, error) {
		return jsonResponse(r, http.StatusNotFound, `{"code":"user_route.not_found"}`), nil
	})}

	err := client.ValidatePostRouteReference(context.Background(), app.PostRouteReferenceValidationInput{
		AuthorUserID: uuid.New(),
		RouteID:      "missing-route",
	})
	if !errors.Is(err, app.ErrInvalidPostRouteReference) {
		t.Fatalf("ValidatePostRouteReference error = %v, want %v", err, app.ErrInvalidPostRouteReference)
	}
}

func TestValidatePostRouteReferenceKeepsServerFailureTechnical(t *testing.T) {
	client := New("http://user-route-service.test", time.Second)
	client.httpClient = &http.Client{Transport: roundTripFunc(func(r *http.Request) (*http.Response, error) {
		return jsonResponse(r, http.StatusInternalServerError, `{"code":"user_route.technical"}`), nil
	})}

	err := client.ValidatePostRouteReference(context.Background(), app.PostRouteReferenceValidationInput{
		AuthorUserID: uuid.New(),
		RouteID:      "route-1",
	})
	if err == nil {
		t.Fatal("ValidatePostRouteReference returned nil, want technical error")
	}
	if errors.Is(err, app.ErrInvalidPostRouteReference) {
		t.Fatalf("ValidatePostRouteReference error = %v, must not be business validation", err)
	}
}

func jsonResponse(req *http.Request, status int, body string) *http.Response {
	return &http.Response{
		StatusCode: status,
		Header:     make(http.Header),
		Body:       io.NopCloser(strings.NewReader(body)),
		Request:    req,
	}
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(req *http.Request) (*http.Response, error) {
	return f(req)
}
