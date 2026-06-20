package http

import (
	"net/http"
	"strings"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"
)

type MiddlewareConfig struct {
	RequestIDHeader            string
	TrustedGatewayHeaderUserID string
	TrustedGatewayHeaderRoles  string
	TrustedGatewayHeaderSub    string
}

func Chain(cfg MiddlewareConfig, next http.Handler) http.Handler {
	return requestIDMiddleware(cfg,
		authContextMiddleware(cfg,
			auditLoggingMiddleware(next),
		),
	)
}

func requireOperationsRole(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if hasOperationsRole(RolesFromContext(r.Context())) {
			next.ServeHTTP(w, r)
			return
		}
		writeError(w, http.StatusForbidden, "forbidden")
	})
}

func requestIDMiddleware(cfg MiddlewareConfig, next http.Handler) http.Handler {
	headerName := valueOrDefault(cfg.RequestIDHeader, "X-Request-Id")
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requestID := strings.TrimSpace(r.Header.Get(headerName))
		if requestID == "" {
			requestID = uuid.NewString()
		}
		w.Header().Set(headerName, requestID)
		next.ServeHTTP(w, r.WithContext(withRequestID(r.Context(), requestID)))
	})
}

func authContextMiddleware(cfg MiddlewareConfig, next http.Handler) http.Handler {
	userIDHeader := valueOrDefault(cfg.TrustedGatewayHeaderUserID, "X-User-Id")
	rolesHeader := valueOrDefault(cfg.TrustedGatewayHeaderRoles, "X-User-Roles")
	subjectHeader := valueOrDefault(cfg.TrustedGatewayHeaderSub, "X-Auth-Subject")
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ctx := r.Context()
		if value := strings.TrimSpace(r.Header.Get(userIDHeader)); value != "" {
			ctx = withUserID(ctx, value)
		}
		if value := strings.TrimSpace(r.Header.Get(subjectHeader)); value != "" {
			ctx = withSubject(ctx, value)
		}
		if roles := splitCSV(r.Header.Get(rolesHeader)); len(roles) > 0 {
			ctx = withRoles(ctx, roles)
		}
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func auditLoggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		rw := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}
		next.ServeHTTP(rw, r)
		log.Info().
			Str("method", r.Method).
			Str("path", r.URL.Path).
			Int("status", rw.statusCode).
			Str("request_id", RequestIDFromContext(r.Context())).
			Msg("http request completed")
	})
}

type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (w *responseWriter) WriteHeader(statusCode int) {
	w.statusCode = statusCode
	w.ResponseWriter.WriteHeader(statusCode)
}

func splitCSV(raw string) []string {
	parts := strings.Split(raw, ",")
	result := make([]string, 0, len(parts))
	for _, part := range parts {
		value := strings.TrimSpace(part)
		if value != "" {
			result = append(result, value)
		}
	}
	return result
}

func hasOperationsRole(roles []string) bool {
	for _, role := range roles {
		switch strings.ToUpper(strings.TrimSpace(role)) {
		case "SUPER_ADMIN", "ADMIN", "OPERATIONS_ADMIN", "OPERATIONS_MANAGER":
			return true
		}
	}
	return false
}

func valueOrDefault(value string, fallback string) string {
	if strings.TrimSpace(value) == "" {
		return fallback
	}
	return strings.TrimSpace(value)
}
