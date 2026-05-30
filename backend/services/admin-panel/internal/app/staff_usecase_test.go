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

func TestAdminUpdatesNonSuperAdminProfileAndRoles(t *testing.T) {
	t.Parallel()

	target := staffFixture(enum.StaffRoleExcursionModerator)
	repo := newStaffRepoStub(target)
	audit := &staffAuditRepoStub{}
	uc := NewStaffUseCase(repo, audit, &staffSessionRepoStub{})

	err := uc.UpdateStaffProfile(context.Background(), adminActor(), UpdateStaffProfileInput{
		StaffID:     target.ID,
		DisplayName: "Aruzhan Ops",
		Roles:       []enum.StaffRole{enum.StaffRoleActivityModerator, enum.StaffRoleSupportViewer},
		Metadata:    RequestMetadata{RequestID: "req-1"},
	})

	if err != nil {
		t.Fatalf("UpdateStaffProfile() error = %v", err)
	}
	if repo.updatedDisplayName != "Aruzhan Ops" {
		t.Fatalf("updated display name = %q", repo.updatedDisplayName)
	}
	if !sameRoles(repo.updatedRoles, []enum.StaffRole{enum.StaffRoleActivityModerator, enum.StaffRoleSupportViewer}) {
		t.Fatalf("updated roles = %v", repo.updatedRoles)
	}
	if audit.lastAction != "staff.updated" {
		t.Fatalf("audit action = %q, want staff.updated", audit.lastAction)
	}
}

func TestAdminCannotAssignSuperAdminRole(t *testing.T) {
	t.Parallel()

	target := staffFixture(enum.StaffRoleSupportViewer)
	uc := NewStaffUseCase(newStaffRepoStub(target), &staffAuditRepoStub{}, &staffSessionRepoStub{})

	err := uc.UpdateStaffProfile(context.Background(), adminActor(), UpdateStaffProfileInput{
		StaffID:     target.ID,
		DisplayName: target.DisplayName,
		Roles:       []enum.StaffRole{enum.StaffRoleSuperAdmin},
	})

	if !errors.Is(err, ErrPermissionDenied) {
		t.Fatalf("UpdateStaffProfile() error = %v, want ErrPermissionDenied", err)
	}
}

func TestAdminCannotEditSuperAdmin(t *testing.T) {
	t.Parallel()

	target := staffFixture(enum.StaffRoleSuperAdmin)
	uc := NewStaffUseCase(newStaffRepoStub(target), &staffAuditRepoStub{}, &staffSessionRepoStub{})

	err := uc.UpdateStaffProfile(context.Background(), adminActor(), UpdateStaffProfileInput{
		StaffID:     target.ID,
		DisplayName: "Changed",
		Roles:       []enum.StaffRole{enum.StaffRoleSupportViewer},
	})

	if !errors.Is(err, ErrPermissionDenied) {
		t.Fatalf("UpdateStaffProfile() error = %v, want ErrPermissionDenied", err)
	}
}

func TestSuperAdminCanUpdateOwnDisplayNameWithoutChangingRoles(t *testing.T) {
	t.Parallel()

	actor := superAdminActor()
	target := staffFixture(enum.StaffRoleSuperAdmin)
	target.ID = actor.ID
	target.Email = actor.Email
	target.DisplayName = actor.DisplayName
	repo := newStaffRepoStub(target)
	uc := NewStaffUseCase(repo, &staffAuditRepoStub{}, &staffSessionRepoStub{})

	err := uc.UpdateStaffProfile(context.Background(), actor, UpdateStaffProfileInput{
		StaffID:     target.ID,
		DisplayName: "Daniyar Khvan",
		Roles:       []enum.StaffRole{enum.StaffRoleSuperAdmin},
	})

	if err != nil {
		t.Fatalf("UpdateStaffProfile() error = %v", err)
	}
	if repo.updatedDisplayName != "Daniyar Khvan" {
		t.Fatalf("updated display name = %q", repo.updatedDisplayName)
	}
}

func TestSuperAdminCanAssignOwnAdditionalRoles(t *testing.T) {
	t.Parallel()

	actor := superAdminActor()
	target := staffFixture(enum.StaffRoleSuperAdmin)
	target.ID = actor.ID
	target.Email = actor.Email
	target.DisplayName = actor.DisplayName
	repo := newStaffRepoStub(target)
	uc := NewStaffUseCase(repo, &staffAuditRepoStub{}, &staffSessionRepoStub{})

	err := uc.UpdateStaffProfile(context.Background(), actor, UpdateStaffProfileInput{
		StaffID:     target.ID,
		DisplayName: "Daniyar Khvan",
		Roles: []enum.StaffRole{
			enum.StaffRoleSuperAdmin,
			enum.StaffRoleAdmin,
			enum.StaffRoleModerationLead,
			enum.StaffRoleExcursionModerator,
			enum.StaffRoleActivityModerator,
			enum.StaffRoleGuideModerator,
			enum.StaffRoleChatModerator,
			enum.StaffRoleReadOnlyAuditor,
			enum.StaffRoleSupportViewer,
		},
	})

	if err != nil {
		t.Fatalf("UpdateStaffProfile() error = %v", err)
	}
	if !sameRoles(repo.updatedRoles, []enum.StaffRole{
		enum.StaffRoleSuperAdmin,
		enum.StaffRoleAdmin,
		enum.StaffRoleModerationLead,
		enum.StaffRoleExcursionModerator,
		enum.StaffRoleActivityModerator,
		enum.StaffRoleGuideModerator,
		enum.StaffRoleChatModerator,
		enum.StaffRoleReadOnlyAuditor,
		enum.StaffRoleSupportViewer,
	}) {
		t.Fatalf("updated roles = %v", repo.updatedRoles)
	}
}

func TestSuperAdminCannotRemoveOwnSuperAdminRole(t *testing.T) {
	t.Parallel()

	actor := superAdminActor()
	target := staffFixture(enum.StaffRoleSuperAdmin)
	target.ID = actor.ID
	target.Email = actor.Email
	target.DisplayName = actor.DisplayName
	uc := NewStaffUseCase(newStaffRepoStub(target), &staffAuditRepoStub{}, &staffSessionRepoStub{})

	err := uc.UpdateStaffProfile(context.Background(), actor, UpdateStaffProfileInput{
		StaffID:     target.ID,
		DisplayName: "Daniyar Khvan",
		Roles:       []enum.StaffRole{enum.StaffRoleAdmin},
	})

	if !errors.Is(err, ErrPermissionDenied) {
		t.Fatalf("UpdateStaffProfile() error = %v, want ErrPermissionDenied", err)
	}
}

func TestAdminCannotUpdateOwnDisplayName(t *testing.T) {
	t.Parallel()

	actor := adminActor()
	target := staffFixture(enum.StaffRoleAdmin)
	target.ID = actor.ID
	target.Email = actor.Email
	target.DisplayName = actor.DisplayName
	uc := NewStaffUseCase(newStaffRepoStub(target), &staffAuditRepoStub{}, &staffSessionRepoStub{})

	err := uc.UpdateStaffProfile(context.Background(), actor, UpdateStaffProfileInput{
		StaffID:     target.ID,
		DisplayName: "Self Rename",
		Roles:       []enum.StaffRole{enum.StaffRoleAdmin},
	})

	if !errors.Is(err, ErrPermissionDenied) {
		t.Fatalf("UpdateStaffProfile() error = %v, want ErrPermissionDenied", err)
	}
}

func TestChangeStaffStatusRequiresReason(t *testing.T) {
	t.Parallel()

	target := staffFixture(enum.StaffRoleSupportViewer)
	uc := NewStaffUseCase(newStaffRepoStub(target), &staffAuditRepoStub{}, &staffSessionRepoStub{})

	err := uc.ChangeStaffStatus(context.Background(), adminActor(), ChangeStaffStatusInput{
		StaffID: target.ID,
		Status:  enum.StaffStatusDisabled,
	})

	if !errors.Is(err, ErrInvalidInput) {
		t.Fatalf("ChangeStaffStatus() error = %v, want ErrInvalidInput", err)
	}
}

func TestRegenerateStaffPasswordRevokesTargetSessions(t *testing.T) {
	t.Parallel()

	target := staffFixture(enum.StaffRoleSupportViewer)
	repo := newStaffRepoStub(target)
	sessions := &staffSessionRepoStub{}
	audit := &staffAuditRepoStub{}
	uc := NewStaffUseCase(repo, audit, sessions)

	result, err := uc.RegenerateStaffPassword(context.Background(), adminActor(), RegenerateStaffPasswordInput{
		StaffID:  target.ID,
		Metadata: RequestMetadata{RequestID: "req-2"},
	})

	if err != nil {
		t.Fatalf("RegenerateStaffPassword() error = %v", err)
	}
	if result.TemporaryPassword == "" {
		t.Fatal("temporary password is empty")
	}
	if repo.passwordStatus != enum.StaffStatusPasswordResetRequired {
		t.Fatalf("password status = %s, want PASSWORD_RESET_REQUIRED", repo.passwordStatus)
	}
	if sessions.revokedStaffID != target.ID {
		t.Fatalf("revoked staff id = %s, want %s", sessions.revokedStaffID, target.ID)
	}
	if audit.lastAction != "staff.password.regenerated" {
		t.Fatalf("audit action = %q, want staff.password.regenerated", audit.lastAction)
	}
}

func TestStaffCanUpdateOwnTimezone(t *testing.T) {
	t.Parallel()

	actor := adminActor()
	target := staffFixture(enum.StaffRoleAdmin)
	target.ID = actor.ID
	target.Email = actor.Email
	target.DisplayName = actor.DisplayName
	target.Timezone = "UTC"
	repo := newStaffRepoStub(target)
	audit := &staffAuditRepoStub{}
	uc := NewStaffUseCase(repo, audit, &staffSessionRepoStub{})

	err := uc.UpdateOwnTimezone(context.Background(), actor, UpdateOwnTimezoneInput{
		Timezone: "Asia/Tokyo",
		Metadata: RequestMetadata{
			RequestID: "req-timezone",
		},
	})

	if err != nil {
		t.Fatalf("UpdateOwnTimezone() error = %v", err)
	}
	if repo.updatedTimezone != "Asia/Tokyo" {
		t.Fatalf("updated timezone = %q, want Asia/Tokyo", repo.updatedTimezone)
	}
	if target.Timezone != "Asia/Tokyo" {
		t.Fatalf("target timezone = %q, want Asia/Tokyo", target.Timezone)
	}
	if audit.lastAction != "staff.timezone.updated" {
		t.Fatalf("audit action = %q, want staff.timezone.updated", audit.lastAction)
	}
}

func TestStaffCannotUpdateOwnTimezoneToInvalidValue(t *testing.T) {
	t.Parallel()

	actor := adminActor()
	target := staffFixture(enum.StaffRoleAdmin)
	target.ID = actor.ID
	repo := newStaffRepoStub(target)
	uc := NewStaffUseCase(repo, &staffAuditRepoStub{}, &staffSessionRepoStub{})

	err := uc.UpdateOwnTimezone(context.Background(), actor, UpdateOwnTimezoneInput{
		Timezone: "Almaty",
	})

	if !errors.Is(err, ErrInvalidInput) {
		t.Fatalf("UpdateOwnTimezone() error = %v, want ErrInvalidInput", err)
	}
	if repo.updatedTimezone != "" {
		t.Fatalf("timezone was updated to %q", repo.updatedTimezone)
	}
}

func adminActor() *model.StaffUser {
	return &model.StaffUser{
		ID:          uuid.New(),
		Email:       "admin@inflap.local",
		DisplayName: "Admin",
		Status:      enum.StaffStatusActive,
		Roles:       []enum.StaffRole{enum.StaffRoleAdmin},
		Permissions: []enum.Permission{enum.PermissionStaffManage},
	}
}

func superAdminActor() *model.StaffUser {
	return &model.StaffUser{
		ID:          uuid.New(),
		Email:       "dkhvan.developer@gmail.com",
		DisplayName: "Super Admin",
		Status:      enum.StaffStatusActive,
		Roles:       []enum.StaffRole{enum.StaffRoleSuperAdmin},
		Permissions: []enum.Permission{enum.PermissionStaffManage},
	}
}

func staffFixture(roles ...enum.StaffRole) *model.StaffUser {
	return &model.StaffUser{
		ID:          uuid.New(),
		Email:       "staff@inflap.local",
		DisplayName: "Staff",
		Status:      enum.StaffStatusActive,
		Timezone:    "Asia/Almaty",
		Roles:       roles,
		CreatedAt:   time.Now().UTC(),
		UpdatedAt:   time.Now().UTC(),
	}
}

type staffRepoStub struct {
	target             *model.StaffUser
	updatedDisplayName string
	updatedRoles       []enum.StaffRole
	updatedTimezone    string
	passwordStatus     enum.StaffStatus
}

func newStaffRepoStub(target *model.StaffUser) *staffRepoStub {
	return &staffRepoStub{target: target}
}

func (r *staffRepoStub) GetByID(_ context.Context, id uuid.UUID) (*model.StaffUser, error) {
	if r.target != nil && r.target.ID == id {
		return r.target, nil
	}
	return nil, nil
}

func (r *staffRepoStub) GetByEmail(context.Context, string) (*model.StaffUser, error) {
	return nil, nil
}

func (r *staffRepoStub) List(context.Context, int, int) ([]*model.StaffUser, error) {
	return []*model.StaffUser{r.target}, nil
}

func (r *staffRepoStub) Create(context.Context, *model.StaffUser, string, []enum.StaffRole) error {
	return nil
}

func (r *staffRepoStub) UpdateProfileAndRoles(_ context.Context, id uuid.UUID, displayName string, roles []enum.StaffRole, _ uuid.UUID, _ time.Time) error {
	if r.target == nil || r.target.ID != id {
		return nil
	}
	r.updatedDisplayName = displayName
	r.updatedRoles = append([]enum.StaffRole(nil), roles...)
	r.target.DisplayName = displayName
	r.target.Roles = append([]enum.StaffRole(nil), roles...)
	return nil
}

func (r *staffRepoStub) UpdateTimezone(_ context.Context, id uuid.UUID, timezone string, _ time.Time) error {
	if r.target == nil || r.target.ID != id {
		return nil
	}
	r.updatedTimezone = timezone
	r.target.Timezone = timezone
	return nil
}

func (r *staffRepoStub) UpdateLoginSuccess(context.Context, uuid.UUID, time.Time) error {
	return nil
}

func (r *staffRepoStub) UpdateLoginFailure(context.Context, uuid.UUID, int, *time.Time) error {
	return nil
}

func (r *staffRepoStub) UpdatePassword(_ context.Context, id uuid.UUID, _ string, status enum.StaffStatus, _ time.Time) error {
	if r.target != nil && r.target.ID == id {
		r.passwordStatus = status
		r.target.Status = status
	}
	return nil
}

func (r *staffRepoStub) SetStatus(_ context.Context, id uuid.UUID, status enum.StaffStatus, _ time.Time) error {
	if r.target != nil && r.target.ID == id {
		r.target.Status = status
	}
	return nil
}

func (r *staffRepoStub) GetPermissions(context.Context, uuid.UUID) ([]enum.Permission, []enum.StaffRole, error) {
	if r.target == nil {
		return nil, nil, nil
	}
	return nil, r.target.Roles, nil
}

type staffSessionRepoStub struct {
	revokedStaffID uuid.UUID
}

func (r *staffSessionRepoStub) Create(context.Context, *model.StaffSession) error {
	return nil
}

func (r *staffSessionRepoStub) GetBySessionHash(context.Context, string) (*model.StaffSession, error) {
	return nil, nil
}

func (r *staffSessionRepoStub) Touch(context.Context, uuid.UUID, time.Time, time.Time) error {
	return nil
}

func (r *staffSessionRepoStub) Revoke(context.Context, uuid.UUID, time.Time) error {
	return nil
}

func (r *staffSessionRepoStub) RevokeAllForStaff(_ context.Context, staffID uuid.UUID, _ time.Time) error {
	r.revokedStaffID = staffID
	return nil
}

type staffAuditRepoStub struct {
	lastAction string
}

func (r *staffAuditRepoStub) Append(_ context.Context, event *model.AuditEvent) error {
	r.lastAction = event.Action
	return nil
}

func (r *staffAuditRepoStub) List(context.Context, model.AuditFilter) ([]*model.AuditEvent, error) {
	return nil, nil
}

func sameRoles(left []enum.StaffRole, right []enum.StaffRole) bool {
	if len(left) != len(right) {
		return false
	}
	for index := range left {
		if left[index] != right[index] {
			return false
		}
	}
	return true
}
