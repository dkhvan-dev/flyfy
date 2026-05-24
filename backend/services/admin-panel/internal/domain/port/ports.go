package port

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/model"
)

var ErrDuplicateDecision = errors.New("moderation decision was already submitted")
var ErrModerationCaseConflict = errors.New("moderation case changed while applying decision")

type StaffRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*model.StaffUser, error)
	GetByEmail(ctx context.Context, email string) (*model.StaffUser, error)
	List(ctx context.Context, limit int, offset int) ([]*model.StaffUser, error)
	Create(ctx context.Context, staff *model.StaffUser, passwordHash string, roles []enum.StaffRole) error
	UpdateProfileAndRoles(ctx context.Context, id uuid.UUID, displayName string, roles []enum.StaffRole, assignedBy uuid.UUID, now time.Time) error
	UpdateLoginSuccess(ctx context.Context, id uuid.UUID, now time.Time) error
	UpdateLoginFailure(ctx context.Context, id uuid.UUID, failedCount int, lockedUntil *time.Time) error
	UpdatePassword(ctx context.Context, id uuid.UUID, passwordHash string, status enum.StaffStatus, now time.Time) error
	SetStatus(ctx context.Context, id uuid.UUID, status enum.StaffStatus, now time.Time) error
	GetPermissions(ctx context.Context, staffID uuid.UUID) ([]enum.Permission, []enum.StaffRole, error)
}

type SessionRepository interface {
	Create(ctx context.Context, session *model.StaffSession) error
	GetBySessionHash(ctx context.Context, sessionHash string) (*model.StaffSession, error)
	Touch(ctx context.Context, id uuid.UUID, expiresAt time.Time, now time.Time) error
	Revoke(ctx context.Context, id uuid.UUID, now time.Time) error
	RevokeAllForStaff(ctx context.Context, staffID uuid.UUID, now time.Time) error
}

type LoginAttemptRepository interface {
	Append(ctx context.Context, attempt *model.StaffLoginAttempt) error
	CountFailuresSince(ctx context.Context, emailHash string, ipAddressHash string, since time.Time) (int, error)
}

type AuditRepository interface {
	Append(ctx context.Context, event *model.AuditEvent) error
	List(ctx context.Context, filter model.AuditFilter) ([]*model.AuditEvent, error)
}

type ModerationRepository interface {
	UpsertExcursionCase(ctx context.Context, item model.ExcursionModerationItem) (*model.ModerationCase, error)
	CancelStaleExcursionCases(ctx context.Context, activeTargetIDs []uuid.UUID, now time.Time) error
	UpsertActivityCase(ctx context.Context, item model.ActivityModerationItem) (*model.ModerationCase, error)
	CancelStaleActivityCases(ctx context.Context, activeTargetIDs []uuid.UUID, now time.Time) error
	ListCases(ctx context.Context, filter model.ModerationQueueFilter) ([]*model.ModerationCase, error)
	GetCase(ctx context.Context, id uuid.UUID) (*model.ModerationCase, error)
	ListDecisions(ctx context.Context, caseID uuid.UUID) ([]*model.ModerationDecision, error)
	CreateDecision(ctx context.Context, decision *model.ModerationDecision) error
	MarkDecisionApplied(ctx context.Context, decisionID uuid.UUID, response []byte, now time.Time) error
	MarkDecisionFailed(ctx context.Context, decisionID uuid.UUID, response []byte, now time.Time) error
	SupersedeAppliedDecisions(ctx context.Context, caseID uuid.UUID, sourceRevision int, exceptDecisionID uuid.UUID, now time.Time) error
	UpdateCaseStatus(ctx context.Context, caseID uuid.UUID, status enum.ModerationCaseStatus, resolvedAt *time.Time, now time.Time) error
}

type ExcursionClient interface {
	ListPendingReview(ctx context.Context, limit int, offset int) ([]model.ExcursionModerationItem, error)
	GetExcursion(ctx context.Context, id uuid.UUID) (*model.ExcursionModerationItem, error)
	Approve(ctx context.Context, input ExcursionDecisionInput) (*model.ExcursionModerationItem, []byte, error)
	Reject(ctx context.Context, input ExcursionDecisionInput) (*model.ExcursionModerationItem, []byte, error)
}

type ExcursionDecisionInput struct {
	ExcursionID    uuid.UUID
	ActorStaffID   uuid.UUID
	ReasonCodes    []string
	PublicComment  string
	IdempotencyKey string
	RequestID      string
}

type ActivityClient interface {
	ListFlagged(ctx context.Context, limit int, offset int) ([]model.ActivityModerationItem, error)
	GetActivity(ctx context.Context, id uuid.UUID) (*model.ActivityModerationItem, error)
	Approve(ctx context.Context, input ActivityDecisionInput) (*model.ActivityModerationItem, []byte, error)
	Reject(ctx context.Context, input ActivityDecisionInput) (*model.ActivityModerationItem, []byte, error)
}

type ActivityDecisionInput struct {
	ActivityID     uuid.UUID
	ActorStaffID   uuid.UUID
	ReasonCodes    []string
	PublicComment  string
	IdempotencyKey string
	RequestID      string
}
