package http

import (
	"context"
	"crypto/subtle"
	"net/http"
	"strings"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/feed-service/internal/config"
)

func Chain(cfg *config.Config, next http.Handler) http.Handler {
	return requestIDMiddleware(cfg,
		authContextMiddleware(cfg,
			auditLoggingMiddleware(next),
		),
	)
}

func requestIDMiddleware(cfg *config.Config, next http.Handler) http.Handler {
	headerName := cfg.Security.RequestIDHeader
	if strings.TrimSpace(headerName) == "" {
		headerName = "X-Request-Id"
	}

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requestID := strings.TrimSpace(r.Header.Get(headerName))
		if requestID == "" {
			requestID = uuid.NewString()
		}

		w.Header().Set(headerName, requestID)
		ctx := withRequestID(r.Context(), requestID)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func authContextMiddleware(cfg *config.Config, next http.Handler) http.Handler {
	userIDHeader := cfg.Security.TrustedGatewayHeaderUserID
	rolesHeader := cfg.Security.TrustedGatewayHeaderRoles
	subjectHeader := cfg.Security.TrustedGatewayHeaderSub

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		hasValidInternalToken := hasValidInternalServiceToken(cfg, r)
		if hasTrustedAuthHeaders(cfg, r) && !hasValidInternalToken {
			writeError(w, r, http.StatusUnauthorized, errorCodeUnauthenticatedWriter)
			return
		}

		userID := strings.TrimSpace(r.Header.Get(userIDHeader))
		roles := splitCSV(strings.TrimSpace(r.Header.Get(rolesHeader)))
		subject := strings.TrimSpace(r.Header.Get(subjectHeader))

		ctx := r.Context()
		if userID != "" {
			ctx = withUserID(ctx, userID)
		}
		if len(roles) > 0 {
			ctx = withUserRoles(ctx, roles)
		}
		if subject != "" {
			ctx = withSubject(ctx, subject)
		}
		if hasValidInternalToken {
			ctx = withInternalCall(ctx)
		}

		if cfg.Security.RequireAuthenticatedWrites &&
			isWriteMethod(r.Method) &&
			!isPublicWriteRoute(r) {
			if subject == "" && !hasValidInternalToken {
				writeError(w, r, http.StatusUnauthorized, errorCodeUnauthenticatedWriter)
				return
			}
		}

		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func hasTrustedAuthHeaders(cfg *config.Config, r *http.Request) bool {
	return strings.TrimSpace(r.Header.Get(cfg.Security.TrustedGatewayHeaderUserID)) != "" ||
		strings.TrimSpace(r.Header.Get(cfg.Security.TrustedGatewayHeaderRoles)) != "" ||
		strings.TrimSpace(r.Header.Get(cfg.Security.TrustedGatewayHeaderSub)) != ""
}

func hasValidInternalServiceToken(cfg *config.Config, r *http.Request) bool {
	expected := strings.TrimSpace(cfg.Security.InternalServiceToken)
	if expected == "" {
		return false
	}
	actual := strings.TrimSpace(r.Header.Get("X-Internal-Service-Token"))
	return subtle.ConstantTimeCompare([]byte(actual), []byte(expected)) == 1
}

func auditLoggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		rw := &responseWriter{
			ResponseWriter: w,
			statusCode:     http.StatusOK,
		}

		next.ServeHTTP(rw, r)

		logger := log.Info().
			Str("transport", "http").
			Str("method", r.Method).
			Str("path", r.URL.Path).
			Int("status", rw.statusCode).
			Str("request_id", RequestIDFromContext(r.Context()))

		if userID := UserIDFromContext(r.Context()); userID != "" {
			logger = logger.Str("user_id", userID)
		}
		if subject := SubjectFromContext(r.Context()); subject != "" {
			logger = logger.Str("subject", subject)
		}

		logger.Msg("http request completed")
	})
}

func splitCSV(v string) []string {
	if strings.TrimSpace(v) == "" {
		return nil
	}

	parts := strings.Split(v, ",")
	result := make([]string, 0, len(parts))
	for _, part := range parts {
		part = strings.TrimSpace(part)
		if part != "" {
			result = append(result, part)
		}
	}
	return result
}

func isWriteMethod(method string) bool {
	switch method {
	case http.MethodPost, http.MethodPut, http.MethodPatch, http.MethodDelete:
		return true
	default:
		return false
	}
}

func isPublicWriteRoute(r *http.Request) bool {
	if r.Method != http.MethodPost {
		return false
	}

	parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	if len(parts) != 4 || parts[0] != "v1" || parts[1] != "posts" || parts[3] != "share" {
		return false
	}

	_, err := uuid.Parse(parts[2])
	return err == nil
}

func hasRole(ctx context.Context, target string) bool {
	target = strings.TrimSpace(strings.ToUpper(target))
	if target == "" {
		return false
	}

	for _, role := range UserRolesFromContext(ctx) {
		if strings.ToUpper(strings.TrimSpace(role)) == target {
			return true
		}
	}
	return false
}
