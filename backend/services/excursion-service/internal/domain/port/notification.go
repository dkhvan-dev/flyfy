package port

import (
	"context"
	"time"

	"github.com/google/uuid"
)

type ExcursionNotificationInput struct {
	IdempotencyKey   string
	RecipientUserIDs []uuid.UUID
	Category         string
	Priority         string
	Title            string
	Body             string
	DeepLink         string
	Data             map[string]string
	CollapseKey      string
	TTL              time.Duration
}

type ExcursionNotificationGateway interface {
	SendExcursionNotification(ctx context.Context, input ExcursionNotificationInput) error
}
