package switches

import (
	"context"
	"encoding/json"
	"net/http"
	"slices"
	"strings"
	"sync"
	"time"
)

const defaultMaintenanceMessage = "Проводятся технические работы"
const defaultMaintenanceCacheTTL = time.Second
const defaultMaintenanceErrorTTL = 250 * time.Millisecond

type MaintenanceMiddlewareConfig struct {
	DomainCode       string
	ScopeCodes       []string
	Message          string
	SkipPaths        []string
	SkipPathPrefixes []string
	CacheTTL         time.Duration
	ErrorTTL         time.Duration
	OnCheckError     func(ctx context.Context, err error, check TechBreakCheck)
}

func NewMaintenanceMiddleware(
	clientCfg HTTPClientConfig,
	middlewareCfg MaintenanceMiddlewareConfig,
	opts ...HTTPClientOption,
) (func(http.Handler) http.Handler, error) {
	client, err := NewHTTPClient(clientCfg, opts...)
	if err != nil {
		return nil, err
	}
	return MaintenanceMiddleware(client, middlewareCfg), nil
}

func MaintenanceMiddleware(checker TechBreakChecker, cfg MaintenanceMiddlewareConfig) func(http.Handler) http.Handler {
	domainCode := strings.TrimSpace(cfg.DomainCode)
	if checker == nil || domainCode == "" {
		return func(next http.Handler) http.Handler { return next }
	}

	message := strings.TrimSpace(cfg.Message)
	if message == "" {
		message = defaultMaintenanceMessage
	}
	cacheTTL := cfg.CacheTTL
	if cacheTTL <= 0 {
		cacheTTL = defaultMaintenanceCacheTTL
	}
	errorTTL := cfg.ErrorTTL
	if errorTTL <= 0 {
		errorTTL = defaultMaintenanceErrorTTL
	}
	skipPaths := append([]string{"/health", "/ready", "/live", "/metrics"}, cfg.SkipPaths...)
	cache := &maintenanceCache{}

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if shouldSkipMaintenanceCheck(r, skipPaths, cfg.SkipPathPrefixes) {
				next.ServeHTTP(w, r)
				return
			}

			if cachedActive, ok := cache.get(time.Now()); ok {
				if cachedActive {
					writeMaintenanceResponse(w, message)
					return
				}
				next.ServeHTTP(w, r)
				return
			}

			check := TechBreakCheck{
				DomainCode: domainCode,
				ScopeCodes: normalizedScopeCodes(cfg.ScopeCodes),
			}
			active, err := checker.HasActiveTechBreak(r.Context(), check)
			if err != nil {
				if cfg.OnCheckError != nil {
					cfg.OnCheckError(r.Context(), err, check)
				}
				cache.set(false, time.Now().Add(errorTTL))
				next.ServeHTTP(w, r)
				return
			}
			cache.set(active, time.Now().Add(cacheTTL))
			if active {
				writeMaintenanceResponse(w, message)
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}

type maintenanceCache struct {
	mu        sync.RWMutex
	active    bool
	expiresAt time.Time
}

func (c *maintenanceCache) get(now time.Time) (bool, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()
	if c.expiresAt.IsZero() || !now.Before(c.expiresAt) {
		return false, false
	}
	return c.active, true
}

func (c *maintenanceCache) set(active bool, expiresAt time.Time) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.active = active
	c.expiresAt = expiresAt
}

func shouldSkipMaintenanceCheck(r *http.Request, skipPaths []string, skipPathPrefixes []string) bool {
	if r.Method == http.MethodOptions {
		return true
	}
	path := r.URL.Path
	if slices.Contains(skipPaths, path) {
		return true
	}
	for _, prefix := range skipPathPrefixes {
		if prefix != "" && strings.HasPrefix(path, prefix) {
			return true
		}
	}
	return false
}

func normalizedScopeCodes(scopeCodes []string) []string {
	if len(scopeCodes) == 0 {
		return nil
	}
	normalized := make([]string, 0, len(scopeCodes))
	for _, scopeCode := range scopeCodes {
		scopeCode = strings.TrimSpace(scopeCode)
		if scopeCode != "" {
			normalized = append(normalized, scopeCode)
		}
	}
	return normalized
}

func writeMaintenanceResponse(w http.ResponseWriter, message string) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusServiceUnavailable)
	_ = json.NewEncoder(w).Encode(map[string]string{
		"error":   "technical_maintenance",
		"message": message,
	})
}
