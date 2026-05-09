package http

import (
	"crypto/subtle"
	"net/http"
	"strings"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/config"
)

func Chain(
	cfg *config.Config,
	next http.Handler,
) http.Handler {
	return requestIDMiddleware(cfg,
		auditLoggingMiddleware(
			authContextMiddleware(cfg, next),
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

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		userID := strings.TrimSpace(r.Header.Get(userIDHeader))
		roles := splitCSV(strings.TrimSpace(r.Header.Get(rolesHeader)))
		internalToken := strings.TrimSpace(r.Header.Get("X-Internal-Service-Token"))
		isInternalCall := internalToken != "" &&
			cfg.Security.InternalServiceToken != "" &&
			subtle.ConstantTimeCompare([]byte(internalToken), []byte(cfg.Security.InternalServiceToken)) == 1

		ctx := r.Context()
		if userID != "" {
			ctx = withUserID(ctx, userID)
		}
		if len(roles) > 0 {
			ctx = withUserRoles(ctx, roles)
		}
		if isInternalCall {
			ctx = withInternalCall(ctx)
		}

		if cfg.Security.RequireAuthenticatedWrites && isWriteMethod(r.Method) {
			if userID == "" && !isInternalCall {
				writeError(w, http.StatusUnauthorized, "missing authenticated user context")
				return
			}
		}

		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func auditLoggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		rw := newResponseWriter(w)
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

func requireUserContext(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if UserIDFromContext(r.Context()) == "" {
			writeError(w, http.StatusUnauthorized, "missing authenticated user context")
			return
		}
		next.ServeHTTP(w, r)
	})
}

func requireInternalToken(cfg *config.Config, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		token := strings.TrimSpace(r.Header.Get("X-Internal-Service-Token"))
		if token == "" {
			writeError(w, http.StatusUnauthorized, "missing internal service token")
			return
		}

		if subtle.ConstantTimeCompare([]byte(token), []byte(cfg.Security.InternalServiceToken)) != 1 {
			writeError(w, http.StatusUnauthorized, "invalid internal service token")
			return
		}

		next.ServeHTTP(w, r.WithContext(withInternalCall(r.Context())))
	})
}

func isWriteMethod(method string) bool {
	switch method {
	case http.MethodPost, http.MethodPut, http.MethodPatch, http.MethodDelete:
		return true
	default:
		return false
	}
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
