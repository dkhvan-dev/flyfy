package grpc

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/chat-service/internal/domain/port"
	activityv1 "kz/inflap/proto/gen/go/activity/v1"
)

type ActivityLifecycleResolver struct {
	client activityv1.ActivityServiceClient
}

func NewActivityLifecycleResolver(client activityv1.ActivityServiceClient) *ActivityLifecycleResolver {
	return &ActivityLifecycleResolver{client: client}
}

func (r *ActivityLifecycleResolver) GetActivityLifecycle(
	ctx context.Context,
	activityID uuid.UUID,
) (*port.ActivityLifecycle, error) {
	resp, err := r.client.GetActivityById(ctx, &activityv1.GetActivityByIdRequest{
		ActivityId: activityID.String(),
	})
	if err != nil {
		return nil, fmt.Errorf("get activity lifecycle: %w", err)
	}

	item := resp.GetActivity()
	if item == nil {
		return nil, fmt.Errorf("activity lifecycle is empty")
	}

	endAt, err := parseProtoTime(item.GetEndAt())
	if err != nil {
		return nil, fmt.Errorf("parse activity end_at: %w", err)
	}

	cancelledAt, err := parseOptionalProtoTime(item.GetCancelledAt())
	if err != nil {
		return nil, fmt.Errorf("parse activity cancelled_at: %w", err)
	}
	completedAt, err := parseOptionalProtoTime(item.GetCompletedAt())
	if err != nil {
		return nil, fmt.Errorf("parse activity completed_at: %w", err)
	}

	return &port.ActivityLifecycle{
		ActivityID:  activityID,
		EndAt:       endAt,
		CancelledAt: cancelledAt,
		CompletedAt: completedAt,
	}, nil
}

func parseOptionalProtoTime(value string) (*time.Time, error) {
	value = strings.TrimSpace(value)
	if value == "" {
		return nil, nil
	}
	parsed, err := parseProtoTime(value)
	if err != nil {
		return nil, err
	}
	return &parsed, nil
}

func parseProtoTime(value string) (time.Time, error) {
	parsed, err := time.Parse(time.RFC3339, strings.TrimSpace(value))
	if err != nil {
		return time.Time{}, err
	}
	return parsed.UTC(), nil
}
