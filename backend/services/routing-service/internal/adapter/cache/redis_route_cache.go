package cache

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"time"

	"github.com/redis/go-redis/v9"
)

const defaultRouteCachePrefix = "routing-service:cache:"

type RedisRouteCache struct {
	client *redis.Client
	prefix string
	ttl    time.Duration
}

func NewRedisRouteCache(client *redis.Client, prefix string, ttl time.Duration) *RedisRouteCache {
	prefix = strings.TrimSpace(prefix)
	if prefix == "" {
		prefix = defaultRouteCachePrefix
	}
	return &RedisRouteCache{client: client, prefix: prefix, ttl: ttl}
}

func (c *RedisRouteCache) Ping(ctx context.Context) error {
	return c.client.Ping(ctx).Err()
}

func (c *RedisRouteCache) Get(ctx context.Context, key string, dst any) (bool, error) {
	payload, err := c.client.Get(ctx, c.dataKey(key)).Bytes()
	if errors.Is(err, redis.Nil) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	if err := json.Unmarshal(payload, dst); err != nil {
		return false, err
	}
	return true, nil
}

func (c *RedisRouteCache) Set(ctx context.Context, key string, value any) error {
	if c.ttl <= 0 {
		return nil
	}
	payload, err := json.Marshal(value)
	if err != nil {
		return err
	}
	return c.client.Set(ctx, c.dataKey(key), payload, c.ttl).Err()
}

func (c *RedisRouteCache) dataKey(key string) string {
	return c.prefix + "data:" + key
}
