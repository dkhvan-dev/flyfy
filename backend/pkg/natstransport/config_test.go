package natstransport

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"fmt"
	"math/big"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/nats-io/nkeys"
)

func TestEnvConfigBuildKeepsLocalPlaintextFlow(t *testing.T) {
	t.Parallel()

	cfg, err := boundedEnvConfig().Build("development", "nats://localhost:4222")
	if err != nil {
		t.Fatalf("Build() error = %v", err)
	}
	if cfg.URLs != "nats://localhost:4222" {
		t.Fatalf("URLs = %q, want local default", cfg.URLs)
	}
	prepared, err := cfg.prepare()
	if err != nil {
		t.Fatalf("prepare() error = %v", err)
	}
	if prepared.secure || len(prepared.endpoints) != 1 || prepared.endpoints[0] != "nats://localhost:4222" {
		t.Fatalf("prepared config = %+v", prepared)
	}
}

func TestConfigRejectsUnsafeOrAmbiguousEndpoints(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name        string
		environment string
		urls        string
	}{
		{name: "production plaintext", environment: "production", urls: "nats://nats.internal:4222"},
		{name: "staging plaintext", environment: "staging", urls: "nats://nats.internal:4222"},
		{name: "inline user password", environment: "development", urls: "nats://user:password@nats.internal:4222"},
		{name: "inline token", environment: "development", urls: "nats://token@nats.internal:4222"},
		{name: "mixed schemes", environment: "development", urls: "nats://nats-a:4222,tls://nats-b:4222"},
		{name: "duplicate endpoint", environment: "development", urls: "nats://NATS-A,nats://nats-a:4222/"},
		{name: "too many endpoints", environment: "development", urls: strings.Repeat("nats://nats.internal:4222,", 8) + "nats://last.internal:4222"},
		{name: "unsupported scheme", environment: "development", urls: "ws://nats.internal:4222"},
		{name: "unknown environment", environment: "prodution", urls: "tls://nats.internal:4222"},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			env := boundedEnvConfig()
			env.URLs = test.urls
			if _, err := env.Build(test.environment, "nats://localhost:4222"); err == nil {
				t.Fatal("Build() error = nil, want rejection")
			}
		})
	}
}

func TestSecureConfigRequiresEveryMountedSecret(t *testing.T) {
	t.Parallel()

	fixture := newSecureFixture(t)
	tests := []struct {
		name   string
		mutate func(*EnvConfig)
	}{
		{name: "credentials", mutate: func(c *EnvConfig) { c.CredentialsPath = "" }},
		{name: "CA", mutate: func(c *EnvConfig) { c.CACertPath = "" }},
		{name: "client certificate", mutate: func(c *EnvConfig) { c.ClientCertPath = "" }},
		{name: "client key", mutate: func(c *EnvConfig) { c.ClientKeyPath = "" }},
		{name: "server name", mutate: func(c *EnvConfig) { c.TLSServerName = "" }},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			cfg := fixture.env
			test.mutate(&cfg)
			if _, err := cfg.Build("production", ""); err == nil {
				t.Fatal("Build() error = nil, want rejection")
			}
		})
	}
}

func TestSecureConfigRejectsMalformedMountedFiles(t *testing.T) {
	t.Parallel()

	fixture := newSecureFixture(t)
	malformed := filepath.Join(t.TempDir(), "malformed-secret")
	if err := os.WriteFile(malformed, []byte("not valid material"), 0o600); err != nil {
		t.Fatalf("WriteFile() error = %v", err)
	}
	tests := []struct {
		name   string
		mutate func(*EnvConfig)
	}{
		{name: "relative credentials path", mutate: func(c *EnvConfig) { c.CredentialsPath = "relative.creds" }},
		{name: "missing credentials file", mutate: func(c *EnvConfig) { c.CredentialsPath = filepath.Join(t.TempDir(), "missing.creds") }},
		{name: "malformed credentials", mutate: func(c *EnvConfig) { c.CredentialsPath = malformed }},
		{name: "malformed CA", mutate: func(c *EnvConfig) { c.CACertPath = malformed }},
		{name: "malformed client certificate", mutate: func(c *EnvConfig) { c.ClientCertPath = malformed }},
		{name: "malformed client key", mutate: func(c *EnvConfig) { c.ClientKeyPath = malformed }},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			cfg := fixture.env
			test.mutate(&cfg)
			if _, err := cfg.Build("production", ""); err == nil {
				t.Fatal("Build() error = nil, want rejection")
			}
		})
	}
}

func TestSecureConfigAcceptsTLS13CredentialedMutualTLS(t *testing.T) {
	t.Parallel()

	fixture := newSecureFixture(t)
	fixture.env.URLs = "tls://nats-a.internal:4222,tls://nats-b.internal:4222"
	cfg, err := fixture.env.Build("production", "")
	if err != nil {
		t.Fatalf("Build() error = %v", err)
	}
	prepared, err := cfg.prepare()
	if err != nil {
		t.Fatalf("prepare() error = %v", err)
	}
	if !prepared.secure || prepared.tls == nil {
		t.Fatal("secure TLS configuration was not prepared")
	}
	if prepared.tls.MinVersion != 0x0304 {
		t.Fatalf("TLS minimum version = %#x, want TLS 1.3", prepared.tls.MinVersion)
	}
	if prepared.tls.ServerName != "nats.internal" || len(prepared.tls.Certificates) != 1 {
		t.Fatalf("TLS config has unexpected identity settings")
	}
}

func TestSecureConfigRejectsTLSVersionDowngrade(t *testing.T) {
	t.Parallel()

	fixture := newSecureFixture(t)
	fixture.env.TLSMinVersion = "1.2"
	if _, err := fixture.env.Build("production", ""); err == nil {
		t.Fatal("Build() error = nil, want TLS downgrade rejection")
	}
}

func TestConfigFormattingRedactsEndpointsAndSecretPaths(t *testing.T) {
	t.Parallel()

	secretURL := "nats://user:top-secret@private.internal:4222"
	secretPath := "/run/secrets/tenant-a/nats.creds"
	env := boundedEnvConfig()
	env.URLs = secretURL
	env.CredentialsPath = secretPath
	wrapper := struct {
		NATS EnvConfig
	}{NATS: env}
	formatted := fmt.Sprintf("%s %v %#v %+v", env.String(), env, env, wrapper)
	for _, secret := range []string{"user", "top-secret", "private.internal", secretPath} {
		if strings.Contains(formatted, secret) {
			t.Fatalf("formatted config leaked %q: %s", secret, formatted)
		}
	}
}

func boundedEnvConfig() EnvConfig {
	return EnvConfig{
		TLSMinVersion:  "1.3",
		ConnectTimeout: 3 * time.Second,
		ReconnectWait:  time.Second,
		MaxReconnects:  30,
		PingInterval:   20 * time.Second,
		MaxPingsOut:    2,
		DrainTimeout:   5 * time.Second,
	}
}

type secureFixture struct {
	env EnvConfig
}

func newSecureFixture(t *testing.T) secureFixture {
	t.Helper()
	directory := t.TempDir()
	caPath, certPath, keyPath := writeCertificates(t, directory)
	credentialsPath := filepath.Join(directory, "nats.creds")
	if err := os.WriteFile(credentialsPath, newCredentials(t), 0o600); err != nil {
		t.Fatalf("write credentials: %v", err)
	}
	env := boundedEnvConfig()
	env.URLs = "tls://nats.internal:4222"
	env.CredentialsPath = credentialsPath
	env.CACertPath = caPath
	env.ClientCertPath = certPath
	env.ClientKeyPath = keyPath
	env.TLSServerName = "nats.internal"
	return secureFixture{env: env}
}

func newCredentials(t *testing.T) []byte {
	t.Helper()
	keyPair, err := nkeys.CreateUser()
	if err != nil {
		t.Fatalf("CreateUser() error = %v", err)
	}
	defer keyPair.Wipe()
	seed, err := keyPair.Seed()
	if err != nil {
		t.Fatalf("Seed() error = %v", err)
	}
	publicKey, err := keyPair.PublicKey()
	if err != nil {
		t.Fatalf("PublicKey() error = %v", err)
	}
	issuer, err := nkeys.CreateAccount()
	if err != nil {
		t.Fatalf("CreateAccount() error = %v", err)
	}
	defer issuer.Wipe()
	issuerPublicKey, err := issuer.PublicKey()
	if err != nil {
		t.Fatalf("issuer PublicKey() error = %v", err)
	}
	header, _ := json.Marshal(map[string]string{"typ": "jwt", "alg": "ed25519-nkey"})
	payload, _ := json.Marshal(map[string]string{"iss": issuerPublicKey, "sub": publicKey})
	unsignedJWT := strings.Join([]string{
		base64.RawURLEncoding.EncodeToString(header),
		base64.RawURLEncoding.EncodeToString(payload),
	}, ".")
	signature, err := issuer.Sign([]byte(unsignedJWT))
	if err != nil {
		t.Fatalf("issuer Sign() error = %v", err)
	}
	jwt := unsignedJWT + "." + base64.RawURLEncoding.EncodeToString(signature)
	return []byte(fmt.Sprintf(
		"-----BEGIN NATS USER JWT-----\n%s\n------END NATS USER JWT------\n\n-----BEGIN USER NKEY SEED-----\n%s\n------END USER NKEY SEED------\n",
		jwt,
		seed,
	))
}

func writeCertificates(t *testing.T, directory string) (string, string, string) {
	t.Helper()
	now := time.Now()
	caKey, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		t.Fatalf("generate CA key: %v", err)
	}
	caTemplate := &x509.Certificate{
		SerialNumber:          big.NewInt(1),
		Subject:               pkix.Name{CommonName: "NATS test CA"},
		NotBefore:             now.Add(-time.Hour),
		NotAfter:              now.Add(time.Hour),
		IsCA:                  true,
		BasicConstraintsValid: true,
		KeyUsage:              x509.KeyUsageCertSign | x509.KeyUsageDigitalSignature,
	}
	caDER, err := x509.CreateCertificate(rand.Reader, caTemplate, caTemplate, &caKey.PublicKey, caKey)
	if err != nil {
		t.Fatalf("create CA certificate: %v", err)
	}
	clientKey, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		t.Fatalf("generate client key: %v", err)
	}
	clientTemplate := &x509.Certificate{
		SerialNumber: big.NewInt(2),
		Subject:      pkix.Name{CommonName: "saved-lifecycle-producer"},
		NotBefore:    now.Add(-time.Hour),
		NotAfter:     now.Add(time.Hour),
		KeyUsage:     x509.KeyUsageDigitalSignature,
		ExtKeyUsage:  []x509.ExtKeyUsage{x509.ExtKeyUsageClientAuth},
	}
	clientDER, err := x509.CreateCertificate(rand.Reader, clientTemplate, caTemplate, &clientKey.PublicKey, caKey)
	if err != nil {
		t.Fatalf("create client certificate: %v", err)
	}
	privateKey, err := x509.MarshalPKCS8PrivateKey(clientKey)
	if err != nil {
		t.Fatalf("marshal client key: %v", err)
	}
	caPath := filepath.Join(directory, "ca.pem")
	certPath := filepath.Join(directory, "client.pem")
	keyPath := filepath.Join(directory, "client-key.pem")
	writePEM(t, caPath, "CERTIFICATE", caDER)
	writePEM(t, certPath, "CERTIFICATE", clientDER)
	writePEM(t, keyPath, "PRIVATE KEY", privateKey)
	return caPath, certPath, keyPath
}

func writePEM(t *testing.T, path, blockType string, contents []byte) {
	t.Helper()
	file, err := os.OpenFile(path, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0o600)
	if err != nil {
		t.Fatalf("open PEM file: %v", err)
	}
	if err = pem.Encode(file, &pem.Block{Type: blockType, Bytes: contents}); err != nil {
		_ = file.Close()
		t.Fatalf("encode PEM: %v", err)
	}
	if err = file.Close(); err != nil {
		t.Fatalf("close PEM file: %v", err)
	}
}
