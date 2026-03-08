package repository

import (
	"context"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

const (
	revocationPrefix = "revoked:"
)

// RedisRevocationStore implements port.RevocationStore using Redis.
type RedisRevocationStore struct {
	client *redis.Client
}

func NewRedisRevocationStore(client *redis.Client) *RedisRevocationStore {
	return &RedisRevocationStore{client: client}
}

// Add puts a token JTI into the revocation list.
// The TTL is set so the entry auto-expires when the token itself would expire.
func (s *RedisRevocationStore) Add(ctx context.Context, jti string, expiresAt int64) error {
	key := revocationPrefix + jti

	// Calculate TTL: token expiry - now + small buffer
	ttl := time.Until(time.Unix(expiresAt, 0)) + time.Minute
	if ttl <= 0 {
		// Token already expired, no need to revoke
		return nil
	}

	if err := s.client.Set(ctx, key, "1", ttl).Err(); err != nil {
		return fmt.Errorf("redis SET revocation: %w", err)
	}
	return nil
}

// Exists checks if a JTI is in the revocation list.
func (s *RedisRevocationStore) Exists(ctx context.Context, jti string) (bool, error) {
	key := revocationPrefix + jti

	result, err := s.client.Exists(ctx, key).Result()
	if err != nil {
		return false, fmt.Errorf("redis EXISTS revocation: %w", err)
	}
	return result > 0, nil
}
