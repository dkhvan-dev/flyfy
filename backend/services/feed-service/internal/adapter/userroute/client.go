package userroute

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/app"
)

const (
	getUserRoutePathPrefix  = "/v1/user-routes/"
	trustedUserIDHeader     = "X-User-Id"
	userRouteErrorBodyLimit = 4096
)

type Client struct {
	baseURL    string
	httpClient *http.Client
}

var _ app.PostRouteReferenceValidator = (*Client)(nil)

func New(baseURL string, timeout time.Duration) *Client {
	if timeout <= 0 {
		timeout = 3 * time.Second
	}
	return &Client{
		baseURL:    strings.TrimRight(strings.TrimSpace(baseURL), "/"),
		httpClient: &http.Client{Timeout: timeout},
	}
}

func (c *Client) ValidatePostRouteReference(
	ctx context.Context,
	input app.PostRouteReferenceValidationInput,
) error {
	routeID := strings.TrimSpace(input.RouteID)
	if input.AuthorUserID == uuid.Nil || routeID == "" {
		return app.ErrInvalidPostRouteReference
	}
	if c == nil || c.baseURL == "" || c.httpClient == nil {
		return fmt.Errorf("user-route client is not configured")
	}

	req, err := http.NewRequestWithContext(
		ctx,
		http.MethodGet,
		c.baseURL+getUserRoutePathPrefix+url.PathEscape(routeID),
		nil,
	)
	if err != nil {
		return fmt.Errorf("create user-route lookup request: %w", err)
	}
	req.Header.Set("Accept", "application/json")
	req.Header.Set(trustedUserIDHeader, input.AuthorUserID.String())

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("call user-route-service: %w", err)
	}
	defer resp.Body.Close()

	switch {
	case resp.StatusCode >= http.StatusOK && resp.StatusCode < http.StatusMultipleChoices:
		var route userRouteResponse
		if err = json.NewDecoder(resp.Body).Decode(&route); err != nil {
			return fmt.Errorf("decode user-route-service response: %w", err)
		}
		if !route.isShareableBy(input.AuthorUserID, routeID) {
			return app.ErrInvalidPostRouteReference
		}
		return nil
	case resp.StatusCode == http.StatusBadRequest ||
		resp.StatusCode == http.StatusUnauthorized ||
		resp.StatusCode == http.StatusForbidden ||
		resp.StatusCode == http.StatusNotFound:
		return app.ErrInvalidPostRouteReference
	default:
		respBody, _ := io.ReadAll(io.LimitReader(resp.Body, userRouteErrorBodyLimit))
		return fmt.Errorf(
			"user-route-service lookup failed: status=%d message=%s",
			resp.StatusCode,
			strings.TrimSpace(string(respBody)),
		)
	}
}

type userRouteResponse struct {
	ID               string `json:"id"`
	OwnerUserID      string `json:"ownerUserId"`
	Visibility       string `json:"visibility"`
	ModerationStatus string `json:"moderationStatus"`
}

func (r userRouteResponse) isShareableBy(authorUserID uuid.UUID, routeID string) bool {
	if authorUserID == uuid.Nil {
		return false
	}
	if strings.TrimSpace(r.ID) != strings.TrimSpace(routeID) {
		return false
	}
	if strings.TrimSpace(r.OwnerUserID) != authorUserID.String() {
		return false
	}
	if strings.ToLower(strings.TrimSpace(r.ModerationStatus)) != "approved" {
		return false
	}
	switch strings.ToLower(strings.TrimSpace(r.Visibility)) {
	case "public", "unlisted":
		return true
	default:
		return false
	}
}
