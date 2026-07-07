package cache

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"time"

	"github.com/redis/go-redis/v9"

	"kz/inflap/backend/services/search-service/internal/app"
)

const defaultSearchCachePrefix = "search-service:search-cache:"

var _ app.SearchCache = (*RedisSearchCache)(nil)

type RedisSearchCache struct {
	client *redis.Client
	prefix string
}

func NewRedisSearchCache(client *redis.Client, prefix string) *RedisSearchCache {
	prefix = strings.TrimSpace(prefix)
	if prefix == "" {
		prefix = defaultSearchCachePrefix
	}
	return &RedisSearchCache{
		client: client,
		prefix: prefix,
	}
}

func (c *RedisSearchCache) Ping(ctx context.Context) error {
	return c.client.Ping(ctx).Err()
}

func (c *RedisSearchCache) GetSearchPage(ctx context.Context, key string) (app.SearchPage, bool, error) {
	payload, err := c.client.Get(ctx, c.dataKey(key)).Bytes()
	if errors.Is(err, redis.Nil) {
		return app.SearchPage{}, false, nil
	}
	if err != nil {
		return app.SearchPage{}, false, err
	}

	var page app.SearchPage
	if err = json.Unmarshal(payload, &page); err != nil {
		return app.SearchPage{}, false, err
	}
	return page, true, nil
}

func (c *RedisSearchCache) SetSearchPage(ctx context.Context, key string, page app.SearchPage, ttl time.Duration) error {
	if ttl <= 0 {
		return nil
	}
	payload, err := json.Marshal(page)
	if err != nil {
		return err
	}
	return c.client.Set(ctx, c.dataKey(key), payload, ttl).Err()
}

func (c *RedisSearchCache) dataKey(key string) string {
	return c.prefix + "data:" + key
}
