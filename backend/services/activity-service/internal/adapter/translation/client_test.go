package translation

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"net/http"
	"testing"
	"time"

	"kz/inflap/backend/services/activity-service/internal/domain/port"
)

func TestClientUsesActivityContentTypeAndDecodesResults(t *testing.T) {
	var gotPayload translateRequest
	transport := roundTripFunc(func(r *http.Request) (*http.Response, error) {
		if r.URL.Path != "/internal/v1/translations/translate" {
			t.Fatalf("path = %q", r.URL.Path)
		}
		if err := json.NewDecoder(r.Body).Decode(&gotPayload); err != nil {
			t.Fatalf("decode request: %v", err)
		}
		body := bytes.NewBuffer(nil)
		_ = json.NewEncoder(body).Encode(translateResponse{
			Provider: "azure_translator",
			Translations: map[string][]translatedText{
				"en": {
					{Text: "Mountain hike", Status: "translated", Provider: "azure_translator"},
					{Text: "Detailed description", Status: "cached", Provider: "azure_translator"},
				},
			},
		})
		return &http.Response{
			StatusCode: http.StatusOK,
			Header:     http.Header{"Content-Type": []string{"application/json"}},
			Body:       io.NopCloser(body),
		}, nil
	})

	client := NewClient(
		"https://translation-service:9497",
		time.Second,
		"internal-token",
		WithHTTPClient(&http.Client{Transport: transport}),
	)
	result, err := client.TranslateTexts(context.Background(), port.ActivityTranslationRequest{
		SourceLocale:  "ru",
		TargetLocales: []string{"en"},
		Texts:         []string{"Поход", "Подробное описание"},
	})
	if err != nil {
		t.Fatalf("TranslateTexts() error = %v", err)
	}
	if gotPayload.ContentType != "activity" || gotPayload.SourceLanguage != "ru" {
		t.Fatalf("payload = %#v", gotPayload)
	}
	if result.Translations["en"][0] != "Mountain hike" || result.Provider != "azure_translator" {
		t.Fatalf("result = %#v", result)
	}
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(request *http.Request) (*http.Response, error) {
	return f(request)
}
