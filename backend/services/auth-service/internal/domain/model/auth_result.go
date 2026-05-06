package model

import "time"

type AuthResult struct {
	AccessToken      string    `json:"access_token"`
	RefreshToken     string    `json:"refresh_token"`
	TokenType        string    `json:"token_type,omitempty"`
	ExpiresAt        time.Time `json:"expires_at,omitempty"`
	RefreshExpiresAt time.Time `json:"refresh_expires_at,omitempty"`
	SessionID        string    `json:"session_id,omitempty"`
	IsNewUser        bool      `json:"is_new_user"`
	PrimaryPhoneHint *string   `json:"primary_phone_hint,omitempty"`
	PrimaryEmailHint *string   `json:"primary_email_hint,omitempty"`
}

// DeviceInfo describes the client device. Mirrors token-service's DeviceInfo
// at the auth-service boundary so auth-service stays decoupled from tokenpb types.
type DeviceInfo struct {
	DeviceID   string
	Platform   string
	OSVersion  string
	AppVersion string
	Model      string
	UserAgent  string
	IPAddress  string
}
