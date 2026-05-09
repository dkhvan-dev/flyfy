package model

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/sticker-service/internal/domain/enum"
)

var (
	ErrInvalidPackID         = errors.New("invalid sticker pack id")
	ErrInvalidPackSlug       = errors.New("invalid sticker pack slug")
	ErrInvalidPackType       = errors.New("invalid sticker pack type")
	ErrInvalidPackVisibility = errors.New("invalid sticker pack visibility")
	ErrInvalidPackStatus     = errors.New("invalid sticker pack status")
	ErrInvalidPackTitle      = errors.New("invalid sticker pack title")
	ErrInvalidPackOwner      = errors.New("invalid sticker pack owner")
)

type StickerPack struct {
	ID              uuid.UUID
	Slug            string
	Type            enum.PackType
	Visibility      enum.PackVisibility
	Status          enum.PackStatus
	OwnerUserID     *uuid.UUID
	Title           map[string]string
	Description     map[string]string
	CoverStickerID  *uuid.UUID
	SortOrder       int
	CreatedByUserID *uuid.UUID
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

type StickerPackWithStickers struct {
	Pack     *StickerPack
	Stickers []*Sticker
}

type NewStickerPackParams struct {
	Slug            string
	Type            enum.PackType
	Visibility      enum.PackVisibility
	Status          enum.PackStatus
	OwnerUserID     *uuid.UUID
	Title           map[string]string
	Description     map[string]string
	CoverStickerID  *uuid.UUID
	SortOrder       int
	CreatedByUserID *uuid.UUID
}

func NewStickerPack(params NewStickerPackParams) (*StickerPack, error) {
	now := time.Now().UTC()
	pack := &StickerPack{
		ID:              uuid.New(),
		Slug:            strings.TrimSpace(params.Slug),
		Type:            params.Type,
		Visibility:      params.Visibility,
		Status:          params.Status,
		OwnerUserID:     params.OwnerUserID,
		Title:           normalizeLocalizedText(params.Title),
		Description:     normalizeLocalizedText(params.Description),
		CoverStickerID:  params.CoverStickerID,
		SortOrder:       params.SortOrder,
		CreatedByUserID: params.CreatedByUserID,
		CreatedAt:       now,
		UpdatedAt:       now,
	}

	if err := pack.Validate(); err != nil {
		return nil, err
	}

	return pack, nil
}

func (p *StickerPack) Validate() error {
	if p.ID == uuid.Nil {
		return ErrInvalidPackID
	}
	if strings.TrimSpace(p.Slug) == "" {
		return ErrInvalidPackSlug
	}
	if !p.Type.IsValid() {
		return ErrInvalidPackType
	}
	if !p.Visibility.IsValid() {
		return ErrInvalidPackVisibility
	}
	if !p.Status.IsValid() {
		return ErrInvalidPackStatus
	}
	if len(normalizeLocalizedText(p.Title)) == 0 {
		return ErrInvalidPackTitle
	}
	if p.Type == enum.PackTypeUserCustom && (p.OwnerUserID == nil || *p.OwnerUserID == uuid.Nil) {
		return ErrInvalidPackOwner
	}
	if p.Type == enum.PackTypeSystem && p.OwnerUserID != nil {
		return ErrInvalidPackOwner
	}
	return nil
}

func normalizeLocalizedText(values map[string]string) map[string]string {
	if len(values) == 0 {
		return nil
	}

	normalized := make(map[string]string, len(values))
	for rawLocale, rawValue := range values {
		locale := strings.ToLower(strings.TrimSpace(rawLocale))
		value := strings.TrimSpace(rawValue)
		if locale == "" || value == "" {
			continue
		}
		normalized[locale] = value
	}
	if len(normalized) == 0 {
		return nil
	}
	return normalized
}
