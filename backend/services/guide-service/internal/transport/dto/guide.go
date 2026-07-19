package dto

type InitGuideProfileRequest struct {
	Type string `json:"type"`
}

type UpdateGuideProfileRequest struct {
	Headline                  *string                      `json:"headline,omitempty"`
	About                     *string                      `json:"about,omitempty"`
	ExperienceYears           *int                         `json:"experienceYears,omitempty"`
	BaseCityID                *string                      `json:"baseCityId,omitempty"`
	IsPrivateGuideAvailable   *bool                        `json:"isPrivateGuideAvailable,omitempty"`
	IsActivityHostAvailable   *bool                        `json:"isActivityHostAvailable,omitempty"`
	IsExcursionGuideAvailable *bool                        `json:"isExcursionGuideAvailable,omitempty"`
	Languages                 []GuideLanguageRequest       `json:"languages,omitempty"`
	Specializations           []GuideSpecializationRequest `json:"specializations,omitempty"`
}

type ApplyGuideRatingSnapshotsRequest struct {
	Items []GuideRatingSnapshotRequest `json:"items"`
}

type GuideRatingSnapshotRequest struct {
	GuideProfileID string  `json:"guideProfileId"`
	RatingAvg      float64 `json:"ratingAvg"`
	ReviewsCount   int     `json:"reviewsCount"`
}

type ApplyGuideRatingSnapshotsResponse struct {
	Updated int `json:"updated"`
}

type GuideLanguageRequest struct {
	LanguageCode     string `json:"languageCode"`
	ProficiencyLevel string `json:"proficiencyLevel"`
}

type GuideSpecializationRequest struct {
	SpecializationCode string `json:"specializationCode"`
}

type CreateVerificationRequestRequest struct {
	Comment *string `json:"comment,omitempty"`
}

type AttachGuideDocumentRequest struct {
	FileID       string `json:"fileId"`
	DocumentType string `json:"documentType"`
}

type SubmitGuideApplicationRequest struct {
	Type                       string  `json:"type"`
	Headline                   *string `json:"headline,omitempty"`
	About                      *string `json:"about,omitempty"`
	ExperienceYears            *int    `json:"experienceYears,omitempty"`
	BaseCityID                 *string `json:"baseCityId,omitempty"`
	IsPrivateGuideAvailable    *bool   `json:"isPrivateGuideAvailable,omitempty"`
	IsActivityHostAvailable    *bool   `json:"isActivityHostAvailable,omitempty"`
	IsExcursionGuideAvailable  *bool   `json:"isExcursionGuideAvailable,omitempty"`
	Comment                    *string `json:"comment,omitempty"`
	IdentityDocumentFileID     string  `json:"identityDocumentFileId"`
	IdentityDocumentType       string  `json:"identityDocumentType"`
	ProfessionalDocumentFileID string  `json:"professionalDocumentFileId"`
	ProfessionalDocumentType   string  `json:"professionalDocumentType"`
	FirstAidCertificateFileID  *string `json:"firstAidCertificateFileId,omitempty"`
	LanguageCertificateFileID  *string `json:"languageCertificateFileId,omitempty"`
}

type GuideAggregateResponse struct {
	Profile             GuideProfileResponse              `json:"profile"`
	VerificationRequest *GuideVerificationRequestResponse `json:"verificationRequest,omitempty"`
	UserProfile         *PublicUserCard                   `json:"userProfile,omitempty"`
	Documents           []GuideDocumentResponse           `json:"documents"`
	Languages           []GuideLanguageResponse           `json:"languages"`
	Specializations     []GuideSpecializationResponse     `json:"specializations"`
}

type GuideProfileResponse struct {
	ID                        string  `json:"id"`
	UserID                    string  `json:"userId"`
	Type                      string  `json:"type"`
	Status                    string  `json:"status"`
	Headline                  *string `json:"headline,omitempty"`
	About                     *string `json:"about,omitempty"`
	ExperienceYears           int     `json:"experienceYears"`
	BaseCityID                *string `json:"baseCityId,omitempty"`
	IsPrivateGuideAvailable   bool    `json:"isPrivateGuideAvailable"`
	IsActivityHostAvailable   bool    `json:"isActivityHostAvailable"`
	IsExcursionGuideAvailable bool    `json:"isExcursionGuideAvailable"`
	RatingAvg                 float64 `json:"ratingAvg"`
	ReviewsCount              int     `json:"reviewsCount"`
	StatusReason              *string `json:"statusReason,omitempty"`
	StatusChangedAt           *string `json:"statusChangedAt,omitempty"`
	StatusChangedBy           *string `json:"statusChangedBy,omitempty"`
	CreatedAt                 string  `json:"createdAt"`
	UpdatedAt                 string  `json:"updatedAt"`
}

type GuideVerificationRequestResponse struct {
	ID             string  `json:"id"`
	GuideProfileID string  `json:"guideProfileId"`
	Status         string  `json:"status"`
	Comment        *string `json:"comment,omitempty"`
	ReviewComment  *string `json:"reviewComment,omitempty"`
	SubmittedAt    *string `json:"submittedAt,omitempty"`
	ReviewedAt     *string `json:"reviewedAt,omitempty"`
	ReviewedBy     *string `json:"reviewedBy,omitempty"`
	CreatedAt      string  `json:"createdAt"`
	UpdatedAt      string  `json:"updatedAt"`
}

type GuideDocumentResponse struct {
	ID                    string `json:"id"`
	VerificationRequestID string `json:"verificationRequestId"`
	FileID                string `json:"fileId"`
	DocumentType          string `json:"documentType"`
	CreatedAt             string `json:"createdAt"`
}

type GuideLanguageResponse struct {
	ID               string `json:"id"`
	GuideProfileID   string `json:"guideProfileId"`
	LanguageCode     string `json:"languageCode"`
	ProficiencyLevel string `json:"proficiencyLevel"`
	CreatedAt        string `json:"createdAt"`
}

type GuideSpecializationResponse struct {
	ID                 string `json:"id"`
	GuideProfileID     string `json:"guideProfileId"`
	SpecializationCode string `json:"specializationCode"`
	CreatedAt          string `json:"createdAt"`
}

type ReviewVerificationRequestRequest struct {
	ReviewComment *string `json:"reviewComment,omitempty"`
}

type VerificationQueueItemResponse struct {
	ID             string  `json:"id"`
	GuideProfileID string  `json:"guideProfileId"`
	Status         string  `json:"status"`
	Comment        *string `json:"comment,omitempty"`
	SubmittedAt    *string `json:"submittedAt,omitempty"`
	CreatedAt      string  `json:"createdAt"`
}

type AdminGuideApplicationListResponse struct {
	Items []AdminGuideApplicationResponse `json:"items"`
}

type AdminGuideApplicationResponse struct {
	ID                        string                       `json:"id"`
	GuideProfileID            string                       `json:"guideProfileId"`
	GuideUserID               string                       `json:"guideUserId"`
	GuideDisplayName          string                       `json:"guideDisplayName"`
	FirstName                 string                       `json:"firstName,omitempty"`
	LastName                  string                       `json:"lastName,omitempty"`
	CountryCode               string                       `json:"countryCode,omitempty"`
	Locale                    string                       `json:"locale,omitempty"`
	Timezone                  string                       `json:"timezone,omitempty"`
	Type                      string                       `json:"type"`
	GuideStatus               string                       `json:"guideStatus"`
	Status                    string                       `json:"status"`
	Headline                  string                       `json:"headline,omitempty"`
	About                     string                       `json:"about,omitempty"`
	ExperienceYears           int                          `json:"experienceYears"`
	BaseCityID                string                       `json:"baseCityId,omitempty"`
	BaseCityName              string                       `json:"baseCityName,omitempty"`
	IsPrivateGuideAvailable   bool                         `json:"isPrivateGuideAvailable"`
	IsActivityHostAvailable   bool                         `json:"isActivityHostAvailable"`
	IsExcursionGuideAvailable bool                         `json:"isExcursionGuideAvailable"`
	RatingAvg                 float64                      `json:"ratingAvg"`
	ReviewsCount              int                          `json:"reviewsCount"`
	StatusReason              string                       `json:"statusReason,omitempty"`
	StatusChangedAt           *string                      `json:"statusChangedAt,omitempty"`
	StatusChangedBy           *string                      `json:"statusChangedBy,omitempty"`
	Comment                   string                       `json:"comment,omitempty"`
	ReviewComment             string                       `json:"reviewComment,omitempty"`
	SubmittedAt               *string                      `json:"submittedAt,omitempty"`
	ReviewedAt                *string                      `json:"reviewedAt,omitempty"`
	ReviewedBy                *string                      `json:"reviewedBy,omitempty"`
	Documents                 []AdminGuideDocumentResponse `json:"documents"`
	Languages                 []AdminGuideLanguageResponse `json:"languages"`
	Specializations           []string                     `json:"specializations"`
	RiskScore                 int                          `json:"riskScore"`
	ModerationReasonCodes     []string                     `json:"moderationReasonCodes"`
	Revision                  int                          `json:"revision"`
	CreatedAt                 string                       `json:"createdAt"`
	UpdatedAt                 string                       `json:"updatedAt"`
}

type AdminGuideDocumentResponse struct {
	ID           string `json:"id"`
	FileID       string `json:"fileId"`
	DocumentType string `json:"documentType"`
	DownloadURL  string `json:"downloadUrl,omitempty"`
	CreatedAt    string `json:"createdAt"`
}

type AdminGuideLanguageResponse struct {
	LanguageCode     string `json:"languageCode"`
	ProficiencyLevel string `json:"proficiencyLevel"`
}

type PublicGuideCardResponse struct {
	GuideProfile    PublicGuideProfileResponse    `json:"guideProfile"`
	UserProfile     *PublicUserCard               `json:"userProfile,omitempty"`
	Languages       []GuideLanguageResponse       `json:"languages"`
	Specializations []GuideSpecializationResponse `json:"specializations"`
}

type PublicGuideProfileResponse struct {
	ID                        string  `json:"id"`
	UserID                    string  `json:"userId"`
	Type                      string  `json:"type"`
	Status                    string  `json:"status"`
	Headline                  *string `json:"headline,omitempty"`
	About                     *string `json:"about,omitempty"`
	ExperienceYears           int     `json:"experienceYears"`
	BaseCityID                *string `json:"baseCityId,omitempty"`
	IsPrivateGuideAvailable   bool    `json:"isPrivateGuideAvailable"`
	IsActivityHostAvailable   bool    `json:"isActivityHostAvailable"`
	IsExcursionGuideAvailable bool    `json:"isExcursionGuideAvailable"`
	RatingAvg                 float64 `json:"ratingAvg"`
	ReviewsCount              int     `json:"reviewsCount"`
	CreatedAt                 string  `json:"createdAt"`
	UpdatedAt                 string  `json:"updatedAt"`
}

type PublicUserCard struct {
	UserID       string  `json:"userId"`
	FirstName    *string `json:"firstName,omitempty"`
	LastName     *string `json:"lastName,omitempty"`
	Nickname     *string `json:"nickname,omitempty"`
	AvatarFileID *string `json:"avatarFileId,omitempty"`
	CountryCode  *string `json:"countryCode,omitempty"`
	Locale       string  `json:"locale"`
	Timezone     string  `json:"timezone"`
}
