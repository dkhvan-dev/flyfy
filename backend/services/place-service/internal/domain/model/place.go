package model

import (
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

type PlaceVisitInfo struct {
	BestTime        string            `json:"bestTime,omitempty"`
	Accessibility   string            `json:"accessibility,omitempty"`
	BookingRequired *bool             `json:"bookingRequired,omitempty"`
	OpeningHours    string            `json:"openingHours,omitempty"`
	Amenities       []string          `json:"amenities,omitempty"`
	Audience        []string          `json:"audience,omitempty"`
	SafetyNotes     []string          `json:"safetyNotes,omitempty"`
	NearbyIDs       []uuid.UUID       `json:"nearbyIds,omitempty"`
	LocalizedTips   map[string]string `json:"localizedTips,omitempty"`
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
