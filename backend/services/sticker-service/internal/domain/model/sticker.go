package model

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/sticker-service/internal/domain/enum"
)

var (
	ErrInvalidStickerID     = errors.New("invalid sticker id")
	ErrInvalidStickerPackID = errors.New("invalid sticker pack id")
	ErrInvalidStickerFileID = errors.New("invalid sticker file id")
	ErrInvalidStickerStatus = errors.New("invalid sticker status")
	ErrInvalidStickerAsset  = errors.New("invalid sticker asset metadata")
)

type Sticker struct {
	ID              uuid.UUID
	PackID          uuid.UUID
	Slug            string
	FileID          uuid.UUID
	FallbackFileID  *uuid.UUID
	PreviewFileID   *uuid.UUID
	Emoji           *string
	Keywords        []string
	Status          enum.StickerStatus
	ContentType     string
	Width           int
	Height          int
	DurationMS      int
	SizeBytes       int64
	Checksum        string
	SortOrder       int
	CreatedByUserID *uuid.UUID
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

type StickerAssetMetadata struct {
	AnimationFileID uuid.UUID
	FallbackFileID  uuid.UUID
	PreviewFileID   *uuid.UUID
	ContentType     string
	Width           int
	Height          int
	DurationMS      int
	SizeBytes       int64
	Checksum        string
}

type NewStickerParams struct {
	PackID          uuid.UUID
	Slug            string
	FileID          uuid.UUID
	FallbackFileID  *uuid.UUID
	PreviewFileID   *uuid.UUID
	Emoji           *string
	Keywords        []string
	Status          enum.StickerStatus
	ContentType     string
	Width           int
	Height          int
	DurationMS      int
	SizeBytes       int64
	Checksum        string
	SortOrder       int
	CreatedByUserID *uuid.UUID
}

func NewSticker(params NewStickerParams) (*Sticker, error) {
	now := time.Now().UTC()
	sticker := &Sticker{
		ID:              uuid.New(),
		PackID:          params.PackID,
		Slug:            strings.TrimSpace(params.Slug),
		FileID:          params.FileID,
		FallbackFileID:  params.FallbackFileID,
		PreviewFileID:   params.PreviewFileID,
		Emoji:           normalizeOptionalString(params.Emoji),
		Keywords:        normalizeStringSlice(params.Keywords),
		Status:          params.Status,
		ContentType:     strings.TrimSpace(params.ContentType),
		Width:           params.Width,
		Height:          params.Height,
		DurationMS:      params.DurationMS,
		SizeBytes:       params.SizeBytes,
		Checksum:        strings.TrimSpace(params.Checksum),
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

func CanSendSticker(pack StickerPack, sticker Sticker) bool {
	return pack.Status == enum.PackStatusActive &&
		pack.Visibility == enum.PackVisibilityPublic &&
		sticker.Status == enum.StickerStatusActive &&
		sticker.PackID == pack.ID
}

func (m StickerAssetMetadata) Validate() error {
	if m.AnimationFileID == uuid.Nil {
		return ErrInvalidStickerAsset
	}
	if m.FallbackFileID == uuid.Nil {
		return ErrInvalidStickerAsset
	}
	if strings.TrimSpace(m.ContentType) == "" {
		return ErrInvalidStickerAsset
	}
	if m.Width <= 0 || m.Height <= 0 {
		return ErrInvalidStickerAsset
	}
	if m.DurationMS <= 0 || m.DurationMS > 3000 {
		return ErrInvalidStickerAsset
	}
	if m.SizeBytes <= 0 {
		return ErrInvalidStickerAsset
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
