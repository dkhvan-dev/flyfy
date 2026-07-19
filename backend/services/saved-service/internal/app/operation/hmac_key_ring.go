package operation

import (
	"crypto/hmac"
	"crypto/sha256"
	"errors"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

const minimumHMACSecretBytes = 32

var ErrInvalidHMACKeyRing = errors.New("invalid semantic HMAC key ring")

// HMACKeyConfig is constructor input only. HMACKeyRing copies the secret and
// provides no API that returns key material.
type HMACKeyConfig struct {
	Version uint32
	Secret  []byte
}

// SemanticRequestHMAC is safe to persist with an operation receipt. It
// contains a digest and key version, never key material or canonical payload.
type SemanticRequestHMAC struct {
	KeyVersion uint32
	digest     [sha256.Size]byte
}

func (m SemanticRequestHMAC) Bytes() []byte {
	return append([]byte(nil), m.digest[:]...)
}

// HMACKeyRing is immutable after construction and safe for concurrent use.
type HMACKeyRing struct {
	currentVersion uint32
	keys           map[uint32][]byte
}

func NewHMACKeyRing(current HMACKeyConfig, verification ...HMACKeyConfig) (*HMACKeyRing, error) {
	keys := make(map[uint32][]byte, len(verification)+1)
	allKeys := make([]HMACKeyConfig, 0, len(verification)+1)
	allKeys = append(allKeys, current)
	allKeys = append(allKeys, verification...)

	for _, key := range allKeys {
		if key.Version == 0 || len(key.Secret) < minimumHMACSecretBytes {
			return nil, ErrInvalidHMACKeyRing
		}
		if _, exists := keys[key.Version]; exists {
			return nil, ErrInvalidHMACKeyRing
		}
		keys[key.Version] = append([]byte(nil), key.Secret...)
	}

	return &HMACKeyRing{currentVersion: current.Version, keys: keys}, nil
}

func (r *HMACKeyRing) CurrentVersion() uint32 {
	if r == nil {
		return 0
	}
	return r.currentVersion
}

func (r *HMACKeyRing) Sign(kind domain.OperationKind, target domain.SavedTarget) (SemanticRequestHMAC, error) {
	if r == nil {
		return SemanticRequestHMAC{}, ErrInvalidHMACKeyRing
	}
	canonical, err := canonicalSemanticRequest(kind, target)
	if err != nil {
		return SemanticRequestHMAC{}, err
	}
	defer clear(canonical)
	return r.signCanonical(canonical)
}

func (r *HMACKeyRing) SignCollection(request CollectionSemanticRequest) (SemanticRequestHMAC, error) {
	if r == nil {
		return SemanticRequestHMAC{}, ErrInvalidHMACKeyRing
	}
	canonical, _, err := canonicalCollectionSemanticRequest(request)
	if err != nil {
		return SemanticRequestHMAC{}, err
	}
	defer clear(canonical)
	return r.signCanonical(canonical)
}

// Verify always compares fixed-size digests with hmac.Equal. An unknown key
// version is evaluated with a fixed dummy key before returning false.
func (r *HMACKeyRing) Verify(
	keyVersion uint32,
	kind domain.OperationKind,
	target domain.SavedTarget,
	expected []byte,
) bool {
	canonical, err := canonicalSemanticRequest(kind, target)
	if err != nil {
		return false
	}
	defer clear(canonical)
	return r.verifyCanonical(keyVersion, canonical, expected)
}

func (r *HMACKeyRing) VerifyCollection(
	keyVersion uint32,
	request CollectionSemanticRequest,
	expected []byte,
) bool {
	canonical, _, err := canonicalCollectionSemanticRequest(request)
	if err != nil {
		return false
	}
	defer clear(canonical)
	return r.verifyCanonical(keyVersion, canonical, expected)
}

func (r *HMACKeyRing) signCanonical(canonical []byte) (SemanticRequestHMAC, error) {
	if r == nil {
		return SemanticRequestHMAC{}, ErrInvalidHMACKeyRing
	}
	secret, exists := r.keys[r.currentVersion]
	if !exists {
		return SemanticRequestHMAC{}, ErrInvalidHMACKeyRing
	}
	digest := calculateHMAC(secret, canonical)
	return SemanticRequestHMAC{KeyVersion: r.currentVersion, digest: digest}, nil
}

func (r *HMACKeyRing) verifyCanonical(keyVersion uint32, canonical []byte, expected []byte) bool {
	if r == nil {
		return false
	}

	var dummySecret [minimumHMACSecretBytes]byte
	secret := dummySecret[:]
	configuredSecret, keyExists := r.keys[keyVersion]
	if keyExists {
		secret = configuredSecret
	}

	actual := calculateHMAC(secret, canonical)
	defer clear(actual[:])

	var expectedDigest [sha256.Size]byte
	validDigestLength := len(expected) == sha256.Size
	if validDigestLength {
		copy(expectedDigest[:], expected)
	}
	defer clear(expectedDigest[:])

	digestsEqual := hmac.Equal(actual[:], expectedDigest[:])
	return keyExists && validDigestLength && digestsEqual
}

func calculateHMAC(secret []byte, canonical []byte) [sha256.Size]byte {
	mac := hmac.New(sha256.New, secret)
	_, _ = mac.Write(canonical)

	var digest [sha256.Size]byte
	copy(digest[:], mac.Sum(nil))
	return digest
}

// String and GoString prevent accidental formatter-based disclosure.
func (r *HMACKeyRing) String() string {
	return "HMACKeyRing{redacted}"
}

func (r *HMACKeyRing) GoString() string {
	return "HMACKeyRing{redacted}"
}
