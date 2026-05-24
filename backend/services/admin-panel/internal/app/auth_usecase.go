package app

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/port"
)

type RequestMetadata struct {
	RequestID string
	IPAddress string
	UserAgent string
}

type AuthUseCase struct {
	staff            port.StaffRepository
	sessions         port.SessionRepository
	loginAttempts    port.LoginAttemptRepository
	audit            port.AuditRepository
	idleTimeout      time.Duration
	absoluteTimeout  time.Duration
	loginWindow      time.Duration
	maxLoginFailures int
}

type AuthConfig struct {
	IdleTimeout      time.Duration
	AbsoluteTimeout  time.Duration
	LoginWindow      time.Duration
	MaxLoginFailures int
}

type LoginResult struct {
	Staff        *model.StaffUser
	Session      *model.StaffSession
	SessionToken string
	CSRFToken    string
}

func NewAuthUseCase(
	staff port.StaffRepository,
	sessions port.SessionRepository,
	loginAttempts port.LoginAttemptRepository,
	audit port.AuditRepository,
	cfg AuthConfig,
) *AuthUseCase {
	if cfg.IdleTimeout <= 0 {
		cfg.IdleTimeout = 30 * time.Minute
	}
	if cfg.AbsoluteTimeout <= cfg.IdleTimeout {
		cfg.AbsoluteTimeout = 12 * time.Hour
	}
	if cfg.LoginWindow <= 0 {
		cfg.LoginWindow = 15 * time.Minute
	}
	if cfg.MaxLoginFailures <= 0 {
		cfg.MaxLoginFailures = 8
	}
	return &AuthUseCase{
		staff:            staff,
		sessions:         sessions,
		loginAttempts:    loginAttempts,
		audit:            audit,
		idleTimeout:      cfg.IdleTimeout,
		absoluteTimeout:  cfg.AbsoluteTimeout,
		loginWindow:      cfg.LoginWindow,
		maxLoginFailures: cfg.MaxLoginFailures,
	}
}

func (u *AuthUseCase) Login(
	ctx context.Context,
	email string,
	password string,
	meta RequestMetadata,
) (*LoginResult, error) {
	now := time.Now().UTC()
	normalizedEmail := strings.ToLower(strings.TrimSpace(email))
	emailHash := HashPassiveIdentifier(normalizedEmail)
	ipAddressHash := HashPassiveIdentifier(meta.IPAddress)
	if u.loginAttempts != nil {
		failures, err := u.loginAttempts.CountFailuresSince(ctx, emailHash, ipAddressHash, now.Add(-u.loginWindow))
		if err != nil {
			return nil, err
		}
		if failures >= u.maxLoginFailures {
			u.recordLoginAttempt(ctx, emailHash, ipAddressHash, false, "rate_limited", now)
			u.appendAudit(ctx, nil, "admin.login.denied_rate_limited", "staff_user", nil, meta, map[string]any{"emailHash": emailHash})
			return nil, ErrStaffLocked
		}
	}
	staffUser, err := u.staff.GetByEmail(ctx, normalizedEmail)
	if err != nil {
		return nil, err
	}
	if staffUser == nil {
		u.recordLoginAttempt(ctx, emailHash, ipAddressHash, false, "unknown_email", now)
		u.appendAudit(ctx, nil, "admin.login.failed", "staff_user", nil, meta, map[string]any{"emailHash": emailHash})
		return nil, ErrInvalidCredentials
	}
	if staffUser.IsDisabled() {
		u.recordLoginAttempt(ctx, emailHash, ipAddressHash, false, "disabled", now)
		u.appendAudit(ctx, &staffUser.ID, "admin.login.denied_disabled", "staff_user", &staffUser.ID, meta, nil)
		return nil, ErrStaffDisabled
	}
	if staffUser.IsLocked(now) {
		u.recordLoginAttempt(ctx, emailHash, ipAddressHash, false, "locked", now)
		u.appendAudit(ctx, &staffUser.ID, "admin.login.denied_locked", "staff_user", &staffUser.ID, meta, nil)
		return nil, ErrStaffLocked
	}
	if !VerifyPassword(staffUser.PasswordHash, password) {
		failedCount := staffUser.FailedLoginCount + 1
		var lockedUntil *time.Time
		if failedCount >= u.maxLoginFailures {
			value := now.Add(u.loginWindow)
			lockedUntil = &value
		}
		if err = u.staff.UpdateLoginFailure(ctx, staffUser.ID, failedCount, lockedUntil); err != nil {
			return nil, err
		}
		u.recordLoginAttempt(ctx, emailHash, ipAddressHash, false, "invalid_password", now)
		u.appendAudit(ctx, &staffUser.ID, "admin.login.failed", "staff_user", &staffUser.ID, meta, map[string]any{"failedCount": failedCount})
		return nil, ErrInvalidCredentials
	}
	permissions, roles, err := u.staff.GetPermissions(ctx, staffUser.ID)
	if err != nil {
		return nil, err
	}
	staffUser.Permissions = permissions
	staffUser.Roles = roles

	sessionToken, err := GenerateOpaqueToken()
	if err != nil {
		return nil, err
	}
	csrfToken, err := GenerateOpaqueToken()
	if err != nil {
		return nil, err
	}
	session := &model.StaffSession{
		ID:              uuid.New(),
		StaffUserID:     staffUser.ID,
		SessionHash:     HashToken(sessionToken),
		CSRFTokenHash:   HashToken(csrfToken),
		IPAddressHash:   HashPassiveIdentifier(meta.IPAddress),
		UserAgentHash:   HashPassiveIdentifier(meta.UserAgent),
		CreatedAt:       now,
		LastSeenAt:      now,
		ExpiresAt:       now.Add(u.idleTimeout),
		AbsoluteExpires: now.Add(u.absoluteTimeout),
	}
	if err = u.sessions.Create(ctx, session); err != nil {
		return nil, err
	}
	if err = u.staff.UpdateLoginSuccess(ctx, staffUser.ID, now); err != nil {
		return nil, err
	}
	u.recordLoginAttempt(ctx, emailHash, ipAddressHash, true, "", now)
	u.appendAudit(ctx, &staffUser.ID, "admin.login.succeeded", "staff_user", &staffUser.ID, meta, nil)
	return &LoginResult{
		Staff:        staffUser,
		Session:      session,
		SessionToken: sessionToken,
		CSRFToken:    csrfToken,
	}, nil
}

func (u *AuthUseCase) recordLoginAttempt(ctx context.Context, emailHash string, ipAddressHash string, success bool, failureReason string, now time.Time) {
	if u.loginAttempts == nil {
		return
	}
	_ = u.loginAttempts.Append(ctx, &model.StaffLoginAttempt{
		ID:            uuid.New(),
		EmailHash:     emailHash,
		IPAddressHash: ipAddressHash,
		Success:       success,
		FailureReason: strings.TrimSpace(failureReason),
		CreatedAt:     now,
	})
}

func (u *AuthUseCase) AuthenticateSession(
	ctx context.Context,
	sessionToken string,
) (*model.StaffUser, *model.StaffSession, error) {
	now := time.Now().UTC()
	sessionHash := HashToken(sessionToken)
	session, err := u.sessions.GetBySessionHash(ctx, sessionHash)
	if err != nil {
		return nil, nil, err
	}
	if session == nil || !session.IsActive(now) {
		return nil, nil, ErrSessionNotFound
	}
	staffUser, err := u.staff.GetByID(ctx, session.StaffUserID)
	if err != nil {
		return nil, nil, err
	}
	if staffUser == nil || staffUser.IsDisabled() || staffUser.IsLocked(now) {
		_ = u.sessions.Revoke(ctx, session.ID, now)
		return nil, nil, ErrSessionNotFound
	}
	permissions, roles, err := u.staff.GetPermissions(ctx, staffUser.ID)
	if err != nil {
		return nil, nil, err
	}
	staffUser.Permissions = permissions
	staffUser.Roles = roles
	nextExpiry := now.Add(u.idleTimeout)
	if nextExpiry.After(session.AbsoluteExpires) {
		nextExpiry = session.AbsoluteExpires
	}
	_ = u.sessions.Touch(ctx, session.ID, nextExpiry, now)
	session.ExpiresAt = nextExpiry
	session.LastSeenAt = now
	return staffUser, session, nil
}

func (u *AuthUseCase) ValidateCSRF(session *model.StaffSession, token string) bool {
	return session != nil &&
		strings.TrimSpace(token) != "" &&
		HashToken(token) == session.CSRFTokenHash
}

func (u *AuthUseCase) Logout(ctx context.Context, sessionID uuid.UUID, actorID uuid.UUID, meta RequestMetadata) error {
	now := time.Now().UTC()
	if err := u.sessions.Revoke(ctx, sessionID, now); err != nil && !errors.Is(err, ErrSessionNotFound) {
		return err
	}
	u.appendAudit(ctx, &actorID, "admin.logout", "staff_session", &sessionID, meta, nil)
	return nil
}

func (u *AuthUseCase) ChangePassword(ctx context.Context, staffID uuid.UUID, currentPassword string, newPassword string, requireCurrentPassword bool, meta RequestMetadata) error {
	now := time.Now().UTC()
	if requireCurrentPassword {
		staffUser, err := u.staff.GetByID(ctx, staffID)
		if err != nil {
			return err
		}
		if staffUser == nil || !VerifyPassword(staffUser.PasswordHash, currentPassword) {
			u.appendAudit(ctx, &staffID, "staff.password.change_denied", "staff_user", &staffID, meta, nil)
			return ErrInvalidCredentials
		}
	}
	hash, err := HashPassword(newPassword)
	if err != nil {
		return err
	}
	if err = u.staff.UpdatePassword(ctx, staffID, hash, enum.StaffStatusActive, now); err != nil {
		return err
	}
	if err = u.sessions.RevokeAllForStaff(ctx, staffID, now); err != nil {
		return err
	}
	u.appendAudit(ctx, &staffID, "staff.password.changed", "staff_user", &staffID, meta, nil)
	return nil
}

func (u *AuthUseCase) appendAudit(
	ctx context.Context,
	actorID *uuid.UUID,
	action string,
	entityType string,
	entityID *uuid.UUID,
	meta RequestMetadata,
	metadata map[string]any,
) {
	if u.audit == nil {
		return
	}
	var metadataJSON []byte
	if metadata != nil {
		metadataJSON, _ = json.Marshal(metadata)
	}
	_ = u.audit.Append(ctx, &model.AuditEvent{
		ID:            uuid.New(),
		ActorStaffID:  actorID,
		Action:        action,
		EntityType:    entityType,
		EntityID:      entityID,
		RequestID:     strings.TrimSpace(meta.RequestID),
		IPAddressHash: HashPassiveIdentifier(meta.IPAddress),
		UserAgentHash: HashPassiveIdentifier(meta.UserAgent),
		Metadata:      metadataJSON,
		CreatedAt:     time.Now().UTC(),
	})
}
