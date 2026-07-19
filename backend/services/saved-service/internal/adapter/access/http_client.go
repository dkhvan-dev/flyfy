package access

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/url"
	"strings"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/app/savedaccess"
)

const (
	savedUserAccessPath        = "/v1/internal/saved-user-access/check"
	defaultMaxResponseBytes    = int64(16 * 1024)
	internalServiceTokenHeader = "X-Internal-Service-Token"
	serviceNameHeader          = "X-Service-Name"
	serviceName                = "saved-service"
)

type Client struct {
	baseURL          string
	internalToken    string
	httpClient       *http.Client
	maxResponseBytes int64
}

type ClientConfig struct {
	BaseURL          string
	InternalToken    string
	HTTPClient       *http.Client
	MaxResponseBytes int64
}

type checkRequest struct {
	OwnerUserID   string   `json:"ownerUserId"`
	TargetUserIDs []string `json:"targetUserIds"`
}

type checkResponse struct {
	DeniedTargetUserIDs *[]string `json:"deniedTargetUserIds"`
}

func NewClient(config ClientConfig) (*Client, error) {
	parsed, err := url.ParseRequestURI(strings.TrimSpace(config.BaseURL))
	if err != nil || parsed == nil || !parsed.IsAbs() || parsed.Host == "" || parsed.User != nil ||
		parsed.RawQuery != "" || parsed.Fragment != "" || (parsed.Path != "" && parsed.Path != "/") ||
		(parsed.Scheme != "https" && parsed.Scheme != "http") ||
		config.BaseURL != strings.TrimSpace(config.BaseURL) ||
		config.InternalToken == "" || config.InternalToken != strings.TrimSpace(config.InternalToken) ||
		config.HTTPClient == nil {
		return nil, savedaccess.ErrPolicyUnavailable
	}
	maxResponseBytes := config.MaxResponseBytes
	if maxResponseBytes == 0 {
		maxResponseBytes = defaultMaxResponseBytes
	}
	if maxResponseBytes < 1 || maxResponseBytes > defaultMaxResponseBytes {
		return nil, savedaccess.ErrPolicyUnavailable
	}
	return &Client{
		baseURL:          strings.TrimSuffix(config.BaseURL, "/"),
		internalToken:    config.InternalToken,
		httpClient:       config.HTTPClient,
		maxResponseBytes: maxResponseBytes,
	}, nil
}

func (client *Client) DeniedUserIDs(
	ctx context.Context,
	ownerUserID uuid.UUID,
	targetUserIDs []uuid.UUID,
) (map[uuid.UUID]struct{}, error) {
	if client == nil || client.httpClient == nil || ctx == nil || ownerUserID == uuid.Nil ||
		len(targetUserIDs) == 0 || len(targetUserIDs) > savedaccess.MaxUserTargets {
		return nil, savedaccess.ErrPolicyUnavailable
	}
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	requested := make(map[uuid.UUID]struct{}, len(targetUserIDs))
	targets := make([]string, len(targetUserIDs))
	for index, targetUserID := range targetUserIDs {
		if targetUserID == uuid.Nil || targetUserID == ownerUserID {
			return nil, savedaccess.ErrPolicyUnavailable
		}
		if _, duplicate := requested[targetUserID]; duplicate {
			return nil, savedaccess.ErrPolicyUnavailable
		}
		requested[targetUserID] = struct{}{}
		targets[index] = targetUserID.String()
	}
	body, err := json.Marshal(checkRequest{
		OwnerUserID:   ownerUserID.String(),
		TargetUserIDs: targets,
	})
	if err != nil {
		return nil, savedaccess.ErrPolicyUnavailable
	}
	request, err := http.NewRequestWithContext(
		ctx,
		http.MethodPost,
		client.baseURL+savedUserAccessPath,
		bytes.NewReader(body),
	)
	if err != nil {
		return nil, savedaccess.ErrPolicyUnavailable
	}
	request.Header.Set("Content-Type", "application/json")
	request.Header.Set("Accept", "application/json")
	request.Header.Set(internalServiceTokenHeader, client.internalToken)
	request.Header.Set(serviceNameHeader, serviceName)

	response, err := client.httpClient.Do(request)
	if err != nil {
		if ctxErr := ctx.Err(); ctxErr != nil {
			return nil, ctxErr
		}
		return nil, savedaccess.ErrPolicyUnavailable
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK || response.Header.Get("Content-Type") == "" ||
		!strings.HasPrefix(strings.ToLower(response.Header.Get("Content-Type")), "application/json") {
		return nil, savedaccess.ErrPolicyUnavailable
	}

	limited := io.LimitReader(response.Body, client.maxResponseBytes+1)
	encoded, err := io.ReadAll(limited)
	if err != nil || int64(len(encoded)) > client.maxResponseBytes {
		return nil, savedaccess.ErrPolicyUnavailable
	}
	decoder := json.NewDecoder(bytes.NewReader(encoded))
	decoder.DisallowUnknownFields()
	var payload checkResponse
	if err := decoder.Decode(&payload); err != nil || payload.DeniedTargetUserIDs == nil {
		return nil, savedaccess.ErrPolicyUnavailable
	}
	if err := decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		return nil, savedaccess.ErrPolicyUnavailable
	}
	denied := make(map[uuid.UUID]struct{}, len(*payload.DeniedTargetUserIDs))
	for _, rawUserID := range *payload.DeniedTargetUserIDs {
		userID, err := uuid.Parse(rawUserID)
		if err != nil || userID == uuid.Nil || userID.String() != rawUserID {
			return nil, savedaccess.ErrPolicyUnavailable
		}
		if _, expected := requested[userID]; !expected {
			return nil, savedaccess.ErrPolicyUnavailable
		}
		if _, duplicate := denied[userID]; duplicate {
			return nil, savedaccess.ErrPolicyUnavailable
		}
		denied[userID] = struct{}{}
	}
	return denied, nil
}
