package http

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/app/savedmaintenance"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

const maxSubjectPurgeBodyBytes = 8 * 1024

var ErrInvalidSubjectPurgeHandlerDependencies = errors.New("invalid subject purge handler dependencies")

type SubjectPurgeUseCase interface {
	StartSubjectPurge(context.Context, savedmaintenance.SubjectPurgeStart) (savedmaintenance.SubjectPurgeJob, error)
	SubjectPurge(context.Context, uuid.UUID) (savedmaintenance.SubjectPurgeJob, error)
}

// SubjectPurgeHandler belongs only on the internal mTLS listener. It must never
// be registered on the public/Gateway listener.
type SubjectPurgeHandler struct {
	useCase             SubjectPurgeUseCase
	allowedCallerSPIFFE string
}

func NewSubjectPurgeHandler(
	useCase SubjectPurgeUseCase,
	allowedCallerSPIFFE string,
) (*SubjectPurgeHandler, error) {
	parsedSPIFFE, err := url.Parse(allowedCallerSPIFFE)
	if useCase == nil || allowedCallerSPIFFE != strings.TrimSpace(allowedCallerSPIFFE) ||
		err != nil || parsedSPIFFE == nil || parsedSPIFFE.Scheme != "spiffe" || parsedSPIFFE.Host == "" ||
		parsedSPIFFE.User != nil || parsedSPIFFE.RawQuery != "" || parsedSPIFFE.Fragment != "" {
		return nil, ErrInvalidSubjectPurgeHandlerDependencies
	}
	return &SubjectPurgeHandler{
		useCase:             useCase,
		allowedCallerSPIFFE: allowedCallerSPIFFE,
	}, nil
}

func (handler *SubjectPurgeHandler) Register(mux *http.ServeMux) error {
	if handler == nil || handler.useCase == nil || handler.allowedCallerSPIFFE == "" || mux == nil {
		return ErrInvalidSubjectPurgeHandlerDependencies
	}
	base := "/internal/v1/compliance/saved-subject-purges"
	mux.HandleFunc("POST "+base, handler.Start)
	mux.HandleFunc("GET "+base+"/{operationId}", handler.Get)
	return nil
}

func (handler *SubjectPurgeHandler) Start(w http.ResponseWriter, request *http.Request) {
	if !isVerifiedInternalMTLSRequest(request, handler.allowedCallerSPIFFE) || !emptyQuery(request) {
		writeInternalPurgeError(w, request, http.StatusForbidden, "FORBIDDEN", false)
		return
	}
	var body struct {
		OperationID  string `json:"operation_id"`
		Subject      string `json:"subject"`
		OwnerUserID  string `json:"owner_user_id"`
		WritesFenced bool   `json:"writes_fenced"`
	}
	if err := DecodeBoundedJSON(w, request, maxSubjectPurgeBodyBytes, &body); err != nil {
		writeInternalPurgeError(w, request, http.StatusBadRequest, invalidArgumentCode, false)
		return
	}
	operationID, err := parseUUIDv4(body.OperationID)
	if err != nil {
		writeInternalPurgeError(w, request, http.StatusBadRequest, invalidArgumentCode, false)
		return
	}
	ownerUserID, err := parseCanonicalUUID(body.OwnerUserID)
	if err != nil {
		writeInternalPurgeError(w, request, http.StatusBadRequest, invalidArgumentCode, false)
		return
	}
	job, err := handler.useCase.StartSubjectPurge(request.Context(), savedmaintenance.SubjectPurgeStart{
		OperationID:  operationID,
		Subject:      body.Subject,
		OwnerUserID:  ownerUserID,
		WritesFenced: body.WritesFenced,
	})
	if err != nil {
		writeSubjectPurgeUseCaseError(w, request, err)
		return
	}
	writeInternalJSON(w, request, http.StatusAccepted, mapSubjectPurgeJob(job))
}

func (handler *SubjectPurgeHandler) Get(w http.ResponseWriter, request *http.Request) {
	if !isVerifiedInternalMTLSRequest(request, handler.allowedCallerSPIFFE) || !emptyQuery(request) {
		writeInternalPurgeError(w, request, http.StatusForbidden, "FORBIDDEN", false)
		return
	}
	operationID, err := parseUUIDv4(request.PathValue("operationId"))
	if err != nil {
		writeInternalPurgeError(w, request, http.StatusBadRequest, invalidArgumentCode, false)
		return
	}
	job, err := handler.useCase.SubjectPurge(request.Context(), operationID)
	if err != nil {
		writeSubjectPurgeUseCaseError(w, request, err)
		return
	}
	writeInternalJSON(w, request, http.StatusOK, mapSubjectPurgeJob(job))
}

type subjectPurgeJobResponse struct {
	OperationID        string                             `json:"operation_id"`
	Phase              savedmaintenance.SubjectPurgePhase `json:"phase"`
	AttemptCount       int                                `json:"attempt_count"`
	NextAttemptAt      *time.Time                         `json:"next_attempt_at,omitempty"`
	CreatedAt          time.Time                          `json:"created_at"`
	UpdatedAt          time.Time                          `json:"updated_at"`
	CompletedAt        *time.Time                         `json:"completed_at,omitempty"`
	RetentionExpiresAt *time.Time                         `json:"retention_expires_at,omitempty"`
}

func mapSubjectPurgeJob(job savedmaintenance.SubjectPurgeJob) subjectPurgeJobResponse {
	return subjectPurgeJobResponse{
		OperationID:        job.OperationID.String(),
		Phase:              job.Phase,
		AttemptCount:       job.AttemptCount,
		NextAttemptAt:      utcTimePointer(job.NextAttemptAt),
		CreatedAt:          job.CreatedAt.UTC(),
		UpdatedAt:          job.UpdatedAt.UTC(),
		CompletedAt:        utcTimePointer(job.CompletedAt),
		RetentionExpiresAt: utcTimePointer(job.RetentionExpiresAt),
	}
}

func utcTimePointer(value *time.Time) *time.Time {
	if value == nil {
		return nil
	}
	utc := value.UTC()
	return &utc
}

func isVerifiedInternalMTLSRequest(request *http.Request, allowedCallerSPIFFE string) bool {
	if request == nil || request.TLS == nil || !request.TLS.HandshakeComplete ||
		len(request.TLS.VerifiedChains) == 0 || allowedCallerSPIFFE == "" {
		return false
	}
	for _, chain := range request.TLS.VerifiedChains {
		if len(chain) == 0 {
			continue
		}
		for _, identity := range chain[0].URIs {
			if identity != nil && identity.String() == allowedCallerSPIFFE {
				return true
			}
		}
	}
	return false
}

func writeSubjectPurgeUseCaseError(w http.ResponseWriter, request *http.Request, err error) {
	switch {
	case errors.Is(err, savedmaintenance.ErrInvalidSubjectPurge):
		writeInternalPurgeError(w, request, http.StatusBadRequest, invalidArgumentCode, false)
	case errors.Is(err, savedmaintenance.ErrSubjectPurgeIdentityClash):
		writeInternalPurgeError(w, request, http.StatusConflict, "SUBJECT_PURGE_IDENTITY_CONFLICT", false)
	case errors.Is(err, savedmaintenance.ErrSubjectPurgeNotFound):
		writeInternalPurgeError(w, request, http.StatusNotFound, "NOT_FOUND", false)
	default:
		writeInternalPurgeError(
			w,
			request,
			http.StatusServiceUnavailable,
			string(domain.ErrorCodeTemporarilyUnavailable),
			true,
		)
	}
}

func writeInternalPurgeError(
	w http.ResponseWriter,
	request *http.Request,
	status int,
	code string,
	retryable bool,
) {
	writeInternalJSON(w, request, status, errorEnvelope{
		Code:      code,
		Retryable: retryable,
		RequestID: personalRequestID(request),
	})
}

func writeInternalJSON(w http.ResponseWriter, request *http.Request, status int, body any) {
	w.Header().Set("Cache-Control", "no-store")
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Pragma", "no-cache")
	w.Header().Set(HeaderRequestID, personalRequestID(request))
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}
