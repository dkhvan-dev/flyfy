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

func (c *Client) ListVisitReferences(ctx context.Context, locale string) (model.PlaceVisitReferenceCatalog, error) {
	values := url.Values{}
	setQuery(values, "locale", locale)
	path := "/internal/v1/admin/place-visit-references"
	if encoded := values.Encode(); encoded != "" {
		path += "?" + encoded
	}
	var resp placeVisitReferenceListResponse
	if err := c.doJSON(ctx, http.MethodGet, path, nil, nil, &resp); err != nil {
		return model.PlaceVisitReferenceCatalog{}, err
	}
	return resp.toModel(), nil
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

type placeVisitReferenceListResponse struct {
	Categories map[string][]placeVisitReferenceValueResponse `json:"categories"`
}

type placeVisitReferenceValueResponse struct {
	Code      string            `json:"code"`
	Label     string            `json:"label"`
	Labels    map[string]string `json:"labels"`
	SortOrder int               `json:"sortOrder"`
	Active    bool              `json:"active"`
}

func (r placeVisitReferenceListResponse) toModel() model.PlaceVisitReferenceCatalog {
	catalog := model.PlaceVisitReferenceCatalog{
		Categories: make(map[string][]model.PlaceVisitReferenceValue, len(r.Categories)),
	}
	for category, values := range r.Categories {
		category = strings.TrimSpace(category)
		if category == "" {
			continue
		}
		for _, value := range values {
			code := strings.ToUpper(strings.TrimSpace(value.Code))
			if code == "" {
				continue
			}
			catalog.Categories[category] = append(catalog.Categories[category], model.PlaceVisitReferenceValue{
				Code:      code,
				Label:     strings.TrimSpace(value.Label),
				Labels:    value.Labels,
				SortOrder: value.SortOrder,
				Active:    value.Active,
			})
		}
	}
	return catalog
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
	VisitInfoLocales  *placeVisitInfoLocalizedResponse    `json:"visitInfoLocales"`
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
	BestTime         string                    `json:"bestTime"`
	Accessibility    string                    `json:"accessibility"`
	BookingRequired  *bool                     `json:"bookingRequired"`
	OpeningHours     openingHoursText          `json:"openingHours"`
	Amenities        []string                  `json:"amenities"`
	Audience         []string                  `json:"audience"`
	SafetyNotes      []string                  `json:"safetyNotes"`
	NearbyIDs        []string                  `json:"nearbyIds"`
	LocalizedTips    map[string]string         `json:"localizedTips"`
	PriceNote        string                    `json:"priceNote"`
	TimeOnSite       *visitDurationResponse    `json:"timeOnSite"`
	CarTravelTime    *visitDurationResponse    `json:"carTravelTime"`
	RoadCondition    string                    `json:"roadCondition"`
	FeeDetails       []feeDetailResponse       `json:"feeDetails"`
	FeeItems         []feeDetailResponse       `json:"feeItems"`
	AccessOptions    []accessOptionResponse    `json:"accessOptions"`
	PracticalNotes   []practicalNoteResponse   `json:"practicalNotes"`
	RecommendedItems []recommendedItemResponse `json:"recommendedItems"`
}

type placeVisitInfoLocalizedResponse struct {
	OpeningHours     map[string]string `json:"openingHours"`
	PriceNote        map[string]string `json:"priceNote"`
	TimeOnSite       *visitDuration    `json:"timeOnSite"`
	CarTravelTime    *visitDuration    `json:"carTravelTime"`
	FeeDetails       []feeDetail       `json:"feeDetails"`
	FeeItems         []feeDetail       `json:"feeItems"`
	AccessOptions    []accessOption    `json:"accessOptions"`
	PracticalNotes   []practicalNote   `json:"practicalNotes"`
	RecommendedItems []recommendedItem `json:"recommendedItems"`
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
	visitInfo := model.PlaceVisitInfo{
		BestTime:         r.VisitInfo.BestTime,
		Accessibility:    r.VisitInfo.Accessibility,
		BookingRequired:  r.VisitInfo.BookingRequired,
		OpeningHours:     r.VisitInfo.OpeningHours.String(),
		Amenities:        r.VisitInfo.Amenities,
		Audience:         r.VisitInfo.Audience,
		SafetyNotes:      r.VisitInfo.SafetyNotes,
		NearbyIDs:        r.VisitInfo.NearbyIDs,
		LocalizedTips:    r.VisitInfo.LocalizedTips,
		PriceNote:        r.VisitInfo.PriceNote,
		TimeOnSite:       r.VisitInfo.TimeOnSite.toModel(),
		CarTravelTime:    r.VisitInfo.CarTravelTime.toModel(),
		RoadCondition:    r.VisitInfo.RoadCondition,
		FeeDetails:       feeDetailsToModel(r.VisitInfo.FeeDetails),
		FeeItems:         feeDetailsToModel(r.VisitInfo.FeeItems),
		AccessOptions:    accessOptionsToModel(r.VisitInfo.AccessOptions),
		PracticalNotes:   practicalNotesToModel(r.VisitInfo.PracticalNotes),
		RecommendedItems: recommendedItemsToModel(r.VisitInfo.RecommendedItems),
	}
	if r.VisitInfoLocales != nil {
		r.VisitInfoLocales.mergeInto(&visitInfo)
	}
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
		VisitInfo:         visitInfo,
		Translations:      translationsToModel(r.Translations),
		Media:             mediaToModel(r.Media),
		CreatedAt:         parseTime(r.CreatedAt),
		UpdatedAt:         parseTime(r.UpdatedAt),
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

func feeDetailsToModel(values []feeDetailResponse) []model.PlaceFeeDetail {
	out := make([]model.PlaceFeeDetail, 0, len(values))
	for _, value := range values {
		out = append(out, model.PlaceFeeDetail{
			Title:         value.Title,
			Description:   value.Description,
			Amount:        value.Amount,
			Type:          value.Type,
			MinAmount:     value.MinAmount,
			MaxAmount:     value.MaxAmount,
			Currency:      value.Currency,
			Unit:          value.Unit,
			Required:      value.Required,
			IsApproximate: value.IsApproximate,
			Note:          value.Note,
			SortOrder:     value.SortOrder,
		})
	}
	return out
}

func accessOptionsToModel(values []accessOptionResponse) []model.PlaceAccessOption {
	out := make([]model.PlaceAccessOption, 0, len(values))
	for _, value := range values {
		out = append(out, model.PlaceAccessOption{
			TransportType:      value.TransportType,
			DurationMinMinutes: value.DurationMinMinutes,
			DurationMaxMinutes: value.DurationMaxMinutes,
			DistanceKm:         value.DistanceKm,
			RouteHint:          value.RouteHint,
			RoadCondition:      value.RoadCondition,
			Requires4x4:        value.Requires4x4,
			ParkingNote:        value.ParkingNote,
			LastSegmentNote:    value.LastSegmentNote,
			Note:               value.Note,
			SortOrder:          value.SortOrder,
		})
	}
	return out
}

func practicalNotesToModel(values []practicalNoteResponse) []model.PlacePracticalNote {
	out := make([]model.PlacePracticalNote, 0, len(values))
	for _, value := range values {
		out = append(out, model.PlacePracticalNote{
			NoteType:  value.NoteType,
			Title:     value.Title,
			Body:      value.Body,
			Priority:  value.Priority,
			SortOrder: value.SortOrder,
		})
	}
	return out
}

func recommendedItemsToModel(values []recommendedItemResponse) []model.PlaceRecommendedItem {
	out := make([]model.PlaceRecommendedItem, 0, len(values))
	for _, value := range values {
		out = append(out, model.PlaceRecommendedItem{
			ItemType:   value.ItemType,
			Title:      value.Title,
			Note:       value.Note,
			Importance: value.Importance,
			Season:     value.Season,
			SortOrder:  value.SortOrder,
		})
	}
	return out
}

func (r *placeVisitInfoLocalizedResponse) mergeInto(item *model.PlaceVisitInfo) {
	if r == nil || item == nil {
		return
	}
	item.OpeningHoursLocales = localizedResponseMap(r.OpeningHours)
	if item.OpeningHours == "" {
		item.OpeningHours = firstLocalizedValue(item.OpeningHoursLocales)
	}
	item.PriceNoteLocales = localizedResponseMap(r.PriceNote)
	if item.PriceNote == "" {
		item.PriceNote = firstLocalizedValue(item.PriceNoteLocales)
	}
	item.TimeOnSite = mergeLocalizedVisitDuration(item.TimeOnSite, r.TimeOnSite)
	item.CarTravelTime = mergeLocalizedVisitDuration(item.CarTravelTime, r.CarTravelTime)
	item.FeeDetails = mergeLocalizedFeeDetails(item.FeeDetails, r.FeeDetails)
	item.FeeItems = mergeLocalizedFeeDetails(item.FeeItems, r.FeeItems)
	item.AccessOptions = mergeLocalizedAccessOptions(item.AccessOptions, r.AccessOptions)
	item.PracticalNotes = mergeLocalizedPracticalNotes(item.PracticalNotes, r.PracticalNotes)
	item.RecommendedItems = mergeLocalizedRecommendedItems(item.RecommendedItems, r.RecommendedItems)
}

func mergeLocalizedVisitDuration(existing *model.PlaceVisitDuration, raw *visitDuration) *model.PlaceVisitDuration {
	if raw == nil {
		return existing
	}
	out := &model.PlaceVisitDuration{
		MinMinutes:  raw.MinMinutes,
		MaxMinutes:  raw.MaxMinutes,
		NoteLocales: localizedResponseMap(raw.Note),
	}
	if existing != nil {
		if out.MinMinutes == nil {
			out.MinMinutes = existing.MinMinutes
		}
		if out.MaxMinutes == nil {
			out.MaxMinutes = existing.MaxMinutes
		}
		out.Note = existing.Note
	}
	if out.Note == "" {
		out.Note = firstLocalizedValue(out.NoteLocales)
	}
	return out
}

func mergeLocalizedFeeDetails(existing []model.PlaceFeeDetail, raw []feeDetail) []model.PlaceFeeDetail {
	if len(raw) == 0 {
		return existing
	}
	out := make([]model.PlaceFeeDetail, 0, len(raw))
	for idx, value := range raw {
		item := model.PlaceFeeDetail{
			TitleLocales:       localizedResponseMap(value.Title),
			DescriptionLocales: localizedResponseMap(value.Description),
			Amount:             value.Amount,
			Type:               value.Type,
			MinAmount:          value.MinAmount,
			MaxAmount:          value.MaxAmount,
			Currency:           value.Currency,
			Unit:               value.Unit,
			Required:           value.Required,
			IsApproximate:      value.IsApproximate,
			NoteLocales:        localizedResponseMap(value.Note),
			SortOrder:          value.SortOrder,
		}
		if idx < len(existing) {
			prev := existing[idx]
			item.Title = prev.Title
			item.Description = prev.Description
			item.Note = prev.Note
			if item.Amount == nil {
				item.Amount = prev.Amount
			}
			if item.Type == "" {
				item.Type = prev.Type
			}
			if item.MinAmount == nil {
				item.MinAmount = prev.MinAmount
			}
			if item.MaxAmount == nil {
				item.MaxAmount = prev.MaxAmount
			}
			if item.Currency == "" {
				item.Currency = prev.Currency
			}
			if item.Unit == "" {
				item.Unit = prev.Unit
			}
			if item.SortOrder == 0 {
				item.SortOrder = prev.SortOrder
			}
		}
		if item.Title == "" {
			item.Title = firstLocalizedValue(item.TitleLocales)
		}
		if item.Description == "" {
			item.Description = firstLocalizedValue(item.DescriptionLocales)
		}
		if item.Note == "" {
			item.Note = firstLocalizedValue(item.NoteLocales)
		}
		out = append(out, item)
	}
	return out
}

func mergeLocalizedAccessOptions(existing []model.PlaceAccessOption, raw []accessOption) []model.PlaceAccessOption {
	if len(raw) == 0 {
		return existing
	}
	out := make([]model.PlaceAccessOption, 0, len(raw))
	for idx, value := range raw {
		item := model.PlaceAccessOption{
			TransportType:          value.TransportType,
			DurationMinMinutes:     value.DurationMinMinutes,
			DurationMaxMinutes:     value.DurationMaxMinutes,
			DistanceKm:             value.DistanceKm,
			RouteHintLocales:       localizedResponseMap(value.RouteHint),
			RoadCondition:          value.RoadCondition,
			Requires4x4:            value.Requires4x4,
			ParkingNoteLocales:     localizedResponseMap(value.ParkingNote),
			LastSegmentNoteLocales: localizedResponseMap(value.LastSegmentNote),
			NoteLocales:            localizedResponseMap(value.Note),
			SortOrder:              value.SortOrder,
		}
		if idx < len(existing) {
			prev := existing[idx]
			item.RouteHint = prev.RouteHint
			item.ParkingNote = prev.ParkingNote
			item.LastSegmentNote = prev.LastSegmentNote
			item.Note = prev.Note
			if item.TransportType == "" {
				item.TransportType = prev.TransportType
			}
			if item.DurationMinMinutes == nil {
				item.DurationMinMinutes = prev.DurationMinMinutes
			}
			if item.DurationMaxMinutes == nil {
				item.DurationMaxMinutes = prev.DurationMaxMinutes
			}
			if item.DistanceKm == nil {
				item.DistanceKm = prev.DistanceKm
			}
			if item.RoadCondition == "" {
				item.RoadCondition = prev.RoadCondition
			}
			if item.SortOrder == 0 {
				item.SortOrder = prev.SortOrder
			}
		}
		if item.RouteHint == "" {
			item.RouteHint = firstLocalizedValue(item.RouteHintLocales)
		}
		if item.ParkingNote == "" {
			item.ParkingNote = firstLocalizedValue(item.ParkingNoteLocales)
		}
		if item.LastSegmentNote == "" {
			item.LastSegmentNote = firstLocalizedValue(item.LastSegmentNoteLocales)
		}
		if item.Note == "" {
			item.Note = firstLocalizedValue(item.NoteLocales)
		}
		out = append(out, item)
	}
	return out
}

func mergeLocalizedPracticalNotes(existing []model.PlacePracticalNote, raw []practicalNote) []model.PlacePracticalNote {
	if len(raw) == 0 {
		return existing
	}
	out := make([]model.PlacePracticalNote, 0, len(raw))
	for idx, value := range raw {
		item := model.PlacePracticalNote{
			NoteType:     value.NoteType,
			TitleLocales: localizedResponseMap(value.Title),
			BodyLocales:  localizedResponseMap(value.Body),
			Priority:     value.Priority,
			SortOrder:    value.SortOrder,
		}
		if idx < len(existing) {
			prev := existing[idx]
			item.Title = prev.Title
			item.Body = prev.Body
			if item.NoteType == "" {
				item.NoteType = prev.NoteType
			}
			if item.Priority == "" {
				item.Priority = prev.Priority
			}
			if item.SortOrder == 0 {
				item.SortOrder = prev.SortOrder
			}
		}
		if item.Title == "" {
			item.Title = firstLocalizedValue(item.TitleLocales)
		}
		if item.Body == "" {
			item.Body = firstLocalizedValue(item.BodyLocales)
		}
		out = append(out, item)
	}
	return out
}

func mergeLocalizedRecommendedItems(existing []model.PlaceRecommendedItem, raw []recommendedItem) []model.PlaceRecommendedItem {
	if len(raw) == 0 {
		return existing
	}
	out := make([]model.PlaceRecommendedItem, 0, len(raw))
	for idx, value := range raw {
		item := model.PlaceRecommendedItem{
			ItemType:     value.ItemType,
			TitleLocales: localizedResponseMap(value.Title),
			NoteLocales:  localizedResponseMap(value.Note),
			Importance:   value.Importance,
			Season:       value.Season,
			SortOrder:    value.SortOrder,
		}
		if idx < len(existing) {
			prev := existing[idx]
			item.Title = prev.Title
			item.Note = prev.Note
			if item.ItemType == "" {
				item.ItemType = prev.ItemType
			}
			if item.Importance == "" {
				item.Importance = prev.Importance
			}
			if item.Season == "" {
				item.Season = prev.Season
			}
			if item.SortOrder == 0 {
				item.SortOrder = prev.SortOrder
			}
		}
		if item.Title == "" {
			item.Title = firstLocalizedValue(item.TitleLocales)
		}
		if item.Note == "" {
			item.Note = firstLocalizedValue(item.NoteLocales)
		}
		out = append(out, item)
	}
	return out
}

func localizedResponseMap(values map[string]string) map[string]string {
	if len(values) == 0 {
		return nil
	}
	out := make(map[string]string, len(values))
	for locale, value := range values {
		locale = normalizeRequestLocale(locale)
		value = strings.TrimSpace(value)
		if value == "" {
			continue
		}
		out[locale] = value
	}
	if len(out) == 0 {
		return nil
	}
	return out
}

func firstLocalizedValue(values map[string]string) string {
	for _, locale := range []string{"ru", "en", "kk"} {
		if value := strings.TrimSpace(values[locale]); value != "" {
			return value
		}
	}
	return ""
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
	BestTime         string                    `json:"bestTime"`
	Accessibility    string                    `json:"accessibility"`
	BookingRequired  *bool                     `json:"bookingRequired"`
	OpeningHours     *placeOpeningHoursRequest `json:"openingHours,omitempty"`
	Amenities        []string                  `json:"amenities"`
	Audience         []string                  `json:"audience"`
	SafetyNotes      []string                  `json:"safetyNotes"`
	NearbyIDs        []string                  `json:"nearbyIds"`
	LocalizedTips    map[string]string         `json:"localizedTips"`
	PriceNote        map[string]string         `json:"priceNote,omitempty"`
	TimeOnSite       *visitDuration            `json:"timeOnSite,omitempty"`
	CarTravelTime    *visitDuration            `json:"carTravelTime,omitempty"`
	RoadCondition    string                    `json:"roadCondition,omitempty"`
	FeeDetails       []feeDetail               `json:"feeDetails,omitempty"`
	FeeItems         []feeDetail               `json:"feeItems,omitempty"`
	AccessOptions    []accessOption            `json:"accessOptions,omitempty"`
	PracticalNotes   []practicalNote           `json:"practicalNotes,omitempty"`
	RecommendedItems []recommendedItem         `json:"recommendedItems,omitempty"`
}

type visitDuration struct {
	MinMinutes *int              `json:"minMinutes,omitempty"`
	MaxMinutes *int              `json:"maxMinutes,omitempty"`
	Note       map[string]string `json:"note,omitempty"`
}

type visitDurationResponse struct {
	MinMinutes *int   `json:"minMinutes"`
	MaxMinutes *int   `json:"maxMinutes"`
	Note       string `json:"note"`
}

func (r *visitDurationResponse) toModel() *model.PlaceVisitDuration {
	if r == nil {
		return nil
	}
	return &model.PlaceVisitDuration{MinMinutes: r.MinMinutes, MaxMinutes: r.MaxMinutes, Note: r.Note}
}

type feeDetail struct {
	Title         map[string]string `json:"title,omitempty"`
	Description   map[string]string `json:"description,omitempty"`
	Amount        *float64          `json:"amount,omitempty"`
	Type          string            `json:"type,omitempty"`
	MinAmount     *float64          `json:"minAmount,omitempty"`
	MaxAmount     *float64          `json:"maxAmount,omitempty"`
	Currency      string            `json:"currency,omitempty"`
	Unit          string            `json:"unit,omitempty"`
	Required      bool              `json:"required,omitempty"`
	IsApproximate bool              `json:"isApproximate,omitempty"`
	Note          map[string]string `json:"note,omitempty"`
	SortOrder     int               `json:"sortOrder,omitempty"`
}

type feeDetailResponse struct {
	Title         string   `json:"title"`
	Description   string   `json:"description"`
	Amount        *float64 `json:"amount"`
	Type          string   `json:"type"`
	MinAmount     *float64 `json:"minAmount"`
	MaxAmount     *float64 `json:"maxAmount"`
	Currency      string   `json:"currency"`
	Unit          string   `json:"unit"`
	Required      bool     `json:"required"`
	IsApproximate bool     `json:"isApproximate"`
	Note          string   `json:"note"`
	SortOrder     int      `json:"sortOrder"`
}

type accessOption struct {
	TransportType      string            `json:"transportType,omitempty"`
	DurationMinMinutes *int              `json:"durationMinMinutes,omitempty"`
	DurationMaxMinutes *int              `json:"durationMaxMinutes,omitempty"`
	DistanceKm         *float64          `json:"distanceKm,omitempty"`
	RouteHint          map[string]string `json:"routeHint,omitempty"`
	RoadCondition      string            `json:"roadCondition,omitempty"`
	Requires4x4        bool              `json:"requires4x4,omitempty"`
	ParkingNote        map[string]string `json:"parkingNote,omitempty"`
	LastSegmentNote    map[string]string `json:"lastSegmentNote,omitempty"`
	Note               map[string]string `json:"note,omitempty"`
	SortOrder          int               `json:"sortOrder,omitempty"`
}

type accessOptionResponse struct {
	TransportType      string   `json:"transportType"`
	DurationMinMinutes *int     `json:"durationMinMinutes"`
	DurationMaxMinutes *int     `json:"durationMaxMinutes"`
	DistanceKm         *float64 `json:"distanceKm"`
	RouteHint          string   `json:"routeHint"`
	RoadCondition      string   `json:"roadCondition"`
	Requires4x4        bool     `json:"requires4x4"`
	ParkingNote        string   `json:"parkingNote"`
	LastSegmentNote    string   `json:"lastSegmentNote"`
	Note               string   `json:"note"`
	SortOrder          int      `json:"sortOrder"`
}

type practicalNote struct {
	NoteType  string            `json:"noteType,omitempty"`
	Title     map[string]string `json:"title,omitempty"`
	Body      map[string]string `json:"body,omitempty"`
	Priority  string            `json:"priority,omitempty"`
	SortOrder int               `json:"sortOrder,omitempty"`
}

type practicalNoteResponse struct {
	NoteType  string `json:"noteType"`
	Title     string `json:"title"`
	Body      string `json:"body"`
	Priority  string `json:"priority"`
	SortOrder int    `json:"sortOrder"`
}

type recommendedItem struct {
	ItemType   string            `json:"itemType,omitempty"`
	Title      map[string]string `json:"title,omitempty"`
	Note       map[string]string `json:"note,omitempty"`
	Importance string            `json:"importance,omitempty"`
	Season     string            `json:"season,omitempty"`
	SortOrder  int               `json:"sortOrder,omitempty"`
}

type recommendedItemResponse struct {
	ItemType   string `json:"itemType"`
	Title      string `json:"title"`
	Note       string `json:"note"`
	Importance string `json:"importance"`
	Season     string `json:"season"`
	SortOrder  int    `json:"sortOrder"`
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
		locale := normalizeRequestLocale(input.DefaultLocale)
		req.VisitInfo = &placeVisitInfoRequest{
			BestTime:         input.VisitInfo.BestTime,
			Accessibility:    input.VisitInfo.Accessibility,
			BookingRequired:  input.VisitInfo.BookingRequired,
			OpeningHours:     placeOpeningHoursRequestFromText(input.VisitInfo.OpeningHours, input.VisitInfo.OpeningHoursLocales, locale),
			Amenities:        input.VisitInfo.Amenities,
			Audience:         input.VisitInfo.Audience,
			SafetyNotes:      input.VisitInfo.SafetyNotes,
			NearbyIDs:        input.VisitInfo.NearbyIDs,
			LocalizedTips:    input.VisitInfo.LocalizedTips,
			PriceNote:        localizedTextMapFromModel(locale, input.VisitInfo.PriceNote, input.VisitInfo.PriceNoteLocales),
			TimeOnSite:       visitDurationFromModel(input.VisitInfo.TimeOnSite, locale),
			CarTravelTime:    visitDurationFromModel(input.VisitInfo.CarTravelTime, locale),
			RoadCondition:    input.VisitInfo.RoadCondition,
			FeeDetails:       feeDetailsFromModel(input.VisitInfo.FeeDetails, locale),
			FeeItems:         feeDetailsFromModel(input.VisitInfo.FeeItems, locale),
			AccessOptions:    accessOptionsFromModel(input.VisitInfo.AccessOptions, locale),
			PracticalNotes:   practicalNotesFromModel(input.VisitInfo.PracticalNotes, locale),
			RecommendedItems: recommendedItemsFromModel(input.VisitInfo.RecommendedItems, locale),
		}
	}
	return req
}

func normalizeRequestLocale(raw string) string {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "en":
		return "en"
	case "kk":
		return "kk"
	default:
		return "ru"
	}
}

func localizedTextMap(locale string, value string) map[string]string {
	return localizedTextMapFromModel(locale, value, nil)
}

func localizedTextMapFromModel(locale string, value string, values map[string]string) map[string]string {
	if len(values) > 0 {
		out := make(map[string]string, len(values))
		for key, item := range values {
			key = normalizeRequestLocale(key)
			item = strings.TrimSpace(item)
			if item == "" {
				continue
			}
			out[key] = item
		}
		if len(out) > 0 {
			return out
		}
	}
	value = strings.TrimSpace(value)
	if value == "" {
		return nil
	}
	return map[string]string{normalizeRequestLocale(locale): value}
}

func visitDurationFromModel(value *model.PlaceVisitDuration, locale string) *visitDuration {
	if value == nil {
		return nil
	}
	note := localizedTextMapFromModel(locale, value.Note, value.NoteLocales)
	if value.MinMinutes == nil && value.MaxMinutes == nil && len(note) == 0 {
		return nil
	}
	return &visitDuration{
		MinMinutes: value.MinMinutes,
		MaxMinutes: value.MaxMinutes,
		Note:       note,
	}
}

func feeDetailsFromModel(values []model.PlaceFeeDetail, locale string) []feeDetail {
	out := make([]feeDetail, 0, len(values))
	for _, value := range values {
		item := feeDetail{
			Title:         localizedTextMapFromModel(locale, value.Title, value.TitleLocales),
			Description:   localizedTextMapFromModel(locale, value.Description, value.DescriptionLocales),
			Amount:        value.Amount,
			Type:          strings.TrimSpace(value.Type),
			MinAmount:     value.MinAmount,
			MaxAmount:     value.MaxAmount,
			Currency:      strings.ToUpper(strings.TrimSpace(value.Currency)),
			Unit:          strings.TrimSpace(value.Unit),
			Required:      value.Required,
			IsApproximate: value.IsApproximate,
			Note:          localizedTextMapFromModel(locale, value.Note, value.NoteLocales),
			SortOrder:     value.SortOrder,
		}
		if len(item.Title) == 0 &&
			len(item.Description) == 0 &&
			item.Amount == nil &&
			item.Type == "" &&
			item.MinAmount == nil &&
			item.MaxAmount == nil &&
			item.Currency == "" &&
			item.Unit == "" &&
			!item.Required &&
			!item.IsApproximate &&
			len(item.Note) == 0 {
			continue
		}
		out = append(out, item)
	}
	return out
}

func accessOptionsFromModel(values []model.PlaceAccessOption, locale string) []accessOption {
	out := make([]accessOption, 0, len(values))
	for _, value := range values {
		item := accessOption{
			TransportType:      strings.TrimSpace(value.TransportType),
			DurationMinMinutes: value.DurationMinMinutes,
			DurationMaxMinutes: value.DurationMaxMinutes,
			DistanceKm:         value.DistanceKm,
			RouteHint:          localizedTextMapFromModel(locale, value.RouteHint, value.RouteHintLocales),
			RoadCondition:      strings.TrimSpace(value.RoadCondition),
			Requires4x4:        value.Requires4x4,
			ParkingNote:        localizedTextMapFromModel(locale, value.ParkingNote, value.ParkingNoteLocales),
			LastSegmentNote:    localizedTextMapFromModel(locale, value.LastSegmentNote, value.LastSegmentNoteLocales),
			Note:               localizedTextMapFromModel(locale, value.Note, value.NoteLocales),
			SortOrder:          value.SortOrder,
		}
		if item.TransportType == "" &&
			item.DurationMinMinutes == nil &&
			item.DurationMaxMinutes == nil &&
			item.DistanceKm == nil &&
			len(item.RouteHint) == 0 &&
			item.RoadCondition == "" &&
			!item.Requires4x4 &&
			len(item.ParkingNote) == 0 &&
			len(item.LastSegmentNote) == 0 &&
			len(item.Note) == 0 {
			continue
		}
		out = append(out, item)
	}
	return out
}

func practicalNotesFromModel(values []model.PlacePracticalNote, locale string) []practicalNote {
	out := make([]practicalNote, 0, len(values))
	for _, value := range values {
		item := practicalNote{
			NoteType:  strings.TrimSpace(value.NoteType),
			Title:     localizedTextMapFromModel(locale, value.Title, value.TitleLocales),
			Body:      localizedTextMapFromModel(locale, value.Body, value.BodyLocales),
			Priority:  strings.TrimSpace(value.Priority),
			SortOrder: value.SortOrder,
		}
		if item.NoteType == "" && len(item.Title) == 0 && len(item.Body) == 0 && item.Priority == "" {
			continue
		}
		out = append(out, item)
	}
	return out
}

func recommendedItemsFromModel(values []model.PlaceRecommendedItem, locale string) []recommendedItem {
	out := make([]recommendedItem, 0, len(values))
	for _, value := range values {
		item := recommendedItem{
			ItemType:   strings.TrimSpace(value.ItemType),
			Title:      localizedTextMapFromModel(locale, value.Title, value.TitleLocales),
			Note:       localizedTextMapFromModel(locale, value.Note, value.NoteLocales),
			Importance: strings.TrimSpace(value.Importance),
			Season:     strings.TrimSpace(value.Season),
			SortOrder:  value.SortOrder,
		}
		if item.ItemType == "" && len(item.Title) == 0 && len(item.Note) == 0 && item.Importance == "" && item.Season == "" {
			continue
		}
		out = append(out, item)
	}
	return out
}

func placeOpeningHoursRequestFromText(value string, values map[string]string, locale string) *placeOpeningHoursRequest {
	summary := localizedTextMapFromModel(locale, value, values)
	if len(summary) == 0 {
		return nil
	}
	return &placeOpeningHoursRequest{Summary: summary}
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
