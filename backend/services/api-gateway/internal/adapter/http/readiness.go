package http

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/rs/zerolog/log"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/api-gateway/internal/app"
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
		Status  string `json:"status"`
		Error   string `json:"error,omitempty"`
		Message string `json:"message,omitempty"`
		Code    string `json:"code,omitempty"`
		Kind    string `json:"kind,omitempty"`
	}

	deps := make(map[string]dependencyStatus, len(h.checkers))
	overallReady := true

	for name, checker := range h.checkers {
		ctx, cancel := context.WithTimeout(r.Context(), h.timeout)
		err := checker.Check(ctx)
		cancel()

		if err != nil {
			log.Warn().
				Err(err).
				Str("dependency", name).
				Str("request_id", RequestIDFromContext(r.Context())).
				Msg("readiness dependency check failed")

			publicError := buildErrorResponse(r, errorCodeTechnical, errorKindTechnical)
			overallReady = false
			deps[name] = dependencyStatus{
				Status:  "down",
				Error:   publicError.Error,
				Message: publicError.Message,
				Code:    publicError.Code,
				Kind:    publicError.Kind,
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
	return &HTTPReadinessChecker{
		client: &http.Client{Timeout: normalizeReadinessTimeout(timeout)},
		url:    url,
	}
}

func NewHTTPReadinessCheckerWithTransportAuth(url string, timeout time.Duration, mtls transportauth.EnvConfig) (*HTTPReadinessChecker, error) {
	timeout = normalizeReadinessTimeout(timeout)
	client, err := transportauth.NewHTTPClient(
		mtls.ClientConfig(transportauth.ServerNameFromTarget(url)),
		timeout,
	)
	if err != nil {
		return nil, fmt.Errorf("initialize readiness mTLS client for %s: %w", url, err)
	}

	return &HTTPReadinessChecker{
		client: client,
		url:    url,
	}, nil
}

func normalizeReadinessTimeout(timeout time.Duration) time.Duration {
	if timeout <= 0 {
		timeout = 2 * time.Second
	}
	return timeout
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
