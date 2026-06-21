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

func TestChecklistRoutesProxyToChecklistService(t *testing.T) {
	policy := matchRoutePolicyForMethod("POST", "/api/v1/checklists/trip-preview", "/api/v1")
	if policy == nil {
		t.Fatal("expected checklist route policy")
	}
	if policy.Upstream != "checklist" {
		t.Fatalf("upstream = %q, want checklist", policy.Upstream)
	}
	if policy.AuthMode != RouteAuthAuthenticated {
		t.Fatalf("auth mode = %q, want authenticated", policy.AuthMode)
	}
	if policy.RewritePrefix != "/v1/checklists" {
		t.Fatalf("rewrite prefix = %q, want /v1/checklists", policy.RewritePrefix)
	}
	assertRouteLimit(t, policy, 180)
}

func TestChecklistFeedbackRouteRequiresAuthentication(t *testing.T) {
	policy := matchRoutePolicyForMethod(
		"POST",
		"/api/v1/checklists/trips/trip-1/items/documents.passport_id/feedback",
		"/api/v1",
	)
	if policy == nil {
		t.Fatal("expected checklist feedback route policy")
	}
	if policy.Upstream != "checklist" {
		t.Fatalf("upstream = %q, want checklist", policy.Upstream)
	}
	if policy.AuthMode != RouteAuthAuthenticated {
		t.Fatalf("auth mode = %q, want authenticated", policy.AuthMode)
	}
	if policy.RewritePrefix != "/v1/checklists" {
		t.Fatalf("rewrite prefix = %q, want /v1/checklists", policy.RewritePrefix)
	}
	assertRouteLimit(t, policy, 180)
}

func TestAdminChecklistFeedbackRouteRequiresModeratorRole(t *testing.T) {
	policy := matchRoutePolicyForMethod("GET", "/api/v1/admin/checklists/feedback", "/api/v1")
	if policy == nil {
		t.Fatal("expected admin checklist route policy")
	}
	if policy.Upstream != "checklist" {
		t.Fatalf("upstream = %q, want checklist", policy.Upstream)
	}
	if policy.AuthMode != RouteAuthRoleBased {
		t.Fatalf("auth mode = %q, want role based", policy.AuthMode)
	}
	if policy.RewritePrefix != "/v1/admin/checklists" {
		t.Fatalf("rewrite prefix = %q, want /v1/admin/checklists", policy.RewritePrefix)
	}
	if len(policy.RequiredRoles) != 2 || policy.RequiredRoles[0] != "ADMIN" || policy.RequiredRoles[1] != "MODERATOR" {
		t.Fatalf("required roles = %#v, want ADMIN/MODERATOR", policy.RequiredRoles)
	}
	assertRouteLimit(t, policy, 60)
}

func TestChecklistCarryItemsSearchIsPublic(t *testing.T) {
	policy := matchRoutePolicyForMethod("GET", "/api/v1/checklists/carry-items/search?q=power", "/api/v1")
	if policy == nil {
		t.Fatal("expected checklist carry item search route policy")
	}
	if policy.Upstream != "checklist" {
		t.Fatalf("upstream = %q, want checklist", policy.Upstream)
	}
	if policy.AuthMode != RouteAuthPublic {
		t.Fatalf("auth mode = %q, want public", policy.AuthMode)
	}
	if policy.RewritePrefix != "/v1/checklists/carry-items/search" {
		t.Fatalf("rewrite prefix = %q, want /v1/checklists/carry-items/search", policy.RewritePrefix)
	}
	assertRouteLimit(t, policy, 180)
}

func TestContentFeedRoutesProxyToFeedServicePublicly(t *testing.T) {
	feedPolicy := matchRoutePolicyForMethod("GET", "/api/v1/feed?surface=home", "/api/v1")
	if feedPolicy == nil {
		t.Fatal("expected feed route policy")
	}
	if feedPolicy.Upstream != "feed" {
		t.Fatalf("feed upstream = %q, want stories", feedPolicy.Upstream)
	}
	if feedPolicy.AuthMode != RouteAuthPublic {
		t.Fatalf("feed auth mode = %q, want public", feedPolicy.AuthMode)
	}
	if feedPolicy.RewritePrefix != "/v1/feed" {
		t.Fatalf("feed rewrite prefix = %q, want /v1/feed", feedPolicy.RewritePrefix)
	}
	assertRouteLimit(t, feedPolicy, 120)

	communityPolicy := matchRoutePolicyForMethod("GET", "/api/v1/communities/investments", "/api/v1")
	if communityPolicy == nil {
		t.Fatal("expected communities route policy")
	}
	if communityPolicy.Upstream != "feed" {
		t.Fatalf("communities upstream = %q, want stories", communityPolicy.Upstream)
	}
	if communityPolicy.AuthMode != RouteAuthPublic {
		t.Fatalf("communities auth mode = %q, want public", communityPolicy.AuthMode)
	}
	if communityPolicy.RewritePrefix != "/v1/communities" {
		t.Fatalf("communities rewrite prefix = %q, want /v1/communities", communityPolicy.RewritePrefix)
	}
	assertRouteLimit(t, communityPolicy, 120)
}

func TestContentFeedEventRouteUsesWritePolicy(t *testing.T) {
	policy := matchRoutePolicyForMethod("POST", "/api/v1/feed/events", "/api/v1")
	if policy == nil {
		t.Fatal("expected feed events route policy")
	}
	if policy.Name != "content-feed-events" {
		t.Fatalf("name = %q, want content-feed-events", policy.Name)
	}
	if policy.Upstream != "feed" {
		t.Fatalf("upstream = %q, want stories", policy.Upstream)
	}
	if policy.AuthMode != RouteAuthPublic {
		t.Fatalf("auth mode = %q, want public", policy.AuthMode)
	}
	if policy.RewritePrefix != "/v1/feed/events" {
		t.Fatalf("rewrite prefix = %q, want /v1/feed/events", policy.RewritePrefix)
	}
	if policy.Cacheable {
		t.Fatal("feed event writes must not be cacheable")
	}
	assertRouteLimit(t, policy, 60)
}

func TestTrustRoutesUseAuthenticatedGrpcBridgePolicies(t *testing.T) {
	tests := map[string]struct {
		method    string
		path      string
		name      string
		rateLimit int
	}{
		"profile": {
			method:    "GET",
			path:      "/api/v1/trust/profile",
			name:      "trust-profile",
			rateLimit: 60,
		},
		"appeals list": {
			method:    "GET",
			path:      "/api/v1/trust/appeals",
			name:      "trust-appeals-list",
			rateLimit: 60,
		},
		"appeal submit": {
			method:    "POST",
			path:      "/api/v1/trust/restrictions/restriction-1/appeals",
			name:      "trust-appeals-submit",
			rateLimit: 10,
		},
	}

	for name, tc := range tests {
		t.Run(name, func(t *testing.T) {
			policy := matchRoutePolicyForMethod(tc.method, tc.path, "/api/v1")
			if policy == nil {
				t.Fatal("expected trust route policy")
			}
			if policy.Name != tc.name {
				t.Fatalf("name = %q, want %q", policy.Name, tc.name)
			}
			if policy.Upstream != "trust" {
				t.Fatalf("upstream = %q, want trust", policy.Upstream)
			}
			if policy.AuthMode != RouteAuthAuthenticated {
				t.Fatalf("auth mode = %q, want authenticated", policy.AuthMode)
			}
			assertRouteLimit(t, policy, tc.rateLimit)
		})
	}
}

func TestStoryActionRoutesUseMethodAwarePolicies(t *testing.T) {
	tests := map[string]struct {
		method    string
		path      string
		name      string
		authMode  RouteAuthMode
		rateLimit int
	}{
		"create story": {
			method:    "POST",
			path:      "/api/v1/stories",
			name:      "stories-create",
			authMode:  RouteAuthAuthenticated,
			rateLimit: 10,
		},
		"create post": {
			method:    "POST",
			path:      "/api/v1/posts",
			name:      "posts-create",
			authMode:  RouteAuthAuthenticated,
			rateLimit: 10,
		},
		"autosave post": {
			method:    "POST",
			path:      "/api/v1/posts/story-1/autosave",
			name:      "posts-autosave",
			authMode:  RouteAuthAuthenticated,
			rateLimit: 60,
		},
		"list post comments": {
			method:    "GET",
			path:      "/api/v1/posts/post-1/comments?limit=20&offset=0",
			name:      "posts-comments",
			authMode:  RouteAuthPublic,
			rateLimit: 20,
		},
		"mark story seen": {
			method:    "POST",
			path:      "/api/v1/stories/story-1/seen",
			name:      "stories-seen",
			authMode:  RouteAuthAuthenticated,
			rateLimit: 60,
		},
		"like story": {
			method:    "POST",
			path:      "/api/v1/stories/story-1/likes",
			name:      "stories-likes",
			authMode:  RouteAuthAuthenticated,
			rateLimit: 60,
		},
		"list my archived stories": {
			method:    "GET",
			path:      "/api/v1/stories/mine/archive?limit=20&offset=0",
			name:      "stories-mine-archive",
			authMode:  RouteAuthAuthenticated,
			rateLimit: 120,
		},
		"list my active stories": {
			method:    "GET",
			path:      "/api/v1/stories/mine/active?limit=20&offset=0",
			name:      "stories-mine-active",
			authMode:  RouteAuthAuthenticated,
			rateLimit: 120,
		},
		"follow community": {
			method:    "POST",
			path:      "/api/v1/communities/community-1/follow",
			name:      "communities-follow",
			authMode:  RouteAuthAuthenticated,
			rateLimit: 60,
		},
		"unfollow community": {
			method:    "DELETE",
			path:      "/api/v1/communities/community-1/follow",
			name:      "communities-follow",
			authMode:  RouteAuthAuthenticated,
			rateLimit: 60,
		},
		"report community": {
			method:    "POST",
			path:      "/api/v1/communities/community-1/report",
			name:      "communities-report",
			authMode:  RouteAuthAuthenticated,
			rateLimit: 60,
		},
		"mute community": {
			method:    "POST",
			path:      "/api/v1/communities/community-1/mute",
			name:      "communities-mute",
			authMode:  RouteAuthAuthenticated,
			rateLimit: 60,
		},
		"unmute community": {
			method:    "DELETE",
			path:      "/api/v1/communities/community-1/mute",
			name:      "communities-mute",
			authMode:  RouteAuthAuthenticated,
			rateLimit: 60,
		},
	}

	for name, tc := range tests {
		t.Run(name, func(t *testing.T) {
			policy := matchRoutePolicyForMethod(tc.method, tc.path, "/api/v1")
			if policy == nil {
				t.Fatal("expected route policy")
			}
			if policy.Name != tc.name {
				t.Fatalf("name = %q, want %q", policy.Name, tc.name)
			}
			if policy.AuthMode != tc.authMode {
				t.Fatalf("auth mode = %q, want %q", policy.AuthMode, tc.authMode)
			}
			assertRouteLimit(t, policy, tc.rateLimit)
		})
	}
}

func TestCommunityModerationRouteRequiresAuthentication(t *testing.T) {
	policy := matchRoutePolicyForMethod("POST", "/api/v1/communities/community-1/moderation/posts/post-1/approve", "/api/v1")
	if policy == nil {
		t.Fatal("expected community moderation route policy")
	}
	if policy.Upstream != "feed" {
		t.Fatalf("upstream = %q, want stories", policy.Upstream)
	}
	if policy.AuthMode != RouteAuthAuthenticated {
		t.Fatalf("auth mode = %q, want authenticated", policy.AuthMode)
	}
	if policy.RewritePrefix != "/v1/communities" {
		t.Fatalf("rewrite prefix = %q, want /v1/communities", policy.RewritePrefix)
	}
	assertRouteLimit(t, policy, 30)
}

func TestCommunityMemberRoleRouteRequiresAuthentication(t *testing.T) {
	policy := matchRoutePolicyForMethod("PATCH", "/api/v1/communities/community-1/members/user-1/role", "/api/v1")
	if policy == nil {
		t.Fatal("expected community member role route policy")
	}
	if policy.Upstream != "feed" {
		t.Fatalf("upstream = %q, want stories", policy.Upstream)
	}
	if policy.AuthMode != RouteAuthAuthenticated {
		t.Fatalf("auth mode = %q, want authenticated", policy.AuthMode)
	}
	if policy.RewritePrefix != "/v1/communities" {
		t.Fatalf("rewrite prefix = %q, want /v1/communities", policy.RewritePrefix)
	}
	assertRouteLimit(t, policy, 30)
}

func TestCommunityMembersRouteRequiresAuthentication(t *testing.T) {
	policy := matchRoutePolicyForMethod("GET", "/api/v1/communities/community-1/members", "/api/v1")
	if policy == nil {
		t.Fatal("expected community members route policy")
	}
	if policy.Upstream != "feed" {
		t.Fatalf("upstream = %q, want stories", policy.Upstream)
	}
	if policy.AuthMode != RouteAuthAuthenticated {
		t.Fatalf("auth mode = %q, want authenticated", policy.AuthMode)
	}
	if policy.RewritePrefix != "/v1/communities" {
		t.Fatalf("rewrite prefix = %q, want /v1/communities", policy.RewritePrefix)
	}
	assertRouteLimit(t, policy, 30)
}

func assertRouteLimit(t *testing.T, policy *RoutePolicy, want int) {
	t.Helper()
	if policy.RateLimitPerMinute == nil {
		t.Fatalf("%s rate limit is nil, want %d", policy.Name, want)
	}
	if *policy.RateLimitPerMinute != want {
		t.Fatalf("%s rate limit = %d, want %d", policy.Name, *policy.RateLimitPerMinute, want)
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

func TestActivityReviewRoutesProxyToActivityService(t *testing.T) {
	publicReviewPolicy := matchRoutePolicy("/api/v1/activity-reviews?hostUserId=user-1", "/api/v1")
	if publicReviewPolicy == nil {
		t.Fatal("expected activity reviews route policy")
	}
	if publicReviewPolicy.Upstream != "activity" {
		t.Fatalf("activity review upstream = %q, want activity", publicReviewPolicy.Upstream)
	}
	if publicReviewPolicy.AuthMode != RouteAuthPublic {
		t.Fatalf("activity review auth mode = %q, want public", publicReviewPolicy.AuthMode)
	}
	if publicReviewPolicy.RewritePrefix != "/v1/activity-reviews" {
		t.Fatalf("activity review rewrite prefix = %q, want /v1/activity-reviews", publicReviewPolicy.RewritePrefix)
	}

	publicOrganizerReviewPolicy := matchRoutePolicy("/api/v1/activity-organizer-reviews?hostUserId=user-1", "/api/v1")
	if publicOrganizerReviewPolicy == nil {
		t.Fatal("expected activity organizer reviews route policy")
	}
	if publicOrganizerReviewPolicy.Upstream != "activity" {
		t.Fatalf("activity organizer review upstream = %q, want activity", publicOrganizerReviewPolicy.Upstream)
	}
	if publicOrganizerReviewPolicy.AuthMode != RouteAuthPublic {
		t.Fatalf("activity organizer review auth mode = %q, want public", publicOrganizerReviewPolicy.AuthMode)
	}
	if publicOrganizerReviewPolicy.RewritePrefix != "/v1/activity-organizer-reviews" {
		t.Fatalf("activity organizer review rewrite prefix = %q, want /v1/activity-organizer-reviews", publicOrganizerReviewPolicy.RewritePrefix)
	}

	myReviewPolicy := matchRoutePolicy("/api/v1/me/activities/activity-1/reviews", "/api/v1")
	if myReviewPolicy == nil {
		t.Fatal("expected my activity reviews route policy")
	}
	if myReviewPolicy.Upstream != "activity" {
		t.Fatalf("my activity review upstream = %q, want activity", myReviewPolicy.Upstream)
	}
	if myReviewPolicy.AuthMode != RouteAuthAuthenticated {
		t.Fatalf("my activity review auth mode = %q, want authenticated", myReviewPolicy.AuthMode)
	}
	if myReviewPolicy.RewritePrefix != "/v1/me/activities" {
		t.Fatalf("my activity review rewrite prefix = %q, want /v1/me/activities", myReviewPolicy.RewritePrefix)
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

func TestPublicGuideByUserRouteDoesNotRequireBearerToken(t *testing.T) {
	policy := matchRoutePolicy("/api/v1/guides/public/by-user/user-1", "/api/v1")
	if policy == nil {
		t.Fatal("expected public guide by user route policy")
	}
	if policy.Upstream != "guide" {
		t.Fatalf("upstream = %q, want guide", policy.Upstream)
	}
	if policy.AuthMode != RouteAuthPublic {
		t.Fatalf("auth mode = %q, want public", policy.AuthMode)
	}
	if policy.RewritePrefix != "/v1/guides/public/by-user" {
		t.Fatalf("rewrite prefix = %q, want /v1/guides/public/by-user", policy.RewritePrefix)
	}
}

func TestPublicGuideFilterOptionsRouteDoesNotRequireBearerToken(t *testing.T) {
	policy := matchRoutePolicy("/api/v1/guides/public/filter-options", "/api/v1")
	if policy == nil {
		t.Fatal("expected public guide filter options route policy")
	}
	if policy.Upstream != "guide" {
		t.Fatalf("upstream = %q, want guide", policy.Upstream)
	}
	if policy.AuthMode != RouteAuthPublic {
		t.Fatalf("auth mode = %q, want public", policy.AuthMode)
	}
	if policy.RewritePrefix != "/v1/guides/public/filter-options" {
		t.Fatalf("rewrite prefix = %q, want /v1/guides/public/filter-options", policy.RewritePrefix)
	}
}

func TestPublicUserProfileRouteDoesNotRequireBearerToken(t *testing.T) {
	policy := matchRoutePolicy("/api/v1/public/users/user-1", "/api/v1")
	if policy == nil {
		t.Fatal("expected public user route policy")
	}
	if policy.Upstream != "user" {
		t.Fatalf("upstream = %q, want user", policy.Upstream)
	}
	if policy.AuthMode != RouteAuthPublic {
		t.Fatalf("auth mode = %q, want public", policy.AuthMode)
	}
	if policy.RewritePrefix != "/v1/public/users" {
		t.Fatalf("rewrite prefix = %q, want /v1/public/users", policy.RewritePrefix)
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
