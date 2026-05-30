package model

import (
	"errors"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/activity-service/internal/domain/enum"
)

var (
	ErrInvalidParticipantID     = errors.New("invalid participant id")
	ErrInvalidParticipantUserID = errors.New("invalid participant user id")
	ErrInvalidParticipantStatus = errors.New("invalid participant status")
)

type ActivityParticipant struct {
	ID         uuid.UUID
	ActivityID uuid.UUID
	UserID     uuid.UUID

	Status                enum.ParticipantStatus
	JoinedAt              time.Time
	ApprovedAt            *time.Time
	WaitlistedAt          *time.Time
	PaymentDueAt          *time.Time
	PaymentTransactionID  *uuid.UUID
	PaidAt                *time.Time
	AttendanceConfirmedAt *time.Time
	CheckedInAt           *time.Time
	AttendedAt            *time.Time
	CancelledAt           *time.Time
	CancelledByUserID     *uuid.UUID
	CancelReason          *string

	CreatedAt time.Time
	UpdatedAt time.Time
}

type NewActivityParticipantParams struct {
	ActivityID uuid.UUID
	UserID     uuid.UUID
	Status     enum.ParticipantStatus
}

func NewActivityParticipant(params NewActivityParticipantParams) (*ActivityParticipant, error) {
	now := time.Now().UTC()

	item := &ActivityParticipant{
		ID:         uuid.New(),
		ActivityID: params.ActivityID,
		UserID:     params.UserID,
		Status:     params.Status,
		JoinedAt:   now,
		CreatedAt:  now,
		UpdatedAt:  now,
	}

	if err := item.Validate(); err != nil {
		return nil, err
	}

	return item, nil
}

func (p *ActivityParticipant) Validate() error {
	if p.ID == uuid.Nil || p.ActivityID == uuid.Nil {
		return ErrInvalidParticipantID
	}
	if p.UserID == uuid.Nil {
		return ErrInvalidParticipantUserID
	}
	if !p.Status.IsValid() {
		return ErrInvalidParticipantStatus
	}
	return nil
}

func (p *ActivityParticipant) SetStatus(status enum.ParticipantStatus, now time.Time) error {
	if !status.IsValid() {
		return ErrInvalidParticipantStatus
	}

	p.Status = status
	p.UpdatedAt = now.UTC()

	switch status {
	case enum.ParticipantStatusApproved:
		ts := now.UTC()
		p.ApprovedAt = &ts
	case enum.ParticipantStatusWaitlisted:
		ts := now.UTC()
		p.WaitlistedAt = &ts
	case enum.ParticipantStatusPendingPayment:
		ts := now.UTC()
		if p.ApprovedAt == nil {
			p.ApprovedAt = &ts
		}
	case enum.ParticipantStatusConfirmed:
		ts := now.UTC()
		if p.PaidAt == nil {
			p.PaidAt = &ts
		}
	case enum.ParticipantStatusCheckedIn:
		ts := now.UTC()
		p.CheckedInAt = &ts
	case enum.ParticipantStatusAttended:
		ts := now.UTC()
		p.AttendedAt = &ts
	case enum.ParticipantStatusCancelled:
		ts := now.UTC()
		p.CancelledAt = &ts
	case enum.ParticipantStatusLateCancelled:
		ts := now.UTC()
		p.CancelledAt = &ts
	case enum.ParticipantStatusCancelledByActivity:
		ts := now.UTC()
		p.CancelledAt = &ts
	}

	return nil
}
