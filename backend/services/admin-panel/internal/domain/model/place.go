package model

import (
	"time"

	"github.com/google/uuid"
)

type AdminPlace struct {
	ID                uuid.UUID
	Locale            string
	DefaultLocale     string
	Title             string
	Description       string
	CountryCode       string
	CityID            string
	AccessCities      []PlaceCityLink
	DepartureCities   []PlaceCityLink
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
	VisitInfo         PlaceVisitInfo
	Translations      map[string]PlaceTranslation
	Media             []AdminPlaceMedia
	CreatedAt         time.Time
	UpdatedAt         time.Time
	DeletedAt         *time.Time
}

type PlaceInput struct {
	Title             string
	Description       string
	DefaultLocale     string
	Translations      map[string]PlaceTranslation
	CountryCode       string
	CityID            string
	AccessCities      []PlaceCityLink
	DepartureCities   []PlaceCityLink
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
	VisitInfo         *PlaceVisitInfo
}

type AdminPlaceFilter struct {
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

type PlaceTranslation struct {
	Title       string
	Description string
}

type PlaceCityLink struct {
	CountryCode string
	CityID      string
}

type PlaceVisitInfo struct {
	BestTime            string
	Accessibility       string
	BookingRequired     *bool
	OpeningHours        string
	OpeningHoursLocales map[string]string
	Amenities           []string
	Audience            []string
	SafetyNotes         []string
	NearbyIDs           []string
	LocalizedTips       map[string]string
	PriceNote           string
	PriceNoteLocales    map[string]string
	TimeOnSite          *PlaceVisitDuration
	CarTravelTime       *PlaceVisitDuration
	RoadCondition       string
	FeeDetails          []PlaceFeeDetail
	FeeItems            []PlaceFeeDetail
	AccessOptions       []PlaceAccessOption
	PracticalNotes      []PlacePracticalNote
	RecommendedItems    []PlaceRecommendedItem
}

type PlaceVisitReferenceCatalog struct {
	Categories map[string][]PlaceVisitReferenceValue
}

type PlaceVisitReferenceValue struct {
	Code      string
	Label     string
	Labels    map[string]string
	SortOrder int
	Active    bool
}

type PlaceVisitDuration struct {
	MinMinutes  *int
	MaxMinutes  *int
	Note        string
	NoteLocales map[string]string
}

type PlaceFeeDetail struct {
	Title              string
	TitleLocales       map[string]string
	Description        string
	DescriptionLocales map[string]string
	Amount             *float64
	Type               string
	MinAmount          *float64
	MaxAmount          *float64
	Currency           string
	Unit               string
	Required           bool
	IsApproximate      bool
	Note               string
	NoteLocales        map[string]string
	SortOrder          int
}

type PlaceAccessOption struct {
	TransportType          string
	DurationMinMinutes     *int
	DurationMaxMinutes     *int
	DistanceKm             *float64
	RouteHint              string
	RouteHintLocales       map[string]string
	RoadCondition          string
	Requires4x4            bool
	ParkingNote            string
	ParkingNoteLocales     map[string]string
	LastSegmentNote        string
	LastSegmentNoteLocales map[string]string
	Note                   string
	NoteLocales            map[string]string
	SortOrder              int
}

type PlacePracticalNote struct {
	NoteType     string
	Title        string
	TitleLocales map[string]string
	Body         string
	BodyLocales  map[string]string
	Priority     string
	SortOrder    int
}

type PlaceRecommendedItem struct {
	ItemType     string
	Title        string
	TitleLocales map[string]string
	Note         string
	NoteLocales  map[string]string
	Importance   string
	Season       string
	SortOrder    int
}

type AdminPlaceMedia struct {
	ID          uuid.UUID
	FileID      uuid.UUID
	ExternalURL string
	SourceURL   string
	Credit      string
	License     string
	MediaType   string
	Position    int
}

type PlaceMediaInput struct {
	FileID      uuid.UUID
	ExternalURL string
	SourceURL   string
	Credit      string
	License     string
	MediaType   string
	Position    int
}

type PlaceMediaBackfillJob struct {
	JobID       string
	CountryCode string
	Status      string
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

type FileDownloadURL struct {
	URL       string
	ExpiresAt time.Time
}
