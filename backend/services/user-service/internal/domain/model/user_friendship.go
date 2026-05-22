package model

import (
	"errors"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/user-service/internal/domain/enum"
)

var (
	ErrInvalidFriendshipID     = errors.New("invalid friendship id")
	ErrInvalidFriendshipUserID = errors.New("invalid friendship user id")
	ErrInvalidFriendshipStatus = errors.New("invalid friendship status")
)

type UserFriendship struct {
	ID              uuid.UUID
	RequesterUserID uuid.UUID
	AddresseeUserID uuid.UUID
	Status          enum.FriendshipStatus
	RequestedAt     time.Time
	RespondedAt     *time.Time
	UpdatedAt       time.Time
}

type UserFriendRequest struct {
	Profile     *UserProfile
	RequestedAt time.Time
}

func (f *UserFriendship) Validate() error {
	if f.ID == uuid.Nil {
		return ErrInvalidFriendshipID
	}
	if f.RequesterUserID == uuid.Nil || f.AddresseeUserID == uuid.Nil {
		return ErrInvalidFriendshipUserID
	}
	if f.RequesterUserID == f.AddresseeUserID {
		return ErrInvalidFriendshipUserID
	}
	if !f.Status.IsValid() {
		return ErrInvalidFriendshipStatus
	}
	return nil
}
