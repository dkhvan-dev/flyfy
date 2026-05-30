package port

import (
	"context"
	"time"

	"github.com/google/uuid"
)

type ActivityNotificationInput struct {
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

type ActivityNotificationGateway interface {
	SendActivityNotification(ctx context.Context, input ActivityNotificationInput) error
}
