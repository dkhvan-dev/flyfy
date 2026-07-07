package transportauth

import (
	"bytes"
	"crypto/rand"
	"crypto/rsa"
	"crypto/tls"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/pem"
	"math/big"
	"net"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestServerTLSConfigDisabledReturnsNil(t *testing.T) {
	t.Parallel()

	tlsConfig, err := Config{Mode: ModeDisabled}.ServerTLSConfig()
	if err != nil {
		t.Fatalf("ServerTLSConfig() error = %v", err)
	}
	if tlsConfig != nil {
		t.Fatalf("ServerTLSConfig() = %#v, want nil", tlsConfig)
	}
}

func TestServerTLSConfigEnforceRequiresVerifiedClientCertificate(t *testing.T) {
	t.Parallel()

	certs := newTestCertificates(t)
	serverTLS, err := Config{
		Mode:             ModeEnforce,
		CACertPath:       certs.caPath,
		ServerCertPath:   certs.serverCertPath,
		ServerKeyPath:    certs.serverKeyPath,
		AllowedSPIFFEIDs: []string{"spiffe://inflap/test/activity-service"},
	}.ServerTLSConfig()
	if err != nil {
		t.Fatalf("ServerTLSConfig() error = %v", err)
	}

	noClientCertTLS, err := Config{
		Mode:       ModeEnforce,
		CACertPath: certs.caPath,
		ServerName: "search-service",
	}.ClientTLSConfig()
	if err != nil {
		t.Fatalf("ClientTLSConfig(no cert) error = %v", err)
	}
	if err := tlsHandshake(serverTLS, noClientCertTLS); err == nil {
		t.Fatal("TLS handshake without client certificate error = nil, want error")
	}

	clientTLS, err := Config{
		Mode:           ModeEnforce,
		CACertPath:     certs.caPath,
		ClientCertPath: certs.clientCertPath,
		ClientKeyPath:  certs.clientKeyPath,
		ServerName:     "search-service",
	}.ClientTLSConfig()
	if err != nil {
		t.Fatalf("ClientTLSConfig(with cert) error = %v", err)
	}
	if err := tlsHandshake(serverTLS, clientTLS); err != nil {
		t.Fatalf("TLS handshake with allowed client certificate error = %v", err)
	}
}

func TestServerTLSConfigRejectsDisallowedSPIFFEID(t *testing.T) {
	t.Parallel()

	certs := newTestCertificates(t)
	serverTLS, err := Config{
		Mode:             ModeEnforce,
		CACertPath:       certs.caPath,
		ServerCertPath:   certs.serverCertPath,
		ServerKeyPath:    certs.serverKeyPath,
		AllowedSPIFFEIDs: []string{"spiffe://inflap/test/guide-service"},
	}.ServerTLSConfig()
	if err != nil {
		t.Fatalf("ServerTLSConfig() error = %v", err)
	}

	clientTLS, err := Config{
		Mode:           ModeEnforce,
		CACertPath:     certs.caPath,
		ClientCertPath: certs.clientCertPath,
		ClientKeyPath:  certs.clientKeyPath,
		ServerName:     "search-service",
	}.ClientTLSConfig()
	if err != nil {
		t.Fatalf("ClientTLSConfig() error = %v", err)
	}
	if err := tlsHandshake(serverTLS, clientTLS); err == nil {
		t.Fatal("TLS handshake with disallowed SPIFFE ID error = nil, want error")
	}
}

func TestClientTLSConfigDisabledKeepsPlainHTTP(t *testing.T) {
	t.Parallel()

	client, err := NewHTTPClient(Config{Mode: ModeDisabled}, time.Second)
	if err != nil {
		t.Fatalf("NewHTTPClient() error = %v", err)
	}

	if client.Transport != nil {
		t.Fatalf("disabled client transport = %#v, want nil default transport", client.Transport)
	}
	if client.Timeout != time.Second {
		t.Fatalf("disabled client timeout = %s, want 1s", client.Timeout)
	}
}

func TestNewHTTPTransportDisabledClonesBaseTransportWithoutTLS(t *testing.T) {
	t.Parallel()

	base := &http.Transport{MaxIdleConnsPerHost: 42}
	transport, err := NewHTTPTransport(Config{Mode: ModeDisabled}, base)
	if err != nil {
		t.Fatalf("NewHTTPTransport() error = %v", err)
	}

	if transport == base {
		t.Fatal("NewHTTPTransport() returned the provided base transport directly, want clone")
	}
	if transport.MaxIdleConnsPerHost != 42 {
		t.Fatalf("MaxIdleConnsPerHost = %d, want 42", transport.MaxIdleConnsPerHost)
	}
	if transport.TLSClientConfig != nil &&
		(transport.TLSClientConfig.RootCAs != nil ||
			transport.TLSClientConfig.ServerName != "" ||
			len(transport.TLSClientConfig.Certificates) != 0) {
		t.Fatalf("TLSClientConfig = %#v, want no custom mTLS material in disabled mode", transport.TLSClientConfig)
	}
}

func TestNewHTTPTransportEnabledConfiguresTLS(t *testing.T) {
	t.Parallel()

	certs := newTestCertificates(t)
	transport, err := NewHTTPTransport(Config{
		Mode:           ModeEnforce,
		CACertPath:     certs.caPath,
		ClientCertPath: certs.clientCertPath,
		ClientKeyPath:  certs.clientKeyPath,
		ServerName:     "search-service",
	}, nil)
	if err != nil {
		t.Fatalf("NewHTTPTransport() error = %v", err)
	}

	if transport.TLSClientConfig == nil {
		t.Fatal("TLSClientConfig = nil, want configured TLS client config")
	}
	if transport.TLSClientConfig.ServerName != "search-service" {
		t.Fatalf("ServerName = %q, want search-service", transport.TLSClientConfig.ServerName)
	}
	if len(transport.TLSClientConfig.Certificates) != 1 {
		t.Fatalf("client certificates = %d, want 1", len(transport.TLSClientConfig.Certificates))
	}
	if transport.TLSClientConfig.GetClientCertificate == nil {
		t.Fatal("GetClientCertificate = nil, want hot-reload callback")
	}
}

func TestGRPCDialOptionsUseTLSOnlyWhenEnabled(t *testing.T) {
	t.Parallel()

	disabled, err := GRPCDialOptions(Config{Mode: ModeDisabled})
	if err != nil {
		t.Fatalf("GRPCDialOptions(disabled) error = %v", err)
	}
	if len(disabled) != 1 {
		t.Fatalf("disabled dial options len = %d, want 1", len(disabled))
	}

	certs := newTestCertificates(t)
	enabled, err := GRPCDialOptions(Config{
		Mode:           ModeEnforce,
		CACertPath:     certs.caPath,
		ClientCertPath: certs.clientCertPath,
		ClientKeyPath:  certs.clientKeyPath,
		ServerName:     "search-service",
	})
	if err != nil {
		t.Fatalf("GRPCDialOptions(enforce) error = %v", err)
	}
	if len(enabled) != 1 {
		t.Fatalf("enabled dial options len = %d, want 1", len(enabled))
	}
}

func TestGRPCServerOptionsUseTLSOnlyWhenEnabled(t *testing.T) {
	t.Parallel()

	disabled, err := GRPCServerOptions(Config{Mode: ModeDisabled})
	if err != nil {
		t.Fatalf("GRPCServerOptions(disabled) error = %v", err)
	}
	if len(disabled) != 0 {
		t.Fatalf("disabled server options len = %d, want 0", len(disabled))
	}

	certs := newTestCertificates(t)
	enabled, err := GRPCServerOptions(Config{
		Mode:           ModeEnforce,
		CACertPath:     certs.caPath,
		ServerCertPath: certs.serverCertPath,
		ServerKeyPath:  certs.serverKeyPath,
	})
	if err != nil {
		t.Fatalf("GRPCServerOptions(enforce) error = %v", err)
	}
	if len(enabled) != 1 {
		t.Fatalf("enabled server options len = %d, want 1", len(enabled))
	}
}

func TestEnvConfigBuildsServerAndClientConfig(t *testing.T) {
	t.Parallel()

	env := EnvConfig{
		Mode:             "enforce",
		CACertPath:       "/ca.pem",
		ServerCertPath:   "/server.pem",
		ServerKeyPath:    "/server-key.pem",
		ClientCertPath:   "/client.pem",
		ClientKeyPath:    "/client-key.pem",
		AllowedSPIFFEIDs: "spiffe://inflap/test/activity-service, spiffe://inflap/test/user-service",
		AllowedDNSNames:  "activity-service,user-service",
		MinVersion:       "1.3",
		ServerName:       "",
	}

	server := env.ServerConfig()
	if server.Mode != ModeEnforce ||
		server.CACertPath != "/ca.pem" ||
		server.ServerCertPath != "/server.pem" ||
		server.MinVersion != "1.3" ||
		len(server.AllowedSPIFFEIDs) != 2 ||
		server.AllowedSPIFFEIDs[1] != "spiffe://inflap/test/user-service" ||
		len(server.AllowedDNSNames) != 2 {
		t.Fatalf("server config = %+v", server)
	}

	client := env.ClientConfig("search-service")
	if client.Mode != ModeEnforce ||
		client.CACertPath != "/ca.pem" ||
		client.ClientCertPath != "/client.pem" ||
		client.ClientKeyPath != "/client-key.pem" ||
		client.MinVersion != "1.3" ||
		client.ServerName != "search-service" {
		t.Fatalf("client config = %+v", client)
	}
}

func TestTLSMinVersionOnlyAllowsTLS13(t *testing.T) {
	t.Parallel()

	certs := newTestCertificates(t)
	_, err := Config{
		Mode:           ModeEnforce,
		MinVersion:     "1.2",
		CACertPath:     certs.caPath,
		ServerCertPath: certs.serverCertPath,
		ServerKeyPath:  certs.serverKeyPath,
	}.ServerTLSConfig()
	if err == nil {
		t.Fatal("ServerTLSConfig() error = nil, want TLS 1.2 rejection")
	}
}

func TestKeyPairReloaderReloadsChangedFiles(t *testing.T) {
	t.Parallel()

	dir := t.TempDir()
	caKey, caCert := newCertificateAuthority(t)
	firstCert, firstKey := newLeafCertificate(t, caCert, caKey, leafSpec{
		CommonName: "activity-service",
		URIs: []*url.URL{
			mustParseURL(t, "spiffe://inflap/test/activity-service"),
		},
	})
	certPath := writePEM(t, dir, "client.pem", "CERTIFICATE", firstCert.Raw)
	keyPath := writePrivateKey(t, dir, "client-key.pem", firstKey)

	reloader, err := newKeyPairReloader(certPath, keyPath)
	if err != nil {
		t.Fatalf("newKeyPairReloader() error = %v", err)
	}
	first, err := reloader.get()
	if err != nil {
		t.Fatalf("first get() error = %v", err)
	}

	secondCert, secondKey := newLeafCertificate(t, caCert, caKey, leafSpec{
		CommonName: "guide-service",
		URIs: []*url.URL{
			mustParseURL(t, "spiffe://inflap/test/guide-service"),
		},
	})
	_ = writePEM(t, dir, "client.pem", "CERTIFICATE", secondCert.Raw)
	_ = writePrivateKey(t, dir, "client-key.pem", secondKey)
	future := time.Now().Add(time.Second)
	if err := os.Chtimes(certPath, future, future); err != nil {
		t.Fatalf("touch cert: %v", err)
	}
	if err := os.Chtimes(keyPath, future, future); err != nil {
		t.Fatalf("touch key: %v", err)
	}

	second, err := reloader.get()
	if err != nil {
		t.Fatalf("second get() error = %v", err)
	}
	if bytes.Equal(first.Certificate[0], second.Certificate[0]) {
		t.Fatal("reloader returned the old certificate after files changed")
	}
}

func TestServerNameFromTarget(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name   string
		target string
		want   string
	}{
		{
			name:   "https URL with port",
			target: "https://search-service:8101",
			want:   "search-service",
		},
		{
			name:   "http URL with path",
			target: "http://token-service:8081/.well-known/jwks.json",
			want:   "token-service",
		},
		{
			name:   "grpc target with port",
			target: "user-service:9094",
			want:   "user-service",
		},
		{
			name:   "dns target without port",
			target: "file-manager-service",
			want:   "file-manager-service",
		},
		{
			name:   "empty target",
			target: "  ",
			want:   "",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			if got := ServerNameFromTarget(tt.target); got != tt.want {
				t.Fatalf("ServerNameFromTarget(%q) = %q, want %q", tt.target, got, tt.want)
			}
		})
	}
}

type testCertificates struct {
	caPath         string
	serverCertPath string
	serverKeyPath  string
	clientCertPath string
	clientKeyPath  string
}

func newTestCertificates(t *testing.T) testCertificates {
	t.Helper()

	dir := t.TempDir()
	caKey, caCert := newCertificateAuthority(t)
	serverCert, serverKey := newLeafCertificate(t, caCert, caKey, leafSpec{
		CommonName: "search-service",
		DNSNames:   []string{"search-service"},
		IPAddresses: []net.IP{
			net.ParseIP("127.0.0.1"),
		},
	})
	clientCert, clientKey := newLeafCertificate(t, caCert, caKey, leafSpec{
		CommonName: "activity-service",
		URIs: []*url.URL{
			mustParseURL(t, "spiffe://inflap/test/activity-service"),
		},
	})

	return testCertificates{
		caPath:         writePEM(t, dir, "ca.pem", "CERTIFICATE", caCert.Raw),
		serverCertPath: writePEM(t, dir, "server.pem", "CERTIFICATE", serverCert.Raw),
		serverKeyPath:  writePrivateKey(t, dir, "server-key.pem", serverKey),
		clientCertPath: writePEM(t, dir, "client.pem", "CERTIFICATE", clientCert.Raw),
		clientKeyPath:  writePrivateKey(t, dir, "client-key.pem", clientKey),
	}
}

func newCertificateAuthority(t *testing.T) (*rsa.PrivateKey, *x509.Certificate) {
	t.Helper()

	key, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatalf("generate CA key: %v", err)
	}
	template := &x509.Certificate{
		SerialNumber:          big.NewInt(1),
		Subject:               pkix.Name{CommonName: "Inflap Test CA"},
		NotBefore:             time.Now().Add(-time.Hour),
		NotAfter:              time.Now().Add(time.Hour),
		KeyUsage:              x509.KeyUsageCertSign | x509.KeyUsageCRLSign,
		BasicConstraintsValid: true,
		IsCA:                  true,
	}
	raw, err := x509.CreateCertificate(rand.Reader, template, template, &key.PublicKey, key)
	if err != nil {
		t.Fatalf("create CA certificate: %v", err)
	}
	cert, err := x509.ParseCertificate(raw)
	if err != nil {
		t.Fatalf("parse CA certificate: %v", err)
	}
	return key, cert
}

type leafSpec struct {
	CommonName  string
	DNSNames    []string
	IPAddresses []net.IP
	URIs        []*url.URL
}

func newLeafCertificate(t *testing.T, caCert *x509.Certificate, caKey *rsa.PrivateKey, spec leafSpec) (*x509.Certificate, *rsa.PrivateKey) {
	t.Helper()

	key, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatalf("generate leaf key: %v", err)
	}
	template := &x509.Certificate{
		SerialNumber: big.NewInt(time.Now().UnixNano()),
		Subject:      pkix.Name{CommonName: spec.CommonName},
		NotBefore:    time.Now().Add(-time.Hour),
		NotAfter:     time.Now().Add(time.Hour),
		KeyUsage:     x509.KeyUsageDigitalSignature,
		ExtKeyUsage: []x509.ExtKeyUsage{
			x509.ExtKeyUsageClientAuth,
			x509.ExtKeyUsageServerAuth,
		},
		DNSNames:    spec.DNSNames,
		IPAddresses: spec.IPAddresses,
		URIs:        spec.URIs,
	}
	raw, err := x509.CreateCertificate(rand.Reader, template, caCert, &key.PublicKey, caKey)
	if err != nil {
		t.Fatalf("create leaf certificate: %v", err)
	}
	cert, err := x509.ParseCertificate(raw)
	if err != nil {
		t.Fatalf("parse leaf certificate: %v", err)
	}
	return cert, key
}

func mustParseURL(t *testing.T, raw string) *url.URL {
	t.Helper()
	parsed, err := url.Parse(raw)
	if err != nil {
		t.Fatalf("parse URL %q: %v", raw, err)
	}
	return parsed
}

func writePEM(t *testing.T, dir string, name string, blockType string, der []byte) string {
	t.Helper()
	path := filepath.Join(dir, name)
	file, err := os.Create(path)
	if err != nil {
		t.Fatalf("create %s: %v", path, err)
	}
	if err := pem.Encode(file, &pem.Block{Type: blockType, Bytes: der}); err != nil {
		_ = file.Close()
		t.Fatalf("write PEM %s: %v", path, err)
	}
	if err := file.Close(); err != nil {
		t.Fatalf("close %s: %v", path, err)
	}
	return path
}

func writePrivateKey(t *testing.T, dir string, name string, key *rsa.PrivateKey) string {
	t.Helper()
	return writePEM(t, dir, name, "RSA PRIVATE KEY", x509.MarshalPKCS1PrivateKey(key))
}

func tlsHandshake(serverConfig *tls.Config, clientConfig *tls.Config) error {
	serverConn, clientConn := net.Pipe()
	defer serverConn.Close()
	defer clientConn.Close()
	_ = serverConn.SetDeadline(time.Now().Add(2 * time.Second))
	_ = clientConn.SetDeadline(time.Now().Add(2 * time.Second))

	serverTLS := tls.Server(serverConn, serverConfig)
	clientTLS := tls.Client(clientConn, clientConfig)

	errCh := make(chan error, 2)
	go func() { errCh <- serverTLS.Handshake() }()
	go func() { errCh <- clientTLS.Handshake() }()

	var firstErr error
	for i := 0; i < 2; i++ {
		if err := <-errCh; err != nil && firstErr == nil {
			firstErr = err
		}
	}
	return firstErr
}
