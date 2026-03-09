package model

import (
	"errors"
	"regexp"
	"strings"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidBlockedURLPatternID     = errors.New("invalid blocked url pattern id")
	ErrInvalidBlockedURLPatternType   = errors.New("invalid blocked url pattern type")
	ErrInvalidBlockedURLPatternValue  = errors.New("invalid blocked url pattern value")
	ErrInvalidBlockedURLPatternAction = errors.New("invalid blocked url pattern action")
)

type BlockedURLPatternType string

const (
	BlockedURLPatternTypeStartsWith BlockedURLPatternType = "STARTS_WITH"
	BlockedURLPatternTypeContains   BlockedURLPatternType = "CONTAINS"
	BlockedURLPatternTypeRegex      BlockedURLPatternType = "REGEX"
	BlockedURLPatternTypeDomain     BlockedURLPatternType = "DOMAIN"
)

func (v BlockedURLPatternType) IsValid() bool {
	switch v {
	case BlockedURLPatternTypeStartsWith,
		BlockedURLPatternTypeContains,
		BlockedURLPatternTypeRegex,
		BlockedURLPatternTypeDomain:
		return true
	default:
		return false
	}
}

type BlockedURLPatternAction string

const (
	BlockedURLPatternActionBlock  BlockedURLPatternAction = "BLOCK"
	BlockedURLPatternActionReview BlockedURLPatternAction = "REVIEW"
)

func (v BlockedURLPatternAction) IsValid() bool {
	switch v {
	case BlockedURLPatternActionBlock, BlockedURLPatternActionReview:
		return true
	default:
		return false
	}
}

type BlockedURLPattern struct {
	ID           uuid.UUID
	PatternType  BlockedURLPatternType
	PatternValue string
	Action       BlockedURLPatternAction
	IsActive     bool
	Comment      *string
	CreatedAt    time.Time
}

func (p *BlockedURLPattern) Validate() error {
	if p.ID == uuid.Nil {
		return ErrInvalidBlockedURLPatternID
	}
	if !p.PatternType.IsValid() {
		return ErrInvalidBlockedURLPatternType
	}
	if strings.TrimSpace(p.PatternValue) == "" {
		return ErrInvalidBlockedURLPatternValue
	}
	if !p.Action.IsValid() {
		return ErrInvalidBlockedURLPatternAction
	}
	if p.PatternType == BlockedURLPatternTypeRegex {
		if _, err := regexp.Compile(strings.TrimSpace(p.PatternValue)); err != nil {
			return ErrInvalidBlockedURLPatternValue
		}
	}
	return nil
}
