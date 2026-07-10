package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"kz/inflap/backend/services/translation-service/internal/domain/model"
	"kz/inflap/backend/services/translation-service/internal/domain/port"
)

func TestTranslateReturnsCachedTextWithoutCallingProvider(t *testing.T) {
	repo := newMemoryRepository(time.Date(2026, 7, 9, 0, 0, 0, 0, time.UTC))
	provider := &providerStub{name: "azure_translator"}
	uc := NewTranslationUseCase(repo, provider, Config{
		BillingMode:            model.BillingModeFreeOnly,
		MonthlyCharacterLimit:  2_000_000,
		QuotaWarningThreshold:  0.80,
		QuotaCriticalThreshold: 0.95,
		Now:                    repo.now,
	})
	key := model.NewCacheKey("hello", model.LanguageEnglish, model.LanguageRussian, provider.name, "")
	repo.cache[key.String()] = model.CachedTranslation{
		Key:                  key,
		NormalizedSourceText: "hello",
		TranslatedText:       "привет",
		Provider:             provider.name,
		QualityStatus:        model.QualityStatusMachine,
		CreatedAt:            repo.now(),
		UpdatedAt:            repo.now(),
	}

	result, err := uc.Translate(context.Background(), TranslateInput{
		SourceLanguage:  "en",
		TargetLanguages: []string{"ru"},
		Texts:           []string{"hello"},
		ContentType:     string(model.ContentTypeExcursion),
	})

	if err != nil {
		t.Fatalf("Translate() error = %v", err)
	}
	if provider.calls != 0 {
		t.Fatalf("provider calls = %d, want 0", provider.calls)
	}
	item := result.Translations[model.LanguageRussian][0]
	if item.Text != "привет" || item.Status != model.TranslationStatusCached || !item.CacheHit {
		t.Fatalf("cached item = %#v, want cached translation", item)
	}
}

func TestTranslateHardStopsBeforeProviderWhenFreeQuotaIsExhausted(t *testing.T) {
	repo := newMemoryRepository(time.Date(2026, 7, 9, 0, 0, 0, 0, time.UTC))
	repo.usedCharacters = 10
	provider := &providerStub{name: "azure_translator"}
	uc := NewTranslationUseCase(repo, provider, Config{
		BillingMode:           model.BillingModeFreeOnly,
		MonthlyCharacterLimit: 10,
		Now:                   repo.now,
	})

	result, err := uc.Translate(context.Background(), TranslateInput{
		SourceLanguage:  "ru",
		TargetLanguages: []string{"en"},
		Texts:           []string{"Старт"},
		ContentType:     string(model.ContentTypeExcursion),
	})

	if err != nil {
		t.Fatalf("Translate() error = %v", err)
	}
	if provider.calls != 0 {
		t.Fatalf("provider calls = %d, want 0", provider.calls)
	}
	item := result.Translations[model.LanguageEnglish][0]
	if item.Text != "Старт" || item.Status != model.TranslationStatusQuotaExhausted {
		t.Fatalf("quota exhausted item = %#v, want original text with quota_exhausted", item)
	}
}

func TestTranslateCacheMissCallsProviderCommitsUsageAndCaches(t *testing.T) {
	repo := newMemoryRepository(time.Date(2026, 7, 9, 0, 0, 0, 0, time.UTC))
	provider := &providerStub{
		name: "azure_translator",
		translations: map[model.Language][]string{
			model.LanguageRussian: {"привет"},
		},
		metered: 8,
	}
	uc := NewTranslationUseCase(repo, provider, Config{
		BillingMode:           model.BillingModeFreeOnly,
		MonthlyCharacterLimit: 2_000_000,
		Now:                   repo.now,
	})

	result, err := uc.Translate(context.Background(), TranslateInput{
		SourceLanguage:  "en",
		TargetLanguages: []string{"ru"},
		Texts:           []string{"hello"},
		ContentType:     string(model.ContentTypeExcursion),
	})

	if err != nil {
		t.Fatalf("Translate() error = %v", err)
	}
	if provider.calls != 1 {
		t.Fatalf("provider calls = %d, want 1", provider.calls)
	}
	if repo.committedRequests != 1 || repo.billedCharacters != 8 {
		t.Fatalf("usage commit = requests:%d billed:%d, want 1/8", repo.committedRequests, repo.billedCharacters)
	}
	if len(repo.cache) != 1 {
		t.Fatalf("cache size = %d, want stored provider translation", len(repo.cache))
	}
	item := result.Translations[model.LanguageRussian][0]
	if item.Text != "привет" || item.Status != model.TranslationStatusTranslated {
		t.Fatalf("translated item = %#v, want provider translation", item)
	}
}

func TestTranslateDisabledModeReturnsOriginalsWithoutProvider(t *testing.T) {
	repo := newMemoryRepository(time.Date(2026, 7, 9, 0, 0, 0, 0, time.UTC))
	provider := &providerStub{name: "azure_translator"}
	uc := NewTranslationUseCase(repo, provider, Config{
		BillingMode:           model.BillingModeDisabled,
		MonthlyCharacterLimit: 2_000_000,
		Now:                   repo.now,
	})

	result, err := uc.Translate(context.Background(), TranslateInput{
		SourceLanguage:  "kk",
		TargetLanguages: []string{"en", "ru"},
		Texts:           []string{"Сәлем"},
		ContentType:     string(model.ContentTypeActivity),
	})

	if err != nil {
		t.Fatalf("Translate() error = %v", err)
	}
	if provider.calls != 0 {
		t.Fatalf("provider calls = %d, want 0", provider.calls)
	}
	for language, items := range result.Translations {
		if items[0].Text != "Сәлем" || items[0].Status != model.TranslationStatusDisabled {
			t.Fatalf("%s item = %#v, want disabled original", language, items[0])
		}
	}
}

func TestTranslateProviderTimeoutReleasesReservedQuotaAndReturnsOriginal(t *testing.T) {
	repo := newMemoryRepository(time.Date(2026, 7, 9, 0, 0, 0, 0, time.UTC))
	provider := &providerStub{
		name: "azure_translator",
		err:  context.DeadlineExceeded,
	}
	uc := NewTranslationUseCase(repo, provider, Config{
		BillingMode:           model.BillingModeFreeOnly,
		MonthlyCharacterLimit: 2_000_000,
		Now:                   repo.now,
	})

	result, err := uc.Translate(context.Background(), TranslateInput{
		SourceLanguage:  "en",
		TargetLanguages: []string{"kk"},
		Texts:           []string{"hello"},
		ContentType:     string(model.ContentTypeHelpArticle),
	})

	if err != nil {
		t.Fatalf("Translate() error = %v", err)
	}
	if repo.usedCharacters != 0 {
		t.Fatalf("used characters = %d, want released reservation", repo.usedCharacters)
	}
	item := result.Translations[model.LanguageKazakh][0]
	if item.Text != "hello" || item.Status != model.TranslationStatusProviderUnavailable {
		t.Fatalf("provider timeout item = %#v, want original with provider_unavailable", item)
	}
}

func TestTranslateProviderFailureReleasesReservedQuotaAndReturnsOriginal(t *testing.T) {
	repo := newMemoryRepository(time.Date(2026, 7, 9, 0, 0, 0, 0, time.UTC))
	provider := &providerStub{
		name: "azure_translator",
		err:  errors.New("provider unavailable"),
	}
	uc := NewTranslationUseCase(repo, provider, Config{
		BillingMode:           model.BillingModeFreeOnly,
		MonthlyCharacterLimit: 2_000_000,
		Now:                   repo.now,
	})

	result, err := uc.Translate(context.Background(), TranslateInput{
		SourceLanguage:  "en",
		TargetLanguages: []string{"kk"},
		Texts:           []string{"hello"},
		ContentType:     string(model.ContentTypeHelpArticle),
	})

	if err != nil {
		t.Fatalf("Translate() error = %v", err)
	}
	if repo.usedCharacters != 0 {
		t.Fatalf("used characters = %d, want released reservation", repo.usedCharacters)
	}
	item := result.Translations[model.LanguageKazakh][0]
	if item.Text != "hello" || item.Status != model.TranslationStatusProviderUnavailable {
		t.Fatalf("provider failure item = %#v, want original with provider_unavailable", item)
	}
}

func TestTranslatePaidAllowedStillHonorsConfiguredMonthlyCap(t *testing.T) {
	repo := newMemoryRepository(time.Date(2026, 7, 9, 0, 0, 0, 0, time.UTC))
	provider := &providerStub{name: "azure_translator"}
	uc := NewTranslationUseCase(repo, provider, Config{
		BillingMode:           model.BillingModePaidAllowed,
		MonthlyCharacterLimit: 3,
		Now:                   repo.now,
	})

	result, err := uc.Translate(context.Background(), TranslateInput{
		SourceLanguage:  "ru",
		TargetLanguages: []string{"en"},
		Texts:           []string{"Старт"},
		ContentType:     string(model.ContentTypeExcursion),
	})

	if err != nil {
		t.Fatalf("Translate() error = %v", err)
	}
	if provider.calls != 0 {
		t.Fatalf("provider calls = %d, want paid_allowed cap guard before provider", provider.calls)
	}
	item := result.Translations[model.LanguageEnglish][0]
	if item.Status != model.TranslationStatusQuotaExhausted {
		t.Fatalf("status = %s, want quota_exhausted", item.Status)
	}
}

func TestTranslateRejectsPrivateContentTypes(t *testing.T) {
	repo := newMemoryRepository(time.Date(2026, 7, 9, 0, 0, 0, 0, time.UTC))
	uc := NewTranslationUseCase(repo, &providerStub{name: "azure_translator"}, Config{
		BillingMode:           model.BillingModeFreeOnly,
		MonthlyCharacterLimit: 2_000_000,
		Now:                   repo.now,
	})

	_, err := uc.Translate(context.Background(), TranslateInput{
		SourceLanguage:  "ru",
		TargetLanguages: []string{"en"},
		Texts:           []string{"private"},
		ContentType:     "chat",
	})

	if !errors.Is(err, ErrContentNotTranslatable) {
		t.Fatalf("Translate() error = %v, want ErrContentNotTranslatable", err)
	}
}

func TestCreateBatchJobCompletesFirstAttemptAndIsIdempotent(t *testing.T) {
	repo := newMemoryRepository(time.Date(2026, 7, 9, 0, 0, 0, 0, time.UTC))
	provider := &providerStub{
		name: "azure_translator",
		translations: map[model.Language][]string{
			model.LanguageEnglish: {"Museum"},
		},
	}
	uc := NewTranslationUseCase(repo, provider, Config{
		BillingMode:           model.BillingModeFreeOnly,
		MonthlyCharacterLimit: 2_000_000,
		Now:                   repo.now,
	})

	result, err := uc.CreateBatchJob(context.Background(), BatchInput{
		IdempotencyKey:  "seed-attractions-2026-07",
		SourceLanguage:  "ru",
		TargetLanguages: []string{"en"},
		Texts:           []string{"Музей"},
		ContentType:     string(model.ContentTypeAttraction),
	})

	if err != nil {
		t.Fatalf("CreateBatchJob() error = %v", err)
	}
	if !result.Created || result.Job.Status != model.TranslationJobStatusCompleted {
		t.Fatalf("job = %#v, want newly completed job", result.Job)
	}
	if provider.calls != 1 {
		t.Fatalf("provider calls = %d, want 1", provider.calls)
	}
	if got := result.Job.Result[model.LanguageEnglish][0].Text; got != "Museum" {
		t.Fatalf("translated text = %q, want Museum", got)
	}

	second, err := uc.CreateBatchJob(context.Background(), BatchInput{
		IdempotencyKey:  "seed-attractions-2026-07",
		SourceLanguage:  "ru",
		TargetLanguages: []string{"en"},
		Texts:           []string{"Музей"},
		ContentType:     string(model.ContentTypeAttraction),
	})

	if err != nil {
		t.Fatalf("second CreateBatchJob() error = %v", err)
	}
	if second.Created {
		t.Fatalf("second Created = true, want existing idempotent job")
	}
	if provider.calls != 1 {
		t.Fatalf("provider calls after duplicate = %d, want still 1", provider.calls)
	}
}

func TestCreateBatchJobStopsAtCriticalThresholdBeforeProvider(t *testing.T) {
	repo := newMemoryRepository(time.Date(2026, 7, 9, 0, 0, 0, 0, time.UTC))
	provider := &providerStub{name: "azure_translator"}
	uc := NewTranslationUseCase(repo, provider, Config{
		BillingMode:            model.BillingModeFreeOnly,
		MonthlyCharacterLimit:  100,
		QuotaWarningThreshold:  0.80,
		QuotaCriticalThreshold: 0.95,
		Now:                    repo.now,
	})

	result, err := uc.CreateBatchJob(context.Background(), BatchInput{
		IdempotencyKey:  "seed-attractions-critical-threshold",
		SourceLanguage:  "ru",
		TargetLanguages: []string{"en"},
		Texts:           []string{"123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456"},
		ContentType:     string(model.ContentTypeAttraction),
	})

	if err != nil {
		t.Fatalf("CreateBatchJob() error = %v", err)
	}
	if provider.calls != 0 {
		t.Fatalf("provider calls = %d, want non-critical batch stopped before provider", provider.calls)
	}
	item := result.Job.Result[model.LanguageEnglish][0]
	if item.Status != model.TranslationStatusQuotaExhausted {
		t.Fatalf("status = %s, want quota_exhausted at critical threshold", item.Status)
	}
	if repo.usedCharacters != 0 {
		t.Fatalf("used characters = %d, want released critical-threshold reservation", repo.usedCharacters)
	}
}

func TestCurrentMonthUsageAggregatesRows(t *testing.T) {
	repo := newMemoryRepository(time.Date(2026, 7, 9, 0, 0, 0, 0, time.UTC))
	repo.usageRows = []model.MonthlyUsageRow{
		{
			Provider:           "azure_translator",
			Environment:        "development",
			YearMonth:          "2026-07",
			SourceLanguage:     model.LanguageRussian,
			TargetLanguage:     model.LanguageEnglish,
			ContentType:        model.ContentTypeAttraction,
			BillingMode:        model.BillingModeFreeOnly,
			ReservedCharacters: 80,
			BilledCharacters:   70,
			RequestCount:       1,
			MonthlyLimit:       100,
			WarningReached:     true,
		},
		{
			Provider:           "azure_translator",
			Environment:        "development",
			YearMonth:          "2026-07",
			SourceLanguage:     model.LanguageKazakh,
			TargetLanguage:     model.LanguageEnglish,
			ContentType:        model.ContentTypeActivity,
			BillingMode:        model.BillingModeFreeOnly,
			ReservedCharacters: 15,
			BilledCharacters:   10,
			RequestCount:       2,
			MonthlyLimit:       100,
			CriticalReached:    true,
		},
	}
	uc := NewTranslationUseCase(repo, &providerStub{name: "azure_translator"}, Config{
		BillingMode:           model.BillingModeFreeOnly,
		MonthlyCharacterLimit: 100,
		Now:                   repo.now,
	})

	result, err := uc.CurrentMonthUsage(context.Background())

	if err != nil {
		t.Fatalf("CurrentMonthUsage() error = %v", err)
	}
	if result.TotalReservedCharacters != 95 || result.TotalBilledCharacters != 80 || result.TotalRequestCount != 3 {
		t.Fatalf("usage totals = %#v, want aggregated rows", result)
	}
	if !result.WarningReached || !result.CriticalReached {
		t.Fatalf("threshold flags = warning:%t critical:%t, want both reached", result.WarningReached, result.CriticalReached)
	}
}

type providerStub struct {
	name         string
	calls        int
	err          error
	translations map[model.Language][]string
	metered      int
}

func (s *providerStub) Name() string {
	return s.name
}

func (s *providerStub) Translate(ctx context.Context, input port.ProviderTranslateRequest) (port.ProviderTranslateResult, error) {
	s.calls++
	if s.err != nil {
		return port.ProviderTranslateResult{}, s.err
	}
	return port.ProviderTranslateResult{
		Translations:       s.translations,
		MeteredCharacters:  s.metered,
		ProviderModelLabel: "stub",
	}, nil
}

type memoryRepository struct {
	cache             map[string]model.CachedTranslation
	jobs              map[string]model.TranslationJob
	jobsByKey         map[string]string
	usageRows         []model.MonthlyUsageRow
	usedCharacters    int
	committedRequests int
	billedCharacters  int
	nowValue          time.Time
}

func newMemoryRepository(now time.Time) *memoryRepository {
	return &memoryRepository{
		cache:     map[string]model.CachedTranslation{},
		jobs:      map[string]model.TranslationJob{},
		jobsByKey: map[string]string{},
		nowValue:  now,
	}
}

func (r *memoryRepository) now() time.Time {
	return r.nowValue
}

func (r *memoryRepository) GetCachedTranslation(ctx context.Context, key model.CacheKey) (model.CachedTranslation, bool, error) {
	entry, ok := r.cache[key.String()]
	return entry, ok, nil
}

func (r *memoryRepository) UpsertCachedTranslation(ctx context.Context, entry model.CachedTranslation) error {
	r.cache[entry.Key.String()] = entry
	return nil
}

func (r *memoryRepository) ReserveMonthlyUsage(ctx context.Context, reservation model.UsageReservation) (model.UsageReservationResult, error) {
	if reservation.MonthlyLimit > 0 && r.usedCharacters+reservation.Characters > reservation.MonthlyLimit {
		return model.UsageReservationResult{
			Allowed:         false,
			UsedCharacters:  r.usedCharacters,
			LimitCharacters: reservation.MonthlyLimit,
		}, nil
	}
	r.usedCharacters += reservation.Characters
	warningReached := false
	criticalReached := false
	if reservation.MonthlyLimit > 0 {
		warningReached = float64(r.usedCharacters) >= float64(reservation.MonthlyLimit)*reservation.QuotaWarningThreshold
		criticalReached = float64(r.usedCharacters) >= float64(reservation.MonthlyLimit)*reservation.QuotaCriticalThreshold
	}
	return model.UsageReservationResult{
		Allowed:            true,
		ReservedCharacters: reservation.Characters,
		UsedCharacters:     r.usedCharacters,
		LimitCharacters:    reservation.MonthlyLimit,
		WarningReached:     warningReached,
		CriticalReached:    criticalReached,
	}, nil
}

func (r *memoryRepository) CommitMonthlyUsage(ctx context.Context, commit model.UsageCommit) error {
	r.committedRequests += commit.RequestCount
	r.billedCharacters += commit.BilledCharacters
	return nil
}

func (r *memoryRepository) ReleaseMonthlyUsage(ctx context.Context, release model.UsageRelease) error {
	r.usedCharacters -= release.Characters
	if r.usedCharacters < 0 {
		r.usedCharacters = 0
	}
	return nil
}

func (r *memoryRepository) CreateTranslationJob(ctx context.Context, job model.TranslationJob) (model.TranslationJob, bool, error) {
	if existingID, ok := r.jobsByKey[job.IdempotencyKey]; ok {
		return r.jobs[existingID], false, nil
	}
	if job.AttemptCount == 0 {
		job.AttemptCount = 1
	}
	r.jobs[job.ID] = job
	r.jobsByKey[job.IdempotencyKey] = job.ID
	return job, true, nil
}

func (r *memoryRepository) CompleteTranslationJob(ctx context.Context, completion model.TranslationJobCompletion) (model.TranslationJob, error) {
	job := r.jobs[completion.ID]
	job.Status = model.TranslationJobStatusCompleted
	job.Result = completion.Result
	job.UpdatedAt = completion.CompletedAt
	job.CompletedAt = &completion.CompletedAt
	r.jobs[job.ID] = job
	return job, nil
}

func (r *memoryRepository) FailTranslationJob(ctx context.Context, failure model.TranslationJobFailure) (model.TranslationJob, error) {
	job := r.jobs[failure.ID]
	job.Status = model.TranslationJobStatusFailed
	job.ErrorCode = failure.ErrorCode
	job.ErrorMessage = failure.ErrorMessage
	job.UpdatedAt = failure.FailedAt
	r.jobs[job.ID] = job
	return job, nil
}

func (r *memoryRepository) GetTranslationJob(ctx context.Context, id string) (model.TranslationJob, bool, error) {
	job, ok := r.jobs[id]
	return job, ok, nil
}

func (r *memoryRepository) GetMonthlyUsage(ctx context.Context, provider string, environment string, yearMonth string) ([]model.MonthlyUsageRow, error) {
	rows := make([]model.MonthlyUsageRow, 0, len(r.usageRows))
	for _, row := range r.usageRows {
		if row.Provider == provider && row.Environment == environment && row.YearMonth == yearMonth {
			rows = append(rows, row)
		}
	}
	return rows, nil
}
