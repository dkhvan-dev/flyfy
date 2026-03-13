package adapter

import (
	"strings"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func NormalizeRoles(roles []string, singleRole string) []string {
	seen := make(map[string]struct{})
	result := make([]string, 0, len(roles)+1)

	appendRole := func(role string) {
		role = strings.ToUpper(strings.TrimSpace(role))
		if role == "" {
			return
		}
		if _, ok := seen[role]; ok {
			return
		}
		seen[role] = struct{}{}
		result = append(result, role)
	}

	for _, role := range roles {
		appendRole(role)
	}
	appendRole(singleRole)

	return result
}

func ValueOrEmpty(v string) string {
	return strings.TrimSpace(v)
}

func IsAuthFailure(err error) bool {
	st, ok := status.FromError(err)
	if !ok {
		return false
	}

	return st.Code() == codes.Unauthenticated || st.Code() == codes.PermissionDenied
}
