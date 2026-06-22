package http

import (
	"context"
	"encoding/json"
	"net/http"

	"kz/inflap/backend/services/routing-service/internal/domain/model"
)

type routingUseCase interface {
	Status(context.Context) model.RoutingStatusResponse
	Route(context.Context, model.RouteRequest) (model.RouteResponse, error)
	ETA(context.Context, model.ETARequest) (model.ETAResponse, error)
	Matrix(context.Context, model.MatrixRequest) (model.MatrixResponse, error)
	Isochrone(context.Context, model.IsochroneRequest) (model.IsochroneResponse, error)
	OptimizeItinerary(context.Context, model.ItineraryOptimizationRequest) (model.ItineraryOptimizationResponse, error)
	MapMatch(context.Context, model.MapMatchRequest) (model.MapMatchResponse, error)
}

type Handler struct {
	uc routingUseCase
}

func NewHandler(uc routingUseCase) *Handler {
	return &Handler{uc: uc}
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.Health)
	mux.HandleFunc("GET /v1/status", h.Status)
	mux.HandleFunc("GET /v1/route-profiles", h.RouteProfiles)
	mux.HandleFunc("POST /v1/routes", h.Route)
	mux.HandleFunc("POST /v1/eta", h.ETA)
	mux.HandleFunc("POST /v1/matrix", h.Matrix)
	mux.HandleFunc("POST /v1/isochrones", h.Isochrone)
	mux.HandleFunc("POST /v1/itineraries/optimize", h.OptimizeItinerary)
	mux.HandleFunc("POST /v1/map-match", h.MapMatch)
	mux.HandleFunc("GET /", h.NotFound)
}

func (h *Handler) Health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (h *Handler) Status(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, h.uc.Status(r.Context()))
}

func (h *Handler) RouteProfiles(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, model.DefaultRouteProfiles())
}

func (h *Handler) Route(w http.ResponseWriter, r *http.Request) {
	var req model.RouteRequest
	if !h.decodeAndValidate(w, r, &req) {
		return
	}

	resp, err := h.uc.Route(r.Context(), req)
	if err != nil {
		writeAppError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) ETA(w http.ResponseWriter, r *http.Request) {
	var req model.ETARequest
	if !h.decodeAndValidate(w, r, &req) {
		return
	}

	resp, err := h.uc.ETA(r.Context(), req)
	if err != nil {
		writeAppError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) Matrix(w http.ResponseWriter, r *http.Request) {
	var req model.MatrixRequest
	if !h.decodeAndValidate(w, r, &req) {
		return
	}

	resp, err := h.uc.Matrix(r.Context(), req)
	if err != nil {
		writeAppError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) Isochrone(w http.ResponseWriter, r *http.Request) {
	var req model.IsochroneRequest
	if !h.decodeAndValidate(w, r, &req) {
		return
	}

	resp, err := h.uc.Isochrone(r.Context(), req)
	if err != nil {
		writeAppError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) OptimizeItinerary(w http.ResponseWriter, r *http.Request) {
	var req model.ItineraryOptimizationRequest
	if !h.decodeAndValidate(w, r, &req) {
		return
	}

	resp, err := h.uc.OptimizeItinerary(r.Context(), req)
	if err != nil {
		writeAppError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) MapMatch(w http.ResponseWriter, r *http.Request) {
	var req model.MapMatchRequest
	if !h.decodeAndValidate(w, r, &req) {
		return
	}

	resp, err := h.uc.MapMatch(r.Context(), req)
	if err != nil {
		writeAppError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) NotFound(w http.ResponseWriter, r *http.Request) {
	writeBusinessError(w, r, http.StatusNotFound, errorCodeRouteNotFound)
}

type normalizable interface {
	NormalizeAndValidate() error
}

func (h *Handler) decodeAndValidate(w http.ResponseWriter, r *http.Request, dst normalizable) bool {
	if err := decodeBody(r, dst); err != nil {
		writeErrorResponse(w, http.StatusBadRequest, errorCodeInvalidRequest, errorKindBusiness, parseErrorLang(r))
		return false
	}
	if err := dst.NormalizeAndValidate(); err != nil {
		writeAppError(w, r, err)
		return false
	}
	return true
}

func decodeBody(r *http.Request, dst any) error {
	decoder := json.NewDecoder(http.MaxBytesReader(nil, r.Body, 1<<20))
	decoder.DisallowUnknownFields()
	return decoder.Decode(dst)
}

func writeJSON(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}
