package model

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/user-service/internal/domain/enum"
)

var (
	ErrInvalidUserID        = errors.New("invalid user id")
	ErrInvalidAuthSubjectID = errors.New("invalid auth subject id")
	ErrInvalidUserStatus    = errors.New("invalid user status")
)

type User struct {
	ID            uuid.UUID
	AuthSubjectID string
	Status        enum.UserStatus
	PrimaryPhone  *string
	PrimaryEmail  *string
	IsDeleted     bool
	DeletedAt     *time.Time
	LastSeenAt    *time.Time
	CreatedAt     time.Time
	UpdatedAt     time.Time
}

type NewUserParams struct {
	AuthSubjectID string
	PrimaryPhone  *string
	PrimaryEmail  *string
}

func NewUser(params NewUserParams) (*User, error) {
	now := time.Now().UTC()

	user := &User{
		ID:            uuid.New(),
		AuthSubjectID: strings.TrimSpace(params.AuthSubjectID),
		Status:        enum.UserStatusActive,
		PrimaryPhone:  normalizeOptionalString(params.PrimaryPhone),
		PrimaryEmail:  normalizeOptionalString(params.PrimaryEmail),
		IsDeleted:     false,
		LastSeenAt:    &now,
		CreatedAt:     now,
		UpdatedAt:     now,
	}

	if err := user.Validate(); err != nil {
		return nil, err
	}

	return user, nil
}

func (u *User) Validate() error {
	if u.ID == uuid.Nil {
		return ErrInvalidUserID
	}
	if strings.TrimSpace(u.AuthSubjectID) == "" {
		return ErrInvalidAuthSubjectID
	}
	if !u.Status.IsValid() {
		return ErrInvalidUserStatus
	}
	return nil
}

func (u *User) Block() error {
	if u.ID == uuid.Nil {
		return ErrInvalidUserID
	}
	u.Status = enum.UserStatusBlocked
	u.UpdatedAt = time.Now().UTC()
	return nil
}

func (u *User) SoftDelete() error {
	if u.ID == uuid.Nil {
		return ErrInvalidUserID
	}

	now := time.Now().UTC()
	u.Status = enum.UserStatusDeleted
	u.IsDeleted = true
	u.DeletedAt = &now
	u.UpdatedAt = now
	return nil
}

func normalizeOptionalString(v *string) *string {
	if v == nil {
		return nil
	}
	s := strings.TrimSpace(*v)
	if s == "" {
		return nil
	}
	return &s
}
