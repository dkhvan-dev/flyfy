package app

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/domain/port"
)

const (
	OperationCreateUploadRequest = "create_upload_request"
	DefaultIdempotencyTTL        = 24 * time.Hour
)

type IdempotencyService struct {
	repo port.IdempotencyRepository
}

func NewIdempotencyService(repo port.IdempotencyRepository) *IdempotencyService {
	return &IdempotencyService{repo: repo}
}

func (s *IdempotencyService) BuildFingerprint(payload any) (string, error) {
	raw, err := json.Marshal(payload)
	if err != nil {
		return "", fmt.Errorf("marshal fingerprint payload: %w", err)
	}

	sum := sha256.Sum256(raw)
	return hex.EncodeToString(sum[:]), nil
}

func (s *IdempotencyService) TryGetReplay(
	ctx context.Context,
	operation string,
	key string,
	fingerprint string,
) (*model.IdempotencyRecord, error) {
	record, err := s.repo.GetByOperationAndKey(ctx, operation, key)
	if err != nil || record == nil {
		return nil, err
	}

	if time.Now().UTC().After(record.ExpiresAt) {
		return nil, nil
	}

	if record.RequestFingerprint != fingerprint {
		return nil, ErrIdempotencyConflict
	}

	if len(record.ResponseBody) == 0 {
		return nil, nil
	}

	return record, nil
}

func (s *IdempotencyService) Reserve(
	ctx context.Context,
	operation string,
	key string,
	fingerprint string,
	createdByUserID *uuid.UUID,
) error {
	existing, err := s.repo.GetByOperationAndKey(ctx, operation, key)
	if err != nil {
		return err
	}

	if existing != nil {
		if time.Now().UTC().After(existing.ExpiresAt) {
			return ErrIdempotencyConflict
		}
		if existing.RequestFingerprint != fingerprint {
			return ErrIdempotencyConflict
		}
		return nil
	}

	now := time.Now().UTC()
	record := &model.IdempotencyRecord{
		ID:                 uuid.New(),
		Operation:          operation,
		IdempotencyKey:     key,
		RequestFingerprint: fingerprint,
		CreatedByUserID:    createdByUserID,
		ExpiresAt:          now.Add(DefaultIdempotencyTTL),
		CreatedAt:          now,
		UpdatedAt:          now,
	}

	return s.repo.Create(ctx, record)
}
