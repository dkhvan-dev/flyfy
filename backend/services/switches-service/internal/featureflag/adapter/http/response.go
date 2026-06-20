package http

import (
	"encoding/json"
	"errors"
	"net/http"

	"kz/inflap/backend/services/switches-service/internal/featureflag/app"
)

type errorResponse struct {
	Message string `json:"message"`
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, errorResponse{Message: message})
}

func writeAppError(w http.ResponseWriter, err error) {
	var appErr *app.AppError
	if errors.As(err, &appErr) {
		writeError(w, appErr.Status, appErr.Error())
		return
	}
	writeError(w, http.StatusInternalServerError, "internal server error")
}
