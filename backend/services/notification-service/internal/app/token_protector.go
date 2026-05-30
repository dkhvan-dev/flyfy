package app

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"fmt"
	"io"
	"strings"
)

type TokenProtector struct {
	encryptionKey []byte
	hashKey       []byte
}

func NewTokenProtector(encryptionKey []byte, hashKey []byte) (*TokenProtector, error) {
	if len(encryptionKey) != 32 {
		return nil, fmt.Errorf("token encryption key must be 32 bytes")
	}
	if len(hashKey) < 32 {
		return nil, fmt.Errorf("token hash key must be at least 32 bytes")
	}
	return &TokenProtector{
		encryptionKey: append([]byte(nil), encryptionKey...),
		hashKey:       append([]byte(nil), hashKey...),
	}, nil
}

func NewTokenProtectorFromBase64(encryptionKey string, hashKey string) (*TokenProtector, error) {
	decodedEncryptionKey, err := base64.StdEncoding.DecodeString(strings.TrimSpace(encryptionKey))
	if err != nil {
		return nil, fmt.Errorf("decode token encryption key: %w", err)
	}
	decodedHashKey, err := base64.StdEncoding.DecodeString(strings.TrimSpace(hashKey))
	if err != nil {
		return nil, fmt.Errorf("decode token hash key: %w", err)
	}
	return NewTokenProtector(decodedEncryptionKey, decodedHashKey)
}

func (p *TokenProtector) Hash(token string) string {
	mac := hmac.New(sha256.New, p.hashKey)
	mac.Write([]byte(strings.TrimSpace(token)))
	return base64.RawURLEncoding.EncodeToString(mac.Sum(nil))
}

func (p *TokenProtector) Encrypt(token string) (string, error) {
	block, err := aes.NewCipher(p.encryptionKey)
	if err != nil {
		return "", fmt.Errorf("create aes cipher: %w", err)
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", fmt.Errorf("create aes-gcm: %w", err)
	}
	nonce := make([]byte, gcm.NonceSize())
	if _, err = io.ReadFull(rand.Reader, nonce); err != nil {
		return "", fmt.Errorf("generate token nonce: %w", err)
	}
	ciphertext := gcm.Seal(nil, nonce, []byte(strings.TrimSpace(token)), nil)
	payload := append(nonce, ciphertext...)
	return base64.RawURLEncoding.EncodeToString(payload), nil
}

func (p *TokenProtector) Decrypt(ciphertext string) (string, error) {
	payload, err := base64.RawURLEncoding.DecodeString(strings.TrimSpace(ciphertext))
	if err != nil {
		return "", fmt.Errorf("decode token ciphertext: %w", err)
	}
	block, err := aes.NewCipher(p.encryptionKey)
	if err != nil {
		return "", fmt.Errorf("create aes cipher: %w", err)
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", fmt.Errorf("create aes-gcm: %w", err)
	}
	if len(payload) < gcm.NonceSize() {
		return "", fmt.Errorf("token ciphertext is too short")
	}
	nonce := payload[:gcm.NonceSize()]
	encryptedToken := payload[gcm.NonceSize():]
	plaintext, err := gcm.Open(nil, nonce, encryptedToken, nil)
	if err != nil {
		return "", fmt.Errorf("decrypt token: %w", err)
	}
	return string(plaintext), nil
}
