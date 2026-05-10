package dto

type TourItineraryItemRequest struct {
	StartOffsetMinutes int    `json:"startOffsetMinutes"`
	DurationMinutes    *int   `json:"durationMinutes,omitempty"`
	Title              string `json:"title"`
	Description        string `json:"description"`
}

type CreateTourRequest struct {
	LandmarkID      *string                    `json:"landmarkId,omitempty"`
	LandmarkName    *string                    `json:"landmarkName,omitempty"`
	Title           string                     `json:"title"`
	Summary         string                     `json:"summary"`
	Description     string                     `json:"description"`
	CategorySlug    string                     `json:"categorySlug"`
	Tags            []string                   `json:"tags,omitempty"`
	Visibility      string                     `json:"visibility"`
	DurationMinutes int                        `json:"durationMinutes"`
	MaxGroupSize    int                        `json:"maxGroupSize"`
	LanguageCodes   []string                   `json:"languageCodes"`
	CountryCode     *string                    `json:"countryCode,omitempty"`
	CityName        *string                    `json:"cityName,omitempty"`
	MeetingPoint    string                     `json:"meetingPoint"`
	Latitude        *float64                   `json:"latitude,omitempty"`
	Longitude       *float64                   `json:"longitude,omitempty"`
	MapURL          *string                    `json:"mapUrl,omitempty"`
	PriceAmount     float64                    `json:"priceAmount"`
	Currency        string                     `json:"currency"`
	CoverFileID     *string                    `json:"coverFileId,omitempty"`
	IncludedItems   []string                   `json:"includedItems,omitempty"`
	Itinerary       []TourItineraryItemRequest `json:"itinerary,omitempty"`
}

type UpdateTourRequest = CreateTourRequest

type TourItineraryItemResponse struct {
	ID                 string `json:"id"`
	SortOrder          int    `json:"sortOrder"`
	StartOffsetMinutes int    `json:"startOffsetMinutes"`
	DurationMinutes    *int   `json:"durationMinutes,omitempty"`
	Title              string `json:"title"`
	Description        string `json:"description"`
	CreatedAt          string `json:"createdAt"`
	UpdatedAt          string `json:"updatedAt"`
}

type TourResponse struct {
	ID              string                      `json:"id"`
	GuideProfileID  string                      `json:"guideProfileId"`
	GuideUserID     string                      `json:"guideUserId"`
	LandmarkID      *string                     `json:"landmarkId,omitempty"`
	LandmarkName    *string                     `json:"landmarkName,omitempty"`
	Title           string                      `json:"title"`
	Summary         string                      `json:"summary"`
	Description     string                      `json:"description"`
	CategorySlug    string                      `json:"categorySlug"`
	Tags            []string                    `json:"tags,omitempty"`
	Status          string                      `json:"status"`
	Visibility      string                      `json:"visibility"`
	DurationMinutes int                         `json:"durationMinutes"`
	MaxGroupSize    int                         `json:"maxGroupSize"`
	LanguageCodes   []string                    `json:"languageCodes"`
	CountryCode     *string                     `json:"countryCode,omitempty"`
	CityName        *string                     `json:"cityName,omitempty"`
	MeetingPoint    string                      `json:"meetingPoint"`
	Latitude        *float64                    `json:"latitude,omitempty"`
	Longitude       *float64                    `json:"longitude,omitempty"`
	MapURL          *string                     `json:"mapUrl,omitempty"`
	PriceAmount     float64                     `json:"priceAmount"`
	Currency        string                      `json:"currency"`
	CoverFileID     *string                     `json:"coverFileId,omitempty"`
	CoverImageURL   *string                     `json:"coverImageUrl,omitempty"`
	IncludedItems   []string                    `json:"includedItems,omitempty"`
	Itinerary       []TourItineraryItemResponse `json:"itinerary,omitempty"`
	PublishedAt     *string                     `json:"publishedAt,omitempty"`
	DeletedAt       *string                     `json:"deletedAt,omitempty"`
	Revision        int                         `json:"revision"`
	CreatedAt       string                      `json:"createdAt"`
	UpdatedAt       string                      `json:"updatedAt"`
}

type TourListResponse struct {
	Items   []TourResponse `json:"items"`
	HasMore bool           `json:"hasMore"`
}
