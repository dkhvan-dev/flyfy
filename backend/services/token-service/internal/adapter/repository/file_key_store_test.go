package repository

import (
	"context"
	"crypto/rand"
	"crypto/rsa"
	"path/filepath"
	"testing"
)

func TestFileKeyStorePersistsActiveKeyAcrossInstances(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	storePath := filepath.Join(t.TempDir(), "signing-keys.json")

	store := NewFileKeyStore(storePath)
	key, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatalf("generate RSA key: %v", err)
	}

	if err := store.StoreKey(ctx, "key-1", key); err != nil {
		t.Fatalf("store key: %v", err)
	}

	reopened := NewFileKeyStore(storePath)
	keyID, restored, err := reopened.GetActiveKey(ctx)
	if err != nil {
		t.Fatalf("get active key: %v", err)
	}

	if keyID != "key-1" {
		t.Fatalf("unexpected key id: got %q want %q", keyID, "key-1")
	}

	if restored.N.Cmp(key.N) != 0 {
		t.Fatal("restored key does not match the stored key")
	}

	pubKeys, err := reopened.GetPublicKeys(ctx)
	if err != nil {
		t.Fatalf("get public keys: %v", err)
	}

	if len(pubKeys) != 1 {
		t.Fatalf("unexpected public key count: got %d want 1", len(pubKeys))
	}

	if pubKeys[0].KeyID != "key-1" {
		t.Fatalf("unexpected public key id: got %q want %q", pubKeys[0].KeyID, "key-1")
	}
}

func TestFileKeyStoreDeleteExpiredKeysKeepsNewest(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store := NewFileKeyStore(filepath.Join(t.TempDir(), "signing-keys.json"))

	for _, keyID := range []string{"key-1", "key-2", "key-3"} {
		key, err := rsa.GenerateKey(rand.Reader, 1024)
		if err != nil {
			t.Fatalf("generate RSA key: %v", err)
		}
		if err := store.StoreKey(ctx, keyID, key); err != nil {
			t.Fatalf("store key %s: %v", keyID, err)
		}
	}

	if err := store.DeleteExpiredKeys(ctx, 2); err != nil {
		t.Fatalf("delete expired keys: %v", err)
	}

	pubKeys, err := store.GetPublicKeys(ctx)
	if err != nil {
		t.Fatalf("get public keys: %v", err)
	}

	if len(pubKeys) != 2 {
		t.Fatalf("unexpected public key count: got %d want 2", len(pubKeys))
	}

	if pubKeys[0].KeyID != "key-2" || pubKeys[1].KeyID != "key-3" {
		t.Fatalf("unexpected key order after cleanup: got %q, %q", pubKeys[0].KeyID, pubKeys[1].KeyID)
	}
}
