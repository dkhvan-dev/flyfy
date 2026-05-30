package app

import (
	"context"
	"testing"

	"github.com/google/uuid"
	"kz/inflap/backend/services/user-service/internal/domain/enum"
)

func TestRevokeRoleDeletesExistingRole(t *testing.T) {
	userID := uuid.New()
	repo := newFriendshipTestRepository(userID)
	repo.roles = map[uuid.UUID]map[enum.SystemRole]struct{}{
		userID: {enum.SystemRoleGuide: {}},
	}
	useCase := NewUserUseCase(repo, nil)

	if err := useCase.RevokeRole(context.Background(), userID, enum.SystemRoleGuide); err != nil {
		t.Fatalf("RevokeRole() error = %v", err)
	}

	if repo.hasRoleValue(userID, enum.SystemRoleGuide) {
		t.Fatal("GUIDE role must be removed")
	}
}

func TestRevokeRoleIsIdempotentForMissingRole(t *testing.T) {
	userID := uuid.New()
	repo := newFriendshipTestRepository(userID)
	repo.roles = map[uuid.UUID]map[enum.SystemRole]struct{}{}
	useCase := NewUserUseCase(repo, nil)

	if err := useCase.RevokeRole(context.Background(), userID, enum.SystemRoleGuide); err != nil {
		t.Fatalf("RevokeRole() error = %v", err)
	}
}
