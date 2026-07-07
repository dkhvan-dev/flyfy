package serviceauth

import (
	"bytes"
	"context"
	"crypto/rand"
	"crypto/rsa"
	"encoding/json"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"sync"
	"testing"
	"time"

	"github.com/go-jose/go-jose/v4"
	josejwt "github.com/go-jose/go-jose/v4/jwt"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/status"
	"google.golang.org/grpc/test/bufconn"
	"google.golang.org/protobuf/types/known/timestamppb"

	"kz/inflap/backend/pkg/transportauth"
	tokenpb "kz/inflap/proto/gen/go/token"
)

func TestJWTVerifierAcceptsServiceTokenWithRequiredRole(t *testing.T) {
	t.Parallel()

	issuer := "tourism-inflap/token-service"
	key, jwksClient, jwksURL := newTestJWKS(t)
	token := signTestToken(t, key, issuer, "activity-service", "service", "service", []string{"search:index"})

	verifier, err := NewJWTVerifier(VerifierConfig{
		Issuer:  issuer,
		JWKSURL: jwksURL,
		Client:  jwksClient,
	})
	if err != nil {
		t.Fatalf("NewJWTVerifier() error = %v", err)
	}

	claims, err := verifier.ValidateBearer(context.Background(), "Bearer "+token, []string{"search:index"})
	if err != nil {
		t.Fatalf("ValidateBearer() error = %v", err)
	}
	if claims.Subject != "activity-service" {
		t.Fatalf("subject = %q, want activity-service", claims.Subject)
	}
	if len(claims.Roles) != 1 || claims.Roles[0] != "search:index" {
		t.Fatalf("roles = %#v, want search:index", claims.Roles)
	}
}

func TestJWTVerifierRejectsServiceTokenWithoutRequiredRole(t *testing.T) {
	t.Parallel()

	issuer := "tourism-inflap/token-service"
	key, jwksClient, jwksURL := newTestJWKS(t)
	token := signTestToken(t, key, issuer, "activity-service", "service", "service", []string{"profile:read"})

	verifier, err := NewJWTVerifier(VerifierConfig{
		Issuer:  issuer,
		JWKSURL: jwksURL,
		Client:  jwksClient,
	})
	if err != nil {
		t.Fatalf("NewJWTVerifier() error = %v", err)
	}

	_, err = verifier.ValidateBearer(context.Background(), "Bearer "+token, []string{"search:index"})
	if err == nil {
		t.Fatal("ValidateBearer() error = nil, want missing role error")
	}
	if !IsUnauthorized(err) && !IsForbidden(err) {
		t.Fatalf("error = %v, want authz error", err)
	}
}

func TestJWTVerifierRejectsUserTokenForServiceAuth(t *testing.T) {
	t.Parallel()

	issuer := "tourism-inflap/token-service"
	key, jwksClient, jwksURL := newTestJWKS(t)
	token := signTestToken(t, key, issuer, "user-1", "user", "access", []string{"search:index"})

	verifier, err := NewJWTVerifier(VerifierConfig{
		Issuer:  issuer,
		JWKSURL: jwksURL,
		Client:  jwksClient,
	})
	if err != nil {
		t.Fatalf("NewJWTVerifier() error = %v", err)
	}

	_, err = verifier.ValidateBearer(context.Background(), "Bearer "+token, []string{"search:index"})
	if err == nil {
		t.Fatal("ValidateBearer() error = nil, want non-service token error")
	}
	if !IsForbidden(err) {
		t.Fatalf("error = %v, want forbidden", err)
	}
}

func TestBearerTransportInjectsServiceJWTAndDropsLegacyHeader(t *testing.T) {
	t.Parallel()

	var gotAuthorization string
	var gotLegacyToken string
	transport := NewBearerTransport(
		staticTokenSource("service-jwt"),
		roundTripFunc(func(r *http.Request) (*http.Response, error) {
			gotAuthorization = r.Header.Get("Authorization")
			gotLegacyToken = r.Header.Get(HeaderInternalServiceToken)
			return &http.Response{
				StatusCode: http.StatusAccepted,
				Body:       http.NoBody,
				Header:     make(http.Header),
			}, nil
		}),
	)

	req := httptest.NewRequest(http.MethodPost, "http://search-service/v1/search/index/events", nil)
	req.Header.Set(HeaderInternalServiceToken, "legacy-token")
	resp, err := transport.RoundTrip(req)
	if err != nil {
		t.Fatalf("RoundTrip() error = %v", err)
	}
	defer resp.Body.Close()

	if gotAuthorization != "Bearer service-jwt" {
		t.Fatalf("Authorization = %q, want bearer service jwt", gotAuthorization)
	}
	if gotLegacyToken != "" {
		t.Fatalf("%s = %q, want empty", HeaderInternalServiceToken, gotLegacyToken)
	}
}

func TestExtractBearerTokenAcceptsCaseInsensitiveScheme(t *testing.T) {
	t.Parallel()

	token, err := ExtractBearerToken("bearer service-jwt")
	if err != nil {
		t.Fatalf("ExtractBearerToken() error = %v", err)
	}
	if token != "service-jwt" {
		t.Fatalf("token = %q, want service-jwt", token)
	}
}

func TestGRPCServiceTokenSourceCachesTokenUntilExpiry(t *testing.T) {
	t.Parallel()

	tokenServer := &fakeTokenServiceServer{
		token:     "service-jwt",
		expiresAt: time.Now().Add(time.Hour),
	}
	listener := bufconn.Listen(1024 * 1024)
	grpcServer := grpc.NewServer()
	tokenpb.RegisterTokenServiceServer(grpcServer, tokenServer)
	go func() {
		if err := grpcServer.Serve(listener); err != nil {
			t.Errorf("serve token grpc: %v", err)
		}
	}()
	t.Cleanup(func() {
		grpcServer.Stop()
		_ = listener.Close()
	})

	source, err := NewGRPCServiceTokenSource(TokenSourceConfig{
		Target:        "passthrough:///bufnet",
		ServiceID:     "activity-service",
		ServiceSecret: "activity-secret",
		CallTimeout:   time.Second,
	}, grpc.WithContextDialer(func(ctx context.Context, _ string) (net.Conn, error) {
		return listener.DialContext(ctx)
	}), grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		t.Fatalf("NewGRPCServiceTokenSource() error = %v", err)
	}
	t.Cleanup(func() { _ = source.Close() })

	first, err := source.Token(context.Background())
	if err != nil {
		t.Fatalf("Token(first) error = %v", err)
	}
	second, err := source.Token(context.Background())
	if err != nil {
		t.Fatalf("Token(second) error = %v", err)
	}

	if first != "service-jwt" || second != "service-jwt" {
		t.Fatalf("tokens = %q/%q, want cached service-jwt", first, second)
	}
	if calls := tokenServer.authenticateCalls(); calls != 1 {
		t.Fatalf("AuthenticateService calls = %d, want 1", calls)
	}
}

func TestGRPCServiceTokenSourceFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := NewGRPCServiceTokenSource(TokenSourceConfig{
		Target:        "token-service:50051",
		ServiceID:     "activity-service",
		ServiceSecret: "activity-secret",
		TransportAuth: transportauth.Config{Mode: transportauth.ModeEnforce},
	})
	if err == nil {
		t.Fatal("NewGRPCServiceTokenSource() error = nil, want mTLS CA config error")
	}
}

type staticTokenSource string

func (s staticTokenSource) Token(context.Context) (string, error) {
	return string(s), nil
}

type fakeTokenServiceServer struct {
	tokenpb.UnimplementedTokenServiceServer

	mu        sync.Mutex
	calls     int
	token     string
	expiresAt time.Time
}

func (s *fakeTokenServiceServer) AuthenticateService(
	_ context.Context,
	req *tokenpb.AuthenticateServiceRequest,
) (*tokenpb.ServiceTokenResponse, error) {
	if req.GetServiceId() != "activity-service" || req.GetServiceSecret() != "activity-secret" {
		return nil, status.Error(codes.Unauthenticated, "unexpected credentials")
	}

	s.mu.Lock()
	s.calls++
	s.mu.Unlock()

	return &tokenpb.ServiceTokenResponse{
		Token:     s.token,
		ExpiresAt: timestamppb.New(s.expiresAt),
	}, nil
}

func (s *fakeTokenServiceServer) authenticateCalls() int {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.calls
}

func newTestJWKS(t *testing.T) (*rsa.PrivateKey, *http.Client, string) {
	t.Helper()

	key, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatalf("generate RSA key: %v", err)
	}
	jwks := jose.JSONWebKeySet{Keys: []jose.JSONWebKey{
		{
			Key:       key.Public(),
			KeyID:     "test-key",
			Algorithm: string(jose.RS256),
			Use:       "sig",
		},
	}}
	body, err := json.Marshal(jwks)
	if err != nil {
		t.Fatalf("encode JWKS: %v", err)
	}
	client := &http.Client{
		Transport: roundTripFunc(func(r *http.Request) (*http.Response, error) {
			if r.URL.String() != "https://token-service/.well-known/jwks.json" {
				t.Fatalf("JWKS URL = %q", r.URL.String())
			}
			return &http.Response{
				StatusCode: http.StatusOK,
				Body:       io.NopCloser(bytes.NewReader(body)),
				Header:     make(http.Header),
			}, nil
		}),
	}
	return key, client, "https://token-service/.well-known/jwks.json"
}

func signTestToken(
	t *testing.T,
	key *rsa.PrivateKey,
	issuer string,
	subject string,
	tokenType string,
	kind string,
	roles []string,
) string {
	t.Helper()

	opts := (&jose.SignerOptions{}).
		WithType("JWT").
		WithHeader("kid", "test-key")
	signer, err := jose.NewSigner(jose.SigningKey{Algorithm: jose.RS256, Key: key}, opts)
	if err != nil {
		t.Fatalf("new signer: %v", err)
	}

	now := time.Now()
	token, err := josejwt.Signed(signer).
		Claims(josejwt.Claims{
			Issuer:    issuer,
			Subject:   subject,
			IssuedAt:  josejwt.NewNumericDate(now),
			Expiry:    josejwt.NewNumericDate(now.Add(time.Hour)),
			NotBefore: josejwt.NewNumericDate(now.Add(-time.Second)),
			ID:        "jti-1",
		}).
		Claims(customClaims{
			Type:      tokenType,
			TokenKind: kind,
			Roles:     roles,
		}).
		Serialize()
	if err != nil {
		t.Fatalf("serialize token: %v", err)
	}
	return token
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(req *http.Request) (*http.Response, error) {
	return f(req)
}
