package model

import "strings"

import "github.com/google/uuid"

func NormalizeOptionalString(v *string) *string {
	if v == nil {
		return nil
	}
	trimmed := strings.TrimSpace(*v)
	if trimmed == "" {
		return nil
	}
	return &trimmed
}

func NormalizeUUIDPointer(v *uuid.UUID) *uuid.UUID {
	if v == nil || *v == uuid.Nil {
		return nil
	}
	out := *v
	return &out
}

func NormalizeSlug(raw string) string {
	raw = strings.ToLower(strings.TrimSpace(raw))
	raw = strings.ReplaceAll(raw, " ", "-")
	return raw
}
