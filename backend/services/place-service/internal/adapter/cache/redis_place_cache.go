package cache

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"time"

	"github.com/redis/go-redis/v9"

	"kz/inflap/backend/services/place-service/internal/domain/model"
)

const defaultPlaceCachePrefix = "place-service:cache:"

type RedisPlaceCache struct {
	client *redis.Client
	prefix string
}

func NewRedisPlaceCache(client *redis.Client, prefix string) *RedisPlaceCache {
	prefix = strings.TrimSpace(prefix)
	if prefix == "" {
		prefix = defaultPlaceCachePrefix
	}
	return &RedisPlaceCache{
		client: client,
		prefix: prefix,
	}
}

func (c *RedisPlaceCache) Ping(ctx context.Context) error {
	return c.client.Ping(ctx).Err()
}

func (c *RedisPlaceCache) GetPlace(ctx context.Context, key string) (*model.Place, bool, error) {
	payload, err := c.client.Get(ctx, c.dataKey(key)).Bytes()
	if errors.Is(err, redis.Nil) {
		return nil, false, nil
	}
	if err != nil {
		return nil, false, err
	}

	var place model.Place
	if err = json.Unmarshal(payload, &place); err != nil {
		return nil, false, err
	}
	return &place, true, nil
}

func (c *RedisPlaceCache) SetPlace(ctx context.Context, key string, place *model.Place, ttl time.Duration) error {
	if place == nil || ttl <= 0 {
		return nil
	}
	payload, err := json.Marshal(place)
	if err != nil {
		return err
	}
	return c.client.Set(ctx, c.dataKey(key), payload, ttl).Err()
}

func (c *RedisPlaceCache) GetPlaceList(ctx context.Context, key string) ([]*model.Place, int, bool, error) {
	payload, err := c.client.Get(ctx, c.dataKey(key)).Bytes()
	if errors.Is(err, redis.Nil) {
		return nil, 0, false, nil
	}
	if err != nil {
		return nil, 0, false, err
	}

	var cached placeListPayload
	if err = json.Unmarshal(payload, &cached); err != nil {
		return nil, 0, false, err
	}
	return cached.Places, cached.Total, true, nil
}

func (c *RedisPlaceCache) SetPlaceList(ctx context.Context, key string, places []*model.Place, total int, ttl time.Duration) error {
	if ttl <= 0 {
		return nil
	}
	payload, err := json.Marshal(placeListPayload{
		Places: places,
		Total:  total,
	})
	if err != nil {
		return err
	}
	return c.client.Set(ctx, c.dataKey(key), payload, ttl).Err()
}

func (c *RedisPlaceCache) CurrentVersion(ctx context.Context, scope string) (int64, error) {
	version, err := c.client.Get(ctx, c.versionKey(scope)).Int64()
	if errors.Is(err, redis.Nil) {
		return 0, nil
	}
	if err != nil {
		return 0, err
	}
	if version < 0 {
		return 0, nil
	}
	return version, nil
}

func (c *RedisPlaceCache) BumpVersion(ctx context.Context, scopes ...string) error {
	pipe := c.client.Pipeline()
	queued := false
	for _, scope := range scopes {
		scope = strings.TrimSpace(scope)
		if scope == "" {
			continue
		}
		pipe.Incr(ctx, c.versionKey(scope))
		queued = true
	}
	if !queued {
		return nil
	}
	_, err := pipe.Exec(ctx)
	return err
}

func (c *RedisPlaceCache) dataKey(key string) string {
	return c.prefix + "data:" + key
}

func (c *RedisPlaceCache) versionKey(scope string) string {
	return c.prefix + "version:" + scope
}

type placeListPayload struct {
	Places []*model.Place `json:"places"`
	Total  int            `json:"total"`
}
