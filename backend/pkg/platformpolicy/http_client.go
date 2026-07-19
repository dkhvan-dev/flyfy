package platformpolicy

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"mime"
	"net/http"
	"net/url"
	"strings"
	"time"
)

const (
	DefaultHTTPTimeout         = 750 * time.Millisecond
	MaximumHTTPTimeout         = 5 * time.Second
	DefaultMaxResponseBytes    = int64(4 * 1024)
	MaximumResponseBytes       = int64(64 * 1024)
	HeaderAuthorization        = "Authorization"
	HeaderInternalServiceToken = "X-Internal-Service-Token"
)

// DecisionSource obtains a decision. Checker remains responsible for temporal
// and monotonic validation before the decision can grant access.
type DecisionSource interface {
	FetchDecision(ctx context.Context) (Decision, error)
}

// TokenHeader is an ephemeral authentication header returned by a provider.
type TokenHeader struct {
	Name  string
	Value string
}

// TokenHeaderProvider supplies request-scoped authentication without storing a
// static secret in HTTPClientConfig.
type TokenHeaderProvider interface {
	TokenHeader(ctx context.Context) (TokenHeader, error)
}

// TokenSource is structurally compatible with the shared serviceauth token
// source and can be adapted with BearerTokenHeaderProvider.
type TokenSource interface {
	Token(ctx context.Context) (string, error)
}

// BearerTokenHeaderProvider adapts a dynamic service token source to an
// Authorization header.
type BearerTokenHeaderProvider struct {
	Source TokenSource
}

func (provider BearerTokenHeaderProvider) TokenHeader(ctx context.Context) (TokenHeader, error) {
	if provider.Source == nil {
		return TokenHeader{}, errors.New("platform policy bearer token source is required")
	}
	token, err := provider.Source.Token(ctx)
	if err != nil {
		return TokenHeader{}, errors.New("platform policy bearer token is unavailable")
	}
	token = strings.TrimSpace(token)
	if token == "" {
		return TokenHeader{}, errors.New("platform policy bearer token is empty")
	}
	return TokenHeader{Name: HeaderAuthorization, Value: "Bearer " + token}, nil
}

type HTTPClientConfig struct {
	BaseURL             string
	Timeout             time.Duration
	MaxResponseBytes    int64
	AllowInsecureHTTP   bool
	Transport           http.RoundTripper
	TokenHeaderProvider TokenHeaderProvider
}

// HTTPClient is a strictly bounded source for the internal policy endpoint.
type HTTPClient struct {
	endpoint            string
	timeout             time.Duration
	maxResponseBytes    int64
	tokenHeaderProvider TokenHeaderProvider
	httpClient          *http.Client
}

// FetchFailure classifies HTTP source failures without retaining response
// bodies or authentication material.
type FetchFailure string

const (
	FetchFailureAuthentication FetchFailure = "AUTHENTICATION"
	FetchFailureTransport      FetchFailure = "TRANSPORT"
	FetchFailureHTTPStatus     FetchFailure = "HTTP_STATUS"
	FetchFailureOversized      FetchFailure = "OVERSIZED_RESPONSE"
	FetchFailureMalformed      FetchFailure = "MALFORMED_RESPONSE"
)

// FetchError is returned by HTTPClient for a bounded, metrics-safe failure.
type FetchError struct {
	kind       FetchFailure
	statusCode int
	cause      error
}

func newFetchError(kind FetchFailure, statusCode int, cause error) *FetchError {
	return &FetchError{kind: kind, statusCode: statusCode, cause: cause}
}

func (err *FetchError) Error() string {
	if err == nil {
		return "platform policy fetch failed"
	}
	if err.kind == FetchFailureHTTPStatus {
		return fmt.Sprintf("platform policy endpoint returned HTTP status %d", err.statusCode)
	}
	return "platform policy fetch failed: " + string(err.kind)
}

func (err *FetchError) Unwrap() error {
	if err == nil {
		return nil
	}
	return err.cause
}

func (err *FetchError) Kind() FetchFailure {
	if err == nil {
		return ""
	}
	return err.kind
}

func (err *FetchError) StatusCode() int {
	if err == nil {
		return 0
	}
	return err.statusCode
}

func NewHTTPClient(cfg HTTPClientConfig) (*HTTPClient, error) {
	endpoint, err := buildEndpoint(cfg.BaseURL, cfg.AllowInsecureHTTP)
	if err != nil {
		return nil, err
	}

	timeout := cfg.Timeout
	if timeout == 0 {
		timeout = DefaultHTTPTimeout
	}
	if timeout < 0 || timeout > MaximumHTTPTimeout {
		return nil, fmt.Errorf("platform policy HTTP timeout must be within (0, %s]", MaximumHTTPTimeout)
	}

	maxResponseBytes := cfg.MaxResponseBytes
	if maxResponseBytes == 0 {
		maxResponseBytes = DefaultMaxResponseBytes
	}
	if maxResponseBytes < 1 || maxResponseBytes > MaximumResponseBytes {
		return nil, fmt.Errorf("platform policy maximum response bytes must be within [1, %d]", MaximumResponseBytes)
	}

	transport := cfg.Transport
	if transport == nil {
		transport = http.DefaultTransport
	}
	return &HTTPClient{
		endpoint:            endpoint,
		timeout:             timeout,
		maxResponseBytes:    maxResponseBytes,
		tokenHeaderProvider: cfg.TokenHeaderProvider,
		httpClient: &http.Client{
			Transport: transport,
			Timeout:   timeout,
			CheckRedirect: func(*http.Request, []*http.Request) error {
				return http.ErrUseLastResponse
			},
		},
	}, nil
}

func buildEndpoint(rawBaseURL string, allowInsecureHTTP bool) (string, error) {
	rawBaseURL = strings.TrimSpace(rawBaseURL)
	if rawBaseURL == "" {
		return "", errors.New("platform policy base URL is required")
	}
	baseURL, err := url.Parse(rawBaseURL)
	if err != nil {
		return "", errors.New("platform policy base URL is invalid")
	}
	if baseURL.Opaque != "" || baseURL.Scheme == "" || baseURL.Host == "" || baseURL.Hostname() == "" {
		return "", errors.New("platform policy base URL must be an absolute HTTP URL")
	}
	if baseURL.User != nil {
		return "", errors.New("platform policy base URL must not contain user information")
	}
	if baseURL.RawQuery != "" || baseURL.Fragment != "" || baseURL.ForceQuery {
		return "", errors.New("platform policy base URL must not contain a query or fragment")
	}
	if baseURL.RawPath != "" || (baseURL.Path != "" && baseURL.Path != "/") {
		return "", errors.New("platform policy base URL must not contain a path")
	}

	switch strings.ToLower(baseURL.Scheme) {
	case "https":
		baseURL.Scheme = "https"
	case "http":
		if !allowInsecureHTTP {
			return "", errors.New("platform policy plaintext HTTP requires explicit opt-in")
		}
		baseURL.Scheme = "http"
	default:
		return "", errors.New("platform policy base URL scheme must be HTTP or HTTPS")
	}

	baseURL.Path = EndpointPath
	baseURL.RawPath = ""
	return baseURL.String(), nil
}

func (client *HTTPClient) FetchDecision(ctx context.Context) (Decision, error) {
	if client == nil || client.httpClient == nil {
		return Decision{}, newFetchError(FetchFailureTransport, 0, errors.New("platform policy HTTP client is nil"))
	}
	if ctx == nil {
		return Decision{}, newFetchError(FetchFailureTransport, 0, errors.New("platform policy context is nil"))
	}

	callCtx, cancel := context.WithTimeout(ctx, client.timeout)
	defer cancel()

	request, err := http.NewRequestWithContext(callCtx, http.MethodGet, client.endpoint, nil)
	if err != nil {
		return Decision{}, newFetchError(FetchFailureTransport, 0, errors.New("build platform policy request"))
	}
	request.Header.Set("Accept", "application/json")

	if client.tokenHeaderProvider != nil {
		header, headerErr := client.tokenHeaderProvider.TokenHeader(callCtx)
		if headerErr != nil {
			return Decision{}, newFetchError(FetchFailureAuthentication, 0, errors.New("platform policy token header is unavailable"))
		}
		name, value, validationErr := validateTokenHeader(header)
		if validationErr != nil {
			return Decision{}, newFetchError(FetchFailureAuthentication, 0, validationErr)
		}
		request.Header.Set(name, value)
	}

	response, err := client.httpClient.Do(request)
	if err != nil {
		if callCtx.Err() != nil {
			err = callCtx.Err()
		}
		return Decision{}, newFetchError(FetchFailureTransport, 0, err)
	}
	defer response.Body.Close()

	if response.StatusCode != http.StatusOK {
		_, _ = io.Copy(io.Discard, io.LimitReader(response.Body, client.maxResponseBytes))
		return Decision{}, newFetchError(FetchFailureHTTPStatus, response.StatusCode, nil)
	}
	if response.ContentLength > client.maxResponseBytes {
		return Decision{}, newFetchError(FetchFailureOversized, 0, nil)
	}

	contentType, _, err := mime.ParseMediaType(response.Header.Get("Content-Type"))
	if err != nil || contentType != "application/json" {
		return Decision{}, newFetchError(FetchFailureMalformed, 0, errors.New("platform policy content type is invalid"))
	}

	body, err := io.ReadAll(io.LimitReader(response.Body, client.maxResponseBytes+1))
	if err != nil {
		return Decision{}, newFetchError(FetchFailureTransport, 0, errors.New("read platform policy response"))
	}
	if int64(len(body)) > client.maxResponseBytes {
		return Decision{}, newFetchError(FetchFailureOversized, 0, nil)
	}

	decoder := json.NewDecoder(bytes.NewReader(body))
	decoder.DisallowUnknownFields()
	var decision Decision
	if err := decoder.Decode(&decision); err != nil {
		return Decision{}, newFetchError(FetchFailureMalformed, 0, errors.New("decode platform policy response"))
	}
	var trailing any
	if err := decoder.Decode(&trailing); !errors.Is(err, io.EOF) {
		return Decision{}, newFetchError(FetchFailureMalformed, 0, errors.New("platform policy response contains trailing data"))
	}
	if validationErr := validateDecisionShape(decision); validationErr != nil {
		return Decision{}, newFetchError(FetchFailureMalformed, 0, validationErr)
	}
	return decision, nil
}

func validateTokenHeader(header TokenHeader) (string, string, error) {
	name := http.CanonicalHeaderKey(strings.TrimSpace(header.Name))
	if name != HeaderAuthorization && name != HeaderInternalServiceToken {
		return "", "", errors.New("platform policy token header name is not allowed")
	}
	value := strings.TrimSpace(header.Value)
	if value == "" || strings.ContainsAny(value, "\r\n") {
		return "", "", errors.New("platform policy token header value is invalid")
	}
	return name, value, nil
}
