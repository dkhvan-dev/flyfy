package http

import (
	"encoding/json"
	"errors"
	"net/http"

	"kz/inflap/backend/services/user-route-service/internal/app"
	"kz/inflap/backend/services/user-route-service/internal/domain/model"
)

type errorResponse struct {
	Code    string `json:"code"`
	Kind    string `json:"kind"`
	Message string `json:"message"`
}

func writeAppError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, app.ErrUserRouteAuthRequired):
		writeError(w, http.StatusUnauthorized, "user_route.authentication_required", "business", "Authentication required")
	case errors.Is(err, app.ErrUserRouteForbidden):
		writeError(w, http.StatusForbidden, "user_route.forbidden", "business", "Route update is forbidden")
	case errors.Is(err, app.ErrUserRouteNotFound):
		writeError(w, http.StatusNotFound, "user_route.not_found", "business", "Route not found")
	case errors.Is(err, app.ErrUserRouteInvalidDecision):
		writeError(w, http.StatusBadRequest, "user_route.invalid_review_decision", "business", "Invalid review decision")
	case errors.Is(err, app.ErrUserRouteReviewReasonRequired):
		writeError(w, http.StatusBadRequest, "user_route.review_reason_required", "business", "Review reason is required")
	case errors.Is(err, model.ErrInvalidUserRoute):
		writeError(w, http.StatusBadRequest, "user_route.invalid", "business", "Invalid user route")
	default:
		writeError(w, http.StatusInternalServerError, "user_route.technical", "technical", "User route service failed")
	}
}

func writeError(w http.ResponseWriter, status int, code string, kind string, message string) {
	writeJSON(w, status, errorResponse{
		Code:    code,
		Kind:    kind,
		Message: message,
	})
}

func writeJSON(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}
