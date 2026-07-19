package savedcollection

import (
	"context"
	"errors"
	"math"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/app/operation"
	"kz/inflap/backend/services/saved-service/internal/app/savedaccess"
	saveditemapp "kz/inflap/backend/services/saved-service/internal/app/saveditem"
	appsession "kz/inflap/backend/services/saved-service/internal/app/session"
	appsource "kz/inflap/backend/services/saved-service/internal/app/source"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

const collectionProjectionShellLifetime = time.Hour

var ErrInvalidMutationServiceDependencies = errors.New("invalid saved collection mutation service dependencies")

type CollectionOperationBeginner interface {
	BeginCollection(context.Context, operation.BeginCollectionRequest) (operation.BeginResult, error)
}

type MutationServiceConfig struct {
	OperationBeginner CollectionOperationBeginner
	Repository        Repository
	SourceResolver    appsource.Resolver
	SessionValidator  appsession.Validator
	PolicyGate        saveditemapp.PolicyGate
	UserAccessPolicy  savedaccess.Policy
	Clock             saveditemapp.Clock
	Limits            Limits
	DisableExpansion  bool
}

type MutationService struct {
	operationBeginner CollectionOperationBeginner
	repository        Repository
	sourceResolver    appsource.Resolver
	sessionValidator  appsession.Validator
	policyGate        saveditemapp.PolicyGate
	userAccessPolicy  savedaccess.Policy
	clock             saveditemapp.Clock
	limits            Limits
	disableExpansion  bool
}

type ClientMutationIdentity struct {
	SubjectID         uuid.UUID
	OwnerUserID       uuid.UUID
	SessionGeneration uuid.UUID
	OperationID       uuid.UUID
	IdempotencyKey    string
	SourceSurface     domain.SourceSurface
}

type CreateRequest struct {
	Identity         ClientMutationIdentity
	ClientCreationID uuid.UUID
	Title            string
	DisableExpansion bool
}

type RenameRequest struct {
	Identity                ClientMutationIdentity
	CollectionID            uuid.UUID
	ExpectedMetadataVersion uint64
	Title                   string
}

type DeleteRequest struct {
	Identity                 ClientMutationIdentity
	CollectionID             uuid.UUID
	ExpectedMetadataVersion  uint64
	ExpectedLifecycleVersion uint64
}

type ReplaceDesiredSetRequest struct {
	Identity         ClientMutationIdentity
	Desired          DesiredSet
	DisableExpansion bool
}

func NewMutationService(config MutationServiceConfig) (*MutationService, error) {
	limits := config.Limits.WithDefaults()
	if config.OperationBeginner == nil || config.Repository == nil ||
		config.SourceResolver == nil || config.SessionValidator == nil ||
		config.PolicyGate == nil || config.Clock == nil || limits.Validate() != nil {
		return nil, ErrInvalidMutationServiceDependencies
	}
	return &MutationService{
		operationBeginner: config.OperationBeginner,
		repository:        config.Repository,
		sourceResolver:    config.SourceResolver,
		sessionValidator:  config.SessionValidator,
		policyGate:        config.PolicyGate,
		userAccessPolicy:  config.UserAccessPolicy,
		clock:             config.Clock,
		limits:            limits,
		disableExpansion:  config.DisableExpansion,
	}, nil
}

func (service *MutationService) Create(
	ctx context.Context,
	request CreateRequest,
) (*domain.SavedOperation, error) {
	if err := service.validateIdentity(ctx, request.Identity); err != nil ||
		!isUUIDv4(request.ClientCreationID) {
		return nil, ErrInvalidCommand
	}
	title, err := NormalizeStoredTitle(request.Title)
	if err != nil {
		return nil, err
	}
	begin, err := service.begin(ctx, request.Identity, operation.CreateCollectionSemanticRequest{
		ClientCreationID: request.ClientCreationID,
		Title:            title.Display,
	})
	if err != nil || begin.Outcome != operation.BeginOutcomeNewlyAcceptedPending {
		return collectionReceiptOrError(begin.Receipt, err)
	}
	opCtx, cancel := collectionOperationContext(ctx, begin.Receipt.CommitDeadline())
	defer cancel()
	if service.disableExpansion || request.DisableExpansion {
		return service.reject(
			opCtx,
			begin.Receipt,
			domain.ErrTargetUnavailable,
			domain.RefreshScopeNone,
		)
	}
	if cause := service.validateFinalCommit(opCtx, begin.Receipt); cause != nil {
		return service.reject(opCtx, begin.Receipt, cause, domain.RefreshScopeCollections)
	}
	return service.repository.Create(opCtx, CreateCommand{
		Identity:         collectionMutationIdentity(begin.Receipt),
		OwnerUserID:      request.Identity.OwnerUserID,
		ClientCreationID: request.ClientCreationID,
		Title:            title.Display,
		ServerNow:        service.clock.Now().UTC(),
	})
}

func (service *MutationService) Rename(
	ctx context.Context,
	request RenameRequest,
) (*domain.SavedOperation, error) {
	if err := service.validateIdentity(ctx, request.Identity); err != nil ||
		request.CollectionID == uuid.Nil || request.ExpectedMetadataVersion == 0 ||
		request.ExpectedMetadataVersion > math.MaxInt64 {
		return nil, ErrInvalidCommand
	}
	title, err := NormalizeStoredTitle(request.Title)
	if err != nil {
		return nil, err
	}
	begin, err := service.begin(ctx, request.Identity, operation.RenameCollectionSemanticRequest{
		CollectionID:            request.CollectionID,
		ExpectedMetadataVersion: request.ExpectedMetadataVersion,
		Title:                   title.Display,
	})
	if err != nil || begin.Outcome != operation.BeginOutcomeNewlyAcceptedPending {
		return collectionReceiptOrError(begin.Receipt, err)
	}
	opCtx, cancel := collectionOperationContext(ctx, begin.Receipt.CommitDeadline())
	defer cancel()
	if cause := service.validateFinalCommit(opCtx, begin.Receipt); cause != nil {
		return service.reject(opCtx, begin.Receipt, cause, domain.RefreshScopeCollections)
	}
	return service.repository.Rename(opCtx, RenameCommand{
		Identity:                collectionMutationIdentity(begin.Receipt),
		OwnerUserID:             request.Identity.OwnerUserID,
		CollectionID:            request.CollectionID,
		ExpectedMetadataVersion: request.ExpectedMetadataVersion,
		Title:                   title.Display,
		ServerNow:               service.clock.Now().UTC(),
	})
}

func (service *MutationService) Delete(
	ctx context.Context,
	request DeleteRequest,
) (*domain.SavedOperation, error) {
	if err := service.validateIdentity(ctx, request.Identity); err != nil ||
		request.CollectionID == uuid.Nil || request.ExpectedMetadataVersion == 0 ||
		request.ExpectedMetadataVersion > math.MaxInt64 || request.ExpectedLifecycleVersion == 0 ||
		request.ExpectedLifecycleVersion > math.MaxInt64 {
		return nil, ErrInvalidCommand
	}
	begin, err := service.begin(ctx, request.Identity, operation.DeleteCollectionSemanticRequest{
		CollectionID:             request.CollectionID,
		ExpectedMetadataVersion:  request.ExpectedMetadataVersion,
		ExpectedLifecycleVersion: request.ExpectedLifecycleVersion,
	})
	if err != nil || begin.Outcome != operation.BeginOutcomeNewlyAcceptedPending {
		return collectionReceiptOrError(begin.Receipt, err)
	}
	opCtx, cancel := collectionOperationContext(ctx, begin.Receipt.CommitDeadline())
	defer cancel()
	if cause := service.validateFinalCommit(opCtx, begin.Receipt); cause != nil {
		return service.reject(opCtx, begin.Receipt, cause, domain.RefreshScopeBoth)
	}
	return service.repository.Delete(opCtx, DeleteCommand{
		Identity:                 collectionMutationIdentity(begin.Receipt),
		OwnerUserID:              request.Identity.OwnerUserID,
		CollectionID:             request.CollectionID,
		ExpectedMetadataVersion:  request.ExpectedMetadataVersion,
		ExpectedLifecycleVersion: request.ExpectedLifecycleVersion,
		ServerNow:                service.clock.Now().UTC(),
	})
}

func (service *MutationService) ReplaceDesiredSet(
	ctx context.Context,
	request ReplaceDesiredSetRequest,
) (*domain.SavedOperation, error) {
	if err := service.validateIdentity(ctx, request.Identity); err != nil {
		return nil, err
	}
	desired, err := service.normalizeDesiredSet(request.Desired)
	if err != nil {
		return nil, err
	}
	begin, err := service.begin(ctx, request.Identity, desiredSemanticRequest(desired))
	if err != nil || begin.Outcome != operation.BeginOutcomeNewlyAcceptedPending {
		return collectionReceiptOrError(begin.Receipt, err)
	}
	opCtx, cancel := collectionOperationContext(ctx, begin.Receipt.CommitDeadline())
	defer cancel()

	analysis, err := service.repository.AnalyzeDesiredSet(opCtx, AnalyzeDesiredSetQuery{
		OwnerUserID: request.Identity.OwnerUserID,
		Desired:     desired,
		ReadAt:      service.clock.Now().UTC(),
	})
	if err != nil {
		return service.reject(
			opCtx, begin.Receipt, collectionPersistableCause(err), domain.RefreshScopeBoth,
		)
	}
	if !validDesiredSetAnalysis(analysis, service.limits) {
		return service.reject(
			opCtx, begin.Receipt, domain.ErrDependencyUnavailable, domain.RefreshScopeBoth,
		)
	}
	if (service.disableExpansion || request.DisableExpansion) &&
		analysis.Change.ExpandsCollections() {
		return service.reject(
			opCtx,
			begin.Receipt,
			domain.ErrTargetUnavailable,
			domain.RefreshScopeBoth,
		)
	}
	if analysis.Change.ExpandsCollections() {
		if cause := savedaccess.ExpansionCause(
			opCtx,
			service.userAccessPolicy,
			request.Identity.OwnerUserID,
			desired.Target,
		); cause != nil {
			return service.reject(opCtx, begin.Receipt, cause, domain.RefreshScopeBoth)
		}
	}

	var eligibility *PublicEligibility
	if analysis.RequiresPublicEligibility() {
		sourceService := saveditemapp.SourceServiceFor(desired.Target.EntityType())
		if sourceService == "" {
			return service.reject(
				opCtx, begin.Receipt, domain.ErrTargetTypeUnsupported, domain.RefreshScopeBoth,
			)
		}
		now := service.clock.Now().UTC()
		prepared, prepareErr := service.repository.PrepareProjectionShell(opCtx, PrepareProjectionShellCommand{
			Identity:       collectionMutationIdentity(begin.Receipt),
			Target:         desired.Target,
			SourceService:  sourceService,
			ShellExpiresAt: now.Add(collectionProjectionShellLifetime),
			ServerNow:      now,
		})
		if prepareErr != nil {
			return service.reject(
				opCtx, begin.Receipt, collectionPersistableCause(prepareErr), domain.RefreshScopeBoth,
			)
		}
		if prepared == nil {
			return service.reject(
				opCtx, begin.Receipt, domain.ErrDependencyUnavailable, domain.RefreshScopeBoth,
			)
		}
		if prepared.Status() != domain.OperationStatusPending {
			return prepared, nil
		}
		resolution, resolveErr := service.sourceResolver.Resolve(opCtx, desired.Target)
		if resolveErr != nil {
			return service.reject(
				opCtx, begin.Receipt, collectionPersistableCause(resolveErr), domain.RefreshScopeBoth,
			)
		}
		if !resolution.Eligible || resolution.Visibility != domain.VisibilityPublic ||
			resolution.PublicProjection == nil {
			return service.reject(
				opCtx, begin.Receipt, domain.ErrTargetUnavailable, domain.RefreshScopeBoth,
			)
		}
		now = service.clock.Now().UTC()
		projection, projectionErr := saveditemapp.BuildPublicProjectionSnapshot(
			resolution, now, begin.Receipt.CommitDeadline(),
		)
		if projectionErr != nil {
			return service.reject(
				opCtx, begin.Receipt, domain.ErrDependencyUnavailable, domain.RefreshScopeBoth,
			)
		}
		eligibility = &PublicEligibility{Projection: projection}
	}

	if cause := service.validateFinalCommit(opCtx, begin.Receipt); cause != nil {
		return service.reject(opCtx, begin.Receipt, cause, domain.RefreshScopeBoth)
	}
	if analysis.Change.ExpandsCollections() {
		if cause := savedaccess.ExpansionCause(
			opCtx,
			service.userAccessPolicy,
			request.Identity.OwnerUserID,
			desired.Target,
		); cause != nil {
			return service.reject(opCtx, begin.Receipt, cause, domain.RefreshScopeBoth)
		}
	}
	receipt, err := service.repository.ReplaceDesiredSet(opCtx, ReplaceDesiredSetCommand{
		Identity:    collectionMutationIdentity(begin.Receipt),
		OwnerUserID: request.Identity.OwnerUserID,
		Desired:     desired,
		Eligibility: eligibility,
		ServerNow:   service.clock.Now().UTC(),
	})
	if errors.Is(err, ErrPublicEligibilityRequired) {
		return service.reject(opCtx, begin.Receipt, domain.ErrMutationStale, domain.RefreshScopeBoth)
	}
	if err != nil {
		return service.reject(
			opCtx, begin.Receipt, collectionPersistableCause(err), domain.RefreshScopeBoth,
		)
	}
	if receipt == nil {
		return service.reject(
			opCtx, begin.Receipt, domain.ErrDependencyUnavailable, domain.RefreshScopeBoth,
		)
	}
	return receipt, nil
}

func (service *MutationService) begin(
	ctx context.Context,
	identity ClientMutationIdentity,
	semantic operation.CollectionSemanticRequest,
) (operation.BeginResult, error) {
	grant, err := service.policyGate.Guard(ctx)
	if err != nil {
		return operation.BeginResult{}, collectionPolicyCause(err)
	}
	if grant.Revision == 0 {
		return operation.BeginResult{}, domain.ErrDependencyUnavailable
	}
	return service.operationBeginner.BeginCollection(ctx, operation.BeginCollectionRequest{
		OperationID:            identity.OperationID,
		SubjectID:              identity.SubjectID,
		SessionGeneration:      identity.SessionGeneration,
		IdempotencyKey:         identity.IdempotencyKey,
		SemanticRequest:        semantic,
		SourceSurface:          identity.SourceSurface,
		AcceptedPolicyRevision: grant.Revision,
	})
}

func (service *MutationService) validateIdentity(
	ctx context.Context,
	identity ClientMutationIdentity,
) error {
	if service == nil || service.operationBeginner == nil || service.repository == nil ||
		service.sourceResolver == nil || service.sessionValidator == nil || service.policyGate == nil ||
		service.clock == nil || ctx == nil || identity.SubjectID == uuid.Nil ||
		identity.OwnerUserID == uuid.Nil || identity.SessionGeneration == uuid.Nil ||
		!isUUIDv4(identity.OperationID) || identity.IdempotencyKey == "" ||
		identity.IdempotencyKey != strings.TrimSpace(identity.IdempotencyKey) ||
		!identity.SourceSurface.IsValid() {
		return ErrInvalidCommand
	}
	return ctx.Err()
}

func (service *MutationService) validateFinalCommit(
	ctx context.Context,
	receipt *domain.SavedOperation,
) *domain.DomainError {
	if receipt == nil {
		return domain.ErrDependencyUnavailable
	}
	valid, err := service.sessionValidator.Validate(
		ctx, receipt.SubjectID().String(), receipt.SessionGeneration().String(),
	)
	if err != nil {
		return domain.ErrDependencyUnavailable
	}
	if !valid {
		return domain.ErrMutationStale
	}
	if err := service.policyGate.ValidateCommit(ctx, receipt.AcceptedPolicyRevision()); err != nil {
		return collectionPolicyCause(err)
	}
	return nil
}

func (service *MutationService) reject(
	ctx context.Context,
	receipt *domain.SavedOperation,
	cause *domain.DomainError,
	refreshScope domain.RefreshScope,
) (*domain.SavedOperation, error) {
	if cause == nil || !saveditemapp.IsPersistableRejection(cause) {
		cause = domain.ErrDependencyUnavailable
	}
	return service.repository.RejectPending(ctx, RejectPendingCommand{
		Identity:     collectionMutationIdentity(receipt),
		Cause:        cause,
		RefreshScope: refreshScope,
		ServerNow:    service.clock.Now().UTC(),
	})
}

func (service *MutationService) normalizeDesiredSet(desired DesiredSet) (DesiredSet, error) {
	normalized := desired
	normalized.DesiredCollectionIDs = append([]uuid.UUID(nil), desired.DesiredCollectionIDs...)
	if desired.NewCollection != nil {
		title, err := NormalizeStoredTitle(desired.NewCollection.Title)
		if err != nil {
			return DesiredSet{}, err
		}
		normalized.NewCollection = &NewCollection{
			ClientCreationID: desired.NewCollection.ClientCreationID,
			Title:            title.Display,
		}
	}
	if err := normalized.Validate(service.limits.MaxDesiredCollectionIDs); err != nil {
		return DesiredSet{}, err
	}
	return normalized, nil
}

func desiredSemanticRequest(desired DesiredSet) operation.SetTargetCollectionsSemanticRequest {
	semantic := operation.SetTargetCollectionsSemanticRequest{
		Target: desired.Target,
		ExpectedRelationship: operation.ExpectedRelationship{
			State:      operation.ExpectedRelationshipState(desired.ExpectedRelationship.State),
			Generation: desired.ExpectedRelationship.Generation,
			Version:    desired.ExpectedRelationship.Version,
		},
		ExpectedDependentMembershipVersion: desired.ExpectedDependentMembershipVersion,
		DesiredCollectionIDs:               append([]uuid.UUID(nil), desired.DesiredCollectionIDs...),
	}
	if desired.NewCollection != nil {
		semantic.NewCollection = &operation.NewCollectionSemanticRequest{
			ClientCreationID: desired.NewCollection.ClientCreationID,
			Title:            desired.NewCollection.Title,
		}
	}
	return semantic
}

func validDesiredSetAnalysis(analysis DesiredSetAnalysis, limits Limits) bool {
	if analysis.Change != DesiredSetNoOp && analysis.Change != DesiredSetReduction &&
		analysis.Change != DesiredSetExpansion && analysis.Change != DesiredSetMixed {
		return false
	}
	if len(analysis.CurrentCollectionIDs) > limits.MaxDesiredCollectionIDs ||
		len(analysis.DesiredExistingIDs) > limits.MaxDesiredCollectionIDs ||
		analysis.DependentMembershipVersion > math.MaxInt64 {
		return false
	}
	switch analysis.Relationship.State {
	case RelationshipSnapshotAbsent:
		return analysis.Relationship.Generation == uuid.Nil && analysis.Relationship.Version == 0 &&
			analysis.DependentMembershipVersion == 0 && len(analysis.CurrentCollectionIDs) == 0
	case RelationshipSnapshotActive, RelationshipSnapshotRemoved:
		return analysis.Relationship.Generation != uuid.Nil && analysis.Relationship.Version > 0 &&
			analysis.Relationship.Version <= math.MaxInt64
	default:
		return false
	}
}

func collectionMutationIdentity(receipt *domain.SavedOperation) MutationIdentity {
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

func collectionOperationContext(parent context.Context, deadline time.Time) (context.Context, context.CancelFunc) {
	if parent == nil {
		parent = context.Background()
	}
	return context.WithDeadline(context.WithoutCancel(parent), deadline)
}

func collectionReceiptOrError(
	receipt *domain.SavedOperation,
	err error,
) (*domain.SavedOperation, error) {
	if err != nil {
		return nil, err
	}
	if receipt == nil {
		return nil, domain.ErrDependencyUnavailable
	}
	return receipt, nil
}

func collectionPersistableCause(err error) *domain.DomainError {
	var cause *domain.DomainError
	if errors.As(err, &cause) && saveditemapp.IsPersistableRejection(cause) {
		return cause
	}
	return domain.ErrDependencyUnavailable
}

func collectionPolicyCause(err error) *domain.DomainError {
	var cause *domain.DomainError
	if errors.As(err, &cause) &&
		(cause.Code == domain.ErrorCodePlatformPersonalDataLocked ||
			cause.Code == domain.ErrorCodeDependencyUnavailable) {
		return cause
	}
	return domain.ErrDependencyUnavailable
}
