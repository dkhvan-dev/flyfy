package payment

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/port"
)

type Client struct {
	baseURL      *url.URL
	internalJWT  string
	httpClient   *http.Client
	requestLimit int64
}

func New(baseURL string, internalToken string, timeout time.Duration) (*Client, error) {
	parsed, err := url.Parse(strings.TrimRight(strings.TrimSpace(baseURL), "/"))
	if err != nil {
		return nil, fmt.Errorf("parse payment service url: %w", err)
	}
	if parsed.Scheme == "" || parsed.Host == "" {
		return nil, errors.New("payment service url must include scheme and host")
	}

	if timeout <= 0 {
		timeout = 5 * time.Second
	}

	return &Client{
		baseURL:     parsed,
		internalJWT: strings.TrimSpace(internalToken),
		httpClient: &http.Client{
			Timeout: timeout,
		},
		requestLimit: 1 << 20,
	}, nil
}

func (c *Client) Authorize(ctx context.Context, input port.PaymentCreateInput) (*port.PaymentTransaction, error) {
	return c.create(ctx, "/v1/payments/authorizations", input)
}

func (c *Client) Capture(ctx context.Context, input port.PaymentChildInput) (*port.PaymentTransaction, error) {
	return c.child(ctx, input.ParentTransactionID, "capture", input)
}

func (c *Client) Refund(ctx context.Context, input port.PaymentChildInput) (*port.PaymentTransaction, error) {
	return c.child(ctx, input.ParentTransactionID, "refund", input)
}

func (c *Client) Void(ctx context.Context, input port.PaymentChildInput) (*port.PaymentTransaction, error) {
	return c.child(ctx, input.ParentTransactionID, "void", input)
}

func (c *Client) create(ctx context.Context, path string, input port.PaymentCreateInput) (*port.PaymentTransaction, error) {
	reqBody := createPaymentRequest{
		IdempotencyKey: input.IdempotencyKey,
		SubjectType:    input.SubjectType,
		SubjectID:      input.SubjectID.String(),
		PayerUserID:    stringPtr(input.PayerUserID.String()),
		Purpose:        input.Purpose,
		AmountMinor:    input.AmountMinor,
		Currency:       input.Currency,
		Description:    input.Description,
		Metadata:       input.Metadata,
	}

	var resp paymentResponse
	if err := c.doJSON(ctx, http.MethodPost, path, reqBody, &resp); err != nil {
		return nil, err
	}
	return resp.toDomain()
}

func (c *Client) child(
	ctx context.Context,
	parentTransactionID uuid.UUID,
	action string,
	input port.PaymentChildInput,
) (*port.PaymentTransaction, error) {
	reqBody := childPaymentRequest{
		IdempotencyKey: input.IdempotencyKey,
		AmountMinor:    input.AmountMinor,
		Description:    input.Description,
		Metadata:       input.Metadata,
	}

	var resp paymentResponse
	path := fmt.Sprintf("/v1/payments/%s/%s", parentTransactionID, action)
	if err := c.doJSON(ctx, http.MethodPost, path, reqBody, &resp); err != nil {
		return nil, err
	}
	return resp.toDomain()
}

func (c *Client) doJSON(ctx context.Context, method string, path string, input any, output any) error {
	body, err := json.Marshal(input)
	if err != nil {
		return fmt.Errorf("marshal payment request: %w", err)
	}

	target := c.baseURL.ResolveReference(&url.URL{Path: path})
	req, err := http.NewRequestWithContext(ctx, method, target.String(), bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("create payment request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")
	if c.internalJWT != "" {
		req.Header.Set("Authorization", "Bearer "+c.internalJWT)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("call payment service: %w", err)
	}
	defer resp.Body.Close()

	limitedBody := io.LimitReader(resp.Body, c.requestLimit)
	if resp.StatusCode < http.StatusOK || resp.StatusCode >= http.StatusMultipleChoices {
		var errBody errorResponse
		_ = json.NewDecoder(limitedBody).Decode(&errBody)
		message := strings.TrimSpace(errBody.Error)
		if message == "" {
			message = resp.Status
		}
		return fmt.Errorf("payment service returned %d: %s", resp.StatusCode, message)
	}

	if err = json.NewDecoder(limitedBody).Decode(output); err != nil {
		return fmt.Errorf("decode payment response: %w", err)
	}
	return nil
}

type createPaymentRequest struct {
	IdempotencyKey string         `json:"idempotencyKey"`
	SubjectType    string         `json:"subjectType"`
	SubjectID      string         `json:"subjectId"`
	PayerUserID    *string        `json:"payerUserId,omitempty"`
	Purpose        string         `json:"purpose"`
	AmountMinor    int64          `json:"amountMinor"`
	Currency       string         `json:"currency"`
	Description    *string        `json:"description,omitempty"`
	Metadata       map[string]any `json:"metadata,omitempty"`
}

type childPaymentRequest struct {
	IdempotencyKey string         `json:"idempotencyKey"`
	AmountMinor    *int64         `json:"amountMinor,omitempty"`
	Description    *string        `json:"description,omitempty"`
	Metadata       map[string]any `json:"metadata,omitempty"`
}

type paymentResponse struct {
	ID            string `json:"id"`
	OperationType string `json:"operationType"`
	Status        string `json:"status"`
}

func (r paymentResponse) toDomain() (*port.PaymentTransaction, error) {
	id, err := uuid.Parse(strings.TrimSpace(r.ID))
	if err != nil {
		return nil, fmt.Errorf("parse payment transaction id: %w", err)
	}
	return &port.PaymentTransaction{
		ID:            id,
		OperationType: r.OperationType,
		Status:        r.Status,
	}, nil
}

type errorResponse struct {
	Error string `json:"error"`
}

func stringPtr(value string) *string {
	value = strings.TrimSpace(value)
	if value == "" {
		return nil
	}
	return &value
}
