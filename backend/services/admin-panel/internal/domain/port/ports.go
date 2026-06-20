package port

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

var ErrDuplicateDecision = errors.New("moderation decision was already submitted")
var ErrModerationCaseConflict = errors.New("moderation case changed while applying decision")

type StaffRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*model.StaffUser, error)
	GetByEmail(ctx context.Context, email string) (*model.StaffUser, error)
	List(ctx context.Context, limit int, offset int) ([]*model.StaffUser, error)
	Create(ctx context.Context, staff *model.StaffUser, passwordHash string, roles []enum.StaffRole) error
	UpdateProfileAndRoles(ctx context.Context, id uuid.UUID, displayName string, roles []enum.StaffRole, assignedBy uuid.UUID, now time.Time) error
	UpdateTimezone(ctx context.Context, id uuid.UUID, timezone string, now time.Time) error
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

type UserNotificationInput struct {
	IdempotencyKey   string
	RecipientUserIDs []uuid.UUID
	Category         string
	Priority         string
	Title            string
	Body             string
	DeepLink         string
	Data             map[string]string
	CollapseKey      string
	TTL              time.Duration
}

type UserNotificationGateway interface {
	SendUserNotification(ctx context.Context, input UserNotificationInput) error
}

type UserAdminClient interface {
	ListAdminUsers(ctx context.Context, filter model.AdminUserListFilter) (model.AdminUserListPage, error)
	GetAdminUserDetail(ctx context.Context, userID uuid.UUID) (model.AdminUserDetail, error)
}

type UserModerationRepository interface {
	CreateUserModerationCase(ctx context.Context, params model.CreateUserModerationCaseParams) (model.UserModerationCase, error)
	GetUserModerationCase(ctx context.Context, id uuid.UUID) (model.UserModerationCase, error)
	ListUserModerationCases(ctx context.Context, userID uuid.UUID) ([]model.UserModerationCase, error)
	ResolveUserModerationCase(ctx context.Context, params model.ResolveUserModerationCaseParams) (model.UserModerationCase, error)
	CreateUserRestriction(ctx context.Context, params model.CreateUserRestrictionParams) (model.UserManualRestriction, error)
	LiftUserRestriction(ctx context.Context, params model.LiftUserRestrictionParams) (model.UserManualRestriction, error)
	ListActiveUserRestrictions(ctx context.Context, userID uuid.UUID) ([]model.UserManualRestriction, error)
}

type UserRestrictionOutboxRepository interface {
	ListDueUserRestrictionEvents(ctx context.Context, limit int, now time.Time) ([]model.UserRestrictionOutboxEvent, error)
	MarkUserRestrictionEventDelivered(ctx context.Context, eventID uuid.UUID, deliveredAt time.Time) error
	MarkUserRestrictionEventFailed(ctx context.Context, eventID uuid.UUID, reason string, nextAttemptAt time.Time) error
}

type TrustRestrictionEventClient interface {
	ApplyUserRestrictionEvent(ctx context.Context, event model.UserRestrictionOutboxEvent) (bool, error)
}

type TrustRestrictionAppealClient interface {
	ListRestrictionAppeals(ctx context.Context, filter model.TrustRestrictionAppealFilter) (model.TrustRestrictionAppealListPage, error)
	GetRestrictionAppeal(ctx context.Context, id uuid.UUID) (model.TrustRestrictionAppeal, error)
	DecideRestrictionAppeal(ctx context.Context, input model.TrustRestrictionAppealDecisionInput) (model.TrustRestrictionAppeal, error)
}

type ModerationRepository interface {
	UpsertExcursionCase(ctx context.Context, item model.ExcursionModerationItem) (*model.ModerationCase, error)
	CancelStaleExcursionCases(ctx context.Context, activeTargetIDs []uuid.UUID, now time.Time) error
	UpsertActivityCase(ctx context.Context, item model.ActivityModerationItem) (*model.ModerationCase, error)
	CancelStaleActivityCases(ctx context.Context, activeTargetIDs []uuid.UUID, now time.Time) error
	UpsertGuideApplicationCase(ctx context.Context, item model.GuideApplicationModerationItem) (*model.ModerationCase, error)
	CancelStaleGuideApplicationCases(ctx context.Context, activeTargetIDs []uuid.UUID, now time.Time) error
	UpsertChatMessageCase(ctx context.Context, item model.ChatMessageModerationItem) (*model.ModerationCase, error)
	CancelStaleChatMessageCases(ctx context.Context, activeTargetIDs []uuid.UUID, now time.Time) error
	UpsertPostReportCase(ctx context.Context, item model.PostReportModerationItem) (*model.ModerationCase, error)
	CancelStalePostReportCases(ctx context.Context, activeTargetIDs []uuid.UUID, now time.Time) error
	UpsertStoryCase(ctx context.Context, item model.PostModerationItem) (*model.ModerationCase, error)
	CancelStaleStoryCases(ctx context.Context, activeTargetIDs []uuid.UUID, now time.Time) error
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

type GuideApplicationClient interface {
	ListPendingApplications(ctx context.Context, limit int, offset int) ([]model.GuideApplicationModerationItem, error)
	ListActiveGuides(ctx context.Context, limit int, offset int) ([]model.GuideApplicationModerationItem, error)
	GetApplication(ctx context.Context, id uuid.UUID) (*model.GuideApplicationModerationItem, error)
	Approve(ctx context.Context, input GuideApplicationDecisionInput) (*model.GuideApplicationModerationItem, []byte, error)
	Reject(ctx context.Context, input GuideApplicationDecisionInput) (*model.GuideApplicationModerationItem, []byte, error)
	Revoke(ctx context.Context, input GuideApplicationDecisionInput) (*model.GuideApplicationModerationItem, []byte, error)
	RevokeProfile(ctx context.Context, input GuideProfileDecisionInput) (*model.GuideApplicationModerationItem, []byte, error)
}

type GuideApplicationDecisionInput struct {
	GuideApplicationID uuid.UUID
	ActorStaffID       uuid.UUID
	ReasonCodes        []string
	PublicComment      string
	IdempotencyKey     string
	RequestID          string
}

type GuideProfileDecisionInput struct {
	GuideProfileID uuid.UUID
	ActorStaffID   uuid.UUID
	ReasonCodes    []string
	PublicComment  string
	IdempotencyKey string
	RequestID      string
}

type ChatClient interface {
	ListFlaggedMessages(ctx context.Context, limit int, offset int) ([]model.ChatMessageModerationItem, error)
	GetMessage(ctx context.Context, id uuid.UUID) (*model.ChatMessageModerationItem, error)
	ApproveMessage(ctx context.Context, input ChatMessageDecisionInput) (*model.ChatMessageModerationItem, []byte, error)
	HideMessage(ctx context.Context, input ChatMessageDecisionInput) (*model.ChatMessageModerationItem, []byte, error)
}

type PostReportClient interface {
	ListOpenReports(ctx context.Context, limit int, offset int) ([]model.PostReportModerationItem, error)
	ListPendingCommunityPosts(ctx context.Context, limit int, offset int) ([]model.PostModerationItem, error)
	GetReport(ctx context.Context, id uuid.UUID) (*model.PostReportModerationItem, error)
	GetCommunityPost(ctx context.Context, id uuid.UUID) (*model.PostModerationItem, error)
	ReviewReport(ctx context.Context, input PostReportDecisionInput) (*model.PostReportModerationItem, []byte, error)
	DismissReport(ctx context.Context, input PostReportDecisionInput) (*model.PostReportModerationItem, []byte, error)
	ApproveCommunityPost(ctx context.Context, input CommunityPostDecisionInput) (*model.PostModerationItem, []byte, error)
	RejectCommunityPost(ctx context.Context, input CommunityPostDecisionInput) (*model.PostModerationItem, []byte, error)
}

type CommunityAdminClient interface {
	CreateCommunity(ctx context.Context, input CreateCommunityInput) (model.AdminCommunity, error)
	GetCommunity(ctx context.Context, id uuid.UUID) (model.AdminCommunity, error)
	UpdateCommunity(ctx context.Context, id uuid.UUID, input UpdateCommunityInput) (model.AdminCommunity, error)
	CommunityPlatformCatalog(ctx context.Context, input CommunityPlatformCatalogInput) (model.CommunityPlatformCatalog, error)
	MaterializeCommunityInstances(ctx context.Context, input MaterializeCommunityInstancesInput) (model.CommunityMaterializationResult, error)
}

type CreateCommunityInput struct {
	ActorStaffID    uuid.UUID
	Slug            string
	TitleI18n       map[string]string
	DescriptionI18n map[string]string
	RulesI18n       map[string][]string
	Topic           string
	CityID          *string
	CountryCode     *string
	AvatarFileID    *uuid.UUID
	CoverFileID     *uuid.UUID
	Visibility      string
	PostingPolicy   string
	Status          string
	RequestID       string
}

type UpdateCommunityInput struct {
	ActorStaffID    uuid.UUID
	Slug            string
	TitleI18n       map[string]string
	DescriptionI18n map[string]string
	RulesI18n       map[string][]string
	Topic           string
	CityID          *string
	CountryCode     *string
	AvatarFileID    *uuid.UUID
	CoverFileID     *uuid.UUID
	Visibility      string
	PostingPolicy   string
	Status          string
	RequestID       string
}

type CommunityPlatformCatalogInput struct {
	CountryCode string
	CityID      string
	ScopeType   string
	Search      string
	Limit       int
	Offset      int
}

type MaterializeCommunityInstancesInput struct {
	ActorStaffID uuid.UUID
	BlueprintID  uuid.UUID
	CountryCode  string
	CityID       string
	ScopeType    string
	Limit        int
	RequestID    string
}

type FeedQualityClient interface {
	ListFeedQualityMetrics(ctx context.Context, filter model.FeedQualityMetricFilter) ([]model.FeedQualityMetric, error)
}

type FeatureFlagAdminClient interface {
	ListDomains(ctx context.Context, filter model.OperationDomainFilter) (model.OperationDomainPage, error)
	FindDomain(ctx context.Context, code string) (*model.OperationDomain, error)
	UpsertDomain(ctx context.Context, input model.OperationDomainInput) (model.OperationDomain, error)
	ListFeatureFlags(ctx context.Context, filter model.OperationFeatureFlagFilter) (model.OperationPage[model.OperationFeatureFlag], error)
	GetFeatureFlag(ctx context.Context, domainCode string, code string) (model.OperationFeatureFlag, error)
	UpsertFeatureFlag(ctx context.Context, input model.OperationFeatureFlagInput) (model.OperationFeatureFlag, error)
	ArchiveFeatureFlag(ctx context.Context, domainCode string, code string) error
	RecoverFeatureFlag(ctx context.Context, domainCode string, code string) (model.OperationFeatureFlag, error)
	ListFeatureFlagHistory(ctx context.Context, filter model.OperationFeatureFlagHistoryFilter) (model.OperationPage[model.OperationFeatureFlagHistory], error)
}

type TechBreakAdminClient interface {
	ListDomains(ctx context.Context, filter model.OperationDomainFilter) (model.OperationDomainPage, error)
	FindDomain(ctx context.Context, code string) (*model.OperationDomain, error)
	UpsertDomain(ctx context.Context, input model.OperationDomainInput) (model.OperationDomain, error)
	ListTechBreaks(ctx context.Context, filter model.OperationTechBreakFilter) (model.OperationPage[model.OperationTechBreak], error)
	GetTechBreak(ctx context.Context, id int64, domainCode string) (model.OperationTechBreak, error)
	UpsertTechBreak(ctx context.Context, input model.OperationTechBreakInput) (model.OperationTechBreak, error)
	ArchiveTechBreak(ctx context.Context, id int64, domainCode string) error
	ListScopes(ctx context.Context, domainCode string) ([]model.OperationTechBreakScope, error)
	GetScope(ctx context.Context, id int64, domainCode string) (model.OperationTechBreakScope, error)
	UpsertScope(ctx context.Context, input model.OperationTechBreakScopeInput) (model.OperationTechBreakScope, error)
	ArchiveScope(ctx context.Context, id int64, domainCode string) error
}

type AntiFraudClient interface {
	ListFraudBlocks(ctx context.Context, target model.FraudBlockTarget, limit int, offset int) ([]model.FraudBlock, error)
	ReviewFraudBlock(ctx context.Context, input model.FraudBlockReviewInput) (*model.FraudBlock, error)
}

type ChatMessageDecisionInput struct {
	MessageID       uuid.UUID
	ActorStaffID    uuid.UUID
	ReasonCodes     []string
	PublicComment   string
	InternalComment string
	IdempotencyKey  string
	RequestID       string
}

type PostReportDecisionInput struct {
	ReportID        uuid.UUID
	ActorStaffID    uuid.UUID
	InternalComment string
	IdempotencyKey  string
	RequestID       string
}

type CommunityPostDecisionInput struct {
	PostID          uuid.UUID
	ActorStaffID    uuid.UUID
	InternalComment string
	IdempotencyKey  string
	RequestID       string
}

type PlaceAdminClient interface {
	ListPlaces(ctx context.Context, filter model.AdminPlaceFilter) ([]model.AdminPlace, int, error)
	GetPlace(ctx context.Context, id uuid.UUID) (*model.AdminPlace, error)
	CreatePlace(ctx context.Context, input model.PlaceInput) (*model.AdminPlace, error)
	UpdatePlace(ctx context.Context, id uuid.UUID, input model.PlaceInput) (*model.AdminPlace, error)
	ReplaceMedia(ctx context.Context, id uuid.UUID, media []model.PlaceMediaInput) error
}

type FileUploadClient interface {
	UploadPublicPlaceImage(ctx context.Context, input model.FileUploadInput) (*model.UploadedFile, error)
	GetPublicContent(ctx context.Context, fileID uuid.UUID) (*model.FileContent, error)
}
