package main

import (
	"strings"
	"testing"

	grpcadapter "kz/inflap/backend/services/feed-service/internal/adapter/grpc"
	"kz/inflap/backend/services/feed-service/internal/config"
)

func TestNewFeedSavedSourceGRPCServerRegistersContract(t *testing.T) {
	t.Parallel()

	server := newFeedSavedSourceGRPCServer(
		grpcadapter.NewSavedPostSourceServer(nil, nil),
	)
	if _, exists := server.GetServiceInfo()["content.v1.SavedSourceService"]; !exists {
		t.Fatal("content.v1.SavedSourceService is not registered")
	}
}

func TestNewSavedPostSourceAuthorizerFailsClosedInProduction(t *testing.T) {
	t.Parallel()

	authorizer, err := newSavedPostSourceAuthorizer(&config.Config{
		App: config.AppConfig{Env: "production"},
	})
	if authorizer != nil || err == nil || !strings.Contains(err.Error(), "SERVICE_AUTH_ISSUER") {
		t.Fatalf("newSavedPostSourceAuthorizer() = (%v, %v), want production config error", authorizer, err)
	}
}

func TestNewSavedPostSourceAuthorizerMayBeDisabledOnlyOutsideProduction(t *testing.T) {
	t.Parallel()

	authorizer, err := newSavedPostSourceAuthorizer(&config.Config{
		App: config.AppConfig{Env: "development"},
	})
	if authorizer != nil || err != nil {
		t.Fatalf("newSavedPostSourceAuthorizer() = (%v, %v), want nil, nil", authorizer, err)
	}
}
