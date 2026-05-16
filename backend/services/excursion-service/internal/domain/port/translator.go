package port

import "context"

type TranslationRequest struct {
	SourceLocale  string
	TargetLocales []string
	Texts         []string
}

type TranslationResult struct {
	Translations map[string][]string
}

type ExcursionTranslator interface {
	TranslateTexts(ctx context.Context, input TranslationRequest) (TranslationResult, error)
}
