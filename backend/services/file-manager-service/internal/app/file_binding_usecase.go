package app

import (
	"context"
	"fmt"
	"strings"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/adapter/repository"
	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/domain/port"
)

type FileBindingUseCase struct {
	files    port.FileRepository
	bindings port.FileBindingRepository
}

func NewFileBindingUseCase(
	files port.FileRepository,
	bindings port.FileBindingRepository,
) *FileBindingUseCase {
	return &FileBindingUseCase{
		files:    files,
		bindings: bindings,
	}
}

type BindFileInput struct {
	FileID          uuid.UUID
	OwnerType       string
	OwnerID         string
	Purpose         string
	IsPrimary       bool
	CreatedByUserID *string
}

func (u *FileBindingUseCase) BindFile(ctx context.Context, input BindFileInput) (*model.FileBinding, error) {
	if input.FileID == uuid.Nil {
		return nil, ErrInvalidFileID
	}

	file, err := u.files.GetByID(ctx, input.FileID)
	if err != nil {
		return nil, fmt.Errorf("get file: %w", err)
	}
	if file == nil || file.IsDeleted {
		return nil, ErrFileNotFound
	}
	if file.Status != enum.FileStatusReady {
		return nil, fmt.Errorf("file is not ready for binding")
	}

	ownerType := enum.OwnerType(strings.TrimSpace(input.OwnerType))
	if !ownerType.IsValid() {
		return nil, ErrForbiddenOwnerType
	}

	ownerID, err := uuid.Parse(strings.TrimSpace(input.OwnerID))
	if err != nil {
		return nil, ErrInvalidOwnerID
	}

	purpose := enum.FilePurpose(strings.TrimSpace(input.Purpose))
	if !purpose.IsValid() {
		return nil, ErrForbiddenPurpose
	}

	var createdByUserID *uuid.UUID
	if input.CreatedByUserID != nil && strings.TrimSpace(*input.CreatedByUserID) != "" {
		parsed, err := uuid.Parse(strings.TrimSpace(*input.CreatedByUserID))
		if err != nil {
			return nil, ErrInvalidOwnerID
		}
		createdByUserID = &parsed
	}

	binding, err := model.NewFileBinding(model.NewFileBindingParams{
		FileID:          input.FileID,
		OwnerType:       ownerType,
		OwnerID:         ownerID,
		Purpose:         purpose,
		IsPrimary:       input.IsPrimary,
		CreatedByUserID: createdByUserID,
	})
	if err != nil {
		return nil, fmt.Errorf("new binding: %w", err)
	}

	err = u.bindings.CreateWithPrimarySwitchTx(ctx, binding)
	if err != nil {
		if err == repository.ErrConflict {
			return nil, ErrIdempotencyConflict
		}
		return nil, fmt.Errorf("create binding: %w", err)
	}

	return binding, nil
}

func (u *FileBindingUseCase) ListByFileID(ctx context.Context, fileID uuid.UUID) ([]*model.FileBinding, error) {
	if fileID == uuid.Nil {
		return nil, ErrInvalidFileID
	}

	file, err := u.files.GetByID(ctx, fileID)
	if err != nil {
		return nil, fmt.Errorf("get file: %w", err)
	}
	if file == nil || file.IsDeleted {
		return nil, ErrFileNotFound
	}

	return u.bindings.ListByFileID(ctx, fileID)
}
