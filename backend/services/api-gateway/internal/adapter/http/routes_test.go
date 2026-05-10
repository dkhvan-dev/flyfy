package http

import "testing"

func TestStickerCatalogRouteProxiesToStickerService(t *testing.T) {
	policy := matchRoutePolicy("/api/v1/stickers/catalog", "/api/v1")

	if policy == nil {
		t.Fatal("expected sticker catalog route policy")
	}
	if policy.Upstream != "sticker" {
		t.Fatalf("upstream = %q, want sticker", policy.Upstream)
	}
	if policy.AuthMode != RouteAuthAuthenticated {
		t.Fatalf("auth mode = %q, want authenticated", policy.AuthMode)
	}
	if policy.RewritePrefix != "/v1/stickers" {
		t.Fatalf("rewrite prefix = %q, want /v1/stickers", policy.RewritePrefix)
	}
}

func TestTourRoutesProxyToTourService(t *testing.T) {
	publicPolicy := matchRoutePolicy("/api/v1/tours/123", "/api/v1")
	if publicPolicy == nil {
		t.Fatal("expected public tour route policy")
	}
	if publicPolicy.Upstream != "tour" {
		t.Fatalf("public upstream = %q, want tour", publicPolicy.Upstream)
	}
	if publicPolicy.AuthMode != RouteAuthPublic {
		t.Fatalf("public auth mode = %q, want public", publicPolicy.AuthMode)
	}
	if publicPolicy.RewritePrefix != "/v1/tours" {
		t.Fatalf("public rewrite prefix = %q, want /v1/tours", publicPolicy.RewritePrefix)
	}

	myPolicy := matchRoutePolicy("/api/v1/me/tours/123", "/api/v1")
	if myPolicy == nil {
		t.Fatal("expected my tour route policy")
	}
	if myPolicy.Upstream != "tour" {
		t.Fatalf("my upstream = %q, want tour", myPolicy.Upstream)
	}
	if myPolicy.AuthMode != RouteAuthAuthenticated {
		t.Fatalf("my auth mode = %q, want authenticated", myPolicy.AuthMode)
	}
	if myPolicy.RewritePrefix != "/v1/me/tours" {
		t.Fatalf("my rewrite prefix = %q, want /v1/me/tours", myPolicy.RewritePrefix)
	}
}
