package app

import (
	"strings"

	"golang.org/x/crypto/bcrypt"

	"kz/inflap/backend/services/activity-service/internal/domain/enum"
	"kz/inflap/backend/services/activity-service/internal/domain/model"
)

const (
	minVisibilityPasswordLength = 4
	maxVisibilityPasswordLength = 64
)

func normalizeVisibilityPassword(
	visibility enum.ActivityVisibility,
	password *string,
) (*string, error) {
	if visibility != enum.ActivityVisibilityPrivate {
		return nil, nil
	}

	trimmed := strings.TrimSpace(model.ValueOrEmpty(password))
	if len(trimmed) < minVisibilityPasswordLength ||
		len(trimmed) > maxVisibilityPasswordLength {
		return nil, model.ErrInvalidVisibilityPassword
	}
	if !isVisibilityPasswordASCII(trimmed) {
		return nil, model.ErrInvalidVisibilityPassword
	}

	return &trimmed, nil
}

func isVisibilityPasswordASCII(value string) bool {
	for _, r := range value {
		if r < 0x20 || r > 0x7E {
			return false
		}
	}
	return true
}

func hashVisibilityPassword(password *string) (*string, error) {
	if password == nil {
		return nil, nil
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(*password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	value := string(hash)
	return &value, nil
}

func verifyVisibilityPassword(hash *string, password *string) error {
	if hash == nil {
		return model.ErrInvalidVisibilityPassword
	}

	normalized, err := normalizeVisibilityPassword(
		enum.ActivityVisibilityPrivate,
		password,
	)
	if err != nil {
		return err
	}

	if err := bcrypt.CompareHashAndPassword(
		[]byte(*hash),
		[]byte(*normalized),
	); err != nil {
		return model.ErrInvalidVisibilityPassword
	}

	return nil
}
