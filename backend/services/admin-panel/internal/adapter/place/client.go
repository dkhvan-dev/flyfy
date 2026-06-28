package place

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

func (c *Client) ListPlaces(ctx context.Context, filter model.AdminPlaceFilter) ([]model.AdminPlace, int, error) {
	values := url.Values{}
	values.Set("limit", fmt.Sprintf("%d", filter.Limit))
	values.Set("offset", fmt.Sprintf("%d", filter.Offset))
	values.Set("includeDeleted", "true")
	setQuery(values, "locale", filter.Locale)
	setQuery(values, "search", filter.Search)
	setQuery(values, "category", filter.Category)
	setQuery(values, "countryCode", filter.CountryCode)
	setQuery(values, "cityId", filter.CityID)
	setQuery(values, "sort", filter.Sort)
	var resp placeListResponse
	if err := c.doJSON(ctx, http.MethodGet, "/internal/v1/admin/places?"+values.Encode(), nil, nil, &resp); err != nil {
		return nil, 0, err
	}
	items := make([]model.AdminPlace, 0, len(resp.Items))
	for _, item := range resp.Items {
		converted := item.toModel()
		if filter.Status != "" && !strings.EqualFold(converted.Status, filter.Status) {
			continue
		}
		items = append(items, converted)
	}
	return items, resp.Total, nil
}

func (c *Client) GetPlace(ctx context.Context, id uuid.UUID) (*model.AdminPlace, error) {
	var resp placeResponse
	if err := c.doJSON(ctx, http.MethodGet, "/internal/v1/admin/places/"+id.String(), nil, nil, &resp); err != nil {
		return nil, err
	}
	item := resp.toModel()
	return &item, nil
}

func (c *Client) CreatePlace(ctx context.Context, input model.PlaceInput) (*model.AdminPlace, error) {
	var resp placeResponse
	if err := c.doJSON(ctx, http.MethodPost, "/internal/v1/admin/places", nil, placeRequestFromModel(input), &resp); err != nil {
		return nil, err
	}
	item := resp.toModel()
	return &item, nil
}

func (c *Client) UpdatePlace(ctx context.Context, id uuid.UUID, input model.PlaceInput) (*model.AdminPlace, error) {
	var resp placeResponse
	if err := c.doJSON(ctx, http.MethodPut, "/internal/v1/admin/places/"+id.String(), nil, placeRequestFromModel(input), &resp); err != nil {
		return nil, err
	}
	item := resp.toModel()
	return &item, nil
}

func (c *Client) ReplaceMedia(ctx context.Context, id uuid.UUID, media []model.PlaceMediaInput) error {
	body := replaceMediaRequest{Media: make([]mediaItemRequest, 0, len(media))}
	for _, item := range media {
		body.Media = append(body.Media, mediaItemRequest{
			FileID:      item.FileID.String(),
			ExternalURL: item.ExternalURL,
			SourceURL:   item.SourceURL,
			Credit:      item.Credit,
			License:     item.License,
			MediaType:   item.MediaType,
			Position:    item.Position,
		})
	}
	return c.doJSON(ctx, http.MethodPut, "/internal/v1/admin/places/"+id.String()+"/media", nil, body, nil)
}

func (c *Client) StartMediaBackfill(ctx context.Context, countryCode string) (model.PlaceMediaBackfillJob, error) {
	body := placeMediaBackfillRequest{
		CountryCode: strings.ToUpper(strings.TrimSpace(countryCode)),
	}
	var resp placeMediaBackfillResponse
	if err := c.doJSON(ctx, http.MethodPost, "/internal/v1/admin/places/media/backfill", nil, body, &resp); err != nil {
		return model.PlaceMediaBackfillJob{}, err
	}
	return model.PlaceMediaBackfillJob{
		JobID:       resp.JobID,
		CountryCode: resp.CountryCode,
		Status:      resp.Status,
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
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	req.Header.Set("Accept", "application/json")
	if c.internalToken != "" {
		req.Header.Set("Authorization", "Bearer "+c.internalToken)
		req.Header.Set("X-Internal-Service-Token", c.internalToken)
		req.Header.Set("X-Internal-Service", "admin-panel")
		req.Header.Set("X-Auth-Subject", "admin-panel")
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
		return fmt.Errorf("place-service %s %s returned %d: %s", method, path, resp.StatusCode, strings.TrimSpace(string(raw)))
	}
	if dest != nil && len(raw) > 0 {
		if err = json.Unmarshal(raw, dest); err != nil {
			return err
		}
	}
	return nil
}

func setQuery(values url.Values, key string, value string) {
	value = strings.TrimSpace(value)
	if value != "" {
		values.Set(key, value)
	}
}

type placeListResponse struct {
	Items []placeResponse `json:"items"`
	Total int             `json:"total"`
}

type placeMediaBackfillRequest struct {
	CountryCode string `json:"countryCode"`
}

type placeMediaBackfillResponse struct {
	JobID       string `json:"jobId"`
	CountryCode string `json:"countryCode"`
	Status      string `json:"status"`
}

type placeResponse struct {
	ID                string                              `json:"id"`
	Locale            string                              `json:"locale"`
	DefaultLocale     string                              `json:"defaultLocale"`
	Title             string                              `json:"title"`
	Description       string                              `json:"description"`
	CountryCode       string                              `json:"countryCode"`
	CityID            string                              `json:"cityId"`
	AccessCities      []placeCityLinkResponse             `json:"accessCities"`
	DepartureCities   []placeCityLinkResponse             `json:"departureCities"`
	Latitude          *float64                            `json:"latitude"`
	Longitude         *float64                            `json:"longitude"`
	LocationSourceURL string                              `json:"locationSourceUrl"`
	Category          string                              `json:"category"`
	PriceAmount       *float64                            `json:"priceAmount"`
	PriceCurrency     *string                             `json:"priceCurrency"`
	DurationValue     *int                                `json:"durationValue"`
	DurationUnit      *string                             `json:"durationUnit"`
	Rating            float64                             `json:"rating"`
	ReviewCount       int                                 `json:"reviewCount"`
	Spots             *int                                `json:"spots"`
	Source            string                              `json:"source"`
	Status            string                              `json:"status"`
	Tags              []string                            `json:"tags"`
	VisitInfo         placeVisitInfoResponse              `json:"visitInfo"`
	Translations      map[string]placeTranslationResponse `json:"translations"`
	Media             []placeMediaResponse                `json:"media"`
	CreatedAt         string                              `json:"createdAt"`
	UpdatedAt         string                              `json:"updatedAt"`
	DeletedAt         *string                             `json:"deletedAt"`
}

type placeTranslationResponse struct {
	Title       string `json:"title"`
	Description string `json:"description"`
}

type placeCityLinkResponse struct {
	CountryCode string `json:"countryCode"`
	CityID      string `json:"cityId"`
}

type placeVisitInfoResponse struct {
	BestTime        string            `json:"bestTime"`
	Accessibility   string            `json:"accessibility"`
	BookingRequired *bool             `json:"bookingRequired"`
	OpeningHours    openingHoursText  `json:"openingHours"`
	Amenities       []string          `json:"amenities"`
	Audience        []string          `json:"audience"`
	SafetyNotes     []string          `json:"safetyNotes"`
	NearbyIDs       []string          `json:"nearbyIds"`
	LocalizedTips   map[string]string `json:"localizedTips"`
}

type openingHoursText string

func (o *openingHoursText) UnmarshalJSON(raw []byte) error {
	raw = bytes.TrimSpace(raw)
	if len(raw) == 0 || bytes.Equal(raw, []byte("null")) {
		*o = ""
		return nil
	}
	var legacy string
	if err := json.Unmarshal(raw, &legacy); err == nil {
		*o = openingHoursText(strings.TrimSpace(legacy))
		return nil
	}
	var v2 struct {
		Is24Hours bool   `json:"is24Hours"`
		Seasonal  string `json:"seasonal"`
		Summary   string `json:"summary"`
	}
	if err := json.Unmarshal(raw, &v2); err != nil {
		return err
	}
	switch {
	case strings.TrimSpace(v2.Summary) != "":
		*o = openingHoursText(strings.TrimSpace(v2.Summary))
	case strings.TrimSpace(v2.Seasonal) != "":
		*o = openingHoursText(strings.TrimSpace(v2.Seasonal))
	case v2.Is24Hours:
		*o = "24/7"
	default:
		*o = ""
	}
	return nil
}

func (o openingHoursText) String() string {
	return string(o)
}

type placeMediaResponse struct {
	ID          string `json:"id"`
	FileID      string `json:"fileId"`
	ExternalURL string `json:"externalUrl"`
	SourceURL   string `json:"sourceUrl"`
	Credit      string `json:"credit"`
	License     string `json:"license"`
	MediaType   string `json:"mediaType"`
	Position    int    `json:"position"`
}

func (r placeResponse) toModel() model.AdminPlace {
	id, _ := uuid.Parse(r.ID)
	item := model.AdminPlace{
		ID:                id,
		Locale:            r.Locale,
		DefaultLocale:     r.DefaultLocale,
		Title:             r.Title,
		Description:       r.Description,
		CountryCode:       r.CountryCode,
		CityID:            r.CityID,
		AccessCities:      cityLinksToModel(r.AccessCities),
		DepartureCities:   cityLinksToModel(r.DepartureCities),
		Latitude:          r.Latitude,
		Longitude:         r.Longitude,
		LocationSourceURL: r.LocationSourceURL,
		Category:          r.Category,
		PriceAmount:       r.PriceAmount,
		PriceCurrency:     r.PriceCurrency,
		DurationValue:     r.DurationValue,
		DurationUnit:      r.DurationUnit,
		Rating:            r.Rating,
		ReviewCount:       r.ReviewCount,
		Spots:             r.Spots,
		Source:            r.Source,
		Status:            r.Status,
		Tags:              r.Tags,
		VisitInfo: model.PlaceVisitInfo{
			BestTime:        r.VisitInfo.BestTime,
			Accessibility:   r.VisitInfo.Accessibility,
			BookingRequired: r.VisitInfo.BookingRequired,
			OpeningHours:    r.VisitInfo.OpeningHours.String(),
			Amenities:       r.VisitInfo.Amenities,
			Audience:        r.VisitInfo.Audience,
			SafetyNotes:     r.VisitInfo.SafetyNotes,
			NearbyIDs:       r.VisitInfo.NearbyIDs,
			LocalizedTips:   r.VisitInfo.LocalizedTips,
		},
		Translations: translationsToModel(r.Translations),
		Media:        mediaToModel(r.Media),
		CreatedAt:    parseTime(r.CreatedAt),
		UpdatedAt:    parseTime(r.UpdatedAt),
	}
	if r.DeletedAt != nil {
		deletedAt := parseTime(*r.DeletedAt)
		item.DeletedAt = &deletedAt
	}
	return item
}

func cityLinksToModel(values []placeCityLinkResponse) []model.PlaceCityLink {
	out := make([]model.PlaceCityLink, 0, len(values))
	for _, value := range values {
		out = append(out, model.PlaceCityLink{CountryCode: value.CountryCode, CityID: value.CityID})
	}
	return out
}

func translationsToModel(values map[string]placeTranslationResponse) map[string]model.PlaceTranslation {
	out := make(map[string]model.PlaceTranslation, len(values))
	for locale, value := range values {
		out[locale] = model.PlaceTranslation{Title: value.Title, Description: value.Description}
	}
	return out
}

func mediaToModel(values []placeMediaResponse) []model.AdminPlaceMedia {
	out := make([]model.AdminPlaceMedia, 0, len(values))
	for _, value := range values {
		id, _ := uuid.Parse(value.ID)
		fileID, _ := uuid.Parse(value.FileID)
		out = append(out, model.AdminPlaceMedia{
			ID:          id,
			FileID:      fileID,
			ExternalURL: value.ExternalURL,
			SourceURL:   value.SourceURL,
			Credit:      value.Credit,
			License:     value.License,
			MediaType:   value.MediaType,
			Position:    value.Position,
		})
	}
	return out
}

func parseTime(raw string) time.Time {
	parsed, _ := time.Parse(time.RFC3339, strings.TrimSpace(raw))
	return parsed
}

type placeRequest struct {
	Title             string                             `json:"title"`
	Description       string                             `json:"description"`
	DefaultLocale     string                             `json:"defaultLocale"`
	Translations      map[string]placeTranslationRequest `json:"translations"`
	CountryCode       string                             `json:"countryCode"`
	CityID            string                             `json:"cityId"`
	AccessCities      []placeCityLinkRequest             `json:"accessCities,omitempty"`
	DepartureCities   []placeCityLinkRequest             `json:"departureCities,omitempty"`
	Latitude          *float64                           `json:"latitude"`
	Longitude         *float64                           `json:"longitude"`
	LocationSourceURL string                             `json:"locationSourceUrl"`
	Category          string                             `json:"category"`
	PriceAmount       *float64                           `json:"priceAmount"`
	PriceCurrency     *string                            `json:"priceCurrency"`
	DurationValue     *int                               `json:"durationValue"`
	DurationUnit      *string                            `json:"durationUnit"`
	Spots             *int                               `json:"spots"`
	Status            string                             `json:"status"`
	Tags              []string                           `json:"tags"`
	VisitInfo         *placeVisitInfoRequest             `json:"visitInfo,omitempty"`
}

type placeTranslationRequest struct {
	Title       string `json:"title"`
	Description string `json:"description"`
}

type placeCityLinkRequest struct {
	CountryCode string `json:"countryCode,omitempty"`
	CityID      string `json:"cityId"`
}

type placeVisitInfoRequest struct {
	BestTime        string                    `json:"bestTime"`
	Accessibility   string                    `json:"accessibility"`
	BookingRequired *bool                     `json:"bookingRequired"`
	OpeningHours    *placeOpeningHoursRequest `json:"openingHours,omitempty"`
	Amenities       []string                  `json:"amenities"`
	Audience        []string                  `json:"audience"`
	SafetyNotes     []string                  `json:"safetyNotes"`
	NearbyIDs       []string                  `json:"nearbyIds"`
	LocalizedTips   map[string]string         `json:"localizedTips"`
}

type placeOpeningHoursRequest struct {
	Summary map[string]string `json:"summary,omitempty"`
}

func placeRequestFromModel(input model.PlaceInput) placeRequest {
	req := placeRequest{
		Title:             input.Title,
		Description:       input.Description,
		DefaultLocale:     input.DefaultLocale,
		Translations:      make(map[string]placeTranslationRequest, len(input.Translations)),
		CountryCode:       input.CountryCode,
		CityID:            input.CityID,
		AccessCities:      cityLinksFromModel(input.AccessCities),
		DepartureCities:   cityLinksFromModel(input.DepartureCities),
		Latitude:          input.Latitude,
		Longitude:         input.Longitude,
		LocationSourceURL: input.LocationSourceURL,
		Category:          input.Category,
		PriceAmount:       input.PriceAmount,
		PriceCurrency:     input.PriceCurrency,
		DurationValue:     input.DurationValue,
		DurationUnit:      input.DurationUnit,
		Spots:             input.Spots,
		Status:            input.Status,
		Tags:              input.Tags,
	}
	for locale, value := range input.Translations {
		req.Translations[locale] = placeTranslationRequest{Title: value.Title, Description: value.Description}
	}
	if input.VisitInfo != nil {
		req.VisitInfo = &placeVisitInfoRequest{
			BestTime:        input.VisitInfo.BestTime,
			Accessibility:   input.VisitInfo.Accessibility,
			BookingRequired: input.VisitInfo.BookingRequired,
			OpeningHours:    placeOpeningHoursRequestFromText(input.VisitInfo.OpeningHours, input.DefaultLocale),
			Amenities:       input.VisitInfo.Amenities,
			Audience:        input.VisitInfo.Audience,
			SafetyNotes:     input.VisitInfo.SafetyNotes,
			NearbyIDs:       input.VisitInfo.NearbyIDs,
			LocalizedTips:   input.VisitInfo.LocalizedTips,
		}
	}
	return req
}

func placeOpeningHoursRequestFromText(value string, locale string) *placeOpeningHoursRequest {
	value = strings.TrimSpace(value)
	if value == "" {
		return nil
	}
	locale = strings.ToLower(strings.TrimSpace(locale))
	if locale == "" {
		locale = "ru"
	}
	return &placeOpeningHoursRequest{Summary: map[string]string{locale: value}}
}

func cityLinksFromModel(values []model.PlaceCityLink) []placeCityLinkRequest {
	out := make([]placeCityLinkRequest, 0, len(values))
	for _, value := range values {
		out = append(out, placeCityLinkRequest{CountryCode: value.CountryCode, CityID: value.CityID})
	}
	return out
}

type replaceMediaRequest struct {
	Media []mediaItemRequest `json:"media"`
}

type mediaItemRequest struct {
	FileID      string `json:"fileId"`
	ExternalURL string `json:"externalUrl,omitempty"`
	SourceURL   string `json:"sourceUrl,omitempty"`
	Credit      string `json:"credit,omitempty"`
	License     string `json:"license,omitempty"`
	MediaType   string `json:"mediaType"`
	Position    int    `json:"position"`
}
