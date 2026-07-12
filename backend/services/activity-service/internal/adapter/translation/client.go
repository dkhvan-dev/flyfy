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
	"unicode/utf8"

	"kz/inflap/backend/pkg/serviceauth"
	"kz/inflap/backend/services/activity-service/internal/domain/port"
)

const (
	headerInternalServiceToken      = "X-Internal-Service-Token"
	maxTranslationRequestTexts      = 200
	maxTranslationRequestCharacters = 100000
	translationContentTypeActivity  = "activity"
)

type Client struct {
	baseURL       string
	internalToken string
	httpClient    *http.Client
}

type Option func(*Client)

func WithHTTPClient(httpClient *http.Client) Option {
	return func(c *Client) {
		if httpClient != nil {
			c.httpClient = httpClient
		}
	}
}

func WithServiceTokenSource(source serviceauth.TokenSource) Option {
	return func(c *Client) {
		if source != nil {
			c.httpClient.Transport = serviceauth.NewBearerTransport(source, c.httpClient.Transport)
		}
	}
}

func NewClient(baseURL string, timeout time.Duration, internalToken string, options ...Option) *Client {
	normalizedBaseURL := strings.TrimRight(strings.TrimSpace(baseURL), "/")
	if normalizedBaseURL == "" {
		return nil
	}
	if timeout <= 0 {
		timeout = 5 * time.Second
	}
	client := &Client{
		baseURL:       normalizedBaseURL,
		internalToken: strings.TrimSpace(internalToken),
		httpClient:    &http.Client{Timeout: timeout},
	}
	for _, option := range options {
		option(client)
	}
	return client
}

func (c *Client) TranslateTexts(
	ctx context.Context,
	input port.ActivityTranslationRequest,
) (port.ActivityTranslationResult, error) {
	if c == nil {
		return port.ActivityTranslationResult{}, nil
	}

	sourceLocale := strings.ToLower(strings.TrimSpace(input.SourceLocale))
	targetLocales := normalizeLocales(input.TargetLocales)
	texts := trimTexts(input.Texts)
	if sourceLocale == "" || len(targetLocales) == 0 || len(texts) == 0 {
		return port.ActivityTranslationResult{
			Translations: map[string][]string{},
			Items:        map[string][]port.ActivityTranslationTextResult{},
		}, nil
	}
	if err := validateTranslationRequestSize(texts); err != nil {
		return port.ActivityTranslationResult{}, err
	}

	payload := translateRequest{
		SourceLanguage:  sourceLocale,
		TargetLanguages: targetLocales,
		Texts:           texts,
		ContentType:     translationContentTypeActivity,
	}
	body := bytes.NewBuffer(nil)
	if err := json.NewEncoder(body).Encode(payload); err != nil {
		return port.ActivityTranslationResult{}, fmt.Errorf("encode translation request: %w", err)
	}

	req, err := http.NewRequestWithContext(
		ctx,
		http.MethodPost,
		c.baseURL+"/internal/v1/translations/translate",
		body,
	)
	if err != nil {
		return port.ActivityTranslationResult{}, fmt.Errorf("create translation request: %w", err)
	}
	req.Header.Set("Accept", "application/json")
	req.Header.Set("Content-Type", "application/json")
	if c.internalToken != "" {
		req.Header.Set(headerInternalServiceToken, c.internalToken)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return port.ActivityTranslationResult{}, fmt.Errorf("call translation-service: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < http.StatusOK || resp.StatusCode >= http.StatusMultipleChoices {
		return port.ActivityTranslationResult{}, newServiceError(resp.StatusCode, readErrorMessage(resp.Body))
	}

	var decoded translateResponse
	if err = json.NewDecoder(resp.Body).Decode(&decoded); err != nil {
		return port.ActivityTranslationResult{}, fmt.Errorf("decode translation response: %w", err)
	}
	result := port.ActivityTranslationResult{
		Translations: make(map[string][]string, len(decoded.Translations)),
		Items:        make(map[string][]port.ActivityTranslationTextResult, len(decoded.Translations)),
		Provider:     strings.TrimSpace(decoded.Provider),
	}
	for _, locale := range targetLocales {
		translatedItems, exists := decoded.Translations[locale]
		if !exists || len(translatedItems) != len(texts) {
			return port.ActivityTranslationResult{}, fmt.Errorf(
				"translation-service returned %d items for %s, want %d",
				len(translatedItems),
				locale,
				len(texts),
			)
		}
		result.Translations[locale] = make([]string, 0, len(translatedItems))
		result.Items[locale] = make([]port.ActivityTranslationTextResult, 0, len(translatedItems))
		for _, translatedItem := range translatedItems {
			item := port.ActivityTranslationTextResult{
				Text: strings.TrimSpace(translatedItem.Text),
				Status: port.ActivityTranslationTextStatus(
					strings.ToLower(strings.TrimSpace(translatedItem.Status)),
				),
				Provider: strings.TrimSpace(translatedItem.Provider),
				CacheHit: translatedItem.CacheHit,
			}
			result.Translations[locale] = append(result.Translations[locale], item.Text)
			result.Items[locale] = append(result.Items[locale], item)
			if !input.AllowIncomplete && !translationStatusSucceeded(item.Status) {
				return result, &ServiceError{
					statusCode: http.StatusServiceUnavailable,
					code:       string(item.Status),
					retryable:  translationStatusRetryable(item.Status),
				}
			}
		}
	}
	return result, nil
}

type ServiceError struct {
	statusCode int
	code       string
	retryable  bool
}

func (e *ServiceError) Error() string {
	return fmt.Sprintf("translation-service request failed: status=%d code=%s", e.statusCode, e.code)
}

func (e *ServiceError) Retryable() bool {
	return e != nil && e.retryable
}

func (e *ServiceError) Code() string {
	if e == nil {
		return "translation_service_error"
	}
	return e.code
}

func newServiceError(statusCode int, code string) *ServiceError {
	normalizedCode := strings.ToLower(strings.TrimSpace(code))
	if normalizedCode == "" {
		normalizedCode = "translation_service_error"
	}
	return &ServiceError{
		statusCode: statusCode,
		code:       normalizedCode,
		retryable:  statusCode == http.StatusRequestTimeout || statusCode == http.StatusTooManyRequests || statusCode >= 500,
	}
}

func translationStatusSucceeded(status port.ActivityTranslationTextStatus) bool {
	switch status {
	case port.ActivityTranslationTextTranslated,
		port.ActivityTranslationTextCached,
		port.ActivityTranslationTextSameLanguage:
		return true
	default:
		return false
	}
}

func translationStatusRetryable(status port.ActivityTranslationTextStatus) bool {
	switch status {
	case port.ActivityTranslationTextQuotaExhausted,
		port.ActivityTranslationTextDisabled,
		port.ActivityTranslationTextProviderUnavailable:
		return true
	default:
		return false
	}
}

func validateTranslationRequestSize(texts []string) error {
	if len(texts) > maxTranslationRequestTexts {
		return &ServiceError{statusCode: http.StatusBadRequest, code: "request_too_large"}
	}
	characters := 0
	for _, text := range texts {
		characters += utf8.RuneCountInString(text)
		if characters > maxTranslationRequestCharacters {
			return &ServiceError{statusCode: http.StatusBadRequest, code: "request_too_large"}
		}
	}
	return nil
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
	ContentType     string   `json:"contentType"`
}

type translateResponse struct {
	Translations map[string][]translatedText `json:"translations"`
	Provider     string                      `json:"provider,omitempty"`
}

type translatedText struct {
	Text     string `json:"text"`
	Status   string `json:"status"`
	Provider string `json:"provider,omitempty"`
	CacheHit bool   `json:"cacheHit,omitempty"`
}
