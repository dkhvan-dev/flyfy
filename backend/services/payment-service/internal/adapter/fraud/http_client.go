package fraud

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"time"

	"kz/inflap/backend/services/payment-service/internal/domain/port"
)

type HTTPClient struct {
	baseURL    string
	token      string
	httpClient *http.Client
}

func NewHTTPClient(baseURL string, token string, timeout time.Duration) (*HTTPClient, error) {
	parsed, err := url.Parse(strings.TrimRight(strings.TrimSpace(baseURL), "/"))
	if err != nil || parsed.Scheme == "" || parsed.Host == "" {
		return nil, fmt.Errorf("invalid anti-fraud base url")
	}
	if strings.TrimSpace(token) == "" {
		return nil, fmt.Errorf("anti-fraud internal token is required")
	}
	if timeout <= 0 {
		timeout = 800 * time.Millisecond
	}

	return &HTTPClient{
		baseURL: parsed.String(),
		token:   strings.TrimSpace(token),
		httpClient: &http.Client{
			Timeout: timeout,
		},
	}, nil
}

func (c *HTTPClient) AssessPayment(ctx context.Context, input port.FraudAssessmentInput) (*port.FraudAssessmentResult, error) {
	metadata := map[string]any{}
	if len(input.Metadata) > 0 {
		_ = json.Unmarshal(input.Metadata, &metadata)
	}
	metadata["purpose"] = input.Purpose
	metadata["operationType"] = string(input.OperationType)

	reqBody := assessActionRequest{
		Action:         input.Action,
		ActorUserID:    &input.ActorUserID,
		SubjectType:    input.SubjectType,
		SubjectID:      &input.SubjectID,
		SourceService:  "payment-service",
		IdempotencyKey: input.IdempotencyKey,
		AmountMinor:    &input.AmountMinor,
		Currency:       input.Currency,
		Metadata:       metadata,
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

type assessActionRequest struct {
	Action         string         `json:"action"`
	ActorUserID    any            `json:"actorUserId,omitempty"`
	SubjectType    string         `json:"subjectType,omitempty"`
	SubjectID      any            `json:"subjectId,omitempty"`
	SourceService  string         `json:"sourceService,omitempty"`
	IdempotencyKey string         `json:"idempotencyKey,omitempty"`
	AmountMinor    *int64         `json:"amountMinor,omitempty"`
	Currency       string         `json:"currency,omitempty"`
	Metadata       map[string]any `json:"metadata,omitempty"`
}

type assessActionResponse struct {
	Decision   string   `json:"decision"`
	RiskScore  int      `json:"riskScore"`
	Reasons    []string `json:"reasons"`
	ShadowMode bool     `json:"shadowMode"`
}

var _ port.FraudDecisionPort = (*HTTPClient)(nil)
