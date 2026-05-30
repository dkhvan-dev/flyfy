package http

import (
	"net"
	"net/http"
	"strings"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"
	"kz/inflap/backend/services/excursion-service/internal/app"

	"kz/inflap/backend/services/excursion-service/internal/config"
)

const headerInternalServiceToken = "X-Internal-Service-Token"

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
	headerName := strings.TrimSpace(cfg.Security.RequestIDHeader)
	if headerName == "" {
		headerName = "X-Request-Id"
	}

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requestID := strings.TrimSpace(r.Header.Get(headerName))
		if requestID == "" {
			requestID = uuid.NewString()
		}
		w.Header().Set(headerName, requestID)
		next.ServeHTTP(w, r.WithContext(withRequestID(r.Context(), requestID)))
	})
}

func authContextMiddleware(cfg *config.Config, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ctx := r.Context()
		if hasTrustedAuthHeaders(cfg, r) && !hasValidInternalServiceToken(cfg, r) {
			writeError(w, http.StatusUnauthorized, "invalid trusted auth headers")
			return
		}
		if userID := strings.TrimSpace(r.Header.Get(cfg.Security.TrustedGatewayHeaderUserID)); userID != "" {
			ctx = withUserID(ctx, userID)
		}
		if subject := strings.TrimSpace(r.Header.Get(cfg.Security.TrustedGatewayHeaderSub)); subject != "" {
			ctx = withSubject(ctx, subject)
		}
		roles := splitCSV(r.Header.Get(cfg.Security.TrustedGatewayHeaderRoles))
		if len(roles) > 0 {
			ctx = withRoles(ctx, roles)
		}

		if cfg.Security.RequireAuthenticatedWrites && isWriteMethod(r.Method) && SubjectFromContext(ctx) == "" {
			writeError(w, http.StatusUnauthorized, "missing authenticated subject")
			return
		}

		next.ServeHTTP(w, r.WithContext(ctx))
	})
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

func hasTrustedAuthHeaders(cfg *config.Config, r *http.Request) bool {
	return strings.TrimSpace(r.Header.Get(cfg.Security.TrustedGatewayHeaderUserID)) != "" ||
		strings.TrimSpace(r.Header.Get(cfg.Security.TrustedGatewayHeaderSub)) != "" ||
		strings.TrimSpace(r.Header.Get(cfg.Security.TrustedGatewayHeaderRoles)) != ""
}

func hasValidInternalServiceToken(cfg *config.Config, r *http.Request) bool {
	expected := strings.TrimSpace(cfg.Security.InternalServiceToken)
	if expected == "" {
		return false
	}
	return strings.TrimSpace(r.Header.Get(headerInternalServiceToken)) == expected
}

func auditLoggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		rw := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}
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
