package model

import (
	"strings"
	"time"
)

type LocalizedText struct {
	EN string `json:"en"`
	RU string `json:"ru"`
	KK string `json:"kk"`
}

func (t LocalizedText) Get(lang string) string {
	switch strings.ToLower(strings.TrimSpace(lang)) {
	case "ru":
		if t.RU != "" {
			return t.RU
		}
	case "kk":
		if t.KK != "" {
			return t.KK
		}
	}
	if t.EN != "" {
		return t.EN
	}
	if t.RU != "" {
		return t.RU
	}
	return t.KK
}

type TransportMode string

const (
	TransportModeFlight TransportMode = "flight"
	TransportModeTrain  TransportMode = "train"
	TransportModeBus    TransportMode = "bus"
	TransportModeCar    TransportMode = "car"
)

type TripDestination struct {
	CountryCode string `json:"countryCode"`
	CityName    string `json:"cityName"`
	CityID      string `json:"cityId"`
}

type TravelerProfile struct {
	HasChildren       bool   `json:"hasChildren"`
	PreferredLanguage string `json:"preferredLanguage"`
}

type ChecklistCategory string

const (
	ChecklistCategoryDocuments ChecklistCategory = "documents"
	ChecklistCategoryBaggage   ChecklistCategory = "baggage"
	ChecklistCategoryWeather   ChecklistCategory = "weather"
	ChecklistCategoryActivity  ChecklistCategory = "activity"
	ChecklistCategoryHealth    ChecklistCategory = "health"
	ChecklistCategorySafety    ChecklistCategory = "safety"
	ChecklistCategoryMoney     ChecklistCategory = "money"
	ChecklistCategoryCustom    ChecklistCategory = "custom"
)

type ChecklistPriority string

const (
	ChecklistPriorityCritical    ChecklistPriority = "critical"
	ChecklistPriorityEssential   ChecklistPriority = "essential"
	ChecklistPriorityImportant   ChecklistPriority = "important"
	ChecklistPriorityRecommended ChecklistPriority = "recommended"
	ChecklistPriorityOptional    ChecklistPriority = "optional"
)

type ChecklistItemStatus string

const (
	ChecklistItemOpen    ChecklistItemStatus = "open"
	ChecklistItemDone    ChecklistItemStatus = "done"
	ChecklistItemSkipped ChecklistItemStatus = "skipped"
)

type ChecklistFeedbackType string

const (
	ChecklistFeedbackHelpful     ChecklistFeedbackType = "helpful"
	ChecklistFeedbackNotHelpful  ChecklistFeedbackType = "not_helpful"
	ChecklistFeedbackAddNextTime ChecklistFeedbackType = "add_next_time"
)

type TrustLevel string

const (
	TrustLevelVerifiedCurated      TrustLevel = "verified_curated"
	TrustLevelOfficialLinkRequired TrustLevel = "official_link_required"
	TrustLevelGeneralAdvisory      TrustLevel = "general_advisory"
)

type SourceType string

const (
	SourceTypeOfficialAuthority SourceType = "official_authority"
	SourceTypeOpenData          SourceType = "open_data"
	SourceTypeCurated           SourceType = "curated"
)

type SourceConfidence string

const (
	SourceConfidenceHigh   SourceConfidence = "high"
	SourceConfidenceMedium SourceConfidence = "medium"
	SourceConfidenceLow    SourceConfidence = "low"
)

type Source struct {
	Name       string           `json:"name"`
	URL        string           `json:"url"`
	Type       SourceType       `json:"type"`
	Confidence SourceConfidence `json:"confidence"`
	ReviewedAt time.Time        `json:"reviewedAt,omitempty"`
}

type RuleCondition struct {
	Always              bool
	CountryCode         string
	CityName            string
	Month               time.Month
	ActivitySlug        string
	TravelerHasChildren bool
	TransportMode       TransportMode
}

type ChecklistTemplate struct {
	ID                       string
	Category                 ChecklistCategory
	Priority                 ChecklistPriority
	Title                    LocalizedText
	Reason                   LocalizedText
	TrustLevel               TrustLevel
	Source                   Source
	RequiresUserConfirmation bool
	AppliesTo                RuleCondition
}

type ChecklistItem struct {
	ID                       string              `json:"id"`
	Category                 ChecklistCategory   `json:"category"`
	Priority                 ChecklistPriority   `json:"priority"`
	Status                   ChecklistItemStatus `json:"status"`
	AssignedUserID           string              `json:"assignedUserId,omitempty"`
	Title                    LocalizedText       `json:"title"`
	Reason                   LocalizedText       `json:"reason"`
	TrustLevel               TrustLevel          `json:"trustLevel"`
	Source                   Source              `json:"source"`
	RequiresUserConfirmation bool                `json:"requiresUserConfirmation"`
	DeadlineAt               *time.Time          `json:"deadlineAt,omitempty"`
}

type ChecklistItemFeedback struct {
	ID                  string                `json:"id"`
	ChecklistInstanceID string                `json:"checklistInstanceId"`
	UserID              string                `json:"userId"`
	TripID              string                `json:"tripId"`
	ItemID              string                `json:"itemId"`
	FeedbackType        ChecklistFeedbackType `json:"type"`
	Comment             string                `json:"comment"`
	CreatedAt           time.Time             `json:"createdAt"`
}

type CustomChecklistItem struct {
	ID                  string              `json:"id"`
	ChecklistInstanceID string              `json:"checklistInstanceId"`
	UserID              string              `json:"userId"`
	TripID              string              `json:"tripId"`
	Title               string              `json:"title"`
	Note                string              `json:"note"`
	Category            ChecklistCategory   `json:"category"`
	Priority            ChecklistPriority   `json:"priority"`
	Status              ChecklistItemStatus `json:"status"`
	AssignedUserID      string              `json:"assignedUserId,omitempty"`
	ReuseInFuture       bool                `json:"reuseInFuture"`
	PersonalTemplateID  string              `json:"personalTemplateId,omitempty"`
	CreatedAt           time.Time           `json:"createdAt"`
	UpdatedAt           time.Time           `json:"updatedAt"`
	DeletedAt           *time.Time          `json:"deletedAt,omitempty"`
}

type PersonalChecklistTemplate struct {
	ID        string            `json:"id"`
	UserID    string            `json:"userId"`
	Title     string            `json:"title"`
	Note      string            `json:"note"`
	Category  ChecklistCategory `json:"category"`
	Priority  ChecklistPriority `json:"priority"`
	IsActive  bool              `json:"isActive"`
	CreatedAt time.Time         `json:"createdAt"`
	UpdatedAt time.Time         `json:"updatedAt"`
}

type PersonalChecklistProgress struct {
	Total   int `json:"total"`
	Done    int `json:"done"`
	Percent int `json:"percent"`
}

type ChecklistReminderStatus string

const (
	ChecklistReminderScheduled ChecklistReminderStatus = "scheduled"
	ChecklistReminderDue       ChecklistReminderStatus = "due"
	ChecklistReminderOverdue   ChecklistReminderStatus = "overdue"
)

type ChecklistReminder struct {
	ID         string                  `json:"id"`
	OffsetDays int                     `json:"offsetDays"`
	DueAt      time.Time               `json:"dueAt"`
	Status     ChecklistReminderStatus `json:"status"`
	Title      LocalizedText           `json:"title"`
	Message    LocalizedText           `json:"message"`
}

type TemperatureBand string

const (
	TemperatureCold    TemperatureBand = "cold"
	TemperatureMild    TemperatureBand = "mild"
	TemperatureWarm    TemperatureBand = "warm"
	TemperatureHot     TemperatureBand = "hot"
	TemperatureVeryHot TemperatureBand = "very_hot"
)

type PrecipitationBand string

const (
	PrecipitationDry            PrecipitationBand = "dry"
	PrecipitationOccasionalRain PrecipitationBand = "occasional_rain"
	PrecipitationRainy          PrecipitationBand = "rainy"
	PrecipitationMonsoon        PrecipitationBand = "monsoon"
	PrecipitationSnow           PrecipitationBand = "snow"
)

type SkyBand string

const (
	SkySunny  SkyBand = "sunny"
	SkyMixed  SkyBand = "mixed"
	SkyCloudy SkyBand = "cloudy"
)

type SeasonalProfile struct {
	Destination         TripDestination
	Month               time.Month
	TemperatureBand     TemperatureBand
	PrecipitationBand   PrecipitationBand
	SkyBand             SkyBand
	RiskTags            []string
	PackingImplications []LocalizedText
	Source              Source
}

type CarryPolicy string

const (
	CarryPolicyAllowed               CarryPolicy = "allowed"
	CarryPolicyAllowedWithConditions CarryPolicy = "allowed_with_conditions"
	CarryPolicyProhibited            CarryPolicy = "prohibited"
	CarryPolicyCheckAuthority        CarryPolicy = "check_authority"
)

type CarryRule struct {
	ItemSlug             string
	Aliases              []string
	TransportMode        TransportMode
	CarryOn              CarryPolicy
	CheckedBaggage       CarryPolicy
	RequiresAirlineCheck bool
	ConditionSummary     LocalizedText
	Source               Source
}

type CatalogSeed struct {
	Templates        []ChecklistTemplate
	SeasonalProfiles []SeasonalProfile
	CarryRules       []CarryRule
}

type ReadinessStatus string

const (
	ReadinessStatusNotReady          ReadinessStatus = "not_ready"
	ReadinessStatusAtRisk            ReadinessStatus = "at_risk"
	ReadinessStatusOnTrack           ReadinessStatus = "on_track"
	ReadinessStatusAlmostReady       ReadinessStatus = "almost_ready"
	ReadinessStatusReady             ReadinessStatus = "ready"
	ReadinessStatusReadyWithWarnings ReadinessStatus = "ready_with_warnings"
)

type ReadinessBlocker struct {
	ItemID   string            `json:"itemId"`
	Priority ChecklistPriority `json:"priority"`
	Reason   LocalizedText     `json:"reason"`
}

type ReadinessSummary struct {
	Score    int                `json:"score"`
	Status   ReadinessStatus    `json:"status"`
	Blockers []ReadinessBlocker `json:"blockers"`
}

type TrustNotice struct {
	Code    string        `json:"code"`
	Title   LocalizedText `json:"title"`
	Message LocalizedText `json:"message"`
}

type TripChecklist struct {
	InstanceID       string                    `json:"instanceId,omitempty"`
	UserID           string                    `json:"userId,omitempty"`
	TripID           string                    `json:"tripId"`
	Destination      TripDestination           `json:"destination"`
	StartAt          time.Time                 `json:"startAt"`
	EndAt            time.Time                 `json:"endAt"`
	TransportModes   []TransportMode           `json:"transportModes,omitempty"`
	ActivitySlugs    []string                  `json:"activitySlugs,omitempty"`
	TravelerProfile  TravelerProfile           `json:"travelerProfile,omitempty"`
	Items            []ChecklistItem           `json:"items"`
	CustomItems      []CustomChecklistItem     `json:"customItems,omitempty"`
	Readiness        ReadinessSummary          `json:"readiness"`
	PersonalProgress PersonalChecklistProgress `json:"personalProgress"`
	SeasonalProfile  *SeasonalProfile          `json:"seasonalProfile,omitempty"`
	TrustNotice      TrustNotice               `json:"trustNotice"`
	GeneratedAt      time.Time                 `json:"generatedAt"`
	UpdatedAt        time.Time                 `json:"updatedAt,omitempty"`
}
