package app

import (
	"context"
	"errors"
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
	fraud    port.FraudEvaluator
}

func NewFileBindingUseCase(
	files port.FileRepository,
	bindings port.FileBindingRepository,
) *FileBindingUseCase {
	return NewFileBindingUseCaseWithFraud(files, bindings, nil)
}

func NewFileBindingUseCaseWithFraud(
	files port.FileRepository,
	bindings port.FileBindingRepository,
	fraud port.FraudEvaluator,
) *FileBindingUseCase {
	return &FileBindingUseCase{
		files:    files,
		bindings: bindings,
		fraud:    fraud,
	}
}

type BindFileInput struct {
	FileID          uuid.UUID
	OwnerType       string
	OwnerID         string
	Purpose         string
	IsPrimary       bool
	CreatedByUserID *string
	ClientIP        string
	DeviceID        string
	UserAgent       string
}

type ListFileBindingsInput struct {
	OwnerType string
	OwnerID   string
	Purpose   string
	Limit     int
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
		return nil, ErrFileNotReady
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
	if file.Purpose != purpose {
		return nil, ErrFilePurposeMismatch
	}

	var createdByUserID *uuid.UUID
	if input.CreatedByUserID != nil && strings.TrimSpace(*input.CreatedByUserID) != "" {
		parsed, err := uuid.Parse(strings.TrimSpace(*input.CreatedByUserID))
		if err != nil {
			return nil, ErrInvalidOwnerID
		}
		createdByUserID = &parsed
	}
	if createdByUserID != nil && file.UploadedByUserID != nil && *createdByUserID != *file.UploadedByUserID {
		return nil, ErrFileOwnershipMismatch
	}

	if err = u.enforceFraud(ctx, port.FraudAssessmentInput{
		Action:      "FILE_BIND",
		ActorUserID: createdByUserID,
		FileID:      &file.ID,
		OwnerType:   &ownerType,
		OwnerID:     &ownerID,
		Purpose:     purpose,
		ContentType: valueOrEmpty(file.DetectedContentType),
		SizeBytes:   file.SizeBytes,
		ClientIP:    input.ClientIP,
		DeviceID:    input.DeviceID,
		UserAgent:   input.UserAgent,
		Metadata: map[string]any{
			"bindingPurpose": string(purpose),
			"isPrimary":      input.IsPrimary,
		},
	}); err != nil {
		return nil, err
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
		if errors.Is(err, repository.ErrConflict) {
			existing, findErr := u.findExistingLiveBinding(ctx, binding)
			if findErr != nil {
				return nil, findErr
			}
			if existing != nil {
				return existing, nil
			}
			return nil, ErrIdempotencyConflict
		}
		return nil, fmt.Errorf("create binding: %w", err)
	}

	return binding, nil
}

func (u *FileBindingUseCase) enforceFraud(ctx context.Context, input port.FraudAssessmentInput) error {
	if u.fraud == nil {
		return nil
	}

	decision, err := u.fraud.AssessFile(ctx, input)
	if err != nil {
		return fmt.Errorf("assess file binding fraud: %w", err)
	}
	if decision == nil || decision.ShadowMode || decision.Decision == "" || decision.Decision == port.FraudDecisionAllow {
		return nil
	}
	return ErrFraudRejected
}

func (u *FileBindingUseCase) findExistingLiveBinding(
	ctx context.Context,
	binding *model.FileBinding,
) (*model.FileBinding, error) {
	bindings, err := u.bindings.ListByFileID(ctx, binding.FileID)
	if err != nil {
		return nil, fmt.Errorf("list existing file bindings: %w", err)
	}

	for _, existing := range bindings {
		if existing == nil || existing.IsDeleted {
			continue
		}
		if existing.OwnerType == binding.OwnerType &&
			existing.OwnerID == binding.OwnerID &&
			existing.Purpose == binding.Purpose {
			return existing, nil
		}
	}

	return nil, nil
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

func (u *FileBindingUseCase) ListByOwnerAndPurpose(
	ctx context.Context,
	input ListFileBindingsInput,
) ([]*model.FileBinding, error) {
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

	limit := input.Limit
	if limit <= 0 {
		limit = 100
	}
	if limit > 200 {
		limit = 200
	}

	return u.bindings.ListByOwnerAndPurpose(ctx, ownerType, ownerID, purpose, limit)
}
