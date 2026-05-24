package app

import (
	"context"

	"github.com/google/uuid"
)

type FileManagerClient interface {
	ValidateGuideDocumentFile(ctx context.Context, fileID uuid.UUID) error
	CreateGuideDocumentDownloadURL(ctx context.Context, fileID uuid.UUID) (string, error)
	BindGuideDocumentToVerificationRequest(
		ctx context.Context,
		fileID uuid.UUID,
		verificationRequestID uuid.UUID,
		createdByUserID *uuid.UUID,
	) error
}
