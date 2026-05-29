package httpadapter

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/anti-fraud-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/anti-fraud-service/internal/config"
	"github.com/dkhvan-dev/flyfy/backend/services/anti-fraud-service/internal/domain/model"
)

type Handler struct {
	useCase *app.RiskUseCase
}

func NewHandler(useCase *app.RiskUseCase) *Handler {
	return &Handler{useCase: useCase}
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.health)
	mux.HandleFunc("POST /v1/risk/assessments", h.assessAction)
	mux.HandleFunc("GET /v1/admin/fraud-blocks", h.listFraudBlocks)
	mux.HandleFunc("POST /v1/admin/fraud-blocks/{assessmentID}/review", h.reviewFraudBlock)
}

func Chain(cfg *config.Config, next http.Handler) http.Handler {
	return withInternalAuth(cfg, next)
}

type assessActionRequest struct {
	Action         string            `json:"action"`
	ActorUserID    *uuid.UUID        `json:"actorUserId,omitempty"`
	SubjectType    string            `json:"subjectType,omitempty"`
	SubjectID      *uuid.UUID        `json:"subjectId,omitempty"`
	SourceService  string            `json:"sourceService,omitempty"`
	IdempotencyKey string            `json:"idempotencyKey,omitempty"`
	SignalHashes   map[string]string `json:"signalHashes,omitempty"`
	AmountMinor    *int64            `json:"amountMinor,omitempty"`
	Currency       string            `json:"currency,omitempty"`
	Metadata       map[string]any    `json:"metadata,omitempty"`
}

type reviewFraudBlockRequest struct {
	Status            string    `json:"status"`
	ReviewedByStaffID uuid.UUID `json:"reviewedByStaffId"`
	ReasonCodes       []string  `json:"reasonCodes,omitempty"`
	Comment           string    `json:"comment"`
}

func (h *Handler) health(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{
		"status": "ok",
		"time":   time.Now().UTC().Format(time.RFC3339),
	})
}

func (h *Handler) assessAction(w http.ResponseWriter, r *http.Request) {
	if h.useCase == nil {
		writeError(w, http.StatusServiceUnavailable, "anti-fraud service is not ready")
		return
	}

	var req assessActionRequest
	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	decision, err := h.useCase.AssessAction(r.Context(), app.AssessActionInput{
		Action:         req.Action,
		ActorUserID:    req.ActorUserID,
		SubjectType:    req.SubjectType,
		SubjectID:      req.SubjectID,
		SourceService:  req.SourceService,
		IdempotencyKey: req.IdempotencyKey,
		SignalHashes:   req.SignalHashes,
		AmountMinor:    req.AmountMinor,
		Currency:       req.Currency,
		Metadata:       req.Metadata,
	})
	if err != nil {
		writeError(w, statusFromError(err), "risk assessment failed")
		return
	}

	writeJSON(w, http.StatusOK, decision)
}

func (h *Handler) listFraudBlocks(w http.ResponseWriter, r *http.Request) {
	if h.useCase == nil {
		writeError(w, http.StatusServiceUnavailable, "anti-fraud service is not ready")
		return
	}
	limit, offset := paginationQuery(r)
	items, err := h.useCase.ListFraudBlocks(r.Context(), app.ListFraudBlocksInput{
		TargetType: app.FraudBlockTarget(modelCode(r.URL.Query().Get("targetType"))),
		Limit:      limit,
		Offset:     offset,
	})
	if err != nil {
		writeError(w, statusFromError(err), "list fraud blocks failed")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"items": items,
	})
}

func (h *Handler) reviewFraudBlock(w http.ResponseWriter, r *http.Request) {
	if h.useCase == nil {
		writeError(w, http.StatusServiceUnavailable, "anti-fraud service is not ready")
		return
	}
	assessmentID, err := uuid.Parse(strings.TrimSpace(r.PathValue("assessmentID")))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid assessment id")
		return
	}
	var req reviewFraudBlockRequest
	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()
	if err = decoder.Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	item, err := h.useCase.ReviewFraudBlock(r.Context(), app.ReviewFraudBlockInput{
		AssessmentID:      assessmentID,
		Status:            riskReviewStatus(req.Status),
		ReviewedByStaffID: req.ReviewedByStaffID,
		ReasonCodes:       req.ReasonCodes,
		Comment:           req.Comment,
	})
	if err != nil {
		writeError(w, statusFromError(err), "review fraud block failed")
		return
	}
	writeJSON(w, http.StatusOK, item)
}

func withInternalAuth(cfg *config.Config, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/health" {
			next.ServeHTTP(w, r)
			return
		}

		expected := ""
		if cfg != nil {
			expected = strings.TrimSpace(cfg.Security.InternalServiceToken)
		}
		if expected == "" {
			writeError(w, http.StatusServiceUnavailable, "internal auth is not configured")
			return
		}

		if bearerToken(r.Header.Get("Authorization")) != expected {
			writeError(w, http.StatusUnauthorized, "unauthorized")
			return
		}

		next.ServeHTTP(w, r)
	})
}

func bearerToken(header string) string {
	parts := strings.Fields(header)
	if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
		return ""
	}
	return parts[1]
}

func modelCode(value string) string {
	return strings.ToUpper(strings.TrimSpace(value))
}

func riskReviewStatus(value string) model.RiskReviewStatus {
	return model.RiskReviewStatus(modelCode(value))
}

func paginationQuery(r *http.Request) (int, int) {
	limit := parsePositiveInt(r.URL.Query().Get("limit"), 100)
	offset := parsePositiveInt(r.URL.Query().Get("offset"), 0)
	if limit > 500 {
		limit = 500
	}
	return limit, offset
}

func parsePositiveInt(value string, fallback int) int {
	value = strings.TrimSpace(value)
	if value == "" {
		return fallback
	}
	n := 0
	for _, ch := range value {
		if ch < '0' || ch > '9' {
			return fallback
		}
		n = n*10 + int(ch-'0')
	}
	return n
}

func statusFromError(err error) int {
	if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
		return http.StatusRequestTimeout
	}
	if errors.Is(err, app.ErrInvalidInput) {
		return http.StatusBadRequest
	}
	if errors.Is(err, app.ErrNotConfigured) {
		return http.StatusServiceUnavailable
	}
	return http.StatusInternalServerError
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}
