package excursionservice

import (
	"bytes"
	"context"
	"io"
	"net/http"
	"net/url"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/guide-service/internal/app"
)

func TestListGuideUserIDsByCitySendsCityIDAndName(t *testing.T) {
	t.Parallel()

	guideUserID := uuid.New()
	var query url.Values
	transport := roundTripFunc(func(r *http.Request) (*http.Response, error) {
		if r.URL.Path != "/v1/guides/by-excursion-city" {
			t.Fatalf("path = %q, want /v1/guides/by-excursion-city", r.URL.Path)
		}
		query = r.URL.Query()
		body := []byte(`{"items":[{"guideUserId":"` + guideUserID.String() + `"}]}`)
		return &http.Response{
			StatusCode: http.StatusOK,
			Header:     make(http.Header),
			Body:       io.NopCloser(bytes.NewReader(body)),
		}, nil
	})

	client := New(
		"https://excursion-service.test",
		"",
		&http.Client{Transport: transport},
	)

	got, err := client.ListGuideUserIDsByCity(
		context.Background(),
		app.GuideExcursionCityFilter{
			CityID:      " Almaty ",
			CityName:    " Алматы ",
			CountryCode: " kz ",
		},
	)
	if err != nil {
		t.Fatalf("ListGuideUserIDsByCity() error = %v", err)
	}
	if len(got) != 1 || got[0] != guideUserID {
		t.Fatalf("guide ids = %#v, want [%s]", got, guideUserID)
	}
	if query.Get("cityId") != "almaty" {
		t.Fatalf("cityId query = %q, want almaty", query.Get("cityId"))
	}
	if query.Get("cityName") != "Алматы" {
		t.Fatalf("cityName query = %q, want Алматы", query.Get("cityName"))
	}
	if query.Get("countryCode") != "KZ" {
		t.Fatalf("countryCode query = %q, want KZ", query.Get("countryCode"))
	}
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(r *http.Request) (*http.Response, error) {
	return f(r)
}
