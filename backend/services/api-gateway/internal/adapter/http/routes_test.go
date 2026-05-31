package http

import "testing"

func TestAdminPanelRouteProxiesToAdminPanelService(t *testing.T) {
	policy := matchRoutePolicy("/admin/dashboard", "/api/v1")

	if policy == nil {
		t.Fatal("expected admin panel route policy")
	}
	if policy.Upstream != "admin-panel" {
		t.Fatalf("upstream = %q, want admin-panel", policy.Upstream)
	}
	if policy.AuthMode != RouteAuthPublic {
		t.Fatalf("auth mode = %q, want public", policy.AuthMode)
	}
	if policy.RewritePrefix != "/admin" {
		t.Fatalf("rewrite prefix = %q, want /admin", policy.RewritePrefix)
	}
}

func TestAdminPanelRouteRequiresPathBoundary(t *testing.T) {
	policy := matchRoutePolicy("/administrator", "/api/v1")

	if policy != nil && policy.Upstream == "admin-panel" {
		t.Fatalf("path matched admin panel route unexpectedly: %+v", policy)
	}
}

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

func TestCurrencyRoutesProxyToCurrencyServicePublicly(t *testing.T) {
	policy := matchRoutePolicy("/api/v1/currency/convert", "/api/v1")

	if policy == nil {
		t.Fatal("expected currency route policy")
	}
	if policy.Upstream != "currency" {
		t.Fatalf("upstream = %q, want currency", policy.Upstream)
	}
	if policy.AuthMode != RouteAuthPublic {
		t.Fatalf("auth mode = %q, want public", policy.AuthMode)
	}
	if policy.RewritePrefix != "/v1/currency" {
		t.Fatalf("rewrite prefix = %q, want /v1/currency", policy.RewritePrefix)
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

	guideBookingsPolicy := matchRoutePolicy("/api/v1/me/guide-excursion-bookings", "/api/v1")
	if guideBookingsPolicy == nil {
		t.Fatal("expected guide excursion bookings route policy")
	}
	if guideBookingsPolicy.Upstream != "excursion" {
		t.Fatalf("guide bookings upstream = %q, want excursion", guideBookingsPolicy.Upstream)
	}
	if guideBookingsPolicy.AuthMode != RouteAuthAuthenticated {
		t.Fatalf("guide bookings auth mode = %q, want authenticated", guideBookingsPolicy.AuthMode)
	}
	if guideBookingsPolicy.RewritePrefix != "/v1/me/guide-excursion-bookings" {
		t.Fatalf("guide bookings rewrite prefix = %q, want /v1/me/guide-excursion-bookings", guideBookingsPolicy.RewritePrefix)
	}

	myBookingsPolicy := matchRoutePolicy("/api/v1/me/excursion-bookings/booking-1/reviews", "/api/v1")
	if myBookingsPolicy == nil {
		t.Fatal("expected my excursion booking reviews route policy")
	}
	if myBookingsPolicy.Upstream != "excursion" {
		t.Fatalf("my booking reviews upstream = %q, want excursion", myBookingsPolicy.Upstream)
	}
	if myBookingsPolicy.AuthMode != RouteAuthAuthenticated {
		t.Fatalf("my booking reviews auth mode = %q, want authenticated", myBookingsPolicy.AuthMode)
	}
	if myBookingsPolicy.RewritePrefix != "/v1/me/excursion-bookings" {
		t.Fatalf("my booking reviews rewrite prefix = %q, want /v1/me/excursion-bookings", myBookingsPolicy.RewritePrefix)
	}

	schedulePolicy := matchRoutePolicy("/api/v1/me/excursion-schedule/slots", "/api/v1")
	if schedulePolicy == nil {
		t.Fatal("expected guide excursion schedule route policy")
	}
	if schedulePolicy.Upstream != "excursion" {
		t.Fatalf("schedule upstream = %q, want excursion", schedulePolicy.Upstream)
	}
	if schedulePolicy.AuthMode != RouteAuthAuthenticated {
		t.Fatalf("schedule auth mode = %q, want authenticated", schedulePolicy.AuthMode)
	}
	if schedulePolicy.RewritePrefix != "/v1/me/excursion-schedule" {
		t.Fatalf("schedule rewrite prefix = %q, want /v1/me/excursion-schedule", schedulePolicy.RewritePrefix)
	}

	publicGuideSchedulePolicy := matchRoutePolicy("/api/v1/excursion-guides/guide-user-1/schedule", "/api/v1")
	if publicGuideSchedulePolicy == nil {
		t.Fatal("expected public guide excursion schedule route policy")
	}
	if publicGuideSchedulePolicy.Upstream != "excursion" {
		t.Fatalf("public guide schedule upstream = %q, want excursion", publicGuideSchedulePolicy.Upstream)
	}
	if publicGuideSchedulePolicy.AuthMode != RouteAuthPublic {
		t.Fatalf("public guide schedule auth mode = %q, want public", publicGuideSchedulePolicy.AuthMode)
	}
	if publicGuideSchedulePolicy.RewritePrefix != "/v1/excursion-guides" {
		t.Fatalf("public guide schedule rewrite prefix = %q, want /v1/excursion-guides", publicGuideSchedulePolicy.RewritePrefix)
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

func TestGuideReviewsRouteProxiesPublicReadsToExcursionService(t *testing.T) {
	policy := matchRoutePolicy("/api/v1/guide-reviews?guideUserId=guide-user-1", "/api/v1")
	if policy == nil {
		t.Fatal("expected guide reviews route policy")
	}
	if policy.Upstream != "excursion" {
		t.Fatalf("upstream = %q, want excursion", policy.Upstream)
	}
	if policy.AuthMode != RouteAuthPublic {
		t.Fatalf("auth mode = %q, want public", policy.AuthMode)
	}
	if policy.RewritePrefix != "/v1/guide-reviews" {
		t.Fatalf("rewrite prefix = %q, want /v1/guide-reviews", policy.RewritePrefix)
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
