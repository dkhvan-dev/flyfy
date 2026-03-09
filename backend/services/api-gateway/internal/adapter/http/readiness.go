package http

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/dkhvan-dev/flyfy/backend/services/api-gateway/internal/app"
)

type ReadinessHandler struct {
	checkers map[string]app.ReadinessChecker
	timeout  time.Duration
}

func NewReadinessHandler(
	checkers map[string]app.ReadinessChecker,
	timeout time.Duration,
) *ReadinessHandler {
	if timeout <= 0 {
		timeout = 2 * time.Second
	}

	return &ReadinessHandler{
		checkers: checkers,
		timeout:  timeout,
	}
}

func (h *ReadinessHandler) Ready(w http.ResponseWriter, r *http.Request) {
	type dependencyStatus struct {
		Status string `json:"status"`
		Error  string `json:"error,omitempty"`
	}

	deps := make(map[string]dependencyStatus, len(h.checkers))
	overallReady := true

	for name, checker := range h.checkers {
		ctx, cancel := context.WithTimeout(r.Context(), h.timeout)
		err := checker.Check(ctx)
		cancel()

		if err != nil {
			overallReady = false
			deps[name] = dependencyStatus{
				Status: "down",
				Error:  err.Error(),
			}
			continue
		}

		deps[name] = dependencyStatus{
			Status: "up",
		}
	}

	if !overallReady {
		writeJSON(w, http.StatusServiceUnavailable, map[string]any{
			"status":       "not_ready",
			"dependencies": deps,
		})
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"status":       "ready",
		"dependencies": deps,
	})
}

type HTTPReadinessChecker struct {
	client *http.Client
	url    string
}

func NewHTTPReadinessChecker(url string, timeout time.Duration) *HTTPReadinessChecker {
	if timeout <= 0 {
		timeout = 2 * time.Second
	}

	return &HTTPReadinessChecker{
		client: &http.Client{Timeout: timeout},
		url:    url,
	}
}

func (c *HTTPReadinessChecker) Check(ctx context.Context) error {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.url, nil)
	if err != nil {
		return fmt.Errorf("build request: %w", err)
	}

	resp, err := c.client.Do(req)
	if err != nil {
		return fmt.Errorf("http check failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("unexpected status: %d", resp.StatusCode)
	}

	return nil
}
