package model

import (
	"time"

	"github.com/google/uuid"
)

type PolicyAction string

const (
	PolicyActionActivityCreate         PolicyAction = "ACTIVITY_CREATE"
	PolicyActionTourPublish            PolicyAction = "TOUR_PUBLISH"
	PolicyActionChatSend               PolicyAction = "CHAT_SEND"
	PolicyActionFileUpload             PolicyAction = "FILE_UPLOAD"
	PolicyActionFileBind               PolicyAction = "FILE_BIND"
	PolicyActionPayoutRequest          PolicyAction = "PAYOUT_REQUEST"
	PolicyActionGuideApplicationSubmit PolicyAction = "GUIDE_APPLICATION_SUBMIT"
)

type PolicyDecision string

const (
	PolicyDecisionAllow      PolicyDecision = "ALLOW"
	PolicyDecisionDeny       PolicyDecision = "DENY"
	PolicyDecisionReview     PolicyDecision = "REVIEW"
	PolicyDecisionQuarantine PolicyDecision = "QUARANTINE"
	PolicyDecisionPending    PolicyDecision = "PENDING"
)

type TrustBand string

const (
	TrustBandNew     TrustBand = "NEW"
	TrustBandLow     TrustBand = "LOW"
	TrustBandNormal  TrustBand = "NORMAL"
	TrustBandTrusted TrustBand = "TRUSTED"
	TrustBandRisky   TrustBand = "RISKY"
	TrustBandBlocked TrustBand = "BLOCKED"
)

type TrustStatus string

const (
	TrustStatusActive      TrustStatus = "ACTIVE"
	TrustStatusUnderReview TrustStatus = "UNDER_REVIEW"
	TrustStatusRestricted  TrustStatus = "RESTRICTED"
)

type RuntimeRestrictionStatus string

const (
	RuntimeRestrictionActive  RuntimeRestrictionStatus = "ACTIVE"
	RuntimeRestrictionLifted  RuntimeRestrictionStatus = "LIFTED"
	RuntimeRestrictionExpired RuntimeRestrictionStatus = "EXPIRED"
)

type RestrictionAppealStatus string

const (
	RestrictionAppealStatusPending  RestrictionAppealStatus = "PENDING"
	RestrictionAppealStatusApproved RestrictionAppealStatus = "APPROVED"
	RestrictionAppealStatusRejected RestrictionAppealStatus = "REJECTED"
)

type RestrictionAppealDecision string

const (
	RestrictionAppealDecisionApprove RestrictionAppealDecision = "APPROVE"
	RestrictionAppealDecisionReject  RestrictionAppealDecision = "REJECT"
)

const (
	RestrictionCodeChat              = "CHAT"
	RestrictionCodeActivityCreation  = "ACTIVITY_CREATION"
	RestrictionCodeTourPublishing    = "TOUR_PUBLISHING"
	RestrictionCodeFileUpload        = "FILE_UPLOAD"
	RestrictionCodePayout            = "PAYOUT"
	RestrictionCodeGuideApplication  = "GUIDE_APPLICATION"
	RestrictionCodeAccountSuspension = "ACCOUNT_SUSPENSION"
)

const (
	RestrictionEventTypeCreated = "CREATED"
	RestrictionEventTypeLifted  = "LIFTED"
)

type TrustProfile struct {
	UserID       uuid.UUID
	Score        int
	Band         TrustBand
	Status       TrustStatus
	CalculatedAt time.Time
	CreatedAt    time.Time
	UpdatedAt    time.Time
}

type RuntimeRestriction struct {
	ID               uuid.UUID
	UserID           uuid.UUID
	CaseID           *uuid.UUID
	RestrictionCode  string
	Status           RuntimeRestrictionStatus
	ReasonCode       string
	SourceEventID    uuid.UUID
	CreatedByStaffID *uuid.UUID
	ExpiresAt        *time.Time
	CreatedAt        time.Time
	LiftedAt         *time.Time
	LiftedByStaffID  *uuid.UUID
}

type TrustContext struct {
	Profile            TrustProfile
	ActiveRestrictions []RuntimeRestriction
}

type PolicyCheckInput struct {
	UserID         uuid.UUID
	Action         PolicyAction
	ResourceType   string
	ResourceID     string
	IdempotencyKey string
	Metadata       map[string]any
	RequestedAt    time.Time
}

type PolicyDecisionRecord struct {
	ID               uuid.UUID
	UserID           uuid.UUID
	Action           PolicyAction
	ResourceType     string
	ResourceID       string
	IdempotencyKey   string
	Decision         PolicyDecision
	ReasonCode       string
	PublicMessageKey string
	InternalMessage  string
	TrustBand        TrustBand
	Score            int
	RestrictionIDs   []uuid.UUID
	CreatedAt        time.Time
}

type RestrictionEventInput struct {
	EventID          uuid.UUID
	EventType        string
	RestrictionID    uuid.UUID
	UserID           uuid.UUID
	CaseID           *uuid.UUID
	RestrictionCode  string
	ReasonCode       string
	CreatedByStaffID *uuid.UUID
	LiftedByStaffID  *uuid.UUID
	ExpiresAt        *time.Time
	OccurredAt       time.Time
}

type RestrictionAppeal struct {
	ID                 uuid.UUID
	UserID             uuid.UUID
	RestrictionID      uuid.UUID
	Status             RestrictionAppealStatus
	ReasonCode         string
	UserMessage        string
	IdempotencyKey     string
	CreatedAt          time.Time
	UpdatedAt          time.Time
	DecidedAt          *time.Time
	DecidedByStaffID   *uuid.UUID
	DecisionReasonCode string
	StaffComment       string
}

type SubmitRestrictionAppealInput struct {
	UserID         uuid.UUID
	RestrictionID  uuid.UUID
	ReasonCode     string
	UserMessage    string
	IdempotencyKey string
	SubmittedAt    time.Time
}

type ListRestrictionAppealsInput struct {
	Status RestrictionAppealStatus
	UserID *uuid.UUID
}

type DecideRestrictionAppealInput struct {
	AppealID        uuid.UUID
	ActorStaffID    uuid.UUID
	Decision        RestrictionAppealDecision
	ReasonCode      string
	StaffComment    string
	DecisionEventID uuid.UUID
	DecidedAt       time.Time
}
