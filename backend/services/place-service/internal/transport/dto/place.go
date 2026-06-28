package dto

type CreatePlaceRequest struct {
	Title             string                             `json:"title"`
	Description       string                             `json:"description"`
	DefaultLocale     string                             `json:"defaultLocale"`
	Translations      map[string]PlaceTranslationRequest `json:"translations"`
	CountryCode       string                             `json:"countryCode"`
	CityID            string                             `json:"cityId"`
	AccessCities      []PlaceCityLinkRequest             `json:"accessCities,omitempty"`
	DepartureCities   []PlaceCityLinkRequest             `json:"departureCities,omitempty"`
	Latitude          *float64                           `json:"latitude"`
	Longitude         *float64                           `json:"longitude"`
	LocationSourceURL string                             `json:"locationSourceUrl"`
	Category          string                             `json:"category"`
	PriceAmount       *float64                           `json:"priceAmount"`
	PriceCurrency     *string                            `json:"priceCurrency"`
	DurationValue     *int                               `json:"durationValue"`
	DurationUnit      *string                            `json:"durationUnit"`
	Rating            float64                            `json:"rating"`
	Spots             *int                               `json:"spots"`
	Status            string                             `json:"status"`
	Tags              []string                           `json:"tags"`
	VisitInfo         *PlaceVisitInfoRequest             `json:"visitInfo,omitempty"`
}

type UpdatePlaceRequest struct {
	Title             string                             `json:"title"`
	Description       string                             `json:"description"`
	DefaultLocale     string                             `json:"defaultLocale"`
	Translations      map[string]PlaceTranslationRequest `json:"translations"`
	CountryCode       string                             `json:"countryCode"`
	CityID            string                             `json:"cityId"`
	AccessCities      []PlaceCityLinkRequest             `json:"accessCities,omitempty"`
	DepartureCities   []PlaceCityLinkRequest             `json:"departureCities,omitempty"`
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
	VisitInfo         *PlaceVisitInfoRequest             `json:"visitInfo,omitempty"`
}

type PlaceTranslationRequest struct {
	Title       string `json:"title"`
	Description string `json:"description"`
}

type PlaceCityLinkRequest struct {
	CountryCode string `json:"countryCode,omitempty"`
	CityID      string `json:"cityId"`
}

type LinkDTO struct {
	Kind string `json:"kind"`
	URL  string `json:"url"`
}

type OpeningHoursRequest struct {
	Is24Hours bool              `json:"is24Hours"`
	Days      map[string]any    `json:"days,omitempty"`
	Seasonal  map[string]string `json:"seasonal,omitempty"`
	Summary   map[string]string `json:"summary,omitempty"`
}

type SeasonRequest struct {
	Months []int             `json:"months,omitempty"`
	Note   map[string]string `json:"note,omitempty"`
}

type VisitDurationRequest struct {
	MinMinutes *int              `json:"minMinutes,omitempty"`
	MaxMinutes *int              `json:"maxMinutes,omitempty"`
	Note       map[string]string `json:"note,omitempty"`
}

type AccessOptionRequest struct {
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

type PracticalNoteRequest struct {
	NoteType  string            `json:"noteType,omitempty"`
	Title     map[string]string `json:"title,omitempty"`
	Body      map[string]string `json:"body,omitempty"`
	Priority  string            `json:"priority,omitempty"`
	SortOrder int               `json:"sortOrder,omitempty"`
}

type RecommendedItemRequest struct {
	ItemType   string            `json:"itemType,omitempty"`
	Title      map[string]string `json:"title,omitempty"`
	Note       map[string]string `json:"note,omitempty"`
	Importance string            `json:"importance,omitempty"`
	Season     string            `json:"season,omitempty"`
	SortOrder  int               `json:"sortOrder,omitempty"`
}

type PlaceVisitInfoRequest struct {
	BestTime         string                   `json:"bestTime"`
	Accessibility    string                   `json:"accessibility"`
	BookingRequired  *bool                    `json:"bookingRequired"`
	OpeningHours     *OpeningHoursRequest     `json:"openingHours,omitempty"`
	Amenities        []string                 `json:"amenities"`
	Audience         []string                 `json:"audience"`
	SafetyNotes      []string                 `json:"safetyNotes"`
	NearbyIDs        []string                 `json:"nearbyIds"`
	LocalizedTips    map[string]string        `json:"localizedTips"`
	Season           *SeasonRequest           `json:"season,omitempty"`
	GettingThere     map[string]string        `json:"gettingThere,omitempty"`
	Included         []map[string]string      `json:"included,omitempty"`
	Excluded         []map[string]string      `json:"excluded,omitempty"`
	Links            []LinkDTO                `json:"links,omitempty"`
	FeeDetails       []FeeDetailRequest       `json:"feeDetails,omitempty"`
	PriceNote        map[string]string        `json:"priceNote,omitempty"`
	TimeOnSite       *VisitDurationRequest    `json:"timeOnSite,omitempty"`
	CarTravelTime    *VisitDurationRequest    `json:"carTravelTime,omitempty"`
	RoadCondition    string                   `json:"roadCondition,omitempty"`
	FeeItems         []FeeDetailRequest       `json:"feeItems,omitempty"`
	AccessOptions    []AccessOptionRequest    `json:"accessOptions,omitempty"`
	PracticalNotes   []PracticalNoteRequest   `json:"practicalNotes,omitempty"`
	RecommendedItems []RecommendedItemRequest `json:"recommendedItems,omitempty"`
}

type FeeDetailRequest struct {
	Title         map[string]string `json:"title"`
	Description   map[string]string `json:"description"`
	Amount        *float64          `json:"amount"`
	Type          string            `json:"type,omitempty"`
	MinAmount     *float64          `json:"minAmount,omitempty"`
	MaxAmount     *float64          `json:"maxAmount,omitempty"`
	Currency      string            `json:"currency"`
	Unit          string            `json:"unit"`
	Required      bool              `json:"required,omitempty"`
	IsApproximate bool              `json:"isApproximate"`
	Note          map[string]string `json:"note,omitempty"`
	SortOrder     int               `json:"sortOrder"`
}

type MediaItemRequest struct {
	FileID      string `json:"fileId"`
	ExternalURL string `json:"externalUrl,omitempty"`
	SourceURL   string `json:"sourceUrl,omitempty"`
	Credit      string `json:"credit,omitempty"`
	License     string `json:"license,omitempty"`
	MediaType   string `json:"mediaType"`
	Position    int    `json:"position"`
}

type ReplaceMediaRequest struct {
	Media []MediaItemRequest `json:"media"`
}

type CreateReviewRequest struct {
	Rating  float64            `json:"rating"`
	Comment string             `json:"comment"`
	Media   []MediaItemRequest `json:"media"`
}

type AuthorResponse struct {
	UserID       string  `json:"userId"`
	Nickname     *string `json:"nickname,omitempty"`
	AvatarFileID *string `json:"avatarFileId,omitempty"`
}

type MediaResponse struct {
	ID          string `json:"id"`
	FileID      string `json:"fileId"`
	ExternalURL string `json:"externalUrl,omitempty"`
	SourceURL   string `json:"sourceUrl,omitempty"`
	Credit      string `json:"credit,omitempty"`
	License     string `json:"license,omitempty"`
	MediaType   string `json:"mediaType"`
	Position    int    `json:"position"`
}

type PlaceResponse struct {
	ID                string                              `json:"id"`
	Locale            string                              `json:"locale"`
	DefaultLocale     string                              `json:"defaultLocale"`
	Title             string                              `json:"title"`
	Description       string                              `json:"description"`
	CountryCode       string                              `json:"countryCode"`
	CityID            string                              `json:"cityId"`
	AccessCities      []PlaceCityLinkResponse             `json:"accessCities,omitempty"`
	DepartureCities   []PlaceCityLinkResponse             `json:"departureCities,omitempty"`
	Latitude          *float64                            `json:"latitude,omitempty"`
	Longitude         *float64                            `json:"longitude,omitempty"`
	LocationSourceURL string                              `json:"locationSourceUrl,omitempty"`
	Category          string                              `json:"category"`
	PriceAmount       *float64                            `json:"priceAmount,omitempty"`
	PriceCurrency     *string                             `json:"priceCurrency,omitempty"`
	PriceSummaryLabel string                              `json:"priceSummaryLabel,omitempty"`
	DurationValue     *int                                `json:"durationValue,omitempty"`
	DurationUnit      *string                             `json:"durationUnit,omitempty"`
	Rating            float64                             `json:"rating"`
	ReviewCount       int                                 `json:"reviewCount"`
	Spots             *int                                `json:"spots,omitempty"`
	Source            string                              `json:"source"`
	Status            string                              `json:"status"`
	Tags              []string                            `json:"tags"`
	VisitInfo         PlaceVisitInfoResponse              `json:"visitInfo"`
	VisitInfoLocales  *PlaceVisitInfoLocalizedResponse    `json:"visitInfoLocales,omitempty"`
	Translations      map[string]PlaceTranslationResponse `json:"translations,omitempty"`
	Media             []MediaResponse                     `json:"media"`
	Author            AuthorResponse                      `json:"author"`
	CreatedAt         string                              `json:"createdAt"`
	UpdatedAt         string                              `json:"updatedAt"`
	DeletedAt         *string                             `json:"deletedAt,omitempty"`
}

type PlaceCityLinkResponse struct {
	CountryCode string `json:"countryCode"`
	CityID      string `json:"cityId"`
}

type PlaceTranslationResponse struct {
	Title       string `json:"title"`
	Description string `json:"description"`
}

type OpeningHoursResponse struct {
	Is24Hours bool           `json:"is24Hours,omitempty"`
	Days      map[string]any `json:"days,omitempty"`
	Seasonal  string         `json:"seasonal,omitempty"`
	Summary   string         `json:"summary,omitempty"`
}

type SeasonResponse struct {
	Months []int  `json:"months,omitempty"`
	Note   string `json:"note,omitempty"`
}

type VisitDurationResponse struct {
	MinMinutes *int   `json:"minMinutes,omitempty"`
	MaxMinutes *int   `json:"maxMinutes,omitempty"`
	Note       string `json:"note,omitempty"`
}

type AccessOptionResponse struct {
	TransportType      string   `json:"transportType,omitempty"`
	DurationMinMinutes *int     `json:"durationMinMinutes,omitempty"`
	DurationMaxMinutes *int     `json:"durationMaxMinutes,omitempty"`
	DistanceKm         *float64 `json:"distanceKm,omitempty"`
	RouteHint          string   `json:"routeHint,omitempty"`
	RoadCondition      string   `json:"roadCondition,omitempty"`
	Requires4x4        bool     `json:"requires4x4,omitempty"`
	ParkingNote        string   `json:"parkingNote,omitempty"`
	LastSegmentNote    string   `json:"lastSegmentNote,omitempty"`
	Note               string   `json:"note,omitempty"`
	SortOrder          int      `json:"sortOrder,omitempty"`
}

type PracticalNoteResponse struct {
	NoteType  string `json:"noteType,omitempty"`
	Title     string `json:"title,omitempty"`
	Body      string `json:"body,omitempty"`
	Priority  string `json:"priority,omitempty"`
	SortOrder int    `json:"sortOrder,omitempty"`
}

type RecommendedItemResponse struct {
	ItemType   string `json:"itemType,omitempty"`
	Title      string `json:"title,omitempty"`
	Note       string `json:"note,omitempty"`
	Importance string `json:"importance,omitempty"`
	Season     string `json:"season,omitempty"`
	SortOrder  int    `json:"sortOrder,omitempty"`
}

type PlaceVisitReferenceListResponse struct {
	Categories map[string][]PlaceVisitReferenceValueResponse `json:"categories"`
}

type PlaceVisitReferenceValueResponse struct {
	Code      string            `json:"code"`
	Label     string            `json:"label"`
	Labels    map[string]string `json:"labels,omitempty"`
	SortOrder int               `json:"sortOrder"`
	Active    bool              `json:"active"`
}

type PlaceVisitInfoResponse struct {
	BestTime         string                    `json:"bestTime,omitempty"`
	Accessibility    string                    `json:"accessibility,omitempty"`
	BookingRequired  *bool                     `json:"bookingRequired,omitempty"`
	OpeningHours     *OpeningHoursResponse     `json:"openingHours,omitempty"`
	Amenities        []string                  `json:"amenities,omitempty"`
	Audience         []string                  `json:"audience,omitempty"`
	SafetyNotes      []string                  `json:"safetyNotes,omitempty"`
	NearbyIDs        []string                  `json:"nearbyIds,omitempty"`
	LocalizedTips    map[string]string         `json:"localizedTips,omitempty"`
	Season           *SeasonResponse           `json:"season,omitempty"`
	GettingThere     string                    `json:"gettingThere,omitempty"`
	Included         []string                  `json:"included,omitempty"`
	Excluded         []string                  `json:"excluded,omitempty"`
	Links            []LinkDTO                 `json:"links,omitempty"`
	FeeDetails       []FeeDetailResponse       `json:"feeDetails,omitempty"`
	PriceNote        string                    `json:"priceNote,omitempty"`
	TimeOnSite       *VisitDurationResponse    `json:"timeOnSite,omitempty"`
	CarTravelTime    *VisitDurationResponse    `json:"carTravelTime,omitempty"`
	RoadCondition    string                    `json:"roadCondition,omitempty"`
	FeeItems         []FeeDetailResponse       `json:"feeItems,omitempty"`
	AccessOptions    []AccessOptionResponse    `json:"accessOptions,omitempty"`
	PracticalNotes   []PracticalNoteResponse   `json:"practicalNotes,omitempty"`
	RecommendedItems []RecommendedItemResponse `json:"recommendedItems,omitempty"`
}

type PlaceVisitInfoLocalizedResponse struct {
	OpeningHours     map[string]string                  `json:"openingHours,omitempty"`
	PriceNote        map[string]string                  `json:"priceNote,omitempty"`
	TimeOnSite       *VisitDurationLocalizedResponse    `json:"timeOnSite,omitempty"`
	CarTravelTime    *VisitDurationLocalizedResponse    `json:"carTravelTime,omitempty"`
	FeeDetails       []FeeDetailLocalizedResponse       `json:"feeDetails,omitempty"`
	FeeItems         []FeeDetailLocalizedResponse       `json:"feeItems,omitempty"`
	AccessOptions    []AccessOptionLocalizedResponse    `json:"accessOptions,omitempty"`
	PracticalNotes   []PracticalNoteLocalizedResponse   `json:"practicalNotes,omitempty"`
	RecommendedItems []RecommendedItemLocalizedResponse `json:"recommendedItems,omitempty"`
}

type VisitDurationLocalizedResponse struct {
	MinMinutes *int              `json:"minMinutes,omitempty"`
	MaxMinutes *int              `json:"maxMinutes,omitempty"`
	Note       map[string]string `json:"note,omitempty"`
}

type FeeDetailLocalizedResponse struct {
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

type AccessOptionLocalizedResponse struct {
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

type PracticalNoteLocalizedResponse struct {
	NoteType  string            `json:"noteType,omitempty"`
	Title     map[string]string `json:"title,omitempty"`
	Body      map[string]string `json:"body,omitempty"`
	Priority  string            `json:"priority,omitempty"`
	SortOrder int               `json:"sortOrder,omitempty"`
}

type RecommendedItemLocalizedResponse struct {
	ItemType   string            `json:"itemType,omitempty"`
	Title      map[string]string `json:"title,omitempty"`
	Note       map[string]string `json:"note,omitempty"`
	Importance string            `json:"importance,omitempty"`
	Season     string            `json:"season,omitempty"`
	SortOrder  int               `json:"sortOrder,omitempty"`
}

type FeeDetailResponse struct {
	Title         string   `json:"title"`
	Description   string   `json:"description,omitempty"`
	Amount        *float64 `json:"amount,omitempty"`
	Type          string   `json:"type,omitempty"`
	MinAmount     *float64 `json:"minAmount,omitempty"`
	MaxAmount     *float64 `json:"maxAmount,omitempty"`
	Currency      string   `json:"currency,omitempty"`
	Unit          string   `json:"unit,omitempty"`
	Required      bool     `json:"required,omitempty"`
	IsApproximate bool     `json:"isApproximate,omitempty"`
	Note          string   `json:"note,omitempty"`
	SortOrder     int      `json:"sortOrder,omitempty"`
}

type PlaceListResponse struct {
	Items []*PlaceResponse `json:"items"`
	Total int              `json:"total"`
}

type ReviewResponse struct {
	ID        string          `json:"id"`
	PlaceID   string          `json:"placeId"`
	Rating    float64         `json:"rating"`
	Comment   string          `json:"comment"`
	Media     []MediaResponse `json:"media"`
	Author    AuthorResponse  `json:"author"`
	CreatedAt string          `json:"createdAt"`
	UpdatedAt string          `json:"updatedAt"`
}

type ReviewListResponse struct {
	Items []*ReviewResponse `json:"items"`
	Total int               `json:"total"`
}

type RecalculateRatingResponse struct {
	PlaceID     string  `json:"placeId"`
	Rating      float64 `json:"rating"`
	ReviewCount int     `json:"reviewCount"`
}

type ApplyRatingSourceSnapshotRequest struct {
	Source      string  `json:"source"`
	RatingAvg   float64 `json:"ratingAvg"`
	ReviewCount int     `json:"reviewCount"`
}
