package dto

type CreateAttractionRequest struct {
	Title         string                                  `json:"title"`
	Description   string                                  `json:"description"`
	DefaultLocale string                                  `json:"defaultLocale"`
	Translations  map[string]AttractionTranslationRequest `json:"translations"`
	CountryCode   string                                  `json:"countryCode"`
	CityID        string                                  `json:"cityId"`
	Category      string                                  `json:"category"`
	PriceAmount   *float64                                `json:"priceAmount"`
	PriceCurrency *string                                 `json:"priceCurrency"`
	DurationValue *int                                    `json:"durationValue"`
	DurationUnit  *string                                 `json:"durationUnit"`
	Rating        float64                                 `json:"rating"`
	Spots         *int                                    `json:"spots"`
	Status        string                                  `json:"status"`
	Tags          []string                                `json:"tags"`
	VisitInfo     *AttractionVisitInfoRequest             `json:"visitInfo,omitempty"`
}

type UpdateAttractionRequest struct {
	Title         string                                  `json:"title"`
	Description   string                                  `json:"description"`
	DefaultLocale string                                  `json:"defaultLocale"`
	Translations  map[string]AttractionTranslationRequest `json:"translations"`
	CountryCode   string                                  `json:"countryCode"`
	CityID        string                                  `json:"cityId"`
	Category      string                                  `json:"category"`
	PriceAmount   *float64                                `json:"priceAmount"`
	PriceCurrency *string                                 `json:"priceCurrency"`
	DurationValue *int                                    `json:"durationValue"`
	DurationUnit  *string                                 `json:"durationUnit"`
	Spots         *int                                    `json:"spots"`
	Status        string                                  `json:"status"`
	Tags          []string                                `json:"tags"`
	VisitInfo     *AttractionVisitInfoRequest             `json:"visitInfo,omitempty"`
}

type AttractionTranslationRequest struct {
	Title       string `json:"title"`
	Description string `json:"description"`
}

type AttractionVisitInfoRequest struct {
	BestTime        string            `json:"bestTime"`
	Accessibility   string            `json:"accessibility"`
	BookingRequired *bool             `json:"bookingRequired"`
	OpeningHours    string            `json:"openingHours"`
	Amenities       []string          `json:"amenities"`
	Audience        []string          `json:"audience"`
	SafetyNotes     []string          `json:"safetyNotes"`
	NearbyIDs       []string          `json:"nearbyIds"`
	LocalizedTips   map[string]string `json:"localizedTips"`
}

type MediaItemRequest struct {
	FileID    string `json:"fileId"`
	MediaType string `json:"mediaType"`
	Position  int    `json:"position"`
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
	DisplayName  *string `json:"displayName,omitempty"`
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

type AttractionResponse struct {
	ID            string                                   `json:"id"`
	Locale        string                                   `json:"locale"`
	DefaultLocale string                                   `json:"defaultLocale"`
	Title         string                                   `json:"title"`
	Description   string                                   `json:"description"`
	CountryCode   string                                   `json:"countryCode"`
	CityID        string                                   `json:"cityId"`
	Category      string                                   `json:"category"`
	PriceAmount   *float64                                 `json:"priceAmount,omitempty"`
	PriceCurrency *string                                  `json:"priceCurrency,omitempty"`
	DurationValue *int                                     `json:"durationValue,omitempty"`
	DurationUnit  *string                                  `json:"durationUnit,omitempty"`
	Rating        float64                                  `json:"rating"`
	ReviewCount   int                                      `json:"reviewCount"`
	Spots         *int                                     `json:"spots,omitempty"`
	Source        string                                   `json:"source"`
	Status        string                                   `json:"status"`
	Tags          []string                                 `json:"tags"`
	VisitInfo     AttractionVisitInfoResponse              `json:"visitInfo"`
	Translations  map[string]AttractionTranslationResponse `json:"translations,omitempty"`
	Media         []MediaResponse                          `json:"media"`
	Author        AuthorResponse                           `json:"author"`
	CreatedAt     string                                   `json:"createdAt"`
	UpdatedAt     string                                   `json:"updatedAt"`
	DeletedAt     *string                                  `json:"deletedAt,omitempty"`
}

type AttractionTranslationResponse struct {
	Title       string `json:"title"`
	Description string `json:"description"`
}

type AttractionVisitInfoResponse struct {
	BestTime        string            `json:"bestTime,omitempty"`
	Accessibility   string            `json:"accessibility,omitempty"`
	BookingRequired *bool             `json:"bookingRequired,omitempty"`
	OpeningHours    string            `json:"openingHours,omitempty"`
	Amenities       []string          `json:"amenities,omitempty"`
	Audience        []string          `json:"audience,omitempty"`
	SafetyNotes     []string          `json:"safetyNotes,omitempty"`
	NearbyIDs       []string          `json:"nearbyIds,omitempty"`
	LocalizedTips   map[string]string `json:"localizedTips,omitempty"`
}

type AttractionListResponse struct {
	Items []*AttractionResponse `json:"items"`
	Total int                   `json:"total"`
}

type ReviewResponse struct {
	ID           string          `json:"id"`
	AttractionID string          `json:"attractionId"`
	Rating       float64         `json:"rating"`
	Comment      string          `json:"comment"`
	Media        []MediaResponse `json:"media"`
	Author       AuthorResponse  `json:"author"`
	CreatedAt    string          `json:"createdAt"`
	UpdatedAt    string          `json:"updatedAt"`
}

type ReviewListResponse struct {
	Items []*ReviewResponse `json:"items"`
	Total int               `json:"total"`
}
