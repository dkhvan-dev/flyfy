package guide

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

func (c *Client) ListPendingApplications(ctx context.Context, limit int, offset int) ([]model.GuideApplicationModerationItem, error) {
	values := url.Values{}
	values.Set("limit", fmt.Sprintf("%d", limit))
	values.Set("offset", fmt.Sprintf("%d", offset))
	var resp guideApplicationListResponse
	if err := c.doJSON(ctx, http.MethodGet, "/v1/admin/guides/verification-requests?"+values.Encode(), nil, nil, &resp); err != nil {
		return nil, err
	}
	items := make([]model.GuideApplicationModerationItem, 0, len(resp.Items))
	for _, item := range resp.Items {
		items = append(items, item.toModel())
	}
	return items, nil
}

func (c *Client) ListActiveGuides(ctx context.Context, limit int, offset int) ([]model.GuideApplicationModerationItem, error) {
	values := url.Values{}
	values.Set("limit", fmt.Sprintf("%d", limit))
	values.Set("offset", fmt.Sprintf("%d", offset))
	var resp guideApplicationListResponse
	if err := c.doJSON(ctx, http.MethodGet, "/v1/admin/guides/profiles?"+values.Encode(), nil, nil, &resp); err != nil {
		return nil, err
	}
	items := make([]model.GuideApplicationModerationItem, 0, len(resp.Items))
	for _, item := range resp.Items {
		items = append(items, item.toModel())
	}
	return items, nil
}

func (c *Client) GetApplication(ctx context.Context, id uuid.UUID) (*model.GuideApplicationModerationItem, error) {
	var resp guideApplicationResponse
	if err := c.doJSON(ctx, http.MethodGet, "/v1/admin/guides/verification-requests/"+id.String(), nil, nil, &resp); err != nil {
		return nil, err
	}
	item := resp.toModel()
	return &item, nil
}

func (c *Client) Approve(ctx context.Context, input port.GuideApplicationDecisionInput) (*model.GuideApplicationModerationItem, []byte, error) {
	headers := c.decisionHeaders(input)
	var resp guideApplicationResponse
	raw, err := c.doJSONRaw(ctx, http.MethodPost, "/v1/admin/guides/verification-requests/"+input.GuideApplicationID.String()+"/approve", headers, nil, &resp)
	if err != nil {
		return nil, nil, err
	}
	item := resp.toModel()
	return &item, raw, nil
}

func (c *Client) Reject(ctx context.Context, input port.GuideApplicationDecisionInput) (*model.GuideApplicationModerationItem, []byte, error) {
	headers := c.decisionHeaders(input)
	body := map[string]any{
		"reviewComment": input.PublicComment,
	}
	var resp guideApplicationResponse
	raw, err := c.doJSONRaw(ctx, http.MethodPost, "/v1/admin/guides/verification-requests/"+input.GuideApplicationID.String()+"/reject", headers, body, &resp)
	if err != nil {
		return nil, nil, err
	}
	item := resp.toModel()
	return &item, raw, nil
}

func (c *Client) Revoke(ctx context.Context, input port.GuideApplicationDecisionInput) (*model.GuideApplicationModerationItem, []byte, error) {
	headers := c.decisionHeaders(input)
	body := map[string]any{
		"reviewComment": input.PublicComment,
	}
	var resp guideApplicationResponse
	raw, err := c.doJSONRaw(ctx, http.MethodPost, "/v1/admin/guides/verification-requests/"+input.GuideApplicationID.String()+"/revoke", headers, body, &resp)
	if err != nil {
		return nil, nil, err
	}
	item := resp.toModel()
	return &item, raw, nil
}

func (c *Client) RevokeProfile(ctx context.Context, input port.GuideProfileDecisionInput) (*model.GuideApplicationModerationItem, []byte, error) {
	headers := c.profileDecisionHeaders(input)
	body := map[string]any{
		"reviewComment": input.PublicComment,
	}
	var resp guideApplicationResponse
	raw, err := c.doJSONRaw(ctx, http.MethodPost, "/v1/admin/guides/profiles/"+input.GuideProfileID.String()+"/revoke", headers, body, &resp)
	if err != nil {
		return nil, nil, err
	}
	item := resp.toModel()
	return &item, raw, nil
}

func (c *Client) decisionHeaders(input port.GuideApplicationDecisionInput) map[string]string {
	headers := map[string]string{
		"X-Auth-Subject":  "admin-panel:" + input.ActorStaffID.String(),
		"X-User-Id":       input.ActorStaffID.String(),
		"X-User-Roles":    "SUPER_ADMIN,GUIDE_MODERATOR,MODERATION_LEAD,ADMIN",
		"Idempotency-Key": input.IdempotencyKey,
	}
	if input.RequestID != "" {
		headers["X-Request-Id"] = input.RequestID
	}
	return headers
}

func (c *Client) profileDecisionHeaders(input port.GuideProfileDecisionInput) map[string]string {
	headers := map[string]string{
		"X-Auth-Subject":  "admin-panel:" + input.ActorStaffID.String(),
		"X-User-Id":       input.ActorStaffID.String(),
		"X-User-Roles":    "SUPER_ADMIN,GUIDE_MODERATOR,MODERATION_LEAD,ADMIN",
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
		req.Header.Set("X-User-Roles", "SUPER_ADMIN,GUIDE_MODERATOR,MODERATION_LEAD,ADMIN")
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
		return nil, fmt.Errorf("guide-service %s %s returned %d: %s", method, path, resp.StatusCode, strings.TrimSpace(string(raw)))
	}
	if dest != nil {
		if err = json.Unmarshal(raw, dest); err != nil {
			return nil, err
		}
	}
	return raw, nil
}

type guideApplicationListResponse struct {
	Items []guideApplicationResponse `json:"items"`
}

type guideApplicationResponse struct {
	ID                        string                     `json:"id"`
	GuideProfileID            string                     `json:"guideProfileId"`
	GuideUserID               string                     `json:"guideUserId"`
	GuideDisplayName          string                     `json:"guideDisplayName"`
	FirstName                 string                     `json:"firstName"`
	LastName                  string                     `json:"lastName"`
	CountryCode               string                     `json:"countryCode"`
	Locale                    string                     `json:"locale"`
	Timezone                  string                     `json:"timezone"`
	Type                      string                     `json:"type"`
	GuideStatus               string                     `json:"guideStatus"`
	Status                    string                     `json:"status"`
	Headline                  string                     `json:"headline"`
	About                     string                     `json:"about"`
	ExperienceYears           int                        `json:"experienceYears"`
	BaseCityID                string                     `json:"baseCityId"`
	BaseCityName              string                     `json:"baseCityName"`
	IsPrivateGuideAvailable   bool                       `json:"isPrivateGuideAvailable"`
	IsActivityHostAvailable   bool                       `json:"isActivityHostAvailable"`
	IsExcursionGuideAvailable bool                       `json:"isExcursionGuideAvailable"`
	RatingAvg                 float64                    `json:"ratingAvg"`
	ReviewsCount              int                        `json:"reviewsCount"`
	StatusReason              string                     `json:"statusReason"`
	StatusChangedAt           *string                    `json:"statusChangedAt"`
	StatusChangedBy           *string                    `json:"statusChangedBy"`
	Comment                   string                     `json:"comment"`
	ReviewComment             string                     `json:"reviewComment"`
	SubmittedAt               *string                    `json:"submittedAt"`
	ReviewedAt                *string                    `json:"reviewedAt"`
	ReviewedBy                *string                    `json:"reviewedBy"`
	Documents                 []guideApplicationDocument `json:"documents"`
	Languages                 []guideApplicationLanguage `json:"languages"`
	Specializations           []string                   `json:"specializations"`
	RiskScore                 int                        `json:"riskScore"`
	ModerationReasonCodes     []string                   `json:"moderationReasonCodes"`
	Revision                  int                        `json:"revision"`
	CreatedAt                 string                     `json:"createdAt"`
	UpdatedAt                 string                     `json:"updatedAt"`
}

type guideApplicationDocument struct {
	ID           string `json:"id"`
	FileID       string `json:"fileId"`
	DocumentType string `json:"documentType"`
	DownloadURL  string `json:"downloadUrl"`
	CreatedAt    string `json:"createdAt"`
}

type guideApplicationLanguage struct {
	LanguageCode     string `json:"languageCode"`
	ProficiencyLevel string `json:"proficiencyLevel"`
}

func (r guideApplicationResponse) toModel() model.GuideApplicationModerationItem {
	id, _ := uuid.Parse(r.ID)
	guideProfileID, _ := uuid.Parse(r.GuideProfileID)
	guideUserID, _ := uuid.Parse(r.GuideUserID)
	var reviewedBy *uuid.UUID
	if r.ReviewedBy != nil {
		if parsed, err := uuid.Parse(*r.ReviewedBy); err == nil {
			reviewedBy = &parsed
		}
	}
	var statusChangedBy *uuid.UUID
	if r.StatusChangedBy != nil {
		if parsed, err := uuid.Parse(*r.StatusChangedBy); err == nil {
			statusChangedBy = &parsed
		}
	}
	documents := make([]model.GuideApplicationDocument, 0, len(r.Documents))
	for _, item := range r.Documents {
		docID, _ := uuid.Parse(item.ID)
		fileID, _ := uuid.Parse(item.FileID)
		documents = append(documents, model.GuideApplicationDocument{
			ID:           docID,
			FileID:       fileID,
			DocumentType: item.DocumentType,
			DownloadURL:  item.DownloadURL,
			CreatedAt:    parseTime(item.CreatedAt),
		})
	}
	languages := make([]model.GuideApplicationLanguage, 0, len(r.Languages))
	for _, item := range r.Languages {
		languages = append(languages, model.GuideApplicationLanguage{
			LanguageCode:     item.LanguageCode,
			ProficiencyLevel: item.ProficiencyLevel,
		})
	}
	return model.GuideApplicationModerationItem{
		ID:                        id,
		GuideProfileID:            guideProfileID,
		GuideUserID:               guideUserID,
		GuideDisplayName:          r.GuideDisplayName,
		FirstName:                 r.FirstName,
		LastName:                  r.LastName,
		CountryCode:               r.CountryCode,
		Locale:                    r.Locale,
		Timezone:                  r.Timezone,
		Type:                      r.Type,
		GuideStatus:               r.GuideStatus,
		Status:                    r.Status,
		Headline:                  r.Headline,
		About:                     r.About,
		ExperienceYears:           r.ExperienceYears,
		BaseCityID:                r.BaseCityID,
		BaseCityName:              r.BaseCityName,
		IsPrivateGuideAvailable:   r.IsPrivateGuideAvailable,
		IsActivityHostAvailable:   r.IsActivityHostAvailable,
		IsExcursionGuideAvailable: r.IsExcursionGuideAvailable,
		RatingAvg:                 r.RatingAvg,
		ReviewsCount:              r.ReviewsCount,
		StatusReason:              r.StatusReason,
		StatusChangedAt:           parseOptionalTime(r.StatusChangedAt),
		StatusChangedBy:           statusChangedBy,
		Comment:                   r.Comment,
		ReviewComment:             r.ReviewComment,
		SubmittedAt:               parseOptionalTime(r.SubmittedAt),
		ReviewedAt:                parseOptionalTime(r.ReviewedAt),
		ReviewedBy:                reviewedBy,
		Documents:                 documents,
		Languages:                 languages,
		Specializations:           r.Specializations,
		RiskScore:                 r.RiskScore,
		ModerationReasonCodes:     r.ModerationReasonCodes,
		Revision:                  r.Revision,
		CreatedAt:                 parseTime(r.CreatedAt),
		UpdatedAt:                 parseTime(r.UpdatedAt),
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
