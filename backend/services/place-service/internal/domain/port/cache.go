package port

import (
	"context"
	"time"

	"kz/inflap/backend/services/place-service/internal/domain/model"
)

type PlaceCache interface {
	GetPlace(ctx context.Context, key string) (*model.Place, bool, error)
	SetPlace(ctx context.Context, key string, place *model.Place, ttl time.Duration) error
	GetPlaceList(ctx context.Context, key string) ([]*model.Place, int, bool, error)
	SetPlaceList(ctx context.Context, key string, places []*model.Place, total int, ttl time.Duration) error
	CurrentVersion(ctx context.Context, scope string) (int64, error)
	BumpVersion(ctx context.Context, scopes ...string) error
}
