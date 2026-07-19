package config

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/base64"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"
)

const (
	maximumPreviousHMACKeys   = 3
	maximumPreviousCursorKeys = 3
	maximumHMACKeyBytes       = 128
)

type SecretBytes struct {
	value []byte
}

func (secret *SecretBytes) EnvDecode(_ context.Context, value string) error {
	if secret == nil {
		return errors.New("crypto key destination is unavailable")
	}
	if value == "" {
		secret.value = nil
		return nil
	}
	if len(value) > 1024 {
		return errors.New("crypto key is too large")
	}
	decoded, err := base64.StdEncoding.Strict().DecodeString(value)
	if err != nil {
		return errors.New("crypto key must use strict padded base64")
	}
	secret.value = append(secret.value[:0], decoded...)
	return nil
}

func newSecretBytes(value []byte) SecretBytes {
	return SecretBytes{value: append([]byte(nil), value...)}
}

func (secret SecretBytes) Bytes() []byte {
	return append([]byte(nil), secret.value...)
}

func (secret SecretBytes) IsEmpty() bool {
	return len(secret.value) == 0
}

func (SecretBytes) String() string {
	return "[redacted]"
}

func (secret SecretBytes) GoString() string {
	return secret.String()
}

type VersionedKey struct {
	Version uint32
	Secret  SecretBytes
}

func (key VersionedKey) String() string {
	return fmt.Sprintf("VersionedKey{version=%d secret=redacted}", key.Version)
}

func (key VersionedKey) GoString() string {
	return key.String()
}

type VersionedKeys struct {
	keys []VersionedKey
}

func (keys *VersionedKeys) EnvDecode(ctx context.Context, value string) error {
	if keys == nil {
		return errors.New("crypto key list destination is unavailable")
	}
	if value == "" {
		keys.keys = nil
		return nil
	}
	if len(value) > 4096 {
		return errors.New("previous crypto key list is too large")
	}
	parts := strings.Split(value, ",")
	if len(parts) > maximumPreviousHMACKeys {
		return errors.New("too many previous crypto keys")
	}
	decoded := make([]VersionedKey, 0, len(parts))
	for _, part := range parts {
		versionText, encodedKey, found := strings.Cut(part, ":")
		if !found || versionText == "" || encodedKey == "" ||
			strings.TrimSpace(part) != part || strings.Contains(encodedKey, ":") {
			return errors.New("previous crypto keys must use version:base64 entries")
		}
		version, err := strconv.ParseUint(versionText, 10, 32)
		if err != nil || version == 0 {
			return errors.New("previous crypto key version must be a positive uint32")
		}
		var secret SecretBytes
		if err := secret.EnvDecode(ctx, encodedKey); err != nil {
			return err
		}
		decoded = append(decoded, VersionedKey{Version: uint32(version), Secret: secret})
	}
	keys.keys = decoded
	return nil
}

func (keys VersionedKeys) Values() []VersionedKey {
	result := make([]VersionedKey, 0, len(keys.keys))
	for _, key := range keys.keys {
		result = append(result, VersionedKey{
			Version: key.Version,
			Secret:  newSecretBytes(key.Secret.value),
		})
	}
	return result
}

func (VersionedKeys) String() string {
	return "VersionedKeys{redacted}"
}

func (keys VersionedKeys) GoString() string {
	return keys.String()
}

type CryptoConfig struct {
	OperationHMACCurrentVersion uint32        `env:"OPERATION_HMAC_CURRENT_VERSION, default=0"`
	OperationHMACCurrentKey     SecretBytes   `env:"OPERATION_HMAC_CURRENT_KEY_BASE64, default="`
	OperationHMACPreviousKeys   VersionedKeys `env:"OPERATION_HMAC_PREVIOUS_KEYS, default="`
	CursorActiveKeyID           uint32        `env:"CURSOR_ACTIVE_KEY_ID, default=0"`
	CursorActiveKey             SecretBytes   `env:"CURSOR_ACTIVE_KEY_BASE64, default="`
	CursorPreviousKeys          VersionedKeys `env:"CURSOR_PREVIOUS_KEYS, default="`
	CursorTTL                   time.Duration `env:"CURSOR_TTL, default=15m"`
}

func (crypto CryptoConfig) OperationCurrentKey() VersionedKey {
	return VersionedKey{
		Version: crypto.OperationHMACCurrentVersion,
		Secret:  newSecretBytes(crypto.OperationHMACCurrentKey.value),
	}
}

func (crypto CryptoConfig) OperationPreviousKeys() []VersionedKey {
	return crypto.OperationHMACPreviousKeys.Values()
}

func (crypto CryptoConfig) CursorCurrentKey() VersionedKey {
	return VersionedKey{
		Version: crypto.CursorActiveKeyID,
		Secret:  newSecretBytes(crypto.CursorActiveKey.value),
	}
}

func (crypto CryptoConfig) CursorDecryptKeys() []VersionedKey {
	return crypto.CursorPreviousKeys.Values()
}

func (CryptoConfig) String() string {
	return "CryptoConfig{keys=redacted}"
}

func (crypto CryptoConfig) GoString() string {
	return crypto.String()
}

func (crypto *CryptoConfig) applyDevelopmentDefaults() {
	if crypto == nil {
		return
	}
	if crypto.OperationHMACCurrentVersion == 0 && crypto.OperationHMACCurrentKey.IsEmpty() {
		operationKey := sha256.Sum256([]byte("saved-service/development/operation-hmac/v1"))
		crypto.OperationHMACCurrentVersion = 1
		crypto.OperationHMACCurrentKey = newSecretBytes(operationKey[:])
	}
	if crypto.CursorActiveKeyID == 0 && crypto.CursorActiveKey.IsEmpty() {
		cursorKey := sha256.Sum256([]byte("saved-service/development/cursor-aead/v1"))
		crypto.CursorActiveKeyID = 1
		crypto.CursorActiveKey = newSecretBytes(cursorKey[:])
	}
}

func (crypto CryptoConfig) Validate(app AppConfig) error {
	operationKeys := append([]VersionedKey{crypto.OperationCurrentKey()}, crypto.OperationPreviousKeys()...)
	if len(operationKeys)-1 > maximumPreviousHMACKeys {
		return fmt.Errorf("OPERATION_HMAC_PREVIOUS_KEYS supports at most %d keys", maximumPreviousHMACKeys)
	}
	if err := validateVersionedKeys(operationKeys, 32, maximumHMACKeyBytes, "operation HMAC"); err != nil {
		return err
	}

	cursorKeys := append([]VersionedKey{crypto.CursorCurrentKey()}, crypto.CursorDecryptKeys()...)
	if len(cursorKeys)-1 > maximumPreviousCursorKeys {
		return fmt.Errorf("CURSOR_PREVIOUS_KEYS supports at most %d keys", maximumPreviousCursorKeys)
	}
	if err := validateVersionedKeys(cursorKeys, 32, 32, "cursor"); err != nil {
		return err
	}
	if crypto.CursorTTL <= 0 || crypto.CursorTTL > 24*time.Hour {
		return fmt.Errorf("CURSOR_TTL must be within (0, 24h]")
	}

	for _, operationKey := range operationKeys {
		for _, cursorKey := range cursorKeys {
			if bytes.Equal(operationKey.Secret.value, cursorKey.Secret.value) {
				return fmt.Errorf("operation HMAC and cursor keys must use separate key material")
			}
		}
	}

	if app.IsSecureEnvironment() {
		if crypto.OperationHMACCurrentVersion == 1 &&
			bytes.Equal(crypto.OperationHMACCurrentKey.value, developmentOperationKey()) {
			return fmt.Errorf("operation HMAC development key is forbidden in staging and production")
		}
		if crypto.CursorActiveKeyID == 1 &&
			bytes.Equal(crypto.CursorActiveKey.value, developmentCursorKey()) {
			return fmt.Errorf("cursor development key is forbidden in staging and production")
		}
	}

	return nil
}

func validateVersionedKeys(keys []VersionedKey, minimumBytes, maximumBytes int, purpose string) error {
	if len(keys) == 0 {
		return fmt.Errorf("%s current key is required", purpose)
	}
	versions := make(map[uint32]struct{}, len(keys))
	for index, key := range keys {
		if key.Version == 0 {
			return fmt.Errorf("%s key versions must be positive", purpose)
		}
		if len(key.Secret.value) < minimumBytes || len(key.Secret.value) > maximumBytes {
			if minimumBytes == maximumBytes {
				return fmt.Errorf("%s keys must decode to exactly %d bytes", purpose, minimumBytes)
			}
			return fmt.Errorf("%s keys must decode to between %d and %d bytes", purpose, minimumBytes, maximumBytes)
		}
		if isWeakCryptoKey(key.Secret.value) {
			return fmt.Errorf("%s key material is too weak", purpose)
		}
		if _, duplicate := versions[key.Version]; duplicate {
			return fmt.Errorf("%s key versions must be unique", purpose)
		}
		versions[key.Version] = struct{}{}
		for priorIndex := 0; priorIndex < index; priorIndex++ {
			if bytes.Equal(keys[priorIndex].Secret.value, key.Secret.value) {
				return fmt.Errorf("%s key material must be unique", purpose)
			}
		}
	}
	return nil
}

func isWeakCryptoKey(key []byte) bool {
	if len(key) == 0 {
		return true
	}
	unique := make(map[byte]struct{}, 16)
	for _, value := range key {
		unique[value] = struct{}{}
	}
	return len(unique) < 8
}

func developmentOperationKey() []byte {
	key := sha256.Sum256([]byte("saved-service/development/operation-hmac/v1"))
	return key[:]
}

func developmentCursorKey() []byte {
	key := sha256.Sum256([]byte("saved-service/development/cursor-aead/v1"))
	return key[:]
}
