package model

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/sticker-service/internal/domain/enum"
)

var (
	ErrInvalidStickerID     = errors.New("invalid sticker id")
	ErrInvalidStickerPackID = errors.New("invalid sticker pack id")
	ErrInvalidStickerFileID = errors.New("invalid sticker file id")
	ErrInvalidStickerStatus = errors.New("invalid sticker status")
)

type Sticker struct {
	ID              uuid.UUID
	PackID          uuid.UUID
	FileID          uuid.UUID
	Emoji           *string
	Keywords        []string
	Status          enum.StickerStatus
	SortOrder       int
	CreatedByUserID *uuid.UUID
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

type NewStickerParams struct {
	PackID          uuid.UUID
	FileID          uuid.UUID
	Emoji           *string
	Keywords        []string
	Status          enum.StickerStatus
	SortOrder       int
	CreatedByUserID *uuid.UUID
}

func NewSticker(params NewStickerParams) (*Sticker, error) {
	now := time.Now().UTC()
	sticker := &Sticker{
		ID:              uuid.New(),
		PackID:          params.PackID,
		FileID:          params.FileID,
		Emoji:           normalizeOptionalString(params.Emoji),
		Keywords:        normalizeStringSlice(params.Keywords),
		Status:          params.Status,
		SortOrder:       params.SortOrder,
		CreatedByUserID: params.CreatedByUserID,
		CreatedAt:       now,
		UpdatedAt:       now,
	}

	if err := sticker.Validate(); err != nil {
		return nil, err
	}

	return sticker, nil
}

func (s *Sticker) Validate() error {
	if s.ID == uuid.Nil {
		return ErrInvalidStickerID
	}
	if s.PackID == uuid.Nil {
		return ErrInvalidStickerPackID
	}
	if s.FileID == uuid.Nil {
		return ErrInvalidStickerFileID
	}
	if !s.Status.IsValid() {
		return ErrInvalidStickerStatus
	}
	return nil
}

func normalizeOptionalString(value *string) *string {
	if value == nil {
		return nil
	}
	normalized := strings.TrimSpace(*value)
	if normalized == "" {
		return nil
	}
	return &normalized
}

func normalizeStringSlice(values []string) []string {
	if len(values) == 0 {
		return []string{}
	}

	seen := make(map[string]struct{}, len(values))
	normalized := make([]string, 0, len(values))
	for _, raw := range values {
		value := strings.ToLower(strings.TrimSpace(raw))
		if value == "" {
			continue
		}
		if _, ok := seen[value]; ok {
			continue
		}
		seen[value] = struct{}{}
		normalized = append(normalized, value)
	}
	if len(normalized) == 0 {
		return []string{}
	}
	return normalized
}
