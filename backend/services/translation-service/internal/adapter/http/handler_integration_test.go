package http

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"kz/inflap/backend/services/translation-service/internal/app"
	"kz/inflap/backend/services/translation-service/internal/domain/model"
	"kz/inflap/backend/services/translation-service/internal/domain/port"
)

func TestInternalTranslateIntegrationUsesFakeProviderAndCache(t *testing.T) {
	now := time.Date(2026, 7, 9, 12, 0, 0, 0, time.UTC)
	repo := newIntegrationRepository(now)
	provider := &integrationProvider{name: "azure_translator"}
	useCase := app.NewTranslationUseCase(repo, provider, app.Config{
		BillingMode:           model.BillingModeFreeOnly,
		MonthlyCharacterLimit: 100,
		Now:                   repo.now,
	})
	handler := NewHandler(useCase, SecurityConfig{InternalServiceToken: "internal-token"})
	mux := http.NewServeMux()
	handler.Register(mux)

	body := bytes.NewBufferString(`{"sourceLanguage":"ru","targetLanguages":["en"],"texts":["Музей"],"contentType":"attraction"}`)
	req := httptest.NewRequest(http.MethodPost, "/internal/v1/translations/translate", body)
	req.Header.Set("X-Internal-Service-Token", "internal-token")
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", rec.Code, rec.Body.String())
	}
	if provider.calls != 1 {
		t.Fatalf("provider calls = %d, want 1", provider.calls)
	}
	var decoded internalTranslateResponse
	if err := json.NewDecoder(rec.Body).Decode(&decoded); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	item := decoded.Translations["en"][0]
	if item.Text != "translated:Музей" || item.Status != string(model.TranslationStatusTranslated) {
		t.Fatalf("item = %#v, want translated provider result", item)
	}
	if len(repo.cache) != 1 {
		t.Fatalf("cache size = %d, want translation cached", len(repo.cache))
	}
}

func TestInternalTranslateIntegrationHardStopsWhenQuotaIsExhausted(t *testing.T) {
	now := time.Date(2026, 7, 9, 12, 0, 0, 0, time.UTC)
	repo := newIntegrationRepository(now)
	provider := &integrationProvider{name: "azure_translator"}
	useCase := app.NewTranslationUseCase(repo, provider, app.Config{
		BillingMode:           model.BillingModeFreeOnly,
		MonthlyCharacterLimit: 1,
		Now:                   repo.now,
	})
	handler := NewHandler(useCase, SecurityConfig{InternalServiceToken: "internal-token"})
	mux := http.NewServeMux()
	handler.Register(mux)

	body := bytes.NewBufferString(`{"sourceLanguage":"ru","targetLanguages":["en"],"texts":["Музей"],"contentType":"attraction"}`)
	req := httptest.NewRequest(http.MethodPost, "/internal/v1/translations/translate", body)
	req.Header.Set("X-Internal-Service-Token", "internal-token")
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", rec.Code, rec.Body.String())
	}
	if provider.calls != 0 {
		t.Fatalf("provider calls = %d, want hard-stop before provider", provider.calls)
	}
	var decoded internalTranslateResponse
	if err := json.NewDecoder(rec.Body).Decode(&decoded); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	item := decoded.Translations["en"][0]
	if item.Text != "Музей" || item.Status != string(model.TranslationStatusQuotaExhausted) {
		t.Fatalf("item = %#v, want original text with quota_exhausted", item)
	}
}

type integrationProvider struct {
	name  string
	calls int
}

func (p *integrationProvider) Name() string {
	return p.name
}

func (p *integrationProvider) Translate(ctx context.Context, input port.ProviderTranslateRequest) (port.ProviderTranslateResult, error) {
	p.calls++
	translations := make(map[model.Language][]string, len(input.TargetLanguages))
	for _, language := range input.TargetLanguages {
		items := make([]string, 0, len(input.Texts))
		for _, text := range input.Texts {
			items = append(items, "translated:"+text)
		}
		translations[language] = items
	}
	return port.ProviderTranslateResult{
		Translations:       translations,
		MeteredCharacters:  model.CountBillableCharacters(input.Texts),
		ProviderModelLabel: "fake-provider",
	}, nil
}

type integrationRepository struct {
	cache          map[string]model.CachedTranslation
	jobs           map[string]model.TranslationJob
	jobsByKey      map[string]string
	usedCharacters int
	nowValue       time.Time
}

func newIntegrationRepository(now time.Time) *integrationRepository {
	return &integrationRepository{
		cache:     map[string]model.CachedTranslation{},
		jobs:      map[string]model.TranslationJob{},
		jobsByKey: map[string]string{},
		nowValue:  now,
	}
}

func (r *integrationRepository) now() time.Time {
	return r.nowValue
}

func (r *integrationRepository) GetCachedTranslation(ctx context.Context, key model.CacheKey) (model.CachedTranslation, bool, error) {
	entry, ok := r.cache[key.String()]
	return entry, ok, nil
}

func (r *integrationRepository) UpsertCachedTranslation(ctx context.Context, entry model.CachedTranslation) error {
	r.cache[entry.Key.String()] = entry
	return nil
}

func (r *integrationRepository) ReserveMonthlyUsage(ctx context.Context, reservation model.UsageReservation) (model.UsageReservationResult, error) {
	if reservation.MonthlyLimit > 0 && r.usedCharacters+reservation.Characters > reservation.MonthlyLimit {
		return model.UsageReservationResult{
			Allowed:         false,
			UsedCharacters:  r.usedCharacters,
			LimitCharacters: reservation.MonthlyLimit,
		}, nil
	}
	r.usedCharacters += reservation.Characters
	return model.UsageReservationResult{
		Allowed:            true,
		ReservedCharacters: reservation.Characters,
		UsedCharacters:     r.usedCharacters,
		LimitCharacters:    reservation.MonthlyLimit,
	}, nil
}

func (r *integrationRepository) CommitMonthlyUsage(ctx context.Context, commit model.UsageCommit) error {
	return nil
}

func (r *integrationRepository) ReleaseMonthlyUsage(ctx context.Context, release model.UsageRelease) error {
	r.usedCharacters -= release.Characters
	if r.usedCharacters < 0 {
		r.usedCharacters = 0
	}
	return nil
}

func (r *integrationRepository) CreateTranslationJob(ctx context.Context, job model.TranslationJob) (model.TranslationJob, bool, error) {
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

func (r *integrationRepository) CompleteTranslationJob(ctx context.Context, completion model.TranslationJobCompletion) (model.TranslationJob, error) {
	job := r.jobs[completion.ID]
	job.Status = model.TranslationJobStatusCompleted
	job.Result = completion.Result
	job.UpdatedAt = completion.CompletedAt
	job.CompletedAt = &completion.CompletedAt
	r.jobs[job.ID] = job
	return job, nil
}

func (r *integrationRepository) FailTranslationJob(ctx context.Context, failure model.TranslationJobFailure) (model.TranslationJob, error) {
	job := r.jobs[failure.ID]
	job.Status = model.TranslationJobStatusFailed
	job.ErrorCode = failure.ErrorCode
	job.ErrorMessage = failure.ErrorMessage
	job.UpdatedAt = failure.FailedAt
	r.jobs[job.ID] = job
	return job, nil
}

func (r *integrationRepository) GetTranslationJob(ctx context.Context, id string) (model.TranslationJob, bool, error) {
	job, ok := r.jobs[id]
	return job, ok, nil
}

func (r *integrationRepository) GetMonthlyUsage(ctx context.Context, provider string, environment string, yearMonth string) ([]model.MonthlyUsageRow, error) {
	return nil, nil
}
