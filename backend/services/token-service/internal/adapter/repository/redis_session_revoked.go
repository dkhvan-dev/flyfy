package repository

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
)

const sessionRevokedPrefix = "sess_revoked:"

// RedisRevokedSessionCache is a fast O(1) Redis-backed cache of revoked
// session_ids. Used on the hot ValidateAccessToken path so the gateway does
// not have to hit Postgres on every request.
//
// On Redis errors we return (false, err) — callers may choose to fall back
// to Postgres (slow path) or trust-cache (false). The default policy is
// "fail open for cache misses" but treat outages as warnings, not 5xx.
type RedisRevokedSessionCache struct {
	client *redis.Client
}

func NewRedisRevokedSessionCache(client *redis.Client) *RedisRevokedSessionCache {
	return &RedisRevokedSessionCache{client: client}
}

func (c *RedisRevokedSessionCache) MarkRevoked(ctx context.Context, sessionID uuid.UUID, ttl time.Duration) error {
	if ttl <= 0 {
		return nil
	}
	if err := c.client.Set(ctx, sessionRevokedPrefix+sessionID.String(), "1", ttl).Err(); err != nil {
		return fmt.Errorf("redis SET sess_revoked: %w", err)
	}
	return nil
}

func (c *RedisRevokedSessionCache) IsRevoked(ctx context.Context, sessionID uuid.UUID) (bool, error) {
	res, err := c.client.Exists(ctx, sessionRevokedPrefix+sessionID.String()).Result()
	if err != nil {
		return false, fmt.Errorf("redis EXISTS sess_revoked: %w", err)
	}
	return res > 0, nil
}
