package port

import (
	"context"

	"kz/inflap/backend/services/file-manager-service/internal/domain/model"
)

type IdempotencyRepository interface {
	GetByOperationAndKey(ctx context.Context, operation string, key string) (*model.IdempotencyRecord, error)
	Create(ctx context.Context, record *model.IdempotencyRecord) error
	UpdateResponse(
		ctx context.Context,
		operation string,
		key string,
		requestFingerprint string,
		statusCode int,
		responseBody []byte,
		resourceType *string,
		resourceID *string,
	) error
}
