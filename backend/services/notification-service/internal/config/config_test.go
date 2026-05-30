package config

import (
	"context"
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestLoadReadsSensitiveValuesFromSecretFiles(t *testing.T) {
	secretDir := t.TempDir()
	internalTokenPath := writeSecret(t, secretDir, "internal-token", "internal-token-from-file\n")
	encryptionKeyPath := writeSecret(t, secretDir, "token-encryption", "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\n")
	hashKeyPath := writeSecret(t, secretDir, "token-hash", "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=\n")
	dbPasswordPath := writeSecret(t, secretDir, "db-password", "postgres-from-file\n")
	hmsSecretPath := writeSecret(t, secretDir, "hms-secret", "hms-from-file\n")

	t.Setenv("INTERNAL_SERVICE_TOKEN_FILE", internalTokenPath)
	t.Setenv("NOTIFICATION_TOKEN_ENCRYPTION_KEY_BASE64_FILE", encryptionKeyPath)
	t.Setenv("NOTIFICATION_TOKEN_HASH_KEY_BASE64_FILE", hashKeyPath)
	t.Setenv("DB_PASSWORD_FILE", dbPasswordPath)
	t.Setenv("HMS_CLIENT_SECRET_FILE", hmsSecretPath)
	t.Setenv("NATS_BATCH_SIZE", "10")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	if cfg.Security.InternalServiceToken != "internal-token-from-file" {
		t.Fatalf("unexpected internal token: %q", cfg.Security.InternalServiceToken)
	}
	if cfg.Security.TokenEncryptionKeyBase64 != "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=" {
		t.Fatalf("unexpected token encryption key: %q", cfg.Security.TokenEncryptionKeyBase64)
	}
	if cfg.Security.TokenHashKeyBase64 != "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=" {
		t.Fatalf("unexpected token hash key: %q", cfg.Security.TokenHashKeyBase64)
	}
	if cfg.DB.Password != "postgres-from-file" {
		t.Fatalf("unexpected db password: %q", cfg.DB.Password)
	}
	if cfg.Providers.HMS.ClientSecret != "hms-from-file" {
		t.Fatalf("unexpected hms client secret: %q", cfg.Providers.HMS.ClientSecret)
	}
}

func TestLoadRejectsMissingRequiredSecrets(t *testing.T) {
	t.Setenv("INTERNAL_SERVICE_TOKEN", "")
	t.Setenv("NOTIFICATION_TOKEN_ENCRYPTION_KEY_BASE64", "")
	t.Setenv("NOTIFICATION_TOKEN_HASH_KEY_BASE64", "")

	_, err := Load(context.Background())
	if err == nil {
		t.Fatal("expected Load to reject missing required secrets")
	}
}

func TestLoadConfiguresConsumerBackpressureAndConcurrency(t *testing.T) {
	setRequiredSecrets(t)
	t.Setenv("NATS_BATCH_SIZE", "750")
	t.Setenv("NATS_FANOUT_CONCURRENCY", "12")
	t.Setenv("NATS_DELIVERY_CONCURRENCY", "96")
	t.Setenv("NATS_MAX_DELIVER", "7")
	t.Setenv("NATS_MAX_ACK_PENDING", "12000")
	t.Setenv("NATS_STREAM_MAX_BYTES", "268435456")
	t.Setenv("NATS_ACK_WAIT", "45s")
	t.Setenv("NATS_NAK_DELAY", "3s")
	t.Setenv("NATS_FETCH_MAX_WAIT", "250ms")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	if cfg.NATS.BatchSize != 750 {
		t.Fatalf("unexpected batch size: %d", cfg.NATS.BatchSize)
	}
	if cfg.NATS.FanoutConcurrency != 12 {
		t.Fatalf("unexpected fanout concurrency: %d", cfg.NATS.FanoutConcurrency)
	}
	if cfg.NATS.DeliveryConcurrency != 96 {
		t.Fatalf("unexpected delivery concurrency: %d", cfg.NATS.DeliveryConcurrency)
	}
	if cfg.NATS.MaxDeliver != 7 {
		t.Fatalf("unexpected max deliver: %d", cfg.NATS.MaxDeliver)
	}
	if cfg.NATS.MaxAckPending != 12000 {
		t.Fatalf("unexpected max ack pending: %d", cfg.NATS.MaxAckPending)
	}
	if cfg.NATS.StreamMaxBytes != 268435456 {
		t.Fatalf("unexpected stream max bytes: %d", cfg.NATS.StreamMaxBytes)
	}
	if cfg.NATS.AckWait != 45*time.Second {
		t.Fatalf("unexpected ack wait: %s", cfg.NATS.AckWait)
	}
	if cfg.NATS.NakDelay != 3*time.Second {
		t.Fatalf("unexpected nak delay: %s", cfg.NATS.NakDelay)
	}
	if cfg.NATS.FetchMaxWait != 250*time.Millisecond {
		t.Fatalf("unexpected fetch max wait: %s", cfg.NATS.FetchMaxWait)
	}
}

func TestLoadRejectsInvalidConsumerBackpressureConfig(t *testing.T) {
	setRequiredSecrets(t)
	t.Setenv("NATS_DELIVERY_CONCURRENCY", "0")

	_, err := Load(context.Background())
	if err == nil {
		t.Fatal("expected Load to reject invalid delivery concurrency")
	}
}

func setRequiredSecrets(t *testing.T) {
	t.Helper()
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("NOTIFICATION_TOKEN_ENCRYPTION_KEY_BASE64", "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=")
	t.Setenv("NOTIFICATION_TOKEN_HASH_KEY_BASE64", "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=")
}

func writeSecret(t *testing.T, dir string, name string, value string) string {
	t.Helper()
	path := filepath.Join(dir, name)
	if err := os.WriteFile(path, []byte(value), 0o600); err != nil {
		t.Fatalf("write secret %s: %v", name, err)
	}
	return path
}
