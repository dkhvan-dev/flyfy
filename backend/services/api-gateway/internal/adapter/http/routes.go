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
