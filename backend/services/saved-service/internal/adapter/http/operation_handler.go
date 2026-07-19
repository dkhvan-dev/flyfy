package http

import (
	"context"
	"errors"
	"net/http"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/app/saveditem"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

var ErrInvalidOperationHandlerDependencies = errors.New("invalid operation handler dependencies")

type OperationReader interface {
	GetOperation(context.Context, saveditem.OperationLookup) (*domain.SavedOperation, error)
}

type ResponseClock interface {
	Now() time.Time
}

type systemResponseClock struct{}

func (systemResponseClock) Now() time.Time { return time.Now().UTC() }

type OperationHandler struct {
	reader OperationReader
	clock  ResponseClock
}

func NewOperationHandler(reader OperationReader, clock ResponseClock) (*OperationHandler, error) {
	if reader == nil {
		return nil, ErrInvalidOperationHandlerDependencies
	}
	if clock == nil {
		clock = systemResponseClock{}
	}
	return &OperationHandler{reader: reader, clock: clock}, nil
}

func (h *OperationHandler) Register(mux *http.ServeMux) error {
	if h == nil || h.reader == nil || h.clock == nil || mux == nil {
		return ErrInvalidOperationHandlerDependencies
	}
	mux.HandleFunc("GET /v1/users/me/saved-operations/{operationId}", h.Get)
	return nil
}

func (h *OperationHandler) Get(w http.ResponseWriter, r *http.Request) {
	principal, ok := PersonalPrincipalFromContext(r.Context())
	if !ok {
		writePersonalAuthError(w, r, "UNAUTHENTICATED")
		return
	}

	operationID, err := parseCanonicalOperationID(r.PathValue("operationId"))
	if err != nil {
		writeInvalidArgument(w, r)
		return
	}
	serverNow := h.clock.Now().UTC()
	receipt, err := h.reader.GetOperation(r.Context(), saveditem.OperationLookup{
		SubjectID:         principal.Subject,
		SessionGeneration: principal.SessionGeneration,
		OperationID:       operationID,
		ServerNow:         serverNow,
	})
	if err != nil {
		switch {
		case errors.Is(err, saveditem.ErrOperationNotFound):
			writeNotFound(w, r)
		case errors.Is(err, saveditem.ErrInvalidCommand):
			writeInvalidArgument(w, r)
		default:
			writeDomainError(w, r, domain.ErrTemporarilyUnavailable)
		}
		return
	}
	if receipt == nil {
		writeDomainError(w, r, domain.ErrTemporarilyUnavailable)
		return
	}
	if err := writeOperationResult(w, r, receipt, nil, serverNow); err != nil {
		writeDomainError(w, r, domain.ErrTemporarilyUnavailable)
	}
}

func parseCanonicalOperationID(value string) (uuid.UUID, error) {
	parsed, err := uuid.Parse(value)
	if err != nil || parsed == uuid.Nil || parsed.Version() != 4 ||
		parsed.Variant() != uuid.RFC4122 || parsed.String() != value {
		return uuid.Nil, saveditem.ErrInvalidCommand
	}
	return parsed, nil
}
