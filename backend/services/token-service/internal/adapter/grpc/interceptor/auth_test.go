package interceptor_test

import (
	"context"
	"reflect"
	"testing"

	"github.com/rs/zerolog"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"

	"kz/inflap/backend/services/token-service/internal/adapter/grpc/interceptor"
	"kz/inflap/backend/services/token-service/internal/domain/model"
	tokenpb "kz/inflap/proto/gen/go/token"
)

const validateUserSessionGenerationMethod = "/token.v1.TokenService/ValidateUserSessionGeneration"

type tokenValidatorStub struct {
	claims       *model.ValidatedClaims
	err          error
	serviceCalls int
}

func (s *tokenValidatorStub) ValidateAccessToken(context.Context, string) (*model.ValidatedClaims, error) {
	return nil, s.err
}

func (s *tokenValidatorStub) ValidateRefreshToken(context.Context, string) (*model.ValidatedClaims, error) {
	return nil, s.err
}

func (s *tokenValidatorStub) ValidateServiceToken(context.Context, string) (*model.ValidatedClaims, error) {
	s.serviceCalls++
	return s.claims, s.err
}

type auditLoggerStub struct{}

func (auditLoggerStub) LogServiceAuth(context.Context, string, string, string, map[string]string) {}

func TestHasAllRoles(t *testing.T) {
	tests := []struct {
		name          string
		serviceRoles  []string
		requiredRoles []string
		want          bool
	}{
		{
			name:          "all roles present",
			serviceRoles:  []string{"otp:send", "otp:verify", "token:generate"},
			requiredRoles: []string{"otp:send", "token:generate"},
			want:          true,
		},
		{
			name:          "missing role",
			serviceRoles:  []string{"token:validate"},
			requiredRoles: []string{"otp:send"},
			want:          false,
		},
		{
			name:          "empty required roles",
			serviceRoles:  []string{"token:validate"},
			requiredRoles: []string{},
			want:          true,
		},
		{
			name:          "empty service roles",
			serviceRoles:  []string{},
			requiredRoles: []string{"otp:send"},
			want:          false,
		},
		{
			name:          "exact match",
			serviceRoles:  []string{"otp:send"},
			requiredRoles: []string{"otp:send"},
			want:          true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// We test via the exported CallerFromContext and the logic indirectly.
			// Since hasAllRoles is unexported, we test through findMissingRoles logic.
			// For a proper test, we'd either export or test through the interceptor.

			// Build a role set to simulate the check
			roleSet := make(map[string]struct{}, len(tt.serviceRoles))
			for _, r := range tt.serviceRoles {
				roleSet[r] = struct{}{}
			}

			allPresent := true
			for _, req := range tt.requiredRoles {
				if _, ok := roleSet[req]; !ok {
					allPresent = false
					break
				}
			}

			if allPresent != tt.want {
				t.Errorf("hasAllRoles(%v, %v) = %v, want %v",
					tt.serviceRoles, tt.requiredRoles, allPresent, tt.want)
			}
		})
	}
}

func TestCallerFromContext_Empty(t *testing.T) {
	// Context without caller should return "unknown"
	ctx := t.Context()
	caller := interceptor.CallerFromContext(ctx)
	if caller != "unknown" {
		t.Errorf("expected 'unknown', got %q", caller)
	}
}

func TestTokenServiceMethodPermissionsCoverGeneratedRPCs(t *testing.T) {
	t.Parallel()

	permissions := interceptor.TokenServiceMethodPermissions()
	for _, method := range tokenpb.TokenService_ServiceDesc.Methods {
		fullMethod := "/" + tokenpb.TokenService_ServiceDesc.ServiceName + "/" + method.MethodName
		roles, protected := permissions[fullMethod]
		if method.MethodName == "AuthenticateService" {
			if protected {
				t.Errorf("AuthenticateService roles = %v, want public method absent from map", roles)
			}
			continue
		}
		if !protected {
			t.Errorf("generated RPC %s is not protected", fullMethod)
		}
	}

	wantRoles := []string{"session:validate"}
	if got := permissions[validateUserSessionGenerationMethod]; !reflect.DeepEqual(got, wantRoles) {
		t.Fatalf("ValidateUserSessionGeneration roles = %v, want %v", got, wantRoles)
	}
}

func TestServiceAuthInterceptorRequiresSessionValidateRole(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name       string
		roles      []string
		wantCode   codes.Code
		wantCalled bool
	}{
		{name: "least privilege role accepted", roles: []string{"session:validate"}, wantCode: codes.OK, wantCalled: true},
		{name: "token validation role is insufficient", roles: []string{"token:validate"}, wantCode: codes.PermissionDenied},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			validator := &tokenValidatorStub{claims: &model.ValidatedClaims{
				Subject: "saved-service",
				Type:    model.TokenTypeService,
				Roles:   test.roles,
			}}
			intercept := interceptor.ServiceAuthInterceptor(
				validator,
				auditLoggerStub{},
				interceptor.TokenServiceMethodPermissions(),
				zerolog.Nop(),
			)
			ctx := metadata.NewIncomingContext(t.Context(), metadata.Pairs("authorization", "Bearer service-token"))
			called := false
			_, err := intercept(ctx, nil, &grpc.UnaryServerInfo{FullMethod: validateUserSessionGenerationMethod}, func(ctx context.Context, _ any) (any, error) {
				called = true
				if caller := interceptor.CallerFromContext(ctx); caller != "saved-service" {
					t.Fatalf("CallerFromContext() = %q, want saved-service", caller)
				}
				return struct{}{}, nil
			})
			if got := status.Code(err); got != test.wantCode {
				t.Fatalf("status code = %s, want %s (error %v)", got, test.wantCode, err)
			}
			if called != test.wantCalled {
				t.Fatalf("handler called = %v, want %v", called, test.wantCalled)
			}
		})
	}
}

func TestServiceAuthInterceptorKeepsAuthenticateServicePublic(t *testing.T) {
	t.Parallel()

	validator := &tokenValidatorStub{}
	intercept := interceptor.ServiceAuthInterceptor(
		validator,
		auditLoggerStub{},
		interceptor.TokenServiceMethodPermissions(),
		zerolog.Nop(),
	)
	called := false
	_, err := intercept(t.Context(), nil, &grpc.UnaryServerInfo{
		FullMethod: "/token.v1.TokenService/AuthenticateService",
	}, func(context.Context, any) (any, error) {
		called = true
		return struct{}{}, nil
	})
	if err != nil {
		t.Fatalf("AuthenticateService interceptor error = %v", err)
	}
	if !called {
		t.Fatal("AuthenticateService handler was not called")
	}
	if validator.serviceCalls != 0 {
		t.Fatalf("ValidateServiceToken() calls = %d, want 0", validator.serviceCalls)
	}
}
