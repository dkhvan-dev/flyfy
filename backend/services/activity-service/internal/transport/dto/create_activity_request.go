package dto

type CreateActivityRequest struct {
	Title        string   `json:"title"`
	Description  string   `json:"description"`
	Format       string   `json:"format"`
	Visibility   string   `json:"visibility"`
	CategorySlug string   `json:"categorySlug"`
	Tags         []string `json:"tags"`
	LanguageCode string   `json:"languageCode"`
	Timezone     string   `json:"timezone"`

	StartAt              string  `json:"startAt"`
	EndAt                string  `json:"endAt"`
	RegistrationDeadline *string `json:"registrationDeadline,omitempty"`

	CapacityType    string `json:"capacityType"`
	MinParticipants *int   `json:"minParticipants,omitempty"`
	MaxParticipants *int   `json:"maxParticipants,omitempty"`

	PriceType   string   `json:"priceType"`
	PriceAmount *float64 `json:"priceAmount,omitempty"`
	Currency    *string  `json:"currency,omitempty"`

	RequiresProfileCompletion      *bool   `json:"requiresProfileCompletion,omitempty"`
	RequiresAttendanceConfirmation *bool   `json:"requiresAttendanceConfirmation,omitempty"`
	ConfirmationDeadline           *string `json:"confirmationDeadline,omitempty"`

	CountryCode *string  `json:"countryCode,omitempty"`
	CityName    *string  `json:"cityName,omitempty"`
	AddressText *string  `json:"addressText,omitempty"`
	Latitude    *float64 `json:"latitude,omitempty"`
	Longitude   *float64 `json:"longitude,omitempty"`
	MapURL      *string  `json:"mapUrl,omitempty"`
	MeetingURL  *string  `json:"meetingUrl,omitempty"`
	CoverFileID *string  `json:"coverFileId,omitempty"`

	VisibilityPassword *string `json:"visibilityPassword,omitempty"`
}
