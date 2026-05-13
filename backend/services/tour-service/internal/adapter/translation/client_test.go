package translation

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/port"
)

func TestTranslateTextsPostsBatchWithInternalToken(t *testing.T) {
	var gotToken string
	var gotPayload translateRequest
	client := NewClient("http://translation-service", time.Second, "internal-token")
	client.httpClient = &http.Client{Transport: roundTripFunc(func(r *http.Request) (*http.Response, error) {
		if r.URL.Path != "/v1/translate" {
			t.Fatalf("path = %s, want /v1/translate", r.URL.Path)
		}
		gotToken = r.Header.Get(headerInternalServiceToken)
		if err := json.NewDecoder(r.Body).Decode(&gotPayload); err != nil {
			t.Fatalf("decode request: %v", err)
		}

		return jsonResponse(http.StatusOK, translateResponse{
			Model: "facebook/m2m100_418M",
			Translations: map[string][]string{
				"en": {"Start", "Meet the guide."},
				"kk": {"Бастау", "Гидпен кездесу."},
			},
		}), nil
	})}

	result, err := client.TranslateTexts(context.Background(), port.TranslationRequest{
		SourceLocale:  "ru",
		TargetLocales: []string{"EN", "kk", "en"},
		Texts:         []string{" Старт ", " Встреча с гидом. "},
	})

	if err != nil {
		t.Fatalf("TranslateTexts() error = %v", err)
	}
	if gotToken != "internal-token" {
		t.Fatalf("internal token = %q, want internal-token", gotToken)
	}
	if gotPayload.SourceLanguage != "ru" {
		t.Fatalf("source language = %q, want ru", gotPayload.SourceLanguage)
	}
	if len(gotPayload.TargetLanguages) != 2 || gotPayload.TargetLanguages[0] != "en" || gotPayload.TargetLanguages[1] != "kk" {
		t.Fatalf("target languages = %#v, want normalized unique locales", gotPayload.TargetLanguages)
	}
	if gotPayload.Texts[0] != "Старт" || gotPayload.Texts[1] != "Встреча с гидом." {
		t.Fatalf("texts = %#v, want trimmed texts", gotPayload.Texts)
	}
	if result.Translations["en"][0] != "Start" || result.Translations["kk"][1] != "Гидпен кездесу." {
		t.Fatalf("translations = %#v, want decoded response", result.Translations)
	}
}

func TestTranslateTextsRejectsMismatchedResponseLength(t *testing.T) {
	client := NewClient("http://translation-service", time.Second, "")
	client.httpClient = &http.Client{Transport: roundTripFunc(func(r *http.Request) (*http.Response, error) {
		return jsonResponse(http.StatusOK, translateResponse{
			Translations: map[string][]string{
				"en": {"Start"},
			},
		}), nil
	})}

	_, err := client.TranslateTexts(context.Background(), port.TranslationRequest{
		SourceLocale:  "ru",
		TargetLocales: []string{"en"},
		Texts:         []string{"Старт", "Встреча с гидом."},
	})

	if err == nil {
		t.Fatal("TranslateTexts() error = nil, want response length validation error")
	}
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (fn roundTripFunc) RoundTrip(req *http.Request) (*http.Response, error) {
	return fn(req)
}

func jsonResponse(statusCode int, payload any) *http.Response {
	body, _ := json.Marshal(payload)
	return &http.Response{
		StatusCode: statusCode,
		Header:     make(http.Header),
		Body:       io.NopCloser(strings.NewReader(string(body))),
	}
}
