package http

import (
	"crypto/subtle"
	"net/http"
	"strings"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/place-service/internal/config"
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
	userIDHeader := cfg.Security.TrustedHeaderUserID
	rolesHeader := cfg.Security.TrustedHeaderRoles
	subjectHeader := cfg.Security.TrustedHeaderSubject

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
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

		if isInternalPath(r.URL.Path) {
			token := strings.TrimSpace(r.Header.Get("X-Internal-Service-Token"))
			if token == "" ||
				subtle.ConstantTimeCompare([]byte(token), []byte(cfg.Security.InternalServiceToken)) != 1 {
				writeError(w, http.StatusUnauthorized, "invalid internal service token")
				return
			}
			next.ServeHTTP(w, r.WithContext(ctx))
			return
		}

		if cfg.Security.RequireAuthenticatedWrites && isWriteMethod(r.Method) {
			if subject == "" {
				writeError(w, http.StatusUnauthorized, "missing authenticated subject")
				return
			}
		}

		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func isInternalPath(path string) bool {
	return strings.HasPrefix(path, "/internal/")
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
