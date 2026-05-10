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
