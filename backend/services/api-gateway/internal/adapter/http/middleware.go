package http

import (
	"context"
	"net"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/dkhvan-dev/flyfy/backend/services/api-gateway/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/api-gateway/internal/config"
)

type contextKey string

const (
	contextKeyRequestID contextKey = "request_id"
	contextKeyClaims    contextKey = "claims"
	contextKeyRouteName contextKey = "route_name"
	contextKeyPolicy    contextKey = "route_policy"
)

type rateLimiter struct {
	mu       sync.Mutex
	window   time.Duration
	visitors map[string]*visitor
}

type visitor struct {
	count      int
	limit      int
	windowFrom time.Time
}

func newRateLimiter(limit int, window time.Duration) *rateLimiter {
	if limit <= 0 {
		limit = 120
	}
	if window <= 0 {
		window = time.Minute
	}

	return &rateLimiter{
		window:   window,
		visitors: make(map[string]*visitor),
	}
}

func (rl *rateLimiter) Allow(key string, limit int, now time.Time) bool {
	if limit <= 0 {
		limit = 120
	}

	rl.mu.Lock()
	defer rl.mu.Unlock()

	v, ok := rl.visitors[key]
	if !ok {
		rl.visitors[key] = &visitor{
			count:      1,
			limit:      limit,
			windowFrom: now,
		}
		return true
	}

	if now.Sub(v.windowFrom) >= rl.window || v.limit != limit {
		v.count = 1
		v.limit = limit
		v.windowFrom = now
		return true
	}

	if v.count >= v.limit {
		return false
	}

	v.count++
	return true
}

func (rl *rateLimiter) Cleanup(now time.Time) {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	for key, v := range rl.visitors {
		if now.Sub(v.windowFrom) >= rl.window*2 {
			delete(rl.visitors, key)
		}
	}
}

func Chain(cfg *config.Config, verifier app.TokenVerifier, next http.Handler) http.Handler {
	var limiter *rateLimiter
	if cfg.RateLimit.Enabled {
		limiter = newRateLimiter(cfg.RateLimit.RequestsPerMinute, time.Minute)
	}

	handler := corsMiddleware(cfg,
		requestIDMiddleware(cfg,
			routePolicyMiddleware(cfg,
				rateLimitMiddleware(cfg, limiter,
					logMiddleware(
						authMiddleware(cfg, verifier, next),
					),
				),
			),
		),
	)

	if limiter != nil {
		go startRateLimiterCleanup(limiter, cfg.RateLimit.CleanupInterval)
	}

	return handler
}

func corsMiddleware(cfg *config.Config, next http.Handler) http.Handler {
	allowedOrigins := splitCSV(cfg.CORS.AllowedOrigins)
	allowedMethods := joinCSVOrDefault(cfg.CORS.AllowedMethods, "GET,POST,PUT,PATCH,DELETE,OPTIONS")
	allowedHeaders := joinCSVOrDefault(cfg.CORS.AllowedHeaders, "Authorization,Content-Type,X-Request-Id")
	exposeHeaders := joinCSVOrDefault(cfg.CORS.ExposeHeaders, "X-Request-Id")

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		origin := strings.TrimSpace(r.Header.Get("Origin"))

		if len(allowedOrigins) == 1 && allowedOrigins[0] == "*" {
			w.Header().Set("Access-Control-Allow-Origin", "*")
		} else if origin != "" && contains(allowedOrigins, origin) {
			w.Header().Set("Access-Control-Allow-Origin", origin)
			w.Header().Add("Vary", "Origin")
		}

		w.Header().Set("Access-Control-Allow-Methods", allowedMethods)
		w.Header().Set("Access-Control-Allow-Headers", allowedHeaders)
		w.Header().Set("Access-Control-Expose-Headers", exposeHeaders)
		w.Header().Set("Access-Control-Max-Age", strconv.Itoa(cfg.CORS.MaxAgeSeconds))

		if cfg.CORS.AllowCredentials {
			w.Header().Set("Access-Control-Allow-Credentials", "true")
		}

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}

		next.ServeHTTP(w, r)
	})
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
		ctx := context.WithValue(r.Context(), contextKeyRequestID, requestID)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func routePolicyMiddleware(cfg *config.Config, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		policy := matchRoutePolicy(r.URL.Path, cfg.Routes.APIPrefix)
		if policy != nil {
			ctx := context.WithValue(r.Context(), contextKeyRouteName, policy.Name)
			ctx = context.WithValue(ctx, contextKeyPolicy, policy)
			next.ServeHTTP(w, r.WithContext(ctx))
			return
		}
		next.ServeHTTP(w, r)
	})
}

func rateLimitMiddleware(cfg *config.Config, limiter *rateLimiter, next http.Handler) http.Handler {
	if limiter == nil {
		return next
	}

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/health" || r.URL.Path == "/ready" {
			next.ServeHTTP(w, r)
			return
		}

		limit := cfg.RateLimit.RequestsPerMinute
		if limit <= 0 {
			limit = 120
		}

		if policy := RoutePolicyFromContext(r.Context()); policy != nil && policy.RateLimitPerMinute != nil && *policy.RateLimitPerMinute > 0 {
			limit = *policy.RateLimitPerMinute
		}

		key := clientIP(r) + ":" + RouteNameOrDefault(r.Context())

		if !limiter.Allow(key, limit, time.Now().UTC()) {
			writeError(w, http.StatusTooManyRequests, "rate limit exceeded")
			return
		}

		next.ServeHTTP(w, r)
	})
}

func logMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		rw := &responseWriter{
			ResponseWriter: w,
			statusCode:     http.StatusOK,
		}

		startedAt := time.Now()
		next.ServeHTTP(rw, r)

		logger := log.Info().
			Str("transport", "http").
			Str("method", r.Method).
			Str("path", r.URL.Path).
			Int("status", rw.statusCode).
			Dur("duration", time.Since(startedAt)).
			Str("request_id", RequestIDFromContext(r.Context()))

		if routeName := RouteNameFromContext(r.Context()); routeName != "" {
			logger = logger.Str("route", routeName)
		}

		if claims := ClaimsFromContext(r.Context()); claims != nil {
			logger = logger.
				Str("subject", claims.Subject).
				Str("user_id", claims.UserID)
		}

		logger.Msg("gateway request completed")
	})
}

func authMiddleware(cfg *config.Config, verifier app.TokenVerifier, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/health" || r.URL.Path == "/ready" {
			next.ServeHTTP(w, r)
			return
		}

		policy := RoutePolicyFromContext(r.Context())
		if policy == nil {
			writeError(w, http.StatusNotFound, "route not found")
			return
		}

		if policy.AuthMode == RouteAuthPublic {
			next.ServeHTTP(w, r)
			return
		}

		authHeader := strings.TrimSpace(r.Header.Get("Authorization"))
		if !strings.HasPrefix(strings.ToLower(authHeader), "bearer ") {
			writeError(w, http.StatusUnauthorized, "missing bearer token")
			return
		}

		token := strings.TrimSpace(authHeader[len("Bearer "):])
		if token == "" {
			writeError(w, http.StatusUnauthorized, "missing bearer token")
			return
		}

		claims, err := verifier.VerifyAccessToken(r.Context(), token)
		if err != nil {
			writeError(w, http.StatusUnauthorized, "invalid access token")
			return
		}

		if policy.AuthMode == RouteAuthRoleBased && !hasAnyRequiredRole(claims.Roles, policy.RequiredRoles) {
			writeError(w, http.StatusForbidden, "insufficient role")
			return
		}

		ctx := context.WithValue(r.Context(), contextKeyClaims, claims)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func hasAnyRequiredRole(actual []string, required []string) bool {
	if len(required) == 0 {
		return true
	}
	if len(actual) == 0 {
		return false
	}

	set := make(map[string]struct{}, len(actual))
	for _, role := range actual {
		role = strings.ToUpper(strings.TrimSpace(role))
		if role != "" {
			set[role] = struct{}{}
		}
	}

	for _, role := range required {
		role = strings.ToUpper(strings.TrimSpace(role))
		if _, ok := set[role]; ok {
			return true
		}
	}

	return false
}

func RequestIDFromContext(ctx context.Context) string {
	v, _ := ctx.Value(contextKeyRequestID).(string)
	return v
}

func ClaimsFromContext(ctx context.Context) *app.TokenClaims {
	v, _ := ctx.Value(contextKeyClaims).(*app.TokenClaims)
	return v
}

func RouteNameFromContext(ctx context.Context) string {
	v, _ := ctx.Value(contextKeyRouteName).(string)
	return v
}

func RoutePolicyFromContext(ctx context.Context) *RoutePolicy {
	v, _ := ctx.Value(contextKeyPolicy).(*RoutePolicy)
	return v
}

type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(statusCode int) {
	rw.statusCode = statusCode
	rw.ResponseWriter.WriteHeader(statusCode)
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

func joinCSVOrDefault(v string, fallback string) string {
	items := splitCSV(v)
	if len(items) == 0 {
		return fallback
	}
	return strings.Join(items, ", ")
}

func contains(items []string, target string) bool {
	for _, item := range items {
		if item == target {
			return true
		}
	}
	return false
}

func startRateLimiterCleanup(limiter *rateLimiter, interval time.Duration) {
	if interval <= 0 {
		interval = time.Minute
	}

	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	for range ticker.C {
		limiter.Cleanup(time.Now().UTC())
	}
}

func clientIP(r *http.Request) string {
	forwardedFor := strings.TrimSpace(r.Header.Get("X-Forwarded-For"))
	if forwardedFor != "" {
		parts := strings.Split(forwardedFor, ",")
		if len(parts) > 0 && strings.TrimSpace(parts[0]) != "" {
			return strings.TrimSpace(parts[0])
		}
	}

	realIP := strings.TrimSpace(r.Header.Get("X-Real-Ip"))
	if realIP != "" {
		return realIP
	}

	host, _, err := net.SplitHostPort(strings.TrimSpace(r.RemoteAddr))
	if err == nil && host != "" {
		return host
	}

	return strings.TrimSpace(r.RemoteAddr)
}

func RouteNameOrDefault(ctx context.Context) string {
	name := RouteNameFromContext(ctx)
	if strings.TrimSpace(name) == "" {
		return "unknown"
	}
	return name
}
