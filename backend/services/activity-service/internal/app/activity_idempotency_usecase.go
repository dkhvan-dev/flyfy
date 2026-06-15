package app

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"strings"

	"kz/inflap/backend/services/activity-service/internal/domain/model"
)

type CreateActivityFromPostInput struct {
	IdempotencyKey string
	SourceService  string
	SourcePostID   string
	Input          CreateActivityInput
}

func (u *ActivityUseCase) CreateActivityFromPost(
	ctx context.Context,
	input CreateActivityFromPostInput,
) (*model.Activity, error) {
	if u == nil || u.repo == nil {
		return nil, fmt.Errorf("activity usecase dependencies are required")
	}
	key := strings.TrimSpace(input.IdempotencyKey)
	if key == "" {
		return nil, model.ErrInvalidActivityIdempotencyKey
	}
	if strings.TrimSpace(input.SourceService) == "" {
		input.SourceService = "feed-service"
	}
	if strings.TrimSpace(input.SourcePostID) == "" {
		return nil, model.ErrInvalidActivityIdempotencyKey
	}

	record, err := model.NewActivityIdempotencyKey(model.ActivityIdempotencyKeyParams{
		Key:                key,
		SourceService:      input.SourceService,
		SourceResourceType: "post",
		SourceResourceID:   input.SourcePostID,
		HostUserID:         input.Input.HostUserID,
		RequestHash:        activityIdempotencyRequestHash(input.Input),
	})
	if err != nil {
		return nil, err
	}

	existing, acquired, err := u.repo.AcquireActivityIdempotencyKey(ctx, record)
	if err != nil {
		return nil, fmt.Errorf("acquire activity idempotency key: %w", err)
	}
	if !acquired {
		return u.resolveExistingActivityIdempotency(ctx, existing, record.RequestHash)
	}

	item, err := u.CreateActivity(ctx, input.Input)
	if err != nil {
		_ = u.repo.FailActivityIdempotencyKey(ctx, key, safeActivityIdempotencyError(err))
		return nil, err
	}
	if err = u.repo.CompleteActivityIdempotencyKey(ctx, key, item.ID); err != nil {
		return nil, fmt.Errorf("complete activity idempotency key: %w", err)
	}
	return item, nil
}

func (u *ActivityUseCase) resolveExistingActivityIdempotency(
	ctx context.Context,
	existing *model.ActivityIdempotencyKey,
	requestHash string,
) (*model.Activity, error) {
	if existing == nil {
		return nil, ErrActivityCreationInProgress
	}
	if strings.TrimSpace(existing.RequestHash) != requestHash {
		return nil, ErrActivityIdempotencyConflict
	}
	if existing.Status != model.ActivityIdempotencyStatusCompleted || existing.ActivityID == nil {
		return nil, ErrActivityCreationInProgress
	}
	return u.GetActivityByID(ctx, *existing.ActivityID)
}

func activityIdempotencyRequestHash(input CreateActivityInput) string {
	raw, err := json.Marshal(input)
	if err != nil {
		sum := sha256.Sum256([]byte(fmt.Sprintf("%#v", input)))
		return hex.EncodeToString(sum[:])
	}
	sum := sha256.Sum256(raw)
	return hex.EncodeToString(sum[:])
}

func safeActivityIdempotencyError(err error) string {
	if err == nil {
		return ""
	}
	value := strings.TrimSpace(err.Error())
	if len(value) > 512 {
		return value[:512]
	}
	return value
}
