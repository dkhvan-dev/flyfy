package auth

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"testing"

	"kz/inflap/backend/pkg/serviceauth"
)

type verifierStub struct {
	claims        *serviceauth.Claims
	err           error
	requiredRoles []string
	header        string
}

func (stub *verifierStub) ValidateBearer(
	_ context.Context,
	header string,
	requiredRoles []string,
) (*serviceauth.Claims, error) {
	stub.header = header
	stub.requiredRoles = append([]string(nil), requiredRoles...)
	return stub.claims, stub.err
}

func TestGatewayAuthorizerRequiresExpectedSubjectAndRole(t *testing.T) {
	verifier := &verifierStub{claims: &serviceauth.Claims{Subject: "api-gateway"}}
	authorizer, err := NewGatewayAuthorizer(verifier, "api-gateway", "saved:proxy")
	if err != nil {
		t.Fatalf("NewGatewayAuthorizer() error = %v", err)
	}

	if err := authorizer.AuthorizeGateway(context.Background(), "Bearer service-jwt"); err != nil {
		t.Fatalf("AuthorizeGateway() error = %v", err)
	}
	if verifier.header != "Bearer service-jwt" {
		t.Fatalf("authorization header = %q", verifier.header)
	}
	if len(verifier.requiredRoles) != 1 || verifier.requiredRoles[0] != "saved:proxy" {
		t.Fatalf("required roles = %#v, want [saved:proxy]", verifier.requiredRoles)
	}
}

func TestGatewayAuthorizerRejectsWrongSubject(t *testing.T) {
	verifier := &verifierStub{claims: &serviceauth.Claims{Subject: "other-service"}}
	authorizer, err := NewGatewayAuthorizer(verifier, "api-gateway", "saved:proxy")
	if err != nil {
		t.Fatalf("NewGatewayAuthorizer() error = %v", err)
	}

	if err := authorizer.AuthorizeGateway(context.Background(), "Bearer service-jwt"); !errors.Is(err, ErrGatewayUnauthorized) {
		t.Fatalf("AuthorizeGateway() error = %v, want neutral unauthorized", err)
	}
}

func TestGatewayAuthorizerDoesNotExposeVerifierFailure(t *testing.T) {
	sensitive := "upstream-jwks-body-with-sensitive-detail"
	verifier := &verifierStub{err: errors.New(sensitive)}
	authorizer, err := NewGatewayAuthorizer(verifier, "api-gateway", "saved:proxy")
	if err != nil {
		t.Fatalf("NewGatewayAuthorizer() error = %v", err)
	}

	authorizeErr := authorizer.AuthorizeGateway(context.Background(), "Bearer invalid")
	if !errors.Is(authorizeErr, ErrGatewayUnauthorized) {
		t.Fatalf("AuthorizeGateway() error = %v", authorizeErr)
	}
	if strings.Contains(authorizeErr.Error(), sensitive) {
		t.Fatalf("AuthorizeGateway() disclosed verifier error: %v", authorizeErr)
	}
	if strings.Contains(fmt.Sprintf("%+v", authorizer), sensitive) {
		t.Fatal("authorizer formatting disclosed verifier state")
	}
}
