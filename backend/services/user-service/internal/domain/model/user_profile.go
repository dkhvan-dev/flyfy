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
	UserID       uuid.UUID
	FirstName    *string
	LastName     *string
	DisplayName  *string
	Bio          *string
	BirthDate    *time.Time
	AvatarFileID *uuid.UUID
	CityID       *uuid.UUID
	CountryCode  *string
	Locale       string
	Timezone     string
	Currency     string
	IsPublic     bool
	CreatedAt    time.Time
	UpdatedAt    time.Time
}

type NewUserProfileParams struct {
	UserID uuid.UUID
}

func NewUserProfile(params NewUserProfileParams) (*UserProfile, error) {
	now := time.Now().UTC()

	profile := &UserProfile{
		UserID:    params.UserID,
		Locale:    "ru",
		Timezone:  "Asia/Almaty",
		Currency:  "KZT",
		IsPublic:  true,
		CreatedAt: now,
		UpdatedAt: now,
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
	if strings.TrimSpace(p.Currency) == "" {
		return ErrInvalidCurrency
	}
	return nil
}

type UpdateUserProfileParams struct {
	FirstName    *string
	LastName     *string
	DisplayName  *string
	Bio          *string
	BirthDate    *time.Time
	AvatarFileID *uuid.UUID
	CityID       *uuid.UUID
	CountryCode  *string
	Locale       *string
	Timezone     *string
	Currency     *string
	IsPublic     *bool
}

func (p *UserProfile) ApplyUpdate(params UpdateUserProfileParams) error {
	if p.UserID == uuid.Nil {
		return ErrInvalidProfileUserID
	}

	p.FirstName = normalizeOptionalString(params.FirstName)
	p.LastName = normalizeOptionalString(params.LastName)
	p.DisplayName = normalizeOptionalString(params.DisplayName)
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
		p.Currency = strings.TrimSpace(*params.Currency)
	}
	if params.IsPublic != nil {
		p.IsPublic = *params.IsPublic
	}

	p.UpdatedAt = time.Now().UTC()
	return p.Validate()
}
