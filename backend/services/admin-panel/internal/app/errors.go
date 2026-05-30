package app

import (
	"errors"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/port"
)

var (
	ErrInvalidCredentials     = errors.New("invalid credentials")
	ErrStaffDisabled          = errors.New("staff account is disabled")
	ErrStaffLocked            = errors.New("staff account is locked")
	ErrSessionNotFound        = errors.New("admin session not found")
	ErrCSRFTokenInvalid       = errors.New("csrf token is invalid")
	ErrPermissionDenied       = errors.New("permission denied")
	ErrInvalidInput           = errors.New("invalid input")
	ErrStaffNotFound          = errors.New("staff account not found")
	ErrDuplicateDecision      = port.ErrDuplicateDecision
	ErrModerationCaseConflict = port.ErrModerationCaseConflict
	ErrModerationCaseNotFound = errors.New("moderation case not found")
	ErrUserNotFound           = errors.New("user not found")
	ErrAttractionNotFound     = errors.New("attraction not found")
)
