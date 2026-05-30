package model

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/sticker-service/internal/domain/enum"
)

var (
	ErrInvalidStickerGroupID     = errors.New("invalid sticker group id")
	ErrInvalidStickerGroupSlug   = errors.New("invalid sticker group slug")
	ErrInvalidStickerGroupStatus = errors.New("invalid sticker group status")
	ErrInvalidStickerGroupTitle  = errors.New("invalid sticker group title")
)

type StickerGroup struct {
	ID           uuid.UUID
	Slug         string
	Title        map[string]string
	DisplayOrder int
	Status       enum.PackStatus
	CreatedAt    time.Time
	UpdatedAt    time.Time
}

type NewStickerGroupParams struct {
	Slug         string
	Title        map[string]string
	DisplayOrder int
	Status       enum.PackStatus
}

func NewStickerGroup(params NewStickerGroupParams) (*StickerGroup, error) {
	now := time.Now().UTC()
	group := &StickerGroup{
		ID:           uuid.New(),
		Slug:         strings.TrimSpace(params.Slug),
		Title:        normalizeLocalizedText(params.Title),
		DisplayOrder: params.DisplayOrder,
		Status:       params.Status,
		CreatedAt:    now,
		UpdatedAt:    now,
	}
	if err := group.Validate(); err != nil {
		return nil, err
	}
	return group, nil
}

func (g *StickerGroup) Validate() error {
	if g.ID == uuid.Nil {
		return ErrInvalidStickerGroupID
	}
	if strings.TrimSpace(g.Slug) == "" {
		return ErrInvalidStickerGroupSlug
	}
	if !g.Status.IsValid() {
		return ErrInvalidStickerGroupStatus
	}
	if len(normalizeLocalizedText(g.Title)) == 0 {
		return ErrInvalidStickerGroupTitle
	}
	return nil
}
