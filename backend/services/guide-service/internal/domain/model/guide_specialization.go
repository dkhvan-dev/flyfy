package model

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidGuideSpecializationID             = errors.New("invalid guide specialization id")
	ErrInvalidGuideSpecializationGuideProfileID = errors.New("invalid guide specialization guide profile id")
	ErrInvalidGuideSpecializationCode           = errors.New("invalid guide specialization code")
)

type GuideSpecialization struct {
	ID                 uuid.UUID
	GuideProfileID     uuid.UUID
	SpecializationCode string
	CreatedAt          time.Time
}

type NewGuideSpecializationParams struct {
	GuideProfileID     uuid.UUID
	SpecializationCode string
}

func NewGuideSpecialization(params NewGuideSpecializationParams) (*GuideSpecialization, error) {
	item := &GuideSpecialization{
		ID:                 uuid.New(),
		GuideProfileID:     params.GuideProfileID,
		SpecializationCode: strings.TrimSpace(strings.ToUpper(params.SpecializationCode)),
		CreatedAt:          time.Now().UTC(),
	}

	if err := item.Validate(); err != nil {
		return nil, err
	}

	return item, nil
}

func (g *GuideSpecialization) Validate() error {
	if g.ID == uuid.Nil {
		return ErrInvalidGuideSpecializationID
	}
	if g.GuideProfileID == uuid.Nil {
		return ErrInvalidGuideSpecializationGuideProfileID
	}
	if strings.TrimSpace(g.SpecializationCode) == "" {
		return ErrInvalidGuideSpecializationCode
	}
	return nil
}
