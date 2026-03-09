package model

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidGuideLanguageID               = errors.New("invalid guide language id")
	ErrInvalidGuideLanguageGuideProfileID   = errors.New("invalid guide language guide profile id")
	ErrInvalidGuideLanguageCode             = errors.New("invalid guide language code")
	ErrInvalidGuideLanguageProficiencyLevel = errors.New("invalid guide language proficiency level")
)

type GuideLanguage struct {
	ID               uuid.UUID
	GuideProfileID   uuid.UUID
	LanguageCode     string
	ProficiencyLevel string
	CreatedAt        time.Time
}

type NewGuideLanguageParams struct {
	GuideProfileID   uuid.UUID
	LanguageCode     string
	ProficiencyLevel string
}

func NewGuideLanguage(params NewGuideLanguageParams) (*GuideLanguage, error) {
	item := &GuideLanguage{
		ID:               uuid.New(),
		GuideProfileID:   params.GuideProfileID,
		LanguageCode:     strings.TrimSpace(strings.ToLower(params.LanguageCode)),
		ProficiencyLevel: strings.TrimSpace(strings.ToUpper(params.ProficiencyLevel)),
		CreatedAt:        time.Now().UTC(),
	}

	if err := item.Validate(); err != nil {
		return nil, err
	}

	return item, nil
}

func (g *GuideLanguage) Validate() error {
	if g.ID == uuid.Nil {
		return ErrInvalidGuideLanguageID
	}
	if g.GuideProfileID == uuid.Nil {
		return ErrInvalidGuideLanguageGuideProfileID
	}
	if strings.TrimSpace(g.LanguageCode) == "" {
		return ErrInvalidGuideLanguageCode
	}
	if strings.TrimSpace(g.ProficiencyLevel) == "" {
		return ErrInvalidGuideLanguageProficiencyLevel
	}
	return nil
}
