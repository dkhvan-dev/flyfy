package excursion

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

func (c *Client) ListPendingReview(ctx context.Context, limit int, offset int) ([]model.ExcursionModerationItem, error) {
	values := url.Values{}
	values.Set("limit", fmt.Sprintf("%d", limit))
	values.Set("offset", fmt.Sprintf("%d", offset))
	var resp excursionListResponse
	if err := c.doJSON(ctx, http.MethodGet, "/v1/admin/excursions/moderation/pending?"+values.Encode(), nil, nil, &resp); err != nil {
		return nil, err
	}
	items := make([]model.ExcursionModerationItem, 0, len(resp.Items))
	for _, item := range resp.Items {
		items = append(items, item.toModel())
	}
	return items, nil
}

func (c *Client) GetExcursion(ctx context.Context, id uuid.UUID) (*model.ExcursionModerationItem, error) {
	var resp excursionResponse
	if err := c.doJSON(ctx, http.MethodGet, "/v1/admin/excursions/"+id.String(), nil, nil, &resp); err != nil {
		return nil, err
	}
	item := resp.toModel()
	return &item, nil
}

func (c *Client) Approve(ctx context.Context, input port.ExcursionDecisionInput) (*model.ExcursionModerationItem, []byte, error) {
	headers := c.decisionHeaders(input)
	var resp excursionResponse
	raw, err := c.doJSONRaw(ctx, http.MethodPost, "/v1/admin/excursions/"+input.ExcursionID.String()+"/moderation/approve", headers, nil, &resp)
	if err != nil {
		return nil, nil, err
	}
	item := resp.toModel()
	return &item, raw, nil
}

func (c *Client) Reject(ctx context.Context, input port.ExcursionDecisionInput) (*model.ExcursionModerationItem, []byte, error) {
	headers := c.decisionHeaders(input)
	body := map[string]any{
		"reasonCodes":   input.ReasonCodes,
		"publicComment": input.PublicComment,
	}
	var resp excursionResponse
	raw, err := c.doJSONRaw(ctx, http.MethodPost, "/v1/admin/excursions/"+input.ExcursionID.String()+"/moderation/reject", headers, body, &resp)
	if err != nil {
		return nil, nil, err
	}
	item := resp.toModel()
	return &item, raw, nil
}

func (c *Client) decisionHeaders(input port.ExcursionDecisionInput) map[string]string {
	headers := map[string]string{
		"X-Auth-Subject":  "admin-panel:" + input.ActorStaffID.String(),
		"X-User-Id":       input.ActorStaffID.String(),
		"X-User-Roles":    "SUPER_ADMIN,MODERATOR",
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
		req.Header.Set("X-User-Roles", "SUPER_ADMIN,MODERATOR")
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
		return nil, fmt.Errorf("excursion-service %s %s returned %d: %s", method, path, resp.StatusCode, strings.TrimSpace(string(raw)))
	}
	if dest != nil {
		if err = json.Unmarshal(raw, dest); err != nil {
			return nil, err
		}
	}
	return raw, nil
}

type excursionListResponse struct {
	Items []excursionResponse `json:"items"`
}

type excursionResponse struct {
	ID                       string                           `json:"id"`
	Title                    string                           `json:"title"`
	Summary                  string                           `json:"summary"`
	Description              string                           `json:"description"`
	Translations             map[string]localizedCopyResponse `json:"translations"`
	ProductTranslations      map[string]localizedCopyResponse `json:"productTranslations"`
	Status                   string                           `json:"status"`
	Visibility               string                           `json:"visibility"`
	GuideUserID              string                           `json:"guideUserId"`
	GuideDisplayName         string                           `json:"guideDisplayName"`
	GuideNickname            string                           `json:"guideNickname"`
	GuideFirstName           string                           `json:"guideFirstName"`
	GuideLastName            string                           `json:"guideLastName"`
	GuideTrustScore          int                              `json:"guideTrustScore"`
	PublishRiskScore         int                              `json:"publishRiskScore"`
	ModerationReasonCodes    []string                         `json:"moderationReasonCodes"`
	LandmarkName             *string                          `json:"landmarkName"`
	Itinerary                []excursionItineraryItemResponse `json:"itinerary"`
	DurationMinutes          int                              `json:"durationMinutes"`
	MaxGroupSize             int                              `json:"maxGroupSize"`
	LanguageCodes            []string                         `json:"languageCodes"`
	CountryCode              *string                          `json:"countryCode"`
	CityName                 *string                          `json:"cityName"`
	DepartureCityID          *string                          `json:"departureCityId"`
	MeetingPoint             string                           `json:"meetingPoint"`
	MeetingPointTranslations map[string]string                `json:"meetingPointTranslations"`
	PriceAmount              float64                          `json:"priceAmount"`
	Currency                 string                           `json:"currency"`
	IncludedItems            []string                         `json:"includedItems"`
	IncludedTranslations     map[string][]string              `json:"includedItemTranslations"`
	Revision                 int                              `json:"revision"`
	SubmittedForReviewAt     *string                          `json:"submittedForReviewAt"`
	CreatedAt                string                           `json:"createdAt"`
	UpdatedAt                string                           `json:"updatedAt"`
}

type excursionItineraryItemResponse struct {
	ID                        string                                `json:"id"`
	SortOrder                 int                                   `json:"sortOrder"`
	StartOffsetMinutes        int                                   `json:"startOffsetMinutes"`
	DurationMinutes           *int                                  `json:"durationMinutes"`
	AttractionID              *string                               `json:"attractionId"`
	AttractionName            *string                               `json:"attractionName"`
	TravelFromPreviousMinutes *int                                  `json:"travelFromPreviousMinutes"`
	Title                     string                                `json:"title"`
	Description               string                                `json:"description"`
	Translations              map[string]localizedItineraryResponse `json:"translations"`
}

type localizedCopyResponse struct {
	Title       string `json:"title"`
	Summary     string `json:"summary"`
	Description string `json:"description"`
}

type localizedItineraryResponse struct {
	Title       string `json:"title"`
	Description string `json:"description"`
}

func (r excursionResponse) toModel() model.ExcursionModerationItem {
	id, _ := uuid.Parse(r.ID)
	guideUserID, _ := uuid.Parse(r.GuideUserID)
	attractionNames := itineraryAttractionNames(r.Itinerary)
	attractionNamesByLocale := itineraryAttractionNamesByLocale(r.Itinerary)
	return model.ExcursionModerationItem{
		ID:                      id,
		Title:                   r.Title,
		Summary:                 r.Summary,
		Description:             r.Description,
		Translations:            localizedCopiesToModel(r.Translations),
		ProductTranslations:     localizedCopiesToModel(r.ProductTranslations),
		Status:                  r.Status,
		Visibility:              r.Visibility,
		GuideUserID:             guideUserID,
		GuideDisplayName:        r.GuideDisplayName,
		GuideNickname:           r.GuideNickname,
		GuideFirstName:          r.GuideFirstName,
		GuideLastName:           r.GuideLastName,
		GuideTrustScore:         r.GuideTrustScore,
		PublishRiskScore:        r.PublishRiskScore,
		ModerationReasonCodes:   r.ModerationReasonCodes,
		LandmarkName:            deref(r.LandmarkName),
		AttractionNames:         attractionNames,
		AttractionNamesByLocale: attractionNamesByLocale,
		StopCount:               len(r.Itinerary),
		DurationMinutes:         r.DurationMinutes,
		MaxGroupSize:            r.MaxGroupSize,
		LanguageCodes:           normalizedStringSlice(r.LanguageCodes),
		CountryCode:             deref(r.CountryCode),
		CityName:                deref(r.CityName),
		DepartureCityID:         deref(r.DepartureCityID),
		MeetingPoint:            strings.TrimSpace(r.MeetingPoint),
		MeetingPointByLocale:    localizedStringMapToModel(r.MeetingPointTranslations),
		PriceAmount:             r.PriceAmount,
		Currency:                r.Currency,
		IncludedItems:           normalizedStringSlice(r.IncludedItems),
		IncludedItemsByLocale:   localizedStringSlicesToModel(r.IncludedTranslations),
		Itinerary:               itineraryToModel(r.Itinerary),
		Revision:                r.Revision,
		SubmittedForReviewAt:    parseOptionalTime(r.SubmittedForReviewAt),
		CreatedAt:               parseTime(r.CreatedAt),
		UpdatedAt:               parseTime(r.UpdatedAt),
	}
}

func localizedCopiesToModel(items map[string]localizedCopyResponse) map[string]model.ExcursionLocalizedCopy {
	if len(items) == 0 {
		return nil
	}
	result := make(map[string]model.ExcursionLocalizedCopy, len(items))
	for locale, item := range items {
		locale = strings.ToLower(strings.TrimSpace(locale))
		if locale == "" {
			continue
		}
		result[locale] = model.ExcursionLocalizedCopy{
			Title:       strings.TrimSpace(item.Title),
			Summary:     strings.TrimSpace(item.Summary),
			Description: strings.TrimSpace(item.Description),
		}
	}
	if len(result) == 0 {
		return nil
	}
	return result
}

func localizedStringMapToModel(items map[string]string) map[string]string {
	if len(items) == 0 {
		return nil
	}
	result := make(map[string]string, len(items))
	for locale, value := range items {
		locale = strings.ToLower(strings.TrimSpace(locale))
		value = strings.TrimSpace(value)
		if locale == "" || value == "" {
			continue
		}
		result[locale] = value
	}
	if len(result) == 0 {
		return nil
	}
	return result
}

func localizedStringSlicesToModel(items map[string][]string) map[string][]string {
	if len(items) == 0 {
		return nil
	}
	result := make(map[string][]string, len(items))
	for locale, values := range items {
		locale = strings.ToLower(strings.TrimSpace(locale))
		if locale == "" {
			continue
		}
		if normalized := normalizedStringSlice(values); len(normalized) > 0 {
			result[locale] = normalized
		}
	}
	if len(result) == 0 {
		return nil
	}
	return result
}

func localizedItineraryCopiesToModel(items map[string]localizedItineraryResponse) map[string]model.ExcursionItineraryLocalizedCopy {
	if len(items) == 0 {
		return nil
	}
	result := make(map[string]model.ExcursionItineraryLocalizedCopy, len(items))
	for locale, item := range items {
		locale = strings.ToLower(strings.TrimSpace(locale))
		if locale == "" {
			continue
		}
		result[locale] = model.ExcursionItineraryLocalizedCopy{
			Title:       strings.TrimSpace(item.Title),
			Description: strings.TrimSpace(item.Description),
		}
	}
	if len(result) == 0 {
		return nil
	}
	return result
}

func itineraryToModel(items []excursionItineraryItemResponse) []model.ExcursionItineraryItem {
	if len(items) == 0 {
		return nil
	}
	result := make([]model.ExcursionItineraryItem, 0, len(items))
	for _, item := range items {
		id, _ := uuid.Parse(strings.TrimSpace(item.ID))
		var attractionID *uuid.UUID
		if item.AttractionID != nil {
			if parsed, err := uuid.Parse(strings.TrimSpace(*item.AttractionID)); err == nil {
				attractionID = &parsed
			}
		}
		result = append(result, model.ExcursionItineraryItem{
			ID:                        id,
			SortOrder:                 item.SortOrder,
			StartOffsetMinutes:        item.StartOffsetMinutes,
			DurationMinutes:           item.DurationMinutes,
			AttractionID:              attractionID,
			AttractionName:            deref(item.AttractionName),
			TravelFromPreviousMinutes: item.TravelFromPreviousMinutes,
			Title:                     strings.TrimSpace(item.Title),
			Description:               strings.TrimSpace(item.Description),
			Translations:              localizedItineraryCopiesToModel(item.Translations),
		})
	}
	return result
}

func itineraryAttractionNames(items []excursionItineraryItemResponse) []string {
	names := make([]string, 0, len(items))
	seen := make(map[string]struct{}, len(items))
	for _, item := range items {
		name := deref(item.AttractionName)
		if name == "" && item.AttractionID != nil {
			name = strings.TrimSpace(item.Title)
		}
		key := strings.ToLower(name)
		if key == "" {
			continue
		}
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		names = append(names, name)
	}
	return names
}

func itineraryAttractionNamesByLocale(items []excursionItineraryItemResponse) map[string][]string {
	result := make(map[string][]string)
	seen := make(map[string]map[string]struct{})
	for _, item := range items {
		for locale, translation := range item.Translations {
			locale = strings.ToLower(strings.TrimSpace(locale))
			name := strings.TrimSpace(translation.Title)
			if locale == "" || name == "" {
				continue
			}
			if _, ok := seen[locale]; !ok {
				seen[locale] = make(map[string]struct{})
			}
			key := strings.ToLower(name)
			if _, ok := seen[locale][key]; ok {
				continue
			}
			seen[locale][key] = struct{}{}
			result[locale] = append(result[locale], name)
		}
	}
	if len(result) == 0 {
		return nil
	}
	return result
}

func normalizedStringSlice(values []string) []string {
	result := make([]string, 0, len(values))
	seen := make(map[string]struct{}, len(values))
	for _, value := range values {
		value = strings.TrimSpace(value)
		key := strings.ToLower(value)
		if key == "" {
			continue
		}
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		result = append(result, value)
	}
	return result
}

func deref(value *string) string {
	if value == nil {
		return ""
	}
	return strings.TrimSpace(*value)
}

func parseOptionalTime(value *string) *time.Time {
	if value == nil || strings.TrimSpace(*value) == "" {
		return nil
	}
	parsed := parseTime(*value)
	if parsed.IsZero() {
		return nil
	}
	return &parsed
}

func parseTime(value string) time.Time {
	parsed, err := time.Parse(time.RFC3339, strings.TrimSpace(value))
	if err != nil {
		return time.Time{}
	}
	return parsed
}
