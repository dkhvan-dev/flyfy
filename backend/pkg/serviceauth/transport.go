package serviceauth

import (
	"context"
	"fmt"
	"net/http"
	"strings"
)

const HeaderInternalServiceToken = "X-Internal-Service-Token"

type TokenSource interface {
	Token(ctx context.Context) (string, error)
}

type BearerTransport struct {
	source TokenSource
	base   http.RoundTripper
}

func NewBearerTransport(source TokenSource, base http.RoundTripper) *BearerTransport {
	if base == nil {
		base = http.DefaultTransport
	}
	return &BearerTransport{
		source: source,
		base:   base,
	}
}

func (t *BearerTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	if t == nil || t.source == nil {
		return nil, fmt.Errorf("serviceauth bearer transport token source is required")
	}
	token, err := t.source.Token(req.Context())
	if err != nil {
		return nil, fmt.Errorf("get service token: %w", err)
	}
	token = strings.TrimSpace(token)
	if token == "" {
		return nil, fmt.Errorf("get service token: empty token")
	}

	out := req.Clone(req.Context())
	out.Header.Del(HeaderInternalServiceToken)
	out.Header.Set("Authorization", "Bearer "+token)
	return t.base.RoundTrip(out)
}
