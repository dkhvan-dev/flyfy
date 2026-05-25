package cache

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"time"

	"github.com/redis/go-redis/v9"

	"github.com/dkhvan-dev/flyfy/backend/services/attraction-service/internal/domain/model"
)

const defaultAttractionCachePrefix = "attraction-service:cache:"

type RedisAttractionCache struct {
	client *redis.Client
	prefix string
}

func NewRedisAttractionCache(client *redis.Client, prefix string) *RedisAttractionCache {
	prefix = strings.TrimSpace(prefix)
	if prefix == "" {
		prefix = defaultAttractionCachePrefix
	}
	return &RedisAttractionCache{
		client: client,
		prefix: prefix,
	}
}

func (c *RedisAttractionCache) Ping(ctx context.Context) error {
	return c.client.Ping(ctx).Err()
}

func (c *RedisAttractionCache) GetAttraction(ctx context.Context, key string) (*model.Attraction, bool, error) {
	payload, err := c.client.Get(ctx, c.dataKey(key)).Bytes()
	if errors.Is(err, redis.Nil) {
		return nil, false, nil
	}
	if err != nil {
		return nil, false, err
	}

	var attraction model.Attraction
	if err = json.Unmarshal(payload, &attraction); err != nil {
		return nil, false, err
	}
	return &attraction, true, nil
}

func (c *RedisAttractionCache) SetAttraction(ctx context.Context, key string, attraction *model.Attraction, ttl time.Duration) error {
	if attraction == nil || ttl <= 0 {
		return nil
	}
	payload, err := json.Marshal(attraction)
	if err != nil {
		return err
	}
	return c.client.Set(ctx, c.dataKey(key), payload, ttl).Err()
}

func (c *RedisAttractionCache) GetAttractionList(ctx context.Context, key string) ([]*model.Attraction, int, bool, error) {
	payload, err := c.client.Get(ctx, c.dataKey(key)).Bytes()
	if errors.Is(err, redis.Nil) {
		return nil, 0, false, nil
	}
	if err != nil {
		return nil, 0, false, err
	}

	var cached attractionListPayload
	if err = json.Unmarshal(payload, &cached); err != nil {
		return nil, 0, false, err
	}
	return cached.Attractions, cached.Total, true, nil
}

func (c *RedisAttractionCache) SetAttractionList(ctx context.Context, key string, attractions []*model.Attraction, total int, ttl time.Duration) error {
	if ttl <= 0 {
		return nil
	}
	payload, err := json.Marshal(attractionListPayload{
		Attractions: attractions,
		Total:       total,
	})
	if err != nil {
		return err
	}
	return c.client.Set(ctx, c.dataKey(key), payload, ttl).Err()
}

func (c *RedisAttractionCache) CurrentVersion(ctx context.Context, scope string) (int64, error) {
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

func (c *RedisAttractionCache) BumpVersion(ctx context.Context, scopes ...string) error {
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

func (c *RedisAttractionCache) dataKey(key string) string {
	return c.prefix + "data:" + key
}

func (c *RedisAttractionCache) versionKey(scope string) string {
	return c.prefix + "version:" + scope
}

type attractionListPayload struct {
	Attractions []*model.Attraction `json:"attractions"`
	Total       int                 `json:"total"`
}
