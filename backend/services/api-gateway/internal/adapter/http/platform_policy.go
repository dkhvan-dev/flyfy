package http

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"strings"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/pkg/platformpolicy"
	"kz/inflap/backend/services/api-gateway/internal/config"
)

const (
	savedPolicyCodeDependencyUnavailable  = "SAVED_DEPENDENCY_UNAVAILABLE"
	savedPolicyCodeTemporarilyUnavailable = "SAVED_TEMPORARILY_UNAVAILABLE"
	savedPolicyRetryAfterSeconds          = 1
	savedPolicyRetryAfterMilliseconds     = int64(savedPolicyRetryAfterSeconds * 1000)
)

type platformPersonalDataGuard interface {
	Guard(ctx context.Context) (platformpolicy.Grant, error)
}

type internalServiceTokenHeaderProvider struct {
	token string
}

func (provider internalServiceTokenHeaderProvider) TokenHeader(ctx context.Context) (platformpolicy.TokenHeader, error) {
	if ctx == nil {
		return platformpolicy.TokenHeader{}, errors.New("platform policy token context is nil")
	}
	if err := ctx.Err(); err != nil {
		return platformpolicy.TokenHeader{}, err
	}
	token := strings.TrimSpace(provider.token)
	if token == "" {
		return platformpolicy.TokenHeader{}, errors.New("platform policy internal token is unavailable")
	}
	return platformpolicy.TokenHeader{
		Name:  platformpolicy.HeaderInternalServiceToken,
		Value: token,
	}, nil
}

func newPlatformPersonalDataGuard(cfg *config.Config) (*platformpolicy.Checker, error) {
	transport, err := newGatewayDownstreamTransport(cfg.PlatformPolicy.BaseURL, cfg.MTLS)
	if err != nil {
		return nil, fmt.Errorf("initialize platform policy mTLS transport: %w", err)
	}
	return newPlatformPersonalDataGuardWithTransport(cfg, transport)
}

func newPlatformPersonalDataGuardWithTransport(
	cfg *config.Config,
	transport http.RoundTripper,
) (*platformpolicy.Checker, error) {
	source, err := platformpolicy.NewHTTPClient(platformpolicy.HTTPClientConfig{
		BaseURL:           cfg.PlatformPolicy.BaseURL,
		Timeout:           cfg.PlatformPolicy.HTTPTimeout,
		MaxResponseBytes:  cfg.PlatformPolicy.MaxResponseBytes,
		AllowInsecureHTTP: cfg.PlatformPolicy.AllowInsecureHTTP,
		Transport:         transport,
		TokenHeaderProvider: internalServiceTokenHeaderProvider{
			token: cfg.PlatformPolicy.InternalServiceToken,
		},
	})
	if err != nil {
		return nil, fmt.Errorf("initialize platform policy HTTP source: %w", err)
	}
	checker, err := platformpolicy.NewChecker(platformpolicy.CheckerConfig{
		Source:         source,
		RefreshTimeout: cfg.PlatformPolicy.RefreshTimeout,
	})
	if err != nil {
		return nil, fmt.Errorf("initialize platform policy checker: %w", err)
	}
	return checker, nil
}

func (h *ProxyHandler) guardPlatformPersonalData(
	w http.ResponseWriter,
	r *http.Request,
	policy *RoutePolicy,
) bool {
	if policy == nil || !policy.SavedPersonal {
		return true
	}
	if h == nil || h.platformPolicyGuard == nil {
		h.writeSavedPolicyDenial(w, r, platformpolicy.ReasonUnavailable)
		return false
	}

	if _, err := h.platformPolicyGuard.Guard(r.Context()); err != nil {
		reason, ok := platformpolicy.DenialReason(err)
		if !ok || reason == platformpolicy.ReasonNone {
			reason = platformpolicy.ReasonUnavailable
		}
		log.Warn().
			Str("route", policy.Name).
			Str("request_id", RequestIDFromContext(r.Context())).
			Str("policy_reason", string(reason)).
			Msg("platform personal-data policy denied Saved request")
		h.writeSavedPolicyDenial(w, r, reason)
		return false
	}
	return true
}

type savedPolicyErrorEnvelope struct {
	Code         string `json:"code"`
	Retryable    bool   `json:"retryable"`
	RetryAfterMS int64  `json:"retry_after_ms,omitempty"`
	RequestID    string `json:"request_id"`
}

func (h *ProxyHandler) writeSavedPolicyDenial(
	w http.ResponseWriter,
	r *http.Request,
	reason platformpolicy.Reason,
) {
	requestID := savedPolicyRequestID(r)
	requestIDHeader := "X-Request-Id"
	if h != nil && h.cfg != nil && strings.TrimSpace(h.cfg.Security.RequestIDHeader) != "" {
		requestIDHeader = strings.TrimSpace(h.cfg.Security.RequestIDHeader)
	}

	header := w.Header()
	header.Set("Cache-Control", "private, no-store")
	header.Set("Pragma", "no-cache")
	header.Set("Content-Language", localeFromRequest(r))
	header.Set("X-Content-Type-Options", "nosniff")
	header.Set(requestIDHeader, requestID)
	ensureVaryValues(header, "Authorization", "Accept-Language")

	status := http.StatusServiceUnavailable
	payload := savedPolicyErrorEnvelope{
		Code:         savedPolicyCodeTemporarilyUnavailable,
		Retryable:    true,
		RetryAfterMS: savedPolicyRetryAfterMilliseconds,
		RequestID:    requestID,
	}
	switch reason {
	case platformpolicy.ReasonLocked:
		status = http.StatusForbidden
		payload.Code = platformpolicy.ExternalDenialCode
		payload.Retryable = false
		payload.RetryAfterMS = 0
	case platformpolicy.ReasonUnavailable:
		payload.Code = savedPolicyCodeDependencyUnavailable
	}
	if payload.Retryable {
		header.Set("Retry-After", "1")
	}
	writeJSON(w, status, payload)
}

func savedPolicyRequestID(r *http.Request) string {
	requestID := ""
	if r != nil {
		requestID = strings.TrimSpace(RequestIDFromContext(r.Context()))
	}
	if !isSafeSavedRequestID(requestID) {
		return uuid.NewString()
	}
	return requestID
}

func isSafeSavedRequestID(requestID string) bool {
	if requestID == "" || len(requestID) > 128 {
		return false
	}
	for index := 0; index < len(requestID); index++ {
		if requestID[index] < 0x21 || requestID[index] > 0x7e {
			return false
		}
	}
	return true
}

func ensureVaryValues(header http.Header, values ...string) {
	seen := make(map[string]struct{})
	ordered := make([]string, 0, len(values)+2)
	for _, raw := range header.Values("Vary") {
		for _, value := range strings.Split(raw, ",") {
			value = strings.TrimSpace(value)
			key := strings.ToLower(value)
			if key == "*" {
				header.Set("Vary", "*")
				return
			}
			if value == "" {
				continue
			}
			if _, ok := seen[key]; ok {
				continue
			}
			seen[key] = struct{}{}
			ordered = append(ordered, value)
		}
	}
	for _, value := range values {
		value = strings.TrimSpace(value)
		key := strings.ToLower(value)
		if value == "" {
			continue
		}
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		ordered = append(ordered, value)
	}
	header.Set("Vary", strings.Join(ordered, ", "))
}
