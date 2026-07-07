package activity

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/enum"
	"kz/inflap/backend/services/feed-service/internal/domain/model"
	"kz/inflap/backend/services/feed-service/internal/domain/port"
)

const (
	internalCreateActivityFromPostPath = "/internal/v1/activities/from-post"
	internalTokenHeader                = "X-Internal-Service-Token"
	internalServiceNameHeader          = "X-Service-Name"
	activityErrorBodyLimit             = 4096
	defaultActivityDuration            = 2 * time.Hour
)

type Client struct {
	baseURL       string
	internalToken string
	serviceName   string
	httpClient    *http.Client
}

type Option func(*Client)

func WithHTTPClient(httpClient *http.Client) Option {
	return func(c *Client) {
		if httpClient != nil {
			c.httpClient = httpClient
		}
	}
}

var _ port.PostActivityIntentPublisher = (*Client)(nil)

func New(baseURL string, internalToken string, serviceName string, timeout time.Duration, options ...Option) *Client {
	if timeout <= 0 {
		timeout = 5 * time.Second
	}
	client := &Client{
		baseURL:       strings.TrimRight(strings.TrimSpace(baseURL), "/"),
		internalToken: strings.TrimSpace(internalToken),
		serviceName:   strings.TrimSpace(serviceName),
		httpClient:    &http.Client{Timeout: timeout},
	}
	for _, option := range options {
		if option != nil {
			option(client)
		}
	}
	return client
}

func (c *Client) PublishPostActivityIntent(
	ctx context.Context,
	event model.PostActivityIntentEvent,
) (uuid.UUID, error) {
	if c == nil || c.baseURL == "" || c.httpClient == nil {
		return uuid.Nil, fmt.Errorf("activity client is not configured")
	}
	payload, err := buildCreateActivityFromPostRequest(event)
	if err != nil {
		return uuid.Nil, err
	}
	body, err := json.Marshal(payload)
	if err != nil {
		return uuid.Nil, fmt.Errorf("marshal activity from post request: %w", err)
	}

	req, err := http.NewRequestWithContext(
		ctx,
		http.MethodPost,
		c.baseURL+internalCreateActivityFromPostPath,
		bytes.NewReader(body),
	)
	if err != nil {
		return uuid.Nil, fmt.Errorf("create activity-service request: %w", err)
	}
	req.Header.Set("Accept", "application/json")
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Idempotency-Key", payload.IdempotencyKey)
	req.Header.Set(internalServiceNameHeader, c.effectiveServiceName())
	if c.internalToken != "" {
		req.Header.Set(internalTokenHeader, c.internalToken)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return uuid.Nil, fmt.Errorf("call activity-service: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < http.StatusOK || resp.StatusCode >= http.StatusMultipleChoices {
		respBody, _ := io.ReadAll(io.LimitReader(resp.Body, activityErrorBodyLimit))
		return uuid.Nil, fmt.Errorf(
			"activity-service create from post failed: status=%d message=%s",
			resp.StatusCode,
			strings.TrimSpace(string(respBody)),
		)
	}

	var result createActivityFromPostResponse
	if err = json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return uuid.Nil, fmt.Errorf("decode activity-service response: %w", err)
	}
	activityID, err := uuid.Parse(strings.TrimSpace(result.ID))
	if err != nil || activityID == uuid.Nil {
		return uuid.Nil, fmt.Errorf("activity-service returned invalid activity id")
	}
	return activityID, nil
}

func (c *Client) effectiveServiceName() string {
	if c != nil && strings.TrimSpace(c.serviceName) != "" {
		return strings.TrimSpace(c.serviceName)
	}
	return "feed-service"
}

type createActivityFromPostRequest struct {
	HostUserID     string `json:"hostUserId"`
	SourcePostID   string `json:"sourcePostId,omitempty"`
	IdempotencyKey string `json:"idempotencyKey,omitempty"`

	Title           string   `json:"title"`
	Description     string   `json:"description"`
	Format          string   `json:"format"`
	Visibility      string   `json:"visibility"`
	CategorySlug    string   `json:"categorySlug"`
	SubcategorySlug *string  `json:"subcategorySlug,omitempty"`
	Tags            []string `json:"tags,omitempty"`
	LanguageCode    string   `json:"languageCode"`
	Timezone        string   `json:"timezone"`

	StartAt              string   `json:"startAt"`
	EndAt                string   `json:"endAt"`
	CapacityType         string   `json:"capacityType"`
	MaxParticipants      *int     `json:"maxParticipants,omitempty"`
	PriceType            string   `json:"priceType"`
	PriceAmount          *float64 `json:"priceAmount,omitempty"`
	Currency             *string  `json:"currency,omitempty"`
	RequiresProfile      *bool    `json:"requiresProfileCompletion,omitempty"`
	RequiresConfirmation *bool    `json:"requiresAttendanceConfirmation,omitempty"`
	AllowsInvites        *bool    `json:"allowsParticipantInvites,omitempty"`

	CountryCode *string  `json:"countryCode,omitempty"`
	CityID      *string  `json:"cityId,omitempty"`
	CityName    *string  `json:"cityName,omitempty"`
	AddressText *string  `json:"addressText,omitempty"`
	Latitude    *float64 `json:"latitude,omitempty"`
	Longitude   *float64 `json:"longitude,omitempty"`
	MapURL      *string  `json:"mapUrl,omitempty"`
	MeetingURL  *string  `json:"meetingUrl,omitempty"`
	CoverFileID *string  `json:"coverFileId,omitempty"`
}

type createActivityFromPostResponse struct {
	ID string `json:"id"`
}

func buildCreateActivityFromPostRequest(event model.PostActivityIntentEvent) (createActivityFromPostRequest, error) {
	if event.ID == uuid.Nil || event.PostID == uuid.Nil || event.AuthorUserID == uuid.Nil {
		return createActivityFromPostRequest{}, fmt.Errorf("post activity intent event ids are required")
	}
	values, err := structuredValues(event.StructuredData)
	if err != nil {
		return createActivityFromPostRequest{}, fmt.Errorf("decode post activity structured data: %w", err)
	}

	startAt, err := structuredTime(values, "starts_at", "startsAt", "startAt")
	if err != nil {
		return createActivityFromPostRequest{}, fmt.Errorf("activity intent requires valid starts_at: %w", err)
	}
	endAt, err := optionalStructuredTime(values, "ends_at", "endsAt", "endAt")
	if err != nil {
		return createActivityFromPostRequest{}, fmt.Errorf("activity intent requires valid ends_at: %w", err)
	}
	if endAt.IsZero() || !endAt.After(startAt) {
		endAt = startAt.Add(defaultActivityDuration)
	}

	location := structuredLocation(values, event.PostProfileKey)
	if location.MeetingURL == nil && location.AddressText == nil && location.Latitude == nil && location.Longitude == nil {
		return createActivityFromPostRequest{}, fmt.Errorf("activity intent requires location")
	}

	categorySlug, subcategorySlug := activityCategory(values, event.PostProfileKey)
	maxParticipants := structuredCapacity(values)
	priceType, priceAmount, currency := structuredPrice(values)
	format := activityFormat(location)
	requiresProfile := true
	requiresConfirmation := false
	allowsInvites := true

	return createActivityFromPostRequest{
		HostUserID:           event.AuthorUserID.String(),
		SourcePostID:         event.PostID.String(),
		IdempotencyKey:       strings.TrimSpace(event.IdempotencyKey),
		Title:                firstStructuredString(values, "title"),
		Description:          firstStructuredString(values, "description", "body", "route"),
		Format:               format,
		Visibility:           "PUBLIC",
		CategorySlug:         categorySlug,
		SubcategorySlug:      subcategorySlug,
		Tags:                 structuredStringList(values, "tags"),
		LanguageCode:         defaultString(firstStructuredString(values, "language_code", "languageCode"), "en"),
		Timezone:             defaultString(firstStructuredString(values, "timezone"), "UTC"),
		StartAt:              startAt.UTC().Format(time.RFC3339),
		EndAt:                endAt.UTC().Format(time.RFC3339),
		CapacityType:         activityCapacityType(maxParticipants),
		MaxParticipants:      maxParticipants,
		PriceType:            priceType,
		PriceAmount:          priceAmount,
		Currency:             currency,
		RequiresProfile:      &requiresProfile,
		RequiresConfirmation: &requiresConfirmation,
		AllowsInvites:        &allowsInvites,
		CountryCode:          location.CountryCode,
		CityID:               location.CityID,
		CityName:             location.CityName,
		AddressText:          location.AddressText,
		Latitude:             location.Latitude,
		Longitude:            location.Longitude,
		MapURL:               location.MapURL,
		MeetingURL:           location.MeetingURL,
		CoverFileID:          structuredCoverFileID(values),
	}, nil
}

type activityLocationPayload struct {
	CountryCode *string
	CityID      *string
	CityName    *string
	AddressText *string
	Latitude    *float64
	Longitude   *float64
	MapURL      *string
	MeetingURL  *string
}

func structuredValues(raw json.RawMessage) (map[string]any, error) {
	if len(bytes.TrimSpace(raw)) == 0 {
		return map[string]any{}, nil
	}
	var values map[string]any
	if err := json.Unmarshal(raw, &values); err != nil {
		return nil, err
	}
	if values == nil {
		values = map[string]any{}
	}
	return values, nil
}

func structuredTime(values map[string]any, keys ...string) (time.Time, error) {
	raw := firstStructuredString(values, keys...)
	if raw == "" {
		return time.Time{}, fmt.Errorf("missing time")
	}
	return parseStructuredTime(raw)
}

func optionalStructuredTime(values map[string]any, keys ...string) (time.Time, error) {
	raw := firstStructuredString(values, keys...)
	if raw == "" {
		return time.Time{}, nil
	}
	return parseStructuredTime(raw)
}

func parseStructuredTime(raw string) (time.Time, error) {
	value := strings.TrimSpace(raw)
	for _, layout := range []string{time.RFC3339, "2006-01-02 15:04", "2006-01-02"} {
		parsed, err := time.Parse(layout, value)
		if err == nil {
			return parsed, nil
		}
	}
	return time.Time{}, fmt.Errorf("invalid time %q", raw)
}

func structuredLocation(values map[string]any, profileKey string) activityLocationPayload {
	result := activityLocationPayload{
		CountryCode: optionalStructuredString(values, "country_code", "countryCode"),
		CityID:      optionalStructuredString(values, "city_id", "cityId"),
		CityName:    optionalStructuredString(values, "city_name", "cityName"),
		AddressText: optionalStructuredString(values, "address_text", "addressText"),
		Latitude:    optionalStructuredFloat(values, "latitude", "lat"),
		Longitude:   optionalStructuredFloat(values, "longitude", "lng", "lon"),
		MapURL:      optionalStructuredString(values, "map_url", "mapUrl"),
		MeetingURL:  optionalStructuredString(values, "meeting_url", "meetingUrl"),
	}

	if raw, ok := values["location"]; ok {
		applyStructuredLocation(&result, raw)
	}
	if result.AddressText == nil {
		switch enum.PostProfileKey(profileKey) {
		case enum.PostProfileTripPlanV1:
			result.AddressText = optionalStructuredString(values, "meeting_point", "meetingPoint")
		default:
			result.AddressText = optionalStructuredString(values, "location_text", "locationText")
		}
	}
	return result
}

func applyStructuredLocation(result *activityLocationPayload, raw any) {
	switch typed := raw.(type) {
	case string:
		setStringPtrIfEmpty(&result.AddressText, typed)
	case map[string]any:
		setStringPtrIfEmpty(&result.CountryCode, firstStructuredString(typed, "country_code", "countryCode"))
		setStringPtrIfEmpty(&result.CityID, firstStructuredString(typed, "city_id", "cityId"))
		setStringPtrIfEmpty(&result.CityName, firstStructuredString(typed, "city_name", "cityName"))
		setStringPtrIfEmpty(&result.AddressText, firstStructuredString(typed, "address_text", "addressText", "address", "title", "name"))
		setStringPtrIfEmpty(&result.MapURL, firstStructuredString(typed, "map_url", "mapUrl"))
		setStringPtrIfEmpty(&result.MeetingURL, firstStructuredString(typed, "meeting_url", "meetingUrl"))
		if result.Latitude == nil {
			result.Latitude = optionalStructuredFloat(typed, "latitude", "lat")
		}
		if result.Longitude == nil {
			result.Longitude = optionalStructuredFloat(typed, "longitude", "lng", "lon")
		}
	}
}

func activityFormat(location activityLocationPayload) string {
	hasOffline := location.AddressText != nil || location.Latitude != nil || location.Longitude != nil
	hasOnline := location.MeetingURL != nil
	switch {
	case hasOffline && hasOnline:
		return "HYBRID"
	case hasOnline:
		return "ONLINE"
	default:
		return "OFFLINE"
	}
}

func activityCategory(values map[string]any, profileKey string) (string, *string) {
	if category := firstStructuredString(values, "activity_category_slug", "activityCategorySlug", "categorySlug"); category != "" {
		return category, optionalStructuredString(values, "activity_subcategory_slug", "activitySubcategorySlug", "subcategorySlug")
	}
	switch enum.PostProfileKey(profileKey) {
	case enum.PostProfileTripPlanV1:
		return "nature-outdoor", stringPtr("day-trip")
	case enum.PostProfileEventAnnouncementV1:
		return "other", stringPtr("community-event")
	default:
		return "other", nil
	}
}

func structuredCapacity(values map[string]any) *int {
	if value := optionalStructuredInt(values, "participant_limit", "participantLimit", "maxParticipants", "max_participants"); value != nil {
		return value
	}
	raw, ok := values["capacity"]
	if !ok {
		return nil
	}
	switch typed := raw.(type) {
	case float64:
		return positiveIntPtr(int(typed))
	case string:
		if parsed, err := strconv.Atoi(strings.TrimSpace(typed)); err == nil {
			return positiveIntPtr(parsed)
		}
	case map[string]any:
		return optionalStructuredInt(typed, "maxParticipants", "max_participants", "limit")
	}
	return nil
}

func activityCapacityType(maxParticipants *int) string {
	if maxParticipants != nil && *maxParticipants > 0 {
		return "LIMITED"
	}
	return "UNLIMITED"
}

func structuredPrice(values map[string]any) (string, *float64, *string) {
	amount := optionalStructuredFloat(values, "price_amount", "priceAmount")
	currency := optionalStructuredString(values, "currency")
	if raw, ok := values["price"]; ok {
		switch typed := raw.(type) {
		case float64:
			amount = positiveFloatPtr(typed)
		case string:
			if parsed, err := strconv.ParseFloat(strings.TrimSpace(typed), 64); err == nil {
				amount = positiveFloatPtr(parsed)
			}
		case map[string]any:
			if amount == nil {
				amount = optionalStructuredFloat(typed, "amount", "priceAmount", "price_amount")
			}
			if currency == nil {
				currency = optionalStructuredString(typed, "currency")
			}
		}
	}
	if amount != nil && *amount > 0 {
		if currency == nil {
			currency = stringPtr(defaultString(firstStructuredString(values, "price_currency", "priceCurrency"), "USD"))
		}
		return "PAID", amount, currency
	}
	return "FREE", nil, nil
}

func structuredCoverFileID(values map[string]any) *string {
	if value := optionalStructuredUUIDString(values, "cover_file_id", "coverFileId"); value != nil {
		return value
	}
	mediaIDs := structuredStringList(values, "media_file_ids", "mediaFileIds")
	for _, value := range mediaIDs {
		if _, err := uuid.Parse(value); err == nil {
			return stringPtr(value)
		}
	}
	return nil
}

func structuredStringList(values map[string]any, keys ...string) []string {
	for _, key := range keys {
		raw, ok := values[key]
		if !ok {
			continue
		}
		switch typed := raw.(type) {
		case []any:
			result := make([]string, 0, len(typed))
			seen := map[string]struct{}{}
			for _, item := range typed {
				if text, ok := item.(string); ok {
					text = strings.TrimSpace(text)
					if text == "" {
						continue
					}
					if _, exists := seen[text]; exists {
						continue
					}
					seen[text] = struct{}{}
					result = append(result, text)
				}
			}
			return result
		case []string:
			return typed
		}
	}
	return nil
}

func firstStructuredString(values map[string]any, keys ...string) string {
	for _, key := range keys {
		value, ok := values[key]
		if !ok {
			continue
		}
		if typed, ok := value.(string); ok {
			if trimmed := strings.TrimSpace(typed); trimmed != "" {
				return trimmed
			}
		}
	}
	return ""
}

func optionalStructuredString(values map[string]any, keys ...string) *string {
	value := firstStructuredString(values, keys...)
	if value == "" {
		return nil
	}
	return stringPtr(value)
}

func optionalStructuredUUIDString(values map[string]any, keys ...string) *string {
	value := firstStructuredString(values, keys...)
	if _, err := uuid.Parse(value); err != nil {
		return nil
	}
	return stringPtr(value)
}

func optionalStructuredFloat(values map[string]any, keys ...string) *float64 {
	for _, key := range keys {
		value, ok := values[key]
		if !ok {
			continue
		}
		switch typed := value.(type) {
		case float64:
			return &typed
		case string:
			if parsed, err := strconv.ParseFloat(strings.TrimSpace(typed), 64); err == nil {
				return &parsed
			}
		}
	}
	return nil
}

func optionalStructuredInt(values map[string]any, keys ...string) *int {
	for _, key := range keys {
		value, ok := values[key]
		if !ok {
			continue
		}
		switch typed := value.(type) {
		case float64:
			return positiveIntPtr(int(typed))
		case string:
			if parsed, err := strconv.Atoi(strings.TrimSpace(typed)); err == nil {
				return positiveIntPtr(parsed)
			}
		}
	}
	return nil
}

func setStringPtrIfEmpty(target **string, value string) {
	if *target != nil {
		return
	}
	if trimmed := strings.TrimSpace(value); trimmed != "" {
		*target = &trimmed
	}
}

func positiveIntPtr(value int) *int {
	if value <= 0 {
		return nil
	}
	return &value
}

func positiveFloatPtr(value float64) *float64 {
	if value <= 0 {
		return nil
	}
	return &value
}

func stringPtr(value string) *string {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return nil
	}
	return &trimmed
}

func defaultString(value string, fallback string) string {
	if strings.TrimSpace(value) == "" {
		return fallback
	}
	return strings.TrimSpace(value)
}
