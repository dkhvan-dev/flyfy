package operation

import (
	"context"
	"crypto/hmac"
	"errors"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

const operationHardCommitWindow = 15 * time.Second

var (
	ErrInvalidServiceDependencies = errors.New("invalid operation service dependencies")
	ErrOperationStoreInvariant    = errors.New("operation store invariant violated")
)

type Clock interface {
	Now() time.Time
}

type ClockFunc func() time.Time

func (f ClockFunc) Now() time.Time {
	if f == nil {
		return time.Time{}
	}
	return f()
}

type SystemClock struct{}

func (SystemClock) Now() time.Time {
	return time.Now().UTC()
}

// BeginRequest intentionally has no client timestamp or source payload.
type BeginRequest struct {
	OperationID            uuid.UUID
	SubjectID              uuid.UUID
	SessionGeneration      uuid.UUID
	Kind                   domain.OperationKind
	IdempotencyKey         string
	Target                 domain.SavedTarget
	SourceSurface          domain.SourceSurface
	AcceptedPolicyRevision uint64
}

type BeginCollectionRequest struct {
	OperationID            uuid.UUID
	SubjectID              uuid.UUID
	SessionGeneration      uuid.UUID
	IdempotencyKey         string
	SemanticRequest        CollectionSemanticRequest
	SourceSurface          domain.SourceSurface
	AcceptedPolicyRevision uint64
}

type BeginOutcome string

const (
	BeginOutcomeNewlyAcceptedPending BeginOutcome = "NEWLY_ACCEPTED_PENDING"
	BeginOutcomeExistingPending      BeginOutcome = "EXISTING_PENDING"
	BeginOutcomeTerminalReplay       BeginOutcome = "TERMINAL_REPLAY"
)

type BeginResult struct {
	Receipt *domain.SavedOperation
	Outcome BeginOutcome
}

type Service struct {
	store   OperationStore
	keyRing *HMACKeyRing
	clock   Clock
}

func NewService(store OperationStore, keyRing *HMACKeyRing, clock Clock) (*Service, error) {
	if store == nil || keyRing == nil || clock == nil {
		return nil, ErrInvalidServiceDependencies
	}

	return &Service{store: store, keyRing: keyRing, clock: clock}, nil
}

// Begin creates or finds the durable Stage-1 receipt. It performs no source
// RPC, mutation execution, retry, lease, marker, reconciliation, or replay.
func (s *Service) Begin(ctx context.Context, request BeginRequest) (BeginResult, error) {
	if s == nil || s.store == nil || s.keyRing == nil || s.clock == nil {
		return BeginResult{}, ErrInvalidServiceDependencies
	}

	semanticHMAC, err := s.keyRing.Sign(request.Kind, request.Target)
	if err != nil {
		return BeginResult{}, err
	}
	identity := beginIdentity{
		OperationID:            request.OperationID,
		SubjectID:              request.SubjectID,
		SessionGeneration:      request.SessionGeneration,
		IdempotencyKey:         request.IdempotencyKey,
		SourceSurface:          request.SourceSurface,
		AcceptedPolicyRevision: request.AcceptedPolicyRevision,
	}
	storeResult, err := s.acceptPending(ctx, identity, request.Kind, semanticHMAC)
	if err != nil {
		return BeginResult{}, err
	}
	return s.classifyStoredReceipt(identity, request.Kind, semanticHMAC, storeResult, func(receipt *domain.SavedOperation) bool {
		return s.keyRing.Verify(
			receipt.RequestHMACKeyVersion(),
			request.Kind,
			request.Target,
			receipt.SemanticRequestHMAC(),
		)
	})
}

func (s *Service) BeginCollection(ctx context.Context, request BeginCollectionRequest) (BeginResult, error) {
	if s == nil || s.store == nil || s.keyRing == nil || s.clock == nil {
		return BeginResult{}, ErrInvalidServiceDependencies
	}
	semanticHMAC, err := s.keyRing.SignCollection(request.SemanticRequest)
	if err != nil {
		return BeginResult{}, err
	}
	kind := request.SemanticRequest.operationKind()
	identity := beginIdentity{
		OperationID:            request.OperationID,
		SubjectID:              request.SubjectID,
		SessionGeneration:      request.SessionGeneration,
		IdempotencyKey:         request.IdempotencyKey,
		SourceSurface:          request.SourceSurface,
		AcceptedPolicyRevision: request.AcceptedPolicyRevision,
	}
	storeResult, err := s.acceptPending(ctx, identity, kind, semanticHMAC)
	if err != nil {
		return BeginResult{}, err
	}
	return s.classifyStoredReceipt(identity, kind, semanticHMAC, storeResult, func(receipt *domain.SavedOperation) bool {
		return s.keyRing.VerifyCollection(
			receipt.RequestHMACKeyVersion(),
			request.SemanticRequest,
			receipt.SemanticRequestHMAC(),
		)
	})
}

type beginIdentity struct {
	OperationID            uuid.UUID
	SubjectID              uuid.UUID
	SessionGeneration      uuid.UUID
	IdempotencyKey         string
	SourceSurface          domain.SourceSurface
	AcceptedPolicyRevision uint64
}

func (s *Service) acceptPending(
	ctx context.Context,
	identity beginIdentity,
	kind domain.OperationKind,
	signed SemanticRequestHMAC,
) (CreateOrFindResult, error) {
	digest := signed.Bytes()
	defer clear(digest)
	serverNow := s.clock.Now().UTC()
	if serverNow.IsZero() {
		return CreateOrFindResult{}, domain.ErrMutationStale
	}
	pending, err := domain.NewPendingOperation(
		identity.OperationID,
		identity.SubjectID,
		identity.SessionGeneration,
		kind,
		identity.IdempotencyKey,
		digest,
		signed.KeyVersion,
		identity.SourceSurface,
		identity.AcceptedPolicyRevision,
		serverNow,
		serverNow.Add(operationHardCommitWindow),
	)
	if err != nil {
		return CreateOrFindResult{}, err
	}
	return s.store.CreateOrFind(ctx, pending)
}

func (s *Service) classifyStoredReceipt(
	identity beginIdentity,
	kind domain.OperationKind,
	signed SemanticRequestHMAC,
	storeResult CreateOrFindResult,
	verify func(*domain.SavedOperation) bool,
) (BeginResult, error) {
	receipt := storeResult.Receipt
	if receipt == nil {
		return BeginResult{}, ErrOperationStoreInvariant
	}

	if receipt.SubjectID() != identity.SubjectID || receipt.SessionGeneration() != identity.SessionGeneration {
		return BeginResult{}, ErrOperationStoreInvariant
	}
	if receipt.OperationID() != identity.OperationID || receipt.IdempotencyKey() != identity.IdempotencyKey {
		return BeginResult{}, domain.ErrReplayMismatch
	}

	if storeResult.Created {
		if receipt.Status() != domain.OperationStatusPending || receipt.Kind() != kind ||
			receipt.RequestHMACKeyVersion() != signed.KeyVersion ||
			!equalSemanticHMAC(receipt.SemanticRequestHMAC(), signed.Bytes()) {
			return BeginResult{}, ErrOperationStoreInvariant
		}

		return BeginResult{Receipt: receipt, Outcome: BeginOutcomeNewlyAcceptedPending}, nil
	}

	if receipt.Kind() != kind || verify == nil || !verify(receipt) {
		return BeginResult{}, domain.ErrReplayMismatch
	}

	switch receipt.Status() {
	case domain.OperationStatusPending:
		return BeginResult{Receipt: receipt, Outcome: BeginOutcomeExistingPending}, nil
	case domain.OperationStatusSucceeded, domain.OperationStatusRejected, domain.OperationStatusExpired:
		return BeginResult{Receipt: receipt, Outcome: BeginOutcomeTerminalReplay}, nil
	default:
		return BeginResult{}, ErrOperationStoreInvariant
	}
}

func equalSemanticHMAC(left []byte, right []byte) bool {
	if len(left) != len(right) {
		return false
	}
	return hmac.Equal(left, right)
}
