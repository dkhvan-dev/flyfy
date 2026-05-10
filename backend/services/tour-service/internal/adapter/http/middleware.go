package http

import (
	"net/http"
	"strings"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/config"
)

func Chain(cfg *config.Config, next http.Handler) http.Handler {
	return requestIDMiddleware(cfg,
		authContextMiddleware(cfg,
			auditLoggingMiddleware(next),
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
