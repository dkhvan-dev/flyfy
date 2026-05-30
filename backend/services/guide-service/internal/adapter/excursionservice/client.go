package excursionservice

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

	"kz/inflap/backend/services/guide-service/internal/app"
)

const defaultListGuideIDsByCityTimeout = 3 * time.Second

type Client struct {
	baseURL       string
	internalToken string
	httpClient    *http.Client
}

func New(baseURL string, internalToken string, httpClient *http.Client) *Client {
	if httpClient == nil {
		httpClient = &http.Client{Timeout: defaultListGuideIDsByCityTimeout}
	}
	return &Client{
		baseURL:       strings.TrimRight(strings.TrimSpace(baseURL), "/"),
		internalToken: strings.TrimSpace(internalToken),
		httpClient:    httpClient,
	}
}

func (c *Client) ListGuideUserIDsByCity(
	ctx context.Context,
	input app.GuideExcursionCityFilter,
) ([]uuid.UUID, error) {
	cityName := strings.TrimSpace(input.CityName)
	if cityName == "" {
		return []uuid.UUID{}, nil
	}
	if c == nil || c.baseURL == "" {
		return nil, fmt.Errorf("excursion-service base url is not configured")
	}

	values := url.Values{}
	values.Set("cityName", cityName)
	if countryCode := strings.ToUpper(strings.TrimSpace(input.CountryCode)); countryCode != "" {
		values.Set("countryCode", countryCode)
	}

	endpoint := c.baseURL + "/v1/guides/by-excursion-city?" + values.Encode()
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return nil, fmt.Errorf("create excursion city guide request: %w", err)
	}
	req.Header.Set("Accept", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("request excursion city guides: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < http.StatusOK || resp.StatusCode >= http.StatusMultipleChoices {
		return nil, fmt.Errorf("excursion-service returned status %d", resp.StatusCode)
	}

	var payload struct {
		Items []struct {
			GuideUserID string `json:"guideUserId"`
		} `json:"items"`
	}
	if err = json.NewDecoder(resp.Body).Decode(&payload); err != nil {
		return nil, fmt.Errorf("decode excursion city guides: %w", err)
	}

	result := make([]uuid.UUID, 0, len(payload.Items))
	seen := make(map[uuid.UUID]struct{}, len(payload.Items))
	for _, item := range payload.Items {
		id, parseErr := uuid.Parse(strings.TrimSpace(item.GuideUserID))
		if parseErr != nil || id == uuid.Nil {
			continue
		}
		if _, exists := seen[id]; exists {
			continue
		}
		seen[id] = struct{}{}
		result = append(result, id)
	}
	return result, nil
}

func (c *Client) ArchiveGuideExcursionOffers(ctx context.Context, guideUserID uuid.UUID) error {
	if guideUserID == uuid.Nil {
		return nil
	}
	if c == nil || c.baseURL == "" {
		return fmt.Errorf("excursion-service base url is not configured")
	}

	endpoint := c.baseURL + "/v1/admin/excursion-guides/" + guideUserID.String() + "/archive-offers"
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, nil)
	if err != nil {
		return fmt.Errorf("create archive guide offers request: %w", err)
	}
	req.Header.Set("Accept", "application/json")
	if c.internalToken != "" {
		req.Header.Set("X-Internal-Service-Token", c.internalToken)
		req.Header.Set("X-Auth-Subject", "guide-service")
		req.Header.Set("X-User-Roles", "ADMIN,GUIDE_MODERATOR,MODERATION_LEAD,SUPER_ADMIN")
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("request archive guide offers: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < http.StatusOK || resp.StatusCode >= http.StatusMultipleChoices {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))
		return fmt.Errorf("excursion-service archive guide offers returned status %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
	}
	return nil
}
