package http

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"kz/inflap/backend/pkg/serviceauth"
	"kz/inflap/backend/services/translation-service/internal/app"
	"kz/inflap/backend/services/translation-service/internal/domain/model"
)

func TestLegacyTranslateEndpointReturnsFlatTranslationsForExistingClients(t *testing.T) {
	uc := &useCaseStub{
		result: app.TranslateResult{
			Translations: map[model.Language][]model.TranslatedText{
				model.LanguageEnglish: {
					{Text: "Start", Status: model.TranslationStatusTranslated, Provider: "azure_translator"},
				},
				model.LanguageKazakh: {
					{Text: "Бастау", Status: model.TranslationStatusTranslated, Provider: "azure_translator"},
				},
			},
			Provider: "azure_translator",
		},
	}
	handler := NewHandler(uc, SecurityConfig{InternalServiceToken: "internal-token"})
	mux := http.NewServeMux()
	handler.Register(mux)

	body := bytes.NewBufferString(`{"sourceLanguage":"ru","targetLanguages":["en","kk"],"texts":["Старт"]}`)
	req := httptest.NewRequest(http.MethodPost, "/v1/translate", body)
	req.Header.Set("X-Internal-Service-Token", "internal-token")
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", rec.Code, rec.Body.String())
	}
	var decoded legacyTranslateResponse
	if err := json.NewDecoder(rec.Body).Decode(&decoded); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if decoded.Model != "azure_translator" {
		t.Fatalf("model = %q, want provider label", decoded.Model)
	}
	if decoded.Translations["en"][0] != "Start" || decoded.Translations["kk"][0] != "Бастау" {
		t.Fatalf("translations = %#v, want flat translation lists", decoded.Translations)
	}
	if uc.input.ContentType != string(model.ContentTypeExcursion) {
		t.Fatalf("content type = %q, want excursion compatibility default", uc.input.ContentType)
	}
}

func TestInternalTranslateEndpointReturnsStatuses(t *testing.T) {
	uc := &useCaseStub{
		result: app.TranslateResult{
			Translations: map[model.Language][]model.TranslatedText{
				model.LanguageEnglish: {
					{Text: "hello", Status: model.TranslationStatusCached, Provider: "azure_translator", CacheHit: true},
				},
			},
			Provider: "azure_translator",
		},
	}
	handler := NewHandler(uc, SecurityConfig{InternalServiceToken: "internal-token"})
	mux := http.NewServeMux()
	handler.Register(mux)

	body := bytes.NewBufferString(`{"sourceLanguage":"ru","targetLanguages":["en"],"texts":["привет"],"contentType":"help_article"}`)
	req := httptest.NewRequest(http.MethodPost, "/internal/v1/translations/translate", body)
	req.Header.Set("X-Internal-Service-Token", "internal-token")
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", rec.Code, rec.Body.String())
	}
	var decoded internalTranslateResponse
	if err := json.NewDecoder(rec.Body).Decode(&decoded); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	item := decoded.Translations["en"][0]
	if item.Text != "hello" || item.Status != string(model.TranslationStatusCached) || !item.CacheHit {
		t.Fatalf("item = %#v, want cached status metadata", item)
	}
}

func TestInternalTranslateEndpointAcceptsServiceJWTWithRequiredRole(t *testing.T) {
	uc := &useCaseStub{
		result: app.TranslateResult{
			Translations: map[model.Language][]model.TranslatedText{
				model.LanguageEnglish: {
					{Text: "hello", Status: model.TranslationStatusTranslated, Provider: "azure_translator"},
				},
			},
			Provider: "azure_translator",
		},
	}
	authorizer := &serviceAuthorizerStub{}
	handler := NewHandler(uc, SecurityConfig{ServiceAuthorizer: authorizer})
	mux := http.NewServeMux()
	handler.Register(mux)

	body := bytes.NewBufferString(`{"sourceLanguage":"ru","targetLanguages":["en"],"texts":["привет"],"contentType":"help_article"}`)
	req := httptest.NewRequest(http.MethodPost, "/internal/v1/translations/translate", body)
	req.Header.Set("Authorization", "Bearer service-jwt")
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", rec.Code, rec.Body.String())
	}
	if authorizer.authHeader != "Bearer service-jwt" {
		t.Fatalf("auth header = %q, want bearer token", authorizer.authHeader)
	}
	if len(authorizer.requiredRoles) != 1 || authorizer.requiredRoles[0] != roleTranslationTranslate {
		t.Fatalf("required roles = %#v, want translation role", authorizer.requiredRoles)
	}
}

func TestInternalTokenMiddlewareRejectsProtectedTranslationEndpoint(t *testing.T) {
	handler := NewHandler(&useCaseStub{}, SecurityConfig{InternalServiceToken: "internal-token"})
	mux := http.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(http.MethodPost, "/v1/translate", bytes.NewBufferString(`{}`))
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d, want unauthorized", rec.Code)
	}
}

func TestInternalBatchEndpointCreatesJob(t *testing.T) {
	now := time.Date(2026, 7, 9, 12, 0, 0, 0, time.UTC)
	uc := &useCaseStub{
		batchResult: app.BatchResult{
			Created:  true,
			Provider: "azure_translator",
			Job: model.TranslationJob{
				ID:              "4a62b49e-a3a0-4b41-9441-fce3e5859c5a",
				IdempotencyKey:  "seed-attractions-2026-07",
				SourceLanguage:  model.LanguageRussian,
				TargetLanguages: []model.Language{model.LanguageEnglish},
				ContentType:     model.ContentTypeAttraction,
				Status:          model.TranslationJobStatusCompleted,
				Result: map[model.Language][]model.TranslatedText{
					model.LanguageEnglish: {
						{Text: "Museum", Status: model.TranslationStatusTranslated, Provider: "azure_translator"},
					},
				},
				AttemptCount: 1,
				CreatedAt:    now,
				UpdatedAt:    now,
				CompletedAt:  &now,
			},
		},
	}
	handler := NewHandler(uc, SecurityConfig{InternalServiceToken: "internal-token"})
	mux := http.NewServeMux()
	handler.Register(mux)

	body := bytes.NewBufferString(`{"sourceLanguage":"ru","targetLanguages":["en"],"texts":["Музей"],"contentType":"attraction"}`)
	req := httptest.NewRequest(http.MethodPost, "/internal/v1/translations/batch", body)
	req.Header.Set("Idempotency-Key", "seed-attractions-2026-07")
	req.Header.Set("X-Internal-Service-Token", "internal-token")
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusAccepted {
		t.Fatalf("status = %d, body = %s", rec.Code, rec.Body.String())
	}
	if uc.batchInput.IdempotencyKey != "seed-attractions-2026-07" {
		t.Fatalf("idempotency key = %q, want header fallback", uc.batchInput.IdempotencyKey)
	}
	var decoded internalBatchResponse
	if err := json.NewDecoder(rec.Body).Decode(&decoded); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if decoded.Job.Status != string(model.TranslationJobStatusCompleted) || decoded.Job.Translations["en"][0].Text != "Museum" {
		t.Fatalf("job = %#v, want completed job with translations", decoded.Job)
	}
}

func TestInternalJobEndpointReturnsJobStatus(t *testing.T) {
	now := time.Date(2026, 7, 9, 12, 0, 0, 0, time.UTC)
	uc := &useCaseStub{
		job: model.TranslationJob{
			ID:              "4a62b49e-a3a0-4b41-9441-fce3e5859c5a",
			IdempotencyKey:  "job-key",
			SourceLanguage:  model.LanguageKazakh,
			TargetLanguages: []model.Language{model.LanguageRussian},
			ContentType:     model.ContentTypeHelpArticle,
			Status:          model.TranslationJobStatusProcessing,
			Result:          map[model.Language][]model.TranslatedText{},
			AttemptCount:    1,
			CreatedAt:       now,
			UpdatedAt:       now,
		},
	}
	handler := NewHandler(uc, SecurityConfig{InternalServiceToken: "internal-token"})
	mux := http.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(http.MethodGet, "/internal/v1/translations/jobs/4a62b49e-a3a0-4b41-9441-fce3e5859c5a", nil)
	req.Header.Set("X-Internal-Service-Token", "internal-token")
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", rec.Code, rec.Body.String())
	}
	if uc.jobID != "4a62b49e-a3a0-4b41-9441-fce3e5859c5a" {
		t.Fatalf("job id = %q, want path value", uc.jobID)
	}
	var decoded internalJobResponse
	if err := json.NewDecoder(rec.Body).Decode(&decoded); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if decoded.Job.Status != string(model.TranslationJobStatusProcessing) {
		t.Fatalf("status = %q, want processing", decoded.Job.Status)
	}
}

func TestInternalUsageEndpointReturnsCurrentMonthUsage(t *testing.T) {
	uc := &useCaseStub{
		usageResult: app.MonthlyUsageResult{
			Provider:                "azure_translator",
			Environment:             "test",
			YearMonth:               "2026-07",
			TotalReservedCharacters: 100,
			TotalBilledCharacters:   90,
			TotalRequestCount:       2,
			MonthlyCharacterLimit:   2_000_000,
			Rows: []model.MonthlyUsageRow{
				{
					Provider:           "azure_translator",
					Environment:        "test",
					YearMonth:          "2026-07",
					SourceLanguage:     model.LanguageRussian,
					TargetLanguage:     model.LanguageEnglish,
					ContentType:        model.ContentTypeAttraction,
					BillingMode:        model.BillingModeFreeOnly,
					ReservedCharacters: 100,
					BilledCharacters:   90,
					RequestCount:       2,
					MonthlyLimit:       2_000_000,
				},
			},
		},
	}
	handler := NewHandler(uc, SecurityConfig{InternalServiceToken: "internal-token"})
	mux := http.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(http.MethodGet, "/internal/v1/translations/usage/current-month", nil)
	req.Header.Set("X-Internal-Service-Token", "internal-token")
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", rec.Code, rec.Body.String())
	}
	var decoded internalUsageResponse
	if err := json.NewDecoder(rec.Body).Decode(&decoded); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if decoded.TotalReservedCharacters != 100 || decoded.Rows[0].ContentType != string(model.ContentTypeAttraction) {
		t.Fatalf("usage = %#v, want current month usage details", decoded)
	}
}

type useCaseStub struct {
	input       app.TranslateInput
	result      app.TranslateResult
	batchInput  app.BatchInput
	batchResult app.BatchResult
	jobID       string
	job         model.TranslationJob
	usageResult app.MonthlyUsageResult
	err         error
}

func (s *useCaseStub) Translate(ctx context.Context, input app.TranslateInput) (app.TranslateResult, error) {
	s.input = input
	return s.result, s.err
}

func (s *useCaseStub) CreateBatchJob(ctx context.Context, input app.BatchInput) (app.BatchResult, error) {
	s.batchInput = input
	return s.batchResult, s.err
}

func (s *useCaseStub) GetTranslationJob(ctx context.Context, id string) (model.TranslationJob, error) {
	s.jobID = id
	return s.job, s.err
}

func (s *useCaseStub) CurrentMonthUsage(ctx context.Context) (app.MonthlyUsageResult, error) {
	return s.usageResult, s.err
}

type serviceAuthorizerStub struct {
	authHeader    string
	requiredRoles []string
	err           error
}

func (s *serviceAuthorizerStub) ValidateBearer(ctx context.Context, authHeader string, requiredRoles []string) (*serviceauth.Claims, error) {
	s.authHeader = authHeader
	s.requiredRoles = append([]string(nil), requiredRoles...)
	if s.err != nil {
		return nil, s.err
	}
	return &serviceauth.Claims{
		Subject: "excursion-service",
		Type:    "service",
		Roles:   requiredRoles,
	}, nil
}
