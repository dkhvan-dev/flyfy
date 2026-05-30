package model

import (
	"errors"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/file-manager-service/internal/domain/enum"
)

var (
	ErrInvalidBindingID      = errors.New("invalid binding id")
	ErrInvalidBindingFileID  = errors.New("invalid binding file id")
	ErrInvalidBindingOwnerID = errors.New("invalid binding owner id")
	ErrInvalidBindingPurpose = errors.New("invalid binding purpose")
	ErrInvalidBindingOwner   = errors.New("invalid binding owner type")
)

type FileBinding struct {
	ID              uuid.UUID
	FileID          uuid.UUID
	OwnerType       enum.OwnerType
	OwnerID         uuid.UUID
	Purpose         enum.FilePurpose
	IsPrimary       bool
	IsDeleted       bool
	DeletedAt       *time.Time
	CreatedByUserID *uuid.UUID
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

type NewFileBindingParams struct {
	FileID          uuid.UUID
	OwnerType       enum.OwnerType
	OwnerID         uuid.UUID
	Purpose         enum.FilePurpose
	IsPrimary       bool
	CreatedByUserID *uuid.UUID
}

func NewFileBinding(params NewFileBindingParams) (*FileBinding, error) {
	now := time.Now().UTC()

	b := &FileBinding{
		ID:              uuid.New(),
		FileID:          params.FileID,
		OwnerType:       params.OwnerType,
		OwnerID:         params.OwnerID,
		Purpose:         params.Purpose,
		IsPrimary:       params.IsPrimary,
		CreatedByUserID: params.CreatedByUserID,
		CreatedAt:       now,
		UpdatedAt:       now,
	}

	if err := b.Validate(); err != nil {
		return nil, err
	}

	return b, nil
}

func (b *FileBinding) Validate() error {
	if b.ID == uuid.Nil {
		return ErrInvalidBindingID
	}
	if b.FileID == uuid.Nil {
		return ErrInvalidBindingFileID
	}
	if !b.OwnerType.IsValid() {
		return ErrInvalidBindingOwner
	}
	if b.OwnerID == uuid.Nil {
		return ErrInvalidBindingOwnerID
	}
	if !b.Purpose.IsValid() {
		return ErrInvalidBindingPurpose
	}
	return nil
}

func (b *FileBinding) SoftDelete() {
	if b.IsDeleted {
		return
	}
	now := time.Now().UTC()
	b.IsDeleted = true
	b.DeletedAt = &now
	b.UpdatedAt = now
}
