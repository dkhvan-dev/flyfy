package model

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/enum"
)

type ModerationTargetType string

const (
	ModerationTargetExcursion        ModerationTargetType = "EXCURSION"
	ModerationTargetActivity         ModerationTargetType = "ACTIVITY"
	ModerationTargetGuideApplication ModerationTargetType = "GUIDE_APPLICATION"
	ModerationTargetChatMessage      ModerationTargetType = "CHAT_MESSAGE"
	ModerationTargetStory            ModerationTargetType = "STORY"
)

type ModerationCase struct {
	ID              uuid.UUID
	TargetType      ModerationTargetType
	TargetID        uuid.UUID
	SourceService   string
	SourceRevision  int
	Status          enum.ModerationCaseStatus
	Priority        int
	Reason          string
	Snapshot        json.RawMessage
	Metadata        json.RawMessage
	AssignedAdminID *uuid.UUID
	OpenedBy        *uuid.UUID
	OpenedAt        time.Time
	DueAt           *time.Time
	ResolvedAt      *time.Time
	LockVersion     int
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

type ModerationDecision struct {
	ID              uuid.UUID
	CaseID          uuid.UUID
	DecisionType    enum.ModerationDecisionType
	SourceRevision  int
	ReasonCodes     []string
	PublicComment   string
	InternalComment string
	IdempotencyKey  string
	DecidedBy       uuid.UUID
	DecidedByName   string
	ApplyStatus     enum.ModerationApplyStatus
	AppliedAt       *time.Time
	SourceResponse  json.RawMessage
	CreatedAt       time.Time
}

type ModerationQueueSort string

const (
	ModerationQueueSortDefault       ModerationQueueSort = ""
	ModerationQueueSortPriorityDesc  ModerationQueueSort = "priority_desc"
	ModerationQueueSortOpenedDesc    ModerationQueueSort = "opened_desc"
	ModerationQueueSortOpenedAsc     ModerationQueueSort = "opened_asc"
	ModerationQueueSortRiskDesc      ModerationQueueSort = "risk_desc"
	ModerationQueueSortSubmittedDesc ModerationQueueSort = "submitted_desc"
)

type ModerationRiskFilter string

const (
	ModerationRiskFilterAll     ModerationRiskFilter = ""
	ModerationRiskFilterFlagged ModerationRiskFilter = "flagged"
	ModerationRiskFilterHigh    ModerationRiskFilter = "high"
)

type ModerationQueueFilter struct {
	TargetType      *ModerationTargetType
	Statuses        []enum.ModerationCaseStatus
	AssignedAdminID *uuid.UUID
	Search          string
	City            string
	Signal          string
	Risk            ModerationRiskFilter
	Sort            ModerationQueueSort
	Limit           int
	Offset          int
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

type ExcursionItineraryItem struct {
	ID                        uuid.UUID
	SortOrder                 int
	StartOffsetMinutes        int
	DurationMinutes           *int
	AttractionID              *uuid.UUID
	AttractionName            string
	TravelFromPreviousMinutes *int
	Title                     string
	Description               string
	Translations              map[string]ExcursionItineraryLocalizedCopy
}

type ExcursionModerationItem struct {
	ID                      uuid.UUID
	Title                   string
	Summary                 string
	Description             string
	Translations            map[string]ExcursionLocalizedCopy
	ProductTranslations     map[string]ExcursionLocalizedCopy
	Status                  string
	Visibility              string
	GuideUserID             uuid.UUID
	GuideDisplayName        string
	GuideNickname           string
	GuideFirstName          string
	GuideLastName           string
	GuideTrustScore         int
	PublishRiskScore        int
	ModerationReasonCodes   []string
	LandmarkName            string
	AttractionNames         []string
	AttractionNamesByLocale map[string][]string
	StopCount               int
	DurationMinutes         int
	MaxGroupSize            int
	LanguageCodes           []string
	CountryCode             string
	CityName                string
	DepartureCityID         string
	MeetingPoint            string
	MeetingPointByLocale    map[string]string
	PriceAmount             float64
	Currency                string
	IncludedItems           []string
	IncludedItemsByLocale   map[string][]string
	Itinerary               []ExcursionItineraryItem
	Revision                int
	SubmittedForReviewAt    *time.Time
	CreatedAt               time.Time
	UpdatedAt               time.Time
}

type ActivityModerationItem struct {
	ID               uuid.UUID
	HostUserID       uuid.UUID
	HostDisplayName  string
	SourceActivityID *uuid.UUID

	Title       string
	Description string

	Format           string
	Status           string
	Visibility       string
	JoinMode         string
	ModerationStatus string

	ModerationRiskScore   int
	ModerationReasonCodes []string
	ModerationTriggeredAt *time.Time
	ModerationReviewedAt  *time.Time

	CategorySlug      string
	SubcategorySlug   *string
	CategoryName      string
	CategoryNameRu    string
	CategoryNameKk    string
	SubcategoryName   string
	SubcategoryNameRu string
	SubcategoryNameKk string
	LanguageCode      string
	Timezone          string

	StartAt              time.Time
	EndAt                time.Time
	RegistrationDeadline time.Time

	CapacityType    string
	MinParticipants *int
	MaxParticipants *int

	PriceType   string
	PriceAmount *float64
	Currency    *string

	CountryCode   *string
	CityID        *string
	CityName      *string
	AddressText   *string
	Latitude      *float64
	Longitude     *float64
	MapURL        *string
	MeetingURL    *string
	CoverImageURL *string

	Revision  int
	CreatedAt time.Time
	UpdatedAt time.Time
}

type ChatParticipantModerationItem struct {
	UserID      uuid.UUID `json:"userId"`
	DisplayName string    `json:"displayName,omitempty"`
	Role        string    `json:"role,omitempty"`
}

type ChatMessageContextItem struct {
	ID                uuid.UUID  `json:"id"`
	SenderUserID      uuid.UUID  `json:"senderUserId"`
	SenderDisplayName string     `json:"senderDisplayName,omitempty"`
	Type              string     `json:"type"`
	Content           string     `json:"content"`
	FileIDs           []string   `json:"fileIds,omitempty"`
	EditedAt          *time.Time `json:"editedAt,omitempty"`
	DeletedAt         *time.Time `json:"deletedAt,omitempty"`
	SentAt            time.Time  `json:"sentAt"`
}

type ChatMessageModerationItem struct {
	ID                      uuid.UUID
	ConversationID          uuid.UUID
	ConversationType        string
	ConversationTitle       string
	ActivityID              *uuid.UUID
	ExcursionScheduleSlotID *uuid.UUID

	SenderUserID      uuid.UUID
	SenderDisplayName string
	Type              string
	Content           string
	FileIDs           []string

	ModerationStatus      string
	ModerationRiskScore   int
	ModerationReasonCodes []string
	ModerationTriggeredAt *time.Time
	ModerationReviewedAt  *time.Time

	ContextBefore []ChatMessageContextItem
	ContextAfter  []ChatMessageContextItem
	Participants  []ChatParticipantModerationItem

	Revision  int
	EditedAt  *time.Time
	DeletedAt *time.Time
	SentAt    time.Time
	CreatedAt time.Time
	UpdatedAt time.Time
}

type GuideApplicationDocument struct {
	ID           uuid.UUID
	FileID       uuid.UUID
	DocumentType string
	DownloadURL  string
	CreatedAt    time.Time
}

type GuideApplicationLanguage struct {
	LanguageCode     string
	ProficiencyLevel string
}

type GuideApplicationModerationItem struct {
	ID             uuid.UUID
	GuideProfileID uuid.UUID
	GuideUserID    uuid.UUID

	GuideDisplayName string
	FirstName        string
	LastName         string
	CountryCode      string
	Locale           string
	Timezone         string

	Type                      string
	GuideStatus               string
	Status                    string
	Headline                  string
	About                     string
	ExperienceYears           int
	BaseCityID                string
	BaseCityName              string
	IsPrivateGuideAvailable   bool
	IsActivityHostAvailable   bool
	IsExcursionGuideAvailable bool
	RatingAvg                 float64
	ReviewsCount              int
	StatusReason              string
	StatusChangedAt           *time.Time
	StatusChangedBy           *uuid.UUID

	Comment       string
	ReviewComment string
	SubmittedAt   *time.Time
	ReviewedAt    *time.Time
	ReviewedBy    *uuid.UUID

	Documents       []GuideApplicationDocument
	Languages       []GuideApplicationLanguage
	Specializations []string

	RiskScore             int
	ModerationReasonCodes []string
	Revision              int
	CreatedAt             time.Time
	UpdatedAt             time.Time
}
