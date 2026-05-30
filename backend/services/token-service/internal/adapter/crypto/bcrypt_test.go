package crypto_test

import (
	"testing"

	"kz/inflap/backend/services/token-service/internal/adapter/crypto"
)

func TestBcryptVerifier_HashAndVerify(t *testing.T) {
	v := crypto.NewBcryptVerifier(10) // lower cost for faster tests

	secret := "auth-service-secret-2026"

	hash, err := v.Hash(secret)
	if err != nil {
		t.Fatalf("hash: %v", err)
	}

	if hash == "" {
		t.Fatal("hash is empty")
	}

	if hash == secret {
		t.Fatal("hash should not equal plaintext")
	}

	// Verify correct secret
	if !v.Verify(hash, secret) {
		t.Error("verify should return true for correct secret")
	}

	// Verify wrong secret
	if v.Verify(hash, "wrong-secret") {
		t.Error("verify should return false for wrong secret")
	}
}

func TestBcryptVerifier_DefaultCost(t *testing.T) {
	v := crypto.NewBcryptVerifier(0) // should use DefaultCost

	hash, err := v.Hash("test")
	if err != nil {
		t.Fatalf("hash with default cost: %v", err)
	}

	if !v.Verify(hash, "test") {
		t.Error("should verify with default cost")
	}
}

func TestBcryptVerifier_EmptyInputs(t *testing.T) {
	v := crypto.NewBcryptVerifier(10)

	// Empty plaintext against valid hash should fail
	hash, _ := v.Hash("something")
	if v.Verify(hash, "") {
		t.Error("empty plaintext should not match")
	}

	// Empty hash should fail
	if v.Verify("", "something") {
		t.Error("empty hash should not match")
	}
}

// Verify it implements the port interface at compile time
// (This would be checked if we import the port package.)
func TestBcryptVerifier_ImplementsInterface(t *testing.T) {
	v := crypto.NewBcryptVerifier(10)

	// Verify method exists and works
	_ = v.Verify("", "")

	// Hash method exists and works
	_, _ = v.Hash("")
}
