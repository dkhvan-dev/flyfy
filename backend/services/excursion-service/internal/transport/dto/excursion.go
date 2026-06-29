package dto

type ExcursionItineraryItemRequest struct {
	StartOffsetMinutes        int                                        `json:"startOffsetMinutes"`
	DurationMinutes           *int                                       `json:"durationMinutes,omitempty"`
	PlaceID                   *string                                    `json:"placeId,omitempty"`
	PlaceName                 *string                                    `json:"placeName,omitempty"`
	Latitude                  *float64                                   `json:"latitude,omitempty"`
	Longitude                 *float64                                   `json:"longitude,omitempty"`
	TravelFromPreviousMinutes *int                                       `json:"travelFromPreviousMinutes,omitempty"`
	Title                     string                                     `json:"title"`
	Description               string                                     `json:"description"`
	Translations              map[string]ExcursionItineraryLocalizedCopy `json:"translations,omitempty"`
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
	DepartureCityID          *string                           `json:"departureCityId,omitempty"`
	MeetingPoint             string                            `json:"meetingPoint"`
	Latitude                 *float64                          `json:"latitude,omitempty"`
	Longitude                *float64                          `json:"longitude,omitempty"`
	MapURL                   *string                           `json:"mapUrl,omitempty"`
	PriceAmount              float64                           `json:"priceAmount"`
	Currency                 string                            `json:"currency"`
	CoverFileID              *string                           `json:"coverFileId,omitempty"`
	ProductCoverFileID       *string                           `json:"productCoverFileId,omitempty"`
	ProductCoverImageURL     *string                           `json:"productCoverImageUrl,omitempty"`
	PhotoFileIDs             []string                          `json:"photoFileIds,omitempty"`
	ProductPhotoFileIDs      []string                          `json:"productPhotoFileIds,omitempty"`
	ProductPhotoImageURLs    []string                          `json:"productPhotoImageUrls,omitempty"`
	IncludedItems            []string                          `json:"includedItems,omitempty"`
	IncludedItemTranslations map[string][]string               `json:"includedItemTranslations,omitempty"`
	Itinerary                []ExcursionItineraryItemRequest   `json:"itinerary,omitempty"`
}

type UpdateExcursionRequest = CreateExcursionRequest

type ExcursionItineraryItemResponse struct {
	ID                        string                                     `json:"id"`
	SortOrder                 int                                        `json:"sortOrder"`
	StartOffsetMinutes        int                                        `json:"startOffsetMinutes"`
	DurationMinutes           *int                                       `json:"durationMinutes,omitempty"`
	PlaceID                   *string                                    `json:"placeId,omitempty"`
	PlaceName                 *string                                    `json:"placeName,omitempty"`
	Latitude                  *float64                                   `json:"latitude,omitempty"`
	Longitude                 *float64                                   `json:"longitude,omitempty"`
	TravelFromPreviousMinutes *int                                       `json:"travelFromPreviousMinutes,omitempty"`
	Title                     string                                     `json:"title"`
	Description               string                                     `json:"description"`
	Translations              map[string]ExcursionItineraryLocalizedCopy `json:"translations,omitempty"`
	CreatedAt                 string                                     `json:"createdAt"`
	UpdatedAt                 string                                     `json:"updatedAt"`
}

type ExcursionResponse struct {
	ID                       string                            `json:"id"`
	GuideProfileID           string                            `json:"guideProfileId"`
	GuideUserID              string                            `json:"guideUserId"`
	GuideDisplayName         string                            `json:"guideDisplayName,omitempty"`
	GuideNickname            string                            `json:"guideNickname,omitempty"`
	GuideFirstName           string                            `json:"guideFirstName,omitempty"`
	GuideLastName            string                            `json:"guideLastName,omitempty"`
	LandmarkID               *string                           `json:"landmarkId,omitempty"`
	LandmarkName             *string                           `json:"landmarkName,omitempty"`
	Title                    string                            `json:"title"`
	Summary                  string                            `json:"summary"`
	Description              string                            `json:"description"`
	Translations             map[string]ExcursionLocalizedCopy `json:"translations,omitempty"`
	ProductTranslations      map[string]ExcursionLocalizedCopy `json:"productTranslations,omitempty"`
	CategorySlug             string                            `json:"categorySlug"`
	Tags                     []string                          `json:"tags,omitempty"`
	Status                   string                            `json:"status"`
	Visibility               string                            `json:"visibility"`
	DurationMinutes          int                               `json:"durationMinutes"`
	MaxGroupSize             int                               `json:"maxGroupSize"`
	LanguageCodes            []string                          `json:"languageCodes"`
	CountryCode              *string                           `json:"countryCode,omitempty"`
	CityName                 *string                           `json:"cityName,omitempty"`
	DepartureCityID          *string                           `json:"departureCityId,omitempty"`
	MeetingPoint             string                            `json:"meetingPoint"`
	Latitude                 *float64                          `json:"latitude,omitempty"`
	Longitude                *float64                          `json:"longitude,omitempty"`
	MapURL                   *string                           `json:"mapUrl,omitempty"`
	PriceAmount              float64                           `json:"priceAmount"`
	Currency                 string                            `json:"currency"`
	CoverFileID              *string                           `json:"coverFileId,omitempty"`
	CoverImageURL            *string                           `json:"coverImageUrl,omitempty"`
	PhotoFileIDs             []string                          `json:"photoFileIds,omitempty"`
	PhotoImageURLs           []string                          `json:"photoImageUrls,omitempty"`
	IncludedItems            []string                          `json:"includedItems,omitempty"`
	IncludedItemTranslations map[string][]string               `json:"includedItemTranslations,omitempty"`
	Itinerary                []ExcursionItineraryItemResponse  `json:"itinerary,omitempty"`
	PublishingDecision       string                            `json:"publishingDecision,omitempty"`
	GuideTrustScore          int                               `json:"guideTrustScore"`
	PublishRiskScore         int                               `json:"publishRiskScore"`
	ModerationReasonCodes    []string                          `json:"moderationReasonCodes,omitempty"`
	SubmittedForReviewAt     *string                           `json:"submittedForReviewAt,omitempty"`
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
	RouteKind            string                            `json:"routeKind"`
	RouteFingerprint     *string                           `json:"routeFingerprint,omitempty"`
	PlaceIDs             []string                          `json:"placeIds,omitempty"`
	PlaceNames           []string                          `json:"placeNames,omitempty"`
	StopCount            int                               `json:"stopCount"`
	TransportMode        string                            `json:"transportMode"`
	RouteTheme           *string                           `json:"routeTheme,omitempty"`
	DurationBucket       *string                           `json:"durationBucket,omitempty"`
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
	DepartureCityID      *string                           `json:"departureCityId,omitempty"`
	Latitude             *float64                          `json:"latitude,omitempty"`
	Longitude            *float64                          `json:"longitude,omitempty"`
	MapURL               *string                           `json:"mapUrl,omitempty"`
	CoverFileID          *string                           `json:"coverFileId,omitempty"`
	CoverImageURL        *string                           `json:"coverImageUrl,omitempty"`
	PhotoFileIDs         []string                          `json:"photoFileIds,omitempty"`
	PhotoImageURLs       []string                          `json:"photoImageUrls,omitempty"`
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
	PhotoFileIDs             []string                          `json:"photoFileIds,omitempty"`
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

type GuideUserIDResponse struct {
	GuideUserID string `json:"guideUserId"`
}

type GuideUserIDListResponse struct {
	Items []GuideUserIDResponse `json:"items"`
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

type CancelExcursionBookingRequest struct {
	Reason string `json:"reason,omitempty"`
}

type ExcursionBookingGuestsQuoteResponse struct {
	Adults             int     `json:"adults"`
	Children           int     `json:"children"`
	TotalSeats         int     `json:"totalSeats"`
	CurrentTotalAmount float64 `json:"currentTotalAmount"`
	NewTotalAmount     float64 `json:"newTotalAmount"`
	DeltaAmount        float64 `json:"deltaAmount"`
	Currency           string  `json:"currency"`
	Status             string  `json:"status"`
}

type ExcursionBookingCancellationQuoteResponse struct {
	Percent    int     `json:"percent"`
	Amount     float64 `json:"amount"`
	Currency   string  `json:"currency"`
	PolicyCode string  `json:"policyCode"`
	Status     string  `json:"status"`
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

type ExcursionAttendanceQRResponse struct {
	ScheduleSlotID string `json:"scheduleSlotId"`
	Token          string `json:"token"`
	ExpiresAt      string `json:"expiresAt"`
	RefreshAt      string `json:"refreshAt"`
}

type ExcursionAttendanceSyncRequest struct {
	Items []ExcursionAttendanceSyncItemRequest `json:"items"`
}

type ExcursionAttendanceSyncItemRequest struct {
	ScanID          string `json:"scanId"`
	QRToken         string `json:"qrToken"`
	InstallationID  string `json:"installationId"`
	ScannedAtDevice string `json:"scannedAtDevice,omitempty"`
}

type ExcursionAttendanceSyncResponse struct {
	Items []ExcursionAttendanceSyncItemResponse `json:"items"`
}

type ExcursionAttendanceSyncItemResponse struct {
	ScanID         string  `json:"scanId"`
	ScheduleSlotID *string `json:"scheduleSlotId,omitempty"`
	Status         string  `json:"status"`
	Code           string  `json:"code"`
	Message        string  `json:"message"`
	CheckedInAt    *string `json:"checkedInAt,omitempty"`
	SyncedAt       string  `json:"syncedAt"`
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
	CancelledAt       *string                  `json:"cancelledAt,omitempty"`
	CancelledBy       *string                  `json:"cancelledBy,omitempty"`
	CancelReason      *string                  `json:"cancelReason,omitempty"`
	RefundPercent     int                      `json:"refundPercent,omitempty"`
	RefundAmount      float64                  `json:"refundAmount,omitempty"`
	RefundCurrency    *string                  `json:"refundCurrency,omitempty"`
	RefundPolicyCode  *string                  `json:"refundPolicyCode,omitempty"`
	RefundStatus      *string                  `json:"refundStatus,omitempty"`
	CheckedInAt       *string                  `json:"checkedInAt,omitempty"`
	Author            *ReviewAuthorResponse    `json:"author,omitempty"`
	CreatedAt         string                   `json:"createdAt"`
	UpdatedAt         string                   `json:"updatedAt"`
	Review            *ExcursionReviewResponse `json:"review,omitempty"`
	GuideReview       *GuideReviewResponse     `json:"guideReview,omitempty"`
}

type ExcursionBookingListResponse struct {
	Items   []ExcursionBookingResponse `json:"items"`
	HasMore bool                       `json:"hasMore"`
}

type CreateExcursionReviewRequest struct {
	Rating  float64 `json:"rating"`
	Comment string  `json:"comment"`
}

type SaveBookingReviewsRequest struct {
	ExcursionReview *ReviewMutationRequest `json:"excursionReview,omitempty"`
	GuideReview     *ReviewMutationRequest `json:"guideReview,omitempty"`
}

type ReviewMutationRequest struct {
	Rating  float64 `json:"rating"`
	Comment string  `json:"comment"`
	Delete  bool    `json:"delete,omitempty"`
}

type BookingReviewsResponse struct {
	ExcursionReview *ExcursionReviewResponse `json:"excursionReview,omitempty"`
	GuideReview     *GuideReviewResponse     `json:"guideReview,omitempty"`
}

type ExcursionReviewResponse struct {
	ID                string               `json:"id"`
	BookingID         string               `json:"bookingId"`
	ProductID         string               `json:"productId"`
	OfferID           string               `json:"offerId"`
	LegacyExcursionID *string              `json:"legacyExcursionId,omitempty"`
	LandmarkID        *string              `json:"landmarkId,omitempty"`
	LandmarkName      *string              `json:"landmarkName,omitempty"`
	GuideProfileID    string               `json:"guideProfileId"`
	GuideUserID       string               `json:"guideUserId"`
	GuideDisplayName  string               `json:"guideDisplayName,omitempty"`
	TouristUserID     string               `json:"touristUserId"`
	Author            ReviewAuthorResponse `json:"author"`
	Rating            float64              `json:"rating"`
	Comment           string               `json:"comment"`
	SourceLabel       string               `json:"sourceLabel"`
	CreatedAt         string               `json:"createdAt"`
	UpdatedAt         string               `json:"updatedAt"`
}

type GuideReviewResponse struct {
	ID             string               `json:"id"`
	BookingID      string               `json:"bookingId"`
	ProductID      string               `json:"productId"`
	OfferID        string               `json:"offerId"`
	GuideProfileID string               `json:"guideProfileId"`
	GuideUserID    string               `json:"guideUserId"`
	TouristUserID  string               `json:"touristUserId"`
	Author         ReviewAuthorResponse `json:"author"`
	Rating         float64              `json:"rating"`
	Comment        string               `json:"comment"`
	SourceLabel    string               `json:"sourceLabel"`
	CreatedAt      string               `json:"createdAt"`
	UpdatedAt      string               `json:"updatedAt"`
}

type ReviewAuthorResponse struct {
	UserID       string  `json:"userId"`
	Nickname     *string `json:"nickname,omitempty"`
	AvatarFileID *string `json:"avatarFileId,omitempty"`
}

type ExcursionReviewListResponse struct {
	Items   []ExcursionReviewResponse `json:"items"`
	HasMore bool                      `json:"hasMore"`
}

type GuideReviewListResponse struct {
	Items   []GuideReviewResponse `json:"items"`
	HasMore bool                  `json:"hasMore"`
}
