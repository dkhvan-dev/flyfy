package repository

import (
	"context"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

const (
	otpPrefix       = "otp:"
	otpRatePrefix   = "otp_rate:"
	maxOTPPerWindow = 5
	rateWindow      = 15 * time.Minute
)

// RedisOTPStore implements port.OTPStore using Redis.
type RedisOTPStore struct {
	client *redis.Client
	ttl    time.Duration
}

func NewRedisOTPStore(client *redis.Client, ttl time.Duration) *RedisOTPStore {
	return &RedisOTPStore{client: client, ttl: ttl}
}

// Store saves an OTP code for a phone number with TTL.
func (s *RedisOTPStore) Store(ctx context.Context, phone, code string) error {
	key := otpPrefix + phone
	if err := s.client.Set(ctx, key, code, s.ttl).Err(); err != nil {
		return fmt.Errorf("redis SET otp: %w", err)
	}

	// Increment rate limit counter
	rateKey := otpRatePrefix + phone
	pipe := s.client.Pipeline()
	pipe.Incr(ctx, rateKey)
	pipe.Expire(ctx, rateKey, rateWindow)
	if _, err := pipe.Exec(ctx); err != nil {
		return fmt.Errorf("redis rate limit: %w", err)
	}

	return nil
}

// Verify checks if the code matches the stored OTP and removes it on success.
func (s *RedisOTPStore) Verify(ctx context.Context, phone, code string) (bool, error) {
	key := otpPrefix + phone

	stored, err := s.client.Get(ctx, key).Result()
	if err == redis.Nil {
		return false, nil // expired or never set
	}
	if err != nil {
		return false, fmt.Errorf("redis GET otp: %w", err)
	}

	if stored != code {
		return false, nil
	}

	// Delete the OTP after successful verification (one-time use)
	s.client.Del(ctx, key)
	return true, nil
}

// CheckRateLimit returns an error if OTP requests are rate-limited for this phone.
func (s *RedisOTPStore) CheckRateLimit(ctx context.Context, phone string) error {
	rateKey := otpRatePrefix + phone
	count, err := s.client.Get(ctx, rateKey).Int()
	if err == redis.Nil {
		return nil // no requests yet
	}
	if err != nil {
		return fmt.Errorf("redis GET rate: %w", err)
	}

	if count >= maxOTPPerWindow {
		return fmt.Errorf("rate limit exceeded: %d requests in %v", count, rateWindow)
	}
	return nil
}
