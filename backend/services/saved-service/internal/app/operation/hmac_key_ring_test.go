package operation

import (
	"bytes"
	"errors"
	"fmt"
	"strings"
	"testing"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestNewHMACKeyRingValidatesEveryKey(t *testing.T) {
	t.Parallel()

	validCurrent := HMACKeyConfig{Version: 2, Secret: testSecret('c')}
	tests := []struct {
		name         string
		current      HMACKeyConfig
		verification []HMACKeyConfig
	}{
		{name: "zero current version", current: HMACKeyConfig{Secret: testSecret('c')}},
		{name: "weak current secret", current: HMACKeyConfig{Version: 2, Secret: bytes.Repeat([]byte{'c'}, minimumHMACSecretBytes-1)}},
		{name: "zero verification version", current: validCurrent, verification: []HMACKeyConfig{{Secret: testSecret('v')}}},
		{name: "weak verification secret", current: validCurrent, verification: []HMACKeyConfig{{Version: 1, Secret: []byte("weak")}}},
		{name: "duplicates current version", current: validCurrent, verification: []HMACKeyConfig{{Version: 2, Secret: testSecret('v')}}},
		{name: "duplicates verification version", current: validCurrent, verification: []HMACKeyConfig{{Version: 1, Secret: testSecret('a')}, {Version: 1, Secret: testSecret('b')}}},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			_, err := NewHMACKeyRing(test.current, test.verification...)
			if !errors.Is(err, ErrInvalidHMACKeyRing) {
				t.Fatalf("NewHMACKeyRing() error = %v, want %v", err, ErrInvalidHMACKeyRing)
			}
		})
	}

	if _, err := NewHMACKeyRing(validCurrent, HMACKeyConfig{Version: 1, Secret: testSecret('v')}); err != nil {
		t.Fatalf("NewHMACKeyRing(valid) error = %v", err)
	}
}

func TestHMACKeyRingRotationOverlap(t *testing.T) {
	t.Parallel()

	target := mustSavedTarget(t, domain.EntityTypeGuide, "guide|rotation:42")
	oldConfig := HMACKeyConfig{Version: 7, Secret: testSecret('o')}
	newConfig := HMACKeyConfig{Version: 8, Secret: testSecret('n')}

	oldRing, err := NewHMACKeyRing(oldConfig)
	if err != nil {
		t.Fatalf("NewHMACKeyRing(old) error = %v", err)
	}
	oldMAC, err := oldRing.Sign(domain.OperationKindSave, target)
	if err != nil {
		t.Fatalf("oldRing.Sign() error = %v", err)
	}

	rotatedRing, err := NewHMACKeyRing(newConfig, oldConfig)
	if err != nil {
		t.Fatalf("NewHMACKeyRing(rotated) error = %v", err)
	}
	if !rotatedRing.Verify(oldMAC.KeyVersion, domain.OperationKindSave, target, oldMAC.Bytes()) {
		t.Fatal("rotated key ring rejected an overlapping verification key")
	}

	newMAC, err := rotatedRing.Sign(domain.OperationKindSave, target)
	if err != nil {
		t.Fatalf("rotatedRing.Sign() error = %v", err)
	}
	if newMAC.KeyVersion != newConfig.Version || rotatedRing.CurrentVersion() != newConfig.Version {
		t.Fatalf("current signing version = %d/%d, want %d", newMAC.KeyVersion, rotatedRing.CurrentVersion(), newConfig.Version)
	}
	if bytes.Equal(oldMAC.Bytes(), newMAC.Bytes()) {
		t.Fatal("rotated signing key produced the old digest")
	}
	if !rotatedRing.Verify(newMAC.KeyVersion, domain.OperationKindSave, target, newMAC.Bytes()) {
		t.Fatal("rotated key ring rejected its current signing key")
	}

	withoutOverlap, err := NewHMACKeyRing(newConfig)
	if err != nil {
		t.Fatalf("NewHMACKeyRing(without overlap) error = %v", err)
	}
	if withoutOverlap.Verify(oldMAC.KeyVersion, domain.OperationKindSave, target, oldMAC.Bytes()) {
		t.Fatal("key ring verified a version that was not configured")
	}
	if rotatedRing.Verify(oldMAC.KeyVersion, domain.OperationKindSave, target, oldMAC.Bytes()[:8]) {
		t.Fatal("key ring verified a truncated digest")
	}
	otherTarget := mustSavedTarget(t, domain.EntityTypeGuide, "guide|rotation:43")
	if rotatedRing.Verify(oldMAC.KeyVersion, domain.OperationKindSave, otherTarget, oldMAC.Bytes()) {
		t.Fatal("key ring verified a digest for different semantics")
	}
}

func TestHMACKeyRingCopiesAndRedactsSecrets(t *testing.T) {
	t.Parallel()

	secret := bytes.Repeat([]byte("s"), minimumHMACSecretBytes)
	ring, err := NewHMACKeyRing(HMACKeyConfig{Version: 1, Secret: secret})
	if err != nil {
		t.Fatalf("NewHMACKeyRing() error = %v", err)
	}
	target := mustSavedTarget(t, domain.EntityTypeAttraction, "attraction-42")
	before, err := ring.Sign(domain.OperationKindSave, target)
	if err != nil {
		t.Fatalf("Sign(before mutation) error = %v", err)
	}
	clear(secret)
	after, err := ring.Sign(domain.OperationKindSave, target)
	if err != nil {
		t.Fatalf("Sign(after mutation) error = %v", err)
	}
	if !bytes.Equal(before.Bytes(), after.Bytes()) {
		t.Fatal("key ring retained an alias to constructor key material")
	}

	formatted := fmt.Sprintf("%v %#v", ring, ring)
	if strings.Contains(formatted, strings.Repeat("s", minimumHMACSecretBytes)) || formatted != "HMACKeyRing{redacted} HMACKeyRing{redacted}" {
		t.Fatalf("key ring formatter exposed internals: %q", formatted)
	}
}

func testSecret(value byte) []byte {
	return bytes.Repeat([]byte{value}, minimumHMACSecretBytes)
}
