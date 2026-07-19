package main

import (
	"strings"
	"testing"

	"kz/inflap/backend/services/place-service/internal/config"
)

func TestNewSavedSourceAuthorizerFailsClosedWithoutProductionServiceAuth(t *testing.T) {
	t.Parallel()

	verifier, err := newSavedSourceAuthorizer(&config.Config{
		App: config.AppConfig{Env: "PRODUCTION"},
	})
	if verifier != nil {
		t.Fatal("verifier is non-nil without production service auth configuration")
	}
	if err == nil || !strings.Contains(err.Error(), "SERVICE_AUTH_ISSUER") {
		t.Fatalf("error = %v, want missing service auth configuration", err)
	}
}

func TestNewSavedSourceAuthorizerMayRemainDisabledOnlyOutsideProduction(t *testing.T) {
	t.Parallel()

	verifier, err := newSavedSourceAuthorizer(&config.Config{
		App: config.AppConfig{Env: "development"},
	})
	if err != nil || verifier != nil {
		t.Fatalf("newSavedSourceAuthorizer() = %#v, %v, want nil, nil", verifier, err)
	}
}
