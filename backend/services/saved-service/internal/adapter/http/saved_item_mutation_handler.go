package http

import (
	"context"
	"errors"
	"net/http"

	"kz/inflap/backend/services/saved-service/internal/app/saveditem"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

var ErrInvalidSavedItemMutationHandlerDependencies = errors.New("invalid saved item mutation handler dependencies")

type SavedItemMutationUseCase interface {
	Save(context.Context, saveditem.TargetMutationRequest) (*domain.SavedOperation, error)
	GlobalUnsave(context.Context, saveditem.TargetMutationRequest) (*domain.SavedOperation, error)
}

type SavedItemMutationHandler struct {
	useCase SavedItemMutationUseCase
	clock   ResponseClock
}

func NewSavedItemMutationHandler(
	useCase SavedItemMutationUseCase,
	clock ResponseClock,
) (*SavedItemMutationHandler, error) {
	if useCase == nil {
		return nil, ErrInvalidSavedItemMutationHandlerDependencies
	}
	if clock == nil {
		clock = systemResponseClock{}
	}
	return &SavedItemMutationHandler{useCase: useCase, clock: clock}, nil
}

func (h *SavedItemMutationHandler) Register(mux *http.ServeMux) error {
	if h == nil || h.useCase == nil || h.clock == nil || mux == nil {
		return ErrInvalidSavedItemMutationHandlerDependencies
	}
	pattern := "/v1/users/me/saved-items/{entityType}/{entityKey}"
	mux.HandleFunc("PUT "+pattern, h.Save)
	mux.HandleFunc("DELETE "+pattern, h.GlobalUnsave)
	return nil
}

func (h *SavedItemMutationHandler) Save(w http.ResponseWriter, r *http.Request) {
	h.handle(w, r, h.useCase.Save, true)
}

func (h *SavedItemMutationHandler) GlobalUnsave(w http.ResponseWriter, r *http.Request) {
	h.handle(w, r, h.useCase.GlobalUnsave, false)
}

func (h *SavedItemMutationHandler) handle(
	w http.ResponseWriter,
	r *http.Request,
	execute func(context.Context, saveditem.TargetMutationRequest) (*domain.SavedOperation, error),
	expands bool,
) {
	principal, ok := PersonalPrincipalFromContext(r.Context())
	if !ok {
		writePersonalAuthError(w, r, "UNAUTHENTICATED")
		return
	}
	if err := RequireEmptyBody(w, r); err != nil {
		writeInvalidArgument(w, r)
		return
	}
	identity, err := ParseMutationIdentity(r.Header)
	if err != nil {
		writeInvalidArgument(w, r)
		return
	}
	surface, err := ParseSourceSurface(r.Header)
	if err != nil {
		writeInvalidArgument(w, r)
		return
	}
	target, err := ParseSavedTargetPath(r)
	if err != nil {
		writeInvalidArgument(w, r)
		return
	}

	receipt, err := execute(r.Context(), saveditem.TargetMutationRequest{
		SubjectID:         principal.Subject,
		OwnerUserID:       principal.UserID,
		SessionGeneration: principal.SessionGeneration,
		OperationID:       identity.OperationID,
		IdempotencyKey:    identity.IdempotencyKey,
		Target:            target,
		SourceSurface:     surface,
		DisableExpansion:  expands && !savedTargetExpansionAllowed(r.Context(), target),
	})
	if err != nil {
		writeSavedMutationError(w, r, err)
		return
	}
	if err := writeOperationResult(w, r, receipt, nil, h.clock.Now().UTC()); err != nil {
		writeDomainError(w, r, domain.ErrTemporarilyUnavailable)
	}
}

func writeSavedMutationError(w http.ResponseWriter, r *http.Request, err error) {
	var domainError *domain.DomainError
	if errors.As(err, &domainError) {
		writeDomainError(w, r, domainError)
		return
	}
	if errors.Is(err, saveditem.ErrInvalidCommand) {
		writeInvalidArgument(w, r)
		return
	}
	writeDomainError(w, r, domain.ErrTemporarilyUnavailable)
}
