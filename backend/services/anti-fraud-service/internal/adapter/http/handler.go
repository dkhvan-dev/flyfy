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

func statusFromError(err error) int {
	if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
		return http.StatusRequestTimeout
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
