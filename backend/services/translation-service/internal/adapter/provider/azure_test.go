package provider

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/services/translation-service/internal/domain/model"
	"kz/inflap/backend/services/translation-service/internal/domain/port"
)

func TestAzureTranslatorPostsOfficialV3RequestShape(t *testing.T) {
	var gotPath string
	var gotQuery string
	var gotKey string
	var gotRegion string
	var gotPayload []map[string]string
	roundTripper := roundTripFunc(func(r *http.Request) (*http.Response, error) {
		gotPath = r.URL.Path
		gotQuery = r.URL.RawQuery
		gotKey = r.Header.Get("Ocp-Apim-Subscription-Key")
		gotRegion = r.Header.Get("Ocp-Apim-Subscription-Region")
		if err := json.NewDecoder(r.Body).Decode(&gotPayload); err != nil {
			t.Fatalf("decode payload: %v", err)
		}
		body, _ := json.Marshal([]azureTranslateResponseItem{
			{
				Translations: []azureTranslation{
					{To: "ru", Text: "Привет"},
					{To: "kk", Text: "Сәлем"},
				},
			},
		})
		return &http.Response{
			StatusCode: http.StatusOK,
			Header:     http.Header{"X-Metered-Usage": []string{"10"}},
			Body:       io.NopCloser(strings.NewReader(string(body))),
		}, nil
	})

	client := NewAzureTranslator(AzureConfig{
		BaseURL:    "https://translator.test",
		Key:        "secret-key",
		Region:     "centralus",
		Timeout:    time.Second,
		HTTPClient: &http.Client{Transport: roundTripper},
	})

	result, err := client.Translate(context.Background(), port.ProviderTranslateRequest{
		SourceLanguage:  model.LanguageEnglish,
		TargetLanguages: []model.Language{model.LanguageRussian, model.LanguageKazakh},
		Texts:           []string{"Hello"},
		RequestID:       "request-1",
	})

	if err != nil {
		t.Fatalf("Translate() error = %v", err)
	}
	if gotPath != "/translate" {
		t.Fatalf("path = %q, want /translate", gotPath)
	}
	if gotQuery != "api-version=3.0&from=en&textType=plain&to=ru&to=kk" {
		t.Fatalf("query = %q, want official v3 translate query", gotQuery)
	}
	if gotKey != "secret-key" {
		t.Fatalf("subscription key header = %q, want secret-key", gotKey)
	}
	if gotRegion != "centralus" {
		t.Fatalf("subscription region header = %q, want centralus", gotRegion)
	}
	if len(gotPayload) != 1 || gotPayload[0]["Text"] != "Hello" {
		t.Fatalf("payload = %#v, want Azure Text array", gotPayload)
	}
	if result.MeteredCharacters != 10 {
		t.Fatalf("metered characters = %d, want 10", result.MeteredCharacters)
	}
	if result.Translations[model.LanguageRussian][0] != "Привет" || result.Translations[model.LanguageKazakh][0] != "Сәлем" {
		t.Fatalf("translations = %#v, want decoded translations", result.Translations)
	}
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (fn roundTripFunc) RoundTrip(req *http.Request) (*http.Response, error) {
	return fn(req)
}
