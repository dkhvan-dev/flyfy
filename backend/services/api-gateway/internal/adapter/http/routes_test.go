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

func TestExcursionRoutesProxyToExcursionService(t *testing.T) {
	publicPolicy := matchRoutePolicy("/api/v1/excursions/123", "/api/v1")
	if publicPolicy == nil {
		t.Fatal("expected public excursion route policy")
	}
	if publicPolicy.Upstream != "excursion" {
		t.Fatalf("public upstream = %q, want excursion", publicPolicy.Upstream)
	}
	if publicPolicy.AuthMode != RouteAuthPublic {
		t.Fatalf("public auth mode = %q, want public", publicPolicy.AuthMode)
	}
	if publicPolicy.RewritePrefix != "/v1/excursions" {
		t.Fatalf("public rewrite prefix = %q, want /v1/excursions", publicPolicy.RewritePrefix)
	}

	myPolicy := matchRoutePolicy("/api/v1/me/excursions/123", "/api/v1")
	if myPolicy == nil {
		t.Fatal("expected my excursion route policy")
	}
	if myPolicy.Upstream != "excursion" {
		t.Fatalf("my upstream = %q, want excursion", myPolicy.Upstream)
	}
	if myPolicy.AuthMode != RouteAuthAuthenticated {
		t.Fatalf("my auth mode = %q, want authenticated", myPolicy.AuthMode)
	}
	if myPolicy.RewritePrefix != "/v1/me/excursions" {
		t.Fatalf("my rewrite prefix = %q, want /v1/me/excursions", myPolicy.RewritePrefix)
	}
}

func TestExcursionProductRoutesProxyToExcursionService(t *testing.T) {
	policy := matchRoutePolicy("/api/v1/excursion-products/123/offers", "/api/v1")

	if policy == nil {
		t.Fatal("expected excursion product route policy")
	}
	if policy.Upstream != "excursion" {
		t.Fatalf("upstream = %q, want excursion", policy.Upstream)
	}
	if policy.AuthMode != RouteAuthPublic {
		t.Fatalf("auth mode = %q, want public", policy.AuthMode)
	}
	if policy.RewritePrefix != "/v1/excursion-products" {
		t.Fatalf("rewrite prefix = %q, want /v1/excursion-products", policy.RewritePrefix)
	}
}

func TestPublicGuidesRouteDoesNotRequireBearerToken(t *testing.T) {
	policy := matchRoutePolicy("/api/v1/guides/public", "/api/v1")
	if policy == nil {
		t.Fatal("expected public guides route policy")
	}
	if policy.Upstream != "guide" {
		t.Fatalf("upstream = %q, want guide", policy.Upstream)
	}
	if policy.AuthMode != RouteAuthPublic {
		t.Fatalf("auth mode = %q, want public", policy.AuthMode)
	}
	if policy.RewritePrefix != "/v1/guides/public" {
		t.Fatalf("rewrite prefix = %q, want /v1/guides/public", policy.RewritePrefix)
	}
}

func TestGuideExcursionLanguagesRouteProxiesToExcursionService(t *testing.T) {
	policy := matchRoutePolicy("/api/v1/guides/excursion-languages", "/api/v1")
	if policy == nil {
		t.Fatal("expected guide excursion languages route policy")
	}
	if policy.Upstream != "excursion" {
		t.Fatalf("upstream = %q, want excursion", policy.Upstream)
	}
	if policy.AuthMode != RouteAuthPublic {
		t.Fatalf("auth mode = %q, want public", policy.AuthMode)
	}
	if policy.RewritePrefix != "/v1/guides/excursion-languages" {
		t.Fatalf("rewrite prefix = %q, want /v1/guides/excursion-languages", policy.RewritePrefix)
	}
}
