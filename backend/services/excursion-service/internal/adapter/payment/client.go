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
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/excursion-service/internal/domain/port"
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

func (c *Client) Charge(ctx context.Context, input port.PaymentCreateInput) (*port.PaymentTransaction, error) {
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
	if err := c.doJSON(ctx, http.MethodPost, "/v1/payments/charges", reqBody, &resp); err != nil {
		return nil, err
	}
	return resp.toDomain()
}

func (c *Client) Refund(ctx context.Context, input port.PaymentChildInput) (*port.PaymentTransaction, error) {
	reqBody := childPaymentRequest{
		IdempotencyKey: input.IdempotencyKey,
		AmountMinor:    input.AmountMinor,
		Description:    input.Description,
		Metadata:       input.Metadata,
	}

	var resp paymentResponse
	path := fmt.Sprintf("/v1/payments/%s/refund", input.ParentTransactionID)
	if err := c.doJSON(ctx, http.MethodPost, path, reqBody, &resp); err != nil {
		return nil, err
	}
	return resp.toDomain()
}

func (c *Client) ListTransactions(ctx context.Context, filter port.PaymentTransactionFilter) ([]*port.PaymentTransaction, error) {
	query := url.Values{}
	if strings.TrimSpace(filter.SubjectType) != "" {
		query.Set("subjectType", strings.TrimSpace(filter.SubjectType))
	}
	if filter.SubjectID != nil && *filter.SubjectID != uuid.Nil {
		query.Set("subjectId", filter.SubjectID.String())
	}
	if filter.OperationType != nil && strings.TrimSpace(*filter.OperationType) != "" {
		query.Set("operationType", strings.TrimSpace(*filter.OperationType))
	}
	if filter.Status != nil && strings.TrimSpace(*filter.Status) != "" {
		query.Set("status", strings.TrimSpace(*filter.Status))
	}
	if filter.Limit > 0 {
		query.Set("limit", strconv.Itoa(filter.Limit))
	}
	if filter.Offset > 0 {
		query.Set("offset", strconv.Itoa(filter.Offset))
	}

	path := "/v1/payments"
	if encoded := query.Encode(); encoded != "" {
		path += "?" + encoded
	}

	var resp paymentListResponse
	if err := c.doJSON(ctx, http.MethodGet, path, nil, &resp); err != nil {
		return nil, err
	}
	items := make([]*port.PaymentTransaction, 0, len(resp.Items))
	for _, item := range resp.Items {
		tx, err := item.toDomain()
		if err != nil {
			return nil, err
		}
		items = append(items, tx)
	}
	return items, nil
}

func (c *Client) doJSON(ctx context.Context, method string, path string, input any, output any) error {
	var body io.Reader
	if input != nil {
		raw, err := json.Marshal(input)
		if err != nil {
			return fmt.Errorf("marshal payment request: %w", err)
		}
		body = bytes.NewReader(raw)
	}

	target := c.baseURL.ResolveReference(&url.URL{Path: path})
	if strings.Contains(path, "?") {
		parts := strings.SplitN(path, "?", 2)
		target = c.baseURL.ResolveReference(&url.URL{Path: parts[0], RawQuery: parts[1]})
	}
	req, err := http.NewRequestWithContext(ctx, method, target.String(), body)
	if err != nil {
		return fmt.Errorf("create payment request: %w", err)
	}
	req.Header.Set("Accept", "application/json")
	if input != nil {
		req.Header.Set("Content-Type", "application/json")
	}
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

	if output == nil {
		return nil
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
	AmountMinor   int64  `json:"amountMinor"`
}

type paymentListResponse struct {
	Items []paymentResponse `json:"items"`
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
		AmountMinor:   r.AmountMinor,
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
