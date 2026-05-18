package dto

type InitMeResponse struct {
	User       UserResponse           `json:"user"`
	Profile    UserProfileResponse    `json:"profile"`
	Settings   UserSettingsResponse   `json:"settings"`
	Reputation UserReputationResponse `json:"reputation"`
	Roles      []string               `json:"roles"`
	Followers  UserFollowResponse     `json:"followers"`
}

type UserFollowResponse struct {
	Count          int  `json:"count"`
	IsFollowedByMe bool `json:"isFollowedByMe"`
}

type UserResponse struct {
	ID            string  `json:"id"`
	AuthSubjectID string  `json:"authSubjectId"`
	Status        string  `json:"status"`
	PrimaryPhone  *string `json:"primaryPhone,omitempty"`
	PrimaryEmail  *string `json:"primaryEmail,omitempty"`
	IsDeleted     bool    `json:"isDeleted"`
	DeletedAt     *string `json:"deletedAt,omitempty"`
	LastSeenAt    *string `json:"lastSeenAt,omitempty"`
	CreatedAt     string  `json:"createdAt"`
	UpdatedAt     string  `json:"updatedAt"`
}

type UserProfileResponse struct {
	UserID             string  `json:"userId"`
	FirstName          *string `json:"firstName,omitempty"`
	LastName           *string `json:"lastName,omitempty"`
	DisplayName        *string `json:"displayName,omitempty"`
	Bio                *string `json:"bio,omitempty"`
	BirthDate          *string `json:"birthDate,omitempty"`
	AvatarFileID       *string `json:"avatarFileId,omitempty"`
	CityID             *string `json:"cityId,omitempty"`
	CountryCode        *string `json:"countryCode,omitempty"`
	Locale             string  `json:"locale"`
	Timezone           string  `json:"timezone"`
	Currency           *string `json:"currency,omitempty"`
	IsProfileCompleted bool    `json:"isProfileCompleted"`
	CreatedAt          string  `json:"createdAt"`
	UpdatedAt          string  `json:"updatedAt"`
}

type UserSettingsResponse struct {
	UserID                    string `json:"userId"`
	NotificationsPushEnabled  bool   `json:"notificationsPushEnabled"`
	NotificationsEmailEnabled bool   `json:"notificationsEmailEnabled"`
	NotificationsSMSEnabled   bool   `json:"notificationsSmsEnabled"`
	MarketingEnabled          bool   `json:"marketingEnabled"`
	DarkModeEnabled           bool   `json:"darkModeEnabled"`
	CreatedAt                 string `json:"createdAt"`
	UpdatedAt                 string `json:"updatedAt"`
}

type UserReputationResponse struct {
	UserID              string `json:"userId"`
	TrustScore          int    `json:"trustScore"`
	RiskScore           int    `json:"riskScore"`
	CompletedBookings   int    `json:"completedBookings"`
	CompletedActivities int    `json:"completedActivities"`
	CancellationsCount  int    `json:"cancellationsCount"`
	ReportsCount        int    `json:"reportsCount"`
	CreatedAt           string `json:"createdAt"`
	UpdatedAt           string `json:"updatedAt"`
}

type UpdateMyProfileRequest struct {
	FirstName    *string `json:"firstName,omitempty"`
	LastName     *string `json:"lastName,omitempty"`
	DisplayName  *string `json:"displayName,omitempty"`
	Bio          *string `json:"bio,omitempty"`
	BirthDate    *string `json:"birthDate,omitempty"`    // YYYY-MM-DD
	AvatarFileID *string `json:"avatarFileId,omitempty"` // UUID
	CityID       *string `json:"cityId,omitempty"`       // UUID
	CountryCode  *string `json:"countryCode,omitempty"`
	Locale       *string `json:"locale,omitempty"`
	Timezone     *string `json:"timezone,omitempty"`
	Currency     *string `json:"currency,omitempty"`
}

type UpdateMySettingsRequest struct {
	NotificationsPushEnabled  *bool `json:"notificationsPushEnabled,omitempty"`
	NotificationsEmailEnabled *bool `json:"notificationsEmailEnabled,omitempty"`
	NotificationsSMSEnabled   *bool `json:"notificationsSmsEnabled,omitempty"`
	MarketingEnabled          *bool `json:"marketingEnabled,omitempty"`
	DarkModeEnabled           *bool `json:"darkModeEnabled,omitempty"`
}

type GrantRoleRequest struct {
	Role string `json:"role"`
}

type PublicProfileResponse struct {
	UserID       string  `json:"userId"`
	DisplayName  *string `json:"displayName,omitempty"`
	Bio          *string `json:"bio,omitempty"`
	AvatarFileID *string `json:"avatarFileId,omitempty"`
	CountryCode  *string `json:"countryCode,omitempty"`
	Locale       string  `json:"locale"`
	Timezone     string  `json:"timezone"`
	IsOnline     bool    `json:"isOnline"`
	LastSeenAt   *string `json:"lastSeenAt,omitempty"`
}

type FollowersListItemResponse struct {
	UserID       string  `json:"userId"`
	DisplayName  *string `json:"displayName,omitempty"`
	AvatarFileID *string `json:"avatarFileId,omitempty"`
	IsOnline     bool    `json:"isOnline"`
	LastSeenAt   *string `json:"lastSeenAt,omitempty"`
}

type FollowersListResponse struct {
	Items      []FollowersListItemResponse `json:"items"`
	NextOffset *int                        `json:"nextOffset,omitempty"`
}
