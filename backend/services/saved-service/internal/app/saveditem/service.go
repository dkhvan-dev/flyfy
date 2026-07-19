package saveditem

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/app/operation"
	"kz/inflap/backend/services/saved-service/internal/app/savedaccess"
	appsession "kz/inflap/backend/services/saved-service/internal/app/session"
	appsource "kz/inflap/backend/services/saved-service/internal/app/source"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

var ErrInvalidServiceDependencies = errors.New("invalid saved item service dependencies")

type OperationBeginner interface {
	Begin(context.Context, operation.BeginRequest) (operation.BeginResult, error)
}

type PolicyGrant struct {
	Revision uint64
}

// PolicyGate maps platform-policy implementation details to Saved's stable,
// transport-neutral domain errors.
type PolicyGate interface {
	Guard(context.Context) (PolicyGrant, error)
	ValidateCommit(context.Context, uint64) error
}

type Clock interface {
	Now() time.Time
}

type UUIDGenerator interface {
	NewV4() uuid.UUID
}

type systemUUIDGenerator struct{}

func (systemUUIDGenerator) NewV4() uuid.UUID { return uuid.New() }

type ServiceConfig struct {
	OperationBeginner OperationBeginner
	Repository        Repository
	SourceResolver    appsource.Resolver
	SessionValidator  appsession.Validator
	PolicyGate        PolicyGate
	UserAccessPolicy  savedaccess.Policy
	Clock             Clock
	UUIDGenerator     UUIDGenerator
	MaxActiveSaves    uint64
	DisableExpansion  bool
}

type Service struct {
	operationBeginner OperationBeginner
	repository        Repository
	sourceResolver    appsource.Resolver
	sessionValidator  appsession.Validator
	policyGate        PolicyGate
	userAccessPolicy  savedaccess.Policy
	clock             Clock
	ids               UUIDGenerator
	maxActiveSaves    uint64
	disableExpansion  bool
}

type TargetMutationRequest struct {
	SubjectID         uuid.UUID
	OwnerUserID       uuid.UUID
	SessionGeneration uuid.UUID
	OperationID       uuid.UUID
	IdempotencyKey    string
	Target            domain.SavedTarget
	SourceSurface     domain.SourceSurface
	DisableExpansion  bool
}

func NewService(config ServiceConfig) (*Service, error) {
	if config.OperationBeginner == nil || config.Repository == nil ||
		config.SourceResolver == nil || config.SessionValidator == nil ||
		config.PolicyGate == nil || config.Clock == nil ||
		config.MaxActiveSaves > uint64(^uint64(0)>>1) {
		return nil, ErrInvalidServiceDependencies
	}
	ids := config.UUIDGenerator
	if ids == nil {
		ids = systemUUIDGenerator{}
	}
	maxActiveSaves := config.MaxActiveSaves
	if maxActiveSaves == 0 {
		maxActiveSaves = DefaultMaxActiveSaves
	}
	return &Service{
		operationBeginner: config.OperationBeginner,
		repository:        config.Repository,
		sourceResolver:    config.SourceResolver,
		sessionValidator:  config.SessionValidator,
		policyGate:        config.PolicyGate,
		userAccessPolicy:  config.UserAccessPolicy,
		clock:             config.Clock,
		ids:               ids,
		maxActiveSaves:    maxActiveSaves,
		disableExpansion:  config.DisableExpansion,
	}, nil
}

func (s *Service) Save(ctx context.Context, request TargetMutationRequest) (*domain.SavedOperation, error) {
	if sourceServiceFor(request.Target.EntityType()) == "" {
		return nil, domain.ErrTargetTypeUnsupported
	}
	begin, err := s.begin(ctx, request, domain.OperationKindSave)
	if err != nil || begin.Outcome != operation.BeginOutcomeNewlyAcceptedPending {
		return receiptOrError(begin.Receipt, err)
	}

	opCtx, cancel := operationContext(ctx, begin.Receipt.CommitDeadline())
	defer cancel()
	if s.disableExpansion || request.DisableExpansion {
		return s.reject(
			opCtx,
			begin.Receipt,
			domain.ErrTargetUnavailable,
			domain.RefreshScopeNone,
		)
	}
	if cause := savedaccess.ExpansionCause(
		opCtx,
		s.userAccessPolicy,
		request.OwnerUserID,
		request.Target,
	); cause != nil {
		return s.reject(opCtx, begin.Receipt, cause, domain.RefreshScopeSavedItems)
	}
	shellNow := s.clock.Now().UTC()
	prepared, err := s.repository.PrepareProjectionShell(opCtx, PrepareProjectionShellCommand{
		Identity:       mutationIdentity(begin.Receipt),
		Target:         request.Target,
		SourceService:  sourceServiceFor(request.Target.EntityType()),
		ShellExpiresAt: shellNow.Add(projectionShellLifetime),
		ServerNow:      shellNow,
	})
	if err != nil {
		return nil, err
	}
	if prepared == nil {
		return nil, domain.ErrDependencyUnavailable
	}
	if prepared.Status() != domain.OperationStatusPending {
		return prepared, nil
	}
	resolution, err := s.sourceResolver.Resolve(opCtx, request.Target)
	if err != nil {
		return s.reject(opCtx, begin.Receipt, persistableCause(err), domain.RefreshScopeSavedItems)
	}
	if !resolution.Eligible || resolution.Visibility != domain.VisibilityPublic || resolution.PublicProjection == nil {
		return s.reject(opCtx, begin.Receipt, domain.ErrTargetUnavailable, domain.RefreshScopeSavedItems)
	}

	now := s.clock.Now().UTC()
	projection, err := projectionSnapshot(resolution, now, begin.Receipt.CommitDeadline())
	if err != nil {
		return s.reject(opCtx, begin.Receipt, domain.ErrDependencyUnavailable, domain.RefreshScopeSavedItems)
	}
	if cause := s.validateFinalCommit(opCtx, begin.Receipt); cause != nil {
		return s.reject(opCtx, begin.Receipt, cause, domain.RefreshScopeSavedItems)
	}
	if cause := savedaccess.ExpansionCause(
		opCtx,
		s.userAccessPolicy,
		request.OwnerUserID,
		request.Target,
	); cause != nil {
		return s.reject(opCtx, begin.Receipt, cause, domain.RefreshScopeSavedItems)
	}

	return s.repository.Save(opCtx, SaveCommand{
		Identity:                  mutationIdentity(begin.Receipt),
		OwnerUserID:               request.OwnerUserID,
		Projection:                projection,
		SavedItemID:               s.ids.NewV4(),
		StateGeneration:           s.ids.NewV4(),
		RelationshipAttributionID: s.ids.NewV4(),
		ActivatedOutboxEventID:    s.ids.NewV4(),
		MaxActiveSaves:            s.maxActiveSaves,
		ServerNow:                 s.clock.Now().UTC(),
	})
}

func (s *Service) GlobalUnsave(ctx context.Context, request TargetMutationRequest) (*domain.SavedOperation, error) {
	begin, err := s.begin(ctx, request, domain.OperationKindUnsave)
	if err != nil || begin.Outcome != operation.BeginOutcomeNewlyAcceptedPending {
		return receiptOrError(begin.Receipt, err)
	}

	opCtx, cancel := operationContext(ctx, begin.Receipt.CommitDeadline())
	defer cancel()
	if cause := s.validateFinalCommit(opCtx, begin.Receipt); cause != nil {
		return s.reject(opCtx, begin.Receipt, cause, domain.RefreshScopeBoth)
	}
	return s.repository.GlobalUnsave(opCtx, GlobalUnsaveCommand{
		Identity:             mutationIdentity(begin.Receipt),
		OwnerUserID:          request.OwnerUserID,
		Target:               request.Target,
		RemovedOutboxEventID: s.ids.NewV4(),
		ServerNow:            s.clock.Now().UTC(),
	})
}

func (s *Service) begin(
	ctx context.Context,
	request TargetMutationRequest,
	kind domain.OperationKind,
) (operation.BeginResult, error) {
	if s == nil || s.operationBeginner == nil || s.repository == nil ||
		s.sourceResolver == nil || s.sessionValidator == nil || s.policyGate == nil ||
		s.clock == nil || s.ids == nil || ctx == nil || request.SubjectID == uuid.Nil ||
		request.OwnerUserID == uuid.Nil || request.SessionGeneration == uuid.Nil ||
		request.Target.IsZero() || !request.SourceSurface.IsValid() {
		return operation.BeginResult{}, ErrInvalidCommand
	}
	grant, err := s.policyGate.Guard(ctx)
	if err != nil {
		return operation.BeginResult{}, policyCause(err)
	}
	if grant.Revision == 0 {
		return operation.BeginResult{}, domain.ErrDependencyUnavailable
	}
	return s.operationBeginner.Begin(ctx, operation.BeginRequest{
		OperationID:            request.OperationID,
		SubjectID:              request.SubjectID,
		SessionGeneration:      request.SessionGeneration,
		Kind:                   kind,
		IdempotencyKey:         request.IdempotencyKey,
		Target:                 request.Target,
		SourceSurface:          request.SourceSurface,
		AcceptedPolicyRevision: grant.Revision,
	})
}

func (s *Service) validateFinalCommit(
	ctx context.Context,
	receipt *domain.SavedOperation,
) *domain.DomainError {
	if receipt == nil {
		return domain.ErrDependencyUnavailable
	}
	valid, err := s.sessionValidator.Validate(
		ctx,
		receipt.SubjectID().String(),
		receipt.SessionGeneration().String(),
	)
	if err != nil {
		return domain.ErrDependencyUnavailable
	}
	if !valid {
		return domain.ErrMutationStale
	}
	if err := s.policyGate.ValidateCommit(ctx, receipt.AcceptedPolicyRevision()); err != nil {
		return policyCause(err)
	}
	return nil
}

func (s *Service) reject(
	ctx context.Context,
	receipt *domain.SavedOperation,
	cause *domain.DomainError,
	refreshScope domain.RefreshScope,
) (*domain.SavedOperation, error) {
	if cause == nil || !IsPersistableRejection(cause) {
		cause = domain.ErrDependencyUnavailable
	}
	return s.repository.RejectPending(ctx, RejectPendingCommand{
		Identity:     mutationIdentity(receipt),
		Cause:        cause,
		RefreshScope: refreshScope,
		ServerNow:    s.clock.Now().UTC(),
	})
}

func mutationIdentity(receipt *domain.SavedOperation) MutationIdentity {
	if receipt == nil {
		return MutationIdentity{}
	}
	return MutationIdentity{
		SubjectID:             receipt.SubjectID(),
		SessionGeneration:     receipt.SessionGeneration(),
		OperationID:           receipt.OperationID(),
		Kind:                  receipt.Kind(),
		SemanticRequestHMAC:   receipt.SemanticRequestHMAC(),
		RequestHMACKeyVersion: receipt.RequestHMACKeyVersion(),
	}
}

func operationContext(parent context.Context, deadline time.Time) (context.Context, context.CancelFunc) {
	if parent == nil {
		parent = context.Background()
	}
	return context.WithDeadline(context.WithoutCancel(parent), deadline)
}

func receiptOrError(receipt *domain.SavedOperation, err error) (*domain.SavedOperation, error) {
	if err != nil {
		return nil, err
	}
	if receipt == nil {
		return nil, domain.ErrDependencyUnavailable
	}
	return receipt, nil
}

func persistableCause(err error) *domain.DomainError {
	var cause *domain.DomainError
	if errors.As(err, &cause) && IsPersistableRejection(cause) {
		return cause
	}
	return domain.ErrDependencyUnavailable
}

func policyCause(err error) *domain.DomainError {
	var cause *domain.DomainError
	if errors.As(err, &cause) &&
		(cause.Code == domain.ErrorCodePlatformPersonalDataLocked ||
			cause.Code == domain.ErrorCodeDependencyUnavailable) {
		return cause
	}
	return domain.ErrDependencyUnavailable
}
