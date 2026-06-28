package model

import (
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"kz/inflap/backend/services/place-service/internal/domain/enum"
)

type Place struct {
	ID                uuid.UUID
	AuthorUserID      uuid.UUID
	DefaultLocale     string
	Locale            string
	Title             string
	Description       string
	CountryCode       string
	CityID            string
	AccessCities      []PlaceCityLink
	DepartureCities   []PlaceCityLink
	Latitude          *float64
	Longitude         *float64
	LocationSourceURL string
	Category          enum.PlaceCategory
	PriceAmount       *float64
	PriceCurrency     *string
	DurationValue     *int
	DurationUnit      *enum.DurationUnit
	Rating            float64
	ReviewCount       int
	Spots             *int
	Source            enum.ContentSource
	Status            enum.PlaceStatus
	Tags              []string
	VisitInfo         PlaceVisitInfo
	Translations      map[string]PlaceTranslation
	Media             []PlaceMedia
	CreatedAt         time.Time
	UpdatedAt         time.Time
	DeletedAt         *time.Time
}

type PlaceCityLink struct {
	PlaceID     uuid.UUID
	Kind        string
	CountryCode string
	CityID      string
	Position    int
	CreatedAt   time.Time
}

func (a *Place) IsPublished() bool {
	return a.Status == enum.StatusPublished && a.DeletedAt == nil
}

func (a *Place) IsDeleted() bool {
	return a.DeletedAt != nil
}

func (a *Place) IsOwnedBy(userID uuid.UUID) bool {
	return a.AuthorUserID == userID
}

type PlaceFeeDetail struct {
	Title         map[string]string `json:"title,omitempty"`
	Description   map[string]string `json:"description,omitempty"`
	Amount        *float64          `json:"amount,omitempty"`
	Currency      string            `json:"currency,omitempty"`
	Unit          string            `json:"unit,omitempty"`
	IsApproximate bool              `json:"isApproximate,omitempty"`
	SortOrder     int               `json:"sortOrder,omitempty"`
}

type LocalizedText map[string]string

type PlaceVisitDuration struct {
	MinMinutes *int          `json:"minMinutes,omitempty"`
	MaxMinutes *int          `json:"maxMinutes,omitempty"`
	Note       LocalizedText `json:"note,omitempty"`
}

type PlaceFeeItem struct {
	Type          string        `json:"type,omitempty"`
	Title         LocalizedText `json:"title,omitempty"`
	Description   LocalizedText `json:"description,omitempty"`
	Amount        *float64      `json:"amount,omitempty"`
	MinAmount     *float64      `json:"minAmount,omitempty"`
	MaxAmount     *float64      `json:"maxAmount,omitempty"`
	Currency      string        `json:"currency,omitempty"`
	Unit          string        `json:"unit,omitempty"`
	Required      bool          `json:"required,omitempty"`
	IsApproximate bool          `json:"isApproximate,omitempty"`
	Note          LocalizedText `json:"note,omitempty"`
	SortOrder     int           `json:"sortOrder,omitempty"`
}

type PlaceAccessOption struct {
	TransportType      string        `json:"transportType,omitempty"`
	DurationMinMinutes *int          `json:"durationMinMinutes,omitempty"`
	DurationMaxMinutes *int          `json:"durationMaxMinutes,omitempty"`
	DistanceKm         *float64      `json:"distanceKm,omitempty"`
	RouteHint          LocalizedText `json:"routeHint,omitempty"`
	RoadCondition      string        `json:"roadCondition,omitempty"`
	Requires4x4        bool          `json:"requires4x4,omitempty"`
	ParkingNote        LocalizedText `json:"parkingNote,omitempty"`
	LastSegmentNote    LocalizedText `json:"lastSegmentNote,omitempty"`
	Note               LocalizedText `json:"note,omitempty"`
	SortOrder          int           `json:"sortOrder,omitempty"`
}

type PlacePracticalNote struct {
	NoteType  string        `json:"noteType,omitempty"`
	Title     LocalizedText `json:"title,omitempty"`
	Body      LocalizedText `json:"body,omitempty"`
	Priority  string        `json:"priority,omitempty"`
	SortOrder int           `json:"sortOrder,omitempty"`
}

type PlaceRecommendedItem struct {
	ItemType   string        `json:"itemType,omitempty"`
	Title      LocalizedText `json:"title,omitempty"`
	Note       LocalizedText `json:"note,omitempty"`
	Importance string        `json:"importance,omitempty"`
	Season     string        `json:"season,omitempty"`
	SortOrder  int           `json:"sortOrder,omitempty"`
}

type PlaceOpeningHours struct {
	Is24Hours bool           `json:"is24Hours,omitempty"`
	Days      map[string]any `json:"days,omitempty"`
	Seasonal  LocalizedText  `json:"seasonal,omitempty"`
	Summary   LocalizedText  `json:"summary,omitempty"`
}

type PlaceSeason struct {
	Months []int         `json:"months,omitempty"`
	Note   LocalizedText `json:"note,omitempty"`
}

type PlaceLink struct {
	Kind string `json:"kind,omitempty"`
	URL  string `json:"url,omitempty"`
}

type PlaceVisitInfo struct {
	BestTime         string                 `json:"bestTime,omitempty"`
	Accessibility    string                 `json:"accessibility,omitempty"`
	BookingRequired  *bool                  `json:"bookingRequired,omitempty"`
	OpeningHours     *PlaceOpeningHours     `json:"openingHours,omitempty"`
	Amenities        []string               `json:"amenities,omitempty"`
	Audience         []string               `json:"audience,omitempty"`
	SafetyNotes      []string               `json:"safetyNotes,omitempty"`
	NearbyIDs        []uuid.UUID            `json:"nearbyIds,omitempty"`
	LocalizedTips    map[string]string      `json:"localizedTips,omitempty"`
	Season           *PlaceSeason           `json:"season,omitempty"`
	GettingThere     LocalizedText          `json:"gettingThere,omitempty"`
	Included         []LocalizedText        `json:"included,omitempty"`
	Excluded         []LocalizedText        `json:"excluded,omitempty"`
	Links            []PlaceLink            `json:"links,omitempty"`
	FeeDetails       []PlaceFeeDetail       `json:"feeDetails,omitempty"`
	PriceNote        LocalizedText          `json:"priceNote,omitempty"`
	TimeOnSite       *PlaceVisitDuration    `json:"timeOnSite,omitempty"`
	CarTravelTime    *PlaceVisitDuration    `json:"carTravelTime,omitempty"`
	RoadCondition    string                 `json:"roadCondition,omitempty"`
	FeeItems         []PlaceFeeItem         `json:"feeItems,omitempty"`
	AccessOptions    []PlaceAccessOption    `json:"accessOptions,omitempty"`
	PracticalNotes   []PlacePracticalNote   `json:"practicalNotes,omitempty"`
	RecommendedItems []PlaceRecommendedItem `json:"recommendedItems,omitempty"`
	LastVerifiedAt   *time.Time             `json:"lastVerifiedAt,omitempty"`
}

func (i *PlaceVisitInfo) UnmarshalJSON(data []byte) error {
	var raw map[string]json.RawMessage
	if err := json.Unmarshal(data, &raw); err != nil {
		return err
	}

	lastVerifiedAtRaw := raw["lastVerifiedAt"]
	delete(raw, "lastVerifiedAt")

	withoutDate, err := json.Marshal(raw)
	if err != nil {
		return err
	}

	type placeVisitInfoAlias PlaceVisitInfo
	var decoded placeVisitInfoAlias
	if err := json.Unmarshal(withoutDate, &decoded); err != nil {
		return err
	}

	lastVerifiedAt, err := parsePlaceVisitInfoLastVerifiedAt(lastVerifiedAtRaw)
	if err != nil {
		return err
	}
	decoded.LastVerifiedAt = lastVerifiedAt

	*i = PlaceVisitInfo(decoded)
	return nil
}

func parsePlaceVisitInfoLastVerifiedAt(raw json.RawMessage) (*time.Time, error) {
	if len(raw) == 0 {
		return nil, nil
	}

	value := strings.TrimSpace(string(raw))
	if value == "" || value == "null" {
		return nil, nil
	}

	var text string
	if err := json.Unmarshal(raw, &text); err != nil {
		var parsed time.Time
		if timeErr := json.Unmarshal(raw, &parsed); timeErr == nil {
			return &parsed, nil
		}
		return nil, fmt.Errorf("lastVerifiedAt must be a string date: %w", err)
	}

	text = strings.TrimSpace(text)
	if text == "" {
		return nil, nil
	}

	for _, layout := range []string{time.RFC3339Nano, time.RFC3339, time.DateOnly} {
		parsed, err := time.Parse(layout, text)
		if err == nil {
			return &parsed, nil
		}
	}

	return nil, fmt.Errorf("lastVerifiedAt %q must use RFC3339 or YYYY-MM-DD", text)
}

type PlaceMedia struct {
	ID          uuid.UUID
	PlaceID     uuid.UUID
	FileID      uuid.UUID
	ExternalURL string
	SourceURL   string
	Credit      string
	License     string
	MediaType   enum.MediaType
	Position    int
	CreatedAt   time.Time
}

type PlaceTranslation struct {
	PlaceID     uuid.UUID
	Locale      string
	Title       string
	Description string
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

type PlaceListFilter struct {
	Search          string
	Locale          string
	Category        string
	CountryCode     string
	CityID          string
	RegionID        string
	AccessCityID    string
	DepartureCityID string
	PriceMin        *float64
	PriceMax        *float64
	DurationMin     *int
	DurationMax     *int
	DurationUnit    *enum.DurationUnit
	SpotsMin        *int
	MinRating       *float64
	Latitude        *float64
	Longitude       *float64
	AuthorUserID    *uuid.UUID
	IncludeDeleted  bool
	Sort            string
	Limit           int
	Offset          int
}
