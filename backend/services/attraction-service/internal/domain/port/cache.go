package port

import (
	"context"
	"time"

	"github.com/dkhvan-dev/flyfy/backend/services/attraction-service/internal/domain/model"
)

type AttractionCache interface {
	GetAttraction(ctx context.Context, key string) (*model.Attraction, bool, error)
	SetAttraction(ctx context.Context, key string, attraction *model.Attraction, ttl time.Duration) error
	GetAttractionList(ctx context.Context, key string) ([]*model.Attraction, int, bool, error)
	SetAttractionList(ctx context.Context, key string, attractions []*model.Attraction, total int, ttl time.Duration) error
	CurrentVersion(ctx context.Context, scope string) (int64, error)
	BumpVersion(ctx context.Context, scopes ...string) error
}
