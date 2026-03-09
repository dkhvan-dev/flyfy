package app

import (
	"context"

	"github.com/google/uuid"
)

type FileManagerClient interface {
	ValidateGuideDocumentFile(ctx context.Context, fileID uuid.UUID) error
	BindGuideDocumentToVerificationRequest(
		ctx context.Context,
		fileID uuid.UUID,
		verificationRequestID uuid.UUID,
		createdByUserID *uuid.UUID,
	) error
}
