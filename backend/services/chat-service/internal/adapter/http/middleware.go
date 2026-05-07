package http

import (
	"bufio"
	"crypto/subtle"
	"net"
	"net/http"
	"strings"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/config"
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
		ctx := r.Context()
		internalPath := strings.HasPrefix(r.URL.Path, "/v1/internal/")

		if internalPath {
			token := strings.TrimSpace(r.Header.Get("X-Internal-Service-Token"))
			if token == "" {
				writeError(w, http.StatusUnauthorized, "missing internal service token")
				return
			}
			if subtle.ConstantTimeCompare([]byte(token), []byte(cfg.Security.InternalServiceToken)) != 1 {
				writeError(w, http.StatusUnauthorized, "invalid internal service token")
				return
			}
			ctx = withInternalCall(ctx)
		}

		userID := strings.TrimSpace(r.Header.Get(userIDHeader))
		if userID != "" {
			ctx = withUserID(ctx, userID)
		}

		roles := splitCSV(strings.TrimSpace(r.Header.Get(rolesHeader)))
		if len(roles) > 0 {
			ctx = withRoles(ctx, roles)
		}

		subject := strings.TrimSpace(r.Header.Get(subjectHeader))
		if subject != "" {
			ctx = withSubject(ctx, subject)
		}

		if cfg.Security.RequireAuthenticatedWrites && isWriteMethod(r.Method) {
			if subject == "" && !InternalCallFromContext(ctx) {
				writeError(w, http.StatusUnauthorized, "missing authenticated subject")
				return
			}
		}

		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func auditLoggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		rw := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}
		next.ServeHTTP(rw, r)

		logger := log.Info().
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

func (rw *responseWriter) Unwrap() http.ResponseWriter {
	return rw.ResponseWriter
}

func (rw *responseWriter) WriteHeader(statusCode int) {
	rw.statusCode = statusCode
	rw.ResponseWriter.WriteHeader(statusCode)
}

func (rw *responseWriter) Flush() {
	if flusher, ok := rw.ResponseWriter.(http.Flusher); ok {
		flusher.Flush()
	}
}

func (rw *responseWriter) Hijack() (net.Conn, *bufio.ReadWriter, error) {
	hijacker, ok := rw.ResponseWriter.(http.Hijacker)
	if !ok {
		return nil, nil, http.ErrNotSupported
	}
	return hijacker.Hijack()
}

func (rw *responseWriter) Push(target string, opts *http.PushOptions) error {
	pusher, ok := rw.ResponseWriter.(http.Pusher)
	if !ok {
		return http.ErrNotSupported
	}
	return pusher.Push(target, opts)
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
