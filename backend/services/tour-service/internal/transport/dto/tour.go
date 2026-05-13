package dto

type TourItineraryItemRequest struct {
	StartOffsetMinutes int                                   `json:"startOffsetMinutes"`
	DurationMinutes    *int                                  `json:"durationMinutes,omitempty"`
	Title              string                                `json:"title"`
	Description        string                                `json:"description"`
	Translations       map[string]TourItineraryLocalizedCopy `json:"translations,omitempty"`
}

type TourLocalizedCopy struct {
	Title       string `json:"title,omitempty"`
	Summary     string `json:"summary,omitempty"`
	Description string `json:"description,omitempty"`
}

type TourItineraryLocalizedCopy struct {
	Title       string `json:"title,omitempty"`
	Description string `json:"description,omitempty"`
}

type CreateTourRequest struct {
	LandmarkID               *string                      `json:"landmarkId,omitempty"`
	LandmarkName             *string                      `json:"landmarkName,omitempty"`
	CategorySlug             string                       `json:"categorySlug,omitempty"`
	ProductTranslations      map[string]TourLocalizedCopy `json:"productTranslations,omitempty"`
	Visibility               string                       `json:"visibility"`
	DurationMinutes          int                          `json:"durationMinutes"`
	MaxGroupSize             int                          `json:"maxGroupSize"`
	LanguageCodes            []string                     `json:"languageCodes"`
	CountryCode              *string                      `json:"countryCode,omitempty"`
	CityName                 *string                      `json:"cityName,omitempty"`
	MeetingPoint             string                       `json:"meetingPoint"`
	Latitude                 *float64                     `json:"latitude,omitempty"`
	Longitude                *float64                     `json:"longitude,omitempty"`
	MapURL                   *string                      `json:"mapUrl,omitempty"`
	PriceAmount              float64                      `json:"priceAmount"`
	Currency                 string                       `json:"currency"`
	CoverFileID              *string                      `json:"coverFileId,omitempty"`
	ProductCoverFileID       *string                      `json:"productCoverFileId,omitempty"`
	IncludedItems            []string                     `json:"includedItems,omitempty"`
	IncludedItemTranslations map[string][]string          `json:"includedItemTranslations,omitempty"`
	Itinerary                []TourItineraryItemRequest   `json:"itinerary,omitempty"`
}

type UpdateTourRequest = CreateTourRequest

type TourItineraryItemResponse struct {
	ID                 string                                `json:"id"`
	SortOrder          int                                   `json:"sortOrder"`
	StartOffsetMinutes int                                   `json:"startOffsetMinutes"`
	DurationMinutes    *int                                  `json:"durationMinutes,omitempty"`
	Title              string                                `json:"title"`
	Description        string                                `json:"description"`
	Translations       map[string]TourItineraryLocalizedCopy `json:"translations,omitempty"`
	CreatedAt          string                                `json:"createdAt"`
	UpdatedAt          string                                `json:"updatedAt"`
}

type TourResponse struct {
	ID                       string                       `json:"id"`
	GuideProfileID           string                       `json:"guideProfileId"`
	GuideUserID              string                       `json:"guideUserId"`
	LandmarkID               *string                      `json:"landmarkId,omitempty"`
	LandmarkName             *string                      `json:"landmarkName,omitempty"`
	Title                    string                       `json:"title"`
	Summary                  string                       `json:"summary"`
	Description              string                       `json:"description"`
	Translations             map[string]TourLocalizedCopy `json:"translations,omitempty"`
	CategorySlug             string                       `json:"categorySlug"`
	Tags                     []string                     `json:"tags,omitempty"`
	Status                   string                       `json:"status"`
	Visibility               string                       `json:"visibility"`
	DurationMinutes          int                          `json:"durationMinutes"`
	MaxGroupSize             int                          `json:"maxGroupSize"`
	LanguageCodes            []string                     `json:"languageCodes"`
	CountryCode              *string                      `json:"countryCode,omitempty"`
	CityName                 *string                      `json:"cityName,omitempty"`
	MeetingPoint             string                       `json:"meetingPoint"`
	Latitude                 *float64                     `json:"latitude,omitempty"`
	Longitude                *float64                     `json:"longitude,omitempty"`
	MapURL                   *string                      `json:"mapUrl,omitempty"`
	PriceAmount              float64                      `json:"priceAmount"`
	Currency                 string                       `json:"currency"`
	CoverFileID              *string                      `json:"coverFileId,omitempty"`
	CoverImageURL            *string                      `json:"coverImageUrl,omitempty"`
	IncludedItems            []string                     `json:"includedItems,omitempty"`
	IncludedItemTranslations map[string][]string          `json:"includedItemTranslations,omitempty"`
	Itinerary                []TourItineraryItemResponse  `json:"itinerary,omitempty"`
	PublishedAt              *string                      `json:"publishedAt,omitempty"`
	DeletedAt                *string                      `json:"deletedAt,omitempty"`
	Revision                 int                          `json:"revision"`
	CreatedAt                string                       `json:"createdAt"`
	UpdatedAt                string                       `json:"updatedAt"`
}

type TourListResponse struct {
	Items   []TourResponse `json:"items"`
	HasMore bool           `json:"hasMore"`
}

type TourProductCardResponse struct {
	ID                   string                       `json:"id"`
	LandmarkID           *string                      `json:"landmarkId,omitempty"`
	LandmarkName         *string                      `json:"landmarkName,omitempty"`
	Title                string                       `json:"title"`
	Summary              string                       `json:"summary"`
	Description          string                       `json:"description"`
	Translations         map[string]TourLocalizedCopy `json:"translations,omitempty"`
	CategorySlug         string                       `json:"categorySlug"`
	Status               string                       `json:"status"`
	Visibility           string                       `json:"visibility"`
	DurationMinutes      int                          `json:"durationMinutes"`
	CountryCode          *string                      `json:"countryCode,omitempty"`
	CityName             *string                      `json:"cityName,omitempty"`
	Latitude             *float64                     `json:"latitude,omitempty"`
	Longitude            *float64                     `json:"longitude,omitempty"`
	MapURL               *string                      `json:"mapUrl,omitempty"`
	CoverFileID          *string                      `json:"coverFileId,omitempty"`
	CoverImageURL        *string                      `json:"coverImageUrl,omitempty"`
	MinPriceAmount       *float64                     `json:"minPriceAmount,omitempty"`
	Currency             *string                      `json:"currency,omitempty"`
	OffersCount          int                          `json:"offersCount"`
	PublishedOffersCount int                          `json:"publishedOffersCount"`
	NextAvailableAt      *string                      `json:"nextAvailableAt,omitempty"`
	CreatedAt            string                       `json:"createdAt"`
	UpdatedAt            string                       `json:"updatedAt"`
}

type TourProductListResponse struct {
	Items   []TourProductCardResponse `json:"items"`
	HasMore bool                      `json:"hasMore"`
}

type TourOfferResponse struct {
	ID                       string                       `json:"id"`
	ProductID                string                       `json:"productId"`
	LegacyTourID             *string                      `json:"legacyTourId,omitempty"`
	GuideProfileID           string                       `json:"guideProfileId"`
	GuideUserID              string                       `json:"guideUserId"`
	GuideRatingAvg           float64                      `json:"guideRatingAvg"`
	GuideReviewsCount        int                          `json:"guideReviewsCount"`
	GuideExperienceYears     int                          `json:"guideExperienceYears"`
	GuideDisplayName         string                       `json:"guideDisplayName,omitempty"`
	Title                    string                       `json:"title"`
	Summary                  string                       `json:"summary"`
	Description              string                       `json:"description"`
	Translations             map[string]TourLocalizedCopy `json:"translations,omitempty"`
	Status                   string                       `json:"status"`
	Visibility               string                       `json:"visibility"`
	DurationMinutes          int                          `json:"durationMinutes"`
	MaxGroupSize             int                          `json:"maxGroupSize"`
	MeetingPoint             string                       `json:"meetingPoint"`
	Latitude                 *float64                     `json:"latitude,omitempty"`
	Longitude                *float64                     `json:"longitude,omitempty"`
	MapURL                   *string                      `json:"mapUrl,omitempty"`
	PriceAmount              float64                      `json:"priceAmount"`
	Currency                 string                       `json:"currency"`
	CoverFileID              *string                      `json:"coverFileId,omitempty"`
	LanguageCodes            []string                     `json:"languageCodes"`
	IncludedItems            []string                     `json:"includedItems,omitempty"`
	IncludedItemTranslations map[string][]string          `json:"includedItemTranslations,omitempty"`
	Itinerary                []TourItineraryItemResponse  `json:"itinerary,omitempty"`
	PublishedAt              *string                      `json:"publishedAt,omitempty"`
	DeletedAt                *string                      `json:"deletedAt,omitempty"`
	Revision                 int                          `json:"revision"`
	CreatedAt                string                       `json:"createdAt"`
	UpdatedAt                string                       `json:"updatedAt"`
}

type TourOfferListResponse struct {
	Items   []TourOfferResponse `json:"items"`
	HasMore bool                `json:"hasMore"`
}

type CreateTourBookingRequest struct {
	ProductID      string  `json:"productId"`
	OfferID        string  `json:"offerId"`
	ScheduledFor   string  `json:"scheduledFor"`
	Adults         int     `json:"adults"`
	Children       int     `json:"children"`
	IdempotencyKey *string `json:"idempotencyKey,omitempty"`
}

type TourBookingResponse struct {
	ID               string  `json:"id"`
	ProductID        string  `json:"productId"`
	OfferID          string  `json:"offerId"`
	LegacyTourID     *string `json:"legacyTourId,omitempty"`
	GuideProfileID   string  `json:"guideProfileId"`
	GuideUserID      string  `json:"guideUserId"`
	TouristUserID    string  `json:"touristUserId"`
	ScheduledFor     string  `json:"scheduledFor"`
	Adults           int     `json:"adults"`
	Children         int     `json:"children"`
	TotalSeats       int     `json:"totalSeats"`
	UnitPriceAmount  float64 `json:"unitPriceAmount"`
	ServiceFeeAmount float64 `json:"serviceFeeAmount"`
	TotalPriceAmount float64 `json:"totalPriceAmount"`
	Currency         string  `json:"currency"`
	Status           string  `json:"status"`
	CreatedAt        string  `json:"createdAt"`
	UpdatedAt        string  `json:"updatedAt"`
}
