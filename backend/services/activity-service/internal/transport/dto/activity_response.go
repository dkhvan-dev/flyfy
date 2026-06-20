package dto

type ActivityResponse struct {
	ID                 string   `json:"id"`
	HostUserID         string   `json:"hostUserId"`
	SourceActivityID   *string  `json:"sourceActivityId,omitempty"`
	HostActivityRating *float64 `json:"hostActivityRating,omitempty"`

	Title       string `json:"title"`
	Description string `json:"description"`

	Format           string `json:"format"`
	Status           string `json:"status"`
	Visibility       string `json:"visibility"`
	JoinMode         string `json:"joinMode"`
	ModerationStatus string `json:"moderationStatus"`

	CategorySlug    string   `json:"categorySlug"`
	SubcategorySlug *string  `json:"subcategorySlug,omitempty"`
	Tags            []string `json:"tags,omitempty"`
	LanguageCode    string   `json:"languageCode"`
	Timezone        string   `json:"timezone"`

	StartAt              string `json:"startAt"`
	EndAt                string `json:"endAt"`
	RegistrationDeadline string `json:"registrationDeadline"`

	CapacityType    string `json:"capacityType"`
	MinParticipants *int   `json:"minParticipants,omitempty"`
	MaxParticipants *int   `json:"maxParticipants,omitempty"`

	PriceType     string   `json:"priceType"`
	PriceAmount   *float64 `json:"priceAmount,omitempty"`
	Currency      *string  `json:"currency,omitempty"`
	PriceLockedAt *string  `json:"priceLockedAt,omitempty"`

	RequiresProfileCompletion      bool    `json:"requiresProfileCompletion"`
	RequiresAttendanceConfirmation bool    `json:"requiresAttendanceConfirmation"`
	AllowsParticipantInvites       bool    `json:"allowsParticipantInvites"`
	ConfirmationDeadline           *string `json:"confirmationDeadline,omitempty"`

	CountryCode   *string  `json:"countryCode,omitempty"`
	CityID        *string  `json:"cityId,omitempty"`
	CityName      *string  `json:"cityName,omitempty"`
	AddressText   *string  `json:"addressText,omitempty"`
	Latitude      *float64 `json:"latitude,omitempty"`
	Longitude     *float64 `json:"longitude,omitempty"`
	MapURL        *string  `json:"mapUrl,omitempty"`
	MeetingURL    *string  `json:"meetingUrl,omitempty"`
	CoverFileID   *string  `json:"coverFileId,omitempty"`
	CoverImageURL *string  `json:"coverImageUrl,omitempty"`

	CancellationReason *string `json:"cancellationReason,omitempty"`
	CancellationSource *string `json:"cancellationSource,omitempty"`
	CancelledByUserID  *string `json:"cancelledByUserId,omitempty"`
	CancelledAt        *string `json:"cancelledAt,omitempty"`
	StartedAt          *string `json:"startedAt,omitempty"`
	CompletedAt        *string `json:"completedAt,omitempty"`
	CompletionReason   *string `json:"completionReason,omitempty"`
	PublishedAt        *string `json:"publishedAt,omitempty"`

	Revision  int    `json:"revision"`
	CreatedAt string `json:"createdAt"`
	UpdatedAt string `json:"updatedAt"`
}

type AdminActivityModerationResponse struct {
	ActivityResponse

	ModerationRiskScore      int      `json:"moderationRiskScore"`
	ModerationReasonCodes    []string `json:"moderationReasonCodes"`
	ModerationTriggeredAt    *string  `json:"moderationTriggeredAt,omitempty"`
	ModerationReviewedAt     *string  `json:"moderationReviewedAt,omitempty"`
	AuthorCountryCode        *string  `json:"authorCountryCode,omitempty"`
	AuthorCityID             *string  `json:"authorCityId,omitempty"`
	AuthorCityName           *string  `json:"authorCityName,omitempty"`
	AuthorLocationCapturedAt *string  `json:"authorLocationCapturedAt,omitempty"`
	HostDisplayName          string   `json:"hostDisplayName,omitempty"`
	HostFullName             string   `json:"hostFullName,omitempty"`
	CategoryName             string   `json:"categoryName,omitempty"`
	CategoryNameRu           string   `json:"categoryNameRu,omitempty"`
	CategoryNameKk           string   `json:"categoryNameKk,omitempty"`
	SubcategoryName          string   `json:"subcategoryName,omitempty"`
	SubcategoryNameRu        string   `json:"subcategoryNameRu,omitempty"`
	SubcategoryNameKk        string   `json:"subcategoryNameKk,omitempty"`
}

type AdminActivityModerationListResponse struct {
	Items []AdminActivityModerationResponse `json:"items"`
}
