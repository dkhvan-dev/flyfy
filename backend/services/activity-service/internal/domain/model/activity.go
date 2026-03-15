package model

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/enum"
)

var (
	ErrInvalidActivityID               = errors.New("invalid activity id")
	ErrInvalidHostUserID               = errors.New("invalid host user id")
	ErrInvalidActivityTitle            = errors.New("invalid activity title")
	ErrInvalidActivityDescription      = errors.New("invalid activity description")
	ErrInvalidActivityFormat           = errors.New("invalid activity format")
	ErrInvalidActivityStatus           = errors.New("invalid activity status")
	ErrInvalidActivityVisibility       = errors.New("invalid activity visibility")
	ErrInvalidActivityJoinMode         = errors.New("invalid activity join mode")
	ErrInvalidActivityModerationStatus = errors.New("invalid activity moderation status")
	ErrInvalidCategorySlug             = errors.New("invalid category slug")
	ErrInvalidLanguageCode             = errors.New("invalid language code")
	ErrInvalidTimezone                 = errors.New("invalid timezone")
	ErrInvalidActivityTimeRange        = errors.New("invalid activity time range")
	ErrInvalidRegistrationDeadline     = errors.New("invalid registration deadline")
	ErrActivityTooSoon                 = errors.New("activity start time must be at least 1 hour from now")
	ErrInvalidCapacityType             = errors.New("invalid capacity type")
	ErrInvalidCapacity                 = errors.New("invalid capacity")
	ErrInvalidPriceType                = errors.New("invalid price type")
	ErrInvalidPrice                    = errors.New("invalid price")
	ErrInvalidCurrency                 = errors.New("invalid currency")
	ErrInvalidMeetingURL               = errors.New("invalid meeting url")
	ErrInvalidOfflineLocation          = errors.New("invalid offline location")
	ErrPriceLocked                     = errors.New("activity price is locked")
	ErrOnlyAuthorCanDuplicate          = errors.New("only author can duplicate activity")
	ErrActivityCannotBePublished       = errors.New("activity cannot be published")
	ErrCriticalFieldsLocked            = errors.New("critical activity fields are locked after publication")
)

type Activity struct {
	ID               uuid.UUID
	HostUserID       uuid.UUID
	SourceActivityID *uuid.UUID

	Title       string
	Description string

	Format           enum.ActivityFormat
	Status           enum.ActivityStatus
	Visibility       enum.ActivityVisibility
	JoinMode         enum.ActivityJoinMode
	ModerationStatus enum.ActivityModerationStatus

	CategorySlug string
	LanguageCode string
	Timezone     string

	StartAt              time.Time
	EndAt                time.Time
	RegistrationDeadline time.Time

	CapacityType    enum.ActivityCapacityType
	MinParticipants *int
	MaxParticipants *int

	PriceType     enum.ActivityPriceType
	PriceAmount   *float64
	Currency      *string
	PriceLockedAt *time.Time

	RequiresProfileCompletion      bool
	RequiresAttendanceConfirmation bool
	ConfirmationDeadline           *time.Time

	CountryCode *string
	CityName    *string
	AddressText *string
	Latitude    *float64
	Longitude   *float64
	MapURL      *string
	MeetingURL  *string

	CancellationReason *string
	CancelledAt        *time.Time
	StartedAt          *time.Time
	CompletedAt        *time.Time
	PublishedAt        *time.Time

	Revision  int
	CreatedAt time.Time
	UpdatedAt time.Time
}

type NewActivityParams struct {
	HostUserID       uuid.UUID
	SourceActivityID *uuid.UUID

	Title        string
	Description  string
	Format       enum.ActivityFormat
	Visibility   enum.ActivityVisibility
	JoinMode     enum.ActivityJoinMode
	CategorySlug string
	LanguageCode string
	Timezone     string

	StartAt              time.Time
	EndAt                time.Time
	RegistrationDeadline time.Time

	CapacityType    enum.ActivityCapacityType
	MinParticipants *int
	MaxParticipants *int

	PriceType   enum.ActivityPriceType
	PriceAmount *float64
	Currency    *string

	RequiresProfileCompletion      bool
	RequiresAttendanceConfirmation bool
	ConfirmationDeadline           *time.Time

	CountryCode *string
	CityName    *string
	AddressText *string
	Latitude    *float64
	Longitude   *float64
	MapURL      *string
	MeetingURL  *string
}

func NewActivity(params NewActivityParams) (*Activity, error) {
	now := time.Now().UTC()

	item := &Activity{
		ID:               uuid.New(),
		HostUserID:       params.HostUserID,
		SourceActivityID: params.SourceActivityID,

		Title:       strings.TrimSpace(params.Title),
		Description: strings.TrimSpace(params.Description),

		Format:           params.Format,
		Status:           enum.ActivityStatusDraft,
		Visibility:       params.Visibility,
		JoinMode:         params.JoinMode,
		ModerationStatus: enum.ActivityModerationStatusNotRequired,

		CategorySlug: strings.TrimSpace(params.CategorySlug),
		LanguageCode: strings.TrimSpace(params.LanguageCode),
		Timezone:     strings.TrimSpace(params.Timezone),

		StartAt:              params.StartAt.UTC(),
		EndAt:                params.EndAt.UTC(),
		RegistrationDeadline: params.RegistrationDeadline.UTC(),

		CapacityType:    params.CapacityType,
		MinParticipants: params.MinParticipants,
		MaxParticipants: params.MaxParticipants,

		PriceType:   params.PriceType,
		PriceAmount: params.PriceAmount,
		Currency:    NormalizeOptionalString(params.Currency),

		RequiresProfileCompletion:      params.RequiresProfileCompletion,
		RequiresAttendanceConfirmation: params.RequiresAttendanceConfirmation,
		ConfirmationDeadline:           params.ConfirmationDeadline,

		CountryCode: NormalizeOptionalString(params.CountryCode),
		CityName:    NormalizeOptionalString(params.CityName),
		AddressText: NormalizeOptionalString(params.AddressText),
		Latitude:    params.Latitude,
		Longitude:   params.Longitude,
		MapURL:      NormalizeOptionalString(params.MapURL),
		MeetingURL:  NormalizeOptionalString(params.MeetingURL),

		Revision:  1,
		CreatedAt: now,
		UpdatedAt: now,
	}

	if err := item.ValidateForCreate(now); err != nil {
		return nil, err
	}

	return item, nil
}

func (a *Activity) ValidateForCreate(now time.Time) error {
	return a.Validate(now, false)
}

func (a *Activity) Validate(now time.Time, skipStartTimeCheck bool) error {
	if a.ID == uuid.Nil {
		return ErrInvalidActivityID
	}
	if a.HostUserID == uuid.Nil {
		return ErrInvalidHostUserID
	}
	if len(strings.TrimSpace(a.Title)) < 3 || len(strings.TrimSpace(a.Title)) > 200 {
		return ErrInvalidActivityTitle
	}
	if len(strings.TrimSpace(a.Description)) < 10 {
		return ErrInvalidActivityDescription
	}
	if !a.Format.IsValid() {
		return ErrInvalidActivityFormat
	}
	if !a.Status.IsValid() {
		return ErrInvalidActivityStatus
	}
	if !a.Visibility.IsValid() {
		return ErrInvalidActivityVisibility
	}
	if !a.JoinMode.IsValid() {
		return ErrInvalidActivityJoinMode
	}
	if !a.ModerationStatus.IsValid() {
		return ErrInvalidActivityModerationStatus
	}
	if strings.TrimSpace(a.CategorySlug) == "" {
		return ErrInvalidCategorySlug
	}
	if strings.TrimSpace(a.LanguageCode) == "" {
		return ErrInvalidLanguageCode
	}
	if strings.TrimSpace(a.Timezone) == "" {
		return ErrInvalidTimezone
	}
	if !skipStartTimeCheck && !a.StartAt.After(now.Add(1*time.Hour)) {
		return ErrActivityTooSoon
	}
	if !a.EndAt.After(a.StartAt) {
		return ErrInvalidActivityTimeRange
	}
	if a.RegistrationDeadline.After(a.StartAt) {
		return ErrInvalidRegistrationDeadline
	}
	if !a.CapacityType.IsValid() {
		return ErrInvalidCapacityType
	}
	if err := a.validateCapacity(); err != nil {
		return err
	}
	if !a.PriceType.IsValid() {
		return ErrInvalidPriceType
	}
	if err := a.validatePrice(); err != nil {
		return err
	}
	if err := a.validateLocation(); err != nil {
		return err
	}
	if a.RequiresAttendanceConfirmation && a.ConfirmationDeadline != nil {
		if a.ConfirmationDeadline.After(a.StartAt) {
			return ErrInvalidRegistrationDeadline
		}
	}

	return nil
}

func (a *Activity) validateCapacity() error {
	switch a.CapacityType {
	case enum.ActivityCapacityTypeUnlimited:
		if a.MaxParticipants != nil {
			return ErrInvalidCapacity
		}
	case enum.ActivityCapacityTypeLimited:
		if a.MaxParticipants == nil || *a.MaxParticipants <= 0 {
			return ErrInvalidCapacity
		}
	default:
		return ErrInvalidCapacityType
	}

	if a.MinParticipants != nil && *a.MinParticipants < 1 {
		return ErrInvalidCapacity
	}
	if a.MinParticipants != nil && a.MaxParticipants != nil && *a.MinParticipants > *a.MaxParticipants {
		return ErrInvalidCapacity
	}

	return nil
}

func (a *Activity) validatePrice() error {
	switch a.PriceType {
	case enum.ActivityPriceTypeFree:
		if a.PriceAmount != nil || a.Currency != nil {
			return ErrInvalidPrice
		}
	case enum.ActivityPriceTypePaid, enum.ActivityPriceTypeDeposit:
		if a.PriceAmount == nil || *a.PriceAmount <= 0 {
			return ErrInvalidPrice
		}
		if a.Currency == nil || strings.TrimSpace(*a.Currency) == "" {
			return ErrInvalidCurrency
		}
	default:
		return ErrInvalidPriceType
	}

	return nil
}

func (a *Activity) validateLocation() error {
	switch a.Format {
	case enum.ActivityFormatOnline:
		if a.MeetingURL == nil || strings.TrimSpace(*a.MeetingURL) == "" {
			return ErrInvalidMeetingURL
		}
	case enum.ActivityFormatOffline:
		if a.CountryCode == nil && a.CityName == nil && a.AddressText == nil && a.MapURL == nil {
			return ErrInvalidOfflineLocation
		}
	case enum.ActivityFormatHybrid:
		if (a.MeetingURL == nil || strings.TrimSpace(*a.MeetingURL) == "") &&
			a.CountryCode == nil && a.CityName == nil && a.AddressText == nil && a.MapURL == nil {
			return ErrInvalidOfflineLocation
		}
	default:
		return ErrInvalidActivityFormat
	}

	return nil
}

func (a *Activity) CanBePublished(now time.Time) error {
	if a.Status != enum.ActivityStatusDraft && a.Status != enum.ActivityStatusReviewRequired {
		return ErrActivityCannotBePublished
	}
	return a.ValidateForCreate(now)
}

func (a *Activity) Publish(now time.Time, reviewRequired bool) error {
	if err := a.CanBePublished(now); err != nil {
		return err
	}

	if reviewRequired {
		a.Status = enum.ActivityStatusReviewRequired
		a.ModerationStatus = enum.ActivityModerationStatusPendingReview
	} else {
		a.Status = enum.ActivityStatusEnrollmentOpen
		a.ModerationStatus = enum.ActivityModerationStatusApproved
		ts := now.UTC()
		a.PublishedAt = &ts
	}

	a.Revision++
	a.UpdatedAt = now.UTC()
	return nil
}

func (a *Activity) ApproveModeration(now time.Time) error {
	if a.ModerationStatus != enum.ActivityModerationStatusPendingReview {
		return ErrActivityCannotBePublished
	}

	ts := now.UTC()
	a.ModerationStatus = enum.ActivityModerationStatusApproved
	a.Status = enum.ActivityStatusEnrollmentOpen
	a.PublishedAt = &ts
	a.Revision++
	a.UpdatedAt = ts

	return nil
}

func (a *Activity) RejectModeration(now time.Time) error {
	if a.ModerationStatus != enum.ActivityModerationStatusPendingReview {
		return ErrActivityCannotBePublished
	}

	a.ModerationStatus = enum.ActivityModerationStatusRejected
	a.Status = enum.ActivityStatusDraft
	a.Revision++
	a.UpdatedAt = now.UTC()

	return nil
}

func (a *Activity) LockPrice(now time.Time) {
	ts := now.UTC()
	a.PriceLockedAt = &ts
	a.UpdatedAt = ts
}

func (a *Activity) CanChangePrice() error {
	if a.PriceLockedAt != nil {
		return ErrPriceLocked
	}
	return nil
}

func (a *Activity) CanDuplicate(actorUserID uuid.UUID) error {
	if actorUserID == uuid.Nil || actorUserID != a.HostUserID {
		return ErrOnlyAuthorCanDuplicate
	}
	return nil
}
