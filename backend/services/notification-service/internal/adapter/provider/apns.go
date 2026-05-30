package provider

import (
	"bytes"
	"context"
	"crypto/ecdsa"
	"crypto/rand"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"fmt"
	"io"
	"math/big"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/notification-service/internal/domain/model"
)

type APNSConfig struct {
	Enabled            bool
	DefaultEnvironment model.Environment
	TeamID             string
	KeyID              string
	BundleID           string
	AuthKeyPath        string
	Timeout            time.Duration
}

type APNSProvider struct {
	cfg    APNSConfig
	client *http.Client
	key    *ecdsa.PrivateKey

	mu        sync.Mutex
	authToken string
	issuedAt  time.Time
}

func NewAPNSProvider(cfg APNSConfig) (*APNSProvider, error) {
	if !cfg.Enabled {
		return nil, model.ErrProviderDisabled
	}
	if strings.TrimSpace(cfg.TeamID) == "" ||
		strings.TrimSpace(cfg.KeyID) == "" ||
		strings.TrimSpace(cfg.BundleID) == "" ||
		strings.TrimSpace(cfg.AuthKeyPath) == "" {
		return nil, fmt.Errorf("APNS_TEAM_ID, APNS_KEY_ID, APNS_BUNDLE_ID and APNS_AUTH_KEY_PATH are required when APNs is enabled")
	}
	data, err := os.ReadFile(cfg.AuthKeyPath)
	if err != nil {
		return nil, fmt.Errorf("read apns auth key: %w", err)
	}
	key, err := parseECDSAPrivateKey(data)
	if err != nil {
		return nil, err
	}
	if cfg.Timeout <= 0 {
		cfg.Timeout = 5 * time.Second
	}
	return &APNSProvider{
		cfg: cfg,
		client: &http.Client{
			Timeout: cfg.Timeout,
		},
		key: key,
	}, nil
}

func (p *APNSProvider) Send(
	ctx context.Context,
	token string,
	delivery model.Delivery,
) (*model.ProviderSendResult, error) {
	authToken, err := p.getAuthToken()
	if err != nil {
		return nil, err
	}

	payload := map[string]any{
		"aps": map[string]any{
			"alert": map[string]string{
				"title": delivery.Payload.Title,
				"body":  delivery.Payload.Body,
			},
			"sound": "default",
		},
	}
	for key, value := range delivery.Payload.Data {
		payload[key] = value
	}
	body, err := json.Marshal(payload)
	if err != nil {
		return nil, fmt.Errorf("marshal apns request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, p.endpoint(token, delivery.Environment), bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+authToken)
	req.Header.Set("apns-topic", p.cfg.BundleID)
	req.Header.Set("apns-push-type", "alert")
	req.Header.Set("apns-priority", apnsPriority(delivery.Priority))
	req.Header.Set("apns-id", delivery.ID.String())
	if delivery.Payload.CollapseKey != "" {
		req.Header.Set("apns-collapse-id", delivery.Payload.CollapseKey)
	}
	if delivery.Payload.TTL > 0 {
		req.Header.Set("apns-expiration", fmt.Sprintf("%d", time.Now().Add(delivery.Payload.TTL).Unix()))
	}

	resp, err := p.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	respBody, _ := io.ReadAll(io.LimitReader(resp.Body, 16*1024))
	if resp.StatusCode >= 200 && resp.StatusCode < 300 {
		messageID := resp.Header.Get("apns-id")
		if messageID == "" {
			messageID = uuid.NewString()
		}
		return &model.ProviderSendResult{
			Status:            model.ProviderSendSucceeded,
			ProviderMessageID: messageID,
		}, nil
	}
	return mapAPNSError(resp, respBody), nil
}

func (p *APNSProvider) endpoint(token string, environment model.Environment) string {
	if !environment.IsValid() {
		environment = p.cfg.DefaultEnvironment
	}
	host := "api.push.apple.com"
	if environment == model.EnvironmentSandbox {
		host = "api.sandbox.push.apple.com"
	}
	return fmt.Sprintf("https://%s/3/device/%s", host, token)
}

func (p *APNSProvider) getAuthToken() (string, error) {
	p.mu.Lock()
	defer p.mu.Unlock()
	if p.authToken != "" && time.Since(p.issuedAt) < 50*time.Minute {
		return p.authToken, nil
	}
	now := time.Now()
	header := map[string]string{
		"alg": "ES256",
		"kid": p.cfg.KeyID,
	}
	claims := map[string]any{
		"iss": p.cfg.TeamID,
		"iat": now.Unix(),
	}
	headerJSON, _ := json.Marshal(header)
	claimsJSON, _ := json.Marshal(claims)
	unsigned := base64.RawURLEncoding.EncodeToString(headerJSON) + "." + base64.RawURLEncoding.EncodeToString(claimsJSON)
	digest := sha256.Sum256([]byte(unsigned))
	r, s, err := ecdsa.Sign(rand.Reader, p.key, digest[:])
	if err != nil {
		return "", fmt.Errorf("sign apns provider token: %w", err)
	}
	signature := joseECDSASignature(r, s, 32)
	p.authToken = unsigned + "." + base64.RawURLEncoding.EncodeToString(signature)
	p.issuedAt = now
	return p.authToken, nil
}

func parseECDSAPrivateKey(data []byte) (*ecdsa.PrivateKey, error) {
	block, _ := pem.Decode(data)
	if block == nil {
		return nil, fmt.Errorf("decode apns auth key pem")
	}
	key, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		return nil, fmt.Errorf("parse apns auth key: %w", err)
	}
	ecdsaKey, ok := key.(*ecdsa.PrivateKey)
	if !ok {
		return nil, fmt.Errorf("apns auth key is not ECDSA")
	}
	return ecdsaKey, nil
}

func apnsPriority(priority model.Priority) string {
	if priority == model.PriorityHigh {
		return "10"
	}
	return "5"
}

func joseECDSASignature(r *big.Int, s *big.Int, size int) []byte {
	signature := make([]byte, size*2)
	rBytes := r.Bytes()
	sBytes := s.Bytes()
	copy(signature[size-len(rBytes):size], rBytes)
	copy(signature[(size*2)-len(sBytes):], sBytes)
	return signature
}

func mapAPNSError(resp *http.Response, body []byte) *model.ProviderSendResult {
	reason := string(body)
	code := fmt.Sprintf("HTTP_%d", resp.StatusCode)
	if strings.Contains(reason, "BadDeviceToken") || strings.Contains(reason, "Unregistered") {
		return &model.ProviderSendResult{Status: model.ProviderSendInvalidToken, ErrorCode: reason, ErrorMessage: reason}
	}
	if resp.StatusCode == http.StatusTooManyRequests || resp.StatusCode >= 500 {
		return &model.ProviderSendResult{
			Status:       model.ProviderSendRetryable,
			ErrorCode:    code,
			ErrorMessage: reason,
			RetryAfter:   retryAfter(resp.Header.Get("Retry-After")),
		}
	}
	return &model.ProviderSendResult{Status: model.ProviderSendTerminal, ErrorCode: code, ErrorMessage: reason}
}
