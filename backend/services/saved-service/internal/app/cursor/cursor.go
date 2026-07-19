package cursor

import (
	"bytes"
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"crypto/subtle"
	"encoding/base64"
	"encoding/binary"
	"encoding/json"
	"errors"
	"io"
	"strings"
	"time"

	"github.com/google/uuid"
)

const (
	tokenFormatVersion byte = 1
	tokenHeaderBytes        = 5
	maxTokenBytes           = 4096
	maxSubjectBytes         = 255
	maxCursorTTL            = 24 * time.Hour
)

var ErrInvalidCursor = errors.New("invalid saved cursor")

type Key struct {
	ID     uint32
	Secret []byte
}

type Position struct {
	SavedAt   time.Time
	ItemID    uuid.UUID
	MatchRank *int64
}

type EncodeInput struct {
	Subject          string
	ScopeFingerprint [scopeFingerprintBytes]byte
	Locale           Locale
	Position         Position
}

type DecodeExpectation struct {
	Subject          string
	ScopeFingerprint [scopeFingerprintBytes]byte
	Locale           Locale
}

type Codec struct {
	currentKeyID uint32
	aeadByKeyID  map[uint32]cipher.AEAD
	ttl          time.Duration
	now          func() time.Time
	random       io.Reader
}

type wirePayload struct {
	Schema      uint8  `json:"s"`
	Subject     string `json:"o"`
	Scope       string `json:"f"`
	Locale      string `json:"l"`
	SavedAtUS   int64  `json:"t"`
	ItemID      string `json:"i"`
	MatchRank   *int64 `json:"r,omitempty"`
	ExpiresAtUS int64  `json:"e"`
}

func NewCodec(keys []Key, currentKeyID uint32, ttl time.Duration) (*Codec, error) {
	if currentKeyID == 0 || ttl <= 0 || ttl > maxCursorTTL || len(keys) == 0 {
		return nil, ErrInvalidCursor
	}

	aeadByKeyID := make(map[uint32]cipher.AEAD, len(keys))
	for _, key := range keys {
		if key.ID == 0 || len(key.Secret) != 32 {
			return nil, ErrInvalidCursor
		}
		if _, exists := aeadByKeyID[key.ID]; exists {
			return nil, ErrInvalidCursor
		}
		block, err := aes.NewCipher(key.Secret)
		if err != nil {
			return nil, ErrInvalidCursor
		}
		aead, err := cipher.NewGCM(block)
		if err != nil {
			return nil, ErrInvalidCursor
		}
		aeadByKeyID[key.ID] = aead
	}
	if _, exists := aeadByKeyID[currentKeyID]; !exists {
		return nil, ErrInvalidCursor
	}

	return &Codec{
		currentKeyID: currentKeyID,
		aeadByKeyID:  aeadByKeyID,
		ttl:          ttl,
		now:          time.Now,
		random:       rand.Reader,
	}, nil
}

func (c *Codec) Encode(input EncodeInput) (string, error) {
	if c == nil || !validSubject(input.Subject) || !input.Locale.IsValid() ||
		input.Position.SavedAt.IsZero() || input.Position.ItemID == uuid.Nil ||
		(input.Position.MatchRank != nil && *input.Position.MatchRank < 0) {
		return "", ErrInvalidCursor
	}

	now := c.now().UTC()
	payload := wirePayload{
		Schema:      tokenFormatVersion,
		Subject:     input.Subject,
		Scope:       base64.RawURLEncoding.EncodeToString(input.ScopeFingerprint[:]),
		Locale:      string(input.Locale),
		SavedAtUS:   input.Position.SavedAt.UTC().UnixMicro(),
		ItemID:      input.Position.ItemID.String(),
		MatchRank:   copyInt64(input.Position.MatchRank),
		ExpiresAtUS: now.Add(c.ttl).UnixMicro(),
	}
	plaintext, err := json.Marshal(payload)
	if err != nil {
		return "", ErrInvalidCursor
	}

	header := make([]byte, tokenHeaderBytes)
	header[0] = tokenFormatVersion
	binary.BigEndian.PutUint32(header[1:], c.currentKeyID)
	aead := c.aeadByKeyID[c.currentKeyID]
	nonce := make([]byte, aead.NonceSize())
	if _, err := io.ReadFull(c.random, nonce); err != nil {
		return "", ErrInvalidCursor
	}
	ciphertext := aead.Seal(nil, nonce, plaintext, header)
	tokenBytes := make([]byte, 0, len(header)+len(nonce)+len(ciphertext))
	tokenBytes = append(tokenBytes, header...)
	tokenBytes = append(tokenBytes, nonce...)
	tokenBytes = append(tokenBytes, ciphertext...)
	if len(tokenBytes) > maxTokenBytes {
		return "", ErrInvalidCursor
	}
	return base64.RawURLEncoding.EncodeToString(tokenBytes), nil
}

func (c *Codec) Decode(token string, expected DecodeExpectation) (Position, error) {
	if c == nil || token == "" || len(token) > base64.RawURLEncoding.EncodedLen(maxTokenBytes) ||
		!validSubject(expected.Subject) || !expected.Locale.IsValid() {
		return Position{}, ErrInvalidCursor
	}

	tokenBytes, err := base64.RawURLEncoding.DecodeString(token)
	if err != nil || len(tokenBytes) < tokenHeaderBytes {
		return Position{}, ErrInvalidCursor
	}
	header := tokenBytes[:tokenHeaderBytes]
	if header[0] != tokenFormatVersion {
		return Position{}, ErrInvalidCursor
	}
	keyID := binary.BigEndian.Uint32(header[1:])
	aead, exists := c.aeadByKeyID[keyID]
	if !exists || len(tokenBytes) < tokenHeaderBytes+aead.NonceSize()+aead.Overhead() {
		return Position{}, ErrInvalidCursor
	}
	nonceStart := tokenHeaderBytes
	ciphertextStart := nonceStart + aead.NonceSize()
	plaintext, err := aead.Open(nil, tokenBytes[nonceStart:ciphertextStart], tokenBytes[ciphertextStart:], header)
	if err != nil {
		return Position{}, ErrInvalidCursor
	}

	var payload wirePayload
	decoder := json.NewDecoder(bytes.NewReader(plaintext))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&payload); err != nil {
		return Position{}, ErrInvalidCursor
	}
	if decoder.Decode(&struct{}{}) != io.EOF {
		return Position{}, ErrInvalidCursor
	}
	if payload.Schema != tokenFormatVersion || !constantTimeEqual(payload.Subject, expected.Subject) ||
		payload.Locale != string(expected.Locale) || payload.ExpiresAtUS <= c.now().UTC().UnixMicro() {
		return Position{}, ErrInvalidCursor
	}

	scope, err := base64.RawURLEncoding.DecodeString(payload.Scope)
	if err != nil || len(scope) != scopeFingerprintBytes ||
		subtle.ConstantTimeCompare(scope, expected.ScopeFingerprint[:]) != 1 {
		return Position{}, ErrInvalidCursor
	}
	itemID, err := uuid.Parse(payload.ItemID)
	if err != nil || itemID == uuid.Nil || payload.SavedAtUS <= 0 ||
		(payload.MatchRank != nil && *payload.MatchRank < 0) {
		return Position{}, ErrInvalidCursor
	}

	return Position{
		SavedAt:   time.UnixMicro(payload.SavedAtUS).UTC(),
		ItemID:    itemID,
		MatchRank: copyInt64(payload.MatchRank),
	}, nil
}

func validSubject(subject string) bool {
	return subject != "" && subject == strings.TrimSpace(subject) && len(subject) <= maxSubjectBytes
}

func constantTimeEqual(left string, right string) bool {
	return len(left) == len(right) && subtle.ConstantTimeCompare([]byte(left), []byte(right)) == 1
}

func copyInt64(value *int64) *int64 {
	if value == nil {
		return nil
	}
	copy := *value
	return &copy
}
