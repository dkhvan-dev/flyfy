package app

import (
	"strings"

	"golang.org/x/crypto/bcrypt"

	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/model"
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

	return &trimmed, nil
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
