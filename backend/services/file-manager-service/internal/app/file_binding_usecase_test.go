package app

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/adapter/repository"
	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/domain/model"
)

func TestBindFileReturnsExistingBindingOnExactDuplicate(t *testing.T) {
	fileID := uuid.New()
	ownerID := uuid.New()
	existing := mustFileBinding(t, model.NewFileBindingParams{
		FileID:    fileID,
		OwnerType: enum.OwnerTypeUser,
		OwnerID:   ownerID,
		Purpose:   enum.FilePurposeChatSticker,
	})

	files := &fakeFileRepository{
		file: &model.File{
			ID:        fileID,
			Purpose:   enum.FilePurposeChatSticker,
			Status:    enum.FileStatusReady,
			IsDeleted: false,
		},
	}
	bindings := &fakeFileBindingRepository{
		createErr:      repository.ErrConflict,
		fileIDBindings: []*model.FileBinding{existing},
	}
	useCase := NewFileBindingUseCase(files, bindings)

	binding, err := useCase.BindFile(context.Background(), BindFileInput{
		FileID:    fileID,
		OwnerType: string(enum.OwnerTypeUser),
		OwnerID:   ownerID.String(),
		Purpose:   string(enum.FilePurposeChatSticker),
	})

	if err != nil {
		t.Fatalf("expected duplicate binding to be idempotent, got %v", err)
	}
	if binding == nil || binding.ID != existing.ID {
		t.Fatalf("binding = %+v, want existing %+v", binding, existing)
	}
}

func TestBindFileReturnsFileNotReadySentinel(t *testing.T) {
	fileID := uuid.New()
	useCase := NewFileBindingUseCase(
		&fakeFileRepository{
			file: &model.File{
				ID:        fileID,
				Purpose:   enum.FilePurposeChatSticker,
				Status:    enum.FileStatusUploaded,
				IsDeleted: false,
			},
		},
		&fakeFileBindingRepository{},
	)

	_, err := useCase.BindFile(context.Background(), BindFileInput{
		FileID:    fileID,
		OwnerType: string(enum.OwnerTypeUser),
		OwnerID:   uuid.NewString(),
		Purpose:   string(enum.FilePurposeChatSticker),
	})

	if !errors.Is(err, ErrFileNotReady) {
		t.Fatalf("error = %v, want ErrFileNotReady", err)
	}
}

func TestBindFileRejectsPurposeMismatch(t *testing.T) {
	fileID := uuid.New()
	useCase := NewFileBindingUseCase(
		&fakeFileRepository{
			file: &model.File{
				ID:        fileID,
				Purpose:   enum.FilePurposeChatAttachment,
				Status:    enum.FileStatusReady,
				IsDeleted: false,
			},
		},
		&fakeFileBindingRepository{},
	)

	_, err := useCase.BindFile(context.Background(), BindFileInput{
		FileID:    fileID,
		OwnerType: string(enum.OwnerTypeUser),
		OwnerID:   uuid.NewString(),
		Purpose:   string(enum.FilePurposeChatSticker),
	})

	if !errors.Is(err, ErrFilePurposeMismatch) {
		t.Fatalf("error = %v, want ErrFilePurposeMismatch", err)
	}
}

type fakeFileRepository struct {
	file *model.File
}

func (f *fakeFileRepository) Create(context.Context, *model.File) error {
	return nil
}

func (f *fakeFileRepository) GetByID(context.Context, uuid.UUID) (*model.File, error) {
	return f.file, nil
}

func (f *fakeFileRepository) GetByObjectKey(context.Context, string) (*model.File, error) {
	return nil, nil
}

func (f *fakeFileRepository) Update(context.Context, *model.File) error {
	return nil
}

func (f *fakeFileRepository) SoftDelete(context.Context, uuid.UUID) error {
	return nil
}

type fakeFileBindingRepository struct {
	createErr      error
	fileIDBindings []*model.FileBinding
}

func (f *fakeFileBindingRepository) Create(context.Context, *model.FileBinding) error {
	return f.createErr
}

func (f *fakeFileBindingRepository) CreateWithPrimarySwitchTx(context.Context, *model.FileBinding) error {
	return f.createErr
}

func (f *fakeFileBindingRepository) GetPrimaryByOwnerAndPurpose(
	context.Context,
	enum.OwnerType,
	uuid.UUID,
	enum.FilePurpose,
) (*model.FileBinding, error) {
	return nil, nil
}

func (f *fakeFileBindingRepository) SoftDeletePrimaryByOwnerAndPurpose(
	context.Context,
	enum.OwnerType,
	uuid.UUID,
	enum.FilePurpose,
) error {
	return nil
}

func (f *fakeFileBindingRepository) ListByFileID(context.Context, uuid.UUID) ([]*model.FileBinding, error) {
	return f.fileIDBindings, nil
}

func (f *fakeFileBindingRepository) ListByOwnerAndPurpose(
	context.Context,
	enum.OwnerType,
	uuid.UUID,
	enum.FilePurpose,
	int,
) ([]*model.FileBinding, error) {
	return nil, nil
}

func mustFileBinding(t testing.TB, params model.NewFileBindingParams) *model.FileBinding {
	t.Helper()
	binding, err := model.NewFileBinding(params)
	if err != nil {
		t.Fatalf("NewFileBinding error: %v", err)
	}
	return binding
}
