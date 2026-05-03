package model

import (
	"time"

	"github.com/dkhvan-dev/flyfy/backend/services/attraction-service/internal/domain/enum"
	"github.com/google/uuid"
)

type Attraction struct {
	ID            uuid.UUID
	AuthorUserID  uuid.UUID
	DefaultLocale string
	Locale        string
	Title         string
	Description   string
	CountryCode   string
	CityID        string
	Category      enum.AttractionCategory
	PriceAmount   *float64
	PriceCurrency *string
	DurationValue *int
	DurationUnit  *enum.DurationUnit
	Rating        float64
	ReviewCount   int
	Spots         *int
	Source        enum.ContentSource
	Status        enum.AttractionStatus
	Tags          []string
	VisitInfo     AttractionVisitInfo
	Translations  map[string]AttractionTranslation
	Media         []AttractionMedia
	CreatedAt     time.Time
	UpdatedAt     time.Time
	DeletedAt     *time.Time
}

func (a *Attraction) IsPublished() bool {
	return a.Status == enum.StatusPublished && a.DeletedAt == nil
}

func (a *Attraction) IsDeleted() bool {
	return a.DeletedAt != nil
}

func (a *Attraction) IsOwnedBy(userID uuid.UUID) bool {
	return a.AuthorUserID == userID
}

type AttractionVisitInfo struct {
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

type AttractionMedia struct {
	ID           uuid.UUID
	AttractionID uuid.UUID
	FileID       uuid.UUID
	ExternalURL  string
	SourceURL    string
	Credit       string
	License      string
	MediaType    enum.MediaType
	Position     int
	CreatedAt    time.Time
}

type AttractionTranslation struct {
	AttractionID uuid.UUID
	Locale       string
	Title        string
	Description  string
	CreatedAt    time.Time
	UpdatedAt    time.Time
}

type AttractionListFilter struct {
	Search         string
	Locale         string
	Category       string
	CountryCode    string
	CityID         string
	PriceMin       *float64
	PriceMax       *float64
	DurationMin    *int
	DurationMax    *int
	DurationUnit   *enum.DurationUnit
	SpotsMin       *int
	MinRating      *float64
	AuthorUserID   *uuid.UUID
	IncludeDeleted bool
	Sort           string
	Limit          int
	Offset         int
}
