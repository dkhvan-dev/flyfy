package savedcollection

import (
	"context"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/app/operation"
	saveditemapp "kz/inflap/backend/services/saved-service/internal/app/saveditem"
	appsource "kz/inflap/backend/services/saved-service/internal/app/source"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestMutationServiceCreateNormalizesTitleBeforeOperationHMAC(t *testing.T) {
	now := time.Now().UTC()
	identity := collectionClientIdentity()
	receipt := collectionPendingReceipt(t, identity, domain.OperationKindCreateCollection, now)
	beginner := &stubCollectionOperationBeginner{result: operation.BeginResult{
		Receipt: receipt, Outcome: operation.BeginOutcomeNewlyAcceptedPending,
	}}
	repository := &stubCollectionMutationRepository{createResult: receipt}
	service := newCollectionMutationServiceForTest(t, beginner, repository, &stubCollectionSource{}, now)
	clientCreationID := uuid.New()

	result, err := service.Create(context.Background(), CreateRequest{
		Identity: identity, ClientCreationID: clientCreationID, Title: "  Cafe\u0301  ",
	})
	if err != nil || result != receipt {
		t.Fatalf("Create() = (%p, %v)", result, err)
	}
	semantic, ok := beginner.semantic.(operation.CreateCollectionSemanticRequest)
	if !ok || semantic.Title != "Café" || repository.createCommand.Title != "Café" ||
		semantic.ClientCreationID != clientCreationID || repository.createCalls != 1 {
		t.Fatalf("semantic/command = (%+v, %+v)", beginner.semantic, repository.createCommand)
	}
	if service.sessionValidator.(*stubCollectionSession).calls != 1 ||
		service.policyGate.(*stubCollectionPolicy).validateCalls != 1 {
		t.Fatal("final session/policy fencing was not executed")
	}
}

func TestMutationServiceDisabledCollectionsRejectsCreate(t *testing.T) {
	now := time.Now().UTC()
	identity := collectionClientIdentity()
	receipt := collectionPendingReceipt(t, identity, domain.OperationKindCreateCollection, now)
	repository := &stubCollectionMutationRepository{rejectResult: receipt}
	service := newCollectionMutationServiceForTest(
		t,
		&stubCollectionOperationBeginner{result: operation.BeginResult{
			Receipt: receipt, Outcome: operation.BeginOutcomeNewlyAcceptedPending,
		}},
		repository,
		&stubCollectionSource{},
		now,
		true,
	)

	result, err := service.Create(context.Background(), CreateRequest{
		Identity: identity, ClientCreationID: uuid.New(), Title: "Trip",
	})
	if err != nil || result != receipt {
		t.Fatalf("Create() = (%p, %v)", result, err)
	}
	if repository.createCalls != 0 || repository.rejectCalls != 1 ||
		repository.rejectCommand.Cause.Code != domain.ErrorCodeTargetUnavailable ||
		repository.rejectCommand.RefreshScope != domain.RefreshScopeNone {
		t.Fatalf("repository = %#v", repository)
	}
}

func TestMutationServiceRequestRolloutRejectsCreate(t *testing.T) {
	now := time.Now().UTC()
	identity := collectionClientIdentity()
	receipt := collectionPendingReceipt(t, identity, domain.OperationKindCreateCollection, now)
	repository := &stubCollectionMutationRepository{rejectResult: receipt}
	service := newCollectionMutationServiceForTest(
		t,
		&stubCollectionOperationBeginner{result: operation.BeginResult{
			Receipt: receipt, Outcome: operation.BeginOutcomeNewlyAcceptedPending,
		}},
		repository,
		&stubCollectionSource{},
		now,
	)

	result, err := service.Create(context.Background(), CreateRequest{
		Identity: identity, ClientCreationID: uuid.New(), Title: "Trip", DisableExpansion: true,
	})
	if err != nil || result != receipt {
		t.Fatalf("Create() = (%p, %v)", result, err)
	}
	if repository.createCalls != 0 || repository.rejectCalls != 1 {
		t.Fatalf("create/reject calls = %d/%d", repository.createCalls, repository.rejectCalls)
	}
}

func TestMutationServiceDesiredSetReductionSkipsSourceResolution(t *testing.T) {
	now := time.Now().UTC()
	identity := collectionClientIdentity()
	receipt := collectionPendingReceipt(t, identity, domain.OperationKindSetTargetCollections, now)
	beginner := &stubCollectionOperationBeginner{result: operation.BeginResult{
		Receipt: receipt, Outcome: operation.BeginOutcomeNewlyAcceptedPending,
	}}
	target := collectionTarget(t, domain.EntityTypeAttraction)
	generation := uuid.New()
	repository := &stubCollectionMutationRepository{
		analysis: DesiredSetAnalysis{
			Change:               DesiredSetReduction,
			CurrentCollectionIDs: []uuid.UUID{uuid.New()},
			Relationship: RelationshipSnapshot{
				State: RelationshipSnapshotActive, Generation: generation, Version: 4,
			},
			DependentMembershipVersion: 3,
		},
		replaceResult: receipt,
	}
	source := &stubCollectionSource{}
	service := newCollectionMutationServiceForTest(t, beginner, repository, source, now, true)
	accessPolicy := &stubCollectionUserAccessPolicy{err: context.DeadlineExceeded}
	service.userAccessPolicy = accessPolicy

	result, err := service.ReplaceDesiredSet(context.Background(), ReplaceDesiredSetRequest{
		Identity: identity,
		Desired: DesiredSet{
			Target: target,
			ExpectedRelationship: ExpectedRelationship{
				State: ExpectedRelationshipActive, Generation: generation, Version: 4,
			},
			ExpectedDependentMembershipVersion: 3,
			DesiredCollectionIDs:               []uuid.UUID{},
		},
	})
	if err != nil || result != receipt {
		t.Fatalf("ReplaceDesiredSet(reduction) = (%p, %v)", result, err)
	}
	if accessPolicy.calls != 0 || source.calls != 0 || repository.prepareCalls != 0 || repository.replaceCalls != 1 ||
		repository.replaceCommand.Eligibility != nil {
		t.Fatalf("reduction access/source/prepare/replace = %d/%d/%d/%d command=%+v",
			accessPolicy.calls, source.calls, repository.prepareCalls, repository.replaceCalls, repository.replaceCommand)
	}
}

func TestMutationServiceActiveDesiredSetExpansionSkipsSourceResolution(t *testing.T) {
	now := time.Now().UTC()
	identity := collectionClientIdentity()
	receipt := collectionPendingReceipt(t, identity, domain.OperationKindSetTargetCollections, now)
	beginner := &stubCollectionOperationBeginner{result: operation.BeginResult{
		Receipt: receipt, Outcome: operation.BeginOutcomeNewlyAcceptedPending,
	}}
	target := collectionTarget(t, domain.EntityTypeActivity)
	generation := uuid.New()
	desiredID := uuid.New()
	repository := &stubCollectionMutationRepository{
		analysis: DesiredSetAnalysis{
			Change:             DesiredSetExpansion,
			DesiredExistingIDs: []uuid.UUID{desiredID},
			Relationship: RelationshipSnapshot{
				State: RelationshipSnapshotActive, Generation: generation, Version: 4,
			},
		},
		replaceResult: receipt,
	}
	source := &stubCollectionSource{}
	service := newCollectionMutationServiceForTest(t, beginner, repository, source, now)

	result, err := service.ReplaceDesiredSet(context.Background(), ReplaceDesiredSetRequest{
		Identity: identity,
		Desired: DesiredSet{
			Target: target,
			ExpectedRelationship: ExpectedRelationship{
				State: ExpectedRelationshipActive, Generation: generation, Version: 4,
			},
			DesiredCollectionIDs: []uuid.UUID{desiredID},
		},
	})
	if err != nil || result != receipt {
		t.Fatalf("ReplaceDesiredSet(active expansion) = (%p, %v)", result, err)
	}
	if source.calls != 0 || repository.prepareCalls != 0 || repository.replaceCalls != 1 ||
		repository.replaceCommand.Eligibility != nil {
		t.Fatalf(
			"active expansion source/prepare/replace = %d/%d/%d command=%+v",
			source.calls,
			repository.prepareCalls,
			repository.replaceCalls,
			repository.replaceCommand,
		)
	}
}

func TestMutationServiceDesiredSetRepositoryFailureRejectsAcceptedOperation(t *testing.T) {
	now := time.Now().UTC()
	identity := collectionClientIdentity()
	receipt := collectionPendingReceipt(t, identity, domain.OperationKindSetTargetCollections, now)
	target := collectionTarget(t, domain.EntityTypeActivity)
	generation := uuid.New()
	repository := &stubCollectionMutationRepository{
		analysis: DesiredSetAnalysis{
			Change:             DesiredSetExpansion,
			DesiredExistingIDs: []uuid.UUID{uuid.New()},
			Relationship: RelationshipSnapshot{
				State: RelationshipSnapshotActive, Generation: generation, Version: 4,
			},
		},
		replaceErr:   ErrRepositoryUnavailable,
		rejectResult: receipt,
	}
	service := newCollectionMutationServiceForTest(
		t,
		&stubCollectionOperationBeginner{result: operation.BeginResult{
			Receipt: receipt, Outcome: operation.BeginOutcomeNewlyAcceptedPending,
		}},
		repository,
		&stubCollectionSource{},
		now,
	)

	result, err := service.ReplaceDesiredSet(context.Background(), ReplaceDesiredSetRequest{
		Identity: identity,
		Desired: DesiredSet{
			Target: target,
			ExpectedRelationship: ExpectedRelationship{
				State: ExpectedRelationshipActive, Generation: generation, Version: 4,
			},
			DesiredCollectionIDs: repository.analysis.DesiredExistingIDs,
		},
	})
	if err != nil || result != receipt {
		t.Fatalf("ReplaceDesiredSet(repository failure) = (%p, %v)", result, err)
	}
	if repository.replaceCalls != 1 || repository.rejectCalls != 1 ||
		repository.rejectCommand.Cause.Code != domain.ErrorCodeDependencyUnavailable ||
		repository.rejectCommand.RefreshScope != domain.RefreshScopeBoth {
		t.Fatalf("replace/reject = %d/%d, command=%+v",
			repository.replaceCalls, repository.rejectCalls, repository.rejectCommand)
	}
}

func TestMutationServiceProjectionPreparationFailureRejectsAcceptedOperation(t *testing.T) {
	now := time.Now().UTC()
	identity := collectionClientIdentity()
	receipt := collectionPendingReceipt(t, identity, domain.OperationKindSetTargetCollections, now)
	target := collectionTarget(t, domain.EntityTypeAttraction)
	repository := &stubCollectionMutationRepository{
		analysis: DesiredSetAnalysis{
			Change:             DesiredSetExpansion,
			DesiredExistingIDs: []uuid.UUID{uuid.New()},
			Relationship:       RelationshipSnapshot{State: RelationshipSnapshotAbsent},
		},
		prepareErr:   ErrRepositoryUnavailable,
		rejectResult: receipt,
	}
	service := newCollectionMutationServiceForTest(
		t,
		&stubCollectionOperationBeginner{result: operation.BeginResult{
			Receipt: receipt, Outcome: operation.BeginOutcomeNewlyAcceptedPending,
		}},
		repository,
		&stubCollectionSource{},
		now,
	)

	result, err := service.ReplaceDesiredSet(context.Background(), ReplaceDesiredSetRequest{
		Identity: identity,
		Desired: DesiredSet{
			Target:               target,
			ExpectedRelationship: ExpectedRelationship{State: ExpectedRelationshipAbsent},
			DesiredCollectionIDs: repository.analysis.DesiredExistingIDs,
		},
	})
	if err != nil || result != receipt {
		t.Fatalf("ReplaceDesiredSet(prepare failure) = (%p, %v)", result, err)
	}
	if repository.prepareCalls != 1 || repository.replaceCalls != 0 ||
		repository.rejectCalls != 1 ||
		repository.rejectCommand.Cause.Code != domain.ErrorCodeDependencyUnavailable {
		t.Fatalf("prepare/replace/reject = %d/%d/%d, command=%+v",
			repository.prepareCalls, repository.replaceCalls, repository.rejectCalls,
			repository.rejectCommand)
	}
}

func TestMutationServiceRejectsBlockedUserCollectionExpansion(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC()
	identity := collectionClientIdentity()
	receipt := collectionPendingReceipt(t, identity, domain.OperationKindSetTargetCollections, now)
	blockedUserID := uuid.New()
	target, err := domain.NewSavedTarget(domain.EntityTypeUser, blockedUserID.String())
	if err != nil {
		t.Fatal(err)
	}
	generation := uuid.New()
	desiredID := uuid.New()
	repository := &stubCollectionMutationRepository{
		analysis: DesiredSetAnalysis{
			Change:             DesiredSetExpansion,
			DesiredExistingIDs: []uuid.UUID{desiredID},
			Relationship: RelationshipSnapshot{
				State: RelationshipSnapshotActive, Generation: generation, Version: 4,
			},
		},
		rejectResult: receipt,
	}
	service := newCollectionMutationServiceForTest(
		t,
		&stubCollectionOperationBeginner{result: operation.BeginResult{
			Receipt: receipt,
			Outcome: operation.BeginOutcomeNewlyAcceptedPending,
		}},
		repository,
		&stubCollectionSource{},
		now,
	)
	accessPolicy := &stubCollectionUserAccessPolicy{
		denied: map[uuid.UUID]struct{}{blockedUserID: {}},
	}
	service.userAccessPolicy = accessPolicy

	result, err := service.ReplaceDesiredSet(context.Background(), ReplaceDesiredSetRequest{
		Identity: identity,
		Desired: DesiredSet{
			Target: target,
			ExpectedRelationship: ExpectedRelationship{
				State: ExpectedRelationshipActive, Generation: generation, Version: 4,
			},
			DesiredCollectionIDs: []uuid.UUID{desiredID},
		},
	})
	if err != nil || result != receipt {
		t.Fatalf("ReplaceDesiredSet(blocked USER) = (%p, %v)", result, err)
	}
	if accessPolicy.calls != 1 || repository.prepareCalls != 0 ||
		repository.replaceCalls != 0 || repository.rejectCalls != 1 ||
		repository.rejectCommand.Cause.Code != domain.ErrorCodeTargetUnavailable {
		t.Fatalf("access/prepare/replace/reject = %d/%d/%d/%d, rejection=%+v",
			accessPolicy.calls, repository.prepareCalls, repository.replaceCalls,
			repository.rejectCalls, repository.rejectCommand)
	}
}

func TestMutationServiceDisabledExpansionRejectsBeforeSourceResolution(t *testing.T) {
	now := time.Now().UTC()
	identity := collectionClientIdentity()
	receipt := collectionPendingReceipt(t, identity, domain.OperationKindSetTargetCollections, now)
	beginner := &stubCollectionOperationBeginner{result: operation.BeginResult{
		Receipt: receipt, Outcome: operation.BeginOutcomeNewlyAcceptedPending,
	}}
	target := collectionTarget(t, domain.EntityTypeAttraction)
	repository := &stubCollectionMutationRepository{
		analysis: DesiredSetAnalysis{
			Change:             DesiredSetExpansion,
			DesiredExistingIDs: []uuid.UUID{uuid.New()},
			Relationship:       RelationshipSnapshot{State: RelationshipSnapshotAbsent},
		},
		rejectResult: receipt,
	}
	source := &stubCollectionSource{}
	service := newCollectionMutationServiceForTest(t, beginner, repository, source, now, true)

	result, err := service.ReplaceDesiredSet(context.Background(), ReplaceDesiredSetRequest{
		Identity: identity,
		Desired: DesiredSet{
			Target:               target,
			ExpectedRelationship: ExpectedRelationship{State: ExpectedRelationshipAbsent},
			DesiredCollectionIDs: repository.analysis.DesiredExistingIDs,
		},
	})
	if err != nil || result != receipt {
		t.Fatalf("ReplaceDesiredSet() = (%p, %v)", result, err)
	}
	if source.calls != 0 || repository.prepareCalls != 0 || repository.replaceCalls != 0 ||
		repository.rejectCalls != 1 ||
		repository.rejectCommand.Cause.Code != domain.ErrorCodeTargetUnavailable {
		t.Fatalf("source/prepare/replace/reject = %d/%d/%d/%d",
			source.calls, repository.prepareCalls, repository.replaceCalls, repository.rejectCalls)
	}
}

func TestMutationServiceRequestRolloutStillAllowsDesiredSetReduction(t *testing.T) {
	now := time.Now().UTC()
	identity := collectionClientIdentity()
	receipt := collectionPendingReceipt(t, identity, domain.OperationKindSetTargetCollections, now)
	target := collectionTarget(t, domain.EntityTypeAttraction)
	generation := uuid.New()
	repository := &stubCollectionMutationRepository{
		analysis: DesiredSetAnalysis{
			Change: DesiredSetReduction,
			Relationship: RelationshipSnapshot{
				State: RelationshipSnapshotActive, Generation: generation, Version: 4,
			},
			DependentMembershipVersion: 3,
		},
		replaceResult: receipt,
	}
	service := newCollectionMutationServiceForTest(
		t,
		&stubCollectionOperationBeginner{result: operation.BeginResult{
			Receipt: receipt, Outcome: operation.BeginOutcomeNewlyAcceptedPending,
		}},
		repository,
		&stubCollectionSource{},
		now,
	)

	result, err := service.ReplaceDesiredSet(context.Background(), ReplaceDesiredSetRequest{
		Identity: identity,
		Desired: DesiredSet{
			Target: target,
			ExpectedRelationship: ExpectedRelationship{
				State: ExpectedRelationshipActive, Generation: generation, Version: 4,
			},
			ExpectedDependentMembershipVersion: 3,
		},
		DisableExpansion: true,
	})
	if err != nil || result != receipt {
		t.Fatalf("ReplaceDesiredSet() = (%p, %v)", result, err)
	}
	if repository.replaceCalls != 1 || repository.rejectCalls != 0 {
		t.Fatalf("replace/reject calls = %d/%d", repository.replaceCalls, repository.rejectCalls)
	}
}

func TestMutationServiceDesiredSetExpansionPreparesShellAndResolvesPublicProjection(t *testing.T) {
	now := time.Now().UTC()
	identity := collectionClientIdentity()
	receipt := collectionPendingReceipt(t, identity, domain.OperationKindSetTargetCollections, now)
	beginner := &stubCollectionOperationBeginner{result: operation.BeginResult{
		Receipt: receipt, Outcome: operation.BeginOutcomeNewlyAcceptedPending,
	}}
	target := collectionTarget(t, domain.EntityTypeAttraction)
	repository := &stubCollectionMutationRepository{
		analysis: DesiredSetAnalysis{
			Change:              DesiredSetExpansion,
			DesiredExistingIDs:  []uuid.UUID{uuid.New()},
			Relationship:        RelationshipSnapshot{State: RelationshipSnapshotAbsent},
			HasInlineCollection: false,
		},
		prepareResult: receipt,
		replaceResult: receipt,
	}
	source := &stubCollectionSource{resolution: publicCollectionResolution(target, now)}
	service := newCollectionMutationServiceForTest(t, beginner, repository, source, now)
	desiredID := repository.analysis.DesiredExistingIDs[0]

	result, err := service.ReplaceDesiredSet(context.Background(), ReplaceDesiredSetRequest{
		Identity: identity,
		Desired: DesiredSet{
			Target:               target,
			ExpectedRelationship: ExpectedRelationship{State: ExpectedRelationshipAbsent},
			DesiredCollectionIDs: []uuid.UUID{desiredID},
		},
	})
	if err != nil || result != receipt {
		t.Fatalf("ReplaceDesiredSet(expansion) = (%p, %v)", result, err)
	}
	if source.calls != 1 || repository.prepareCalls != 1 || repository.replaceCalls != 1 ||
		repository.replaceCommand.Eligibility == nil ||
		repository.replaceCommand.Eligibility.Projection.Target != target ||
		repository.prepareCommand.SourceService != "place-service" ||
		!repository.prepareCommand.ShellExpiresAt.After(receipt.CommitDeadline()) {
		t.Fatalf("expansion orchestration source=%d prepare=%+v replace=%+v",
			source.calls, repository.prepareCommand, repository.replaceCommand)
	}
}

func TestMutationServiceExistingPendingDoesNotRepeatCollectionWork(t *testing.T) {
	now := time.Now().UTC()
	identity := collectionClientIdentity()
	receipt := collectionPendingReceipt(t, identity, domain.OperationKindDeleteCollection, now)
	beginner := &stubCollectionOperationBeginner{result: operation.BeginResult{
		Receipt: receipt, Outcome: operation.BeginOutcomeExistingPending,
	}}
	repository := &stubCollectionMutationRepository{}
	service := newCollectionMutationServiceForTest(t, beginner, repository, &stubCollectionSource{}, now)

	result, err := service.Delete(context.Background(), DeleteRequest{
		Identity: identity, CollectionID: uuid.New(),
		ExpectedMetadataVersion: 1, ExpectedLifecycleVersion: 1,
	})
	if err != nil || result != receipt {
		t.Fatalf("Delete(existing pending) = (%p, %v)", result, err)
	}
	if repository.deleteCalls != 0 || service.sessionValidator.(*stubCollectionSession).calls != 0 {
		t.Fatal("existing PENDING replay repeated mutation work")
	}
}

func newCollectionMutationServiceForTest(
	t *testing.T,
	beginner CollectionOperationBeginner,
	repository Repository,
	source appsource.Resolver,
	now time.Time,
	disableExpansion ...bool,
) *MutationService {
	t.Helper()
	service, err := NewMutationService(MutationServiceConfig{
		OperationBeginner: beginner,
		Repository:        repository,
		SourceResolver:    source,
		SessionValidator:  &stubCollectionSession{valid: true},
		PolicyGate:        &stubCollectionPolicy{grant: saveditemapp.PolicyGrant{Revision: 7}},
		Clock:             fixedCollectionClock{now: now},
		Limits:            Limits{}.WithDefaults(),
		DisableExpansion:  len(disableExpansion) > 0 && disableExpansion[0],
	})
	if err != nil {
		t.Fatalf("NewMutationService() error = %v", err)
	}
	return service
}

func collectionClientIdentity() ClientMutationIdentity {
	return ClientMutationIdentity{
		SubjectID:         uuid.MustParse("11111111-1111-4111-8111-111111111111"),
		OwnerUserID:       uuid.MustParse("22222222-2222-4222-8222-222222222222"),
		SessionGeneration: uuid.MustParse("33333333-3333-4333-8333-333333333333"),
		OperationID:       uuid.MustParse("44444444-4444-4444-8444-444444444444"),
		IdempotencyKey:    "0123456789abcdefghijklmnopqrstuv",
		SourceSurface:     domain.SourceSurfaceSavedAll,
	}
}

func collectionPendingReceipt(
	t *testing.T,
	identity ClientMutationIdentity,
	kind domain.OperationKind,
	now time.Time,
) *domain.SavedOperation {
	t.Helper()
	receipt, err := domain.NewPendingOperation(
		identity.OperationID,
		identity.SubjectID,
		identity.SessionGeneration,
		kind,
		identity.IdempotencyKey,
		[]byte(strings.Repeat("h", 32)),
		1,
		identity.SourceSurface,
		7,
		now,
		now.Add(10*time.Second),
	)
	if err != nil {
		t.Fatalf("NewPendingOperation() error = %v", err)
	}
	return receipt
}

func collectionTarget(t *testing.T, entityType domain.EntityType) domain.SavedTarget {
	t.Helper()
	target, err := domain.NewSavedTarget(entityType, uuid.NewString())
	if err != nil {
		t.Fatal(err)
	}
	return target
}

func publicCollectionResolution(target domain.SavedTarget, now time.Time) appsource.Resolution {
	return appsource.Resolution{
		Target: target, Eligible: true, Visibility: domain.VisibilityPublic,
		Revisions:   appsource.Revisions{Source: 1, Projection: 2, Visibility: 3},
		ValidatedAt: now,
		PublicProjection: &appsource.PublicCardProjection{
			SourceDefaultLocale: appsource.LocaleEN,
			Localized: map[appsource.Locale]appsource.LocalizedCardProjection{
				appsource.LocaleEN: {Title: "Museum", City: "Almaty", Country: "Kazakhstan"},
			},
			CanonicalDetailRoute: "/attractions/" + target.EntityID(),
		},
	}
}

type stubCollectionOperationBeginner struct {
	result   operation.BeginResult
	err      error
	semantic operation.CollectionSemanticRequest
	calls    int
}

func (stub *stubCollectionOperationBeginner) BeginCollection(
	_ context.Context,
	request operation.BeginCollectionRequest,
) (operation.BeginResult, error) {
	stub.calls++
	stub.semantic = request.SemanticRequest
	return stub.result, stub.err
}

type stubCollectionMutationRepository struct {
	analysis       DesiredSetAnalysis
	analyzeErr     error
	prepareResult  *domain.SavedOperation
	prepareErr     error
	createResult   *domain.SavedOperation
	renameResult   *domain.SavedOperation
	deleteResult   *domain.SavedOperation
	replaceResult  *domain.SavedOperation
	replaceErr     error
	rejectResult   *domain.SavedOperation
	createCommand  CreateCommand
	prepareCommand PrepareProjectionShellCommand
	replaceCommand ReplaceDesiredSetCommand
	rejectCommand  RejectPendingCommand
	createCalls    int
	renameCalls    int
	deleteCalls    int
	prepareCalls   int
	replaceCalls   int
	rejectCalls    int
}

func (stub *stubCollectionMutationRepository) ListCollectionRecords(context.Context, ListQuery) ([]CollectionRecord, error) {
	return nil, nil
}
func (stub *stubCollectionMutationRepository) GetCollectionRecord(context.Context, GetQuery) (CollectionRecord, error) {
	return CollectionRecord{}, nil
}
func (stub *stubCollectionMutationRepository) GetTargetCollections(context.Context, TargetSnapshotQuery) (TargetCollectionsSnapshot, error) {
	return TargetCollectionsSnapshot{}, nil
}
func (stub *stubCollectionMutationRepository) AnalyzeDesiredSet(context.Context, AnalyzeDesiredSetQuery) (DesiredSetAnalysis, error) {
	return stub.analysis, stub.analyzeErr
}
func (stub *stubCollectionMutationRepository) PrepareProjectionShell(
	_ context.Context,
	command PrepareProjectionShellCommand,
) (*domain.SavedOperation, error) {
	stub.prepareCalls++
	stub.prepareCommand = command
	return stub.prepareResult, stub.prepareErr
}
func (stub *stubCollectionMutationRepository) Create(
	_ context.Context,
	command CreateCommand,
) (*domain.SavedOperation, error) {
	stub.createCalls++
	stub.createCommand = command
	return stub.createResult, nil
}
func (stub *stubCollectionMutationRepository) Rename(context.Context, RenameCommand) (*domain.SavedOperation, error) {
	stub.renameCalls++
	return stub.renameResult, nil
}
func (stub *stubCollectionMutationRepository) Delete(context.Context, DeleteCommand) (*domain.SavedOperation, error) {
	stub.deleteCalls++
	return stub.deleteResult, nil
}
func (stub *stubCollectionMutationRepository) ReplaceDesiredSet(
	_ context.Context,
	command ReplaceDesiredSetCommand,
) (*domain.SavedOperation, error) {
	stub.replaceCalls++
	stub.replaceCommand = command
	return stub.replaceResult, stub.replaceErr
}
func (stub *stubCollectionMutationRepository) RejectPending(
	_ context.Context,
	command RejectPendingCommand,
) (*domain.SavedOperation, error) {
	stub.rejectCalls++
	stub.rejectCommand = command
	return stub.rejectResult, nil
}

type stubCollectionSource struct {
	resolution appsource.Resolution
	err        error
	calls      int
}

func (stub *stubCollectionSource) Resolve(
	context.Context,
	domain.SavedTarget,
) (appsource.Resolution, error) {
	stub.calls++
	return stub.resolution, stub.err
}

type stubCollectionSession struct {
	valid bool
	err   error
	calls int
}

func (stub *stubCollectionSession) Validate(context.Context, string, string) (bool, error) {
	stub.calls++
	return stub.valid, stub.err
}

type stubCollectionPolicy struct {
	grant         saveditemapp.PolicyGrant
	guardErr      error
	validateErr   error
	guardCalls    int
	validateCalls int
}

type stubCollectionUserAccessPolicy struct {
	denied map[uuid.UUID]struct{}
	err    error
	calls  int
}

func (stub *stubCollectionUserAccessPolicy) DeniedUserIDs(
	context.Context,
	uuid.UUID,
	[]uuid.UUID,
) (map[uuid.UUID]struct{}, error) {
	stub.calls++
	return stub.denied, stub.err
}

func (stub *stubCollectionPolicy) Guard(context.Context) (saveditemapp.PolicyGrant, error) {
	stub.guardCalls++
	return stub.grant, stub.guardErr
}

func (stub *stubCollectionPolicy) ValidateCommit(context.Context, uint64) error {
	stub.validateCalls++
	return stub.validateErr
}

type fixedCollectionClock struct{ now time.Time }

func (clock fixedCollectionClock) Now() time.Time { return clock.now }

var _ CollectionOperationBeginner = (*stubCollectionOperationBeginner)(nil)
var _ Repository = (*stubCollectionMutationRepository)(nil)
var _ appsource.Resolver = (*stubCollectionSource)(nil)
var _ saveditemapp.PolicyGate = (*stubCollectionPolicy)(nil)
