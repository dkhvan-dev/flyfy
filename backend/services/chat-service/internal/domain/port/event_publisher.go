package port

import (
	"context"
	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/event"
)

type EventPublisher interface {
	Publish(ctx context.Context, subject string, evt event.Event) error
	Close() error
}
