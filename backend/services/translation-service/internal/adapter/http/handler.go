package http

import (
	"context"
	"crypto/subtle"
	"encoding/json"
	"errors"
	"net/http"
	"strings"

	"kz/inflap/backend/pkg/serviceauth"
	"kz/inflap/backend/services/translation-service/internal/app"
	"kz/inflap/backend/services/translation-service/internal/domain/model"
)

const headerInternalServiceToken = "X-Internal-Service-Token"

const (
	roleTranslationTranslate = "translation:translate"
	roleTranslationAdmin     = "translation:admin"
)

type UseCase interface {
	Translate(ctx context.Context, input app.TranslateInput) (app.TranslateResult, error)
	CreateBatchJob(ctx context.Context, input app.BatchInput) (app.BatchResult, error)
	GetTranslationJob(ctx context.Context, id string) (model.TranslationJob, error)
	CurrentMonthUsage(ctx context.Context) (app.MonthlyUsageResult, error)
}

type ServiceAuthorizer interface {
	ValidateBearer(ctx context.Context, authHeader string, requiredRoles []string) (*serviceauth.Claims, error)
}

type SecurityConfig struct {
	InternalServiceToken string
	ServiceAuthorizer    ServiceAuthorizer
}

type Handler struct {
	uc       UseCase
	security SecurityConfig
}

func NewHandler(uc UseCase, security SecurityConfig) *Handler {
	return &Handler{uc: uc, security: security}
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.Health)
	mux.HandleFunc("GET /health/live", h.Live)
	mux.HandleFunc("GET /health/ready", h.Ready)
	mux.HandleFunc("POST /v1/translate", h.requireInternalAuth([]string{roleTranslationTranslate}, h.LegacyTranslate))
	mux.HandleFunc("POST /internal/v1/translations/translate", h.requireInternalAuth([]string{roleTranslationTranslate}, h.InternalTranslate))
	mux.HandleFunc("POST /internal/v1/translations/batch", h.requireInternalAuth([]string{roleTranslationTranslate}, h.InternalBatch))
	mux.HandleFunc("GET /internal/v1/translations/jobs/{job_id}", h.requireInternalAuth([]string{roleTranslationAdmin}, h.InternalJob))
	mux.HandleFunc("GET /internal/v1/translations/usage/current-month", h.requireInternalAuth([]string{roleTranslationAdmin}, h.InternalUsageCurrentMonth))
	mux.HandleFunc("GET /", h.NotFound)
	mux.HandleFunc("POST /", h.NotFound)
}

func (h *Handler) Health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (h *Handler) Live(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (h *Handler) Ready(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ready"})
}

func (h *Handler) NotFound(w http.ResponseWriter, _ *http.Request) {
	writeError(w, http.StatusNotFound, "route_not_found")
}

func (h *Handler) LegacyTranslate(w http.ResponseWriter, r *http.Request) {
	var req legacyTranslateRequest
	if !decodeJSON(w, r, &req) {
		return
	}
	result, err := h.uc.Translate(r.Context(), app.TranslateInput{
		SourceLanguage:  req.SourceLanguage,
		TargetLanguages: req.TargetLanguages,
		Texts:           req.Texts,
		ContentType:     string(model.ContentTypeExcursion),
		RequestID:       requestID(r),
	})
	if err != nil {
		writeAppError(w, err)
		return
	}

	translations := make(map[string][]string, len(result.Translations))
	for language, items := range result.Translations {
		texts := make([]string, 0, len(items))
		for _, item := range items {
			texts = append(texts, item.Text)
		}
		translations[string(language)] = texts
	}
	writeJSON(w, http.StatusOK, legacyTranslateResponse{
		Translations: translations,
		Model:        result.Provider,
	})
}

func (h *Handler) InternalTranslate(w http.ResponseWriter, r *http.Request) {
	var req internalTranslateRequest
	if !decodeJSON(w, r, &req) {
		return
	}
	result, err := h.uc.Translate(r.Context(), app.TranslateInput{
		SourceLanguage:  req.SourceLanguage,
		TargetLanguages: req.TargetLanguages,
		Texts:           req.Texts,
		ContentType:     req.ContentType,
		RequestID:       requestID(r),
	})
	if err != nil {
		writeAppError(w, err)
		return
	}

	translations := make(map[string][]internalTranslatedText, len(result.Translations))
	for language, items := range result.Translations {
		responseItems := make([]internalTranslatedText, 0, len(items))
		for _, item := range items {
			responseItems = append(responseItems, internalTranslatedText{
				Text:     item.Text,
				Status:   string(item.Status),
				Provider: item.Provider,
				CacheHit: item.CacheHit,
			})
		}
		translations[string(language)] = responseItems
	}
	writeJSON(w, http.StatusOK, internalTranslateResponse{
		Translations: translations,
		Provider:     result.Provider,
	})
}

func (h *Handler) InternalBatch(w http.ResponseWriter, r *http.Request) {
	var req internalBatchRequest
	if !decodeJSONWithLimit(w, r, &req, 1024*1024) {
		return
	}
	if strings.TrimSpace(req.IdempotencyKey) == "" {
		req.IdempotencyKey = strings.TrimSpace(r.Header.Get("Idempotency-Key"))
	}
	result, err := h.uc.CreateBatchJob(r.Context(), app.BatchInput{
		IdempotencyKey:  req.IdempotencyKey,
		SourceLanguage:  req.SourceLanguage,
		TargetLanguages: req.TargetLanguages,
		Texts:           req.Texts,
		ContentType:     req.ContentType,
		RequestID:       requestID(r),
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	status := http.StatusOK
	if result.Created {
		status = http.StatusAccepted
	}
	writeJSON(w, status, internalBatchResponse{
		Job:      toJobResponse(result.Job),
		Provider: result.Provider,
	})
}

func (h *Handler) InternalJob(w http.ResponseWriter, r *http.Request) {
	job, err := h.uc.GetTranslationJob(r.Context(), r.PathValue("job_id"))
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, internalJobResponse{Job: toJobResponse(job)})
}

func (h *Handler) InternalUsageCurrentMonth(w http.ResponseWriter, r *http.Request) {
	usage, err := h.uc.CurrentMonthUsage(r.Context())
	if err != nil {
		writeAppError(w, err)
		return
	}
	rows := make([]internalUsageRow, 0, len(usage.Rows))
	for _, row := range usage.Rows {
		rows = append(rows, internalUsageRow{
			Provider:           row.Provider,
			Environment:        row.Environment,
			YearMonth:          row.YearMonth,
			SourceLanguage:     string(row.SourceLanguage),
			TargetLanguage:     string(row.TargetLanguage),
			ContentType:        string(row.ContentType),
			BillingMode:        string(row.BillingMode),
			ReservedCharacters: row.ReservedCharacters,
			BilledCharacters:   row.BilledCharacters,
			RequestCount:       row.RequestCount,
			MonthlyLimit:       row.MonthlyLimit,
			WarningReached:     row.WarningReached,
			CriticalReached:    row.CriticalReached,
		})
	}
	writeJSON(w, http.StatusOK, internalUsageResponse{
		Provider:                usage.Provider,
		Environment:             usage.Environment,
		YearMonth:               usage.YearMonth,
		Rows:                    rows,
		TotalReservedCharacters: usage.TotalReservedCharacters,
		TotalBilledCharacters:   usage.TotalBilledCharacters,
		TotalRequestCount:       usage.TotalRequestCount,
		MonthlyCharacterLimit:   usage.MonthlyCharacterLimit,
		QuotaWarningThreshold:   usage.QuotaWarningThreshold,
		QuotaCriticalThreshold:  usage.QuotaCriticalThreshold,
		WarningReached:          usage.WarningReached,
		CriticalReached:         usage.CriticalReached,
	})
}

func (h *Handler) requireInternalAuth(requiredRoles []string, next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if h.security.ServiceAuthorizer != nil {
			authHeader := strings.TrimSpace(r.Header.Get("Authorization"))
			if authHeader != "" {
				if _, err := h.security.ServiceAuthorizer.ValidateBearer(r.Context(), authHeader, requiredRoles); err == nil {
					next(w, r)
					return
				} else if serviceauth.IsForbidden(err) {
					writeError(w, http.StatusForbidden, "service_not_allowed")
					return
				} else if serviceauth.IsUnauthorized(err) {
					writeError(w, http.StatusUnauthorized, "missing_or_invalid_service_token")
					return
				} else {
					writeError(w, http.StatusServiceUnavailable, "service_auth_unavailable")
					return
				}
			}
		}

		required := strings.TrimSpace(h.security.InternalServiceToken)
		if required == "" {
			writeError(w, http.StatusServiceUnavailable, "service_auth_not_configured")
			return
		}
		if tokenMatches(r.Header.Get(headerInternalServiceToken), required) {
			next(w, r)
			return
		}
		const bearerPrefix = "bearer "
		authHeader := strings.TrimSpace(r.Header.Get("Authorization"))
		if len(authHeader) > len(bearerPrefix) &&
			strings.EqualFold(authHeader[:len(bearerPrefix)], bearerPrefix) &&
			tokenMatches(strings.TrimSpace(authHeader[len(bearerPrefix):]), required) {
			next(w, r)
			return
		}
		writeError(w, http.StatusUnauthorized, "invalid_internal_service_token")
	}
}

func tokenMatches(actual string, expected string) bool {
	actual = strings.TrimSpace(actual)
	expected = strings.TrimSpace(expected)
	if actual == "" || expected == "" {
		return false
	}
	return subtle.ConstantTimeCompare([]byte(actual), []byte(expected)) == 1
}

func decodeJSON(w http.ResponseWriter, r *http.Request, out any) bool {
	return decodeJSONWithLimit(w, r, out, 64*1024)
}

func decodeJSONWithLimit(w http.ResponseWriter, r *http.Request, out any, limit int64) bool {
	defer r.Body.Close()
	decoder := json.NewDecoder(http.MaxBytesReader(w, r.Body, limit))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(out); err != nil {
		writeError(w, http.StatusBadRequest, "invalid_request")
		return false
	}
	return true
}

func writeAppError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, app.ErrInvalidLanguage), errors.Is(err, app.ErrInvalidRequest), errors.Is(err, app.ErrContentNotTranslatable):
		writeError(w, http.StatusBadRequest, "invalid_request")
	case errors.Is(err, app.ErrTranslationJobNotFound):
		writeError(w, http.StatusNotFound, "translation_job_not_found")
	default:
		writeError(w, http.StatusInternalServerError, "internal_error")
	}
}

func writeError(w http.ResponseWriter, status int, code string) {
	writeJSON(w, status, map[string]string{"error": code})
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

func requestID(r *http.Request) string {
	if value := strings.TrimSpace(r.Header.Get("X-Request-Id")); value != "" {
		return value
	}
	return strings.TrimSpace(r.Header.Get("X-Request-ID"))
}

type legacyTranslateRequest struct {
	SourceLanguage  string   `json:"sourceLanguage"`
	TargetLanguages []string `json:"targetLanguages"`
	Texts           []string `json:"texts"`
}

type legacyTranslateResponse struct {
	Translations map[string][]string `json:"translations"`
	Model        string              `json:"model,omitempty"`
}

type internalTranslateRequest struct {
	SourceLanguage  string   `json:"sourceLanguage"`
	TargetLanguages []string `json:"targetLanguages"`
	Texts           []string `json:"texts"`
	ContentType     string   `json:"contentType"`
}

type internalTranslateResponse struct {
	Translations map[string][]internalTranslatedText `json:"translations"`
	Provider     string                              `json:"provider,omitempty"`
}

type internalTranslatedText struct {
	Text     string `json:"text"`
	Status   string `json:"status"`
	Provider string `json:"provider,omitempty"`
	CacheHit bool   `json:"cacheHit,omitempty"`
}

type internalBatchRequest struct {
	IdempotencyKey  string   `json:"idempotencyKey"`
	SourceLanguage  string   `json:"sourceLanguage"`
	TargetLanguages []string `json:"targetLanguages"`
	Texts           []string `json:"texts"`
	ContentType     string   `json:"contentType"`
}

type internalBatchResponse struct {
	Job      internalJob `json:"job"`
	Provider string      `json:"provider,omitempty"`
}

type internalJobResponse struct {
	Job internalJob `json:"job"`
}

type internalJob struct {
	ID              string                              `json:"id"`
	IdempotencyKey  string                              `json:"idempotencyKey"`
	SourceLanguage  string                              `json:"sourceLanguage"`
	TargetLanguages []string                            `json:"targetLanguages"`
	ContentType     string                              `json:"contentType"`
	Status          string                              `json:"status"`
	Translations    map[string][]internalTranslatedText `json:"translations,omitempty"`
	ErrorCode       string                              `json:"errorCode,omitempty"`
	ErrorMessage    string                              `json:"errorMessage,omitempty"`
	AttemptCount    int                                 `json:"attemptCount"`
	CreatedAt       string                              `json:"createdAt"`
	UpdatedAt       string                              `json:"updatedAt"`
	CompletedAt     string                              `json:"completedAt,omitempty"`
}

type internalUsageResponse struct {
	Provider                string             `json:"provider"`
	Environment             string             `json:"environment"`
	YearMonth               string             `json:"yearMonth"`
	Rows                    []internalUsageRow `json:"rows"`
	TotalReservedCharacters int                `json:"totalReservedCharacters"`
	TotalBilledCharacters   int                `json:"totalBilledCharacters"`
	TotalRequestCount       int                `json:"totalRequestCount"`
	MonthlyCharacterLimit   int                `json:"monthlyCharacterLimit"`
	QuotaWarningThreshold   float64            `json:"quotaWarningThreshold"`
	QuotaCriticalThreshold  float64            `json:"quotaCriticalThreshold"`
	WarningReached          bool               `json:"warningReached"`
	CriticalReached         bool               `json:"criticalReached"`
}

type internalUsageRow struct {
	Provider           string `json:"provider"`
	Environment        string `json:"environment"`
	YearMonth          string `json:"yearMonth"`
	SourceLanguage     string `json:"sourceLanguage"`
	TargetLanguage     string `json:"targetLanguage"`
	ContentType        string `json:"contentType"`
	BillingMode        string `json:"billingMode"`
	ReservedCharacters int    `json:"reservedCharacters"`
	BilledCharacters   int    `json:"billedCharacters"`
	RequestCount       int    `json:"requestCount"`
	MonthlyLimit       int    `json:"monthlyLimit"`
	WarningReached     bool   `json:"warningReached"`
	CriticalReached    bool   `json:"criticalReached"`
}

func toJobResponse(job model.TranslationJob) internalJob {
	targetLanguages := make([]string, 0, len(job.TargetLanguages))
	for _, language := range job.TargetLanguages {
		targetLanguages = append(targetLanguages, string(language))
	}
	translations := make(map[string][]internalTranslatedText, len(job.Result))
	for language, items := range job.Result {
		responseItems := make([]internalTranslatedText, 0, len(items))
		for _, item := range items {
			responseItems = append(responseItems, internalTranslatedText{
				Text:     item.Text,
				Status:   string(item.Status),
				Provider: item.Provider,
				CacheHit: item.CacheHit,
			})
		}
		translations[string(language)] = responseItems
	}
	response := internalJob{
		ID:              job.ID,
		IdempotencyKey:  job.IdempotencyKey,
		SourceLanguage:  string(job.SourceLanguage),
		TargetLanguages: targetLanguages,
		ContentType:     string(job.ContentType),
		Status:          string(job.Status),
		Translations:    translations,
		ErrorCode:       job.ErrorCode,
		ErrorMessage:    job.ErrorMessage,
		AttemptCount:    job.AttemptCount,
		CreatedAt:       job.CreatedAt.UTC().Format("2006-01-02T15:04:05Z07:00"),
		UpdatedAt:       job.UpdatedAt.UTC().Format("2006-01-02T15:04:05Z07:00"),
	}
	if job.CompletedAt != nil {
		response.CompletedAt = job.CompletedAt.UTC().Format("2006-01-02T15:04:05Z07:00")
	}
	return response
}
