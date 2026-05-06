package grpcserver

import (
	"context"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/dkhvan-dev/flyfy/backend/services/token-service/internal/adapter/grpc/handler"
	"github.com/dkhvan-dev/flyfy/backend/services/token-service/internal/domain/model"
	pb "github.com/dkhvan-dev/flyfy/proto/gen/go/token"
)

// TokenServiceServer implements the gRPC TokenService defined in token.proto.
type TokenServiceServer struct {
	handler *handler.TokenGRPCHandler
	pb.UnimplementedTokenServiceServer
}

func NewTokenServiceServer(h *handler.TokenGRPCHandler) *TokenServiceServer {
	return &TokenServiceServer{handler: h}
}

// Register registers this server on the given gRPC server.
func (srv *TokenServiceServer) Register(s *grpc.Server) {
	pb.RegisterTokenServiceServer(s, srv)
}

// --- User Token RPCs ---

func (srv *TokenServiceServer) GenerateUserTokens(ctx context.Context, req *pb.GenerateUserTokensRequest) (*pb.TokenPairResponse, error) {
	if req.GetUserId() == "" {
		return nil, status.Error(codes.InvalidArgument, "user_id is required")
	}
	if req.GetRole() == "" {
		return nil, status.Error(codes.InvalidArgument, "role is required")
	}

	result, err := srv.handler.GenerateUserTokens(ctx, req.GetUserId(), req.GetRole(), req.GetPermissions(), deviceFromProto(req.GetDevice()))
	if err != nil {
		return nil, err
	}

	return &pb.TokenPairResponse{
		AccessToken:      result.AccessToken,
		RefreshToken:     result.RefreshToken,
		TokenType:        result.TokenType,
		ExpiresAt:        result.ExpiresAt,
		RefreshExpiresAt: result.RefreshExpiresAt,
		SessionId:        result.SessionID,
	}, nil
}

func (srv *TokenServiceServer) ValidateAccessToken(ctx context.Context, req *pb.ValidateTokenRequest) (*pb.ValidatedClaimsResponse, error) {
	if req.GetToken() == "" {
		return nil, status.Error(codes.InvalidArgument, "token is required")
	}
	result, err := srv.handler.ValidateAccessToken(ctx, req.GetToken())
	if err != nil {
		return nil, err
	}
	return validatedClaimsToProto(result), nil
}

func (srv *TokenServiceServer) ValidateRefreshToken(ctx context.Context, req *pb.ValidateTokenRequest) (*pb.ValidatedClaimsResponse, error) {
	if req.GetToken() == "" {
		return nil, status.Error(codes.InvalidArgument, "token is required")
	}
	result, err := srv.handler.ValidateRefreshToken(ctx, req.GetToken())
	if err != nil {
		return nil, err
	}
	return validatedClaimsToProto(result), nil
}

func (srv *TokenServiceServer) RefreshTokens(ctx context.Context, req *pb.RefreshTokensRequest) (*pb.TokenPairResponse, error) {
	if req.GetRefreshToken() == "" {
		return nil, status.Error(codes.InvalidArgument, "refresh_token is required")
	}
	result, err := srv.handler.RefreshTokens(ctx, req.GetRefreshToken(), deviceFromProto(req.GetDevice()))
	if err != nil {
		return nil, err
	}
	return &pb.TokenPairResponse{
		AccessToken:      result.AccessToken,
		RefreshToken:     result.RefreshToken,
		TokenType:        result.TokenType,
		ExpiresAt:        result.ExpiresAt,
		RefreshExpiresAt: result.RefreshExpiresAt,
		SessionId:        result.SessionID,
	}, nil
}

func (srv *TokenServiceServer) RevokeToken(ctx context.Context, req *pb.RevokeTokenRequest) (*pb.RevokeTokenResponse, error) {
	if req.GetJti() == "" {
		return nil, status.Error(codes.InvalidArgument, "jti is required")
	}
	revoked, err := srv.handler.RevokeToken(ctx, req.GetJti(), req.GetExp(), req.GetReason())
	if err != nil {
		return nil, err
	}
	return &pb.RevokeTokenResponse{Revoked: revoked}, nil
}

// --- Session RPCs ---

func (srv *TokenServiceServer) ListUserSessions(ctx context.Context, req *pb.ListUserSessionsRequest) (*pb.ListUserSessionsResponse, error) {
	if req.GetUserId() == "" {
		return nil, status.Error(codes.InvalidArgument, "user_id is required")
	}
	sessions, err := srv.handler.ListUserSessions(ctx, req.GetUserId())
	if err != nil {
		return nil, err
	}
	out := make([]*pb.UserSessionInfo, 0, len(sessions))
	for _, s := range sessions {
		out = append(out, sessionInfoToProto(s))
	}
	return &pb.ListUserSessionsResponse{Sessions: out}, nil
}

func (srv *TokenServiceServer) RevokeSession(ctx context.Context, req *pb.RevokeSessionRequest) (*pb.RevokeSessionResponse, error) {
	if req.GetSessionId() == "" {
		return nil, status.Error(codes.InvalidArgument, "session_id is required")
	}
	revoked, err := srv.handler.RevokeSession(ctx, req.GetSessionId(), req.GetReason())
	if err != nil {
		return nil, err
	}
	return &pb.RevokeSessionResponse{Revoked: revoked}, nil
}

func (srv *TokenServiceServer) RevokeAllUserSessions(ctx context.Context, req *pb.RevokeAllUserSessionsRequest) (*pb.RevokeAllUserSessionsResponse, error) {
	if req.GetUserId() == "" {
		return nil, status.Error(codes.InvalidArgument, "user_id is required")
	}
	count, err := srv.handler.RevokeAllUserSessions(ctx, req.GetUserId(), req.GetReason())
	if err != nil {
		return nil, err
	}
	return &pb.RevokeAllUserSessionsResponse{RevokedCount: count}, nil
}

// --- Service Token RPCs ---

func (srv *TokenServiceServer) AuthenticateService(ctx context.Context, req *pb.AuthenticateServiceRequest) (*pb.ServiceTokenResponse, error) {
	if req.GetServiceId() == "" || req.GetServiceSecret() == "" {
		return nil, status.Error(codes.InvalidArgument, "service_id and service_secret are required")
	}
	result, err := srv.handler.AuthenticateService(ctx, req.GetServiceId(), req.GetServiceSecret())
	if err != nil {
		return nil, err
	}
	return &pb.ServiceTokenResponse{
		Token:     result.Token,
		ExpiresAt: result.ExpiresAt,
	}, nil
}

func (srv *TokenServiceServer) ValidateServiceToken(ctx context.Context, req *pb.ValidateTokenRequest) (*pb.ValidatedClaimsResponse, error) {
	if req.GetToken() == "" {
		return nil, status.Error(codes.InvalidArgument, "token is required")
	}
	result, err := srv.handler.ValidateServiceToken(ctx, req.GetToken())
	if err != nil {
		return nil, err
	}
	return validatedClaimsToProto(result), nil
}

func (srv *TokenServiceServer) GenerateServiceToken(ctx context.Context, req *pb.GenerateServiceTokenRequest) (*pb.ServiceTokenResponse, error) {
	if req.GetServiceId() == "" {
		return nil, status.Error(codes.InvalidArgument, "service_id is required")
	}
	return nil, status.Error(codes.Unimplemented, "use AuthenticateService for service token generation")
}

// --- Helpers ---

func deviceFromProto(d *pb.DeviceInfo) model.DeviceInfo {
	if d == nil {
		return model.DeviceInfo{}
	}
	return model.DeviceInfo{
		DeviceID:   d.GetDeviceId(),
		Platform:   d.GetPlatform(),
		OSVersion:  d.GetOsVersion(),
		AppVersion: d.GetAppVersion(),
		Model:      d.GetModel(),
		UserAgent:  d.GetUserAgent(),
		IPAddress:  d.GetIpAddress(),
	}
}

func deviceToProto(d model.DeviceInfo) *pb.DeviceInfo {
	if d == (model.DeviceInfo{}) {
		return nil
	}
	return &pb.DeviceInfo{
		DeviceId:   d.DeviceID,
		Platform:   d.Platform,
		OsVersion:  d.OSVersion,
		AppVersion: d.AppVersion,
		Model:      d.Model,
		UserAgent:  d.UserAgent,
		IpAddress:  d.IPAddress,
	}
}

func validatedClaimsToProto(c *handler.ValidatedClaimsResult) *pb.ValidatedClaimsResponse {
	return &pb.ValidatedClaimsResponse{
		Valid:       c.Valid,
		Subject:     c.Subject,
		UserId:      c.UserID,
		Type:        c.Type,
		Role:        c.Role,
		Roles:       c.Roles,
		Permissions: c.Permissions,
		Jti:         c.JTI,
		SessionId:   c.SessionID,
		IssuedAt:    c.IssuedAt,
		ExpiresAt:   c.ExpiresAt,
	}
}

func sessionInfoToProto(s *handler.UserSessionResult) *pb.UserSessionInfo {
	return &pb.UserSessionInfo{
		SessionId:        s.SessionID,
		UserId:           s.UserID,
		Device:           deviceToProto(s.Device),
		CreatedAt:        s.CreatedAt,
		LastUsedAt:       s.LastUsedAt,
		LastRefreshedAt:  s.LastRefreshedAt,
		RefreshExpiresAt: s.RefreshExpiresAt,
	}
}

// --- Compile-time interface check ---
var _ pb.TokenServiceServer = (*TokenServiceServer)(nil)
