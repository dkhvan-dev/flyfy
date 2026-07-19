package grpc

import (
	"context"
	"errors"
	"reflect"
	"testing"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"

	"kz/inflap/backend/pkg/serviceauth"
	"kz/inflap/backend/services/guide-service/internal/config"
	contentv1 "kz/inflap/proto/gen/go/content/v1"
)

func TestSavedSourceInterceptorRequiresLeastPrivilegeRoleAndCaller(t *testing.T) {
	authorizer := &savedSourceAuthorizerStub{
		claims: &serviceauth.Claims{Subject: "saved-service", Roles: []string{savedSourceResolveRole}},
	}
	interceptor := UnaryServerInterceptor(&config.Config{
		Security: config.SecurityConfig{SavedSourceAllowedCaller: "saved-service"},
	}, authorizer)
	ctx := metadata.NewIncomingContext(
		context.Background(),
		metadata.Pairs("authorization", "Bearer signed-service-token"),
	)

	response, err := interceptor(
		ctx,
		"request",
		&grpc.UnaryServerInfo{FullMethod: contentv1.SavedSourceService_ResolveSaveEligibility_FullMethodName},
		func(handlerCtx context.Context, request any) (any, error) {
			if savedSourceCallerFromContext(handlerCtx) != "saved-service" {
				t.Fatalf("saved caller missing from authorized context")
			}
			return request, nil
		},
	)
	if err != nil {
		t.Fatalf("interceptor() error = %v", err)
	}
	if response != "request" {
		t.Fatalf("response = %v", response)
	}
	if authorizer.authHeader != "Bearer signed-service-token" {
		t.Fatalf("auth header = %q", authorizer.authHeader)
	}
	if !reflect.DeepEqual(authorizer.requiredRoles, []string{savedSourceResolveRole}) {
		t.Fatalf("required roles = %#v", authorizer.requiredRoles)
	}
}

func TestSavedSourceInterceptorFailsClosed(t *testing.T) {
	tests := []struct {
		name       string
		metadata   metadata.MD
		authorizer ServiceAuthorizer
		wantCode   codes.Code
	}{
		{
			name:       "missing token",
			metadata:   metadata.MD{},
			authorizer: &savedSourceAuthorizerStub{},
			wantCode:   codes.Unauthenticated,
		},
		{
			name: "duplicate token",
			metadata: metadata.MD{
				"authorization": []string{"Bearer one", "Bearer two"},
			},
			authorizer: &savedSourceAuthorizerStub{},
			wantCode:   codes.Unauthenticated,
		},
		{
			name:       "missing role",
			metadata:   metadata.Pairs("authorization", "Bearer token"),
			authorizer: &savedSourceAuthorizerStub{err: serviceauth.ErrForbiddenService},
			wantCode:   codes.PermissionDenied,
		},
		{
			name:       "wrong caller",
			metadata:   metadata.Pairs("authorization", "Bearer token"),
			authorizer: &savedSourceAuthorizerStub{claims: &serviceauth.Claims{Subject: "other-service"}},
			wantCode:   codes.PermissionDenied,
		},
		{
			name:       "verifier unavailable",
			metadata:   metadata.Pairs("authorization", "Bearer token"),
			authorizer: &savedSourceAuthorizerStub{err: errors.New("jwks unavailable")},
			wantCode:   codes.Unavailable,
		},
		{
			name:       "authorizer not configured",
			metadata:   metadata.Pairs("authorization", "Bearer token"),
			authorizer: nil,
			wantCode:   codes.Unavailable,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			interceptor := UnaryServerInterceptor(&config.Config{
				Security: config.SecurityConfig{SavedSourceAllowedCaller: "saved-service"},
			}, tt.authorizer)
			ctx := metadata.NewIncomingContext(context.Background(), tt.metadata)
			_, err := interceptor(
				ctx,
				nil,
				&grpc.UnaryServerInfo{FullMethod: contentv1.SavedSourceService_ResolveSaveEligibility_FullMethodName},
				func(context.Context, any) (any, error) {
					t.Fatal("handler must not run for rejected authentication")
					return nil, nil
				},
			)
			if status.Code(err) != tt.wantCode {
				t.Fatalf("interceptor() code = %s, want %s", status.Code(err), tt.wantCode)
			}
		})
	}
}

type savedSourceAuthorizerStub struct {
	claims        *serviceauth.Claims
	err           error
	authHeader    string
	requiredRoles []string
}

func (s *savedSourceAuthorizerStub) ValidateBearer(
	_ context.Context,
	authHeader string,
	requiredRoles []string,
) (*serviceauth.Claims, error) {
	s.authHeader = authHeader
	s.requiredRoles = append([]string(nil), requiredRoles...)
	return s.claims, s.err
}
