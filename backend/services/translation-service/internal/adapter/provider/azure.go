package provider

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"

	"kz/inflap/backend/services/translation-service/internal/domain/model"
	"kz/inflap/backend/services/translation-service/internal/domain/port"
)

const azureTranslatorName = "azure_translator"

type AzureConfig struct {
	BaseURL    string
	Key        string
	Region     string
	Timeout    time.Duration
	HTTPClient *http.Client
}

type AzureTranslator struct {
	baseURL    string
	key        string
	region     string
	httpClient *http.Client
}

func NewAzureTranslator(cfg AzureConfig) *AzureTranslator {
	baseURL := strings.TrimRight(strings.TrimSpace(cfg.BaseURL), "/")
	if baseURL == "" {
		baseURL = "https://api.cognitive.microsofttranslator.com"
	}
	timeout := cfg.Timeout
	if timeout <= 0 {
		timeout = 5 * time.Second
	}
	httpClient := cfg.HTTPClient
	if httpClient == nil {
		httpClient = &http.Client{Timeout: timeout}
	}
	if httpClient.Timeout <= 0 {
		httpClient.Timeout = timeout
	}
	return &AzureTranslator{
		baseURL:    strings.TrimRight(baseURL, "/"),
		key:        strings.TrimSpace(cfg.Key),
		region:     strings.TrimSpace(cfg.Region),
		httpClient: httpClient,
	}
}

func (c *AzureTranslator) Name() string {
	return azureTranslatorName
}

func (c *AzureTranslator) Translate(ctx context.Context, input port.ProviderTranslateRequest) (port.ProviderTranslateResult, error) {
	if c == nil {
		return port.ProviderTranslateResult{}, errors.New("azure translator client is nil")
	}
	endpoint, err := url.Parse(c.baseURL + "/translate")
	if err != nil {
		return port.ProviderTranslateResult{}, fmt.Errorf("parse azure translator endpoint: %w", err)
	}
	query := endpoint.Query()
	query.Set("api-version", "3.0")
	query.Set("from", string(input.SourceLanguage))
	query.Set("textType", "plain")
	for _, targetLanguage := range input.TargetLanguages {
		query.Add("to", string(targetLanguage))
	}
	endpoint.RawQuery = query.Encode()

	payload := make([]azureTranslateRequestItem, 0, len(input.Texts))
	for _, text := range input.Texts {
		payload = append(payload, azureTranslateRequestItem{Text: text})
	}
	body := bytes.NewBuffer(nil)
	if err := json.NewEncoder(body).Encode(payload); err != nil {
		return port.ProviderTranslateResult{}, fmt.Errorf("encode azure translation request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint.String(), body)
	if err != nil {
		return port.ProviderTranslateResult{}, fmt.Errorf("create azure translation request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json; charset=UTF-8")
	req.Header.Set("Accept", "application/json")
	if c.key != "" {
		req.Header.Set("Ocp-Apim-Subscription-Key", c.key)
	}
	if c.region != "" {
		req.Header.Set("Ocp-Apim-Subscription-Region", c.region)
	}
	if strings.TrimSpace(input.RequestID) != "" {
		req.Header.Set("X-ClientTraceId", strings.TrimSpace(input.RequestID))
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return port.ProviderTranslateResult{}, fmt.Errorf("call azure translator: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusForbidden {
		return port.ProviderTranslateResult{}, port.ErrProviderQuotaExceeded
	}
	if resp.StatusCode < http.StatusOK || resp.StatusCode >= http.StatusMultipleChoices {
		return port.ProviderTranslateResult{}, fmt.Errorf("azure translator status=%d message=%s", resp.StatusCode, readProviderError(resp.Body))
	}

	var decoded []azureTranslateResponseItem
	if err := json.NewDecoder(resp.Body).Decode(&decoded); err != nil {
		return port.ProviderTranslateResult{}, fmt.Errorf("decode azure translation response: %w", err)
	}
	translations := make(map[model.Language][]string, len(input.TargetLanguages))
	for _, language := range input.TargetLanguages {
		translations[language] = make([]string, len(input.Texts))
	}
	for index, item := range decoded {
		if index >= len(input.Texts) {
			break
		}
		for _, translation := range item.Translations {
			language, ok := model.NormalizeLanguage(translation.To)
			if !ok {
				continue
			}
			if _, requested := translations[language]; !requested {
				continue
			}
			translations[language][index] = translation.Text
		}
	}

	return port.ProviderTranslateResult{
		Translations:       translations,
		MeteredCharacters:  parseMeteredUsage(resp.Header.Get("X-metered-usage")),
		ProviderModelLabel: resp.Header.Get("X-mt-system"),
	}, nil
}

type azureTranslateRequestItem struct {
	Text string `json:"Text"`
}

type azureTranslateResponseItem struct {
	Translations []azureTranslation `json:"translations"`
}

type azureTranslation struct {
	To   string `json:"to"`
	Text string `json:"text"`
}

func parseMeteredUsage(value string) int {
	parsed, err := strconv.Atoi(strings.TrimSpace(value))
	if err != nil || parsed < 0 {
		return 0
	}
	return parsed
}

func readProviderError(body io.Reader) string {
	payload, err := io.ReadAll(io.LimitReader(body, 1024))
	if err != nil || len(payload) == 0 {
		return "unknown"
	}
	return strings.TrimSpace(string(payload))
}
