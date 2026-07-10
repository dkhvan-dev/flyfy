package app

import (
	"context"
	"crypto/rand"
	"fmt"
	"strings"
	"time"

	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/translation-service/internal/domain/model"
	"kz/inflap/backend/services/translation-service/internal/domain/port"
)

type Repository interface {
	GetCachedTranslation(ctx context.Context, key model.CacheKey) (model.CachedTranslation, bool, error)
	UpsertCachedTranslation(ctx context.Context, entry model.CachedTranslation) error
	ReserveMonthlyUsage(ctx context.Context, reservation model.UsageReservation) (model.UsageReservationResult, error)
	CommitMonthlyUsage(ctx context.Context, commit model.UsageCommit) error
	ReleaseMonthlyUsage(ctx context.Context, release model.UsageRelease) error
	CreateTranslationJob(ctx context.Context, job model.TranslationJob) (model.TranslationJob, bool, error)
	CompleteTranslationJob(ctx context.Context, completion model.TranslationJobCompletion) (model.TranslationJob, error)
	FailTranslationJob(ctx context.Context, failure model.TranslationJobFailure) (model.TranslationJob, error)
	GetTranslationJob(ctx context.Context, id string) (model.TranslationJob, bool, error)
	GetMonthlyUsage(ctx context.Context, provider string, environment string, yearMonth string) ([]model.MonthlyUsageRow, error)
}

type Config struct {
	Environment            string
	BillingMode            model.BillingMode
	MonthlyCharacterLimit  int
	QuotaWarningThreshold  float64
	QuotaCriticalThreshold float64
	GlossaryVersion        string
	Now                    func() time.Time
}

type TranslationUseCase struct {
	repo     Repository
	provider port.Provider
	cfg      Config
}

type TranslateInput struct {
	SourceLanguage             string
	TargetLanguages            []string
	Texts                      []string
	ContentType                string
	RequestID                  string
	DisableAtCriticalThreshold bool
}

type TranslateResult struct {
	SourceLanguage  model.Language
	TargetLanguages []model.Language
	Translations    map[model.Language][]model.TranslatedText
	Provider        string
}

type BatchInput struct {
	IdempotencyKey  string
	SourceLanguage  string
	TargetLanguages []string
	Texts           []string
	ContentType     string
	RequestID       string
}

type BatchResult struct {
	Job      model.TranslationJob
	Created  bool
	Provider string
}

type MonthlyUsageResult struct {
	Provider                string
	Environment             string
	YearMonth               string
	Rows                    []model.MonthlyUsageRow
	TotalReservedCharacters int
	TotalBilledCharacters   int
	TotalRequestCount       int
	MonthlyCharacterLimit   int
	QuotaWarningThreshold   float64
	QuotaCriticalThreshold  float64
	WarningReached          bool
	CriticalReached         bool
}

func NewTranslationUseCase(repo Repository, provider port.Provider, cfg Config) *TranslationUseCase {
	if cfg.BillingMode == "" {
		cfg.BillingMode = model.BillingModeFreeOnly
	}
	if cfg.Now == nil {
		cfg.Now = func() time.Time { return time.Now().UTC() }
	}
	if cfg.QuotaWarningThreshold <= 0 {
		cfg.QuotaWarningThreshold = 0.80
	}
	if cfg.QuotaCriticalThreshold <= 0 {
		cfg.QuotaCriticalThreshold = 0.95
	}
	cfg.Environment = strings.TrimSpace(cfg.Environment)
	if cfg.Environment == "" {
		cfg.Environment = "development"
	}
	return &TranslationUseCase{repo: repo, provider: provider, cfg: cfg}
}

func (u *TranslationUseCase) Translate(ctx context.Context, input TranslateInput) (TranslateResult, error) {
	sourceLanguage, ok := model.NormalizeLanguage(input.SourceLanguage)
	if !ok {
		return TranslateResult{}, fmt.Errorf("%w: source_language=%q", ErrInvalidLanguage, input.SourceLanguage)
	}
	targetLanguages, err := normalizeTargetLanguages(input.TargetLanguages)
	if err != nil {
		return TranslateResult{}, err
	}
	texts := normalizeTexts(input.Texts)
	if len(texts) == 0 || len(targetLanguages) == 0 {
		return TranslateResult{
			SourceLanguage:  sourceLanguage,
			TargetLanguages: targetLanguages,
			Translations:    map[model.Language][]model.TranslatedText{},
			Provider:        u.providerName(),
		}, nil
	}
	contentType, ok := model.NormalizeContentType(input.ContentType)
	if !ok {
		return TranslateResult{}, ErrContentNotTranslatable
	}

	result := TranslateResult{
		SourceLanguage:  sourceLanguage,
		TargetLanguages: targetLanguages,
		Translations:    make(map[model.Language][]model.TranslatedText, len(targetLanguages)),
		Provider:        u.providerName(),
	}
	for _, targetLanguage := range targetLanguages {
		result.Translations[targetLanguage] = make([]model.TranslatedText, len(texts))
	}

	if u.cfg.BillingMode == model.BillingModeDisabled {
		log.Info().
			Str("request_id", input.RequestID).
			Str("content_type", string(contentType)).
			Int("text_count", len(texts)).
			Msg("translation disabled by billing mode")
		for _, targetLanguage := range targetLanguages {
			fillOriginals(result.Translations[targetLanguage], texts, model.TranslationStatusDisabled, "")
		}
		return result, nil
	}

	for _, targetLanguage := range targetLanguages {
		if targetLanguage == sourceLanguage {
			fillOriginals(result.Translations[targetLanguage], texts, model.TranslationStatusSameLanguage, "")
			continue
		}
		if err := u.translateTarget(ctx, input.RequestID, contentType, sourceLanguage, targetLanguage, texts, result.Translations[targetLanguage], input.DisableAtCriticalThreshold); err != nil {
			return TranslateResult{}, err
		}
	}

	return result, nil
}

func (u *TranslationUseCase) CreateBatchJob(ctx context.Context, input BatchInput) (BatchResult, error) {
	idempotencyKey := strings.TrimSpace(input.IdempotencyKey)
	if idempotencyKey == "" {
		return BatchResult{}, ErrInvalidRequest
	}
	sourceLanguage, ok := model.NormalizeLanguage(input.SourceLanguage)
	if !ok {
		return BatchResult{}, fmt.Errorf("%w: source_language=%q", ErrInvalidLanguage, input.SourceLanguage)
	}
	targetLanguages, err := normalizeTargetLanguages(input.TargetLanguages)
	if err != nil {
		return BatchResult{}, err
	}
	texts := normalizeTexts(input.Texts)
	if len(texts) == 0 || len(targetLanguages) == 0 {
		return BatchResult{}, ErrInvalidRequest
	}
	contentType, ok := model.NormalizeContentType(input.ContentType)
	if !ok {
		return BatchResult{}, ErrContentNotTranslatable
	}
	jobID, err := newTranslationJobID()
	if err != nil {
		return BatchResult{}, fmt.Errorf("generate translation job id: %w", err)
	}
	now := u.cfg.Now()
	job, created, err := u.repo.CreateTranslationJob(ctx, model.TranslationJob{
		ID:              jobID,
		IdempotencyKey:  idempotencyKey,
		SourceLanguage:  sourceLanguage,
		TargetLanguages: targetLanguages,
		ContentType:     contentType,
		Texts:           texts,
		Status:          model.TranslationJobStatusProcessing,
		Result:          map[model.Language][]model.TranslatedText{},
		CreatedAt:       now,
		UpdatedAt:       now,
	})
	if err != nil {
		return BatchResult{}, fmt.Errorf("create translation job: %w", err)
	}
	if !created || job.Status == model.TranslationJobStatusCompleted || job.Status == model.TranslationJobStatusFailed {
		return BatchResult{Job: job, Created: created, Provider: u.providerName()}, nil
	}

	result, err := u.Translate(ctx, TranslateInput{
		SourceLanguage:  string(sourceLanguage),
		TargetLanguages: languagesToStrings(targetLanguages),
		Texts:           texts,
		ContentType:     string(contentType),
		RequestID:       input.RequestID,
		// Batch/admin backfills are intentionally non-critical at the 95% threshold.
		DisableAtCriticalThreshold: true,
	})
	if err != nil {
		failed, failErr := u.repo.FailTranslationJob(ctx, model.TranslationJobFailure{
			ID:           job.ID,
			ErrorCode:    "translation_failed",
			ErrorMessage: safeErrorMessage(err),
			FailedAt:     u.cfg.Now(),
		})
		if failErr != nil {
			return BatchResult{}, fmt.Errorf("fail translation job after translate error: %w", failErr)
		}
		return BatchResult{Job: failed, Created: created, Provider: u.providerName()}, nil
	}

	completed, err := u.repo.CompleteTranslationJob(ctx, model.TranslationJobCompletion{
		ID:          job.ID,
		Result:      result.Translations,
		CompletedAt: u.cfg.Now(),
	})
	if err != nil {
		return BatchResult{}, fmt.Errorf("complete translation job: %w", err)
	}
	return BatchResult{Job: completed, Created: created, Provider: result.Provider}, nil
}

func (u *TranslationUseCase) GetTranslationJob(ctx context.Context, id string) (model.TranslationJob, error) {
	job, ok, err := u.repo.GetTranslationJob(ctx, strings.TrimSpace(id))
	if err != nil {
		return model.TranslationJob{}, fmt.Errorf("get translation job: %w", err)
	}
	if !ok {
		return model.TranslationJob{}, ErrTranslationJobNotFound
	}
	return job, nil
}

func (u *TranslationUseCase) CurrentMonthUsage(ctx context.Context) (MonthlyUsageResult, error) {
	provider := u.providerName()
	yearMonth := model.YearMonth(u.cfg.Now())
	rows, err := u.repo.GetMonthlyUsage(ctx, provider, u.cfg.Environment, yearMonth)
	if err != nil {
		return MonthlyUsageResult{}, fmt.Errorf("get monthly translation usage: %w", err)
	}
	result := MonthlyUsageResult{
		Provider:               provider,
		Environment:            u.cfg.Environment,
		YearMonth:              yearMonth,
		Rows:                   rows,
		MonthlyCharacterLimit:  u.cfg.MonthlyCharacterLimit,
		QuotaWarningThreshold:  u.cfg.QuotaWarningThreshold,
		QuotaCriticalThreshold: u.cfg.QuotaCriticalThreshold,
	}
	for _, row := range rows {
		result.TotalReservedCharacters += row.ReservedCharacters
		result.TotalBilledCharacters += row.BilledCharacters
		result.TotalRequestCount += row.RequestCount
		result.WarningReached = result.WarningReached || row.WarningReached
		result.CriticalReached = result.CriticalReached || row.CriticalReached
	}
	return result, nil
}

func (u *TranslationUseCase) translateTarget(
	ctx context.Context,
	requestID string,
	contentType model.ContentType,
	sourceLanguage model.Language,
	targetLanguage model.Language,
	texts []string,
	output []model.TranslatedText,
	disableAtCriticalThreshold bool,
) error {
	missingIndexes := make([]int, 0, len(texts))
	missingTexts := make([]string, 0, len(texts))
	cacheHits := 0
	for index, text := range texts {
		if text == "" {
			output[index] = model.TranslatedText{Text: "", Status: model.TranslationStatusSameLanguage}
			continue
		}
		key := model.NewCacheKey(text, sourceLanguage, targetLanguage, u.providerName(), u.cfg.GlossaryVersion)
		cached, ok, err := u.repo.GetCachedTranslation(ctx, key)
		if err != nil {
			return fmt.Errorf("get cached translation: %w", err)
		}
		if ok {
			cacheHits++
			output[index] = model.TranslatedText{
				Text:     cached.TranslatedText,
				Status:   model.TranslationStatusCached,
				Provider: cached.Provider,
				CacheHit: true,
			}
			continue
		}
		missingIndexes = append(missingIndexes, index)
		missingTexts = append(missingTexts, text)
	}
	if len(missingIndexes) == 0 {
		log.Debug().
			Str("request_id", requestID).
			Str("provider", u.providerName()).
			Str("source_language", string(sourceLanguage)).
			Str("target_language", string(targetLanguage)).
			Str("content_type", string(contentType)).
			Int("cache_hits", cacheHits).
			Msg("translation served from cache")
		return nil
	}

	estimatedCharacters := model.CountBillableCharacters(missingTexts)
	now := u.cfg.Now()
	yearMonth := model.YearMonth(now)
	reservation, err := u.repo.ReserveMonthlyUsage(ctx, model.UsageReservation{
		Provider:               u.providerName(),
		Environment:            u.cfg.Environment,
		YearMonth:              yearMonth,
		SourceLanguage:         sourceLanguage,
		TargetLanguage:         targetLanguage,
		ContentType:            contentType,
		BillingMode:            u.cfg.BillingMode,
		Characters:             estimatedCharacters,
		MonthlyLimit:           u.cfg.MonthlyCharacterLimit,
		QuotaWarningThreshold:  u.cfg.QuotaWarningThreshold,
		QuotaCriticalThreshold: u.cfg.QuotaCriticalThreshold,
		ReservedAt:             now,
	})
	if err != nil {
		return fmt.Errorf("reserve monthly usage: %w", err)
	}
	if !reservation.Allowed {
		log.Warn().
			Str("request_id", requestID).
			Str("provider", u.providerName()).
			Str("environment", u.cfg.Environment).
			Str("year_month", yearMonth).
			Str("source_language", string(sourceLanguage)).
			Str("target_language", string(targetLanguage)).
			Str("content_type", string(contentType)).
			Int("characters", estimatedCharacters).
			Int("used_characters", reservation.UsedCharacters).
			Int("limit_characters", reservation.LimitCharacters).
			Int("remaining_characters", remainingCharacters(reservation)).
			Msg("translation quota exhausted before provider call")
		for _, index := range missingIndexes {
			output[index] = model.TranslatedText{Text: texts[index], Status: model.TranslationStatusQuotaExhausted}
		}
		return nil
	}
	if reservation.CriticalReached {
		log.Warn().
			Str("request_id", requestID).
			Str("provider", u.providerName()).
			Str("environment", u.cfg.Environment).
			Str("year_month", yearMonth).
			Int("used_characters", reservation.UsedCharacters).
			Int("limit_characters", reservation.LimitCharacters).
			Int("remaining_characters", remainingCharacters(reservation)).
			Msg("translation quota critical threshold reached")
	} else if reservation.WarningReached {
		log.Warn().
			Str("request_id", requestID).
			Str("provider", u.providerName()).
			Str("environment", u.cfg.Environment).
			Str("year_month", yearMonth).
			Int("used_characters", reservation.UsedCharacters).
			Int("limit_characters", reservation.LimitCharacters).
			Int("remaining_characters", remainingCharacters(reservation)).
			Msg("translation quota warning threshold reached")
	}
	if disableAtCriticalThreshold && reservation.CriticalReached {
		_ = u.repo.ReleaseMonthlyUsage(ctx, usageRelease(u.providerName(), u.cfg.Environment, yearMonth, sourceLanguage, targetLanguage, contentType, estimatedCharacters, now))
		log.Warn().
			Str("request_id", requestID).
			Str("provider", u.providerName()).
			Str("environment", u.cfg.Environment).
			Str("year_month", yearMonth).
			Str("source_language", string(sourceLanguage)).
			Str("target_language", string(targetLanguage)).
			Str("content_type", string(contentType)).
			Int("characters", estimatedCharacters).
			Int("used_characters", reservation.UsedCharacters).
			Int("limit_characters", reservation.LimitCharacters).
			Int("remaining_characters", remainingCharacters(reservation)).
			Msg("non-critical batch translation disabled at quota critical threshold")
		for _, index := range missingIndexes {
			output[index] = model.TranslatedText{Text: texts[index], Status: model.TranslationStatusQuotaExhausted}
		}
		return nil
	}

	if u.provider == nil {
		_ = u.repo.ReleaseMonthlyUsage(ctx, usageRelease(u.providerName(), u.cfg.Environment, yearMonth, sourceLanguage, targetLanguage, contentType, estimatedCharacters, now))
		for _, index := range missingIndexes {
			output[index] = model.TranslatedText{Text: texts[index], Status: model.TranslationStatusProviderUnavailable}
		}
		return nil
	}

	log.Debug().
		Str("request_id", requestID).
		Str("provider", u.providerName()).
		Str("source_language", string(sourceLanguage)).
		Str("target_language", string(targetLanguage)).
		Str("content_type", string(contentType)).
		Int("text_count", len(missingTexts)).
		Int("characters", estimatedCharacters).
		Msg("calling translation provider")
	providerStartedAt := time.Now()
	providerResult, err := u.provider.Translate(ctx, port.ProviderTranslateRequest{
		SourceLanguage:  sourceLanguage,
		TargetLanguages: []model.Language{targetLanguage},
		Texts:           missingTexts,
		RequestID:       requestID,
	})
	if err != nil {
		_ = u.repo.ReleaseMonthlyUsage(ctx, usageRelease(u.providerName(), u.cfg.Environment, yearMonth, sourceLanguage, targetLanguage, contentType, estimatedCharacters, now))
		log.Warn().
			Err(err).
			Str("request_id", requestID).
			Str("provider", u.providerName()).
			Str("source_language", string(sourceLanguage)).
			Str("target_language", string(targetLanguage)).
			Str("content_type", string(contentType)).
			Int("characters", estimatedCharacters).
			Dur("provider_latency", time.Since(providerStartedAt)).
			Msg("translation provider failed")
		for _, index := range missingIndexes {
			output[index] = model.TranslatedText{Text: texts[index], Status: model.TranslationStatusProviderUnavailable}
		}
		return nil
	}
	translatedTexts := providerResult.Translations[targetLanguage]
	if len(translatedTexts) != len(missingTexts) {
		_ = u.repo.ReleaseMonthlyUsage(ctx, usageRelease(u.providerName(), u.cfg.Environment, yearMonth, sourceLanguage, targetLanguage, contentType, estimatedCharacters, now))
		log.Warn().
			Str("request_id", requestID).
			Str("provider", u.providerName()).
			Str("source_language", string(sourceLanguage)).
			Str("target_language", string(targetLanguage)).
			Str("content_type", string(contentType)).
			Int("expected_text_count", len(missingTexts)).
			Int("actual_text_count", len(translatedTexts)).
			Msg("translation provider returned unexpected item count")
		for _, index := range missingIndexes {
			output[index] = model.TranslatedText{Text: texts[index], Status: model.TranslationStatusProviderUnavailable}
		}
		return nil
	}

	billedCharacters := providerResult.MeteredCharacters
	if billedCharacters <= 0 {
		billedCharacters = estimatedCharacters
	}
	if err := u.repo.CommitMonthlyUsage(ctx, model.UsageCommit{
		Provider:           u.providerName(),
		Environment:        u.cfg.Environment,
		YearMonth:          yearMonth,
		SourceLanguage:     sourceLanguage,
		TargetLanguage:     targetLanguage,
		ContentType:        contentType,
		ReservedCharacters: estimatedCharacters,
		BilledCharacters:   billedCharacters,
		RequestCount:       1,
		CommittedAt:        now,
	}); err != nil {
		return fmt.Errorf("commit monthly usage: %w", err)
	}
	log.Info().
		Str("request_id", requestID).
		Str("provider", u.providerName()).
		Str("environment", u.cfg.Environment).
		Str("year_month", yearMonth).
		Str("source_language", string(sourceLanguage)).
		Str("target_language", string(targetLanguage)).
		Str("content_type", string(contentType)).
		Int("reserved_characters", estimatedCharacters).
		Int("billed_characters", billedCharacters).
		Int("remaining_characters", remainingCharacters(reservation)).
		Int("cache_hits", cacheHits).
		Int("translated_count", len(translatedTexts)).
		Dur("provider_latency", time.Since(providerStartedAt)).
		Msg("translation provider call completed")

	for offset, index := range missingIndexes {
		translatedText := translatedTexts[offset]
		key := model.NewCacheKey(texts[index], sourceLanguage, targetLanguage, u.providerName(), u.cfg.GlossaryVersion)
		entry := model.CachedTranslation{
			Key:                  key,
			NormalizedSourceText: model.NormalizeSourceText(texts[index]),
			TranslatedText:       translatedText,
			Provider:             u.providerName(),
			ProviderModelLabel:   providerResult.ProviderModelLabel,
			QualityStatus:        model.QualityStatusMachine,
			CreatedAt:            now,
			UpdatedAt:            now,
		}
		if err := u.repo.UpsertCachedTranslation(ctx, entry); err != nil {
			return fmt.Errorf("upsert cached translation: %w", err)
		}
		output[index] = model.TranslatedText{
			Text:     translatedText,
			Status:   model.TranslationStatusTranslated,
			Provider: u.providerName(),
		}
	}
	return nil
}

func normalizeTargetLanguages(values []string) ([]model.Language, error) {
	seen := make(map[model.Language]struct{}, len(values))
	result := make([]model.Language, 0, len(values))
	for _, value := range values {
		language, ok := model.NormalizeLanguage(value)
		if !ok {
			return nil, fmt.Errorf("%w: target_language=%q", ErrInvalidLanguage, value)
		}
		if _, exists := seen[language]; exists {
			continue
		}
		seen[language] = struct{}{}
		result = append(result, language)
	}
	return result, nil
}

func normalizeTexts(values []string) []string {
	result := make([]string, 0, len(values))
	for _, value := range values {
		result = append(result, strings.TrimSpace(value))
	}
	return result
}

func languagesToStrings(values []model.Language) []string {
	result := make([]string, 0, len(values))
	for _, value := range values {
		result = append(result, string(value))
	}
	return result
}

func newTranslationJobID() (string, error) {
	var bytes [16]byte
	if _, err := rand.Read(bytes[:]); err != nil {
		return "", err
	}
	bytes[6] = (bytes[6] & 0x0f) | 0x40
	bytes[8] = (bytes[8] & 0x3f) | 0x80
	return fmt.Sprintf("%x-%x-%x-%x-%x", bytes[0:4], bytes[4:6], bytes[6:8], bytes[8:10], bytes[10:]), nil
}

func safeErrorMessage(err error) string {
	message := strings.TrimSpace(err.Error())
	if len(message) > 240 {
		message = message[:240]
	}
	return message
}

func remainingCharacters(reservation model.UsageReservationResult) int {
	if reservation.LimitCharacters <= 0 {
		return 0
	}
	remaining := reservation.LimitCharacters - reservation.UsedCharacters
	if remaining < 0 {
		return 0
	}
	return remaining
}

func fillOriginals(items []model.TranslatedText, texts []string, status model.TranslationStatus, provider string) {
	for index, text := range texts {
		items[index] = model.TranslatedText{Text: text, Status: status, Provider: provider}
	}
}

func (u *TranslationUseCase) providerName() string {
	if u.provider == nil || strings.TrimSpace(u.provider.Name()) == "" {
		return "none"
	}
	return strings.TrimSpace(u.provider.Name())
}

func usageRelease(
	provider string,
	environment string,
	yearMonth string,
	sourceLanguage model.Language,
	targetLanguage model.Language,
	contentType model.ContentType,
	characters int,
	now time.Time,
) model.UsageRelease {
	return model.UsageRelease{
		Provider:       provider,
		Environment:    environment,
		YearMonth:      yearMonth,
		SourceLanguage: sourceLanguage,
		TargetLanguage: targetLanguage,
		ContentType:    contentType,
		Characters:     characters,
		ReleasedAt:     now,
	}
}
