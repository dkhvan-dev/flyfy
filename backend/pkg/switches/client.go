package switches

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"time"
)

const internalServiceTokenHeader = "X-Internal-Service-Token"

// TechBreakCheck is the request contract used by services that need to guard a
// domain or a narrower scope with switches-service.
type TechBreakCheck struct {
	DomainCode string
	ScopeCodes []string
	Email      string
	Nickname   string
}

// TechBreakChecker checks whether the requested domain/scope is currently under
// an active technical break.
type TechBreakChecker interface {
	HasActiveTechBreak(ctx context.Context, check TechBreakCheck) (bool, error)
}

type HTTPClientConfig struct {
	BaseURL              string
	InternalServiceToken string
	Timeout              time.Duration
}

type HTTPClient struct {
	baseURL              *url.URL
	internalServiceToken string
	httpClient           *http.Client
}

type HTTPClientOption func(*HTTPClient)

func EffectiveInternalServiceToken(preferred string, fallback string) string {
	if token := strings.TrimSpace(preferred); token != "" {
		return token
	}
	return strings.TrimSpace(fallback)
}

func WithHTTPClient(httpClient *http.Client) HTTPClientOption {
	return func(c *HTTPClient) {
		if httpClient != nil {
			c.httpClient = httpClient
		}
	}
}

func NewHTTPClient(cfg HTTPClientConfig, opts ...HTTPClientOption) (*HTTPClient, error) {
	rawBaseURL := strings.TrimSpace(cfg.BaseURL)
	if rawBaseURL == "" {
		return nil, errors.New("switches base URL is required")
	}
	baseURL, err := url.Parse(rawBaseURL)
	if err != nil {
		return nil, fmt.Errorf("parse switches base URL: %w", err)
	}
	if baseURL.Scheme == "" || baseURL.Host == "" {
		return nil, fmt.Errorf("switches base URL must include scheme and host: %q", rawBaseURL)
	}

	timeout := cfg.Timeout
	if timeout <= 0 {
		timeout = 800 * time.Millisecond
	}
	client := &HTTPClient{
		baseURL:              baseURL,
		internalServiceToken: strings.TrimSpace(cfg.InternalServiceToken),
		httpClient:           &http.Client{Timeout: timeout},
	}
	for _, opt := range opts {
		opt(client)
	}
	return client, nil
}

func (c *HTTPClient) HasActiveTechBreak(ctx context.Context, check TechBreakCheck) (bool, error) {
	domainCode := strings.TrimSpace(check.DomainCode)
	if domainCode == "" {
		return false, errors.New("tech break domain code is required")
	}

	endpoint := c.baseURL.ResolveReference(&url.URL{Path: "/api/v1/internal/tech-breaks/has-active"})
	query := endpoint.Query()
	query.Set("domainCode", domainCode)
	for _, scopeCode := range check.ScopeCodes {
		scopeCode = strings.TrimSpace(scopeCode)
		if scopeCode != "" {
			query.Add("scopeCodes", scopeCode)
		}
	}
	if email := strings.TrimSpace(check.Email); email != "" {
		query.Set("email", email)
	}
	if nickname := strings.TrimSpace(check.Nickname); nickname != "" {
		query.Set("nickname", nickname)
	}
	endpoint.RawQuery = query.Encode()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint.String(), nil)
	if err != nil {
		return false, fmt.Errorf("build tech break check request: %w", err)
	}
	if c.internalServiceToken != "" {
		req.Header.Set(internalServiceTokenHeader, c.internalServiceToken)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return false, fmt.Errorf("call switches-service tech break check: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < http.StatusOK || resp.StatusCode >= http.StatusMultipleChoices {
		return false, fmt.Errorf("switches-service tech break check returned status %d", resp.StatusCode)
	}

	var active bool
	if err := json.NewDecoder(resp.Body).Decode(&active); err != nil {
		return false, fmt.Errorf("decode switches-service tech break response: %w", err)
	}
	return active, nil
}
