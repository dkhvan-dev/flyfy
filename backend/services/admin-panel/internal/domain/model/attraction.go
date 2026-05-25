package model

import (
	"time"

	"github.com/google/uuid"
)

type AdminAttraction struct {
	ID                uuid.UUID
	Locale            string
	DefaultLocale     string
	Title             string
	Description       string
	CountryCode       string
	CityID            string
	AccessCities      []AttractionCityLink
	DepartureCities   []AttractionCityLink
	Latitude          *float64
	Longitude         *float64
	LocationSourceURL string
	Category          string
	PriceAmount       *float64
	PriceCurrency     *string
	DurationValue     *int
	DurationUnit      *string
	Rating            float64
	ReviewCount       int
	Spots             *int
	Source            string
	Status            string
	Tags              []string
	VisitInfo         AttractionVisitInfo
	Translations      map[string]AttractionTranslation
	Media             []AdminAttractionMedia
	CreatedAt         time.Time
	UpdatedAt         time.Time
	DeletedAt         *time.Time
}

type AttractionInput struct {
	Title             string
	Description       string
	DefaultLocale     string
	Translations      map[string]AttractionTranslation
	CountryCode       string
	CityID            string
	AccessCities      []AttractionCityLink
	DepartureCities   []AttractionCityLink
	Latitude          *float64
	Longitude         *float64
	LocationSourceURL string
	Category          string
	PriceAmount       *float64
	PriceCurrency     *string
	DurationValue     *int
	DurationUnit      *string
	Spots             *int
	Status            string
	Tags              []string
	VisitInfo         *AttractionVisitInfo
}

type AdminAttractionFilter struct {
	Search         string
	Locale         string
	Category       string
	CountryCode    string
	CityID         string
	Status         string
	Sort           string
	Limit          int
	Offset         int
	IncludeDeleted bool
}

type AttractionTranslation struct {
	Title       string
	Description string
}

type AttractionCityLink struct {
	CountryCode string
	CityID      string
}

type AttractionVisitInfo struct {
	BestTime        string
	Accessibility   string
	BookingRequired *bool
	OpeningHours    string
	Amenities       []string
	Audience        []string
	SafetyNotes     []string
	NearbyIDs       []string
	LocalizedTips   map[string]string
}

type AdminAttractionMedia struct {
	ID          uuid.UUID
	FileID      uuid.UUID
	ExternalURL string
	SourceURL   string
	Credit      string
	License     string
	MediaType   string
	Position    int
}

type AttractionMediaInput struct {
	FileID      uuid.UUID
	ExternalURL string
	SourceURL   string
	Credit      string
	License     string
	MediaType   string
	Position    int
}

type FileUploadInput struct {
	FileName    string
	ContentType string
	Content     []byte
	Purpose     string
	Visibility  string
	OwnerType   string
	OwnerID     uuid.UUID
}

type UploadedFile struct {
	ID uuid.UUID
}

type FileContent struct {
	ContentType string
	Content     []byte
}
