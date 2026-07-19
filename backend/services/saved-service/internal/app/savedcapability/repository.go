package savedcapability

import (
	"context"

	"github.com/google/uuid"
)

type Repository interface {
	GetUsage(context.Context, uuid.UUID) (Usage, error)
}
