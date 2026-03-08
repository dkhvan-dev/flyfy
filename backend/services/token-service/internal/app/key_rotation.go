package app

import (
	"context"
	"time"

	"github.com/rs/zerolog"

	"github.com/dkhvan-dev/flyfy/token-service/internal/config"
	"github.com/dkhvan-dev/flyfy/token-service/internal/domain/port"
)

// KeyRotationScheduler manages periodic RSA key rotation.
type KeyRotationScheduler struct {
	keyManager port.KeyManager
	cfg        config.JWTConfig
	logger     zerolog.Logger
}

// NewKeyRotationScheduler creates a new KeyRotationScheduler.
func NewKeyRotationScheduler(
	keyManager port.KeyManager,
	cfg config.JWTConfig,
	logger zerolog.Logger,
) *KeyRotationScheduler {
	return &KeyRotationScheduler{
		keyManager: keyManager,
		cfg:        cfg,
		logger:     logger.With().Str("component", "key_rotation").Logger(),
	}
}

// EnsureActiveKey checks if there is an active signing key.
// If not, it triggers a key rotation to create one.
func (s *KeyRotationScheduler) EnsureActiveKey(ctx context.Context, keyStore port.KeyStore) error {
	_, _, err := keyStore.GetActiveKey(ctx)
	if err == nil {
		s.logger.Info().Msg("active signing key found")
		return nil
	}

	s.logger.Info().Msg("no active signing key found, generating initial key")
	return s.keyManager.RotateKeys(ctx)
}

// Start begins the background key rotation loop.
// It blocks until the context is cancelled.
func (s *KeyRotationScheduler) Start(ctx context.Context) {
	ticker := time.NewTicker(s.cfg.KeyRotationInterval)
	defer ticker.Stop()

	s.logger.Info().
		Dur("interval", s.cfg.KeyRotationInterval).
		Msg("key rotation scheduler started")

	for {
		select {
		case <-ctx.Done():
			s.logger.Info().Msg("key rotation scheduler stopped")
			return
		case <-ticker.C:
			s.logger.Info().Msg("rotating keys")
			if err := s.keyManager.RotateKeys(ctx); err != nil {
				s.logger.Error().Err(err).Msg("key rotation failed")
			} else {
				s.logger.Info().Msg("key rotation completed successfully")
			}
		}
	}
}
