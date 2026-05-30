package repository

import (
	"context"
	"crypto/rsa"
	"sync"

	"github.com/go-jose/go-jose/v4"
	"kz/inflap/backend/services/token-service/internal/domain/model"
)

// keyEntry holds a key pair with metadata.
type keyEntry struct {
	ID        string
	Key       *rsa.PrivateKey
	Active    bool
	CreatedAt int64 // unix timestamp
}

// InMemoryKeyStore implements port.KeyStore.
// In production, replace with Vault-backed store + PostgreSQL for metadata.
type InMemoryKeyStore struct {
	mu   sync.RWMutex
	keys []keyEntry
}

func NewInMemoryKeyStore() *InMemoryKeyStore {
	return &InMemoryKeyStore{
		keys: make([]keyEntry, 0, 4),
	}
}

func (s *InMemoryKeyStore) GetActiveKey(_ context.Context) (string, *rsa.PrivateKey, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	for i := len(s.keys) - 1; i >= 0; i-- {
		if s.keys[i].Active {
			return s.keys[i].ID, s.keys[i].Key, nil
		}
	}
	return "", nil, model.ErrNoActiveKey
}

func (s *InMemoryKeyStore) GetPublicKeys(_ context.Context) ([]jose.JSONWebKey, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	jwks := make([]jose.JSONWebKey, 0, len(s.keys))
	for _, entry := range s.keys {
		jwks = append(jwks, jose.JSONWebKey{
			Key:       &entry.Key.PublicKey,
			KeyID:     entry.ID,
			Algorithm: string(jose.RS256),
			Use:       "sig",
		})
	}
	return jwks, nil
}

func (s *InMemoryKeyStore) StoreKey(_ context.Context, keyID string, key *rsa.PrivateKey) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	// Deactivate all existing keys
	for i := range s.keys {
		s.keys[i].Active = false
	}

	// Add the new key as active
	s.keys = append(s.keys, keyEntry{
		ID:     keyID,
		Key:    key,
		Active: true,
	})
	return nil
}

func (s *InMemoryKeyStore) DeactivateKey(_ context.Context, keyID string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	for i := range s.keys {
		if s.keys[i].ID == keyID {
			s.keys[i].Active = false
			return nil
		}
	}
	return model.ErrKeyNotFound
}

func (s *InMemoryKeyStore) DeleteExpiredKeys(_ context.Context, maxKeys int) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if len(s.keys) <= maxKeys {
		return nil
	}

	// Keep only the most recent maxKeys
	s.keys = s.keys[len(s.keys)-maxKeys:]
	return nil
}
