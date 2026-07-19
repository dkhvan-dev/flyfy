package http

import (
	"encoding/json"
	"errors"
	"math"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

const invalidArgumentCode = "INVALID_ARGUMENT"

type errorEnvelope struct {
	Code         string `json:"code"`
	Retryable    bool   `json:"retryable"`
	RetryAfterMS *int64 `json:"retry_after_ms,omitempty"`
	RequestID    string `json:"request_id,omitempty"`
}

func writeOperationResult(
	w http.ResponseWriter,
	r *http.Request,
	receipt *domain.SavedOperation,
	currentResourceSnapshot any,
	now time.Time,
) error {
	response, err := mapOperationResult(receipt, currentResourceSnapshot)
	if err != nil {
		return err
	}

	status := http.StatusOK
	if receipt.Status() == domain.OperationStatusPending {
		status = http.StatusAccepted
		if retryAfter := pendingRetryAfterSeconds(receipt.CommitDeadline(), now); retryAfter != nil {
			w.Header().Set("Retry-After", *retryAfter)
		}
	}
	writePersonalJSON(w, r, status, response)
	return nil
}

func writeDomainError(w http.ResponseWriter, r *http.Request, err error) {
	var domainError *domain.DomainError
	if !errors.As(err, &domainError) || domainError == nil || !domainError.Code.IsValid() {
		writeErrorEnvelope(w, r, http.StatusServiceUnavailable, string(domain.ErrorCodeTemporarilyUnavailable), true, nil)
		return
	}

	status := statusForDomainError(domainError.Code)
	writeErrorEnvelope(
		w,
		r,
		status,
		string(domainError.Code),
		domainError.Retryable,
		boundedRetryAfterMS(domainError.RetryAfterMS),
	)
}

func writeInvalidArgument(w http.ResponseWriter, r *http.Request) {
	writeErrorEnvelope(w, r, http.StatusBadRequest, invalidArgumentCode, false, nil)
}

func writeNotFound(w http.ResponseWriter, r *http.Request) {
	writeErrorEnvelope(w, r, http.StatusNotFound, "NOT_FOUND", false, nil)
}

func writeErrorEnvelope(
	w http.ResponseWriter,
	r *http.Request,
	status int,
	code string,
	retryable bool,
	retryAfterMS *int64,
) {
	requestID := personalRequestID(r)
	if retryAfterMS != nil && (status == http.StatusTooManyRequests || status == http.StatusServiceUnavailable) {
		seconds := int64(math.Ceil(float64(*retryAfterMS) / float64(time.Second/time.Millisecond)))
		if seconds < 0 {
			seconds = 0
		}
		if seconds > 30 {
			seconds = 30
		}
		w.Header().Set("Retry-After", formatSmallInt(seconds))
	}
	writePersonalJSON(w, r, status, errorEnvelope{
		Code:         code,
		Retryable:    retryable,
		RetryAfterMS: retryAfterMS,
		RequestID:    requestID,
	})
}

func writePersonalJSON(w http.ResponseWriter, r *http.Request, status int, body any) {
	requestID := personalRequestID(r)
	w.Header().Set("Cache-Control", "private, no-store")
	w.Header().Set("Content-Language", effectiveErrorLocale(r.Header.Get("Accept-Language")))
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Pragma", "no-cache")
	w.Header().Set("Vary", "Authorization, Accept-Language")
	w.Header().Set(HeaderRequestID, requestID)
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}

func personalRequestID(r *http.Request) string {
	if r != nil {
		if principal, ok := PersonalPrincipalFromContext(r.Context()); ok &&
			principal.RequestID != "" && len(principal.RequestID) <= 128 &&
			principal.RequestID == strings.TrimSpace(principal.RequestID) &&
			!containsControl(principal.RequestID) {
			return principal.RequestID
		}
		candidate := r.Header.Get(HeaderRequestID)
		if candidate != "" && len(candidate) <= 128 && candidate == strings.TrimSpace(candidate) && !containsControl(candidate) {
			return candidate
		}
	}
	return uuid.NewString()
}

func statusForDomainError(code domain.ErrorCode) int {
	switch code {
	case domain.ErrorCodePlatformPersonalDataLocked:
		return http.StatusForbidden
	case domain.ErrorCodeCollectionNotFound:
		return http.StatusNotFound
	case domain.ErrorCodeMutationStale,
		domain.ErrorCodeReplayMismatch,
		domain.ErrorCodeCollectionDeleted,
		domain.ErrorCodeCollectionTitleConflict,
		domain.ErrorCodeRequestInProgress:
		return http.StatusConflict
	case domain.ErrorCodeTargetTypeUnsupported,
		domain.ErrorCodeTargetUnavailable,
		domain.ErrorCodeCollectionTitleInvalid,
		domain.ErrorCodeCollectionLimitReached,
		domain.ErrorCodeCollectionItemLimitReached,
		domain.ErrorCodeMembershipLimitReached,
		domain.ErrorCodeItemLimitReached:
		return http.StatusUnprocessableEntity
	case domain.ErrorCodeCursorInvalid:
		return http.StatusBadRequest
	case domain.ErrorCodeRateLimited:
		return http.StatusTooManyRequests
	case domain.ErrorCodeDependencyUnavailable,
		domain.ErrorCodeTemporarilyUnavailable:
		return http.StatusServiceUnavailable
	case domain.ErrorCodeOperationExpired:
		return http.StatusNotFound
	default:
		return http.StatusServiceUnavailable
	}
}

func boundedRetryAfterMS(value *int64) *int64 {
	if value == nil {
		return nil
	}
	bounded := *value
	if bounded < 0 {
		bounded = 0
	}
	if bounded > 86_400_000 {
		bounded = 86_400_000
	}
	return &bounded
}

func pendingRetryAfterSeconds(deadline, now time.Time) *string {
	if deadline.IsZero() || now.IsZero() || !deadline.After(now) {
		return nil
	}
	seconds := int64(math.Ceil(deadline.Sub(now).Seconds()))
	if seconds < 1 {
		seconds = 1
	}
	if seconds > 30 {
		seconds = 30
	}
	formatted := formatSmallInt(seconds)
	return &formatted
}

func formatSmallInt(value int64) string {
	if value == 0 {
		return "0"
	}
	var buffer [20]byte
	position := len(buffer)
	for value > 0 {
		position--
		buffer[position] = byte('0' + value%10)
		value /= 10
	}
	return string(buffer[position:])
}
