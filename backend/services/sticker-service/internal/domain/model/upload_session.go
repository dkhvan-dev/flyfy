package model

import (
	"errors"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/sticker-service/internal/domain/enum"
)

var (
	ErrInvalidUploadSessionID        = errors.New("invalid sticker upload session id")
	ErrInvalidUploadSessionUserID    = errors.New("invalid sticker upload session user id")
	ErrInvalidUploadSessionPackID    = errors.New("invalid sticker upload session pack id")
	ErrInvalidUploadSessionFileID    = errors.New("invalid sticker upload session file id")
	ErrInvalidUploadSessionStatus    = errors.New("invalid sticker upload session status")
	ErrInvalidUploadSessionExpiresAt = errors.New("invalid sticker upload session expiration")
)

type UploadSession struct {
	ID             uuid.UUID
	UserID         uuid.UUID
	PackID         uuid.UUID
	FileID         uuid.UUID
	Status         enum.UploadSessionStatus
	IdempotencyKey *string
	ExpiresAt      time.Time
	CreatedAt      time.Time
}

type NewUploadSessionParams struct {
	UserID         uuid.UUID
	PackID         uuid.UUID
	FileID         uuid.UUID
	Status         enum.UploadSessionStatus
	IdempotencyKey *string
	ExpiresAt      time.Time
}

func NewUploadSession(params NewUploadSessionParams) (*UploadSession, error) {
	session := &UploadSession{
		ID:             uuid.New(),
		UserID:         params.UserID,
		PackID:         params.PackID,
		FileID:         params.FileID,
		Status:         params.Status,
		IdempotencyKey: normalizeOptionalString(params.IdempotencyKey),
		ExpiresAt:      params.ExpiresAt.UTC(),
		CreatedAt:      time.Now().UTC(),
	}

	if err := session.Validate(); err != nil {
		return nil, err
	}

	return session, nil
}

func (s *UploadSession) Validate() error {
	if s.ID == uuid.Nil {
		return ErrInvalidUploadSessionID
	}
	if s.UserID == uuid.Nil {
		return ErrInvalidUploadSessionUserID
	}
	if s.PackID == uuid.Nil {
		return ErrInvalidUploadSessionPackID
	}
	if s.FileID == uuid.Nil {
		return ErrInvalidUploadSessionFileID
	}
	if !s.Status.IsValid() {
		return ErrInvalidUploadSessionStatus
	}
	if s.ExpiresAt.IsZero() {
		return ErrInvalidUploadSessionExpiresAt
	}
	return nil
}

func (s *UploadSession) MarkReady() error {
	if s.Status == enum.UploadSessionStatusExpired || time.Now().UTC().After(s.ExpiresAt) {
		s.Status = enum.UploadSessionStatusExpired
		return ErrInvalidUploadSessionStatus
	}
	s.Status = enum.UploadSessionStatusReady
	return nil
}
