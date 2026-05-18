package dto

type ExcursionItineraryItemRequest struct {
	StartOffsetMinutes int                                        `json:"startOffsetMinutes"`
	DurationMinutes    *int                                       `json:"durationMinutes,omitempty"`
	Title              string                                     `json:"title"`
	Description        string                                     `json:"description"`
	Translations       map[string]ExcursionItineraryLocalizedCopy `json:"translations,omitempty"`
}

type ExcursionLocalizedCopy struct {
	Title       string `json:"title,omitempty"`
	Summary     string `json:"summary,omitempty"`
	Description string `json:"description,omitempty"`
}

type ExcursionItineraryLocalizedCopy struct {
	Title       string `json:"title,omitempty"`
	Description string `json:"description,omitempty"`
}

type CreateExcursionRequest struct {
	LandmarkID               *string                           `json:"landmarkId,omitempty"`
	LandmarkName             *string                           `json:"landmarkName,omitempty"`
	CategorySlug             string                            `json:"categorySlug,omitempty"`
	ProductTranslations      map[string]ExcursionLocalizedCopy `json:"productTranslations,omitempty"`
	Visibility               string                            `json:"visibility"`
	DurationMinutes          int                               `json:"durationMinutes"`
	MaxGroupSize             int                               `json:"maxGroupSize"`
	LanguageCodes            []string                          `json:"languageCodes"`
	CountryCode              *string                           `json:"countryCode,omitempty"`
	CityName                 *string                           `json:"cityName,omitempty"`
	MeetingPoint             string                            `json:"meetingPoint"`
	Latitude                 *float64                          `json:"latitude,omitempty"`
	Longitude                *float64                          `json:"longitude,omitempty"`
	MapURL                   *string                           `json:"mapUrl,omitempty"`
	PriceAmount              float64                           `json:"priceAmount"`
	Currency                 string                            `json:"currency"`
	CoverFileID              *string                           `json:"coverFileId,omitempty"`
	ProductCoverFileID       *string                           `json:"productCoverFileId,omitempty"`
	IncludedItems            []string                          `json:"includedItems,omitempty"`
	IncludedItemTranslations map[string][]string               `json:"includedItemTranslations,omitempty"`
	Itinerary                []ExcursionItineraryItemRequest   `json:"itinerary,omitempty"`
}

type UpdateExcursionRequest = CreateExcursionRequest

type ExcursionItineraryItemResponse struct {
	ID                 string                                     `json:"id"`
	SortOrder          int                                        `json:"sortOrder"`
	StartOffsetMinutes int                                        `json:"startOffsetMinutes"`
	DurationMinutes    *int                                       `json:"durationMinutes,omitempty"`
	Title              string                                     `json:"title"`
	Description        string                                     `json:"description"`
	Translations       map[string]ExcursionItineraryLocalizedCopy `json:"translations,omitempty"`
	CreatedAt          string                                     `json:"createdAt"`
	UpdatedAt          string                                     `json:"updatedAt"`
}

type ExcursionResponse struct {
	ID                       string                            `json:"id"`
	GuideProfileID           string                            `json:"guideProfileId"`
	GuideUserID              string                            `json:"guideUserId"`
	LandmarkID               *string                           `json:"landmarkId,omitempty"`
	LandmarkName             *string                           `json:"landmarkName,omitempty"`
	Title                    string                            `json:"title"`
	Summary                  string                            `json:"summary"`
	Description              string                            `json:"description"`
	Translations             map[string]ExcursionLocalizedCopy `json:"translations,omitempty"`
	CategorySlug             string                            `json:"categorySlug"`
	Tags                     []string                          `json:"tags,omitempty"`
	Status                   string                            `json:"status"`
	Visibility               string                            `json:"visibility"`
	DurationMinutes          int                               `json:"durationMinutes"`
	MaxGroupSize             int                               `json:"maxGroupSize"`
	LanguageCodes            []string                          `json:"languageCodes"`
	CountryCode              *string                           `json:"countryCode,omitempty"`
	CityName                 *string                           `json:"cityName,omitempty"`
	MeetingPoint             string                            `json:"meetingPoint"`
	Latitude                 *float64                          `json:"latitude,omitempty"`
	Longitude                *float64                          `json:"longitude,omitempty"`
	MapURL                   *string                           `json:"mapUrl,omitempty"`
	PriceAmount              float64                           `json:"priceAmount"`
	Currency                 string                            `json:"currency"`
	CoverFileID              *string                           `json:"coverFileId,omitempty"`
	CoverImageURL            *string                           `json:"coverImageUrl,omitempty"`
	IncludedItems            []string                          `json:"includedItems,omitempty"`
	IncludedItemTranslations map[string][]string               `json:"includedItemTranslations,omitempty"`
	Itinerary                []ExcursionItineraryItemResponse  `json:"itinerary,omitempty"`
	PublishedAt              *string                           `json:"publishedAt,omitempty"`
	DeletedAt                *string                           `json:"deletedAt,omitempty"`
	Revision                 int                               `json:"revision"`
	CreatedAt                string                            `json:"createdAt"`
	UpdatedAt                string                            `json:"updatedAt"`
}

type ExcursionListResponse struct {
	Items   []ExcursionResponse `json:"items"`
	HasMore bool                `json:"hasMore"`
}

type ExcursionProductCardResponse struct {
	ID                   string                            `json:"id"`
	LandmarkID           *string                           `json:"landmarkId,omitempty"`
	LandmarkName         *string                           `json:"landmarkName,omitempty"`
	Title                string                            `json:"title"`
	Summary              string                            `json:"summary"`
	Description          string                            `json:"description"`
	Translations         map[string]ExcursionLocalizedCopy `json:"translations,omitempty"`
	CategorySlug         string                            `json:"categorySlug"`
	Status               string                            `json:"status"`
	Visibility           string                            `json:"visibility"`
	DurationMinutes      int                               `json:"durationMinutes"`
	CountryCode          *string                           `json:"countryCode,omitempty"`
	CityName             *string                           `json:"cityName,omitempty"`
	Latitude             *float64                          `json:"latitude,omitempty"`
	Longitude            *float64                          `json:"longitude,omitempty"`
	MapURL               *string                           `json:"mapUrl,omitempty"`
	CoverFileID          *string                           `json:"coverFileId,omitempty"`
	CoverImageURL        *string                           `json:"coverImageUrl,omitempty"`
	MinPriceAmount       *float64                          `json:"minPriceAmount,omitempty"`
	Currency             *string                           `json:"currency,omitempty"`
	OffersCount          int                               `json:"offersCount"`
	PublishedOffersCount int                               `json:"publishedOffersCount"`
	NextAvailableAt      *string                           `json:"nextAvailableAt,omitempty"`
	CreatedAt            string                            `json:"createdAt"`
	UpdatedAt            string                            `json:"updatedAt"`
}

type ExcursionProductListResponse struct {
	Items   []ExcursionProductCardResponse `json:"items"`
	HasMore bool                           `json:"hasMore"`
}

type ExcursionOfferResponse struct {
	ID                       string                            `json:"id"`
	ProductID                string                            `json:"productId"`
	LegacyExcursionID        *string                           `json:"legacyExcursionId,omitempty"`
	GuideProfileID           string                            `json:"guideProfileId"`
	GuideUserID              string                            `json:"guideUserId"`
	GuideRatingAvg           float64                           `json:"guideRatingAvg"`
	GuideReviewsCount        int                               `json:"guideReviewsCount"`
	GuideExperienceYears     int                               `json:"guideExperienceYears"`
	GuideDisplayName         string                            `json:"guideDisplayName,omitempty"`
	Title                    string                            `json:"title"`
	Summary                  string                            `json:"summary"`
	Description              string                            `json:"description"`
	Translations             map[string]ExcursionLocalizedCopy `json:"translations,omitempty"`
	Status                   string                            `json:"status"`
	Visibility               string                            `json:"visibility"`
	DurationMinutes          int                               `json:"durationMinutes"`
	MaxGroupSize             int                               `json:"maxGroupSize"`
	MeetingPoint             string                            `json:"meetingPoint"`
	Latitude                 *float64                          `json:"latitude,omitempty"`
	Longitude                *float64                          `json:"longitude,omitempty"`
	MapURL                   *string                           `json:"mapUrl,omitempty"`
	PriceAmount              float64                           `json:"priceAmount"`
	Currency                 string                            `json:"currency"`
	CoverFileID              *string                           `json:"coverFileId,omitempty"`
	LanguageCodes            []string                          `json:"languageCodes"`
	IncludedItems            []string                          `json:"includedItems,omitempty"`
	IncludedItemTranslations map[string][]string               `json:"includedItemTranslations,omitempty"`
	Itinerary                []ExcursionItineraryItemResponse  `json:"itinerary,omitempty"`
	PublishedAt              *string                           `json:"publishedAt,omitempty"`
	DeletedAt                *string                           `json:"deletedAt,omitempty"`
	Revision                 int                               `json:"revision"`
	CreatedAt                string                            `json:"createdAt"`
	UpdatedAt                string                            `json:"updatedAt"`
}

type ExcursionOfferListResponse struct {
	Items   []ExcursionOfferResponse `json:"items"`
	HasMore bool                     `json:"hasMore"`
}

type GuideExcursionLanguageResponse struct {
	GuideUserID   string   `json:"guideUserId"`
	LanguageCodes []string `json:"languageCodes"`
}

type GuideExcursionLanguageListResponse struct {
	Items []GuideExcursionLanguageResponse `json:"items"`
}

type CreateExcursionBookingRequest struct {
	ProductID      string  `json:"productId"`
	OfferID        string  `json:"offerId"`
	ScheduleSlotID *string `json:"scheduleSlotId,omitempty"`
	ScheduledFor   string  `json:"scheduledFor"`
	Adults         int     `json:"adults"`
	Children       int     `json:"children"`
	IdempotencyKey *string `json:"idempotencyKey,omitempty"`
}

type UpdateExcursionBookingGuestsRequest struct {
	Adults   int `json:"adults"`
	Children int `json:"children"`
}

type CreateGuideScheduleSlotRequest struct {
	OfferID  string `json:"offerId"`
	StartAt  string `json:"startAt"`
	Timezone string `json:"timezone"`
	Capacity int    `json:"capacity,omitempty"`
}

type UpdateGuideScheduleSlotRequest struct {
	OfferID  string `json:"offerId,omitempty"`
	StartAt  string `json:"startAt"`
	Timezone string `json:"timezone"`
	Capacity int    `json:"capacity,omitempty"`
}

type CreateGuideScheduleSeriesRequest struct {
	OfferID         string `json:"offerId"`
	StartsOn        string `json:"startsOn"`
	EndsOn          string `json:"endsOn,omitempty"`
	OccurrenceLimit int    `json:"occurrenceLimit,omitempty"`
	StartTime       string `json:"startTime"`
	Timezone        string `json:"timezone"`
	Weekdays        []int  `json:"weekdays"`
	Capacity        int    `json:"capacity,omitempty"`
}

type CancelGuideScheduleSlotRequest struct {
	Reason string `json:"reason"`
}

type GuideScheduleSlotResponse struct {
	ID                string  `json:"id"`
	SeriesID          *string `json:"seriesId,omitempty"`
	OfferID           string  `json:"offerId"`
	ProductID         string  `json:"productId"`
	LegacyExcursionID *string `json:"legacyExcursionId,omitempty"`
	StartAt           string  `json:"startAt"`
	EndAt             string  `json:"endAt"`
	Timezone          string  `json:"timezone"`
	Capacity          int     `json:"capacity"`
	BookedSeats       int     `json:"bookedSeats"`
	Status            string  `json:"status"`
	Title             string  `json:"title,omitempty"`
	CancelReason      *string `json:"cancelReason,omitempty"`
}

type GuideScheduleListResponse struct {
	Items []GuideScheduleSlotResponse `json:"items"`
}

type ExcursionBookingResponse struct {
	ID                string                   `json:"id"`
	ProductID         string                   `json:"productId"`
	OfferID           string                   `json:"offerId"`
	ScheduleSlotID    *string                  `json:"scheduleSlotId,omitempty"`
	LegacyExcursionID *string                  `json:"legacyExcursionId,omitempty"`
	GuideProfileID    string                   `json:"guideProfileId"`
	GuideUserID       string                   `json:"guideUserId"`
	GuideDisplayName  string                   `json:"guideDisplayName,omitempty"`
	TouristUserID     string                   `json:"touristUserId"`
	Title             string                   `json:"title,omitempty"`
	Summary           string                   `json:"summary,omitempty"`
	LandmarkID        *string                  `json:"landmarkId,omitempty"`
	LandmarkName      *string                  `json:"landmarkName,omitempty"`
	CategorySlug      string                   `json:"categorySlug,omitempty"`
	CountryCode       *string                  `json:"countryCode,omitempty"`
	CityName          *string                  `json:"cityName,omitempty"`
	CoverFileID       *string                  `json:"coverFileId,omitempty"`
	ScheduledFor      string                   `json:"scheduledFor"`
	Adults            int                      `json:"adults"`
	Children          int                      `json:"children"`
	TotalSeats        int                      `json:"totalSeats"`
	MaxGroupSize      int                      `json:"maxGroupSize,omitempty"`
	UnitPriceAmount   float64                  `json:"unitPriceAmount"`
	ServiceFeeAmount  float64                  `json:"serviceFeeAmount"`
	TotalPriceAmount  float64                  `json:"totalPriceAmount"`
	Currency          string                   `json:"currency"`
	Status            string                   `json:"status"`
	CreatedAt         string                   `json:"createdAt"`
	UpdatedAt         string                   `json:"updatedAt"`
	Review            *ExcursionReviewResponse `json:"review,omitempty"`
}

type ExcursionBookingListResponse struct {
	Items   []ExcursionBookingResponse `json:"items"`
	HasMore bool                       `json:"hasMore"`
}

type CreateExcursionReviewRequest struct {
	Rating  float64 `json:"rating"`
	Comment string  `json:"comment"`
}

type ExcursionReviewResponse struct {
	ID                string  `json:"id"`
	BookingID         string  `json:"bookingId"`
	ProductID         string  `json:"productId"`
	OfferID           string  `json:"offerId"`
	LegacyExcursionID *string `json:"legacyExcursionId,omitempty"`
	LandmarkID        *string `json:"landmarkId,omitempty"`
	LandmarkName      *string `json:"landmarkName,omitempty"`
	GuideProfileID    string  `json:"guideProfileId"`
	GuideUserID       string  `json:"guideUserId"`
	GuideDisplayName  string  `json:"guideDisplayName,omitempty"`
	TouristUserID     string  `json:"touristUserId"`
	Rating            float64 `json:"rating"`
	Comment           string  `json:"comment"`
	SourceLabel       string  `json:"sourceLabel"`
	CreatedAt         string  `json:"createdAt"`
	UpdatedAt         string  `json:"updatedAt"`
}

type ExcursionReviewListResponse struct {
	Items   []ExcursionReviewResponse `json:"items"`
	HasMore bool                      `json:"hasMore"`
}
