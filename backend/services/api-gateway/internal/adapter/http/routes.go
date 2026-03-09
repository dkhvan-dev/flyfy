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
}

func routePolicies(apiPrefix string) []RoutePolicy {
	apiPrefix = strings.TrimRight(strings.TrimSpace(apiPrefix), "/")
	if apiPrefix == "" {
		apiPrefix = "/api/v1"
	}

	adminLimit := 60
	authLimit := 300
	filesLimit := 180

	return []RoutePolicy{
		{
			Name:               "auth",
			Prefix:             apiPrefix + "/auth/",
			AuthMode:           RouteAuthPublic,
			Upstream:           "auth",
			RateLimitPerMinute: &authLimit,
		},
		{
			Name:     "users",
			Prefix:   apiPrefix + "/users/",
			AuthMode: RouteAuthAuthenticated,
			Upstream: "user",
		},
		{
			Name:     "public-users",
			Prefix:   apiPrefix + "/public/users",
			AuthMode: RouteAuthAuthenticated,
			Upstream: "user",
		},
		{
			Name:     "guides",
			Prefix:   apiPrefix + "/guides/",
			AuthMode: RouteAuthAuthenticated,
			Upstream: "guide",
		},
		{
			Name:               "admin-guides",
			Prefix:             apiPrefix + "/admin/guides/",
			AuthMode:           RouteAuthRoleBased,
			RequiredRoles:      []string{"ADMIN", "MODERATOR"},
			Upstream:           "guide",
			RateLimitPerMinute: &adminLimit,
		},
		{
			Name:               "files",
			Prefix:             apiPrefix + "/files/",
			AuthMode:           RouteAuthAuthenticated,
			Upstream:           "file-manager",
			RateLimitPerMinute: &filesLimit,
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
