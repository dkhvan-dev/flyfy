package model

import (
	"errors"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/user-service/internal/domain/enum"
)

var (
	ErrInvalidRoleID     = errors.New("invalid role id")
	ErrInvalidRoleUserID = errors.New("invalid role user id")
	ErrInvalidSystemRole = errors.New("invalid system role")
)

type UserSystemRole struct {
	ID        uuid.UUID
	UserID    uuid.UUID
	Role      enum.SystemRole
	GrantedAt time.Time
	GrantedBy *uuid.UUID
	CreatedAt time.Time
}

type NewUserSystemRoleParams struct {
	UserID    uuid.UUID
	Role      enum.SystemRole
	GrantedBy *uuid.UUID
}

func NewUserSystemRole(params NewUserSystemRoleParams) (*UserSystemRole, error) {
	now := time.Now().UTC()

	role := &UserSystemRole{
		ID:        uuid.New(),
		UserID:    params.UserID,
		Role:      params.Role,
		GrantedAt: now,
		GrantedBy: params.GrantedBy,
		CreatedAt: now,
	}

	if err := role.Validate(); err != nil {
		return nil, err
	}

	return role, nil
}

func (r *UserSystemRole) Validate() error {
	if r.ID == uuid.Nil {
		return ErrInvalidRoleID
	}
	if r.UserID == uuid.Nil {
		return ErrInvalidRoleUserID
	}
	if !r.Role.IsValid() {
		return ErrInvalidSystemRole
	}
	return nil
}
