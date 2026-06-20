package techbreak

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
	if input.TechBreakServiceID > 0 {
		method = http.MethodPut
		path += "/" + strconv.FormatInt(input.TechBreakServiceID, 10)
	}
	var resp domainResponse
	if err := c.doJSON(ctx, method, path, headers, body, &resp); err != nil {
		return model.OperationDomain{}, err
	}
	return resp.toModel(), nil
}

func (c *Client) ListTechBreaks(ctx context.Context, filter model.OperationTechBreakFilter) (model.OperationPage[model.OperationTechBreak], error) {
	values := url.Values{}
	setInt(values, "page", filter.Page)
	setInt(values, "size", filter.Size)
	setQuery(values, "orderBy", filter.OrderBy)
	setQuery(values, "direction", filter.Direction)
	setQuery(values, "domainCode", strings.ToUpper(strings.TrimSpace(filter.DomainCode)))
	setQuery(values, "search", filter.Search)
	setTime(values, "actionStartDate", filter.ActionStartDate)
	setTime(values, "actionEndDate", filter.ActionEndDate)

	var resp pageResponse[techBreakResponse]
	if err := c.doJSON(ctx, http.MethodGet, "/api/v1/tech-breaks?"+values.Encode(), nil, nil, &resp); err != nil {
		return model.OperationPage[model.OperationTechBreak]{}, err
	}
	items := make([]model.OperationTechBreak, 0, len(resp.Content))
	for _, item := range resp.Content {
		items = append(items, item.toModel(filter.DomainCode))
	}
	return model.OperationPage[model.OperationTechBreak]{
		Content:       items,
		Page:          resp.Page,
		Size:          resp.Size,
		TotalElements: resp.TotalElements,
		TotalPages:    resp.TotalPages,
	}, nil
}

func (c *Client) GetTechBreak(ctx context.Context, id int64, domainCode string) (model.OperationTechBreak, error) {
	values := url.Values{}
	setQuery(values, "domainCode", strings.ToUpper(strings.TrimSpace(domainCode)))
	var resp techBreakResponse
	if err := c.doJSON(ctx, http.MethodGet, "/api/v1/tech-breaks/"+strconv.FormatInt(id, 10)+"?"+values.Encode(), nil, nil, &resp); err != nil {
		return model.OperationTechBreak{}, err
	}
	return resp.toModel(domainCode), nil
}

func (c *Client) UpsertTechBreak(ctx context.Context, input model.OperationTechBreakInput) (model.OperationTechBreak, error) {
	body := techBreakRequest{
		DomainCode:       strings.ToUpper(strings.TrimSpace(input.DomainCode)),
		Name:             strings.TrimSpace(input.Name),
		ActionStartDate:  input.ActionStartDate,
		ActionEndDate:    input.ActionEndDate,
		ExcludeEmails:    cleanStringSlice(input.ExcludeEmails),
		ExcludeNicknames: cleanStringSlice(input.ExcludeNicknames),
		ScopeCodes:       cleanStringSlice(input.ScopeCodes),
	}
	headers := actorHeaders(input.Actor, input.RequestID)
	path := "/api/v1/tech-breaks"
	method := http.MethodPost
	if input.ID > 0 {
		method = http.MethodPut
		path += "/" + strconv.FormatInt(input.ID, 10)
	}
	var resp techBreakResponse
	if err := c.doJSON(ctx, method, path, headers, body, &resp); err != nil {
		return model.OperationTechBreak{}, err
	}
	return resp.toModel(input.DomainCode), nil
}

func (c *Client) ArchiveTechBreak(ctx context.Context, id int64, domainCode string) error {
	values := url.Values{}
	setQuery(values, "domainCode", strings.ToUpper(strings.TrimSpace(domainCode)))
	return c.doJSON(ctx, http.MethodDelete, "/api/v1/tech-breaks/"+strconv.FormatInt(id, 10)+"?"+values.Encode(), nil, nil, nil)
}

func (c *Client) ListScopes(ctx context.Context, domainCode string) ([]model.OperationTechBreakScope, error) {
	values := url.Values{}
	setQuery(values, "domainCode", strings.ToUpper(strings.TrimSpace(domainCode)))
	var resp []scopeResponse
	if err := c.doJSON(ctx, http.MethodGet, "/api/v1/dict/tech-break-scopes?"+values.Encode(), nil, nil, &resp); err != nil {
		return nil, err
	}
	items := make([]model.OperationTechBreakScope, 0, len(resp))
	for _, item := range resp {
		items = append(items, item.toModel(domainCode))
	}
	return items, nil
}

func (c *Client) GetScope(ctx context.Context, id int64, domainCode string) (model.OperationTechBreakScope, error) {
	values := url.Values{}
	setQuery(values, "domainCode", strings.ToUpper(strings.TrimSpace(domainCode)))
	var resp scopeResponse
	if err := c.doJSON(ctx, http.MethodGet, "/api/v1/dict/tech-break-scopes/"+strconv.FormatInt(id, 10)+"?"+values.Encode(), nil, nil, &resp); err != nil {
		return model.OperationTechBreakScope{}, err
	}
	return resp.toModel(domainCode), nil
}

func (c *Client) UpsertScope(ctx context.Context, input model.OperationTechBreakScopeInput) (model.OperationTechBreakScope, error) {
	body := scopeRequest{
		DomainCode: strings.ToUpper(strings.TrimSpace(input.DomainCode)),
		Code:       strings.ToUpper(strings.TrimSpace(input.Code)),
		Name:       strings.TrimSpace(input.Name),
	}
	headers := actorHeaders(input.Actor, input.RequestID)
	path := "/api/v1/dict/tech-break-scopes"
	method := http.MethodPost
	if input.ID > 0 {
		method = http.MethodPut
		path += "/" + strconv.FormatInt(input.ID, 10)
	}
	var resp scopeResponse
	if err := c.doJSON(ctx, method, path, headers, body, &resp); err != nil {
		return model.OperationTechBreakScope{}, err
	}
	return resp.toModel(input.DomainCode), nil
}

func (c *Client) ArchiveScope(ctx context.Context, id int64, domainCode string) error {
	values := url.Values{}
	setQuery(values, "domainCode", strings.ToUpper(strings.TrimSpace(domainCode)))
	return c.doJSON(ctx, http.MethodDelete, "/api/v1/dict/tech-break-scopes/"+strconv.FormatInt(id, 10)+"?"+values.Encode(), nil, nil, nil)
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
		return fmt.Errorf("tech-break-service %s %s returned %d: %s", method, path, resp.StatusCode, strings.TrimSpace(string(raw)))
	}
	if dest != nil && len(raw) > 0 {
		if err = json.Unmarshal(raw, dest); err != nil {
			return err
		}
	}
	return nil
}

type pageResponse[T any] struct {
	Content       []T   `json:"content"`
	Page          int   `json:"page"`
	Size          int   `json:"size"`
	TotalElements int64 `json:"totalElements"`
	TotalPages    int   `json:"totalPages"`
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
		TechBreakServiceID: r.ID,
		Code:               strings.ToUpper(strings.TrimSpace(r.Code)),
		Description:        strings.TrimSpace(r.Description),
		CreatedAt:          r.CreatedAt,
		CreatedBy:          r.CreatedBy,
		UpdatedAt:          r.UpdatedAt,
		UpdatedBy:          r.UpdatedBy,
		FeatureFlagGroups:  append([]string(nil), r.FeatureFlagGroups...),
	}
}

type techBreakRequest struct {
	DomainCode       string     `json:"domainCode"`
	Name             string     `json:"name"`
	ActionStartDate  time.Time  `json:"actionStartDate"`
	ActionEndDate    *time.Time `json:"actionEndDate"`
	ExcludeEmails    []string   `json:"excludeEmails"`
	ExcludeNicknames []string   `json:"excludeNicknames"`
	ScopeCodes       []string   `json:"scopeCodes"`
}

type techBreakResponse struct {
	ID               int64           `json:"id"`
	CreatedAt        time.Time       `json:"createdAt"`
	CreatedBy        string          `json:"createdBy"`
	UpdatedAt        *time.Time      `json:"updatedAt"`
	UpdatedBy        string          `json:"updatedBy"`
	Name             string          `json:"name"`
	Enabled          bool            `json:"enabled"`
	ActionStartDate  time.Time       `json:"actionStartDate"`
	ActionEndDate    *time.Time      `json:"actionEndDate"`
	ExcludeEmails    []string        `json:"excludeEmails"`
	ExcludeNicknames []string        `json:"excludeNicknames"`
	Scopes           []scopeResponse `json:"scopes"`
}

func (r techBreakResponse) toModel(domainCode string) model.OperationTechBreak {
	scopes := make([]model.OperationTechBreakScope, 0, len(r.Scopes))
	scopeCodes := make([]string, 0, len(r.Scopes))
	for _, item := range r.Scopes {
		scope := item.toModel(domainCode)
		scopes = append(scopes, scope)
		scopeCodes = append(scopeCodes, scope.Code)
	}
	return model.OperationTechBreak{
		ID:               r.ID,
		DomainCode:       strings.ToUpper(strings.TrimSpace(domainCode)),
		Name:             strings.TrimSpace(r.Name),
		Enabled:          r.Enabled,
		ActionStartDate:  r.ActionStartDate,
		ActionEndDate:    r.ActionEndDate,
		ExcludeEmails:    append([]string(nil), r.ExcludeEmails...),
		ExcludeNicknames: append([]string(nil), r.ExcludeNicknames...),
		ScopeCodes:       scopeCodes,
		Scopes:           scopes,
		CreatedAt:        r.CreatedAt,
		CreatedBy:        r.CreatedBy,
		UpdatedAt:        r.UpdatedAt,
		UpdatedBy:        r.UpdatedBy,
	}
}

type scopeRequest struct {
	DomainCode string `json:"domainCode"`
	Code       string `json:"code,omitempty"`
	Name       string `json:"name"`
}

type scopeResponse struct {
	ID        int64      `json:"id"`
	CreatedAt time.Time  `json:"createdAt"`
	CreatedBy string     `json:"createdBy"`
	UpdatedAt *time.Time `json:"updatedAt"`
	UpdatedBy string     `json:"updatedBy"`
	Code      string     `json:"code"`
	Name      string     `json:"name"`
}

func (r scopeResponse) toModel(domainCode string) model.OperationTechBreakScope {
	return model.OperationTechBreakScope{
		ID:         r.ID,
		DomainCode: strings.ToUpper(strings.TrimSpace(domainCode)),
		Code:       strings.ToUpper(strings.TrimSpace(r.Code)),
		Name:       strings.TrimSpace(r.Name),
		CreatedAt:  r.CreatedAt,
		CreatedBy:  r.CreatedBy,
		UpdatedAt:  r.UpdatedAt,
		UpdatedBy:  r.UpdatedBy,
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

func cleanStringSlice(values []string) []string {
	out := make([]string, 0, len(values))
	for _, value := range values {
		value = strings.TrimSpace(value)
		if value != "" {
			out = append(out, value)
		}
	}
	return out
}
