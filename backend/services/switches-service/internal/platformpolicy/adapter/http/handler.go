package http

import (
	"bytes"
	"context"
	"crypto/subtle"
	"encoding/json"
	"errors"
	"io"
	"mime"
	nethttp "net/http"
	"strings"

	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/switches-service/internal/platformpolicy/app"
)

const (
	InternalDecisionPath = "/api/v1/internal/platform-policy/personal-data"
	AdminMutationPath    = "/api/v1/platform-policy/personal-data"
	maxMutationBodyBytes = 4 << 10
)

type policyService interface {
	ReadDecision(ctx context.Context) (app.Decision, error)
	ChangeState(ctx context.Context, command app.ChangeCommand) (app.Decision, error)
}

type AuthConfig struct {
	InternalServiceToken      string
	TrustedGatewayHeaderRoles string
	TrustedGatewayHeaderSub   string
}

type Handler struct {
	service              policyService
	internalServiceToken string
	rolesHeader          string
	subjectHeader        string
}

func NewHandler(service policyService, config AuthConfig) *Handler {
	return &Handler{
		service:              service,
		internalServiceToken: strings.TrimSpace(config.InternalServiceToken),
		rolesHeader:          valueOrDefault(config.TrustedGatewayHeaderRoles, "X-User-Roles"),
		subjectHeader:        valueOrDefault(config.TrustedGatewayHeaderSub, "X-Auth-Subject"),
	}
}

func (handler *Handler) Register(mux *nethttp.ServeMux) {
	mux.Handle(
		"GET "+InternalDecisionPath,
		handler.privateNoStore(handler.requireInternalToken(nethttp.HandlerFunc(handler.GetDecision))),
	)
	mux.Handle(
		"PUT "+AdminMutationPath,
		handler.privateNoStore(
			handler.trustedGatewayContext(
				handler.requireInternalToken(
					handler.requireAdmin(nethttp.HandlerFunc(handler.ChangeState)),
				),
			),
		),
	)
}

func (handler *Handler) GetDecision(writer nethttp.ResponseWriter, request *nethttp.Request) {
	if handler == nil || handler.service == nil {
		log.Error().Msg("platform policy read service is unavailable")
		writeError(writer, nethttp.StatusServiceUnavailable, "policy unavailable")
		return
	}
	decision, err := handler.service.ReadDecision(request.Context())
	if err != nil {
		log.Error().Err(err).Msg("platform policy read failed")
		writeError(writer, nethttp.StatusServiceUnavailable, "policy unavailable")
		return
	}
	writeJSON(writer, nethttp.StatusOK, decision)
}

type changeStateRequest struct {
	ExpectedRevision uint64    `json:"expected_revision"`
	State            app.State `json:"state"`
	Reason           string    `json:"reason"`
	ChangeTicket     string    `json:"change_ticket"`
}

func (handler *Handler) ChangeState(writer nethttp.ResponseWriter, request *nethttp.Request) {
	if handler == nil || handler.service == nil {
		log.Error().Msg("platform policy mutation service is unavailable")
		writeError(writer, nethttp.StatusServiceUnavailable, "policy unavailable")
		return
	}

	payload, err := decodeChangeStateRequest(writer, request)
	if err != nil {
		writeError(writer, nethttp.StatusBadRequest, "invalid request")
		return
	}
	actor := actorFromContext(request.Context())
	if actor == "" {
		writeError(writer, nethttp.StatusUnauthorized, "unauthorized")
		return
	}

	decision, err := handler.service.ChangeState(request.Context(), app.ChangeCommand{
		ExpectedRevision: payload.ExpectedRevision,
		State:            payload.State,
		Actor:            actor,
		Reason:           payload.Reason,
		ChangeTicket:     payload.ChangeTicket,
	})
	switch {
	case err == nil:
		writeJSON(writer, nethttp.StatusOK, decision)
	case errors.Is(err, app.ErrInvalidCommand):
		writeError(writer, nethttp.StatusBadRequest, "invalid request")
	case errors.Is(err, app.ErrRevisionConflict):
		writeError(writer, nethttp.StatusConflict, "policy revision conflict")
	case errors.Is(err, app.ErrStateUnchanged):
		writeError(writer, nethttp.StatusConflict, "policy state is unchanged")
	default:
		log.Error().Err(err).Msg("platform policy mutation failed")
		writeError(writer, nethttp.StatusServiceUnavailable, "policy unavailable")
	}
}

func decodeChangeStateRequest(writer nethttp.ResponseWriter, request *nethttp.Request) (changeStateRequest, error) {
	mediaType, _, err := mime.ParseMediaType(request.Header.Get("Content-Type"))
	if err != nil || mediaType != "application/json" {
		return changeStateRequest{}, errors.New("content type must be application/json")
	}

	request.Body = nethttp.MaxBytesReader(writer, request.Body, maxMutationBodyBytes)
	body, err := io.ReadAll(request.Body)
	if err != nil || len(body) == 0 {
		return changeStateRequest{}, errors.New("invalid request body")
	}
	if err = rejectDuplicateTopLevelKeys(body); err != nil {
		return changeStateRequest{}, err
	}

	decoder := json.NewDecoder(bytes.NewReader(body))
	decoder.DisallowUnknownFields()
	var payload changeStateRequest
	if err = decoder.Decode(&payload); err != nil {
		return changeStateRequest{}, err
	}
	if err = decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		return changeStateRequest{}, errors.New("request body must contain one JSON object")
	}
	return payload, nil
}

func rejectDuplicateTopLevelKeys(body []byte) error {
	decoder := json.NewDecoder(bytes.NewReader(body))
	token, err := decoder.Token()
	if err != nil {
		return err
	}
	delimiter, ok := token.(json.Delim)
	if !ok || delimiter != '{' {
		return errors.New("request body must be a JSON object")
	}

	seen := make(map[string]struct{}, 4)
	for decoder.More() {
		keyToken, keyErr := decoder.Token()
		if keyErr != nil {
			return keyErr
		}
		key, ok := keyToken.(string)
		if !ok {
			return errors.New("request body contains an invalid object key")
		}
		if _, duplicate := seen[key]; duplicate {
			return errors.New("request body contains a duplicate object key")
		}
		seen[key] = struct{}{}
		var value json.RawMessage
		if err = decoder.Decode(&value); err != nil {
			return err
		}
	}
	if _, err = decoder.Token(); err != nil {
		return err
	}
	if err = decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		return errors.New("request body must contain one JSON object")
	}
	return nil
}

func (handler *Handler) requireInternalToken(next nethttp.Handler) nethttp.Handler {
	return nethttp.HandlerFunc(func(writer nethttp.ResponseWriter, request *nethttp.Request) {
		provided, hasSingleToken := singleHeaderValue(request.Header, "X-Internal-Service-Token")
		if handler == nil || !hasSingleToken || handler.internalServiceToken == "" ||
			subtle.ConstantTimeCompare([]byte(provided), []byte(handler.internalServiceToken)) != 1 {
			writeError(writer, nethttp.StatusUnauthorized, "unauthorized")
			return
		}
		next.ServeHTTP(writer, request)
	})
}

func (handler *Handler) trustedGatewayContext(next nethttp.Handler) nethttp.Handler {
	return nethttp.HandlerFunc(func(writer nethttp.ResponseWriter, request *nethttp.Request) {
		rolesValue, hasSingleRolesHeader := singleHeaderValue(request.Header, handler.rolesHeader)
		subject, hasSingleSubject := singleHeaderValue(request.Header, handler.subjectHeader)
		roles := []string(nil)
		if hasSingleRolesHeader {
			roles = splitCSV(rolesValue)
		}
		if !hasSingleSubject {
			subject = ""
		}
		ctx := context.WithValue(request.Context(), rolesContextKey, roles)
		ctx = context.WithValue(ctx, actorContextKey, subject)
		next.ServeHTTP(writer, request.WithContext(ctx))
	})
}

func (handler *Handler) requireAdmin(next nethttp.Handler) nethttp.Handler {
	return nethttp.HandlerFunc(func(writer nethttp.ResponseWriter, request *nethttp.Request) {
		if !hasAdminRole(rolesFromContext(request.Context())) {
			writeError(writer, nethttp.StatusForbidden, "forbidden")
			return
		}
		next.ServeHTTP(writer, request)
	})
}

func (handler *Handler) privateNoStore(next nethttp.Handler) nethttp.Handler {
	return nethttp.HandlerFunc(func(writer nethttp.ResponseWriter, request *nethttp.Request) {
		writer.Header().Set("Cache-Control", "private, no-store, max-age=0, must-revalidate")
		writer.Header().Set("Pragma", "no-cache")
		writer.Header().Set("Expires", "0")
		writer.Header().Set("X-Content-Type-Options", "nosniff")
		next.ServeHTTP(writer, request)
	})
}

type contextKey string

const (
	rolesContextKey contextKey = "platform_policy_roles"
	actorContextKey contextKey = "platform_policy_actor"
)

func rolesFromContext(ctx context.Context) []string {
	roles, _ := ctx.Value(rolesContextKey).([]string)
	return roles
}

func actorFromContext(ctx context.Context) string {
	actor, _ := ctx.Value(actorContextKey).(string)
	return strings.TrimSpace(actor)
}

func hasAdminRole(roles []string) bool {
	for _, role := range roles {
		switch strings.ToUpper(strings.TrimSpace(role)) {
		case "ADMIN", "SUPER_ADMIN":
			return true
		}
	}
	return false
}

func splitCSV(raw string) []string {
	parts := strings.Split(raw, ",")
	result := make([]string, 0, len(parts))
	for _, part := range parts {
		if value := strings.TrimSpace(part); value != "" {
			result = append(result, value)
		}
	}
	return result
}

func singleHeaderValue(header nethttp.Header, name string) (string, bool) {
	values := header.Values(name)
	if len(values) != 1 {
		return "", false
	}
	return strings.TrimSpace(values[0]), true
}

func valueOrDefault(value string, fallback string) string {
	if strings.TrimSpace(value) == "" {
		return fallback
	}
	return strings.TrimSpace(value)
}

type errorResponse struct {
	Message string `json:"message"`
}

func writeJSON(writer nethttp.ResponseWriter, status int, payload any) {
	writer.Header().Set("Content-Type", "application/json")
	writer.WriteHeader(status)
	_ = json.NewEncoder(writer).Encode(payload)
}

func writeError(writer nethttp.ResponseWriter, status int, message string) {
	writeJSON(writer, status, errorResponse{Message: message})
}
