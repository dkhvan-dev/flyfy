package savedaccess

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestDeniedTargetsCombinesLocalAndRelationshipDenials(t *testing.T) {
	t.Parallel()

	ownerUserID := uuid.New()
	blockedUserID := uuid.New()
	allowedUserID := uuid.New()
	selfTarget := userTarget(t, ownerUserID)
	blockedTarget := userTarget(t, blockedUserID)
	allowedTarget := userTarget(t, allowedUserID)
	activityTarget := targetForAccessTest(t, domain.EntityTypeActivity, uuid.NewString())
	policy := &policyStub{denied: map[uuid.UUID]struct{}{blockedUserID: {}}}

	denied, err := DeniedTargets(context.Background(), policy, ownerUserID, []domain.SavedTarget{
		activityTarget,
		selfTarget,
		blockedTarget,
		allowedTarget,
		blockedTarget,
	})
	if err != nil {
		t.Fatalf("DeniedTargets() error = %v", err)
	}
	if len(denied) != 2 {
		t.Fatalf("denied = %+v, want self and blocked target", denied)
	}
	if _, ok := denied[selfTarget]; !ok {
		t.Fatal("own profile was not denied locally")
	}
	if _, ok := denied[blockedTarget]; !ok {
		t.Fatal("relationship-denied profile was not denied")
	}
	if _, ok := denied[allowedTarget]; ok {
		t.Fatal("allowed profile was denied")
	}
	if policy.calls != 1 || policy.ownerUserID != ownerUserID || len(policy.userIDs) != 2 {
		t.Fatalf("policy call = %+v", policy)
	}
}

func TestDeniedTargetsDoesNotCoupleNonUserTargetsToPolicy(t *testing.T) {
	t.Parallel()

	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	activityTarget := targetForAccessTest(t, domain.EntityTypeActivity, uuid.NewString())
	denied, err := DeniedTargets(ctx, nil, uuid.New(), []domain.SavedTarget{activityTarget})
	if err != nil || len(denied) != 0 {
		t.Fatalf("DeniedTargets(non-user) = (%+v, %v)", denied, err)
	}
}

func TestDeniedTargetsRejectsUntrustedPolicyOutput(t *testing.T) {
	t.Parallel()

	requestedUserID := uuid.New()
	policy := &policyStub{denied: map[uuid.UUID]struct{}{uuid.New(): {}}}
	_, err := DeniedTargets(
		context.Background(),
		policy,
		uuid.New(),
		[]domain.SavedTarget{userTarget(t, requestedUserID)},
	)
	if !errors.Is(err, ErrPolicyUnavailable) {
		t.Fatalf("DeniedTargets() error = %v, want %v", err, ErrPolicyUnavailable)
	}
}

func TestDeniedTargetsFailClosedScrubsOnlyUserTargets(t *testing.T) {
	t.Parallel()

	user := userTarget(t, uuid.New())
	activity := targetForAccessTest(t, domain.EntityTypeActivity, uuid.NewString())
	denied, err := DeniedTargetsFailClosed(
		context.Background(),
		&policyStub{err: errors.New("chat unavailable")},
		uuid.New(),
		[]domain.SavedTarget{user, activity},
	)
	if err != nil {
		t.Fatalf("DeniedTargetsFailClosed() error = %v", err)
	}
	if len(denied) != 1 {
		t.Fatalf("denied = %+v, want only USER", denied)
	}
	if _, ok := denied[user]; !ok {
		t.Fatal("USER target was not denied fail closed")
	}
	if _, ok := denied[activity]; ok {
		t.Fatal("non-USER target was coupled to relationship policy")
	}
}

func TestExpansionCauseUsesNeutralMutationErrors(t *testing.T) {
	t.Parallel()

	blockedUserID := uuid.New()
	blocked := userTarget(t, blockedUserID)
	if cause := ExpansionCause(
		context.Background(),
		&policyStub{denied: map[uuid.UUID]struct{}{blockedUserID: {}}},
		uuid.New(),
		blocked,
	); cause != domain.ErrTargetUnavailable {
		t.Fatalf("blocked expansion cause = %v", cause)
	}
	if cause := ExpansionCause(
		context.Background(),
		&policyStub{err: errors.New("chat unavailable")},
		uuid.New(),
		blocked,
	); cause != domain.ErrDependencyUnavailable {
		t.Fatalf("dependency expansion cause = %v", cause)
	}
	activity := targetForAccessTest(t, domain.EntityTypeActivity, uuid.NewString())
	if cause := ExpansionCause(context.Background(), nil, uuid.New(), activity); cause != nil {
		t.Fatalf("non-user expansion cause = %v", cause)
	}
}

type policyStub struct {
	denied      map[uuid.UUID]struct{}
	err         error
	ownerUserID uuid.UUID
	userIDs     []uuid.UUID
	calls       int
}

func (stub *policyStub) DeniedUserIDs(
	_ context.Context,
	ownerUserID uuid.UUID,
	userIDs []uuid.UUID,
) (map[uuid.UUID]struct{}, error) {
	stub.calls++
	stub.ownerUserID = ownerUserID
	stub.userIDs = append([]uuid.UUID(nil), userIDs...)
	return stub.denied, stub.err
}

func userTarget(t testing.TB, userID uuid.UUID) domain.SavedTarget {
	t.Helper()
	return targetForAccessTest(t, domain.EntityTypeUser, userID.String())
}

func targetForAccessTest(
	t testing.TB,
	entityType domain.EntityType,
	entityID string,
) domain.SavedTarget {
	t.Helper()
	target, err := domain.NewSavedTarget(entityType, entityID)
	if err != nil {
		t.Fatalf("NewSavedTarget() error = %v", err)
	}
	return target
}

var _ Policy = (*policyStub)(nil)
