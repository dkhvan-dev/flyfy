package model

import (
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/enum"
)

type StaffUser struct {
	ID                uuid.UUID
	Email             string
	DisplayName       string
	PasswordHash      string
	Status            enum.StaffStatus
	FailedLoginCount  int
	LockedUntil       *time.Time
	LastLoginAt       *time.Time
	PasswordChangedAt *time.Time
	CreatedByStaffID  *uuid.UUID
	CreatedAt         time.Time
	UpdatedAt         time.Time
	DisabledAt        *time.Time
	Roles             []enum.StaffRole
	Permissions       []enum.Permission
}

func (u StaffUser) NormalizedEmail() string {
	return strings.ToLower(strings.TrimSpace(u.Email))
}

func (u StaffUser) IsDisabled() bool {
	return u.Status == enum.StaffStatusDisabled
}

func (u StaffUser) IsLocked(now time.Time) bool {
	if u.LockedUntil != nil {
		return now.Before(*u.LockedUntil)
	}
	return u.Status == enum.StaffStatusLocked
}

func (u StaffUser) RequiresPasswordChange() bool {
	return u.Status == enum.StaffStatusPasswordResetRequired || u.PasswordChangedAt == nil
}

func (u StaffUser) HasPermission(permission enum.Permission) bool {
	for _, candidate := range u.Permissions {
		if candidate == permission {
			return true
		}
	}
	return false
}

func (u StaffUser) HasRole(role enum.StaffRole) bool {
	for _, candidate := range u.Roles {
		if candidate == role {
			return true
		}
	}
	return false
}

type StaffSession struct {
	ID              uuid.UUID
	StaffUserID     uuid.UUID
	SessionHash     string
	CSRFTokenHash   string
	IPAddressHash   string
	UserAgentHash   string
	CreatedAt       time.Time
	LastSeenAt      time.Time
	ExpiresAt       time.Time
	RevokedAt       *time.Time
	AbsoluteExpires time.Time
}

func (s StaffSession) IsActive(now time.Time) bool {
	return s.RevokedAt == nil && now.Before(s.ExpiresAt) && now.Before(s.AbsoluteExpires)
}

type StaffLoginAttempt struct {
	ID            uuid.UUID
	EmailHash     string
	IPAddressHash string
	Success       bool
	FailureReason string
	CreatedAt     time.Time
}

type BootstrapToken struct {
	ID            uuid.UUID
	StaffUserID   uuid.UUID
	TokenHash     string
	CreatedBy     uuid.UUID
	CreatedAt     time.Time
	ExpiresAt     time.Time
	UsedAt        *time.Time
	GeneratedOnce string
}
