package post

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

func (c *Client) ListOpenReports(ctx context.Context, limit int, offset int) ([]model.PostReportModerationItem, error) {
	values := url.Values{}
	values.Set("status", "open")
	values.Set("limit", fmt.Sprintf("%d", limit))
	values.Set("offset", fmt.Sprintf("%d", offset))
	var resp postReportListResponse
	if err := c.doJSON(ctx, http.MethodGet, "/internal/v1/moderation/post-reports?"+values.Encode(), nil, nil, &resp); err != nil {
		return nil, err
	}
	items := make([]model.PostReportModerationItem, 0, len(resp.Items))
	for _, item := range resp.Items {
		items = append(items, item.toModel())
	}
	return items, nil
}

func (c *Client) ListPendingCommunityPosts(ctx context.Context, limit int, offset int) ([]model.PostModerationItem, error) {
	values := url.Values{}
	values.Set("limit", fmt.Sprintf("%d", limit))
	values.Set("offset", fmt.Sprintf("%d", offset))
	var resp postModerationListResponse
	if err := c.doJSON(ctx, http.MethodGet, "/internal/v1/moderation/community-posts?"+values.Encode(), nil, nil, &resp); err != nil {
		return nil, err
	}
	items := make([]model.PostModerationItem, 0, len(resp.Items))
	for _, item := range resp.Items {
		items = append(items, item.toModerationModel())
	}
	return items, nil
}

func (c *Client) GetReport(ctx context.Context, id uuid.UUID) (*model.PostReportModerationItem, error) {
	var resp postReportResponse
	if err := c.doJSON(ctx, http.MethodGet, "/internal/v1/moderation/post-reports/"+id.String(), nil, nil, &resp); err != nil {
		return nil, err
	}
	item := resp.toModel()
	return &item, nil
}

func (c *Client) GetCommunityPost(ctx context.Context, id uuid.UUID) (*model.PostModerationItem, error) {
	var resp postModerationResponse
	if err := c.doJSON(ctx, http.MethodGet, "/internal/v1/moderation/community-posts/"+id.String(), nil, nil, &resp); err != nil {
		return nil, err
	}
	item := resp.toModerationModel()
	return &item, nil
}

func (c *Client) ReviewReport(ctx context.Context, input port.PostReportDecisionInput) (*model.PostReportModerationItem, []byte, error) {
	headers := c.decisionHeaders(input)
	body := map[string]any{
		"resolutionNote": input.InternalComment,
	}
	var resp postReportResponse
	raw, err := c.doJSONRaw(ctx, http.MethodPost, "/internal/v1/moderation/post-reports/"+input.ReportID.String()+"/review", headers, body, &resp)
	if err != nil {
		return nil, nil, err
	}
	item := resp.toModel()
	return &item, raw, nil
}

func (c *Client) DismissReport(ctx context.Context, input port.PostReportDecisionInput) (*model.PostReportModerationItem, []byte, error) {
	headers := c.decisionHeaders(input)
	body := map[string]any{
		"resolutionNote": input.InternalComment,
	}
	var resp postReportResponse
	raw, err := c.doJSONRaw(ctx, http.MethodPost, "/internal/v1/moderation/post-reports/"+input.ReportID.String()+"/dismiss", headers, body, &resp)
	if err != nil {
		return nil, nil, err
	}
	item := resp.toModel()
	return &item, raw, nil
}

func (c *Client) ApproveCommunityPost(ctx context.Context, input port.CommunityPostDecisionInput) (*model.PostModerationItem, []byte, error) {
	return c.reviewCommunityPost(ctx, input, "approve")
}

func (c *Client) RejectCommunityPost(ctx context.Context, input port.CommunityPostDecisionInput) (*model.PostModerationItem, []byte, error) {
	return c.reviewCommunityPost(ctx, input, "reject")
}

func (c *Client) reviewCommunityPost(ctx context.Context, input port.CommunityPostDecisionInput, action string) (*model.PostModerationItem, []byte, error) {
	headers := c.decisionHeadersForStaff(input.ActorStaffID, input.IdempotencyKey, input.RequestID)
	body := map[string]any{
		"reason": input.InternalComment,
	}
	var resp postModerationResponse
	raw, err := c.doJSONRaw(ctx, http.MethodPost, "/internal/v1/moderation/community-posts/"+input.PostID.String()+"/"+action, headers, body, &resp)
	if err != nil {
		return nil, nil, err
	}
	item := resp.toModerationModel()
	return &item, raw, nil
}

func (c *Client) ListFeedQualityMetrics(ctx context.Context, filter model.FeedQualityMetricFilter) ([]model.FeedQualityMetric, error) {
	values := url.Values{}
	if !filter.Since.IsZero() {
		values.Set("since", filter.Since.UTC().Format(time.RFC3339))
	}
	if !filter.Until.IsZero() {
		values.Set("until", filter.Until.UTC().Format(time.RFC3339))
	}
	if strings.TrimSpace(filter.Surface) != "" {
		values.Set("surface", strings.TrimSpace(filter.Surface))
	}
	if filter.Limit > 0 {
		values.Set("limit", fmt.Sprintf("%d", filter.Limit))
	}

	path := "/internal/v1/feed/quality-metrics"
	if encoded := values.Encode(); encoded != "" {
		path += "?" + encoded
	}
	var resp feedQualityMetricsResponse
	if err := c.doJSON(ctx, http.MethodGet, path, nil, nil, &resp); err != nil {
		return nil, err
	}
	items := make([]model.FeedQualityMetric, 0, len(resp.Items))
	for _, item := range resp.Items {
		items = append(items, item.toModel())
	}
	return items, nil
}

func (c *Client) CreateCommunity(ctx context.Context, input port.CreateCommunityInput) (model.AdminCommunity, error) {
	headers := c.decisionHeadersForStaff(input.ActorStaffID, "", input.RequestID)
	body := createCommunityRequestFromCreateInput(input)
	var resp communityResponse
	if err := c.doJSON(ctx, http.MethodPost, "/internal/v1/communities", headers, body, &resp); err != nil {
		return model.AdminCommunity{}, err
	}
	return resp.toModel(), nil
}

func (c *Client) GetCommunity(ctx context.Context, id uuid.UUID) (model.AdminCommunity, error) {
	var resp communityResponse
	if err := c.doJSON(ctx, http.MethodGet, "/internal/v1/communities/"+id.String(), nil, nil, &resp); err != nil {
		return model.AdminCommunity{}, err
	}
	return resp.toModel(), nil
}

func (c *Client) UpdateCommunity(ctx context.Context, id uuid.UUID, input port.UpdateCommunityInput) (model.AdminCommunity, error) {
	headers := c.decisionHeadersForStaff(input.ActorStaffID, "", input.RequestID)
	body := createCommunityRequestFromUpdateInput(input)
	var resp communityResponse
	if err := c.doJSON(ctx, http.MethodPatch, "/internal/v1/communities/"+id.String(), headers, body, &resp); err != nil {
		return model.AdminCommunity{}, err
	}
	return resp.toModel(), nil
}

func (c *Client) CommunityPlatformCatalog(ctx context.Context, input port.CommunityPlatformCatalogInput) (model.CommunityPlatformCatalog, error) {
	values := communityCatalogQuery(input)

	var profilesResp communityPostProfileListResponse
	if err := c.doJSON(ctx, http.MethodGet, "/internal/v1/community-post-profiles?"+values.Encode(), nil, nil, &profilesResp); err != nil {
		return model.CommunityPlatformCatalog{}, err
	}

	blueprintsValues := cloneURLValues(values)
	if strings.TrimSpace(input.Search) != "" {
		blueprintsValues.Set("q", strings.TrimSpace(input.Search))
	}
	var blueprintsResp communityBlueprintListResponse
	if err := c.doJSON(ctx, http.MethodGet, "/internal/v1/community-blueprints?"+blueprintsValues.Encode(), nil, nil, &blueprintsResp); err != nil {
		return model.CommunityPlatformCatalog{}, err
	}

	hubsValues := cloneURLValues(values)
	hubsValues.Set("includeAliasOnly", "true")
	if country := strings.ToUpper(strings.TrimSpace(input.CountryCode)); country != "" {
		hubsValues.Set("countryCode", country)
	}
	var hubsResp communityGeoHubListResponse
	if err := c.doJSON(ctx, http.MethodGet, "/internal/v1/community-geo-hubs?"+hubsValues.Encode(), nil, nil, &hubsResp); err != nil {
		return model.CommunityPlatformCatalog{}, err
	}

	instancesValues := cloneURLValues(values)
	if country := strings.ToUpper(strings.TrimSpace(input.CountryCode)); country != "" {
		instancesValues.Set("countryCode", country)
	}
	if cityID := strings.TrimSpace(input.CityID); cityID != "" {
		instancesValues.Set("cityId", cityID)
	}
	if scopeType := strings.ToUpper(strings.TrimSpace(input.ScopeType)); scopeType != "" {
		instancesValues.Set("scopeType", scopeType)
	}
	if strings.TrimSpace(input.Search) != "" {
		instancesValues.Set("q", strings.TrimSpace(input.Search))
	}
	var instancesResp communityInstanceListResponse
	if err := c.doJSON(ctx, http.MethodGet, "/internal/v1/community-instances?"+instancesValues.Encode(), nil, nil, &instancesResp); err != nil {
		return model.CommunityPlatformCatalog{}, err
	}

	return model.CommunityPlatformCatalog{
		PostProfiles: profilesResp.toModel(),
		Blueprints:   blueprintsResp.toModel(),
		GeoHubs:      hubsResp.toModel(),
		Instances:    instancesResp.toModel(),
	}, nil
}

func (c *Client) MaterializeCommunityInstances(ctx context.Context, input port.MaterializeCommunityInstancesInput) (model.CommunityMaterializationResult, error) {
	headers := c.decisionHeadersForStaff(input.ActorStaffID, "", input.RequestID)
	body := materializeCommunityInstancesRequest{
		BlueprintID: uuidString(input.BlueprintID),
		CountryCode: strings.ToUpper(strings.TrimSpace(input.CountryCode)),
		CityID:      strings.TrimSpace(input.CityID),
		ScopeType:   strings.ToUpper(strings.TrimSpace(input.ScopeType)),
		Limit:       input.Limit,
	}
	var resp materializeCommunityInstancesResponse
	if err := c.doJSON(ctx, http.MethodPost, "/internal/v1/community-instances/materialize", headers, body, &resp); err != nil {
		return model.CommunityMaterializationResult{}, err
	}
	return model.CommunityMaterializationResult{MaterializedCount: resp.MaterializedCount}, nil
}

func (c *Client) decisionHeaders(input port.PostReportDecisionInput) map[string]string {
	return c.decisionHeadersForStaff(input.ActorStaffID, input.IdempotencyKey, input.RequestID)
}

func (c *Client) decisionHeadersForStaff(actorStaffID uuid.UUID, idempotencyKey string, requestID string) map[string]string {
	headers := map[string]string{
		"X-Auth-Subject":  "admin-panel:" + actorStaffID.String(),
		"X-User-Id":       actorStaffID.String(),
		"X-User-Roles":    "SUPER_ADMIN,MODERATION_LEAD",
		"Idempotency-Key": idempotencyKey,
	}
	if requestID != "" {
		headers["X-Request-Id"] = requestID
	}
	return headers
}

type feedQualityMetricsResponse struct {
	Items []feedQualityMetricResponse `json:"items"`
}

type createCommunityRequest struct {
	Slug            string              `json:"slug"`
	TitleI18n       map[string]string   `json:"titleI18n"`
	DescriptionI18n map[string]string   `json:"descriptionI18n"`
	RulesI18n       map[string][]string `json:"rulesI18n"`
	Topic           string              `json:"topic,omitempty"`
	CityID          *string             `json:"cityId,omitempty"`
	CountryCode     *string             `json:"countryCode,omitempty"`
	AvatarFileID    *string             `json:"avatarFileId,omitempty"`
	CoverFileID     *string             `json:"coverFileId,omitempty"`
	Visibility      string              `json:"visibility,omitempty"`
	PostingPolicy   string              `json:"postingPolicy,omitempty"`
	Status          string              `json:"status,omitempty"`
}

func createCommunityRequestFromCreateInput(input port.CreateCommunityInput) createCommunityRequest {
	return createCommunityRequest{
		Slug:            strings.TrimSpace(input.Slug),
		TitleI18n:       cloneStringMap(input.TitleI18n),
		DescriptionI18n: cloneStringMap(input.DescriptionI18n),
		RulesI18n:       cloneStringSliceMap(input.RulesI18n),
		Topic:           strings.ToUpper(strings.TrimSpace(input.Topic)),
		CityID:          cloneStringPtr(input.CityID),
		CountryCode:     cloneStringPtr(input.CountryCode),
		AvatarFileID:    uuidPtrString(input.AvatarFileID),
		CoverFileID:     uuidPtrString(input.CoverFileID),
		Visibility:      strings.ToUpper(strings.TrimSpace(input.Visibility)),
		PostingPolicy:   strings.ToUpper(strings.TrimSpace(input.PostingPolicy)),
		Status:          strings.ToUpper(strings.TrimSpace(input.Status)),
	}
}

func createCommunityRequestFromUpdateInput(input port.UpdateCommunityInput) createCommunityRequest {
	return createCommunityRequest{
		Slug:            strings.TrimSpace(input.Slug),
		TitleI18n:       cloneStringMap(input.TitleI18n),
		DescriptionI18n: cloneStringMap(input.DescriptionI18n),
		RulesI18n:       cloneStringSliceMap(input.RulesI18n),
		Topic:           strings.ToUpper(strings.TrimSpace(input.Topic)),
		CityID:          cloneStringPtr(input.CityID),
		CountryCode:     cloneStringPtr(input.CountryCode),
		AvatarFileID:    uuidPtrString(input.AvatarFileID),
		CoverFileID:     uuidPtrString(input.CoverFileID),
		Visibility:      strings.ToUpper(strings.TrimSpace(input.Visibility)),
		PostingPolicy:   strings.ToUpper(strings.TrimSpace(input.PostingPolicy)),
		Status:          strings.ToUpper(strings.TrimSpace(input.Status)),
	}
}

type materializeCommunityInstancesRequest struct {
	BlueprintID string `json:"blueprintId,omitempty"`
	CountryCode string `json:"countryCode,omitempty"`
	CityID      string `json:"cityId,omitempty"`
	ScopeType   string `json:"scopeType,omitempty"`
	Limit       int    `json:"limit,omitempty"`
}

type materializeCommunityInstancesResponse struct {
	MaterializedCount int `json:"materializedCount"`
}

type communityResponse struct {
	ID              string              `json:"id"`
	Slug            string              `json:"slug"`
	Title           string              `json:"title"`
	TitleI18n       map[string]string   `json:"titleI18n"`
	Description     string              `json:"description"`
	DescriptionI18n map[string]string   `json:"descriptionI18n"`
	Rules           []string            `json:"rules"`
	RulesI18n       map[string][]string `json:"rulesI18n"`
	Topic           string              `json:"topic"`
	CityID          *string             `json:"cityId"`
	CountryCode     *string             `json:"countryCode"`
	AvatarFileID    *string             `json:"avatarFileId"`
	CoverFileID     *string             `json:"coverFileId"`
	Visibility      string              `json:"visibility"`
	PostingPolicy   string              `json:"postingPolicy"`
	Status          string              `json:"status"`
	MembersCount    int                 `json:"membersCount"`
	PostCount       int                 `json:"postCount"`
	CreatedAt       string              `json:"createdAt"`
	UpdatedAt       string              `json:"updatedAt"`
}

type communityPostProfileListResponse struct {
	Items []communityPostProfileResponse `json:"items"`
}

type communityPostProfileResponse struct {
	Key                  string `json:"key"`
	Version              int    `json:"version"`
	PostKind             string `json:"postKind"`
	ComposerPreset       string `json:"composerPreset"`
	RenderPreset         string `json:"renderPreset"`
	ModerationMode       string `json:"moderationMode"`
	ActivityCreationMode string `json:"activityCreationMode"`
	CreatedAt            string `json:"createdAt"`
	UpdatedAt            string `json:"updatedAt"`
}

func (r communityPostProfileListResponse) toModel() []model.CommunityPostProfile {
	items := make([]model.CommunityPostProfile, 0, len(r.Items))
	for _, item := range r.Items {
		items = append(items, item.toModel())
	}
	return items
}

func (r communityPostProfileResponse) toModel() model.CommunityPostProfile {
	return model.CommunityPostProfile{
		Key:                  strings.TrimSpace(r.Key),
		Version:              r.Version,
		PostKind:             strings.ToUpper(strings.TrimSpace(r.PostKind)),
		ComposerPreset:       strings.TrimSpace(r.ComposerPreset),
		RenderPreset:         strings.TrimSpace(r.RenderPreset),
		ModerationMode:       strings.ToUpper(strings.TrimSpace(r.ModerationMode)),
		ActivityCreationMode: strings.ToUpper(strings.TrimSpace(r.ActivityCreationMode)),
		CreatedAt:            parseTime(r.CreatedAt),
		UpdatedAt:            parseTime(r.UpdatedAt),
	}
}

type communityBlueprintListResponse struct {
	Items []communityBlueprintResponse `json:"items"`
}

type communityBlueprintResponse struct {
	ID                     string              `json:"id"`
	Key                    string              `json:"key"`
	Category               string              `json:"category"`
	DefaultPostProfileKey  string              `json:"defaultPostProfileKey"`
	AllowedPostProfileKeys []string            `json:"allowedPostProfileKeys"`
	EnabledTabs            []string            `json:"enabledTabs"`
	SubcategoryKeys        []string            `json:"subcategoryKeys"`
	PromotionSegmentKeys   []string            `json:"promotionSegmentKeys"`
	TitleI18n              map[string]string   `json:"titleI18n"`
	DescriptionI18n        map[string]string   `json:"descriptionI18n"`
	RulesI18n              map[string][]string `json:"rulesI18n"`
	IconKey                string              `json:"iconKey"`
	RolloutPolicy          string              `json:"rolloutPolicy"`
	AllowedScopeTypes      []string            `json:"allowedScopeTypes"`
	DefaultModerationMode  string              `json:"defaultModerationMode"`
	Status                 string              `json:"status"`
	CreatedAt              string              `json:"createdAt"`
	UpdatedAt              string              `json:"updatedAt"`
}

func (r communityBlueprintListResponse) toModel() []model.CommunityBlueprint {
	items := make([]model.CommunityBlueprint, 0, len(r.Items))
	for _, item := range r.Items {
		items = append(items, item.toModel())
	}
	return items
}

func (r communityBlueprintResponse) toModel() model.CommunityBlueprint {
	id, _ := uuid.Parse(strings.TrimSpace(r.ID))
	return model.CommunityBlueprint{
		ID:                     id,
		Key:                    strings.TrimSpace(r.Key),
		Category:               strings.TrimSpace(r.Category),
		DefaultPostProfileKey:  strings.TrimSpace(r.DefaultPostProfileKey),
		AllowedPostProfileKeys: cloneStringSlice(r.AllowedPostProfileKeys),
		EnabledTabs:            cloneStringSlice(r.EnabledTabs),
		SubcategoryKeys:        cloneStringSlice(r.SubcategoryKeys),
		PromotionSegmentKeys:   cloneStringSlice(r.PromotionSegmentKeys),
		TitleI18n:              cloneStringMap(r.TitleI18n),
		DescriptionI18n:        cloneStringMap(r.DescriptionI18n),
		RulesI18n:              cloneStringSliceMap(r.RulesI18n),
		IconKey:                strings.TrimSpace(r.IconKey),
		RolloutPolicy:          strings.ToUpper(strings.TrimSpace(r.RolloutPolicy)),
		AllowedScopeTypes:      cloneStringSliceUpper(r.AllowedScopeTypes),
		DefaultModerationMode:  strings.ToUpper(strings.TrimSpace(r.DefaultModerationMode)),
		Status:                 strings.ToUpper(strings.TrimSpace(r.Status)),
		CreatedAt:              parseTime(r.CreatedAt),
		UpdatedAt:              parseTime(r.UpdatedAt),
	}
}

type communityGeoHubListResponse struct {
	Items []communityGeoHubResponse `json:"items"`
}

type communityGeoHubResponse struct {
	CountryCode       string  `json:"countryCode"`
	CityID            string  `json:"cityId"`
	HubTier           string  `json:"hubTier"`
	CommunityEnabled  bool    `json:"communityEnabled"`
	ParentCountryCode *string `json:"parentCountryCode"`
	ParentCityID      *string `json:"parentCityId"`
	Reason            string  `json:"reason"`
	Priority          int     `json:"priority"`
	CanMaterialize    bool    `json:"canMaterialize"`
	EffectiveCountry  string  `json:"effectiveCountryCode"`
	EffectiveCityID   string  `json:"effectiveCityId"`
	CreatedBy         string  `json:"createdBy"`
	UpdatedAt         string  `json:"updatedAt"`
}

func (r communityGeoHubListResponse) toModel() []model.CommunityGeoHub {
	items := make([]model.CommunityGeoHub, 0, len(r.Items))
	for _, item := range r.Items {
		items = append(items, item.toModel())
	}
	return items
}

func (r communityGeoHubResponse) toModel() model.CommunityGeoHub {
	return model.CommunityGeoHub{
		CountryCode:       strings.ToUpper(strings.TrimSpace(r.CountryCode)),
		CityID:            strings.TrimSpace(r.CityID),
		HubTier:           strings.ToUpper(strings.TrimSpace(r.HubTier)),
		CommunityEnabled:  r.CommunityEnabled,
		ParentCountryCode: cloneStringPtr(r.ParentCountryCode),
		ParentCityID:      cloneStringPtr(r.ParentCityID),
		Reason:            strings.TrimSpace(r.Reason),
		Priority:          r.Priority,
		CanMaterialize:    r.CanMaterialize,
		EffectiveCountry:  strings.ToUpper(strings.TrimSpace(r.EffectiveCountry)),
		EffectiveCityID:   strings.TrimSpace(r.EffectiveCityID),
		CreatedBy:         strings.TrimSpace(r.CreatedBy),
		UpdatedAt:         parseTime(r.UpdatedAt),
	}
}

type communityInstanceListResponse struct {
	Items []communityInstanceResponse `json:"items"`
}

type communityInstanceResponse struct {
	ID              string              `json:"id"`
	CommunityID     *string             `json:"communityId"`
	BlueprintID     string              `json:"blueprintId"`
	Slug            string              `json:"slug"`
	CountryCode     string              `json:"countryCode"`
	CityID          *string             `json:"cityId"`
	ScopeType       string              `json:"scopeType"`
	TitleI18n       map[string]string   `json:"titleI18n"`
	DescriptionI18n map[string]string   `json:"descriptionI18n"`
	RulesI18n       map[string][]string `json:"rulesI18n"`
	Status          string              `json:"status"`
	MemberCount     int                 `json:"memberCount"`
	PostCount       int                 `json:"postCount"`
	CreatedAt       string              `json:"createdAt"`
	UpdatedAt       string              `json:"updatedAt"`
}

func (r communityInstanceListResponse) toModel() []model.CommunityInstance {
	items := make([]model.CommunityInstance, 0, len(r.Items))
	for _, item := range r.Items {
		items = append(items, item.toModel())
	}
	return items
}

func (r communityInstanceResponse) toModel() model.CommunityInstance {
	id, _ := uuid.Parse(strings.TrimSpace(r.ID))
	blueprintID, _ := uuid.Parse(strings.TrimSpace(r.BlueprintID))
	return model.CommunityInstance{
		ID:              id,
		CommunityID:     parseOptionalUUID(r.CommunityID),
		BlueprintID:     blueprintID,
		Slug:            strings.TrimSpace(r.Slug),
		CountryCode:     strings.ToUpper(strings.TrimSpace(r.CountryCode)),
		CityID:          cloneStringPtr(r.CityID),
		ScopeType:       strings.ToUpper(strings.TrimSpace(r.ScopeType)),
		TitleI18n:       cloneStringMap(r.TitleI18n),
		DescriptionI18n: cloneStringMap(r.DescriptionI18n),
		RulesI18n:       cloneStringSliceMap(r.RulesI18n),
		Status:          strings.ToUpper(strings.TrimSpace(r.Status)),
		MemberCount:     r.MemberCount,
		PostCount:       r.PostCount,
		CreatedAt:       parseTime(r.CreatedAt),
		UpdatedAt:       parseTime(r.UpdatedAt),
	}
}

func (r communityResponse) toModel() model.AdminCommunity {
	id, _ := uuid.Parse(strings.TrimSpace(r.ID))
	return model.AdminCommunity{
		ID:              id,
		Slug:            strings.TrimSpace(r.Slug),
		Title:           strings.TrimSpace(r.Title),
		TitleI18n:       cloneStringMap(r.TitleI18n),
		Description:     strings.TrimSpace(r.Description),
		DescriptionI18n: cloneStringMap(r.DescriptionI18n),
		Rules:           cloneStringSlice(r.Rules),
		RulesI18n:       cloneStringSliceMap(r.RulesI18n),
		Topic:           strings.ToUpper(strings.TrimSpace(r.Topic)),
		CityID:          cloneStringPtr(r.CityID),
		CountryCode:     cloneStringPtr(r.CountryCode),
		AvatarFileID:    parseOptionalUUID(r.AvatarFileID),
		CoverFileID:     parseOptionalUUID(r.CoverFileID),
		Visibility:      strings.ToUpper(strings.TrimSpace(r.Visibility)),
		PostingPolicy:   strings.ToUpper(strings.TrimSpace(r.PostingPolicy)),
		Status:          strings.ToUpper(strings.TrimSpace(r.Status)),
		MembersCount:    r.MembersCount,
		PostCount:       r.PostCount,
		CreatedAt:       parseTime(r.CreatedAt),
		UpdatedAt:       parseTime(r.UpdatedAt),
	}
}

type feedQualityMetricResponse struct {
	Surface            string `json:"surface"`
	BlockType          string `json:"blockType"`
	Action             string `json:"action"`
	EventCount         int64  `json:"eventCount"`
	UniqueViewers      int64  `json:"uniqueViewers"`
	ConversionCount    int64  `json:"conversionCount"`
	HideCount          int64  `json:"hideCount"`
	NotInterestedCount int64  `json:"notInterestedCount"`
}

func (r feedQualityMetricResponse) toModel() model.FeedQualityMetric {
	return model.FeedQualityMetric{
		Surface:            strings.TrimSpace(r.Surface),
		BlockType:          strings.TrimSpace(r.BlockType),
		Action:             strings.TrimSpace(r.Action),
		EventCount:         r.EventCount,
		UniqueViewers:      r.UniqueViewers,
		ConversionCount:    r.ConversionCount,
		HideCount:          r.HideCount,
		NotInterestedCount: r.NotInterestedCount,
	}
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
		return nil, fmt.Errorf("feed-service %s %s returned %d: %s", method, path, resp.StatusCode, strings.TrimSpace(string(raw)))
	}
	if dest != nil {
		if err = json.Unmarshal(raw, dest); err != nil {
			return nil, err
		}
	}
	return raw, nil
}

type postReportListResponse struct {
	Items []postReportResponse `json:"items"`
}

type postModerationListResponse struct {
	Items []postModerationResponse `json:"items"`
}

type postModerationResponse struct {
	ID               string  `json:"id"`
	Title            string  `json:"title"`
	Excerpt          string  `json:"excerpt"`
	Status           string  `json:"status"`
	ModerationStatus string  `json:"moderationStatus"`
	CommunityID      *string `json:"communityId"`
	Category         string  `json:"category"`
	Revision         int64   `json:"revision"`
	Author           struct {
		UserID string `json:"userId"`
	} `json:"author"`
	CreatedAt string `json:"createdAt"`
	UpdatedAt string `json:"updatedAt"`
}

func (r postModerationResponse) toModerationModel() model.PostModerationItem {
	id, _ := uuid.Parse(r.ID)
	authorUserID, _ := uuid.Parse(r.Author.UserID)
	revision := int(r.Revision)
	if revision <= 0 {
		revision = 1
	}
	return model.PostModerationItem{
		ID:                    id,
		CommunityID:           parseOptionalUUID(r.CommunityID),
		AuthorUserID:          authorUserID,
		Title:                 strings.TrimSpace(r.Title),
		Excerpt:               strings.TrimSpace(r.Excerpt),
		Status:                strings.ToUpper(strings.TrimSpace(r.Status)),
		ModerationStatus:      strings.ToUpper(strings.TrimSpace(r.ModerationStatus)),
		Category:              strings.ToUpper(strings.TrimSpace(r.Category)),
		ModerationRiskScore:   postModerationRiskScore(r),
		ModerationReasonCodes: postModerationReasonCodes(r),
		Revision:              revision,
		CreatedAt:             parseTime(r.CreatedAt),
		UpdatedAt:             parseTime(r.UpdatedAt),
	}
}

type postReportResponse struct {
	ID               string  `json:"id"`
	PostID           string  `json:"postId"`
	CommunityID      *string `json:"communityId"`
	ReporterUserID   string  `json:"reporterUserId"`
	AuthorUserID     string  `json:"authorUserId"`
	Reason           string  `json:"reason"`
	Details          string  `json:"details"`
	Status           string  `json:"status"`
	ResolvedByUserID *string `json:"resolvedByUserId"`
	ResolutionNote   string  `json:"resolutionNote"`
	CreatedAt        string  `json:"createdAt"`
	UpdatedAt        string  `json:"updatedAt"`
	ResolvedAt       *string `json:"resolvedAt"`
}

func postModerationRiskScore(r postModerationResponse) int {
	title := strings.ToLower(strings.TrimSpace(r.Title + " " + r.Excerpt))
	switch {
	case strings.Contains(title, "spam"), strings.Contains(title, "casino"), strings.Contains(title, "crypto"):
		return 70
	default:
		return 35
	}
}

func postModerationReasonCodes(r postModerationResponse) []string {
	reasons := []string{"COMMUNITY_POST_REVIEW"}
	if strings.TrimSpace(r.CommunityIDValue()) != "" {
		reasons = append(reasons, "COMMUNITY_SCOPED")
	}
	return reasons
}

func (r postModerationResponse) CommunityIDValue() string {
	if r.CommunityID == nil {
		return ""
	}
	return *r.CommunityID
}

func (r postReportResponse) toModel() model.PostReportModerationItem {
	id, _ := uuid.Parse(r.ID)
	postID, _ := uuid.Parse(r.PostID)
	reporterUserID, _ := uuid.Parse(r.ReporterUserID)
	authorUserID, _ := uuid.Parse(r.AuthorUserID)
	reason := strings.ToUpper(strings.TrimSpace(r.Reason))
	return model.PostReportModerationItem{
		ID:                    id,
		PostID:                postID,
		CommunityID:           parseOptionalUUID(r.CommunityID),
		ReporterUserID:        reporterUserID,
		AuthorUserID:          authorUserID,
		Reason:                reason,
		Details:               r.Details,
		Status:                strings.ToUpper(strings.TrimSpace(r.Status)),
		ResolvedByUserID:      parseOptionalUUID(r.ResolvedByUserID),
		ResolutionNote:        r.ResolutionNote,
		ModerationRiskScore:   postReportRiskScore(reason),
		ModerationReasonCodes: postReportReasonCodes(reason),
		Revision:              1,
		CreatedAt:             parseTime(r.CreatedAt),
		UpdatedAt:             parseTime(r.UpdatedAt),
		ResolvedAt:            parseOptionalTime(r.ResolvedAt),
	}
}

func postReportRiskScore(reason string) int {
	switch strings.ToUpper(strings.TrimSpace(reason)) {
	case "ILLEGAL", "VIOLENCE", "HATE", "SEXUAL_CONTENT":
		return 90
	case "HARASSMENT", "MISINFORMATION":
		return 70
	case "SPAM":
		return 40
	default:
		return 30
	}
}

func postReportReasonCodes(reason string) []string {
	reason = strings.ToLower(strings.TrimSpace(reason))
	if reason == "" {
		return nil
	}
	return []string{reason}
}

func communityCatalogQuery(input port.CommunityPlatformCatalogInput) url.Values {
	values := url.Values{}
	if input.Limit > 0 {
		values.Set("limit", fmt.Sprintf("%d", input.Limit))
	}
	if input.Offset > 0 {
		values.Set("offset", fmt.Sprintf("%d", input.Offset))
	}
	return values
}

func cloneURLValues(input url.Values) url.Values {
	out := url.Values{}
	for key, values := range input {
		out[key] = append([]string(nil), values...)
	}
	return out
}

func uuidString(input uuid.UUID) string {
	if input == uuid.Nil {
		return ""
	}
	return input.String()
}

func parseOptionalUUID(value *string) *uuid.UUID {
	if value == nil {
		return nil
	}
	parsed, err := uuid.Parse(strings.TrimSpace(*value))
	if err != nil {
		return nil
	}
	return &parsed
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

func cloneStringMap(input map[string]string) map[string]string {
	if len(input) == 0 {
		return nil
	}
	out := make(map[string]string, len(input))
	for key, value := range input {
		key = strings.TrimSpace(key)
		value = strings.TrimSpace(value)
		if key != "" && value != "" {
			out[key] = value
		}
	}
	return out
}

func cloneStringSliceMap(input map[string][]string) map[string][]string {
	if len(input) == 0 {
		return nil
	}
	out := make(map[string][]string, len(input))
	for key, values := range input {
		key = strings.TrimSpace(key)
		if key == "" {
			continue
		}
		cloned := cloneStringSlice(values)
		if len(cloned) > 0 {
			out[key] = cloned
		}
	}
	return out
}

func cloneStringSlice(input []string) []string {
	if len(input) == 0 {
		return nil
	}
	out := make([]string, 0, len(input))
	for _, value := range input {
		if trimmed := strings.TrimSpace(value); trimmed != "" {
			out = append(out, trimmed)
		}
	}
	return out
}

func cloneStringSliceUpper(input []string) []string {
	if len(input) == 0 {
		return nil
	}
	out := make([]string, 0, len(input))
	for _, value := range input {
		if trimmed := strings.ToUpper(strings.TrimSpace(value)); trimmed != "" {
			out = append(out, trimmed)
		}
	}
	return out
}

func cloneStringPtr(input *string) *string {
	if input == nil {
		return nil
	}
	trimmed := strings.TrimSpace(*input)
	if trimmed == "" {
		return nil
	}
	return &trimmed
}

func uuidPtrString(input *uuid.UUID) *string {
	if input == nil || *input == uuid.Nil {
		return nil
	}
	value := input.String()
	return &value
}
