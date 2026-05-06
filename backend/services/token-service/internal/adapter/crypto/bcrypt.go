package crypto

import (
	"fmt"

	"golang.org/x/crypto/bcrypt"
)

const (
	// DefaultCost is the bcrypt cost factor.
	// 12 is a good balance between security and performance (~250ms on modern hardware).
	DefaultCost = 12
)

// BcryptVerifier implements port.PasswordVerifier using bcrypt.
type BcryptVerifier struct {
	cost int
}

// NewBcryptVerifier creates a BcryptVerifier with the given cost.
// If cost <= 0, DefaultCost is used.
func NewBcryptVerifier(cost int) *BcryptVerifier {
	if cost <= 0 {
		cost = DefaultCost
	}
	return &BcryptVerifier{cost: cost}
}

// Verify compares a bcrypt hash with a plaintext secret.
func (v *BcryptVerifier) Verify(hash, plaintext string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(plaintext))
	return err == nil
}

// Hash creates a bcrypt hash from a plaintext value.
func (v *BcryptVerifier) Hash(plaintext string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(plaintext), v.cost)
	if err != nil {
		return "", fmt.Errorf("bcrypt hash: %w", err)
	}
	return string(bytes), nil
}
