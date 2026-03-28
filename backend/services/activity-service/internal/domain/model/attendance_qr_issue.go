package model

import (
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidAttendanceQRJTI        = errors.New("invalid attendance qr jti")
	ErrInvalidAttendanceQRActivityID = errors.New("invalid attendance qr activity id")
	ErrInvalidAttendanceQRHostUserID = errors.New("invalid attendance qr host user id")
	ErrInvalidAttendanceQRTimeRange  = errors.New("invalid attendance qr time range")
)

type AttendanceQRIssue struct {
	JTI         uuid.UUID
	ActivityID  uuid.UUID
	HostUserID  uuid.UUID
	IssuedAt    time.Time
	ExpiresAt   time.Time
	UsableUntil time.Time
	CreatedAt   time.Time
}

type NewAttendanceQRIssueParams struct {
	ActivityID    uuid.UUID
	HostUserID    uuid.UUID
	IssuedAt      time.Time
	TTL           time.Duration
	OfflineWindow time.Duration
}

func NewAttendanceQRIssue(params NewAttendanceQRIssueParams) (*AttendanceQRIssue, error) {
	issuedAt := params.IssuedAt.UTC()
	item := &AttendanceQRIssue{
		JTI:         uuid.New(),
		ActivityID:  params.ActivityID,
		HostUserID:  params.HostUserID,
		IssuedAt:    issuedAt,
		ExpiresAt:   issuedAt.Add(params.TTL),
		UsableUntil: issuedAt.Add(params.OfflineWindow),
		CreatedAt:   time.Now().UTC(),
	}

	if err := item.Validate(); err != nil {
		return nil, err
	}

	return item, nil
}

func (i *AttendanceQRIssue) Validate() error {
	if i.JTI == uuid.Nil {
		return ErrInvalidAttendanceQRJTI
	}
	if i.ActivityID == uuid.Nil {
		return ErrInvalidAttendanceQRActivityID
	}
	if i.HostUserID == uuid.Nil {
		return ErrInvalidAttendanceQRHostUserID
	}
	if !i.ExpiresAt.After(i.IssuedAt) || !i.UsableUntil.After(i.ExpiresAt) {
		return ErrInvalidAttendanceQRTimeRange
	}
	return nil
}
