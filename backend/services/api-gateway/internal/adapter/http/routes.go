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
	Prefix             string
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
	storiesLimit := 180
	attractionLimit := 180
	chatLimit := 300
	paymentLimit := 180
	stickerLimit := 180
	excursionLimit := 180

	return []RoutePolicy{
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
			Name:               "public-guides",
			Prefix:             apiPrefix + "/guides/public",
			AuthMode:           RouteAuthPublic,
			Upstream:           "guide",
			RateLimitPerMinute: &guideLimit,
			RewritePrefix:      "/v1/guides/public",
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
			Name:               "public-stories",
			Prefix:             apiPrefix + "/public/stories/",
			AuthMode:           RouteAuthPublic,
			Upstream:           "stories",
			RateLimitPerMinute: &storiesLimit,
			RewritePrefix:      "/v1/public/stories/",
		},
		{
			Name:               "stories",
			Prefix:             apiPrefix + "/stories",
			AuthMode:           RouteAuthPublic,
			Upstream:           "stories",
			RateLimitPerMinute: &storiesLimit,
			RewritePrefix:      "/v1/stories",
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
			Name:          "chat-ws",
			Prefix:        apiPrefix + "/chat/ws",
			AuthMode:      RouteAuthAuthenticated,
			Upstream:      "chat",
			RewritePrefix: "/v1/ws",
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
			Name:               "attraction-reviews",
			Prefix:             apiPrefix + "/attractions/",
			AuthMode:           RouteAuthPublic,
			Upstream:           "attraction",
			RateLimitPerMinute: &attractionLimit,
			RewritePrefix:      "/v1/attractions/",
		},
		{
			Name:               "attractions",
			Prefix:             apiPrefix + "/attractions",
			AuthMode:           RouteAuthPublic,
			Upstream:           "attraction",
			RateLimitPerMinute: &attractionLimit,
			RewritePrefix:      "/v1/attractions",
		},
		{
			Name:               "reviews-delete",
			Prefix:             apiPrefix + "/reviews/",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "attraction",
			RateLimitPerMinute: &attractionLimit,
			RewritePrefix:      "/v1/reviews/",
		},
	}
}

func matchRoutePolicy(path string, apiPrefix string) *RoutePolicy {
	for _, policy := range routePolicies(apiPrefix) {
		if strings.HasPrefix(path, policy.Prefix) {
			p := policy
			return &p
		}
	}
	return nil
}
