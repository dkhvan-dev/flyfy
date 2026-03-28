package dto

type UpdateActivityRequest struct {
	Title        *string  `json:"title,omitempty"`
	Description  *string  `json:"description,omitempty"`
	Visibility   *string  `json:"visibility,omitempty"`
	JoinMode     *string  `json:"joinMode,omitempty"`
	CategorySlug *string  `json:"categorySlug,omitempty"`
	Tags         []string `json:"tags,omitempty"`
	HasTags      bool     `json:"hasTags,omitempty"`
	LanguageCode *string  `json:"languageCode,omitempty"`
	Timezone     *string  `json:"timezone,omitempty"`

	StartAt              *string `json:"startAt,omitempty"`
	EndAt                *string `json:"endAt,omitempty"`
	RegistrationDeadline *string `json:"registrationDeadline,omitempty"`

	CapacityType       *string `json:"capacityType,omitempty"`
	MinParticipants    *int    `json:"minParticipants,omitempty"`
	HasMinParticipants bool    `json:"hasMinParticipants,omitempty"`
	MaxParticipants    *int    `json:"maxParticipants,omitempty"`
	HasMaxParticipants bool    `json:"hasMaxParticipants,omitempty"`

	PriceType      *string  `json:"priceType,omitempty"`
	PriceAmount    *float64 `json:"priceAmount,omitempty"`
	HasPriceAmount bool     `json:"hasPriceAmount,omitempty"`
	Currency       *string  `json:"currency,omitempty"`
	HasCurrency    bool     `json:"hasCurrency,omitempty"`

	RequiresProfileCompletion      *bool   `json:"requiresProfileCompletion,omitempty"`
	RequiresAttendanceConfirmation *bool   `json:"requiresAttendanceConfirmation,omitempty"`
	ConfirmationDeadline           *string `json:"confirmationDeadline,omitempty"`
	HasConfirmationDeadline        bool    `json:"hasConfirmationDeadline,omitempty"`

	CountryCode    *string  `json:"countryCode,omitempty"`
	HasCountryCode bool     `json:"hasCountryCode,omitempty"`
	CityName       *string  `json:"cityName,omitempty"`
	HasCityName    bool     `json:"hasCityName,omitempty"`
	AddressText    *string  `json:"addressText,omitempty"`
	HasAddressText bool     `json:"hasAddressText,omitempty"`
	Latitude       *float64 `json:"latitude,omitempty"`
	HasLatitude    bool     `json:"hasLatitude,omitempty"`
	Longitude      *float64 `json:"longitude,omitempty"`
	HasLongitude   bool     `json:"hasLongitude,omitempty"`
	MapURL         *string  `json:"mapUrl,omitempty"`
	HasMapURL      bool     `json:"hasMapUrl,omitempty"`
	MeetingURL     *string  `json:"meetingUrl,omitempty"`
	HasMeetingURL  bool     `json:"hasMeetingUrl,omitempty"`
	CoverFileID    *string  `json:"coverFileId,omitempty"`
	HasCoverFileID bool     `json:"hasCoverFileId,omitempty"`

	VisibilityPassword    *string `json:"visibilityPassword,omitempty"`
	HasVisibilityPassword bool    `json:"hasVisibilityPassword,omitempty"`
}
