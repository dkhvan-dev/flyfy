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

type PlaceVisitInfoRequest struct {
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
	DurationValue     *int                                `json:"durationValue,omitempty"`
	DurationUnit      *string                             `json:"durationUnit,omitempty"`
	Rating            float64                             `json:"rating"`
	ReviewCount       int                                 `json:"reviewCount"`
	Spots             *int                                `json:"spots,omitempty"`
	Source            string                              `json:"source"`
	Status            string                              `json:"status"`
	Tags              []string                            `json:"tags"`
	VisitInfo         PlaceVisitInfoResponse              `json:"visitInfo"`
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

type PlaceVisitInfoResponse struct {
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
