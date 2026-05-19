package model

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

const (
	AttendanceSyncAttemptStatusAccepted         = "ACCEPTED"
	AttendanceSyncAttemptStatusAlreadyCheckedIn = "ALREADY_CHECKED_IN"
	AttendanceSyncAttemptStatusRejected         = "REJECTED"
)

var (
	ErrInvalidExcursionAttendanceQRJTI    = errors.New("invalid excursion attendance qr jti")
	ErrInvalidExcursionAttendanceQRSlot   = errors.New("invalid excursion attendance qr slot")
	ErrInvalidExcursionAttendanceQRGuide  = errors.New("invalid excursion attendance qr guide")
	ErrInvalidExcursionAttendanceQRRange  = errors.New("invalid excursion attendance qr time range")
	ErrInvalidAttendanceSyncScanID        = errors.New("invalid attendance sync scan id")
	ErrInvalidAttendanceSyncScheduleSlot  = errors.New("invalid attendance sync schedule slot")
	ErrInvalidAttendanceSyncParticipantID = errors.New("invalid attendance sync participant user id")
	ErrInvalidAttendanceSyncQRJTI         = errors.New("invalid attendance sync qr jti")
	ErrInvalidAttendanceSyncInstallID     = errors.New("invalid attendance sync installation id")
	ErrInvalidAttendanceSyncStatus        = errors.New("invalid attendance sync status")
)

type ExcursionAttendanceQRIssue struct {
	JTI            uuid.UUID
	ScheduleSlotID uuid.UUID
	GuideUserID    uuid.UUID
	IssuedAt       time.Time
	ExpiresAt      time.Time
	UsableUntil    time.Time
	CreatedAt      time.Time
}

type NewExcursionAttendanceQRIssueParams struct {
	ScheduleSlotID uuid.UUID
	GuideUserID    uuid.UUID
	IssuedAt       time.Time
	TTL            time.Duration
	OfflineWindow  time.Duration
}

func NewExcursionAttendanceQRIssue(params NewExcursionAttendanceQRIssueParams) (*ExcursionAttendanceQRIssue, error) {
	issuedAt := params.IssuedAt.UTC()
	item := &ExcursionAttendanceQRIssue{
		JTI:            uuid.New(),
		ScheduleSlotID: params.ScheduleSlotID,
		GuideUserID:    params.GuideUserID,
		IssuedAt:       issuedAt,
		ExpiresAt:      issuedAt.Add(params.TTL),
		UsableUntil:    issuedAt.Add(params.OfflineWindow),
		CreatedAt:      time.Now().UTC(),
	}
	if err := item.Validate(); err != nil {
		return nil, err
	}
	return item, nil
}

func (i *ExcursionAttendanceQRIssue) Validate() error {
	if i.JTI == uuid.Nil {
		return ErrInvalidExcursionAttendanceQRJTI
	}
	if i.ScheduleSlotID == uuid.Nil {
		return ErrInvalidExcursionAttendanceQRSlot
	}
	if i.GuideUserID == uuid.Nil {
		return ErrInvalidExcursionAttendanceQRGuide
	}
	if !i.ExpiresAt.After(i.IssuedAt) || !i.UsableUntil.After(i.ExpiresAt) {
		return ErrInvalidExcursionAttendanceQRRange
	}
	return nil
}

type ExcursionAttendanceSyncAttempt struct {
	ScanID          uuid.UUID
	ScheduleSlotID  uuid.UUID
	TouristUserID   uuid.UUID
	QRJTI           uuid.UUID
	InstallationID  string
	ScannedAtDevice *time.Time
	ResultStatus    string
	FailureCode     *string
	FailureMessage  *string
	CheckedInAt     *time.Time
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

type NewExcursionAttendanceSyncAttemptParams struct {
	ScanID          uuid.UUID
	ScheduleSlotID  uuid.UUID
	TouristUserID   uuid.UUID
	QRJTI           uuid.UUID
	InstallationID  string
	ScannedAtDevice *time.Time
	ResultStatus    string
	FailureCode     *string
	FailureMessage  *string
	CheckedInAt     *time.Time
}

func NewExcursionAttendanceSyncAttempt(params NewExcursionAttendanceSyncAttemptParams) (*ExcursionAttendanceSyncAttempt, error) {
	now := time.Now().UTC()
	item := &ExcursionAttendanceSyncAttempt{
		ScanID:         params.ScanID,
		ScheduleSlotID: params.ScheduleSlotID,
		TouristUserID:  params.TouristUserID,
		QRJTI:          params.QRJTI,
		InstallationID: strings.TrimSpace(params.InstallationID),
		ResultStatus:   strings.TrimSpace(params.ResultStatus),
		FailureCode:    NormalizeOptionalString(params.FailureCode),
		FailureMessage: NormalizeOptionalString(params.FailureMessage),
		CheckedInAt:    params.CheckedInAt,
		CreatedAt:      now,
		UpdatedAt:      now,
	}
	if params.ScannedAtDevice != nil {
		ts := params.ScannedAtDevice.UTC()
		item.ScannedAtDevice = &ts
	}
	if err := item.Validate(); err != nil {
		return nil, err
	}
	return item, nil
}

func (a *ExcursionAttendanceSyncAttempt) Validate() error {
	if a.ScanID == uuid.Nil {
		return ErrInvalidAttendanceSyncScanID
	}
	if a.ScheduleSlotID == uuid.Nil {
		return ErrInvalidAttendanceSyncScheduleSlot
	}
	if a.TouristUserID == uuid.Nil {
		return ErrInvalidAttendanceSyncParticipantID
	}
	if a.QRJTI == uuid.Nil {
		return ErrInvalidAttendanceSyncQRJTI
	}
	if strings.TrimSpace(a.InstallationID) == "" {
		return ErrInvalidAttendanceSyncInstallID
	}
	switch a.ResultStatus {
	case AttendanceSyncAttemptStatusAccepted,
		AttendanceSyncAttemptStatusAlreadyCheckedIn,
		AttendanceSyncAttemptStatusRejected:
		return nil
	default:
		return ErrInvalidAttendanceSyncStatus
	}
}
