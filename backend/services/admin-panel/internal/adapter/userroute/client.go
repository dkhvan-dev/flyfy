package userroute

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/app"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

type Client struct {
	baseURL       string
	httpClient    *http.Client
	internalToken string
}

func NewClient(baseURL string, timeout time.Duration, internalToken string) *Client {
	baseURL = strings.TrimRight(strings.TrimSpace(baseURL), "/")
	if timeout <= 0 {
		timeout = 5 * time.Second
	}
	return &Client{
		baseURL: baseURL,
		httpClient: &http.Client{
			Timeout: timeout,
		},
		internalToken: strings.TrimSpace(internalToken),
	}
}

func (c *Client) ListUserRoutes(
	ctx context.Context,
	input model.AdminUserRouteAdminListRequest,
) ([]model.AdminUserRoute, error) {
	values := url.Values{}
	values.Set("limit", fmt.Sprintf("%d", input.Limit))
	values.Set("offset", fmt.Sprintf("%d", input.Offset))
	setQuery(values, "status", string(input.ModerationStatus))
	setQuery(values, "ownerUserId", input.OwnerUserID)
	setQuery(values, "cityCode", input.CityCode)

	var resp routeListResponse
	if err := c.doJSON(ctx, http.MethodGet, "/v1/admin/user-routes?"+values.Encode(), input.ActorUserID, input.ActorRoles, nil, &resp); err != nil {
		return nil, err
	}
	items := make([]model.AdminUserRoute, 0, len(resp.Items))
	for _, item := range resp.Items {
		items = append(items, item.toModel())
	}
	return items, nil
}

func (c *Client) ReviewUserRoute(
	ctx context.Context,
	input model.AdminUserRouteAdminReviewRequest,
) (*model.AdminUserRoute, error) {
	body := reviewRouteRequest{
		Decision: string(input.Decision),
		Reason:   input.Reason,
	}
	var resp routeResponse
	path := "/v1/admin/user-routes/" + input.RouteID.String() + "/review"
	if err := c.doJSON(ctx, http.MethodPost, path, input.ActorUserID, input.ActorRoles, body, &resp); err != nil {
		return nil, err
	}
	item := resp.toModel()
	return &item, nil
}

func (c *Client) doJSON(
	ctx context.Context,
	method string,
	path string,
	actorUserID string,
	actorRoles []string,
	body any,
	dest any,
) error {
	var reader io.Reader
	if body != nil {
		payload, err := json.Marshal(body)
		if err != nil {
			return err
		}
		reader = bytes.NewReader(payload)
	}

	req, err := http.NewRequestWithContext(ctx, method, c.baseURL+path, reader)
	if err != nil {
		return err
	}
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	req.Header.Set("Accept", "application/json")
	req.Header.Set("X-User-Id", strings.TrimSpace(actorUserID))
	req.Header.Set("X-User-Roles", strings.Join(actorRoles, ","))
	if subject := strings.TrimSpace(actorUserID); subject != "" {
		req.Header.Set("X-Auth-Subject", "admin-panel:"+subject)
	}
	if c.internalToken != "" {
		req.Header.Set("Authorization", "Bearer "+c.internalToken)
		req.Header.Set("X-Internal-Service-Token", c.internalToken)
		req.Header.Set("X-Internal-Service", "admin-panel")
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	raw, err := io.ReadAll(io.LimitReader(resp.Body, 4<<20))
	if err != nil {
		return err
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return mapUserRouteStatusError(method, path, resp.StatusCode, raw)
	}
	if dest != nil && len(raw) > 0 {
		if err = json.Unmarshal(raw, dest); err != nil {
			return err
		}
	}
	return nil
}

func mapUserRouteStatusError(method string, path string, statusCode int, raw []byte) error {
	switch statusCode {
	case http.StatusBadRequest, http.StatusUnprocessableEntity:
		return app.ErrInvalidInput
	case http.StatusUnauthorized, http.StatusForbidden:
		return app.ErrPermissionDenied
	case http.StatusNotFound:
		return app.ErrOperationResourceNotFound
	default:
		return fmt.Errorf("user-route-service %s %s returned %d: %s", method, path, statusCode, strings.TrimSpace(string(raw)))
	}
}

func setQuery(values url.Values, key string, value string) {
	value = strings.TrimSpace(value)
	if value != "" {
		values.Set(key, value)
	}
}

type routeListResponse struct {
	Items []routeResponse `json:"items"`
}

type routeResponse struct {
	ID                string                `json:"id"`
	OwnerUserID       string                `json:"ownerUserId"`
	Title             string                `json:"title"`
	Description       string                `json:"description"`
	Visibility        string                `json:"visibility"`
	CityCode          string                `json:"cityCode"`
	Points            []routePointResponse  `json:"points"`
	Snapshot          routeSnapshotResponse `json:"snapshot"`
	ModerationStatus  string                `json:"moderationStatus"`
	ModerationReason  string                `json:"moderationReason"`
	ModeratedByUserID *string               `json:"moderatedByUserId"`
	ModeratedAt       *time.Time            `json:"moderatedAt"`
	CreatedAt         time.Time             `json:"createdAt"`
	UpdatedAt         time.Time             `json:"updatedAt"`
}

type routePointResponse struct {
	Name      string  `json:"name"`
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}

type routeSnapshotResponse struct {
	DistanceMeters  int `json:"distanceMeters"`
	DurationSeconds int `json:"durationSeconds"`
}

type reviewRouteRequest struct {
	Decision string `json:"decision"`
	Reason   string `json:"reason"`
}

func (r routeResponse) toModel() model.AdminUserRoute {
	id, _ := uuid.Parse(strings.TrimSpace(r.ID))
	ownerID, _ := uuid.Parse(strings.TrimSpace(r.OwnerUserID))
	points := make([]model.AdminUserRoutePoint, 0, len(r.Points))
	for i, point := range r.Points {
		points = append(points, model.AdminUserRoutePoint{
			Position:  i + 1,
			Label:     strings.TrimSpace(point.Name),
			Latitude:  point.Latitude,
			Longitude: point.Longitude,
		})
	}
	return model.AdminUserRoute{
		ID:                id,
		OwnerUserID:       ownerID,
		Title:             r.Title,
		Description:       r.Description,
		Visibility:        r.Visibility,
		CityCode:          strings.ToLower(strings.TrimSpace(r.CityCode)),
		DistanceMeters:    float64(r.Snapshot.DistanceMeters),
		DurationSeconds:   r.Snapshot.DurationSeconds,
		Points:            points,
		ModerationStatus:  model.NormalizeUserRouteModerationStatus(r.ModerationStatus),
		ModerationReason:  strings.TrimSpace(r.ModerationReason),
		ModeratedByUserID: r.ModeratedByUserID,
		ModeratedAt:       r.ModeratedAt,
		CreatedAt:         r.CreatedAt,
		UpdatedAt:         r.UpdatedAt,
	}
}
