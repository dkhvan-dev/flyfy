package switches

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"

	"github.com/rs/zerolog"

	"kz/inflap/backend/services/auth-service/internal/config"
	"kz/inflap/backend/services/auth-service/internal/domain/port"
)

type Client struct {
	baseURL string
	token   string
	http    *http.Client
	logger  zerolog.Logger
}

type Option func(*Client)

func WithHTTPClient(httpClient *http.Client) Option {
	return func(c *Client) {
		if httpClient != nil {
			c.http = httpClient
		}
	}
}

func NewHTTPClient(cfg config.SwitchesConfig, logger zerolog.Logger, opts ...Option) (*Client, error) {
	baseURL := strings.TrimRight(strings.TrimSpace(cfg.BaseURL), "/")
	if baseURL == "" {
		return nil, fmt.Errorf("switches service url is empty")
	}
	if _, err := url.ParseRequestURI(baseURL); err != nil {
		return nil, fmt.Errorf("parse switches service url: %w", err)
	}
	timeout := cfg.Timeout
	if timeout <= 0 {
		timeout = 800 * time.Millisecond
	}
	client := &Client{
		baseURL: baseURL,
		token:   strings.TrimSpace(cfg.InternalServiceToken),
		http:    &http.Client{Timeout: timeout},
		logger:  logger.With().Str("component", "switches_client").Logger(),
	}
	for _, opt := range opts {
		if opt != nil {
			opt(client)
		}
	}
	return client, nil
}

func (c *Client) GetFeatureFlag(ctx context.Context, domainCode string, code string) (port.FeatureFlag, error) {
	if c == nil {
		return port.FeatureFlag{}, nil
	}
	query := url.Values{}
	query.Set("domainCode", strings.TrimSpace(domainCode))
	endpoint := c.baseURL + "/api/v1/internal/feature-flags/" + url.PathEscape(strings.TrimSpace(code)) + "?" + query.Encode()
	req, err := c.newRequest(ctx, http.MethodGet, endpoint)
	if err != nil {
		return port.FeatureFlag{}, err
	}

	resp, err := c.http.Do(req)
	if err != nil {
		return port.FeatureFlag{}, fmt.Errorf("request feature flag: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusNotFound {
		return port.FeatureFlag{}, nil
	}
	if resp.StatusCode < http.StatusOK || resp.StatusCode >= http.StatusMultipleChoices {
		return port.FeatureFlag{}, fmt.Errorf("feature flag service returned status %d", resp.StatusCode)
	}

	var payload struct {
		Enabled bool   `json:"enabled"`
		Type    string `json:"type"`
		Value   []any  `json:"value"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&payload); err != nil {
		return port.FeatureFlag{}, fmt.Errorf("decode feature flag response: %w", err)
	}

	return port.FeatureFlag{
		Enabled: payload.Enabled,
		Type:    port.FeatureFlagType(payload.Type),
		Values:  featureFlagValuesToStrings(payload.Value),
	}, nil
}

func (c *Client) HasActiveTechBreak(ctx context.Context, input port.TechBreakCheckInput) (bool, error) {
	if c == nil {
		return false, nil
	}
	query := url.Values{}
	query.Set("domainCode", strings.TrimSpace(input.DomainCode))
	if email := strings.TrimSpace(input.Email); email != "" {
		query.Set("email", email)
	}
	if nickname := strings.TrimSpace(input.Nickname); nickname != "" {
		query.Set("nickname", nickname)
	}
	for _, scopeCode := range input.ScopeCodes {
		if scopeCode = strings.TrimSpace(scopeCode); scopeCode != "" {
			query.Add("scopeCodes", scopeCode)
		}
	}

	endpoint := c.baseURL + "/api/v1/internal/tech-breaks/has-active?" + query.Encode()
	req, err := c.newRequest(ctx, http.MethodGet, endpoint)
	if err != nil {
		return false, err
	}

	resp, err := c.http.Do(req)
	if err != nil {
		return false, fmt.Errorf("request active tech break: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < http.StatusOK || resp.StatusCode >= http.StatusMultipleChoices {
		return false, fmt.Errorf("tech break service returned status %d", resp.StatusCode)
	}

	var active bool
	if err := json.NewDecoder(resp.Body).Decode(&active); err != nil {
		return false, fmt.Errorf("decode active tech break response: %w", err)
	}
	return active, nil
}

func (c *Client) newRequest(ctx context.Context, method string, endpoint string) (*http.Request, error) {
	req, err := http.NewRequestWithContext(ctx, method, endpoint, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Accept", "application/json")
	if c.token != "" {
		req.Header.Set("X-Internal-Service-Token", c.token)
	}
	return req, nil
}

func featureFlagValuesToStrings(values []any) []string {
	result := make([]string, 0, len(values))
	for _, value := range values {
		switch v := value.(type) {
		case string:
			result = append(result, v)
		case float64:
			if v == float64(int64(v)) {
				result = append(result, strconv.FormatInt(int64(v), 10))
			} else {
				result = append(result, strconv.FormatFloat(v, 'f', -1, 64))
			}
		case bool:
			result = append(result, strconv.FormatBool(v))
		case nil:
			continue
		default:
			result = append(result, fmt.Sprint(v))
		}
	}
	return result
}

var _ port.FeatureFlagReader = (*Client)(nil)
var _ port.TechBreakChecker = (*Client)(nil)
