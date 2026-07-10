package port

import (
	"context"
	"errors"

	"kz/inflap/backend/services/translation-service/internal/domain/model"
)

var ErrProviderQuotaExceeded = errors.New("translation provider quota exceeded")

type Provider interface {
	Name() string
	Translate(ctx context.Context, input ProviderTranslateRequest) (ProviderTranslateResult, error)
}

type ProviderTranslateRequest struct {
	SourceLanguage  model.Language
	TargetLanguages []model.Language
	Texts           []string
	RequestID       string
}

type ProviderTranslateResult struct {
	Translations       map[model.Language][]string
	MeteredCharacters  int
	ProviderModelLabel string
}
