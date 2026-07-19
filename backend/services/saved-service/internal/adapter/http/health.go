package http

import (
	"context"
	"encoding/json"
	"net/http"
	"time"
)

type DatabasePinger interface {
	Ping(context.Context) error
}

type HealthHandler struct {
	database         DatabasePinger
	readinessTimeout time.Duration
}

func NewHealthHandler(database DatabasePinger, readinessTimeout time.Duration) *HealthHandler {
	return &HealthHandler{
		database:         database,
		readinessTimeout: readinessTimeout,
	}
}

func (h *HealthHandler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.Health)
	mux.HandleFunc("GET /ready", h.Ready)
}

func (h *HealthHandler) Health(w http.ResponseWriter, _ *http.Request) {
	writeHealthStatus(w, http.StatusOK, "ok")
}

func (h *HealthHandler) Ready(w http.ResponseWriter, r *http.Request) {
	if h.database == nil {
		writeHealthStatus(w, http.StatusServiceUnavailable, "not_ready")
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), h.readinessTimeout)
	defer cancel()
	if err := h.database.Ping(ctx); err != nil {
		writeHealthStatus(w, http.StatusServiceUnavailable, "not_ready")
		return
	}
	writeHealthStatus(w, http.StatusOK, "ok")
}

func writeHealthStatus(w http.ResponseWriter, status int, value string) {
	w.Header().Set("Cache-Control", "no-store")
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(map[string]string{"status": value})
}
