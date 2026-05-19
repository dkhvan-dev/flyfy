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
	excursionAttendanceQRPrefix   = "ffexatt1"
	excursionAttendanceQRAudience = "excursion-attendance-check-in"
	excursionAttendanceQRVersion  = 1
)

type excursionAttendanceQRClaims struct {
	Version        int    `json:"v"`
	Audience       string `json:"aud"`
	ScheduleSlotID string `json:"slotId"`
	GuideUserID    string `json:"guideId"`
	JTI            string `json:"jti"`
	IssuedAt       int64  `json:"iat"`
	ExpiresAt      int64  `json:"exp"`
}

type decodedExcursionAttendanceQR struct {
	ScheduleSlotID uuid.UUID
	GuideUserID    uuid.UUID
	JTI            uuid.UUID
	IssuedAt       time.Time
	ExpiresAt      time.Time
}

func signExcursionAttendanceQRToken(
	secret []byte,
	scheduleSlotID uuid.UUID,
	guideUserID uuid.UUID,
	jti uuid.UUID,
	issuedAt time.Time,
	expiresAt time.Time,
) (string, error) {
	claims := excursionAttendanceQRClaims{
		Version:        excursionAttendanceQRVersion,
		Audience:       excursionAttendanceQRAudience,
		ScheduleSlotID: scheduleSlotID.String(),
		GuideUserID:    guideUserID.String(),
		JTI:            jti.String(),
		IssuedAt:       issuedAt.UTC().Unix(),
		ExpiresAt:      expiresAt.UTC().Unix(),
	}
	payload, err := json.Marshal(claims)
	if err != nil {
		return "", err
	}
	payloadPart := base64.RawURLEncoding.EncodeToString(payload)
	signaturePart := signExcursionAttendanceQRPayload(secret, payloadPart)
	return excursionAttendanceQRPrefix + "." + payloadPart + "." + signaturePart, nil
}

func decodeAndVerifyExcursionAttendanceQR(secret []byte, token string) (*decodedExcursionAttendanceQR, error) {
	parts := strings.Split(strings.TrimSpace(token), ".")
	if len(parts) != 3 || parts[0] != excursionAttendanceQRPrefix {
		return nil, ErrExcursionAttendanceQRInvalid
	}

	expectedSignature := signExcursionAttendanceQRPayload(secret, parts[1])
	if !hmac.Equal([]byte(expectedSignature), []byte(parts[2])) {
		return nil, ErrExcursionAttendanceQRInvalid
	}

	payload, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return nil, ErrExcursionAttendanceQRInvalid
	}

	var claims excursionAttendanceQRClaims
	if err = json.Unmarshal(payload, &claims); err != nil {
		return nil, ErrExcursionAttendanceQRInvalid
	}
	if claims.Version != excursionAttendanceQRVersion {
		return nil, ErrExcursionAttendanceQRVersionInvalid
	}
	if claims.Audience != excursionAttendanceQRAudience || claims.ExpiresAt <= claims.IssuedAt {
		return nil, ErrExcursionAttendanceQRInvalid
	}

	slotID, err := uuid.Parse(claims.ScheduleSlotID)
	if err != nil {
		return nil, ErrExcursionAttendanceQRInvalid
	}
	guideUserID, err := uuid.Parse(claims.GuideUserID)
	if err != nil {
		return nil, ErrExcursionAttendanceQRInvalid
	}
	jti, err := uuid.Parse(claims.JTI)
	if err != nil {
		return nil, ErrExcursionAttendanceQRInvalid
	}

	return &decodedExcursionAttendanceQR{
		ScheduleSlotID: slotID,
		GuideUserID:    guideUserID,
		JTI:            jti,
		IssuedAt:       time.Unix(claims.IssuedAt, 0).UTC(),
		ExpiresAt:      time.Unix(claims.ExpiresAt, 0).UTC(),
	}, nil
}

func signExcursionAttendanceQRPayload(secret []byte, payloadPart string) string {
	mac := hmac.New(sha256.New, secret)
	_, _ = mac.Write([]byte(payloadPart))
	return base64.RawURLEncoding.EncodeToString(mac.Sum(nil))
}
