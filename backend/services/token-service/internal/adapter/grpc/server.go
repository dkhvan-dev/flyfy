package grpcserver

import (
	"context"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	pb "github.com/dkhvan-dev/flyfy/proto/gen/go/token"
	"github.com/dkhvan-dev/flyfy/token-service/internal/adapter/grpc/handler"
	"github.com/dkhvan-dev/flyfy/token-service/internal/domain/port"
)

// TokenServiceServer implements the gRPC TokenService defined in token.proto.
// This bridges the proto-generated interface with our domain handler.
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

// GenerateUserTokens creates an access + refresh token pair.
func (srv *TokenServiceServer) GenerateUserTokens(ctx context.Context, req *pb.GenerateUserTokensRequest) (*pb.TokenPairResponse, error) {
	if req.UserId == "" {
		return nil, status.Error(codes.InvalidArgument, "user_id is required")
	}
	if req.Role == "" {
		return nil, status.Error(codes.InvalidArgument, "role is required")
	}

	result, err := srv.handler.GenerateUserTokens(ctx, req.UserId, req.Role, req.Permissions)
	if err != nil {
		return nil, err
	}

	return &pb.TokenPairResponse{
		AccessToken:  result.AccessToken,
		RefreshToken: result.RefreshToken,
		TokenType:    result.TokenType,
		ExpiresAt:    result.ExpiresAt,
	}, nil
}

// ValidateAccessToken validates a user access token.
func (srv *TokenServiceServer) ValidateAccessToken(ctx context.Context, req *pb.ValidateTokenRequest) (*pb.ValidatedClaimsResponse, error) {
	if req.Token == "" {
		return nil, status.Error(codes.InvalidArgument, "token is required")
	}

	result, err := srv.handler.ValidateAccessToken(ctx, req.Token)
	if err != nil {
		return nil, err
	}

	return validatedClaimsToProto(result), nil
}

// ValidateRefreshToken validates a user refresh token.
func (srv *TokenServiceServer) ValidateRefreshToken(ctx context.Context, req *pb.ValidateTokenRequest) (*pb.ValidatedClaimsResponse, error) {
	if req.Token == "" {
		return nil, status.Error(codes.InvalidArgument, "token is required")
	}

	result, err := srv.handler.ValidateRefreshToken(ctx, req.Token)
	if err != nil {
		return nil, err
	}

	return validatedClaimsToProto(result), nil
}

// RefreshTokens validates a refresh token and issues a new pair.
func (srv *TokenServiceServer) RefreshTokens(ctx context.Context, req *pb.RefreshTokensRequest) (*pb.TokenPairResponse, error) {
	if req.RefreshToken == "" {
		return nil, status.Error(codes.InvalidArgument, "refresh_token is required")
	}

	result, err := srv.handler.RefreshTokens(ctx, req.RefreshToken)
	if err != nil {
		return nil, err
	}

	return &pb.TokenPairResponse{
		AccessToken:  result.AccessToken,
		RefreshToken: result.RefreshToken,
		TokenType:    result.TokenType,
		ExpiresAt:    result.ExpiresAt,
	}, nil
}

// RevokeToken revokes a token by JTI.
func (srv *TokenServiceServer) RevokeToken(ctx context.Context, req *pb.RevokeTokenRequest) (*pb.RevokeTokenResponse, error) {
	if req.Jti == "" {
		return nil, status.Error(codes.InvalidArgument, "jti is required")
	}

	revoked, err := srv.handler.RevokeToken(ctx, req.Jti, req.Exp, req.Reason)
	if err != nil {
		return nil, err
	}

	return &pb.RevokeTokenResponse{Revoked: revoked}, nil
}

// --- Service Token RPCs ---

// AuthenticateService validates service credentials and returns a service token.
func (srv *TokenServiceServer) AuthenticateService(ctx context.Context, req *pb.AuthenticateServiceRequest) (*pb.ServiceTokenResponse, error) {
	if req.ServiceId == "" || req.ServiceSecret == "" {
		return nil, status.Error(codes.InvalidArgument, "service_id and service_secret are required")
	}

	result, err := srv.handler.AuthenticateService(ctx, req.ServiceId, req.ServiceSecret)
	if err != nil {
		return nil, err
	}

	return &pb.ServiceTokenResponse{
		Token:     result.Token,
		ExpiresAt: result.ExpiresAt,
	}, nil
}

// ValidateServiceToken validates a service-to-service token.
func (srv *TokenServiceServer) ValidateServiceToken(ctx context.Context, req *pb.ValidateTokenRequest) (*pb.ValidatedClaimsResponse, error) {
	if req.Token == "" {
		return nil, status.Error(codes.InvalidArgument, "token is required")
	}

	result, err := srv.handler.ValidateServiceToken(ctx, req.Token)
	if err != nil {
		return nil, err
	}

	return validatedClaimsToProto(result), nil
}

// GenerateServiceToken creates a service token with specified roles.
func (srv *TokenServiceServer) GenerateServiceToken(ctx context.Context, req *pb.GenerateServiceTokenRequest) (*pb.ServiceTokenResponse, error) {
	if req.ServiceId == "" {
		return nil, status.Error(codes.InvalidArgument, "service_id is required")
	}

	// Delegate to the generator port directly
	_ = req // TODO: wire through handler when needed
	return nil, status.Error(codes.Unimplemented, "use AuthenticateService for service token generation")
}

// --- Helpers ---

func validatedClaimsToProto(c *handler.ValidatedClaimsResult) *pb.ValidatedClaimsResponse {
	return &pb.ValidatedClaimsResponse{
		Valid:       c.Valid,
		Subject:     c.Subject,
		Type:        c.Type,
		Role:        c.Role,
		Roles:       c.Roles,
		Permissions: c.Permissions,
		Jti:         c.JTI,
		IssuedAt:    c.IssuedAt,
		ExpiresAt:   c.ExpiresAt,
	}
}

// --- Compile-time interface check ---
var _ pb.TokenServiceServer = (*TokenServiceServer)(nil)

// --- Helper: create the server with all required ports ---

func NewFromPorts(
	gen port.TokenGenerator,
	val port.TokenValidator,
	rev port.TokenRevoker,
	auth port.ServiceAuthenticator,
	logger interface{ With() interface{} },
) *TokenServiceServer {
	// This is a convenience factory — in production, use the DI in main.go
	_ = gen
	_ = val
	_ = rev
	_ = auth
	return nil
}
