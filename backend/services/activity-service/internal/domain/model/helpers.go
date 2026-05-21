package model

import (
	"strings"

	"github.com/google/uuid"
)

func NormalizeOptionalString(v *string) *string {
	if v == nil {
		return nil
	}

	s := strings.TrimSpace(*v)
	if s == "" {
		return nil
	}

	return &s
}

func ValueOrEmpty(v *string) string {
	if v == nil {
		return ""
	}
	return strings.TrimSpace(*v)
}

func ValueOrEmptyUUID(v *uuid.UUID) string {
	if v == nil {
		return ""
	}
	return v.String()
}
