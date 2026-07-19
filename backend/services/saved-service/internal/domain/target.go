package domain

import (
	"strings"
	"unicode"
	"unicode/utf8"
)

const maxEntityIDBytes = 512

// EntityType is intentionally closed: Saved does not support generic content.
type EntityType string

const (
	EntityTypeAttraction EntityType = "ATTRACTION"
	EntityTypeActivity   EntityType = "ACTIVITY"
	EntityTypeGuide      EntityType = "GUIDE"
	EntityTypeUser       EntityType = "USER"
	EntityTypePost       EntityType = "POST"
)

func (t EntityType) IsValid() bool {
	switch t {
	case EntityTypeAttraction, EntityTypeActivity, EntityTypeGuide, EntityTypeUser, EntityTypePost:
		return true
	default:
		return false
	}
}

// SavedTarget identifies one immutable canonical source entity.
type SavedTarget struct {
	entityType EntityType
	entityID   string
}

func NewSavedTarget(entityType EntityType, entityID string) (SavedTarget, error) {
	if !entityType.IsValid() {
		return SavedTarget{}, ErrTargetTypeUnsupported
	}

	if entityID == "" || entityID != strings.TrimSpace(entityID) || !utf8.ValidString(entityID) ||
		len(entityID) > maxEntityIDBytes || strings.IndexFunc(entityID, unicode.IsControl) >= 0 {
		return SavedTarget{}, ErrTargetUnavailable
	}

	return SavedTarget{entityType: entityType, entityID: entityID}, nil
}

func (t SavedTarget) EntityType() EntityType {
	return t.entityType
}

func (t SavedTarget) EntityID() string {
	return t.entityID
}

func (t SavedTarget) IsZero() bool {
	return !t.entityType.IsValid() || t.entityID == ""
}
