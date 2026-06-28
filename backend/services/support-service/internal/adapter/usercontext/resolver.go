package usercontext

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"kz/inflap/backend/services/support-service/internal/app"
)

type Resolver struct {
	userBaseURL   string
	guideBaseURL  string
	internalToken string
	httpClient    *http.Client
}

func NewResolver(userServiceURL string, guideServiceURL string, internalToken string, timeout time.Duration) *Resolver {
	if timeout <= 0 {
		timeout = 3 * time.Second
	}
	return &Resolver{
		userBaseURL:   strings.TrimRight(strings.TrimSpace(userServiceURL), "/"),
		guideBaseURL:  strings.TrimRight(strings.TrimSpace(guideServiceURL), "/"),
		internalToken: strings.TrimSpace(internalToken),
		httpClient: &http.Client{
			Timeout: timeout,
		},
	}
}

func (r *Resolver) ResolveSupportUserSegment(ctx context.Context, userID string) (app.SupportUserSegment, error) {
	userID = strings.TrimSpace(userID)
	if r == nil || r.userBaseURL == "" || userID == "" {
		return app.SupportUserSegment{}, fmt.Errorf("invalid support user context resolver request")
	}

	user, err := r.getUser(ctx, userID)
	if err != nil {
		return app.SupportUserSegment{}, err
	}

	segment := app.SupportUserSegment{
		UserID:         userID,
		Nickname:       stringValue(user.Profile.Nickname),
		FollowersCount: user.Followers.Count,
		RefreshStatus:  app.SupportSegmentRefreshStatusFresh,
		SourceVersion:  "user-service",
	}
	if r.guideBaseURL == "" {
		return segment, nil
	}

	guide, found, err := r.getGuide(ctx, userID)
	if err != nil {
		segment.RefreshStatus = app.SupportSegmentRefreshStatusStale
		segment.SourceVersion = "user-service+guide-service:stale"
		return segment, nil
	}
	if !found {
		segment.SourceVersion = "user-service+guide-service:not_found"
		return segment, nil
	}
	segment.GuideStatus = strings.TrimSpace(guide.Profile.Status)
	segment.IsGuide = supportGuideStatusIsActive(segment.GuideStatus)
	segment.SourceVersion = "user-service+guide-service"
	return segment, nil
}

func (r *Resolver) getUser(ctx context.Context, userID string) (userResponse, error) {
	var decoded userResponse
	path := "/v1/users/" + url.PathEscape(userID)
	if err := r.getJSON(ctx, r.userBaseURL+path, &decoded); err != nil {
		return userResponse{}, fmt.Errorf("resolve user context: %w", err)
	}
	return decoded, nil
}

func (r *Resolver) getGuide(ctx context.Context, userID string) (guideResponse, bool, error) {
	var decoded guideResponse
	path := "/v1/guides/by-user/" + url.PathEscape(userID)
	status, err := r.getJSONStatus(ctx, r.guideBaseURL+path, &decoded)
	if err != nil {
		return guideResponse{}, false, err
	}
	if status == http.StatusNotFound {
		return guideResponse{}, false, nil
	}
	if status < http.StatusOK || status >= http.StatusMultipleChoices {
		return guideResponse{}, false, fmt.Errorf("%s returned status %d", path, status)
	}
	return decoded, true, nil
}

func (r *Resolver) getJSON(ctx context.Context, endpoint string, target any) error {
	status, err := r.getJSONStatus(ctx, endpoint, target)
	if err != nil {
		return err
	}
	if status < http.StatusOK || status >= http.StatusMultipleChoices {
		return fmt.Errorf("%s returned status %d", endpoint, status)
	}
	return nil
}

func (r *Resolver) getJSONStatus(ctx context.Context, endpoint string, target any) (int, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return 0, fmt.Errorf("create request: %w", err)
	}
	r.applyHeaders(req)
	resp, err := r.httpClient.Do(req)
	if err != nil {
		return 0, fmt.Errorf("send request: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode < http.StatusOK || resp.StatusCode >= http.StatusMultipleChoices {
		_, _ = io.Copy(io.Discard, io.LimitReader(resp.Body, 1<<20))
		return resp.StatusCode, nil
	}
	raw, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return resp.StatusCode, fmt.Errorf("read response: %w", err)
	}
	if err := json.Unmarshal(raw, target); err != nil {
		return resp.StatusCode, fmt.Errorf("decode response: %w", err)
	}
	return resp.StatusCode, nil
}

func (r *Resolver) applyHeaders(req *http.Request) {
	req.Header.Set("Accept", "application/json")
	req.Header.Set("X-User-Roles", "SUPPORT_AGENT,SUPPORT_ADMIN")
	if r.internalToken != "" {
		req.Header.Set("Authorization", "Bearer "+r.internalToken)
		req.Header.Set("X-Internal-Service-Token", r.internalToken)
		req.Header.Set("X-Internal-Service", "support-service")
	}
}

func stringValue(value *string) string {
	if value == nil {
		return ""
	}
	return strings.TrimSpace(*value)
}

func supportGuideStatusIsActive(status string) bool {
	switch strings.ToUpper(strings.TrimSpace(status)) {
	case "ACTIVE", "VERIFIED", "APPROVED":
		return true
	default:
		return false
	}
}

type userResponse struct {
	Profile struct {
		Nickname *string `json:"nickname,omitempty"`
	} `json:"profile"`
	Followers struct {
		Count int `json:"count"`
	} `json:"followers"`
}

type guideResponse struct {
	Profile struct {
		Status string `json:"status"`
	} `json:"profile"`
}
