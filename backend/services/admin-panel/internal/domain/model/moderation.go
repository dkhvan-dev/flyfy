package model

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/enum"
)

type ModerationTargetType string

const (
	ModerationTargetExcursion   ModerationTargetType = "EXCURSION"
	ModerationTargetActivity    ModerationTargetType = "ACTIVITY"
	ModerationTargetChatMessage ModerationTargetType = "CHAT_MESSAGE"
	ModerationTargetStory       ModerationTargetType = "STORY"
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
