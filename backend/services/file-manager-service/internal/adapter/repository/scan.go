package repository

import (
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"kz/inflap/backend/services/file-manager-service/internal/domain/enum"
	"kz/inflap/backend/services/file-manager-service/internal/domain/model"
)

type rowScanner interface {
	Scan(dest ...any) error
}

func scanFile(row rowScanner) (*model.File, error) {
	var (
		file             model.File
		visibility       string
		purpose          string
		status           string
		policyStatus     string
		ownerType        *string
		ownerID          *uuid.UUID
		uploadedByUserID *uuid.UUID
	)

	err := row.Scan(
		&file.ID,
		&file.Provider,
		&file.Bucket,
		&file.ObjectKey,
		&file.OriginalName,
		&file.StoredName,
		&file.Extension,
		&file.ContentType,
		&file.DetectedContentType,
		&file.SizeBytes,
		&file.ChecksumSHA256,
		&visibility,
		&purpose,
		&status,
		&ownerType,
		&ownerID,
		&uploadedByUserID,
		&file.UploadExpiresAt,
		&policyStatus,
		&file.PolicyReasonCode,
		&file.PolicyDecisionID,
		&file.IsDeleted,
		&file.DeletedAt,
		&file.CreatedAt,
		&file.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}

	file.Visibility = enum.FileVisibility(visibility)
	file.Purpose = enum.FilePurpose(purpose)
	file.Status = enum.FileStatus(status)
	file.PolicyStatus = model.FilePolicyStatus(policyStatus)
	if file.PolicyStatus == "" {
		file.PolicyStatus = model.FilePolicyAllowed
	}
	file.OwnerID = ownerID
	file.UploadedByUserID = uploadedByUserID

	if ownerType != nil {
		v := enum.OwnerType(*ownerType)
		file.OwnerType = &v
	}

	return &file, nil
}

func ownerTypeToDB(ownerType *enum.OwnerType) *string {
	if ownerType == nil {
		return nil
	}
	v := string(*ownerType)
	return &v
}
