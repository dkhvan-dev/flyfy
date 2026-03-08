package grpc

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/domain/model"
	filev1 "github.com/dkhvan-dev/flyfy/proto/gen/go/file/v1"
)

type Server struct {
	filev1.UnimplementedFileServiceServer
	useCase        *app.FileUseCase
	bindingUseCase *app.FileBindingUseCase
}

func NewServer(useCase *app.FileUseCase, bindingUseCase *app.FileBindingUseCase) *Server {
	return &Server{
		useCase:        useCase,
		bindingUseCase: bindingUseCase,
	}
}

func (s *Server) CreateUploadRequest(
	ctx context.Context,
	req *filev1.CreateUploadRequestRequest,
) (*filev1.CreateUploadRequestResponse, error) {
	var ownerType *string
	if req.GetOwnerType() != "" {
		v := req.GetOwnerType()
		ownerType = &v
	}

	var ownerID *string
	if req.GetOwnerId() != "" {
		v := req.GetOwnerId()
		ownerID = &v
	}

	var uploadedByUserID *string
	if req.GetUploadedByUserId() != "" {
		v := req.GetUploadedByUserId()
		uploadedByUserID = &v
	}

	resp, err := s.useCase.CreateUploadRequest(ctx, app.CreateUploadRequestInput{
		OriginalName:     req.GetOriginalName(),
		ContentType:      req.GetContentType(),
		SizeBytes:        req.GetSizeBytes(),
		Purpose:          req.GetPurpose(),
		Visibility:       req.GetVisibility(),
		OwnerType:        ownerType,
		OwnerID:          ownerID,
		UploadedByUserID: uploadedByUserID,
	})
	if err != nil {
		return nil, mapError(err)
	}

	return &filev1.CreateUploadRequestResponse{
		FileId:        resp.FileID.String(),
		ObjectKey:     resp.ObjectKey,
		Status:        resp.Status,
		UploadMethod:  resp.Method,
		UploadUrl:     resp.URL,
		UploadHeaders: resp.Headers,
		ExpiresAt:     resp.ExpiresAt.UTC().Format(time.RFC3339),
	}, nil
}

func (s *Server) CompleteUpload(
	ctx context.Context,
	req *filev1.CompleteUploadRequest,
) (*filev1.CompleteUploadResponse, error) {
	fileID, err := uuid.Parse(req.GetFileId())
	if err != nil {
		return nil, mapError(fmt.Errorf("%w: invalid file id", app.ErrInvalidFileID))
	}

	resp, err := s.useCase.CompleteUpload(ctx, fileID)
	if err != nil {
		return nil, mapError(err)
	}

	return &filev1.CompleteUploadResponse{
		FileId:              resp.FileID.String(),
		Status:              resp.Status,
		DetectedContentType: resp.DetectedContentType,
		SizeBytes:           resp.SizeBytes,
	}, nil
}

func (s *Server) GetFile(
	ctx context.Context,
	req *filev1.GetFileRequest,
) (*filev1.GetFileResponse, error) {
	fileID, err := uuid.Parse(req.GetFileId())
	if err != nil {
		return nil, mapError(fmt.Errorf("%w: invalid file id", app.ErrInvalidFileID))
	}

	file, err := s.useCase.GetFile(ctx, fileID)
	if err != nil {
		return nil, mapError(err)
	}

	var ownerType string
	if file.OwnerType != nil {
		ownerType = string(*file.OwnerType)
	}

	var ownerID string
	if file.OwnerID != nil {
		ownerID = file.OwnerID.String()
	}

	detectedContentType := ""
	if file.DetectedContentType != nil {
		detectedContentType = *file.DetectedContentType
	}

	return &filev1.GetFileResponse{
		FileId:              file.ID.String(),
		Bucket:              file.Bucket,
		ObjectKey:           file.ObjectKey,
		OriginalName:        file.OriginalName,
		ContentType:         file.ContentType,
		DetectedContentType: detectedContentType,
		SizeBytes:           file.SizeBytes,
		Purpose:             string(file.Purpose),
		Visibility:          string(file.Visibility),
		Status:              string(file.Status),
		OwnerType:           ownerType,
		OwnerId:             ownerID,
	}, nil
}

func (s *Server) CreateDownloadUrl(
	ctx context.Context,
	req *filev1.CreateDownloadUrlRequest,
) (*filev1.CreateDownloadUrlResponse, error) {
	fileID, err := uuid.Parse(req.GetFileId())
	if err != nil {
		return nil, mapError(fmt.Errorf("%w: invalid file id", app.ErrInvalidFileID))
	}

	url, expiresAt, err := s.useCase.CreateDownloadURL(ctx, fileID)
	if err != nil {
		return nil, mapError(err)
	}

	return &filev1.CreateDownloadUrlResponse{
		Url:       url,
		ExpiresAt: expiresAt.UTC().Format(time.RFC3339),
	}, nil
}

func (s *Server) SoftDeleteFile(
	ctx context.Context,
	req *filev1.SoftDeleteFileRequest,
) (*filev1.SoftDeleteFileResponse, error) {
	fileID, err := uuid.Parse(req.GetFileId())
	if err != nil {
		return nil, mapError(fmt.Errorf("%w: invalid file id", app.ErrInvalidFileID))
	}

	if err = s.useCase.SoftDelete(ctx, fileID); err != nil {
		return nil, mapError(err)
	}

	return &filev1.SoftDeleteFileResponse{
		Success: true,
	}, nil
}

func (s *Server) BindFile(
	ctx context.Context,
	req *filev1.BindFileRequest,
) (*filev1.BindFileResponse, error) {
	fileID, err := uuid.Parse(req.GetFileId())
	if err != nil {
		return nil, mapError(fmt.Errorf("%w: invalid file id", app.ErrInvalidFileID))
	}

	binding, err := s.bindingUseCase.BindFile(ctx, app.BindFileInput{
		FileID:          fileID,
		OwnerType:       req.GetOwnerType(),
		OwnerID:         req.GetOwnerId(),
		Purpose:         req.GetPurpose(),
		IsPrimary:       req.GetIsPrimary(),
		CreatedByUserID: stringPtrOrNil(req.GetCreatedByUserId()),
	})
	if err != nil {
		return nil, mapError(err)
	}

	return &filev1.BindFileResponse{
		Binding: toProtoBinding(binding),
	}, nil
}

func (s *Server) ListFileBindings(
	ctx context.Context,
	req *filev1.ListFileBindingsRequest,
) (*filev1.ListFileBindingsResponse, error) {
	fileID, err := uuid.Parse(req.GetFileId())
	if err != nil {
		return nil, mapError(fmt.Errorf("%w: invalid file id", app.ErrInvalidFileID))
	}

	items, err := s.bindingUseCase.ListByFileID(ctx, fileID)
	if err != nil {
		return nil, mapError(err)
	}

	resp := &filev1.ListFileBindingsResponse{
		Bindings: make([]*filev1.FileBinding, 0, len(items)),
	}
	for _, item := range items {
		resp.Bindings = append(resp.Bindings, toProtoBinding(item))
	}

	return resp, nil
}

func toProtoBinding(binding *model.FileBinding) *filev1.FileBinding {
	var deletedAt string
	if binding.DeletedAt != nil {
		deletedAt = binding.DeletedAt.UTC().Format(time.RFC3339)
	}

	var createdByUserID string
	if binding.CreatedByUserID != nil {
		createdByUserID = binding.CreatedByUserID.String()
	}

	return &filev1.FileBinding{
		Id:              binding.ID.String(),
		FileId:          binding.FileID.String(),
		OwnerType:       string(binding.OwnerType),
		OwnerId:         binding.OwnerID.String(),
		Purpose:         string(binding.Purpose),
		IsPrimary:       binding.IsPrimary,
		IsDeleted:       binding.IsDeleted,
		DeletedAt:       deletedAt,
		CreatedByUserId: createdByUserID,
		CreatedAt:       binding.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:       binding.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func stringPtrOrNil(v string) *string {
	if strings.TrimSpace(v) == "" {
		return nil
	}
	return &v
}
