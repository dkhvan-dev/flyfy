package http

import (
	"net/http"
	"strings"
)

func IdentityMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ctx := r.Context()

		if userID := strings.TrimSpace(r.Header.Get("X-User-Id")); userID != "" {
			ctx = withUserID(ctx, userID)
		}
		if subject := strings.TrimSpace(r.Header.Get("X-Subject")); subject != "" {
			ctx = withSubject(ctx, subject)
		}
		if role := strings.TrimSpace(r.Header.Get("X-Role")); role != "" {
			ctx = withRole(ctx, role)
		}

		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func Chain(middlewares ...func(http.Handler) http.Handler) func(http.Handler) http.Handler {
	return func(final http.Handler) http.Handler {
		h := final
		for i := len(middlewares) - 1; i >= 0; i-- {
			h = middlewares[i](h)
		}
		return h
	}
}
