package serviceauth

import (
	"context"
	"fmt"
	"strings"
	"sync"
	"time"

	"google.golang.org/grpc"

	"kz/inflap/backend/pkg/transportauth"
	tokenpb "kz/inflap/proto/gen/go/token"
)

type TokenSourceConfig struct {
	Target        string
	ServiceID     string
	ServiceSecret string
	CallTimeout   time.Duration
	RefreshBefore time.Duration
	TransportAuth transportauth.Config
}

type GRPCServiceTokenSource struct {
	cfg     TokenSourceConfig
	conn    *grpc.ClientConn
	service tokenpb.TokenServiceClient

	mu        sync.Mutex
	token     string
	expiresAt time.Time
}

func NewGRPCServiceTokenSource(cfg TokenSourceConfig, opts ...grpc.DialOption) (*GRPCServiceTokenSource, error) {
	if strings.TrimSpace(cfg.Target) == "" {
		return nil, fmt.Errorf("token-service target is required")
	}
	if strings.TrimSpace(cfg.ServiceID) == "" {
		return nil, fmt.Errorf("token-service service id is required")
	}
	if strings.TrimSpace(cfg.ServiceSecret) == "" {
		return nil, fmt.Errorf("token-service service secret is required")
	}
	if cfg.CallTimeout <= 0 {
		cfg.CallTimeout = 3 * time.Second
	}
	if cfg.RefreshBefore <= 0 {
		cfg.RefreshBefore = 5 * time.Minute
	}
	if len(opts) == 0 {
		var err error
		opts, err = transportauth.GRPCDialOptions(cfg.TransportAuth)
		if err != nil {
			return nil, fmt.Errorf("configure token-service grpc transport: %w", err)
		}
	}

	conn, err := grpc.NewClient(strings.TrimSpace(cfg.Target), opts...)
	if err != nil {
		return nil, fmt.Errorf("create token-service grpc client: %w", err)
	}
	return &GRPCServiceTokenSource{
		cfg:     cfg,
		conn:    conn,
		service: tokenpb.NewTokenServiceClient(conn),
	}, nil
}

func (s *GRPCServiceTokenSource) Close() error {
	if s == nil || s.conn == nil {
		return nil
	}
	return s.conn.Close()
}

func (s *GRPCServiceTokenSource) Token(ctx context.Context) (string, error) {
	if s == nil {
		return "", fmt.Errorf("service token source is nil")
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	if token := strings.TrimSpace(s.token); token != "" && time.Now().Add(s.cfg.RefreshBefore).Before(s.expiresAt) {
		return token, nil
	}

	callCtx, cancel := context.WithTimeout(ctx, s.cfg.CallTimeout)
	defer cancel()

	resp, err := s.service.AuthenticateService(callCtx, &tokenpb.AuthenticateServiceRequest{
		ServiceId:     strings.TrimSpace(s.cfg.ServiceID),
		ServiceSecret: strings.TrimSpace(s.cfg.ServiceSecret),
	})
	if err != nil {
		return "", fmt.Errorf("authenticate service in token-service: %w", err)
	}

	token := strings.TrimSpace(resp.GetToken())
	if token == "" {
		return "", fmt.Errorf("token-service returned empty service token")
	}
	expiresAt := time.Now().Add(time.Hour)
	if resp.GetExpiresAt() != nil {
		expiresAt = resp.GetExpiresAt().AsTime()
	}
	s.token = token
	s.expiresAt = expiresAt
	return token, nil
}
