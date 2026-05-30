package provider

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"sync"
	"time"

	"kz/inflap/backend/services/notification-service/internal/domain/model"
)

type HMSConfig struct {
	Enabled      bool
	AppID        string
	ClientID     string
	ClientSecret string
	TokenURL     string
	SendURL      string
	Timeout      time.Duration
}

type HMSProvider struct {
	cfg    HMSConfig
	client *http.Client

	mu          sync.Mutex
	accessToken string
	expiresAt   time.Time
}

func NewHMSProvider(cfg HMSConfig) (*HMSProvider, error) {
	if !cfg.Enabled {
		return nil, model.ErrProviderDisabled
	}
	if strings.TrimSpace(cfg.AppID) == "" ||
		strings.TrimSpace(cfg.ClientID) == "" ||
		strings.TrimSpace(cfg.ClientSecret) == "" {
		return nil, fmt.Errorf("HMS_APP_ID, HMS_CLIENT_ID and HMS_CLIENT_SECRET are required when HMS is enabled")
	}
	if strings.TrimSpace(cfg.TokenURL) == "" {
		cfg.TokenURL = "https://oauth-login.cloud.huawei.com/oauth2/v3/token"
	}
	if strings.TrimSpace(cfg.SendURL) == "" {
		cfg.SendURL = fmt.Sprintf("https://push-api.cloud.huawei.com/v1/%s/messages:send", cfg.AppID)
	}
	if cfg.Timeout <= 0 {
		cfg.Timeout = 5 * time.Second
	}
	return &HMSProvider{cfg: cfg, client: &http.Client{Timeout: cfg.Timeout}}, nil
}

func (p *HMSProvider) Send(
	ctx context.Context,
	token string,
	delivery model.Delivery,
) (*model.ProviderSendResult, error) {
	accessToken, err := p.getAccessToken(ctx)
	if err != nil {
		return nil, err
	}
	payload := map[string]any{
		"validate_only": false,
		"message": map[string]any{
			"token": []string{token},
			"notification": map[string]string{
				"title": delivery.Payload.Title,
				"body":  delivery.Payload.Body,
			},
			"data": jsonString(delivery.Payload.Data),
			"android": map[string]any{
				"urgency": hmsUrgency(delivery.Priority),
				"ttl":     fmt.Sprintf("%ds", int(delivery.Payload.TTL.Seconds())),
			},
		},
	}
	body, err := json.Marshal(payload)
	if err != nil {
		return nil, fmt.Errorf("marshal hms request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, p.cfg.SendURL, bytes.NewReader(body))
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
			Code      string `json:"code"`
			Msg       string `json:"msg"`
			RequestID string `json:"requestId"`
		}
		_ = json.Unmarshal(respBody, &parsed)
		if parsed.Code != "" && parsed.Code != "80000000" {
			return mapHMSError(resp.StatusCode, parsed.Code, parsed.Msg, resp.Header.Get("Retry-After")), nil
		}
		return &model.ProviderSendResult{Status: model.ProviderSendSucceeded, ProviderMessageID: parsed.RequestID}, nil
	}
	return mapHMSError(resp.StatusCode, fmt.Sprintf("HTTP_%d", resp.StatusCode), string(respBody), resp.Header.Get("Retry-After")), nil
}

func (p *HMSProvider) getAccessToken(ctx context.Context) (string, error) {
	p.mu.Lock()
	if p.accessToken != "" && time.Now().Before(p.expiresAt.Add(-time.Minute)) {
		token := p.accessToken
		p.mu.Unlock()
		return token, nil
	}
	p.mu.Unlock()

	form := url.Values{}
	form.Set("grant_type", "client_credentials")
	form.Set("client_id", p.cfg.ClientID)
	form.Set("client_secret", p.cfg.ClientSecret)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, p.cfg.TokenURL, strings.NewReader(form.Encode()))
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
		return "", fmt.Errorf("hms oauth token request failed: status=%d body=%s", resp.StatusCode, string(body))
	}
	var tokenResp struct {
		AccessToken string `json:"access_token"`
		ExpiresIn   int    `json:"expires_in"`
	}
	if err = json.NewDecoder(resp.Body).Decode(&tokenResp); err != nil {
		return "", fmt.Errorf("decode hms oauth token: %w", err)
	}
	if tokenResp.AccessToken == "" {
		return "", fmt.Errorf("hms oauth token response is missing access_token")
	}

	p.mu.Lock()
	defer p.mu.Unlock()
	p.accessToken = tokenResp.AccessToken
	p.expiresAt = time.Now().Add(time.Duration(tokenResp.ExpiresIn) * time.Second)
	return p.accessToken, nil
}

func hmsUrgency(priority model.Priority) string {
	if priority == model.PriorityHigh {
		return "HIGH"
	}
	return "NORMAL"
}

func jsonString(value map[string]string) string {
	data, _ := json.Marshal(value)
	return string(data)
}

func mapHMSError(status int, code string, message string, retryAfterHeader string) *model.ProviderSendResult {
	if strings.Contains(message, "invalid token") || strings.Contains(message, "not exist") || strings.Contains(code, "80300007") {
		return &model.ProviderSendResult{Status: model.ProviderSendInvalidToken, ErrorCode: code, ErrorMessage: message}
	}
	if status == http.StatusTooManyRequests || status >= 500 {
		return &model.ProviderSendResult{
			Status:       model.ProviderSendRetryable,
			ErrorCode:    code,
			ErrorMessage: message,
			RetryAfter:   retryAfter(retryAfterHeader),
		}
	}
	return &model.ProviderSendResult{Status: model.ProviderSendTerminal, ErrorCode: code, ErrorMessage: message}
}
