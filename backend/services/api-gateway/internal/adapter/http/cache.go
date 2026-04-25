package http

import (
	"bytes"
	"context"
	"net/http"
	"time"

	"github.com/redis/go-redis/v9"
	"github.com/rs/zerolog/log"

	"github.com/dkhvan-dev/flyfy/backend/services/api-gateway/internal/config"
)

// ResponseCache is a Redis-backed HTTP response cache for cacheable GET routes.
type ResponseCache struct {
	client *redis.Client
	ttl    time.Duration
}

func NewResponseCache(cfg config.RedisConfig) *ResponseCache {
	client := redis.NewClient(&redis.Options{
		Addr: cfg.Addr,
		DB:   cfg.DB,
	})
	return &ResponseCache{
		client: client,
		ttl:    cfg.TTL,
	}
}

func (rc *ResponseCache) Close() error {
	return rc.client.Close()
}

func (rc *ResponseCache) Ping(ctx context.Context) error {
	return rc.client.Ping(ctx).Err()
}

// Middleware returns an HTTP middleware that caches GET responses for cacheable routes.
func (rc *ResponseCache) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			next.ServeHTTP(w, r)
			return
		}

		policy := RoutePolicyFromContext(r.Context())
		if policy == nil || !policy.Cacheable {
			next.ServeHTTP(w, r)
			return
		}

		cacheKey := "gw:cache:" + r.URL.RequestURI()

		// Try cache hit.
		cached, err := rc.client.Get(r.Context(), cacheKey).Bytes()
		if err == nil {
			w.Header().Set("Content-Type", "application/json; charset=utf-8")
			w.Header().Set("X-Cache", "HIT")
			w.WriteHeader(http.StatusOK)
			_, _ = w.Write(cached)
			return
		}

		// Cache miss — capture response.
		rec := &responseCapturer{
			ResponseWriter: w,
			body:           &bytes.Buffer{},
			statusCode:     http.StatusOK,
		}

		next.ServeHTTP(rec, r)

		// Only cache successful responses.
		if rec.statusCode == http.StatusOK && rec.body.Len() > 0 {
			if cacheErr := rc.client.Set(r.Context(), cacheKey, rec.body.Bytes(), rc.ttl).Err(); cacheErr != nil {
				log.Warn().Err(cacheErr).Str("key", cacheKey).Msg("failed to write response cache")
			}
		}

		w.Header().Set("X-Cache", "MISS")
	})
}

type responseCapturer struct {
	http.ResponseWriter
	body       *bytes.Buffer
	statusCode int
}

func (rc *responseCapturer) WriteHeader(code int) {
	rc.statusCode = code
	rc.ResponseWriter.WriteHeader(code)
}

func (rc *responseCapturer) Write(b []byte) (int, error) {
	if rc.statusCode == http.StatusOK {
		rc.body.Write(b)
	}
	return rc.ResponseWriter.Write(b)
}
