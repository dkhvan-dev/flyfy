package featureflag

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"

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

func (c *Client) ListDomains(ctx context.Context, filter model.OperationDomainFilter) (model.OperationDomainPage, error) {
	values := domainQuery(filter)
	var resp pageResponse[domainResponse]
	if err := c.doJSON(ctx, http.MethodGet, "/api/v1/dict/teams?"+values.Encode(), nil, nil, &resp); err != nil {
		return model.OperationDomainPage{}, err
	}
	items := make([]model.OperationDomain, 0, len(resp.Content))
	for _, item := range resp.Content {
		items = append(items, item.toModel())
	}
	return model.OperationDomainPage{
		Content:       items,
		Page:          resp.Page,
		Size:          resp.Size,
		TotalElements: resp.TotalElements,
		TotalPages:    resp.TotalPages,
	}, nil
}

func (c *Client) FindDomain(ctx context.Context, code string) (*model.OperationDomain, error) {
	code = strings.ToUpper(strings.TrimSpace(code))
	if code == "" {
		return nil, nil
	}
	page, err := c.ListDomains(ctx, model.OperationDomainFilter{Search: code, Size: 100})
	if err != nil {
		return nil, err
	}
	for _, item := range page.Content {
		if strings.EqualFold(item.Code, code) {
			copy := item
			return &copy, nil
		}
	}
	return nil, nil
}

func (c *Client) UpsertDomain(ctx context.Context, input model.OperationDomainInput) (model.OperationDomain, error) {
	body := domainRequest{
		Code:        strings.ToUpper(strings.TrimSpace(input.Code)),
		Description: strings.TrimSpace(input.Description),
	}
	headers := actorHeaders(input.Actor, input.RequestID)
	path := "/api/v1/dict/teams"
	method := http.MethodPost
	if input.FeatureFlagServiceID > 0 {
		method = http.MethodPut
		path += "/" + strconv.FormatInt(input.FeatureFlagServiceID, 10)
	}
	var resp domainResponse
	if err := c.doJSON(ctx, method, path, headers, body, &resp); err != nil {
		return model.OperationDomain{}, err
	}
	return resp.toModel(), nil
}

func (c *Client) ListFeatureFlags(ctx context.Context, filter model.OperationFeatureFlagFilter) (model.OperationPage[model.OperationFeatureFlag], error) {
	values := url.Values{}
	setInt(values, "page", filter.Page)
	setInt(values, "size", filter.Size)
	setQuery(values, "orderBy", filter.OrderBy)
	setQuery(values, "direction", filter.Direction)
	setQuery(values, "domainCode", strings.ToUpper(strings.TrimSpace(filter.DomainCode)))
	setQuery(values, "group", filter.Group)
	setQuery(values, "search", filter.Search)
	setTime(values, "actionStartDate", filter.ActionStartDate)
	setTime(values, "actionEndDate", filter.ActionEndDate)
	values.Set("inArchive", strconv.FormatBool(filter.InArchive))

	var resp pageResponse[featureFlagResponse]
	if err := c.doJSON(ctx, http.MethodGet, "/api/v1/feature-flags?"+values.Encode(), nil, nil, &resp); err != nil {
		return model.OperationPage[model.OperationFeatureFlag]{}, err
	}
	items := make([]model.OperationFeatureFlag, 0, len(resp.Content))
	for _, item := range resp.Content {
		items = append(items, item.toModel(filter.DomainCode))
	}
	return model.OperationPage[model.OperationFeatureFlag]{
		Content:       items,
		Page:          resp.Page,
		Size:          resp.Size,
		TotalElements: resp.TotalElements,
		TotalPages:    resp.TotalPages,
		NextCursor:    resp.NextCursor,
	}, nil
}

func (c *Client) GetFeatureFlag(ctx context.Context, domainCode string, code string) (model.OperationFeatureFlag, error) {
	values := url.Values{}
	setQuery(values, "domainCode", strings.ToUpper(strings.TrimSpace(domainCode)))
	var resp featureFlagResponse
	if err := c.doJSON(ctx, http.MethodGet, "/api/v1/feature-flags/"+url.PathEscape(strings.ToUpper(strings.TrimSpace(code)))+"?"+values.Encode(), nil, nil, &resp); err != nil {
		return model.OperationFeatureFlag{}, err
	}
	return resp.toModel(domainCode), nil
}

func (c *Client) UpsertFeatureFlag(ctx context.Context, input model.OperationFeatureFlagInput) (model.OperationFeatureFlag, error) {
	body := featureFlagRequest{
		DomainCode:      strings.ToUpper(strings.TrimSpace(input.DomainCode)),
		Code:            strings.ToUpper(strings.TrimSpace(input.Code)),
		Name:            strings.TrimSpace(input.Name),
		Group:           strings.TrimSpace(input.Group),
		Type:            strings.ToUpper(strings.TrimSpace(input.Type)),
		ActionStartDate: input.ActionStartDate,
		ActionEndDate:   input.ActionEndDate,
		Enabled:         input.Enabled,
		Value:           input.Value,
	}
	headers := actorHeaders(input.Actor, input.RequestID)
	path := "/api/v1/feature-flags"
	method := http.MethodPost
	if strings.TrimSpace(input.ExistingCode) != "" {
		method = http.MethodPut
		path += "/" + url.PathEscape(strings.ToUpper(strings.TrimSpace(input.ExistingCode)))
	}
	var resp featureFlagResponse
	if err := c.doJSON(ctx, method, path, headers, body, &resp); err != nil {
		return model.OperationFeatureFlag{}, err
	}
	return resp.toModel(input.DomainCode), nil
}

func (c *Client) ArchiveFeatureFlag(ctx context.Context, domainCode string, code string) error {
	values := url.Values{}
	setQuery(values, "domainCode", strings.ToUpper(strings.TrimSpace(domainCode)))
	return c.doJSON(ctx, http.MethodDelete, "/api/v1/feature-flags/"+url.PathEscape(strings.ToUpper(strings.TrimSpace(code)))+"?"+values.Encode(), nil, nil, nil)
}

func (c *Client) RecoverFeatureFlag(ctx context.Context, domainCode string, code string) (model.OperationFeatureFlag, error) {
	values := url.Values{}
	setQuery(values, "domainCode", strings.ToUpper(strings.TrimSpace(domainCode)))
	var resp featureFlagResponse
	if err := c.doJSON(ctx, http.MethodPatch, "/api/v1/feature-flags/"+url.PathEscape(strings.ToUpper(strings.TrimSpace(code)))+"/recover?"+values.Encode(), nil, nil, &resp); err != nil {
		return model.OperationFeatureFlag{}, err
	}
	return resp.toModel(domainCode), nil
}

func (c *Client) ListFeatureFlagHistory(ctx context.Context, filter model.OperationFeatureFlagHistoryFilter) (model.OperationPage[model.OperationFeatureFlagHistory], error) {
	values := url.Values{}
	setInt(values, "page", filter.Page)
	setInt(values, "size", filter.Size)
	setQuery(values, "orderBy", filter.OrderBy)
	setQuery(values, "direction", filter.Direction)
	setQuery(values, "domainCode", strings.ToUpper(strings.TrimSpace(filter.DomainCode)))
	setQuery(values, "code", strings.ToUpper(strings.TrimSpace(filter.Code)))
	setQuery(values, "featureFlagType", strings.ToUpper(strings.TrimSpace(filter.Type)))
	setQuery(values, "cursor", filter.Cursor)
	var resp pageResponse[featureFlagHistoryResponse]
	if err := c.doJSON(ctx, http.MethodGet, "/api/v1/feature-flags/history?"+values.Encode(), nil, nil, &resp); err != nil {
		return model.OperationPage[model.OperationFeatureFlagHistory]{}, err
	}
	items := make([]model.OperationFeatureFlagHistory, 0, len(resp.Content))
	for _, item := range resp.Content {
		items = append(items, item.toModel())
	}
	return model.OperationPage[model.OperationFeatureFlagHistory]{
		Content:       items,
		Page:          resp.Page,
		Size:          resp.Size,
		TotalElements: resp.TotalElements,
		TotalPages:    resp.TotalPages,
		NextCursor:    resp.NextCursor,
	}, nil
}

func (c *Client) doJSON(ctx context.Context, method string, path string, headers map[string]string, body any, dest any) error {
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
	req.Header.Set("Accept", "application/json")
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	if c.internalToken != "" {
		req.Header.Set("Authorization", "Bearer "+c.internalToken)
		req.Header.Set("X-Internal-Service-Token", c.internalToken)
		req.Header.Set("X-Internal-Service", "admin-panel")
		req.Header.Set("X-User-Roles", "SUPER_ADMIN,ADMIN")
	}
	for key, value := range headers {
		if strings.TrimSpace(value) != "" {
			req.Header.Set(key, value)
		}
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
		return fmt.Errorf("feature-flag-service %s %s returned %d: %s", method, path, resp.StatusCode, strings.TrimSpace(string(raw)))
	}
	if dest != nil && len(raw) > 0 {
		if err = json.Unmarshal(raw, dest); err != nil {
			return err
		}
	}
	return nil
}

type pageResponse[T any] struct {
	Content       []T    `json:"content"`
	Page          int    `json:"page"`
	Size          int    `json:"size"`
	TotalElements int64  `json:"totalElements"`
	TotalPages    int    `json:"totalPages"`
	NextCursor    string `json:"nextCursor"`
}

type domainRequest struct {
	Code        string `json:"code"`
	Description string `json:"description"`
}

type domainResponse struct {
	ID                int64      `json:"id"`
	CreatedAt         time.Time  `json:"createdAt"`
	CreatedBy         string     `json:"createdBy"`
	UpdatedAt         *time.Time `json:"updatedAt"`
	UpdatedBy         string     `json:"updatedBy"`
	Code              string     `json:"code"`
	Description       string     `json:"description"`
	FeatureFlagGroups []string   `json:"featureFlagGroups"`
}

func (r domainResponse) toModel() model.OperationDomain {
	return model.OperationDomain{
		FeatureFlagServiceID: r.ID,
		Code:                 strings.ToUpper(strings.TrimSpace(r.Code)),
		Description:          strings.TrimSpace(r.Description),
		CreatedAt:            r.CreatedAt,
		CreatedBy:            r.CreatedBy,
		UpdatedAt:            r.UpdatedAt,
		UpdatedBy:            r.UpdatedBy,
		FeatureFlagGroups:    append([]string(nil), r.FeatureFlagGroups...),
	}
}

type featureFlagRequest struct {
	DomainCode      string     `json:"domainCode"`
	Code            string     `json:"code,omitempty"`
	Name            string     `json:"name"`
	Group           string     `json:"group"`
	Type            string     `json:"type"`
	ActionStartDate time.Time  `json:"actionStartDate"`
	ActionEndDate   *time.Time `json:"actionEndDate"`
	Enabled         bool       `json:"enabled"`
	Value           []any      `json:"value"`
}

type featureFlagResponse struct {
	Code            string     `json:"code"`
	CreatedAt       time.Time  `json:"createdAt"`
	CreatedBy       string     `json:"createdBy"`
	UpdatedAt       *time.Time `json:"updatedAt"`
	UpdatedBy       string     `json:"updatedBy"`
	Name            string     `json:"name"`
	Group           string     `json:"group"`
	Type            string     `json:"type"`
	Enabled         bool       `json:"enabled"`
	ActionStartDate time.Time  `json:"actionStartDate"`
	ActionEndDate   *time.Time `json:"actionEndDate"`
	InArchive       bool       `json:"inArchive"`
	Value           []any      `json:"value"`
}

func (r featureFlagResponse) toModel(domainCode string) model.OperationFeatureFlag {
	return model.OperationFeatureFlag{
		DomainCode:      strings.ToUpper(strings.TrimSpace(domainCode)),
		Code:            strings.ToUpper(strings.TrimSpace(r.Code)),
		Name:            strings.TrimSpace(r.Name),
		Group:           strings.TrimSpace(r.Group),
		Type:            strings.ToUpper(strings.TrimSpace(r.Type)),
		Enabled:         r.Enabled,
		ActionStartDate: r.ActionStartDate,
		ActionEndDate:   r.ActionEndDate,
		InArchive:       r.InArchive,
		Value:           append([]any(nil), r.Value...),
		CreatedAt:       r.CreatedAt,
		CreatedBy:       r.CreatedBy,
		UpdatedAt:       r.UpdatedAt,
		UpdatedBy:       r.UpdatedBy,
	}
}

type featureFlagHistoryResponse struct {
	UpdatedAt       time.Time  `json:"updatedAt"`
	UpdatedBy       string     `json:"updatedBy"`
	Name            string     `json:"name"`
	Group           string     `json:"group"`
	Enabled         bool       `json:"enabled"`
	ActionStartDate time.Time  `json:"actionStartDate"`
	ActionEndDate   *time.Time `json:"actionEndDate"`
	InArchive       bool       `json:"inArchive"`
	Value           []any      `json:"value"`
}

func (r featureFlagHistoryResponse) toModel() model.OperationFeatureFlagHistory {
	return model.OperationFeatureFlagHistory{
		UpdatedAt:       r.UpdatedAt,
		UpdatedBy:       r.UpdatedBy,
		Name:            strings.TrimSpace(r.Name),
		Group:           strings.TrimSpace(r.Group),
		Enabled:         r.Enabled,
		ActionStartDate: r.ActionStartDate,
		ActionEndDate:   r.ActionEndDate,
		InArchive:       r.InArchive,
		Value:           append([]any(nil), r.Value...),
	}
}

func domainQuery(filter model.OperationDomainFilter) url.Values {
	values := url.Values{}
	setInt(values, "page", filter.Page)
	setInt(values, "size", filter.Size)
	setQuery(values, "orderBy", filter.OrderBy)
	setQuery(values, "direction", filter.Direction)
	setQuery(values, "search", filter.Search)
	return values
}

func actorHeaders(actor string, requestID string) map[string]string {
	return map[string]string{
		"X-Auth-Subject": strings.TrimSpace(actor),
		"X-User-Id":      strings.TrimSpace(actor),
		"X-Request-Id":   strings.TrimSpace(requestID),
	}
}

func setQuery(values url.Values, key string, value string) {
	if value = strings.TrimSpace(value); value != "" {
		values.Set(key, value)
	}
}

func setInt(values url.Values, key string, value int) {
	if value > 0 {
		values.Set(key, strconv.Itoa(value))
	}
}

func setTime(values url.Values, key string, value *time.Time) {
	if value != nil && !value.IsZero() {
		values.Set(key, value.UTC().Format(time.RFC3339))
	}
}
