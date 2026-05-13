package translation

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/port"
)

const headerInternalServiceToken = "X-Internal-Service-Token"

type Client struct {
	baseURL       string
	internalToken string
	httpClient    *http.Client
}

func NewClient(baseURL string, timeout time.Duration, internalToken string) *Client {
	normalizedBaseURL := strings.TrimRight(strings.TrimSpace(baseURL), "/")
	if normalizedBaseURL == "" {
		return nil
	}
	if timeout <= 0 {
		timeout = 5 * time.Second
	}
	return &Client{
		baseURL:       normalizedBaseURL,
		internalToken: strings.TrimSpace(internalToken),
		httpClient:    &http.Client{Timeout: timeout},
	}
}

func (c *Client) TranslateTexts(ctx context.Context, input port.TranslationRequest) (port.TranslationResult, error) {
	if c == nil {
		return port.TranslationResult{}, nil
	}

	sourceLocale := strings.ToLower(strings.TrimSpace(input.SourceLocale))
	targetLocales := normalizeLocales(input.TargetLocales)
	texts := trimTexts(input.Texts)
	if sourceLocale == "" || len(targetLocales) == 0 || len(texts) == 0 {
		return port.TranslationResult{Translations: map[string][]string{}}, nil
	}

	payload := translateRequest{
		SourceLanguage:  sourceLocale,
		TargetLanguages: targetLocales,
		Texts:           texts,
	}
	body := bytes.NewBuffer(nil)
	if err := json.NewEncoder(body).Encode(payload); err != nil {
		return port.TranslationResult{}, fmt.Errorf("encode translation request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+"/v1/translate", body)
	if err != nil {
		return port.TranslationResult{}, fmt.Errorf("create translation request: %w", err)
	}
	req.Header.Set("Accept", "application/json")
	req.Header.Set("Content-Type", "application/json")
	if c.internalToken != "" {
		req.Header.Set(headerInternalServiceToken, c.internalToken)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return port.TranslationResult{}, fmt.Errorf("call translation-service: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < http.StatusOK || resp.StatusCode >= http.StatusMultipleChoices {
		return port.TranslationResult{}, fmt.Errorf(
			"translation-service request failed: status=%d message=%s",
			resp.StatusCode,
			readErrorMessage(resp.Body),
		)
	}

	var decoded translateResponse
	if err = json.NewDecoder(resp.Body).Decode(&decoded); err != nil {
		return port.TranslationResult{}, fmt.Errorf("decode translation response: %w", err)
	}
	for locale, translatedTexts := range decoded.Translations {
		if len(translatedTexts) != len(texts) {
			return port.TranslationResult{}, fmt.Errorf(
				"translation-service returned %d texts for %s, want %d",
				len(translatedTexts),
				locale,
				len(texts),
			)
		}
	}
	return port.TranslationResult{Translations: decoded.Translations}, nil
}

func normalizeLocales(values []string) []string {
	seen := make(map[string]struct{}, len(values))
	result := make([]string, 0, len(values))
	for _, value := range values {
		normalized := strings.ToLower(strings.TrimSpace(value))
		if index := strings.IndexAny(normalized, "-_"); index >= 0 {
			normalized = normalized[:index]
		}
		if normalized == "" {
			continue
		}
		if _, ok := seen[normalized]; ok {
			continue
		}
		seen[normalized] = struct{}{}
		result = append(result, normalized)
	}
	return result
}

func trimTexts(values []string) []string {
	result := make([]string, 0, len(values))
	for _, value := range values {
		result = append(result, strings.TrimSpace(value))
	}
	return result
}

func readErrorMessage(body io.Reader) string {
	const maxErrorBytes = 512

	payload, err := io.ReadAll(io.LimitReader(body, maxErrorBytes))
	if err != nil || len(payload) == 0 {
		return "unknown"
	}

	var structured struct {
		Error string `json:"error"`
	}
	if json.Unmarshal(payload, &structured) == nil && strings.TrimSpace(structured.Error) != "" {
		return strings.TrimSpace(structured.Error)
	}

	return strings.TrimSpace(string(payload))
}

type translateRequest struct {
	SourceLanguage  string   `json:"sourceLanguage"`
	TargetLanguages []string `json:"targetLanguages"`
	Texts           []string `json:"texts"`
}

type translateResponse struct {
	Translations map[string][]string `json:"translations"`
	Model        string              `json:"model,omitempty"`
}
