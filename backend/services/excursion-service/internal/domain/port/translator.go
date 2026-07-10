package port

import "context"

type TranslationRequest struct {
	SourceLocale    string
	TargetLocales   []string
	Texts           []string
	AllowIncomplete bool
}

type TranslationTextStatus string

const (
	TranslationTextTranslated          TranslationTextStatus = "translated"
	TranslationTextCached              TranslationTextStatus = "cached"
	TranslationTextSameLanguage        TranslationTextStatus = "same_language"
	TranslationTextQuotaExhausted      TranslationTextStatus = "quota_exhausted"
	TranslationTextDisabled            TranslationTextStatus = "disabled"
	TranslationTextProviderUnavailable TranslationTextStatus = "provider_unavailable"
)

type TranslationTextResult struct {
	Text     string
	Status   TranslationTextStatus
	Provider string
	CacheHit bool
}

type TranslationResult struct {
	Translations map[string][]string
	Items        map[string][]TranslationTextResult
	Provider     string
}

type ExcursionTranslator interface {
	TranslateTexts(ctx context.Context, input TranslationRequest) (TranslationResult, error)
}
