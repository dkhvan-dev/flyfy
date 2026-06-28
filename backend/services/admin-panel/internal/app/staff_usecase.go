package app

import (
	"context"
	"encoding/json"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
	"kz/inflap/backend/services/admin-panel/internal/domain/port"
)

type StaffUseCase struct {
	staff    port.StaffRepository
	sessions port.SessionRepository
	audit    port.AuditRepository
}

type CreateStaffInput struct {
	ActorStaffID uuid.UUID
	Email        string
	DisplayName  string
	Roles        []enum.StaffRole
	Metadata     RequestMetadata
}

type CreateStaffResult struct {
	Staff             *model.StaffUser
	TemporaryPassword string
}

type UpdateStaffProfileInput struct {
	StaffID     uuid.UUID
	DisplayName string
	Roles       []enum.StaffRole
	Metadata    RequestMetadata
}

type UpdateOwnTimezoneInput struct {
	Timezone string
	Metadata RequestMetadata
}

type ChangeStaffStatusInput struct {
	StaffID  uuid.UUID
	Status   enum.StaffStatus
	Reason   string
	Metadata RequestMetadata
}

type RegenerateStaffPasswordInput struct {
	StaffID  uuid.UUID
	Metadata RequestMetadata
}

type RegenerateStaffPasswordResult struct {
	TemporaryPassword string
}

type StaffDisplayContact struct {
	DisplayName string
	Email       string
}

type BootstrapSuperAdminInput struct {
	Email       string
	DisplayName string
	Password    string
	Metadata    RequestMetadata
}

func NewStaffUseCase(staff port.StaffRepository, audit port.AuditRepository, sessions ...port.SessionRepository) *StaffUseCase {
	var sessionRepo port.SessionRepository
	if len(sessions) > 0 {
		sessionRepo = sessions[0]
	}
	return &StaffUseCase{staff: staff, sessions: sessionRepo, audit: audit}
}

func canReadStaffDisplayName(actor *model.StaffUser) bool {
	return actor.HasPermission(enum.PermissionStaffManage) ||
		actor.HasPermission(enum.PermissionSupportRead) ||
		actor.HasPermission(enum.PermissionSupportReply) ||
		actor.HasPermission(enum.PermissionSupportManage)
}

func (u *StaffUseCase) ListStaff(ctx context.Context, actor *model.StaffUser, limit int, offset int) ([]*model.StaffUser, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionStaffManage) {
		return nil, ErrPermissionDenied
	}
	return u.staff.List(ctx, clampLimit(limit), normalizeOffset(offset))
}

func (u *StaffUseCase) ListSupportAssignableStaff(ctx context.Context, actor *model.StaffUser, limit int, offset int) ([]*model.StaffUser, error) {
	if actor == nil || (!actor.HasPermission(enum.PermissionSupportManage) && !actor.HasPermission(enum.PermissionStaffManage)) {
		return nil, ErrPermissionDenied
	}
	if u == nil || u.staff == nil {
		return nil, ErrIntegrationNotReady
	}
	items, err := u.staff.List(ctx, clampLimit(limit), normalizeOffset(offset))
	if err != nil {
		return nil, err
	}
	assignable := make([]*model.StaffUser, 0, len(items))
	for _, item := range items {
		enriched, err := u.staffWithPermissions(ctx, item)
		if err != nil {
			return nil, err
		}
		if supportStaffCanHandleTickets(enriched) {
			assignable = append(assignable, enriched)
		}
	}
	return assignable, nil
}

func supportStaffCanHandleTickets(staff *model.StaffUser) bool {
	if staff == nil || staff.IsDisabled() || staff.Status == enum.StaffStatusLocked {
		return false
	}
	return staff.HasPermission(enum.PermissionSupportReply) ||
		staff.HasPermission(enum.PermissionSupportManage) ||
		staff.HasRole(enum.StaffRoleSupportAgent) ||
		staff.HasRole(enum.StaffRoleSupportLead) ||
		staff.HasRole(enum.StaffRoleSupportAdmin)
}

func (u *StaffUseCase) GetStaff(ctx context.Context, actor *model.StaffUser, staffID uuid.UUID) (*model.StaffUser, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionStaffManage) {
		return nil, ErrPermissionDenied
	}
	target, err := u.staffWithRoles(ctx, staffID)
	if err != nil {
		return nil, err
	}
	if target == nil {
		return nil, ErrStaffNotFound
	}
	return target, nil
}

func (u *StaffUseCase) ResolveStaffDisplayName(ctx context.Context, actor *model.StaffUser, staffID uuid.UUID) (string, error) {
	contact, err := u.ResolveStaffDisplayContact(ctx, actor, staffID)
	if err != nil {
		return "", err
	}
	if displayName := strings.TrimSpace(contact.DisplayName); displayName != "" {
		return displayName, nil
	}
	return strings.TrimSpace(contact.Email), nil
}

func (u *StaffUseCase) ResolveStaffDisplayContact(ctx context.Context, actor *model.StaffUser, staffID uuid.UUID) (StaffDisplayContact, error) {
	if actor == nil || !canReadStaffDisplayName(actor) {
		return StaffDisplayContact{}, ErrPermissionDenied
	}
	if u == nil || u.staff == nil {
		return StaffDisplayContact{}, ErrIntegrationNotReady
	}
	if staffID == uuid.Nil {
		return StaffDisplayContact{}, ErrInvalidInput
	}
	target, err := u.staff.GetByID(ctx, staffID)
	if err != nil {
		return StaffDisplayContact{}, err
	}
	if target == nil {
		return StaffDisplayContact{}, ErrStaffNotFound
	}
	return StaffDisplayContact{
		DisplayName: strings.TrimSpace(target.DisplayName),
		Email:       strings.TrimSpace(target.Email),
	}, nil
}

func (u *StaffUseCase) CreateStaff(ctx context.Context, actor *model.StaffUser, input CreateStaffInput) (*CreateStaffResult, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionStaffManage) {
		return nil, ErrPermissionDenied
	}
	roles, err := normalizeRoles(input.Roles)
	if err != nil {
		return nil, err
	}
	if err = ensureAssignableRoles(actor, roles); err != nil {
		return nil, err
	}
	email := strings.ToLower(strings.TrimSpace(input.Email))
	if email == "" || !strings.Contains(email, "@") {
		return nil, ErrInvalidInput
	}
	tempPassword, err := GenerateTemporaryPassword()
	if err != nil {
		return nil, err
	}
	passwordHash, err := HashPassword(tempPassword)
	if err != nil {
		return nil, err
	}
	now := time.Now().UTC()
	createdBy := actor.ID
	staffUser := &model.StaffUser{
		ID:               uuid.New(),
		Email:            email,
		DisplayName:      strings.TrimSpace(input.DisplayName),
		Status:           enum.StaffStatusPasswordResetRequired,
		Timezone:         model.DefaultStaffTimezone,
		CreatedByStaffID: &createdBy,
		CreatedAt:        now,
		UpdatedAt:        now,
		Roles:            roles,
	}
	if staffUser.DisplayName == "" {
		staffUser.DisplayName = email
	}
	if err = u.staff.Create(ctx, staffUser, passwordHash, staffUser.Roles); err != nil {
		return nil, err
	}
	if u.audit != nil {
		_ = u.audit.Append(ctx, &model.AuditEvent{
			ID:            uuid.New(),
			ActorStaffID:  &actor.ID,
			Action:        "staff.created",
			EntityType:    "staff_user",
			EntityID:      &staffUser.ID,
			RequestID:     input.Metadata.RequestID,
			IPAddressHash: HashPassiveIdentifier(input.Metadata.IPAddress),
			UserAgentHash: HashPassiveIdentifier(input.Metadata.UserAgent),
			AfterJSON:     auditJSON(staffAuditSnapshot(staffUser)),
			CreatedAt:     now,
		})
	}
	return &CreateStaffResult{Staff: staffUser, TemporaryPassword: tempPassword}, nil
}

func (u *StaffUseCase) UpdateStaffProfile(ctx context.Context, actor *model.StaffUser, input UpdateStaffProfileInput) error {
	if actor == nil || !actor.HasPermission(enum.PermissionStaffManage) {
		return ErrPermissionDenied
	}
	target, err := u.staffWithRoles(ctx, input.StaffID)
	if err != nil {
		return err
	}
	if target == nil {
		return ErrStaffNotFound
	}
	roles, err := normalizeRoles(input.Roles)
	if err != nil {
		return err
	}
	if actor.ID == target.ID {
		if !actor.HasRole(enum.StaffRoleSuperAdmin) {
			return ErrPermissionDenied
		}
		if !hasRole(roles, enum.StaffRoleSuperAdmin) {
			return ErrPermissionDenied
		}
	} else {
		if err = ensureCanManageTarget(actor, target); err != nil {
			return err
		}
	}
	if err = ensureAssignableRoles(actor, roles); err != nil {
		return err
	}
	displayName := strings.TrimSpace(input.DisplayName)
	if displayName == "" {
		return ErrInvalidInput
	}
	before := staffAuditSnapshot(target)
	now := time.Now().UTC()
	if err = u.staff.UpdateProfileAndRoles(ctx, target.ID, displayName, roles, actor.ID, now); err != nil {
		return err
	}
	after := staffAuditPayload{
		ID:          target.ID,
		Email:       target.Email,
		DisplayName: displayName,
		Status:      target.Status,
		Timezone:    target.EffectiveTimezone(),
		Roles:       roles,
	}
	u.appendStaffAudit(ctx, actor, "staff.updated", target.ID, input.Metadata, before, after, nil, now)
	return nil
}

func (u *StaffUseCase) UpdateOwnTimezone(ctx context.Context, actor *model.StaffUser, input UpdateOwnTimezoneInput) error {
	if actor == nil {
		return ErrPermissionDenied
	}
	timezone, err := normalizeStaffTimezone(input.Timezone)
	if err != nil {
		return err
	}
	target, err := u.staffWithRoles(ctx, actor.ID)
	if err != nil {
		return err
	}
	if target == nil {
		return ErrStaffNotFound
	}
	before := staffAuditSnapshot(target)
	now := time.Now().UTC()
	if err = u.staff.UpdateTimezone(ctx, target.ID, timezone, now); err != nil {
		return err
	}
	after := staffAuditPayload{
		ID:          target.ID,
		Email:       target.Email,
		DisplayName: target.DisplayName,
		Status:      target.Status,
		Timezone:    timezone,
		Roles:       target.Roles,
	}
	u.appendStaffAudit(ctx, actor, "staff.timezone.updated", target.ID, input.Metadata, before, after, nil, now)
	return nil
}

func (u *StaffUseCase) ChangeStaffStatus(ctx context.Context, actor *model.StaffUser, input ChangeStaffStatusInput) error {
	if actor == nil || !actor.HasPermission(enum.PermissionStaffManage) {
		return ErrPermissionDenied
	}
	reason := strings.TrimSpace(input.Reason)
	if reason == "" || !input.Status.IsValid() {
		return ErrInvalidInput
	}
	target, err := u.staffWithRoles(ctx, input.StaffID)
	if err != nil {
		return err
	}
	if target == nil {
		return ErrStaffNotFound
	}
	if err = ensureCanManageTarget(actor, target); err != nil {
		return err
	}
	before := staffAuditSnapshot(target)
	now := time.Now().UTC()
	if err = u.staff.SetStatus(ctx, target.ID, input.Status, now); err != nil {
		return err
	}
	if input.Status != enum.StaffStatusActive && u.sessions != nil {
		_ = u.sessions.RevokeAllForStaff(ctx, target.ID, now)
	}
	after := staffAuditPayload{
		ID:          target.ID,
		Email:       target.Email,
		DisplayName: target.DisplayName,
		Status:      input.Status,
		Timezone:    target.EffectiveTimezone(),
		Roles:       target.Roles,
	}
	u.appendStaffAudit(ctx, actor, "staff.status.changed", target.ID, input.Metadata, before, after, map[string]any{"reason": reason}, now)
	return nil
}

func (u *StaffUseCase) RegenerateStaffPassword(ctx context.Context, actor *model.StaffUser, input RegenerateStaffPasswordInput) (*RegenerateStaffPasswordResult, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionStaffManage) {
		return nil, ErrPermissionDenied
	}
	target, err := u.staffWithRoles(ctx, input.StaffID)
	if err != nil {
		return nil, err
	}
	if target == nil {
		return nil, ErrStaffNotFound
	}
	if err = ensureCanManageTarget(actor, target); err != nil {
		return nil, err
	}
	tempPassword, err := GenerateTemporaryPassword()
	if err != nil {
		return nil, err
	}
	passwordHash, err := HashPassword(tempPassword)
	if err != nil {
		return nil, err
	}
	before := staffAuditSnapshot(target)
	now := time.Now().UTC()
	if err = u.staff.UpdatePassword(ctx, target.ID, passwordHash, enum.StaffStatusPasswordResetRequired, now); err != nil {
		return nil, err
	}
	if u.sessions != nil {
		_ = u.sessions.RevokeAllForStaff(ctx, target.ID, now)
	}
	after := staffAuditPayload{
		ID:          target.ID,
		Email:       target.Email,
		DisplayName: target.DisplayName,
		Status:      enum.StaffStatusPasswordResetRequired,
		Timezone:    target.EffectiveTimezone(),
		Roles:       target.Roles,
	}
	u.appendStaffAudit(ctx, actor, "staff.password.regenerated", target.ID, input.Metadata, before, after, nil, now)
	return &RegenerateStaffPasswordResult{TemporaryPassword: tempPassword}, nil
}

func (u *StaffUseCase) BootstrapSuperAdmin(ctx context.Context, input BootstrapSuperAdminInput) (bool, error) {
	email := strings.ToLower(strings.TrimSpace(input.Email))
	if email == "" {
		return false, nil
	}
	existing, err := u.staff.GetByEmail(ctx, email)
	if err != nil {
		return false, err
	}
	if existing != nil {
		return false, nil
	}
	passwordHash, err := HashPassword(input.Password)
	if err != nil {
		return false, err
	}
	now := time.Now().UTC()
	displayName := strings.TrimSpace(input.DisplayName)
	if displayName == "" {
		displayName = email
	}
	staffUser := &model.StaffUser{
		ID:          uuid.New(),
		Email:       email,
		DisplayName: displayName,
		Status:      enum.StaffStatusPasswordResetRequired,
		Timezone:    model.DefaultStaffTimezone,
		CreatedAt:   now,
		UpdatedAt:   now,
		Roles:       []enum.StaffRole{enum.StaffRoleSuperAdmin},
	}
	if err = u.staff.Create(ctx, staffUser, passwordHash, staffUser.Roles); err != nil {
		return false, err
	}
	if u.audit != nil {
		_ = u.audit.Append(ctx, &model.AuditEvent{
			ID:            uuid.New(),
			Action:        "staff.bootstrap_super_admin.created",
			EntityType:    "staff_user",
			EntityID:      &staffUser.ID,
			RequestID:     input.Metadata.RequestID,
			IPAddressHash: HashPassiveIdentifier(input.Metadata.IPAddress),
			UserAgentHash: HashPassiveIdentifier(input.Metadata.UserAgent),
			CreatedAt:     now,
		})
	}
	return true, nil
}

func (u *StaffUseCase) staffWithRoles(ctx context.Context, staffID uuid.UUID) (*model.StaffUser, error) {
	if staffID == uuid.Nil {
		return nil, ErrInvalidInput
	}
	target, err := u.staff.GetByID(ctx, staffID)
	if err != nil || target == nil {
		return target, err
	}
	permissions, roles, err := u.staff.GetPermissions(ctx, target.ID)
	if err != nil {
		return nil, err
	}
	target.Permissions = permissions
	target.Roles = roles
	return target, nil
}

func (u *StaffUseCase) staffWithPermissions(ctx context.Context, staff *model.StaffUser) (*model.StaffUser, error) {
	if staff == nil || staff.ID == uuid.Nil {
		return staff, nil
	}
	permissions, roles, err := u.staff.GetPermissions(ctx, staff.ID)
	if err != nil {
		return nil, err
	}
	enriched := *staff
	enriched.Permissions = mergeStaffPermissions(enriched.Permissions, permissions)
	enriched.Roles = mergeStaffRoles(enriched.Roles, roles)
	return &enriched, nil
}

func mergeStaffPermissions(base []enum.Permission, extra []enum.Permission) []enum.Permission {
	seen := make(map[enum.Permission]struct{}, len(base)+len(extra))
	out := make([]enum.Permission, 0, len(base)+len(extra))
	for _, permission := range base {
		if permission == "" {
			continue
		}
		if _, ok := seen[permission]; ok {
			continue
		}
		seen[permission] = struct{}{}
		out = append(out, permission)
	}
	for _, permission := range extra {
		if permission == "" {
			continue
		}
		if _, ok := seen[permission]; ok {
			continue
		}
		seen[permission] = struct{}{}
		out = append(out, permission)
	}
	return out
}

func mergeStaffRoles(base []enum.StaffRole, extra []enum.StaffRole) []enum.StaffRole {
	seen := make(map[enum.StaffRole]struct{}, len(base)+len(extra))
	out := make([]enum.StaffRole, 0, len(base)+len(extra))
	for _, role := range base {
		if role == "" {
			continue
		}
		if _, ok := seen[role]; ok {
			continue
		}
		seen[role] = struct{}{}
		out = append(out, role)
	}
	for _, role := range extra {
		if role == "" {
			continue
		}
		if _, ok := seen[role]; ok {
			continue
		}
		seen[role] = struct{}{}
		out = append(out, role)
	}
	return out
}

func normalizeRoles(input []enum.StaffRole) ([]enum.StaffRole, error) {
	seen := make(map[enum.StaffRole]struct{}, len(input))
	out := make([]enum.StaffRole, 0, len(input))
	for _, role := range input {
		role = enum.StaffRole(strings.ToUpper(strings.TrimSpace(string(role))))
		if role == "" {
			continue
		}
		if !role.IsValid() {
			return nil, ErrInvalidInput
		}
		if _, ok := seen[role]; ok {
			continue
		}
		seen[role] = struct{}{}
		out = append(out, role)
	}
	if len(out) == 0 {
		out = append(out, enum.StaffRoleSupportViewer)
	}
	return out, nil
}

func ensureCanManageTarget(actor *model.StaffUser, target *model.StaffUser) error {
	if actor == nil || target == nil {
		return ErrPermissionDenied
	}
	if actor.ID == target.ID {
		return ErrPermissionDenied
	}
	if target.HasRole(enum.StaffRoleSuperAdmin) && !actor.HasRole(enum.StaffRoleSuperAdmin) {
		return ErrPermissionDenied
	}
	return nil
}

func ensureAssignableRoles(actor *model.StaffUser, roles []enum.StaffRole) error {
	if actor == nil {
		return ErrPermissionDenied
	}
	if actor.HasRole(enum.StaffRoleSuperAdmin) {
		return nil
	}
	for _, role := range roles {
		if role == enum.StaffRoleSuperAdmin {
			return ErrPermissionDenied
		}
	}
	return nil
}

func hasRole(roles []enum.StaffRole, expected enum.StaffRole) bool {
	for _, role := range roles {
		if role == expected {
			return true
		}
	}
	return false
}

func normalizeStaffTimezone(input string) (string, error) {
	timezone := strings.TrimSpace(input)
	if timezone == "" || timezone == "Local" {
		return "", ErrInvalidInput
	}
	if _, err := time.LoadLocation(timezone); err != nil {
		return "", ErrInvalidInput
	}
	return timezone, nil
}

func sameStaffRoleSet(left []enum.StaffRole, right []enum.StaffRole) bool {
	if len(left) != len(right) {
		return false
	}
	seen := make(map[enum.StaffRole]int, len(left))
	for _, role := range left {
		seen[role]++
	}
	for _, role := range right {
		if seen[role] == 0 {
			return false
		}
		seen[role]--
	}
	return true
}

type staffAuditPayload struct {
	ID          uuid.UUID        `json:"id"`
	Email       string           `json:"email"`
	DisplayName string           `json:"displayName"`
	Status      enum.StaffStatus `json:"status"`
	Timezone    string           `json:"timezone"`
	Roles       []enum.StaffRole `json:"roles"`
}

func staffAuditSnapshot(staff *model.StaffUser) staffAuditPayload {
	if staff == nil {
		return staffAuditPayload{}
	}
	return staffAuditPayload{
		ID:          staff.ID,
		Email:       staff.Email,
		DisplayName: staff.DisplayName,
		Status:      staff.Status,
		Timezone:    staff.EffectiveTimezone(),
		Roles:       append([]enum.StaffRole(nil), staff.Roles...),
	}
}

func (u *StaffUseCase) appendStaffAudit(
	ctx context.Context,
	actor *model.StaffUser,
	action string,
	entityID uuid.UUID,
	meta RequestMetadata,
	before any,
	after any,
	metadata any,
	now time.Time,
) {
	if u.audit == nil || actor == nil {
		return
	}
	_ = u.audit.Append(ctx, &model.AuditEvent{
		ID:            uuid.New(),
		ActorStaffID:  &actor.ID,
		Action:        action,
		EntityType:    "staff_user",
		EntityID:      &entityID,
		RequestID:     meta.RequestID,
		IPAddressHash: HashPassiveIdentifier(meta.IPAddress),
		UserAgentHash: HashPassiveIdentifier(meta.UserAgent),
		BeforeJSON:    auditJSON(before),
		AfterJSON:     auditJSON(after),
		Metadata:      auditJSON(metadata),
		CreatedAt:     now,
	})
}

func auditJSON(value any) json.RawMessage {
	if value == nil {
		return nil
	}
	raw, err := json.Marshal(value)
	if err != nil {
		return nil
	}
	return raw
}

func clampLimit(limit int) int {
	if limit <= 0 {
		return 50
	}
	if limit > 200 {
		return 200
	}
	return limit
}

func normalizeOffset(offset int) int {
	if offset < 0 {
		return 0
	}
	return offset
}
