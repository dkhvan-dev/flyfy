package http

import "strings"

type RouteAuthMode string

const (
	RouteAuthPublic        RouteAuthMode = "PUBLIC"
	RouteAuthAuthenticated RouteAuthMode = "AUTHENTICATED"
	RouteAuthRoleBased     RouteAuthMode = "ROLE_BASED"
)

type RoutePolicy struct {
	Name               string
	Method             string
	Prefix             string
	ExactPath          string
	PathContains       string
	PathSuffix         string
	AuthMode           RouteAuthMode
	RequiredRoles      []string
	Upstream           string
	RateLimitPerMinute *int
	RewritePrefix      string
	Cacheable          bool
}

func routePolicies(apiPrefix string) []RoutePolicy {
	apiPrefix = strings.TrimRight(strings.TrimSpace(apiPrefix), "/")
	if apiPrefix == "" {
		apiPrefix = "/api/v1"
	}

	adminLimit := 60
	authLimit := 300
	filesLimit := 180
	activityLimit := 180
	guideLimit := 180
	storiesReadLimit := 120
	storyCreateLimit := 10
	storyAutosaveLimit := 60
	storyActionLimit := 60
	trustAppealLimit := 10
	storyCommentLimit := 20
	communityAdminLimit := 30
	placeLimit := 180
	chatLimit := 300
	paymentLimit := 180
	stickerLimit := 180
	excursionLimit := 180
	notificationLimit := 300
	currencyLimit := 180

	return []RoutePolicy{
		{
			Name:               "admin-panel",
			Prefix:             "/admin",
			AuthMode:           RouteAuthPublic,
			Upstream:           "admin-panel",
			RateLimitPerMinute: &adminLimit,
			RewritePrefix:      "/admin",
		},
		{
			Name:               "auth",
			Prefix:             apiPrefix + "/auth/",
			AuthMode:           RouteAuthPublic,
			Upstream:           "auth",
			RateLimitPerMinute: &authLimit,
			RewritePrefix:      "/api/v1/auth/",
		},
		{
			Name:          "users",
			Prefix:        apiPrefix + "/users/",
			AuthMode:      RouteAuthAuthenticated,
			Upstream:      "user",
			RewritePrefix: "/v1/users/",
		},
		{
			Name:          "public-users",
			Prefix:        apiPrefix + "/public/users",
			AuthMode:      RouteAuthPublic,
			Upstream:      "user",
			RewritePrefix: "/v1/public/users",
		},
		{
			Name:               "public-files",
			Prefix:             apiPrefix + "/public/files/",
			AuthMode:           RouteAuthPublic,
			Upstream:           "file-manager",
			RateLimitPerMinute: &filesLimit,
			RewritePrefix:      "/v1/public/files/",
		},
		{
			Name:               "public-guide-by-user",
			Prefix:             apiPrefix + "/guides/public/by-user",
			AuthMode:           RouteAuthPublic,
			Upstream:           "guide",
			RateLimitPerMinute: &guideLimit,
			RewritePrefix:      "/v1/guides/public/by-user",
		},
		{
			Name:               "public-guide-filter-options",
			Prefix:             apiPrefix + "/guides/public/filter-options",
			AuthMode:           RouteAuthPublic,
			Upstream:           "guide",
			RateLimitPerMinute: &guideLimit,
			RewritePrefix:      "/v1/guides/public/filter-options",
		},
		{
			Name:               "public-guides",
			Prefix:             apiPrefix + "/guides/public",
			AuthMode:           RouteAuthPublic,
			Upstream:           "guide",
			RateLimitPerMinute: &guideLimit,
			RewritePrefix:      "/v1/guides/public",
		},
		{
			Name:               "guide-excursion-languages",
			Prefix:             apiPrefix + "/guides/excursion-languages",
			AuthMode:           RouteAuthPublic,
			Upstream:           "excursion",
			RateLimitPerMinute: &excursionLimit,
			RewritePrefix:      "/v1/guides/excursion-languages",
		},
		{
			Name:          "guides",
			Prefix:        apiPrefix + "/guides/",
			AuthMode:      RouteAuthAuthenticated,
			Upstream:      "guide",
			RewritePrefix: "/v1/guides/",
		},
		{
			Name:               "admin-guides",
			Prefix:             apiPrefix + "/admin/guides/",
			AuthMode:           RouteAuthRoleBased,
			RequiredRoles:      []string{"ADMIN", "MODERATOR"},
			Upstream:           "guide",
			RateLimitPerMinute: &adminLimit,
			RewritePrefix:      "/v1/admin/guides/",
		},
		{
			Name:               "files",
			Prefix:             apiPrefix + "/files/",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "file-manager",
			RateLimitPerMinute: &filesLimit,
			RewritePrefix:      "/v1/files/",
		},
		{
			Name:               "my-activities",
			Prefix:             apiPrefix + "/me/activities",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "activity",
			RateLimitPerMinute: &activityLimit,
			RewritePrefix:      "/v1/me/activities",
		},
		{
			Name:               "my-attendance",
			Prefix:             apiPrefix + "/me/attendance",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "activity",
			RateLimitPerMinute: &activityLimit,
			RewritePrefix:      "/v1/me/attendance",
		},
		{
			Name:               "activity-categories",
			Prefix:             apiPrefix + "/activity-categories",
			AuthMode:           RouteAuthPublic,
			Upstream:           "activity",
			RateLimitPerMinute: &activityLimit,
			RewritePrefix:      "/v1/activity-categories",
		},
		{
			Name:               "activity-reviews",
			Prefix:             apiPrefix + "/activity-reviews",
			AuthMode:           RouteAuthPublic,
			Upstream:           "activity",
			RateLimitPerMinute: &activityLimit,
			RewritePrefix:      "/v1/activity-reviews",
		},
		{
			Name:               "activity-organizer-reviews",
			Prefix:             apiPrefix + "/activity-organizer-reviews",
			AuthMode:           RouteAuthPublic,
			Upstream:           "activity",
			RateLimitPerMinute: &activityLimit,
			RewritePrefix:      "/v1/activity-organizer-reviews",
		},
		{
			Name:               "activities",
			Prefix:             apiPrefix + "/activities",
			AuthMode:           RouteAuthPublic,
			Upstream:           "activity",
			RateLimitPerMinute: &activityLimit,
			RewritePrefix:      "/v1/activities",
		},
		{
			Name:               "my-excursion-bookings",
			Prefix:             apiPrefix + "/me/excursion-bookings",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "excursion",
			RateLimitPerMinute: &excursionLimit,
			RewritePrefix:      "/v1/me/excursion-bookings",
		},
		{
			Name:               "my-guide-excursion-bookings",
			Prefix:             apiPrefix + "/me/guide-excursion-bookings",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "excursion",
			RateLimitPerMinute: &excursionLimit,
			RewritePrefix:      "/v1/me/guide-excursion-bookings",
		},
		{
			Name:               "my-excursion-schedule",
			Prefix:             apiPrefix + "/me/excursion-schedule",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "excursion",
			RateLimitPerMinute: &excursionLimit,
			RewritePrefix:      "/v1/me/excursion-schedule",
		},
		{
			Name:               "my-excursions",
			Prefix:             apiPrefix + "/me/excursions",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "excursion",
			RateLimitPerMinute: &excursionLimit,
			RewritePrefix:      "/v1/me/excursions",
		},
		{
			Name:               "excursion-products",
			Prefix:             apiPrefix + "/excursion-products",
			AuthMode:           RouteAuthPublic,
			Upstream:           "excursion",
			RateLimitPerMinute: &excursionLimit,
			RewritePrefix:      "/v1/excursion-products",
		},
		{
			Name:               "public-guide-excursion-schedule",
			Prefix:             apiPrefix + "/excursion-guides",
			AuthMode:           RouteAuthPublic,
			Upstream:           "excursion",
			RateLimitPerMinute: &excursionLimit,
			RewritePrefix:      "/v1/excursion-guides",
		},
		{
			Name:               "excursion-reviews",
			Prefix:             apiPrefix + "/excursion-reviews",
			AuthMode:           RouteAuthPublic,
			Upstream:           "excursion",
			RateLimitPerMinute: &excursionLimit,
			RewritePrefix:      "/v1/excursion-reviews",
		},
		{
			Name:               "guide-reviews",
			Prefix:             apiPrefix + "/guide-reviews",
			AuthMode:           RouteAuthPublic,
			Upstream:           "excursion",
			RateLimitPerMinute: &excursionLimit,
			RewritePrefix:      "/v1/guide-reviews",
		},
		{
			Name:               "excursions",
			Prefix:             apiPrefix + "/excursions",
			AuthMode:           RouteAuthPublic,
			Upstream:           "excursion",
			RateLimitPerMinute: &excursionLimit,
			RewritePrefix:      "/v1/excursions",
		},
		{
			Name:               "payments",
			Prefix:             apiPrefix + "/payments",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "payment",
			RateLimitPerMinute: &paymentLimit,
			RewritePrefix:      "/v1/payments",
		},
		{
			Name:               "default-sticker-packs",
			Prefix:             apiPrefix + "/sticker-packs/default",
			AuthMode:           RouteAuthPublic,
			Upstream:           "sticker",
			RateLimitPerMinute: &stickerLimit,
			RewritePrefix:      "/v1/sticker-packs/default",
			Cacheable:          true,
		},
		{
			Name:               "stickers",
			Prefix:             apiPrefix + "/stickers",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "sticker",
			RateLimitPerMinute: &stickerLimit,
			RewritePrefix:      "/v1/stickers",
		},
		{
			Name:               "sticker-packs",
			Prefix:             apiPrefix + "/sticker-packs",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "sticker",
			RateLimitPerMinute: &stickerLimit,
			RewritePrefix:      "/v1/sticker-packs",
		},
		{
			Name:               "public-posts",
			Prefix:             apiPrefix + "/public/posts/",
			AuthMode:           RouteAuthPublic,
			Upstream:           "feed",
			RateLimitPerMinute: &storiesReadLimit,
			RewritePrefix:      "/v1/public/posts/",
		},
		{
			Name:               "posts-autosave",
			Method:             "POST",
			Prefix:             apiPrefix + "/posts/",
			PathSuffix:         "/autosave",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "feed",
			RateLimitPerMinute: &storyAutosaveLimit,
			RewritePrefix:      "/v1/posts/",
		},
		{
			Name:               "posts-likes",
			Method:             "POST",
			Prefix:             apiPrefix + "/posts/",
			PathSuffix:         "/likes",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "feed",
			RateLimitPerMinute: &storyActionLimit,
			RewritePrefix:      "/v1/posts/",
		},
		{
			Name:               "posts-likes",
			Method:             "DELETE",
			Prefix:             apiPrefix + "/posts/",
			PathSuffix:         "/likes",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "feed",
			RateLimitPerMinute: &storyActionLimit,
			RewritePrefix:      "/v1/posts/",
		},
		{
			Name:               "posts-comments",
			Method:             "GET",
			Prefix:             apiPrefix + "/posts/",
			PathSuffix:         "/comments",
			AuthMode:           RouteAuthPublic,
			Upstream:           "feed",
			RateLimitPerMinute: &storyCommentLimit,
			RewritePrefix:      "/v1/posts/",
		},
		{
			Name:               "posts-comments",
			Method:             "POST",
			Prefix:             apiPrefix + "/posts/",
			PathSuffix:         "/comments",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "feed",
			RateLimitPerMinute: &storyCommentLimit,
			RewritePrefix:      "/v1/posts/",
		},
		{
			Name:               "posts-share",
			Method:             "POST",
			Prefix:             apiPrefix + "/posts/",
			PathSuffix:         "/share",
			AuthMode:           RouteAuthPublic,
			Upstream:           "feed",
			RateLimitPerMinute: &storyActionLimit,
			RewritePrefix:      "/v1/posts/",
		},
		{
			Name:               "posts-views",
			Method:             "POST",
			Prefix:             apiPrefix + "/posts/",
			PathSuffix:         "/views",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "feed",
			RateLimitPerMinute: &storyActionLimit,
			RewritePrefix:      "/v1/posts/",
		},
		{
			Name:               "posts-create",
			Method:             "POST",
			Prefix:             apiPrefix + "/posts",
			ExactPath:          apiPrefix + "/posts",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "feed",
			RateLimitPerMinute: &storyCreateLimit,
			RewritePrefix:      "/v1/posts",
		},
		{
			Name:               "posts",
			Prefix:             apiPrefix + "/posts",
			AuthMode:           RouteAuthPublic,
			Upstream:           "feed",
			RateLimitPerMinute: &storiesReadLimit,
			RewritePrefix:      "/v1/posts",
		},
		{
			Name:               "stories-seen",
			Method:             "POST",
			Prefix:             apiPrefix + "/stories/",
			PathSuffix:         "/seen",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "feed",
			RateLimitPerMinute: &storyActionLimit,
			RewritePrefix:      "/v1/stories/",
		},
		{
			Name:               "stories-likes",
			Method:             "POST",
			Prefix:             apiPrefix + "/stories/",
			PathSuffix:         "/likes",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "feed",
			RateLimitPerMinute: &storyActionLimit,
			RewritePrefix:      "/v1/stories/",
		},
		{
			Name:               "stories-mine-active",
			Method:             "GET",
			Prefix:             apiPrefix + "/stories/mine/active",
			ExactPath:          apiPrefix + "/stories/mine/active",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "feed",
			RateLimitPerMinute: &storiesReadLimit,
			RewritePrefix:      "/v1/stories/mine/active",
		},
		{
			Name:               "stories-mine-archive",
			Method:             "GET",
			Prefix:             apiPrefix + "/stories/mine/archive",
			ExactPath:          apiPrefix + "/stories/mine/archive",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "feed",
			RateLimitPerMinute: &storiesReadLimit,
			RewritePrefix:      "/v1/stories/mine/archive",
		},
		{
			Name:               "stories-create",
			Method:             "POST",
			Prefix:             apiPrefix + "/stories",
			ExactPath:          apiPrefix + "/stories",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "feed",
			RateLimitPerMinute: &storyCreateLimit,
			RewritePrefix:      "/v1/stories",
		},
		{
			Name:               "content-feed-events",
			Method:             "POST",
			Prefix:             apiPrefix + "/feed/events",
			ExactPath:          apiPrefix + "/feed/events",
			AuthMode:           RouteAuthPublic,
			Upstream:           "feed",
			RateLimitPerMinute: &storyActionLimit,
			RewritePrefix:      "/v1/feed/events",
		},
		{
			Name:               "content-feed",
			Prefix:             apiPrefix + "/feed",
			AuthMode:           RouteAuthPublic,
			Upstream:           "feed",
			RateLimitPerMinute: &storiesReadLimit,
			RewritePrefix:      "/v1/feed",
		},
		{
			Name:               "trust-profile",
			Method:             "GET",
			Prefix:             apiPrefix + "/trust/profile",
			ExactPath:          apiPrefix + "/trust/profile",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "trust",
			RateLimitPerMinute: &storyActionLimit,
		},
		{
			Name:               "trust-appeals-list",
			Method:             "GET",
			Prefix:             apiPrefix + "/trust/appeals",
			ExactPath:          apiPrefix + "/trust/appeals",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "trust",
			RateLimitPerMinute: &storyActionLimit,
		},
		{
			Name:               "trust-appeals-submit",
			Method:             "POST",
			Prefix:             apiPrefix + "/trust/restrictions/",
			PathSuffix:         "/appeals",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "trust",
			RateLimitPerMinute: &trustAppealLimit,
		},
		{
			Name:               "community-moderation",
			Prefix:             apiPrefix + "/communities",
			PathContains:       "/moderation/posts",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "feed",
			RateLimitPerMinute: &communityAdminLimit,
			RewritePrefix:      "/v1/communities",
		},
		{
			Name:               "community-members",
			Prefix:             apiPrefix + "/communities",
			PathContains:       "/members",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "feed",
			RateLimitPerMinute: &communityAdminLimit,
			RewritePrefix:      "/v1/communities",
		},
		{
			Name:               "communities-follow",
			Method:             "POST",
			Prefix:             apiPrefix + "/communities/",
			PathSuffix:         "/follow",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "feed",
			RateLimitPerMinute: &storyActionLimit,
			RewritePrefix:      "/v1/communities/",
		},
		{
			Name:               "communities-follow",
			Method:             "DELETE",
			Prefix:             apiPrefix + "/communities/",
			PathSuffix:         "/follow",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "feed",
			RateLimitPerMinute: &storyActionLimit,
			RewritePrefix:      "/v1/communities/",
		},
		{
			Name:               "communities-report",
			Method:             "POST",
			Prefix:             apiPrefix + "/communities/",
			PathSuffix:         "/report",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "feed",
			RateLimitPerMinute: &storyActionLimit,
			RewritePrefix:      "/v1/communities/",
		},
		{
			Name:               "communities-mute",
			Method:             "POST",
			Prefix:             apiPrefix + "/communities/",
			PathSuffix:         "/mute",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "feed",
			RateLimitPerMinute: &storyActionLimit,
			RewritePrefix:      "/v1/communities/",
		},
		{
			Name:               "communities-mute",
			Method:             "DELETE",
			Prefix:             apiPrefix + "/communities/",
			PathSuffix:         "/mute",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "feed",
			RateLimitPerMinute: &storyActionLimit,
			RewritePrefix:      "/v1/communities/",
		},
		{
			Name:               "communities",
			Prefix:             apiPrefix + "/communities",
			AuthMode:           RouteAuthPublic,
			Upstream:           "feed",
			RateLimitPerMinute: &storiesReadLimit,
			RewritePrefix:      "/v1/communities",
		},
		{
			Name:               "chat-conversations",
			Prefix:             apiPrefix + "/chat/conversations",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "chat",
			RateLimitPerMinute: &chatLimit,
			RewritePrefix:      "/v1/conversations",
		},
		{
			Name:               "chat-users",
			Prefix:             apiPrefix + "/chat/users",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "chat",
			RateLimitPerMinute: &chatLimit,
			RewritePrefix:      "/v1/users",
		},
		{
			Name:          "chat-ws",
			Prefix:        apiPrefix + "/chat/ws",
			AuthMode:      RouteAuthAuthenticated,
			Upstream:      "chat",
			RewritePrefix: "/v1/ws",
		},
		{
			Name:               "notifications",
			Prefix:             apiPrefix + "/notifications",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "notification",
			RateLimitPerMinute: &notificationLimit,
			RewritePrefix:      "/v1/notifications",
		},
		{
			Name:          "reference-countries",
			Prefix:        apiPrefix + "/reference/countries",
			AuthMode:      RouteAuthPublic,
			Upstream:      "reference",
			RewritePrefix: "/v1/countries",
			Cacheable:     true,
		},
		{
			Name:          "reference-cities",
			Prefix:        apiPrefix + "/reference/cities",
			AuthMode:      RouteAuthPublic,
			Upstream:      "reference",
			RewritePrefix: "/v1/cities",
			Cacheable:     true,
		},
		{
			Name:          "reference-currencies",
			Prefix:        apiPrefix + "/reference/currencies",
			AuthMode:      RouteAuthPublic,
			Upstream:      "reference",
			RewritePrefix: "/v1/currencies",
			Cacheable:     true,
		},
		{
			Name:          "reference-timezones",
			Prefix:        apiPrefix + "/reference/timezones",
			AuthMode:      RouteAuthPublic,
			Upstream:      "reference",
			RewritePrefix: "/v1/timezones",
			Cacheable:     true,
		},
		{
			Name:               "currency",
			Prefix:             apiPrefix + "/currency",
			AuthMode:           RouteAuthPublic,
			Upstream:           "currency",
			RateLimitPerMinute: &currencyLimit,
			RewritePrefix:      "/v1/currency",
		},
		{
			Name:               "exchange-rates",
			Prefix:             apiPrefix + "/exchange-rates",
			AuthMode:           RouteAuthPublic,
			Upstream:           "currency",
			RateLimitPerMinute: &currencyLimit,
			RewritePrefix:      "/v1/exchange-rates",
		},
		{
			Name:               "place-reviews",
			Prefix:             apiPrefix + "/places/",
			AuthMode:           RouteAuthPublic,
			Upstream:           "place",
			RateLimitPerMinute: &placeLimit,
			RewritePrefix:      "/v1/places/",
		},
		{
			Name:               "places",
			Prefix:             apiPrefix + "/places",
			AuthMode:           RouteAuthPublic,
			Upstream:           "place",
			RateLimitPerMinute: &placeLimit,
			RewritePrefix:      "/v1/places",
		},
		{
			Name:               "reviews-delete",
			Prefix:             apiPrefix + "/reviews/",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "place",
			RateLimitPerMinute: &placeLimit,
			RewritePrefix:      "/v1/reviews/",
		},
	}
}

func matchRoutePolicy(path string, apiPrefix string) *RoutePolicy {
	return matchRoutePolicyForMethod("", path, apiPrefix)
}

func matchRoutePolicyForMethod(method string, path string, apiPrefix string) *RoutePolicy {
	for _, policy := range routePolicies(apiPrefix) {
		if pathMatchesPolicy(method, path, policy) {
			p := policy
			return &p
		}
	}
	return nil
}

func pathMatchesPolicy(method string, path string, policy RoutePolicy) bool {
	if policy.Method != "" && method != "" && !strings.EqualFold(method, policy.Method) {
		return false
	}
	cleanPath := strings.SplitN(path, "?", 2)[0]
	if policy.ExactPath != "" && cleanPath != policy.ExactPath {
		return false
	}
	if !pathMatchesPolicyPrefix(path, policy.Prefix) {
		return false
	}
	if policy.PathContains != "" && !strings.Contains(cleanPath, policy.PathContains) {
		return false
	}
	if policy.PathSuffix != "" && !strings.HasSuffix(cleanPath, policy.PathSuffix) {
		return false
	}
	return true
}

func pathMatchesPolicyPrefix(path string, prefix string) bool {
	path = strings.SplitN(path, "?", 2)[0]
	if path == prefix {
		return true
	}
	if strings.HasSuffix(prefix, "/") {
		return strings.HasPrefix(path, prefix)
	}
	return strings.HasPrefix(path, prefix+"/")
}
