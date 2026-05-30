package antifraud

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

type Client struct {
	baseURL       string
	httpClient    *http.Client
	internalToken string
}

func NewClient(baseURL string, timeout time.Duration, internalToken string) *Client {
	baseURL = strings.TrimRight(strings.TrimSpace(baseURL), "/")
	if timeout <= 0 {
		timeout = 5 * time.Second
	}
	return &Client{
		baseURL: baseURL,
		httpClient: &http.Client{
			Timeout: timeout,
		},
		internalToken: strings.TrimSpace(internalToken),
	}
}

func (c *Client) ListFraudBlocks(ctx context.Context, target model.FraudBlockTarget, limit int, offset int) ([]model.FraudBlock, error) {
	values := url.Values{}
	values.Set("targetType", string(target))
	values.Set("limit", fmt.Sprintf("%d", limit))
	values.Set("offset", fmt.Sprintf("%d", offset))

	var resp fraudBlockListResponse
	if err := c.doJSON(ctx, http.MethodGet, "/v1/admin/fraud-blocks?"+values.Encode(), nil, nil, &resp); err != nil {
		return nil, err
	}
	items := make([]model.FraudBlock, 0, len(resp.Items))
	for _, item := range resp.Items {
		items = append(items, item.toModel())
	}
	return items, nil
}

func (c *Client) ReviewFraudBlock(ctx context.Context, input model.FraudBlockReviewInput) (*model.FraudBlock, error) {
	body := map[string]any{
		"status":            input.Status,
		"reviewedByStaffId": input.ReviewedByStaffID,
		"reasonCodes":       input.ReasonCodes,
		"comment":           input.Comment,
	}
	var resp fraudBlockResponse
	if err := c.doJSON(ctx, http.MethodPost, "/v1/admin/fraud-blocks/"+input.AssessmentID.String()+"/review", nil, body, &resp); err != nil {
		return nil, err
	}
	item := resp.toModel()
	return &item, nil
}

func (c *Client) doJSON(ctx context.Context, method string, path string, headers map[string]string, body any, dest any) error {
	var reader io.Reader
	if body != nil {
		payload, err := json.Marshal(body)
		if err != nil {
			return err
		}
		reader = bytes.NewReader(payload)
	}
	req, err := http.NewRequestWithContext(ctx, method, c.baseURL+path, reader)
	if err != nil {
		return err
	}
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	req.Header.Set("Accept", "application/json")
	if c.internalToken != "" {
		req.Header.Set("Authorization", "Bearer "+c.internalToken)
		req.Header.Set("X-Internal-Service", "admin-panel")
	}
	for key, value := range headers {
		if strings.TrimSpace(value) != "" {
			req.Header.Set(key, value)
		}
	}
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	raw, err := io.ReadAll(io.LimitReader(resp.Body, 4<<20))
	if err != nil {
		return err
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("anti-fraud-service %s %s returned %d: %s", method, path, resp.StatusCode, strings.TrimSpace(string(raw)))
	}
	if dest != nil {
		if err = json.Unmarshal(raw, dest); err != nil {
			return err
		}
	}
	return nil
}

type fraudBlockListResponse struct {
	Items []fraudBlockResponse `json:"items"`
}

type fraudBlockResponse struct {
	ID                uuid.UUID                    `json:"id"`
	EventID           uuid.UUID                    `json:"eventId"`
	Action            string                       `json:"action"`
	ActorUserID       *uuid.UUID                   `json:"actorUserId"`
	SubjectType       string                       `json:"subjectType"`
	SubjectID         *uuid.UUID                   `json:"subjectId"`
	Decision          string                       `json:"decision"`
	RiskScore         int                          `json:"riskScore"`
	Reasons           []string                     `json:"reasons"`
	PolicyVersion     string                       `json:"policyVersion"`
	ShadowMode        bool                         `json:"shadowMode"`
	ReviewStatus      model.FraudBlockReviewStatus `json:"reviewStatus"`
	ReviewedByStaffID *uuid.UUID                   `json:"reviewedByStaffId"`
	ReviewReasonCodes []string                     `json:"reviewReasonCodes"`
	ReviewComment     string                       `json:"reviewComment"`
	ReviewedAt        *time.Time                   `json:"reviewedAt"`
	UpdatedAt         time.Time                    `json:"updatedAt"`
	Metadata          map[string]any               `json:"metadata"`
	CreatedAt         time.Time                    `json:"createdAt"`
}

func (r fraudBlockResponse) toModel() model.FraudBlock {
	return model.FraudBlock{
		ID:                r.ID,
		EventID:           r.EventID,
		Action:            r.Action,
		ActorUserID:       r.ActorUserID,
		SubjectType:       r.SubjectType,
		SubjectID:         r.SubjectID,
		Decision:          r.Decision,
		RiskScore:         r.RiskScore,
		Reasons:           append([]string(nil), r.Reasons...),
		PolicyVersion:     r.PolicyVersion,
		ShadowMode:        r.ShadowMode,
		ReviewStatus:      r.ReviewStatus,
		ReviewedByStaffID: r.ReviewedByStaffID,
		ReviewReasonCodes: append([]string(nil), r.ReviewReasonCodes...),
		ReviewComment:     r.ReviewComment,
		ReviewedAt:        r.ReviewedAt,
		UpdatedAt:         r.UpdatedAt,
		Metadata:          r.Metadata,
		CreatedAt:         r.CreatedAt,
	}
}
