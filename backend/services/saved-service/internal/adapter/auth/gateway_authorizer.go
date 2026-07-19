package auth

import (
	"context"
	"errors"
	"strings"

	"kz/inflap/backend/pkg/serviceauth"
)

var (
	ErrInvalidGatewayAuthorizer = errors.New("invalid Gateway authorizer configuration")
	ErrGatewayUnauthorized      = errors.New("Gateway service authentication failed")
)

type BearerVerifier interface {
	ValidateBearer(
		ctx context.Context,
		authorizationHeader string,
		requiredRoles []string,
	) (*serviceauth.Claims, error)
}

type GatewayAuthorizer struct {
	verifier        BearerVerifier
	expectedSubject string
	requiredRole    string
}

func NewGatewayAuthorizer(
	verifier BearerVerifier,
	expectedSubject string,
	requiredRole string,
) (*GatewayAuthorizer, error) {
	expectedSubject = strings.TrimSpace(expectedSubject)
	requiredRole = strings.TrimSpace(requiredRole)
	if verifier == nil || expectedSubject == "" || requiredRole == "" {
		return nil, ErrInvalidGatewayAuthorizer
	}
	return &GatewayAuthorizer{
		verifier:        verifier,
		expectedSubject: expectedSubject,
		requiredRole:    requiredRole,
	}, nil
}

func (authorizer *GatewayAuthorizer) AuthorizeGateway(
	ctx context.Context,
	authorizationHeader string,
) error {
	if ctx == nil || authorizer == nil || authorizer.verifier == nil {
		return ErrGatewayUnauthorized
	}
	if err := ctx.Err(); err != nil {
		return ErrGatewayUnauthorized
	}
	claims, err := authorizer.verifier.ValidateBearer(
		ctx,
		authorizationHeader,
		[]string{authorizer.requiredRole},
	)
	if err != nil || claims == nil || claims.Subject != authorizer.expectedSubject {
		return ErrGatewayUnauthorized
	}
	return nil
}

func (*GatewayAuthorizer) String() string {
	return "GatewayAuthorizer{verifier=redacted}"
}

func (authorizer *GatewayAuthorizer) GoString() string {
	return authorizer.String()
}
