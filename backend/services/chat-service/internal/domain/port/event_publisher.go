package port

import (
	"context"
	"kz/inflap/backend/services/chat-service/internal/event"
)

type EventPublisher interface {
	Publish(ctx context.Context, subject string, evt event.Event) error
	Close() error
}
