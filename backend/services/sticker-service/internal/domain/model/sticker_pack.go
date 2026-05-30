package model

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/sticker-service/internal/domain/enum"
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
	GroupID         *uuid.UUID
	Slug            string
	Type            enum.PackType
	Visibility      enum.PackVisibility
	Status          enum.PackStatus
	IsOfficial      bool
	Version         int
	OwnerUserID     *uuid.UUID
	Title           map[string]string
	Description     map[string]string
	CoverStickerID  *uuid.UUID
	ThumbnailFileID *uuid.UUID
	SortOrder       int
	PublishedAt     *time.Time
	CreatedByUserID *uuid.UUID
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

type StickerPackWithStickers struct {
	Pack     *StickerPack
	Stickers []*Sticker
}

type NewStickerPackParams struct {
	GroupID         *uuid.UUID
	Slug            string
	Type            enum.PackType
	Visibility      enum.PackVisibility
	Status          enum.PackStatus
	IsOfficial      bool
	Version         int
	OwnerUserID     *uuid.UUID
	Title           map[string]string
	Description     map[string]string
	CoverStickerID  *uuid.UUID
	ThumbnailFileID *uuid.UUID
	SortOrder       int
	PublishedAt     *time.Time
	CreatedByUserID *uuid.UUID
}

func NewStickerPack(params NewStickerPackParams) (*StickerPack, error) {
	now := time.Now().UTC()
	version := params.Version
	if version <= 0 {
		version = 1
	}
	pack := &StickerPack{
		ID:              uuid.New(),
		GroupID:         params.GroupID,
		Slug:            strings.TrimSpace(params.Slug),
		Type:            params.Type,
		Visibility:      params.Visibility,
		Status:          params.Status,
		IsOfficial:      params.IsOfficial,
		Version:         version,
		OwnerUserID:     params.OwnerUserID,
		Title:           normalizeLocalizedText(params.Title),
		Description:     normalizeLocalizedText(params.Description),
		CoverStickerID:  params.CoverStickerID,
		ThumbnailFileID: params.ThumbnailFileID,
		SortOrder:       params.SortOrder,
		PublishedAt:     params.PublishedAt,
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
