package http

import (
	"net/http"
	"strings"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/payment-service/internal/config"
)

func Chain(cfg *config.Config, next http.Handler) http.Handler {
	return withRequestContext(cfg, withPaymentAuth(cfg, next))
}

func withRequestContext(cfg *config.Config, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ctx := r.Context()
		if requestID := strings.TrimSpace(r.Header.Get(cfg.Security.RequestIDHeader)); requestID != "" {
			ctx = withContextValue(ctx, contextKeyRequestID, requestID)
		}
		if userID := strings.TrimSpace(r.Header.Get(cfg.Security.TrustedGatewayHeaderUserID)); userID != "" {
			ctx = withContextValue(ctx, contextKeyUserID, userID)
		}
		if subject := strings.TrimSpace(r.Header.Get(cfg.Security.TrustedGatewayHeaderSub)); subject != "" {
			ctx = withContextValue(ctx, contextKeySubject, subject)
		}
		if roles := strings.TrimSpace(r.Header.Get(cfg.Security.TrustedGatewayHeaderRoles)); roles != "" {
			ctx = withContextValue(ctx, contextKeyRoles, roles)
		}
		if isInternalRequest(cfg, r) {
			ctx = withContextValue(ctx, contextKeyInternal, true)
		}
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func withPaymentAuth(cfg *config.Config, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodOptions || !strings.HasPrefix(r.URL.Path, "/v1/payments") {
			next.ServeHTTP(w, r)
			return
		}

		requiresAuth := cfg.Security.RequireAuthenticatedRequests ||
			(cfg.Security.RequireAuthenticatedWrites && r.Method != http.MethodGet && r.Method != http.MethodHead)
		if !requiresAuth {
			next.ServeHTTP(w, r)
			return
		}
		if isInternalRequest(cfg, r) {
			next.ServeHTTP(w, r)
			return
		}

		userID := strings.TrimSpace(r.Header.Get(cfg.Security.TrustedGatewayHeaderUserID))
		if _, err := uuid.Parse(userID); err != nil {
			writeError(w, http.StatusUnauthorized, "missing authenticated user")
			return
		}

		next.ServeHTTP(w, r)
	})
}

func isInternalRequest(cfg *config.Config, r *http.Request) bool {
	token := strings.TrimSpace(cfg.Security.InternalServiceToken)
	if token == "" {
		return false
	}
	authHeader := strings.TrimSpace(r.Header.Get("Authorization"))
	return authHeader == "Bearer "+token
}
