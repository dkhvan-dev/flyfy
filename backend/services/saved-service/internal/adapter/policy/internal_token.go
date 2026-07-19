package policy

import (
	"context"
	"errors"
	"strings"
	"unicode"

	"kz/inflap/backend/pkg/platformpolicy"
)

var ErrInvalidInternalToken = errors.New("invalid platform policy authentication configuration")

type InternalTokenHeaderProvider struct {
	token string
}

func NewInternalTokenHeaderProvider(token string) (*InternalTokenHeaderProvider, error) {
	if token == "" || token != strings.TrimSpace(token) || strings.IndexFunc(token, unicode.IsControl) >= 0 {
		return nil, ErrInvalidInternalToken
	}
	return &InternalTokenHeaderProvider{token: token}, nil
}

func (provider *InternalTokenHeaderProvider) TokenHeader(
	ctx context.Context,
) (platformpolicy.TokenHeader, error) {
	if ctx == nil || provider == nil || provider.token == "" {
		return platformpolicy.TokenHeader{}, ErrInvalidInternalToken
	}
	if err := ctx.Err(); err != nil {
		return platformpolicy.TokenHeader{}, err
	}
	return platformpolicy.TokenHeader{
		Name:  platformpolicy.HeaderInternalServiceToken,
		Value: provider.token,
	}, nil
}

func (*InternalTokenHeaderProvider) String() string {
	return "InternalTokenHeaderProvider{token=redacted}"
}

func (provider *InternalTokenHeaderProvider) GoString() string {
	return provider.String()
}
