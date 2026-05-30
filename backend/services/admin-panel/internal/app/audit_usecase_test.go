package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

func TestAuditListOwnAllowsStaffWithoutGlobalAuditPermission(t *testing.T) {
	t.Parallel()

	actorID := uuid.New()
	repo := &auditRepoStub{}
	uc := NewAuditUseCase(repo)
	actor := &model.StaffUser{
		ID:          actorID,
		Email:       "moderator@inflap.local",
		DisplayName: "Moderator",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{enum.PermissionDashboardRead},
	}

	events, err := uc.ListOwn(context.Background(), actor, model.AuditFilter{Limit: 20})
	if err != nil {
		t.Fatalf("ListOwn() error = %v", err)
	}
	if len(events) != 1 {
		t.Fatalf("ListOwn() returned %d events, want 1", len(events))
	}
	if repo.lastFilter.ActorStaffID == nil || *repo.lastFilter.ActorStaffID != actorID {
		t.Fatalf("ActorStaffID filter = %v, want %s", repo.lastFilter.ActorStaffID, actorID)
	}
}

func TestAuditListStillRequiresGlobalAuditPermission(t *testing.T) {
	t.Parallel()

	uc := NewAuditUseCase(&auditRepoStub{})
	actor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "moderator@inflap.local",
		DisplayName: "Moderator",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{enum.PermissionDashboardRead},
	}

	_, err := uc.List(context.Background(), actor, model.AuditFilter{Limit: 20})
	if !errors.Is(err, ErrPermissionDenied) {
		t.Fatalf("List() error = %v, want ErrPermissionDenied", err)
	}
}

type auditRepoStub struct {
	lastFilter model.AuditFilter
}

func (r *auditRepoStub) Append(context.Context, *model.AuditEvent) error {
	return nil
}

func (r *auditRepoStub) List(_ context.Context, filter model.AuditFilter) ([]*model.AuditEvent, error) {
	r.lastFilter = filter
	return []*model.AuditEvent{
		{
			ID:               uuid.New(),
			ActorStaffID:     filter.ActorStaffID,
			ActorDisplayName: "Moderator",
			ActorEmail:       "moderator@inflap.local",
			Action:           "admin.login.succeeded",
			EntityType:       "staff_session",
			CreatedAt:        time.Now().UTC(),
		},
	}, nil
}
