package repository

import (
	"context"
	"crypto/rsa"
	"crypto/x509"
	"encoding/json"
	"encoding/pem"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/go-jose/go-jose/v4"
	"kz/inflap/backend/services/token-service/internal/domain/model"
)

type fileKeyRecord struct {
	ID            string `json:"id"`
	PrivateKeyPEM string `json:"private_key_pem"`
	Active        bool   `json:"active"`
	CreatedAtUnix int64  `json:"created_at_unix"`
}

// FileKeyStore persists signing keys on disk so JWT sessions survive service restarts.
type FileKeyStore struct {
	path    string
	mu      sync.RWMutex
	loaded  bool
	records []fileKeyRecord
}

func NewFileKeyStore(path string) *FileKeyStore {
	return &FileKeyStore{
		path:    path,
		records: make([]fileKeyRecord, 0, 4),
	}
}

func (s *FileKeyStore) GetActiveKey(ctx context.Context) (string, *rsa.PrivateKey, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if err := s.ensureLoadedLocked(ctx); err != nil {
		return "", nil, err
	}

	for i := len(s.records) - 1; i >= 0; i-- {
		if !s.records[i].Active {
			continue
		}
		key, err := parseRSAPrivateKeyPEM(s.records[i].PrivateKeyPEM)
		if err != nil {
			return "", nil, fmt.Errorf("parsing active private key %s: %w", s.records[i].ID, err)
		}
		return s.records[i].ID, key, nil
	}

	return "", nil, model.ErrNoActiveKey
}

func (s *FileKeyStore) GetPublicKeys(ctx context.Context) ([]jose.JSONWebKey, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if err := s.ensureLoadedLocked(ctx); err != nil {
		return nil, err
	}

	keys := make([]jose.JSONWebKey, 0, len(s.records))
	for _, record := range s.records {
		key, err := parseRSAPrivateKeyPEM(record.PrivateKeyPEM)
		if err != nil {
			return nil, fmt.Errorf("parsing private key %s: %w", record.ID, err)
		}
		keys = append(keys, jose.JSONWebKey{
			Key:       &key.PublicKey,
			KeyID:     record.ID,
			Algorithm: string(jose.RS256),
			Use:       "sig",
		})
	}

	return keys, nil
}

func (s *FileKeyStore) StoreKey(ctx context.Context, keyID string, key *rsa.PrivateKey) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if err := s.ensureLoadedLocked(ctx); err != nil {
		return err
	}

	keyPEM, err := encodeRSAPrivateKeyPEM(key)
	if err != nil {
		return fmt.Errorf("encoding private key: %w", err)
	}

	for i := range s.records {
		s.records[i].Active = false
	}

	s.records = append(s.records, fileKeyRecord{
		ID:            keyID,
		PrivateKeyPEM: keyPEM,
		Active:        true,
		CreatedAtUnix: time.Now().UTC().Unix(),
	})

	return s.persistLocked()
}

func (s *FileKeyStore) DeactivateKey(ctx context.Context, keyID string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if err := s.ensureLoadedLocked(ctx); err != nil {
		return err
	}

	for i := range s.records {
		if s.records[i].ID == keyID {
			s.records[i].Active = false
			return s.persistLocked()
		}
	}

	return model.ErrKeyNotFound
}

func (s *FileKeyStore) DeleteExpiredKeys(ctx context.Context, maxKeys int) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if err := s.ensureLoadedLocked(ctx); err != nil {
		return err
	}

	if maxKeys <= 0 || len(s.records) <= maxKeys {
		return nil
	}

	s.records = append([]fileKeyRecord(nil), s.records[len(s.records)-maxKeys:]...)
	return s.persistLocked()
}

func (s *FileKeyStore) ensureLoadedLocked(_ context.Context) error {
	if s.loaded {
		return nil
	}

	records, err := s.loadFromDiskLocked()
	if err != nil {
		return err
	}

	s.records = records
	s.loaded = true
	return nil
}

func (s *FileKeyStore) loadFromDiskLocked() ([]fileKeyRecord, error) {
	bytes, err := os.ReadFile(s.path)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return make([]fileKeyRecord, 0, 4), nil
		}
		return nil, fmt.Errorf("read key store file: %w", err)
	}

	if len(bytes) == 0 {
		return make([]fileKeyRecord, 0, 4), nil
	}

	var records []fileKeyRecord
	if err := json.Unmarshal(bytes, &records); err != nil {
		return nil, fmt.Errorf("decode key store file: %w", err)
	}

	return records, nil
}

func (s *FileKeyStore) persistLocked() error {
	if err := os.MkdirAll(filepath.Dir(s.path), 0o755); err != nil {
		return fmt.Errorf("create key store directory: %w", err)
	}

	payload, err := json.MarshalIndent(s.records, "", "  ")
	if err != nil {
		return fmt.Errorf("encode key store file: %w", err)
	}

	tempPath := s.path + ".tmp"
	if err := os.WriteFile(tempPath, payload, 0o600); err != nil {
		return fmt.Errorf("write temp key store file: %w", err)
	}

	if err := os.Rename(tempPath, s.path); err != nil {
		return fmt.Errorf("replace key store file: %w", err)
	}

	return nil
}

func encodeRSAPrivateKeyPEM(key *rsa.PrivateKey) (string, error) {
	block := &pem.Block{
		Type:  "RSA PRIVATE KEY",
		Bytes: x509.MarshalPKCS1PrivateKey(key),
	}
	return string(pem.EncodeToMemory(block)), nil
}

func parseRSAPrivateKeyPEM(value string) (*rsa.PrivateKey, error) {
	block, _ := pem.Decode([]byte(value))
	if block == nil {
		return nil, errors.New("missing PEM block")
	}

	if key, err := x509.ParsePKCS1PrivateKey(block.Bytes); err == nil {
		return key, nil
	}

	pkcs8Key, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		return nil, err
	}

	rsaKey, ok := pkcs8Key.(*rsa.PrivateKey)
	if !ok {
		return nil, errors.New("PEM is not an RSA private key")
	}

	return rsaKey, nil
}
