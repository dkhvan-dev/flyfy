package app

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"strings"
	"time"

	"github.com/google/uuid"
)

const (
	attendanceQRPrefix   = "ffatt1"
	attendanceQRAudience = "activity-attendance-check-in"
	attendanceQRVersion  = 1
)

type attendanceQRClaims struct {
	Version    int    `json:"v"`
	Audience   string `json:"aud"`
	ActivityID string `json:"activityId"`
	HostUserID string `json:"hostId"`
	JTI        string `json:"jti"`
	IssuedAt   int64  `json:"iat"`
	ExpiresAt  int64  `json:"exp"`
}

type decodedAttendanceQR struct {
	ActivityID uuid.UUID
	HostUserID uuid.UUID
	JTI        uuid.UUID
	IssuedAt   time.Time
	ExpiresAt  time.Time
}

func signAttendanceQRToken(
	secret []byte,
	activityID uuid.UUID,
	hostUserID uuid.UUID,
	jti uuid.UUID,
	issuedAt time.Time,
	expiresAt time.Time,
) (string, error) {
	claims := attendanceQRClaims{
		Version:    attendanceQRVersion,
		Audience:   attendanceQRAudience,
		ActivityID: activityID.String(),
		HostUserID: hostUserID.String(),
		JTI:        jti.String(),
		IssuedAt:   issuedAt.UTC().Unix(),
		ExpiresAt:  expiresAt.UTC().Unix(),
	}

	payload, err := json.Marshal(claims)
	if err != nil {
		return "", err
	}

	payloadPart := base64.RawURLEncoding.EncodeToString(payload)
	signaturePart := signAttendanceQRPayload(secret, payloadPart)
	return attendanceQRPrefix + "." + payloadPart + "." + signaturePart, nil
}

func decodeAndVerifyAttendanceQR(secret []byte, token string) (*decodedAttendanceQR, error) {
	parts := strings.Split(strings.TrimSpace(token), ".")
	if len(parts) != 3 || parts[0] != attendanceQRPrefix {
		return nil, ErrAttendanceQRInvalid
	}

	expectedSignature := signAttendanceQRPayload(secret, parts[1])
	if !hmac.Equal([]byte(expectedSignature), []byte(parts[2])) {
		return nil, ErrAttendanceQRInvalid
	}

	payload, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return nil, ErrAttendanceQRInvalid
	}

	var claims attendanceQRClaims
	if err = json.Unmarshal(payload, &claims); err != nil {
		return nil, ErrAttendanceQRInvalid
	}
	if claims.Version != attendanceQRVersion {
		return nil, ErrAttendanceQRVersionInvalid
	}
	if claims.Audience != attendanceQRAudience {
		return nil, ErrAttendanceQRInvalid
	}
	if claims.ExpiresAt <= claims.IssuedAt {
		return nil, ErrAttendanceQRInvalid
	}

	activityID, err := uuid.Parse(claims.ActivityID)
	if err != nil {
		return nil, ErrAttendanceQRInvalid
	}
	hostUserID, err := uuid.Parse(claims.HostUserID)
	if err != nil {
		return nil, ErrAttendanceQRInvalid
	}
	jti, err := uuid.Parse(claims.JTI)
	if err != nil {
		return nil, ErrAttendanceQRInvalid
	}

	return &decodedAttendanceQR{
		ActivityID: activityID,
		HostUserID: hostUserID,
		JTI:        jti,
		IssuedAt:   time.Unix(claims.IssuedAt, 0).UTC(),
		ExpiresAt:  time.Unix(claims.ExpiresAt, 0).UTC(),
	}, nil
}

func signAttendanceQRPayload(secret []byte, payloadPart string) string {
	mac := hmac.New(sha256.New, secret)
	_, _ = mac.Write([]byte(payloadPart))
	return base64.RawURLEncoding.EncodeToString(mac.Sum(nil))
}
