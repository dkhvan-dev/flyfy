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

	"kz/inflap/backend/services/file-manager-service/internal/domain/port"
)

type HTTPClient struct {
	baseURL    string
	token      string
	hashKey    []byte
	httpClient *http.Client
}

func NewHTTPClient(baseURL string, token string, signalHashKey string, timeout time.Duration) (*HTTPClient, error) {
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

	return &HTTPClient{
		baseURL: parsed.String(),
		token:   strings.TrimSpace(token),
		hashKey: []byte(signalHashKey),
		httpClient: &http.Client{
			Timeout: timeout,
		},
	}, nil
}

func (c *HTTPClient) AssessFile(ctx context.Context, input port.FraudAssessmentInput) (*port.FraudAssessmentResult, error) {
	signalHashes := map[string]string{}
	if input.ClientIP != "" {
		signalHashes["ip"] = c.hash("ip", input.ClientIP)
	}
	if input.DeviceID != "" {
		signalHashes["device"] = c.hash("device", input.DeviceID)
	}
	if input.UserAgent != "" {
		signalHashes["user_agent"] = c.hash("user_agent", input.UserAgent)
	}

	metadata := map[string]any{
		"purpose":     string(input.Purpose),
		"contentType": input.ContentType,
		"sizeBytes":   input.SizeBytes,
	}
	if input.OwnerType != nil {
		metadata["ownerType"] = string(*input.OwnerType)
	}
	for key, value := range input.Metadata {
		metadata[key] = value
	}

	reqBody := assessActionRequest{
		Action:        input.Action,
		ActorUserID:   input.ActorUserID,
		SubjectType:   "FILE",
		SubjectID:     input.FileID,
		SourceService: "file-manager-service",
		SignalHashes:  signalHashes,
		Metadata:      metadata,
	}
	if input.FileID == nil && input.OwnerID != nil {
		reqBody.SubjectType = "FILE_OWNER"
		reqBody.SubjectID = input.OwnerID
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
	SubjectType   string            `json:"subjectType,omitempty"`
	SubjectID     *uuid.UUID        `json:"subjectId,omitempty"`
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
