package model

import (
	"time"

	"github.com/google/uuid"
)

type AdminUserListFilter struct {
	PageSize       int
	PageToken      string
	Query          string
	Status         string
	Role           string
	CountryCode    string
	CreatedFrom    *time.Time
	CreatedTo      *time.Time
	LastActiveFrom *time.Time
	LastActiveTo   *time.Time
}

type AdminUserListItem struct {
	UserID                  uuid.UUID
	Nickname                string
	MaskedPhone             string
	MaskedEmail             string
	CountryCode             string
	Roles                   []string
	AccountStatus           string
	GuideStatus             string
	TrustBand               string
	TrustScore              *int
	OpenModerationCaseCount int
	ActiveRestrictionCount  int
	CreatedAt               time.Time
	LastActiveAt            *time.Time
}

type AdminUserListPage struct {
	Items         []AdminUserListItem
	NextPageToken string
}

type AdminUserDetail struct {
	UserID                  uuid.UUID
	Nickname                string
	MaskedPhone             string
	MaskedEmail             string
	CountryCode             string
	Roles                   []string
	AccountStatus           string
	GuideStatus             string
	TrustBand               string
	TrustScore              *int
	OpenModerationCaseCount int
	ActiveRestrictionCount  int
	CreatedAt               time.Time
	UpdatedAt               time.Time
	LastActiveAt            *time.Time
}

type AdminUserDetailPage struct {
	User               AdminUserDetail
	ModerationCases    []UserModerationCase
	ActiveRestrictions []UserManualRestriction
}

type UserModerationSource string

const (
	UserModerationSourceStaff             UserModerationSource = "STAFF"
	UserModerationSourceReport            UserModerationSource = "REPORT"
	UserModerationSourceFraud             UserModerationSource = "FRAUD"
	UserModerationSourcePayment           UserModerationSource = "PAYMENT"
	UserModerationSourceGuideVerification UserModerationSource = "GUIDE_VERIFICATION"
	UserModerationSourceFileScan          UserModerationSource = "FILE_SCAN"
	UserModerationSourceSystem            UserModerationSource = "SYSTEM"
)

type UserModerationPriority string

const (
	UserModerationPriorityLow      UserModerationPriority = "LOW"
	UserModerationPriorityNormal   UserModerationPriority = "NORMAL"
	UserModerationPriorityHigh     UserModerationPriority = "HIGH"
	UserModerationPriorityCritical UserModerationPriority = "CRITICAL"
)

type UserModerationStatus string

const (
	UserModerationStatusOpen        UserModerationStatus = "OPEN"
	UserModerationStatusInReview    UserModerationStatus = "IN_REVIEW"
	UserModerationStatusWaitingUser UserModerationStatus = "WAITING_USER"
	UserModerationStatusEscalated   UserModerationStatus = "ESCALATED"
	UserModerationStatusResolved    UserModerationStatus = "RESOLVED"
	UserModerationStatusDismissed   UserModerationStatus = "DISMISSED"
)

type UserModerationDecision string

const (
	UserModerationDecisionNoAction          UserModerationDecision = "NO_ACTION"
	UserModerationDecisionInternalNote      UserModerationDecision = "INTERNAL_NOTE"
	UserModerationDecisionWarning           UserModerationDecision = "WARNING"
	UserModerationDecisionRequestVerify     UserModerationDecision = "REQUEST_VERIFICATION"
	UserModerationDecisionRestrict          UserModerationDecision = "RESTRICT"
	UserModerationDecisionSuspend           UserModerationDecision = "SUSPEND"
	UserModerationDecisionPermanentBlock    UserModerationDecision = "PERMANENT_BLOCK"
	UserModerationDecisionRemoveRestriction UserModerationDecision = "REMOVE_RESTRICTION"
	UserModerationDecisionEscalate          UserModerationDecision = "ESCALATE"
)

type UserRestrictionCode string

const (
	UserRestrictionChat              UserRestrictionCode = "CHAT"
	UserRestrictionActivityCreation  UserRestrictionCode = "ACTIVITY_CREATION"
	UserRestrictionTourPublishing    UserRestrictionCode = "TOUR_PUBLISHING"
	UserRestrictionFileUpload        UserRestrictionCode = "FILE_UPLOAD"
	UserRestrictionPayout            UserRestrictionCode = "PAYOUT"
	UserRestrictionGuideApplication  UserRestrictionCode = "GUIDE_APPLICATION"
	UserRestrictionAccountSuspension UserRestrictionCode = "ACCOUNT_SUSPENSION"
)

type UserRestrictionStatus string

const (
	UserRestrictionStatusActive  UserRestrictionStatus = "ACTIVE"
	UserRestrictionStatusLifted  UserRestrictionStatus = "LIFTED"
	UserRestrictionStatusExpired UserRestrictionStatus = "EXPIRED"
)

type UserModerationCase struct {
	ID              uuid.UUID
	TargetUserID    uuid.UUID
	Source          UserModerationSource
	ReasonCode      string
	Priority        UserModerationPriority
	Status          UserModerationStatus
	AssignedStaffID *uuid.UUID
	Decision        *UserModerationDecision
	StaffComment    string
	CreatedAt       time.Time
	UpdatedAt       time.Time
	ResolvedAt      *time.Time
}

type UserModerationCaseEvent struct {
	ID           uuid.UUID
	CaseID       uuid.UUID
	ActorStaffID uuid.UUID
	EventType    string
	FromStatus   *UserModerationStatus
	ToStatus     *UserModerationStatus
	Decision     *UserModerationDecision
	ReasonCode   string
	Comment      string
	CreatedAt    time.Time
}

type UserManualRestriction struct {
	ID               uuid.UUID
	UserID           uuid.UUID
	CaseID           *uuid.UUID
	RestrictionCode  UserRestrictionCode
	Status           UserRestrictionStatus
	ReasonCode       string
	StaffComment     string
	CreatedByStaffID uuid.UUID
	ExpiresAt        *time.Time
	CreatedAt        time.Time
	LiftedAt         *time.Time
	LiftedByStaffID  *uuid.UUID
}

type UserRestrictionOutboxStatus string

const (
	UserRestrictionOutboxPending   UserRestrictionOutboxStatus = "PENDING"
	UserRestrictionOutboxDelivered UserRestrictionOutboxStatus = "DELIVERED"
	UserRestrictionOutboxDead      UserRestrictionOutboxStatus = "DEAD"
)

const (
	UserRestrictionOutboxEventCreated = "USER_RESTRICTION_CREATED"
	UserRestrictionOutboxEventLifted  = "USER_RESTRICTION_LIFTED"
)

type UserRestrictionOutboxEvent struct {
	ID            uuid.UUID
	EventType     string
	AggregateID   uuid.UUID
	UserID        uuid.UUID
	Payload       []byte
	Status        UserRestrictionOutboxStatus
	AttemptCount  int
	NextAttemptAt time.Time
	LastError     string
	CreatedAt     time.Time
	DeliveredAt   *time.Time
}

type TrustRestrictionAppealStatus string

const (
	TrustRestrictionAppealStatusOpen     TrustRestrictionAppealStatus = "OPEN"
	TrustRestrictionAppealStatusApproved TrustRestrictionAppealStatus = "APPROVED"
	TrustRestrictionAppealStatusRejected TrustRestrictionAppealStatus = "REJECTED"
)

type TrustRestrictionAppealDecision string

const (
	TrustRestrictionAppealDecisionApprove TrustRestrictionAppealDecision = "APPROVE"
	TrustRestrictionAppealDecisionReject  TrustRestrictionAppealDecision = "REJECT"
)

type TrustRestrictionAppealFilter struct {
	Status    TrustRestrictionAppealStatus
	Query     string
	PageSize  int
	PageToken string
}

type TrustRestrictionAppealListPage struct {
	Items         []TrustRestrictionAppeal
	NextPageToken string
}

type TrustRestrictionAppeal struct {
	ID               uuid.UUID
	RestrictionID    uuid.UUID
	UserID           uuid.UUID
	RestrictionCode  UserRestrictionCode
	Status           TrustRestrictionAppealStatus
	ReasonCode       string
	UserMessage      string
	StaffDecision    *TrustRestrictionAppealDecision
	StaffComment     string
	DecidedByStaffID *uuid.UUID
	CreatedAt        time.Time
	UpdatedAt        time.Time
	DecidedAt        *time.Time
}

type TrustRestrictionAppealDecisionInput struct {
	AppealID       uuid.UUID
	ActorStaffID   uuid.UUID
	Decision       TrustRestrictionAppealDecision
	ReasonCode     string
	StaffComment   string
	IdempotencyKey string
	RequestID      string
}

type CreateUserModerationCaseParams struct {
	TargetUserID     uuid.UUID
	Source           UserModerationSource
	ReasonCode       string
	Priority         UserModerationPriority
	AssignedStaffID  *uuid.UUID
	CreatedByStaffID uuid.UUID
	StaffComment     string
}

type ResolveUserModerationCaseParams struct {
	CaseID       uuid.UUID
	ActorStaffID uuid.UUID
	Decision     UserModerationDecision
	ReasonCode   string
	StaffComment string
}

type CreateUserRestrictionParams struct {
	UserID           uuid.UUID
	CaseID           *uuid.UUID
	RestrictionCode  UserRestrictionCode
	ReasonCode       string
	StaffComment     string
	CreatedByStaffID uuid.UUID
	ExpiresAt        *time.Time
}

type LiftUserRestrictionParams struct {
	RestrictionID   uuid.UUID
	LiftedByStaffID uuid.UUID
	ReasonCode      string
	StaffComment    string
}
