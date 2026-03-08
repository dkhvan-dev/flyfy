package model

import (
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidSettingsUserID = errors.New("invalid settings user id")
)

type UserSettings struct {
	UserID                    uuid.UUID
	NotificationsPushEnabled  bool
	NotificationsEmailEnabled bool
	NotificationsSMSEnabled   bool
	MarketingEnabled          bool
	DarkModeEnabled           bool
	CreatedAt                 time.Time
	UpdatedAt                 time.Time
}

type NewUserSettingsParams struct {
	UserID uuid.UUID
}

func NewUserSettings(params NewUserSettingsParams) (*UserSettings, error) {
	now := time.Now().UTC()

	settings := &UserSettings{
		UserID:                    params.UserID,
		NotificationsPushEnabled:  true,
		NotificationsEmailEnabled: true,
		NotificationsSMSEnabled:   true,
		MarketingEnabled:          false,
		DarkModeEnabled:           false,
		CreatedAt:                 now,
		UpdatedAt:                 now,
	}

	if err := settings.Validate(); err != nil {
		return nil, err
	}

	return settings, nil
}

func (s *UserSettings) Validate() error {
	if s.UserID == uuid.Nil {
		return ErrInvalidSettingsUserID
	}
	return nil
}

type UpdateUserSettingsParams struct {
	NotificationsPushEnabled  *bool
	NotificationsEmailEnabled *bool
	NotificationsSMSEnabled   *bool
	MarketingEnabled          *bool
	DarkModeEnabled           *bool
}

func (s *UserSettings) ApplyUpdate(params UpdateUserSettingsParams) error {
	if s.UserID == uuid.Nil {
		return ErrInvalidSettingsUserID
	}

	if params.NotificationsPushEnabled != nil {
		s.NotificationsPushEnabled = *params.NotificationsPushEnabled
	}
	if params.NotificationsEmailEnabled != nil {
		s.NotificationsEmailEnabled = *params.NotificationsEmailEnabled
	}
	if params.NotificationsSMSEnabled != nil {
		s.NotificationsSMSEnabled = *params.NotificationsSMSEnabled
	}
	if params.MarketingEnabled != nil {
		s.MarketingEnabled = *params.MarketingEnabled
	}
	if params.DarkModeEnabled != nil {
		s.DarkModeEnabled = *params.DarkModeEnabled
	}

	s.UpdatedAt = time.Now().UTC()
	return s.Validate()
}
