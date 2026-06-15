package cache

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"time"

	"github.com/redis/go-redis/v9"

	"kz/inflap/backend/services/feed-service/internal/domain/model"
)

const defaultPostFeedCachePrefix = "feed-service:feed-cache:"

type RedisPostFeedCache struct {
	client *redis.Client
	prefix string
}

func NewRedisPostFeedCache(client *redis.Client, prefix string) *RedisPostFeedCache {
	prefix = strings.TrimSpace(prefix)
	if prefix == "" {
		prefix = defaultPostFeedCachePrefix
	}
	return &RedisPostFeedCache{
		client: client,
		prefix: prefix,
	}
}

func (c *RedisPostFeedCache) Ping(ctx context.Context) error {
	return c.client.Ping(ctx).Err()
}

func (c *RedisPostFeedCache) GetPosts(ctx context.Context, key string) ([]*model.Post, bool, error) {
	payload, err := c.client.Get(ctx, c.dataKey(key)).Bytes()
	if errors.Is(err, redis.Nil) {
		return nil, false, nil
	}
	if err != nil {
		return nil, false, err
	}

	posts, err := unmarshalPostFeedCachePayload(payload)
	if err != nil {
		return nil, false, err
	}
	return posts, true, nil
}

func (c *RedisPostFeedCache) SetPosts(ctx context.Context, key string, posts []*model.Post, ttl time.Duration) error {
	if ttl <= 0 {
		return nil
	}
	payload, err := marshalPostFeedCachePayload(posts)
	if err != nil {
		return err
	}
	return c.client.Set(ctx, c.dataKey(key), payload, ttl).Err()
}

func (c *RedisPostFeedCache) CurrentVersion(ctx context.Context, scope string) (int64, error) {
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

func (c *RedisPostFeedCache) BumpVersion(ctx context.Context, scopes ...string) error {
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

func (c *RedisPostFeedCache) dataKey(key string) string {
	return c.prefix + "data:" + key
}

func (c *RedisPostFeedCache) versionKey(scope string) string {
	return c.prefix + "version:" + scope
}

func marshalPostFeedCachePayload(posts []*model.Post) ([]byte, error) {
	return json.Marshal(postFeedCachePayload{Posts: posts})
}

func unmarshalPostFeedCachePayload(payload []byte) ([]*model.Post, error) {
	var cached postFeedCachePayload
	if err := json.Unmarshal(payload, &cached); err != nil {
		return nil, err
	}
	return cached.Posts, nil
}

type postFeedCachePayload struct {
	Posts []*model.Post `json:"posts"`
}
