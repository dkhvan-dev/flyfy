package provider

import (
	"context"

	"kz/inflap/backend/services/notification-service/internal/domain/model"
)

type DisabledProvider struct {
	Name model.Provider
}

func (p DisabledProvider) Send(
	ctx context.Context,
	token string,
	delivery model.Delivery,
) (*model.ProviderSendResult, error) {
	return &model.ProviderSendResult{
		Status:       model.ProviderSendTerminal,
		ErrorCode:    "PROVIDER_DISABLED",
		ErrorMessage: string(p.Name) + " provider is disabled",
	}, nil
}
