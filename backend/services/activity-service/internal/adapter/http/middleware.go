package http

import (
	"net"
	"net/http"
	"strings"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"
	"kz/inflap/backend/services/activity-service/internal/app"
	"kz/inflap/backend/services/activity-service/internal/config"
)

func IdentityMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ctx := r.Context()

		if userID := strings.TrimSpace(r.Header.Get("X-User-Id")); userID != "" {
			ctx = withUserID(ctx, userID)
		}

		if subject := strings.TrimSpace(r.Header.Get("X-Auth-Subject")); subject != "" {
			ctx = withSubject(ctx, subject)
		}

		roles := parseRolesHeader(r.Header.Get("X-User-Roles"))
		if len(roles) > 0 {
			ctx = withRole(ctx, roles[0])
			ctx = withRoles(ctx, roles)
		}

		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func parseRolesHeader(raw string) []string {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return nil
	}

	parts := strings.Split(raw, ",")
	result := make([]string, 0, len(parts))
	seen := make(map[string]struct{}, len(parts))

	for _, part := range parts {
		role := strings.ToUpper(strings.TrimSpace(part))
		if role == "" {
			continue
		}
		if _, ok := seen[role]; ok {
			continue
		}
		seen[role] = struct{}{}
		result = append(result, role)
	}

	return result
}

func Chain(cfg *config.Config, next http.Handler) http.Handler {
	return requestIDMiddleware(cfg,
		authContextMiddleware(cfg,
			fraudSignalsMiddleware(
				auditLoggingMiddleware(next),
			),
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
		userID := strings.TrimSpace(r.Header.Get(userIDHeader))
		roles := splitCSV(strings.TrimSpace(r.Header.Get(rolesHeader)))
		subject := strings.TrimSpace(r.Header.Get(subjectHeader))
		hasInternalToken := hasValidInternalServiceToken(cfg, r)

		ctx := r.Context()
		if userID != "" {
			ctx = withUserID(ctx, userID)
		}
		if len(roles) > 0 {
			ctx = withRoles(ctx, roles)
		}
		if subject != "" {
			ctx = withSubject(ctx, subject)
		}

		if cfg.Security.RequireAuthenticatedWrites && isWriteMethod(r.Method) {
			if subject == "" && !hasInternalToken {
				writeError(w, http.StatusUnauthorized, "missing authenticated subject")
				return
			}
		}

		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func hasValidInternalServiceToken(cfg *config.Config, r *http.Request) bool {
	expected := strings.TrimSpace(cfg.Security.InternalServiceToken)
	if expected == "" {
		return false
	}
	token := strings.TrimSpace(r.Header.Get("X-Internal-Service-Token"))
	if token == "" {
		token = bearerToken(r.Header.Get("Authorization"))
	}
	return token == expected
}

func fraudSignalsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		signals := app.FraudSignals{
			ClientIP:  clientIPFromRequest(r),
			DeviceID:  r.Header.Get("X-Device-Id"),
			UserAgent: r.UserAgent(),
		}
		next.ServeHTTP(w, r.WithContext(app.WithFraudSignals(r.Context(), signals)))
	})
}

func clientIPFromRequest(r *http.Request) string {
	if r == nil {
		return ""
	}
	if forwardedFor := strings.TrimSpace(r.Header.Get("X-Forwarded-For")); forwardedFor != "" {
		parts := strings.Split(forwardedFor, ",")
		if len(parts) > 0 {
			return strings.TrimSpace(parts[0])
		}
	}
	if realIP := strings.TrimSpace(r.Header.Get("X-Real-IP")); realIP != "" {
		return realIP
	}
	host, _, err := net.SplitHostPort(strings.TrimSpace(r.RemoteAddr))
	if err == nil {
		return host
	}
	return strings.TrimSpace(r.RemoteAddr)
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
		if role := RoleFromContext(r.Context()); role != "" {
			logger = logger.Str("role", role)
		}

		logger.Msg("http request completed")
	})
}

type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(statusCode int) {
	rw.statusCode = statusCode
	rw.ResponseWriter.WriteHeader(statusCode)
}

func isWriteMethod(method string) bool {
	switch method {
	case http.MethodPost, http.MethodPut, http.MethodPatch, http.MethodDelete:
		return true
	default:
		return false
	}
}
