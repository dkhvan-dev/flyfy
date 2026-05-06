package model

import (
	"time"

	"github.com/google/uuid"
)

// Session lifecycle event names (audit log).
const (
	SessionEventCreated            = "created"
	SessionEventReplaced           = "replaced"
	SessionEventRefreshed          = "refreshed"
	SessionEventLogout             = "logout"
	SessionEventTokenReuseDetected = "token_reuse_detected"
	SessionEventAdminRevoke        = "admin_revoke"
	SessionEventInactivityExpired  = "inactivity_expired"
)

// Session revoke reasons (stored in user_sessions.revoke_reason).
const (
	RevokeReasonNewLogin          = "new_login"
	RevokeReasonUserLogout        = "user_logout"
	RevokeReasonTokenReuse        = "token_reuse"
	RevokeReasonAdmin             = "admin"
	RevokeReasonInactivityExpired = "inactivity_expired"
)

// DeviceInfo describes the client device that owns a session.
// All fields are optional and supplied by the caller (auth-service / gateway).
type DeviceInfo struct {
	DeviceID   string
	Platform   string
	OSVersion  string
	AppVersion string
	Model      string
	UserAgent  string
	IPAddress  string
}

// UserSession represents one active session for a user.
// At most one non-revoked session per user_id is allowed (DB-enforced).
type UserSession struct {
	ID     uuid.UUID
	UserID uuid.UUID

	RefreshJTI       string
	RefreshTokenHash string
	RefreshIssuedAt  time.Time
	RefreshExpiresAt time.Time

	Device DeviceInfo

	CreatedAt       time.Time
	LastUsedAt      time.Time
	LastRefreshedAt *time.Time

	RevokedAt    *time.Time
	RevokeReason string
}

// IsActive reports whether the session is currently valid (not revoked).
func (s *UserSession) IsActive() bool {
	return s != nil && s.RevokedAt == nil
}
