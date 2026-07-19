package cursor

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/binary"
	"errors"
	"strings"
	"unicode/utf8"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

const scopeFingerprintBytes = sha256.Size

var ErrInvalidScope = errors.New("invalid saved cursor scope")

type Locale string

const (
	LocaleEN Locale = "EN"
	LocaleRU Locale = "RU"
	LocaleKK Locale = "KK"
)

func (l Locale) IsValid() bool {
	return l == LocaleEN || l == LocaleRU || l == LocaleKK
}

// Scope contains only canonical query inputs. Its raw representation is never
// written to a cursor; only the keyed fingerprint is included.
type Scope struct {
	EntityType   *domain.EntityType
	CollectionID *uuid.UUID
	Uncollected  bool
	Search       string
	Locale       Locale
}

type Fingerprinter struct {
	key []byte
}

func NewFingerprinter(key []byte) (*Fingerprinter, error) {
	if len(key) < 32 {
		return nil, ErrInvalidScope
	}
	return &Fingerprinter{key: append([]byte(nil), key...)}, nil
}

func (f *Fingerprinter) Fingerprint(scope Scope) ([scopeFingerprintBytes]byte, error) {
	var empty [scopeFingerprintBytes]byte
	if f == nil || len(f.key) < 32 || !scope.Locale.IsValid() {
		return empty, ErrInvalidScope
	}
	if scope.EntityType != nil && !scope.EntityType.IsValid() {
		return empty, ErrInvalidScope
	}
	if scope.CollectionID != nil && *scope.CollectionID == uuid.Nil {
		return empty, ErrInvalidScope
	}
	if scope.CollectionID != nil && scope.Uncollected {
		return empty, ErrInvalidScope
	}
	if scope.Search != strings.TrimSpace(scope.Search) {
		return empty, ErrInvalidScope
	}
	if !utf8.ValidString(scope.Search) || utf8.RuneCountInString(scope.Search) > 200 {
		return empty, ErrInvalidScope
	}

	mac := hmac.New(sha256.New, f.key)
	writeField(mac, "saved-cursor-scope-v1")
	if scope.EntityType == nil {
		writeField(mac, "")
	} else {
		writeField(mac, string(*scope.EntityType))
	}
	if scope.CollectionID == nil {
		writeField(mac, "")
	} else {
		writeField(mac, scope.CollectionID.String())
	}
	if scope.Uncollected {
		writeField(mac, "1")
	} else {
		writeField(mac, "0")
	}
	writeField(mac, scope.Search)
	writeField(mac, string(scope.Locale))

	var result [scopeFingerprintBytes]byte
	copy(result[:], mac.Sum(nil))
	return result, nil
}

type fieldWriter interface {
	Write([]byte) (int, error)
}

func writeField(writer fieldWriter, value string) {
	var size [4]byte
	binary.BigEndian.PutUint32(size[:], uint32(len(value)))
	_, _ = writer.Write(size[:])
	_, _ = writer.Write([]byte(value))
}
