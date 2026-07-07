package http

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	nethttp "net/http"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/api-gateway/internal/config"
)

const userIDResolverCacheTTL = 10 * time.Minute

type userIDResolver interface {
	ResolveUserID(ctx context.Context, subject string, roles []string, requestID string) (string, error)
}

type userServiceUserIDResolver struct {
	cfg      *config.Config
	client   *nethttp.Client
	endpoint string
	cache    sync.Map
	now      func() time.Time
}

type cachedUserID struct {
	value     string
	expiresAt time.Time
}

func newUserServiceUserIDResolver(cfg *config.Config) (*userServiceUserIDResolver, error) {
	baseURL := strings.TrimRight(strings.TrimSpace(cfg.Downstreams.UserService), "/")
	if baseURL == "" {
		return nil, errors.New("user-service url is empty")
	}
	client, err := transportauth.NewHTTPClient(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(baseURL)),
		3*time.Second,
	)
	if err != nil {
		return nil, fmt.Errorf("initialize user-service mTLS client: %w", err)
	}
	return &userServiceUserIDResolver{
		cfg:      cfg,
		client:   client,
		endpoint: baseURL + "/v1/users/me/init",
		now:      time.Now,
	}, nil
}

func (r *userServiceUserIDResolver) ResolveUserID(
	ctx context.Context,
	subject string,
	roles []string,
	requestID string,
) (string, error) {
	subject = strings.TrimSpace(subject)
	if subject == "" {
		return "", errors.New("subject is empty")
	}
	if cached, ok := r.cache.Load(subject); ok {
		item, ok := cached.(cachedUserID)
		if ok && item.value != "" && r.now().Before(item.expiresAt) {
			return item.value, nil
		}
		r.cache.Delete(subject)
	}

	req, err := nethttp.NewRequestWithContext(ctx, nethttp.MethodPost, r.endpoint, nil)
	if err != nil {
		return "", fmt.Errorf("create user-service request: %w", err)
	}
	req.Header.Set(r.cfg.Security.TrustedHeaderSub, subject)
	if requestID = strings.TrimSpace(requestID); requestID != "" {
		req.Header.Set(r.cfg.Security.RequestIDHeader, requestID)
	}
	if len(roles) > 0 {
		req.Header.Set(r.cfg.Security.TrustedHeaderRoles, strings.Join(roles, ","))
	}

	resp, err := r.client.Do(req)
	if err != nil {
		return "", fmt.Errorf("call user-service: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 512))
		return "", fmt.Errorf("user-service returned status %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
	}

	var payload struct {
		User struct {
			ID string `json:"id"`
		} `json:"user"`
	}
	if err = json.NewDecoder(resp.Body).Decode(&payload); err != nil {
		return "", fmt.Errorf("decode user-service response: %w", err)
	}
	userID := strings.TrimSpace(payload.User.ID)
	if _, err = uuid.Parse(userID); err != nil {
		return "", fmt.Errorf("user-service returned invalid user id: %w", err)
	}

	r.cache.Store(subject, cachedUserID{
		value:     userID,
		expiresAt: r.now().Add(userIDResolverCacheTTL),
	})
	return userID, nil
}
