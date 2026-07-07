package fraud

import (
	"bytes"
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/auth-service/internal/domain/port"
)

type HTTPClient struct {
	baseURL    string
	token      string
	hashKey    []byte
	httpClient *http.Client
}

type Option func(*HTTPClient)

func WithHTTPClient(httpClient *http.Client) Option {
	return func(c *HTTPClient) {
		if httpClient != nil {
			c.httpClient = httpClient
		}
	}
}

func NewHTTPClient(baseURL string, token string, signalHashKey string, timeout time.Duration, opts ...Option) (*HTTPClient, error) {
	parsed, err := url.Parse(strings.TrimRight(strings.TrimSpace(baseURL), "/"))
	if err != nil || parsed.Scheme == "" || parsed.Host == "" {
		return nil, fmt.Errorf("invalid anti-fraud base url")
	}
	if strings.TrimSpace(token) == "" {
		return nil, fmt.Errorf("anti-fraud internal token is required")
	}
	if strings.TrimSpace(signalHashKey) == "" {
		return nil, fmt.Errorf("anti-fraud signal hash key is required")
	}
	if timeout <= 0 {
		timeout = 800 * time.Millisecond
	}

	client := &HTTPClient{
		baseURL: parsed.String(),
		token:   strings.TrimSpace(token),
		hashKey: []byte(signalHashKey),
		httpClient: &http.Client{
			Timeout: timeout,
		},
	}
	for _, opt := range opts {
		if opt != nil {
			opt(client)
		}
	}

	return client, nil
}

func (c *HTTPClient) AssessAuth(ctx context.Context, input port.FraudAssessmentInput) (*port.FraudAssessmentResult, error) {
	signalHashes := map[string]string{}
	if input.Phone != "" {
		signalHashes["phone"] = c.hash("phone", input.Phone)
	}
	if input.Device.IPAddress != "" {
		signalHashes["ip"] = c.hash("ip", input.Device.IPAddress)
	}
	if input.Device.DeviceID != "" {
		signalHashes["device"] = c.hash("device", input.Device.DeviceID)
	}
	if input.ProviderID != "" {
		signalHashes["provider_subject"] = c.hash("provider_subject", input.ProviderID)
	}

	reqBody := assessActionRequest{
		Action:        input.Action,
		ActorUserID:   input.ActorUserID,
		SourceService: "auth-service",
		SignalHashes:  signalHashes,
		Metadata: map[string]any{
			"provider":   string(input.Provider),
			"platform":   input.Device.Platform,
			"osVersion":  input.Device.OSVersion,
			"appVersion": input.Device.AppVersion,
			"model":      input.Device.Model,
		},
	}
	for key, value := range input.Metadata {
		reqBody.Metadata[key] = value
	}

	body, err := json.Marshal(reqBody)
	if err != nil {
		return nil, fmt.Errorf("marshal anti-fraud request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+"/v1/risk/assessments", bytes.NewReader(body))
	if err != nil {
		return nil, fmt.Errorf("build anti-fraud request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+c.token)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("call anti-fraud service: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nil, fmt.Errorf("anti-fraud service returned status %d", resp.StatusCode)
	}

	var result assessActionResponse
	if err = json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("decode anti-fraud response: %w", err)
	}

	return &port.FraudAssessmentResult{
		Decision:   port.FraudDecision(result.Decision),
		RiskScore:  result.RiskScore,
		Reasons:    result.Reasons,
		ShadowMode: result.ShadowMode,
	}, nil
}

func (c *HTTPClient) hash(kind string, value string) string {
	mac := hmac.New(sha256.New, c.hashKey)
	mac.Write([]byte(kind))
	mac.Write([]byte{0})
	mac.Write([]byte(strings.ToLower(strings.TrimSpace(value))))
	return hex.EncodeToString(mac.Sum(nil))
}

type assessActionRequest struct {
	Action        string            `json:"action"`
	ActorUserID   *uuid.UUID        `json:"actorUserId,omitempty"`
	SourceService string            `json:"sourceService,omitempty"`
	SignalHashes  map[string]string `json:"signalHashes,omitempty"`
	Metadata      map[string]any    `json:"metadata,omitempty"`
}

type assessActionResponse struct {
	Decision   string   `json:"decision"`
	RiskScore  int      `json:"riskScore"`
	Reasons    []string `json:"reasons"`
	ShadowMode bool     `json:"shadowMode"`
}

var _ port.FraudEvaluator = (*HTTPClient)(nil)
