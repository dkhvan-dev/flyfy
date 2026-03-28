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
	ErrInvalidAttendanceSyncScanID        = errors.New("invalid attendance sync scan id")
	ErrInvalidAttendanceSyncActivityID    = errors.New("invalid attendance sync activity id")
	ErrInvalidAttendanceSyncParticipantID = errors.New("invalid attendance sync participant user id")
	ErrInvalidAttendanceSyncQRJTI         = errors.New("invalid attendance sync qr jti")
	ErrInvalidAttendanceSyncInstallID     = errors.New("invalid attendance sync installation id")
	ErrInvalidAttendanceSyncStatus        = errors.New("invalid attendance sync status")
)

type AttendanceSyncAttempt struct {
	ScanID            uuid.UUID
	ActivityID        uuid.UUID
	ParticipantUserID uuid.UUID
	QRJTI             uuid.UUID
	InstallationID    string
	ScannedAtDevice   *time.Time
	ResultStatus      string
	FailureCode       *string
	FailureMessage    *string
	CheckedInAt       *time.Time
	CreatedAt         time.Time
	UpdatedAt         time.Time
}

type NewAttendanceSyncAttemptParams struct {
	ScanID            uuid.UUID
	ActivityID        uuid.UUID
	ParticipantUserID uuid.UUID
	QRJTI             uuid.UUID
	InstallationID    string
	ScannedAtDevice   *time.Time
	ResultStatus      string
	FailureCode       *string
	FailureMessage    *string
	CheckedInAt       *time.Time
}

func NewAttendanceSyncAttempt(params NewAttendanceSyncAttemptParams) (*AttendanceSyncAttempt, error) {
	now := time.Now().UTC()
	item := &AttendanceSyncAttempt{
		ScanID:            params.ScanID,
		ActivityID:        params.ActivityID,
		ParticipantUserID: params.ParticipantUserID,
		QRJTI:             params.QRJTI,
		InstallationID:    strings.TrimSpace(params.InstallationID),
		ResultStatus:      strings.TrimSpace(params.ResultStatus),
		FailureCode:       NormalizeOptionalString(params.FailureCode),
		FailureMessage:    NormalizeOptionalString(params.FailureMessage),
		CheckedInAt:       params.CheckedInAt,
		CreatedAt:         now,
		UpdatedAt:         now,
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

func (a *AttendanceSyncAttempt) Validate() error {
	if a.ScanID == uuid.Nil {
		return ErrInvalidAttendanceSyncScanID
	}
	if a.ActivityID == uuid.Nil {
		return ErrInvalidAttendanceSyncActivityID
	}
	if a.ParticipantUserID == uuid.Nil {
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
