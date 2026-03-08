package model

import (
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidReputationUserID = errors.New("invalid reputation user id")
	ErrInvalidScoreValue       = errors.New("invalid score value")
	ErrInvalidCounterValue     = errors.New("invalid counter value")
)

type UserReputation struct {
	UserID              uuid.UUID
	TrustScore          int
	RiskScore           int
	CompletedBookings   int
	CompletedActivities int
	CancellationsCount  int
	ReportsCount        int
	CreatedAt           time.Time
	UpdatedAt           time.Time
}

type NewUserReputationParams struct {
	UserID uuid.UUID
}

func NewUserReputation(params NewUserReputationParams) (*UserReputation, error) {
	now := time.Now().UTC()

	rep := &UserReputation{
		UserID:              params.UserID,
		TrustScore:          0,
		RiskScore:           0,
		CompletedBookings:   0,
		CompletedActivities: 0,
		CancellationsCount:  0,
		ReportsCount:        0,
		CreatedAt:           now,
		UpdatedAt:           now,
	}

	if err := rep.Validate(); err != nil {
		return nil, err
	}

	return rep, nil
}

func (r *UserReputation) Validate() error {
	if r.UserID == uuid.Nil {
		return ErrInvalidReputationUserID
	}
	if r.TrustScore < 0 || r.RiskScore < 0 {
		return ErrInvalidScoreValue
	}
	if r.CompletedBookings < 0 ||
		r.CompletedActivities < 0 ||
		r.CancellationsCount < 0 ||
		r.ReportsCount < 0 {
		return ErrInvalidCounterValue
	}
	return nil
}
