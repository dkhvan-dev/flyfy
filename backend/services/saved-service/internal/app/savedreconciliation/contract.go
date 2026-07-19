package savedreconciliation

import (
	"context"
	"math"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/app/saveditem"
	appsource "kz/inflap/backend/services/saved-service/internal/app/source"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

const (
	maxResolutionFutureSkew = 5 * time.Second
	maxResolutionAge        = 5 * time.Minute
)

type CandidateKey struct {
	VisibilityValidatedAt *time.Time
	Target                domain.SavedTarget
}

func (k CandidateKey) Validate() error {
	if k.Target.IsZero() {
		return ErrDataInvariant
	}
	if k.VisibilityValidatedAt != nil && k.VisibilityValidatedAt.IsZero() {
		return ErrDataInvariant
	}
	return nil
}

type Candidate struct {
	Key                CandidateKey
	SourceService      string
	SourceRevision     uint64
	ProjectionRevision uint64
	VisibilityRevision uint64
	Visibility         domain.VisibilityStatus
	FailClosedAt       *time.Time
}

func (c Candidate) Validate() error {
	if err := c.Key.Validate(); err != nil || !validSourceService(c.SourceService) ||
		!validDatabaseRevision(c.SourceRevision, true) ||
		!validDatabaseRevision(c.ProjectionRevision, true) ||
		!validDatabaseRevision(c.VisibilityRevision, true) ||
		!c.Visibility.IsValid() {
		return ErrDataInvariant
	}
	if c.Visibility == domain.VisibilityUnknown {
		if c.Key.VisibilityValidatedAt != nil {
			return ErrDataInvariant
		}
	} else if c.Key.VisibilityValidatedAt == nil {
		return ErrDataInvariant
	}
	if c.Visibility == domain.VisibilityPrivate &&
		c.Key.Target.EntityType() != domain.EntityTypeActivity {
		return ErrDataInvariant
	}
	if c.FailClosedAt != nil && c.FailClosedAt.IsZero() {
		return ErrDataInvariant
	}
	return nil
}

const maxStoredFailureCount = 32_767

type ClaimRequest struct {
	StaleAfter    time.Duration
	LeaseDuration time.Duration
}

func (r ClaimRequest) Validate() error {
	if r.StaleAfter <= 0 || r.LeaseDuration <= 0 ||
		r.LeaseDuration > maxLeaseDuration {
		return ErrDataInvariant
	}
	return nil
}

type DueRequest struct {
	StaleAfter time.Duration
}

func (r DueRequest) Validate() error {
	if r.StaleAfter <= 0 {
		return ErrDataInvariant
	}
	return nil
}

type Claim struct {
	Token           uuid.UUID
	Candidate       Candidate
	ClaimedAt       time.Time
	LeaseExpiresAt  time.Time
	FailureCount    int
	PreviousFailure CompletionFailure
}

func (c Claim) Validate() error {
	if c.Token == uuid.Nil || c.ClaimedAt.IsZero() || c.LeaseExpiresAt.IsZero() ||
		!c.LeaseExpiresAt.After(c.ClaimedAt) || c.FailureCount < 0 ||
		c.FailureCount > maxStoredFailureCount || !c.PreviousFailure.IsValid() ||
		(c.FailureCount == 0) != (c.PreviousFailure == CompletionFailureNone) {
		return ErrDataInvariant
	}
	return c.Candidate.Validate()
}

type DecisionKind uint8

const (
	DecisionNoop DecisionKind = iota + 1
	DecisionResolved
	DecisionNotFound
)

type Decision struct {
	Kind               DecisionKind
	Target             domain.SavedTarget
	SourceRevision     uint64
	ProjectionRevision uint64
	VisibilityRevision uint64
	Visibility         domain.VisibilityStatus
	ValidatedAt        time.Time
	PublicProjection   *saveditem.PublicProjectionSnapshot
}

func NewNoopDecision(target domain.SavedTarget) Decision {
	return Decision{Kind: DecisionNoop, Target: target}
}

func NewNotFoundDecision(target domain.SavedTarget, validatedAt time.Time) (Decision, error) {
	decision := Decision{
		Kind:        DecisionNotFound,
		Target:      target,
		Visibility:  domain.VisibilityUnavailable,
		ValidatedAt: validatedAt.UTC(),
	}
	if err := decision.Validate(target); err != nil {
		return Decision{}, err
	}
	return decision, nil
}

func BuildResolvedDecision(
	resolution appsource.Resolution,
	serverNow time.Time,
) (Decision, error) {
	serverNow = serverNow.UTC()
	validatedAt := resolution.ValidatedAt.UTC()
	if resolution.Target.IsZero() || serverNow.IsZero() || validatedAt.IsZero() ||
		validatedAt.After(serverNow.Add(maxResolutionFutureSkew)) ||
		validatedAt.Before(serverNow.Add(-maxResolutionAge)) ||
		resolution.Eligible != (resolution.Visibility == domain.VisibilityPublic) ||
		resolution.Eligible != (resolution.PublicProjection != nil) {
		return Decision{}, ErrDataInvariant
	}
	decision := Decision{
		Kind:               DecisionResolved,
		Target:             resolution.Target,
		SourceRevision:     resolution.Revisions.Source,
		ProjectionRevision: resolution.Revisions.Projection,
		VisibilityRevision: resolution.Revisions.Visibility,
		Visibility:         resolution.Visibility,
		ValidatedAt:        validatedAt,
	}
	if resolution.Visibility == domain.VisibilityPublic {
		snapshot, err := saveditem.BuildPublicProjectionSnapshot(
			resolution,
			serverNow,
			serverNow,
		)
		if err != nil {
			return Decision{}, ErrDataInvariant
		}
		decision.PublicProjection = &snapshot
	}
	if err := decision.Validate(resolution.Target); err != nil {
		return Decision{}, err
	}
	return decision, nil
}

func (d Decision) Validate(expectedTarget domain.SavedTarget) error {
	if d.Target.IsZero() || d.Target.EntityType() != expectedTarget.EntityType() ||
		d.Target.EntityID() != expectedTarget.EntityID() {
		return ErrDataInvariant
	}
	switch d.Kind {
	case DecisionNoop:
		if d.SourceRevision != 0 || d.ProjectionRevision != 0 ||
			d.VisibilityRevision != 0 || d.Visibility != "" ||
			!d.ValidatedAt.IsZero() || d.PublicProjection != nil {
			return ErrDataInvariant
		}
	case DecisionNotFound:
		if d.SourceRevision != 0 || d.ProjectionRevision != 0 ||
			d.VisibilityRevision != 0 ||
			d.Visibility != domain.VisibilityUnavailable ||
			d.ValidatedAt.IsZero() || d.PublicProjection != nil {
			return ErrDataInvariant
		}
	case DecisionResolved:
		if !validDatabaseRevision(d.SourceRevision, false) ||
			!validDatabaseRevision(d.ProjectionRevision, false) ||
			!validDatabaseRevision(d.VisibilityRevision, false) ||
			d.ValidatedAt.IsZero() || !resolvedVisibility(d.Visibility) ||
			(d.Visibility == domain.VisibilityPrivate &&
				d.Target.EntityType() != domain.EntityTypeActivity) {
			return ErrDataInvariant
		}
		if d.Visibility == domain.VisibilityPublic {
			if d.PublicProjection == nil ||
				d.PublicProjection.Target.EntityType() != d.Target.EntityType() ||
				d.PublicProjection.Target.EntityID() != d.Target.EntityID() ||
				d.PublicProjection.SourceRevision != d.SourceRevision ||
				d.PublicProjection.ProjectionRevision != d.ProjectionRevision ||
				d.PublicProjection.VisibilityRevision != d.VisibilityRevision {
				return ErrDataInvariant
			}
		} else if d.PublicProjection != nil {
			return ErrDataInvariant
		}
	default:
		return ErrDataInvariant
	}
	return nil
}

type ApplyOutcome uint8

const (
	ApplyNoChange ApplyOutcome = iota + 1
	ApplyPublic
	ApplyDeny
	ApplyMetadataOnly
	ApplyStale
)

func (o ApplyOutcome) IsValid() bool {
	return o >= ApplyNoChange && o <= ApplyStale
}

type ApplyResult struct {
	Outcome            ApplyOutcome
	SourceAdvanced     bool
	ProjectionAdvanced bool
	VisibilityAdvanced bool
	PayloadCleared     bool
}

func (r ApplyResult) Validate() error {
	if !r.Outcome.IsValid() {
		return ErrDataInvariant
	}
	changed := r.SourceAdvanced || r.ProjectionAdvanced ||
		r.VisibilityAdvanced || r.PayloadCleared
	if (r.Outcome == ApplyNoChange || r.Outcome == ApplyStale) && changed {
		return ErrDataInvariant
	}
	if r.PayloadCleared && r.Outcome != ApplyDeny {
		return ErrDataInvariant
	}
	return nil
}

type CompletionFailure uint8

const (
	CompletionFailureNone CompletionFailure = iota
	CompletionFailureTransient
	CompletionFailureInvariant
	CompletionFailureUnsupported
)

func (f CompletionFailure) IsValid() bool {
	return f >= CompletionFailureNone && f <= CompletionFailureUnsupported
}

type CompletionRequest struct {
	Claim            Claim
	Decision         Decision
	NextAttemptDelay time.Duration
	Failure          CompletionFailure
	Quarantine       bool
}

func (r CompletionRequest) Validate() error {
	if err := r.Claim.Validate(); err != nil {
		return err
	}
	if !r.Failure.IsValid() {
		return ErrDataInvariant
	}
	if r.Failure == CompletionFailureNone {
		if r.Quarantine || r.NextAttemptDelay <= 0 {
			return ErrDataInvariant
		}
		return r.Decision.Validate(r.Claim.Candidate.Key.Target)
	}
	if r.Decision.Kind != 0 {
		return ErrDataInvariant
	}
	if r.Quarantine {
		if r.NextAttemptDelay != 0 ||
			(r.Failure != CompletionFailureInvariant &&
				r.Failure != CompletionFailureUnsupported) {
			return ErrDataInvariant
		}
		return nil
	}
	if r.NextAttemptDelay <= 0 {
		return ErrDataInvariant
	}
	return nil
}

type CompletionResult struct {
	Applied        ApplyResult
	LeaseLost      bool
	RetryScheduled bool
	Quarantined    bool
}

func (r CompletionResult) Validate() error {
	if err := r.Applied.Validate(); err != nil {
		return err
	}
	states := 0
	for _, active := range []bool{r.LeaseLost, r.RetryScheduled, r.Quarantined} {
		if active {
			states++
		}
	}
	if states > 1 || (r.LeaseLost && r.Applied.Outcome != ApplyStale) ||
		((r.RetryScheduled || r.Quarantined) && r.Applied.Outcome != ApplyNoChange) {
		return ErrDataInvariant
	}
	return nil
}

// Repository persists short claims and completes them with a snapshot CAS.
// Source RPCs happen between these calls and therefore never hold a DB lock.
type Repository interface {
	ClaimNext(context.Context, ClaimRequest) (Claim, bool, error)
	Complete(context.Context, CompletionRequest) (CompletionResult, error)
	HasDue(context.Context, DueRequest) (bool, error)
}

func resolvedVisibility(value domain.VisibilityStatus) bool {
	switch value {
	case domain.VisibilityPublic,
		domain.VisibilityPrivate,
		domain.VisibilityUnavailable,
		domain.VisibilityDeleted,
		domain.VisibilityRestricted:
		return true
	default:
		return false
	}
}

func validDatabaseRevision(value uint64, allowZero bool) bool {
	return (allowZero || value > 0) && value <= math.MaxInt64
}

func validSourceService(value string) bool {
	if value == "" || len(value) > 64 || value != strings.TrimSpace(value) ||
		!utf8.ValidString(value) || value[0] < 'a' || value[0] > 'z' {
		return false
	}
	for _, char := range value[1:] {
		if (char >= 'a' && char <= 'z') || (char >= '0' && char <= '9') || char == '-' {
			continue
		}
		return false
	}
	return true
}
