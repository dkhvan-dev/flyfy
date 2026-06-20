package activity

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
	"kz/inflap/backend/services/admin-panel/internal/domain/port"
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

func (c *Client) ListFlagged(ctx context.Context, limit int, offset int) ([]model.ActivityModerationItem, error) {
	values := url.Values{}
	values.Set("limit", fmt.Sprintf("%d", limit))
	values.Set("offset", fmt.Sprintf("%d", offset))
	var resp activityListResponse
	if err := c.doJSON(ctx, http.MethodGet, "/v1/admin/activities/moderation/flagged?"+values.Encode(), nil, nil, &resp); err != nil {
		return nil, err
	}
	items := make([]model.ActivityModerationItem, 0, len(resp.Items))
	for _, item := range resp.Items {
		items = append(items, item.toModel())
	}
	return items, nil
}

func (c *Client) GetActivity(ctx context.Context, id uuid.UUID) (*model.ActivityModerationItem, error) {
	var resp activityResponse
	if err := c.doJSON(ctx, http.MethodGet, "/v1/admin/activities/"+id.String(), nil, nil, &resp); err != nil {
		return nil, err
	}
	item := resp.toModel()
	return &item, nil
}

func (c *Client) Approve(ctx context.Context, input port.ActivityDecisionInput) (*model.ActivityModerationItem, []byte, error) {
	headers := c.decisionHeaders(input)
	var resp activityResponse
	raw, err := c.doJSONRaw(ctx, http.MethodPost, "/v1/admin/activities/"+input.ActivityID.String()+"/moderation/approve", headers, nil, &resp)
	if err != nil {
		return nil, nil, err
	}
	item := resp.toModel()
	return &item, raw, nil
}

func (c *Client) Reject(ctx context.Context, input port.ActivityDecisionInput) (*model.ActivityModerationItem, []byte, error) {
	headers := c.decisionHeaders(input)
	body := map[string]any{
		"reasonCodes":   input.ReasonCodes,
		"publicComment": input.PublicComment,
	}
	var resp activityResponse
	raw, err := c.doJSONRaw(ctx, http.MethodPost, "/v1/admin/activities/"+input.ActivityID.String()+"/moderation/reject", headers, body, &resp)
	if err != nil {
		return nil, nil, err
	}
	item := resp.toModel()
	return &item, raw, nil
}

func (c *Client) decisionHeaders(input port.ActivityDecisionInput) map[string]string {
	headers := map[string]string{
		"X-Auth-Subject":  "admin-panel:" + input.ActorStaffID.String(),
		"X-User-Id":       input.ActorStaffID.String(),
		"X-User-Roles":    "SUPER_ADMIN,ACTIVITY_MODERATOR",
		"Idempotency-Key": input.IdempotencyKey,
	}
	if input.RequestID != "" {
		headers["X-Request-Id"] = input.RequestID
	}
	return headers
}

func (c *Client) doJSON(ctx context.Context, method string, path string, headers map[string]string, body any, dest any) error {
	_, err := c.doJSONRaw(ctx, method, path, headers, body, dest)
	return err
}

func (c *Client) doJSONRaw(ctx context.Context, method string, path string, headers map[string]string, body any, dest any) ([]byte, error) {
	var reader io.Reader
	if body != nil {
		payload, err := json.Marshal(body)
		if err != nil {
			return nil, err
		}
		reader = bytes.NewReader(payload)
	}
	req, err := http.NewRequestWithContext(ctx, method, c.baseURL+path, reader)
	if err != nil {
		return nil, err
	}
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	req.Header.Set("Accept", "application/json")
	if c.internalToken != "" {
		req.Header.Set("Authorization", "Bearer "+c.internalToken)
		req.Header.Set("X-Internal-Service-Token", c.internalToken)
		req.Header.Set("X-Internal-Service", "admin-panel")
		req.Header.Set("X-Auth-Subject", "admin-panel")
		req.Header.Set("X-User-Roles", "SUPER_ADMIN,ACTIVITY_MODERATOR")
	}
	for key, value := range headers {
		if strings.TrimSpace(value) != "" {
			req.Header.Set(key, value)
		}
	}
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	raw, err := io.ReadAll(io.LimitReader(resp.Body, 4<<20))
	if err != nil {
		return nil, err
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		if isMaintenanceError(raw) {
			return nil, app.ErrTechnicalMaintenance
		}
		return nil, fmt.Errorf("activity-service %s %s returned %d: %s", method, path, resp.StatusCode, strings.TrimSpace(string(raw)))
	}
	if dest != nil {
		if err = json.Unmarshal(raw, dest); err != nil {
			return nil, err
		}
	}
	return raw, nil
}

func isMaintenanceError(raw []byte) bool {
	var payload struct {
		Code string `json:"code"`
		Kind string `json:"kind"`
	}
	if err := json.Unmarshal(raw, &payload); err != nil {
		return false
	}
	return strings.TrimSpace(payload.Kind) == "maintenance" ||
		strings.HasSuffix(strings.TrimSpace(payload.Code), ".technical_maintenance")
}

type activityListResponse struct {
	Items []activityResponse `json:"items"`
}

type activityResponse struct {
	ID                    string   `json:"id"`
	HostUserID            string   `json:"hostUserId"`
	HostDisplayName       string   `json:"hostDisplayName"`
	SourceActivityID      *string  `json:"sourceActivityId"`
	Title                 string   `json:"title"`
	Description           string   `json:"description"`
	Format                string   `json:"format"`
	Status                string   `json:"status"`
	Visibility            string   `json:"visibility"`
	JoinMode              string   `json:"joinMode"`
	ModerationStatus      string   `json:"moderationStatus"`
	ModerationRiskScore   int      `json:"moderationRiskScore"`
	ModerationReasonCodes []string `json:"moderationReasonCodes"`
	ModerationTriggeredAt *string  `json:"moderationTriggeredAt"`
	ModerationReviewedAt  *string  `json:"moderationReviewedAt"`
	CategorySlug          string   `json:"categorySlug"`
	SubcategorySlug       *string  `json:"subcategorySlug"`
	CategoryName          string   `json:"categoryName"`
	CategoryNameRu        string   `json:"categoryNameRu"`
	CategoryNameKk        string   `json:"categoryNameKk"`
	SubcategoryName       string   `json:"subcategoryName"`
	SubcategoryNameRu     string   `json:"subcategoryNameRu"`
	SubcategoryNameKk     string   `json:"subcategoryNameKk"`
	LanguageCode          string   `json:"languageCode"`
	Timezone              string   `json:"timezone"`
	StartAt               string   `json:"startAt"`
	EndAt                 string   `json:"endAt"`
	RegistrationDeadline  string   `json:"registrationDeadline"`
	CapacityType          string   `json:"capacityType"`
	MinParticipants       *int     `json:"minParticipants"`
	MaxParticipants       *int     `json:"maxParticipants"`
	PriceType             string   `json:"priceType"`
	PriceAmount           *float64 `json:"priceAmount"`
	Currency              *string  `json:"currency"`
	CountryCode           *string  `json:"countryCode"`
	CityID                *string  `json:"cityId"`
	CityName              *string  `json:"cityName"`
	AddressText           *string  `json:"addressText"`
	Latitude              *float64 `json:"latitude"`
	Longitude             *float64 `json:"longitude"`
	MapURL                *string  `json:"mapUrl"`
	MeetingURL            *string  `json:"meetingUrl"`
	CoverImageURL         *string  `json:"coverImageUrl"`
	Revision              int      `json:"revision"`
	CreatedAt             string   `json:"createdAt"`
	UpdatedAt             string   `json:"updatedAt"`
}

func (r activityResponse) toModel() model.ActivityModerationItem {
	id, _ := uuid.Parse(r.ID)
	hostUserID, _ := uuid.Parse(r.HostUserID)
	var sourceActivityID *uuid.UUID
	if r.SourceActivityID != nil {
		if parsed, err := uuid.Parse(*r.SourceActivityID); err == nil {
			sourceActivityID = &parsed
		}
	}
	return model.ActivityModerationItem{
		ID:                    id,
		HostUserID:            hostUserID,
		HostDisplayName:       r.HostDisplayName,
		SourceActivityID:      sourceActivityID,
		Title:                 r.Title,
		Description:           r.Description,
		Format:                r.Format,
		Status:                r.Status,
		Visibility:            r.Visibility,
		JoinMode:              r.JoinMode,
		ModerationStatus:      r.ModerationStatus,
		ModerationRiskScore:   r.ModerationRiskScore,
		ModerationReasonCodes: r.ModerationReasonCodes,
		ModerationTriggeredAt: parseOptionalTime(r.ModerationTriggeredAt),
		ModerationReviewedAt:  parseOptionalTime(r.ModerationReviewedAt),
		CategorySlug:          r.CategorySlug,
		SubcategorySlug:       r.SubcategorySlug,
		CategoryName:          r.CategoryName,
		CategoryNameRu:        r.CategoryNameRu,
		CategoryNameKk:        r.CategoryNameKk,
		SubcategoryName:       r.SubcategoryName,
		SubcategoryNameRu:     r.SubcategoryNameRu,
		SubcategoryNameKk:     r.SubcategoryNameKk,
		LanguageCode:          r.LanguageCode,
		Timezone:              r.Timezone,
		StartAt:               parseTime(r.StartAt),
		EndAt:                 parseTime(r.EndAt),
		RegistrationDeadline:  parseTime(r.RegistrationDeadline),
		CapacityType:          r.CapacityType,
		MinParticipants:       r.MinParticipants,
		MaxParticipants:       r.MaxParticipants,
		PriceType:             r.PriceType,
		PriceAmount:           r.PriceAmount,
		Currency:              r.Currency,
		CountryCode:           r.CountryCode,
		CityID:                r.CityID,
		CityName:              r.CityName,
		AddressText:           r.AddressText,
		Latitude:              r.Latitude,
		Longitude:             r.Longitude,
		MapURL:                r.MapURL,
		MeetingURL:            r.MeetingURL,
		CoverImageURL:         r.CoverImageURL,
		Revision:              r.Revision,
		CreatedAt:             parseTime(r.CreatedAt),
		UpdatedAt:             parseTime(r.UpdatedAt),
	}
}

func parseTime(value string) time.Time {
	parsed, _ := time.Parse(time.RFC3339, strings.TrimSpace(value))
	return parsed
}

func parseOptionalTime(value *string) *time.Time {
	if value == nil {
		return nil
	}
	parsed, err := time.Parse(time.RFC3339, strings.TrimSpace(*value))
	if err != nil {
		return nil
	}
	return &parsed
}
