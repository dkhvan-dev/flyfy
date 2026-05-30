package provider

import (
	"bytes"
	"context"
	"crypto"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"

	"kz/inflap/backend/services/notification-service/internal/domain/model"
)

const fcmScope = "https://www.googleapis.com/auth/firebase.messaging"

type FCMConfig struct {
	Enabled                bool
	ProjectID              string
	ServiceAccountJSONPath string
	TokenURL               string
	Timeout                time.Duration
}

type FCMProvider struct {
	cfg     FCMConfig
	client  *http.Client
	account fcmServiceAccount

	mu          sync.Mutex
	accessToken string
	expiresAt   time.Time
}

type fcmServiceAccount struct {
	ProjectID    string `json:"project_id"`
	ClientEmail  string `json:"client_email"`
	PrivateKey   string `json:"private_key"`
	PrivateKeyID string `json:"private_key_id"`
	TokenURI     string `json:"token_uri"`
}

func NewFCMProvider(cfg FCMConfig) (*FCMProvider, error) {
	if !cfg.Enabled {
		return nil, model.ErrProviderDisabled
	}
	if strings.TrimSpace(cfg.ServiceAccountJSONPath) == "" {
		return nil, fmt.Errorf("FCM_SERVICE_ACCOUNT_JSON_PATH is required when FCM is enabled")
	}
	data, err := os.ReadFile(cfg.ServiceAccountJSONPath)
	if err != nil {
		return nil, fmt.Errorf("read fcm service account json: %w", err)
	}
	var account fcmServiceAccount
	if err = json.Unmarshal(data, &account); err != nil {
		return nil, fmt.Errorf("decode fcm service account json: %w", err)
	}
	if strings.TrimSpace(cfg.ProjectID) == "" {
		cfg.ProjectID = account.ProjectID
	}
	if strings.TrimSpace(cfg.ProjectID) == "" {
		return nil, fmt.Errorf("FCM_PROJECT_ID is required")
	}
	if strings.TrimSpace(cfg.TokenURL) == "" {
		cfg.TokenURL = account.TokenURI
	}
	if strings.TrimSpace(cfg.TokenURL) == "" {
		cfg.TokenURL = "https://oauth2.googleapis.com/token"
	}
	if cfg.Timeout <= 0 {
		cfg.Timeout = 5 * time.Second
	}
	return &FCMProvider{
		cfg:     cfg,
		client:  &http.Client{Timeout: cfg.Timeout},
		account: account,
	}, nil
}

func (p *FCMProvider) Send(
	ctx context.Context,
	token string,
	delivery model.Delivery,
) (*model.ProviderSendResult, error) {
	accessToken, err := p.getAccessToken(ctx)
	if err != nil {
		return nil, err
	}

	payload := map[string]any{
		"message": map[string]any{
			"token":        token,
			"notification": notificationObject(delivery.Payload),
			"data":         delivery.Payload.Data,
			"android": map[string]any{
				"priority":     fcmAndroidPriority(delivery.Priority),
				"ttl":          fmt.Sprintf("%ds", int(delivery.Payload.TTL.Seconds())),
				"collapse_key": delivery.Payload.CollapseKey,
			},
		},
	}
	body, err := json.Marshal(payload)
	if err != nil {
		return nil, fmt.Errorf("marshal fcm request: %w", err)
	}

	endpoint := fmt.Sprintf("https://fcm.googleapis.com/v1/projects/%s/messages:send", p.cfg.ProjectID)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+accessToken)
	req.Header.Set("Content-Type", "application/json")

	resp, err := p.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	respBody, _ := io.ReadAll(io.LimitReader(resp.Body, 16*1024))
	if resp.StatusCode >= 200 && resp.StatusCode < 300 {
		var parsed struct {
			Name string `json:"name"`
		}
		_ = json.Unmarshal(respBody, &parsed)
		return &model.ProviderSendResult{
			Status:            model.ProviderSendSucceeded,
			ProviderMessageID: parsed.Name,
		}, nil
	}
	return mapFCMError(resp, respBody), nil
}

func (p *FCMProvider) getAccessToken(ctx context.Context) (string, error) {
	p.mu.Lock()
	if p.accessToken != "" && time.Now().Before(p.expiresAt.Add(-time.Minute)) {
		token := p.accessToken
		p.mu.Unlock()
		return token, nil
	}
	p.mu.Unlock()

	assertion, err := p.signJWTAssertion()
	if err != nil {
		return "", err
	}

	form := "grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=" + assertion
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, p.cfg.TokenURL, strings.NewReader(form))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err := p.client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 16*1024))
		return "", fmt.Errorf("fcm oauth token request failed: status=%d body=%s", resp.StatusCode, string(body))
	}

	var tokenResp struct {
		AccessToken string `json:"access_token"`
		ExpiresIn   int    `json:"expires_in"`
	}
	if err = json.NewDecoder(resp.Body).Decode(&tokenResp); err != nil {
		return "", fmt.Errorf("decode fcm oauth token: %w", err)
	}
	if tokenResp.AccessToken == "" {
		return "", fmt.Errorf("fcm oauth token response is missing access_token")
	}

	p.mu.Lock()
	defer p.mu.Unlock()
	p.accessToken = tokenResp.AccessToken
	p.expiresAt = time.Now().Add(time.Duration(tokenResp.ExpiresIn) * time.Second)
	return p.accessToken, nil
}

func (p *FCMProvider) signJWTAssertion() (string, error) {
	now := time.Now()
	header := map[string]string{
		"alg": "RS256",
		"typ": "JWT",
		"kid": p.account.PrivateKeyID,
	}
	claims := map[string]any{
		"iss":   p.account.ClientEmail,
		"scope": fcmScope,
		"aud":   p.cfg.TokenURL,
		"iat":   now.Unix(),
		"exp":   now.Add(time.Hour).Unix(),
	}
	headerJSON, _ := json.Marshal(header)
	claimsJSON, _ := json.Marshal(claims)
	unsigned := base64.RawURLEncoding.EncodeToString(headerJSON) + "." + base64.RawURLEncoding.EncodeToString(claimsJSON)

	privateKey, err := parseRSAPrivateKey(p.account.PrivateKey)
	if err != nil {
		return "", err
	}
	digest := sha256.Sum256([]byte(unsigned))
	signature, err := rsa.SignPKCS1v15(rand.Reader, privateKey, crypto.SHA256, digest[:])
	if err != nil {
		return "", fmt.Errorf("sign fcm jwt assertion: %w", err)
	}
	return unsigned + "." + base64.RawURLEncoding.EncodeToString(signature), nil
}

func parseRSAPrivateKey(raw string) (*rsa.PrivateKey, error) {
	block, _ := pem.Decode([]byte(raw))
	if block == nil {
		return nil, fmt.Errorf("decode rsa private key pem")
	}
	parsed, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		return nil, fmt.Errorf("parse rsa private key: %w", err)
	}
	key, ok := parsed.(*rsa.PrivateKey)
	if !ok {
		return nil, fmt.Errorf("private key is not RSA")
	}
	return key, nil
}

func notificationObject(payload model.NotificationPayload) map[string]string {
	notification := map[string]string{}
	if payload.Title != "" {
		notification["title"] = payload.Title
	}
	if payload.Body != "" {
		notification["body"] = payload.Body
	}
	if payload.ImageURL != "" {
		notification["image"] = payload.ImageURL
	}
	return notification
}

func fcmAndroidPriority(priority model.Priority) string {
	if priority == model.PriorityHigh {
		return "HIGH"
	}
	return "NORMAL"
}

func mapFCMError(resp *http.Response, body []byte) *model.ProviderSendResult {
	code := fmt.Sprintf("HTTP_%d", resp.StatusCode)
	message := string(body)
	if resp.StatusCode == http.StatusNotFound || strings.Contains(message, "UNREGISTERED") {
		return &model.ProviderSendResult{Status: model.ProviderSendInvalidToken, ErrorCode: "UNREGISTERED", ErrorMessage: message}
	}
	if resp.StatusCode == http.StatusTooManyRequests || resp.StatusCode >= 500 {
		return &model.ProviderSendResult{
			Status:       model.ProviderSendRetryable,
			ErrorCode:    code,
			ErrorMessage: message,
			RetryAfter:   retryAfter(resp.Header.Get("Retry-After")),
		}
	}
	return &model.ProviderSendResult{Status: model.ProviderSendTerminal, ErrorCode: code, ErrorMessage: message}
}
