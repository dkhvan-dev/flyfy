package model

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidProfileUserID = errors.New("invalid profile user id")
	ErrInvalidLocale        = errors.New("invalid locale")
	ErrInvalidTimezone      = errors.New("invalid timezone")
	ErrInvalidCurrency      = errors.New("invalid currency")
)

type UserProfile struct {
	UserID             uuid.UUID  `json:"user_id"`
	FirstName          *string    `json:"first_name,omitempty"`
	LastName           *string    `json:"last_name,omitempty"`
	Nickname           *string    `json:"nickname,omitempty"`
	Bio                *string    `json:"bio,omitempty"`
	BirthDate          *time.Time `json:"birth_date,omitempty"`
	AvatarFileID       *uuid.UUID `json:"avatar_file_id,omitempty"`
	CityID             *uuid.UUID `json:"city_id,omitempty"`
	CountryCode        *string    `json:"country_code,omitempty"`
	Locale             string     `json:"locale"`
	Timezone           string     `json:"timezone"`
	Currency           *string    `json:"currency,omitempty"`
	IsProfileCompleted bool       `json:"is_profile_completed"`
	IsOnline           bool       `json:"is_online"`
	LastSeenAt         *time.Time `json:"last_seen_at,omitempty"`
	CreatedAt          time.Time  `json:"created_at"`
	UpdatedAt          time.Time  `json:"updated_at"`
}

type NewUserProfileParams struct {
	UserID uuid.UUID
}

func NewUserProfile(params NewUserProfileParams) (*UserProfile, error) {
	now := time.Now().UTC()
	defaultCurrency := "KZT"

	profile := &UserProfile{
		UserID:             params.UserID,
		Locale:             "ru",
		Timezone:           "Asia/Almaty",
		Currency:           &defaultCurrency,
		IsProfileCompleted: false,
		CreatedAt:          now,
		UpdatedAt:          now,
	}

	if err := profile.Validate(); err != nil {
		return nil, err
	}

	return profile, nil
}

func (p *UserProfile) Validate() error {
	if p.UserID == uuid.Nil {
		return ErrInvalidProfileUserID
	}
	if strings.TrimSpace(p.Locale) == "" {
		return ErrInvalidLocale
	}
	if strings.TrimSpace(p.Timezone) == "" {
		return ErrInvalidTimezone
	}
	if p.Currency == nil || strings.TrimSpace(*p.Currency) == "" {
		return ErrInvalidCurrency
	}
	return nil
}

type UpdateUserProfileParams struct {
	FirstName    *string
	LastName     *string
	Nickname     *string
	Bio          *string
	BirthDate    *time.Time
	AvatarFileID *uuid.UUID
	CityID       *uuid.UUID
	CountryCode  *string
	Locale       *string
	Timezone     *string
	Currency     *string
}

func (p *UserProfile) ApplyUpdate(params UpdateUserProfileParams) error {
	if p.UserID == uuid.Nil {
		return ErrInvalidProfileUserID
	}

	p.FirstName = normalizeOptionalString(params.FirstName)
	p.LastName = normalizeOptionalString(params.LastName)
	p.Nickname = normalizeOptionalString(params.Nickname)
	p.Bio = normalizeOptionalString(params.Bio)
	p.BirthDate = params.BirthDate
	p.AvatarFileID = params.AvatarFileID
	p.CityID = params.CityID
	p.CountryCode = normalizeOptionalString(params.CountryCode)

	if params.Locale != nil {
		p.Locale = strings.TrimSpace(*params.Locale)
	}
	if params.Timezone != nil {
		p.Timezone = strings.TrimSpace(*params.Timezone)
	}
	if params.Currency != nil {
		p.Currency = normalizeOptionalString(params.Currency)
	}

	p.UpdatedAt = time.Now().UTC()
	return p.Validate()
}
