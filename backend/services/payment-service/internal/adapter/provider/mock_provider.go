package provider

import (
	"context"
	"fmt"

	"github.com/dkhvan-dev/flyfy/backend/services/payment-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/payment-service/internal/domain/port"
)

type MockProvider struct{}

func NewMockProvider() *MockProvider {
	return &MockProvider{}
}

func (p *MockProvider) Authorize(ctx context.Context, input port.ProviderOperationInput) (*port.ProviderOperationResult, error) {
	return p.succeed("auth", input), nil
}

func (p *MockProvider) Charge(ctx context.Context, input port.ProviderOperationInput) (*port.ProviderOperationResult, error) {
	return p.succeed("charge", input), nil
}

func (p *MockProvider) Capture(ctx context.Context, input port.ProviderOperationInput) (*port.ProviderOperationResult, error) {
	return p.succeed("capture", input), nil
}

func (p *MockProvider) Refund(ctx context.Context, input port.ProviderOperationInput) (*port.ProviderOperationResult, error) {
	return p.succeed("refund", input), nil
}

func (p *MockProvider) Void(ctx context.Context, input port.ProviderOperationInput) (*port.ProviderOperationResult, error) {
	return p.succeed("void", input), nil
}

func (p *MockProvider) succeed(prefix string, input port.ProviderOperationInput) *port.ProviderOperationResult {
	return &port.ProviderOperationResult{
		Provider:              enum.PaymentProviderMock,
		ProviderTransactionID: fmt.Sprintf("mock_%s_%s", prefix, input.TransactionID.String()),
		Status:                enum.PaymentStatusSucceeded,
	}
}
