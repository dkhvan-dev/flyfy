package http

import (
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"regexp"
	"strings"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

const (
	HeaderOperationID    = "Operation-Id"
	HeaderIdempotencyKey = "Idempotency-Key"
	HeaderSourceSurface  = "Saved-Source-Surface"
	maxIdempotencyBytes  = 128
	minIdempotencyBytes  = 22
)

var (
	ErrInvalidMutationIdentity = errors.New("invalid Saved mutation identity")
	ErrInvalidSourceSurface    = errors.New("invalid Saved source surface")
	ErrInvalidJSONBody         = errors.New("invalid Saved JSON body")
	idempotencyKeyPattern      = regexp.MustCompile(`^[A-Za-z0-9_-]+$`)
)

type MutationIdentity struct {
	OperationID    uuid.UUID
	IdempotencyKey string
}

func ParseMutationIdentity(header http.Header) (MutationIdentity, error) {
	operationIDValue, ok := singleHeaderValue(header, HeaderOperationID)
	if !ok {
		return MutationIdentity{}, ErrInvalidMutationIdentity
	}
	operationID, err := uuid.Parse(operationIDValue)
	if err != nil || operationID == uuid.Nil || operationID.Version() != 4 || operationID.Variant() != uuid.RFC4122 {
		return MutationIdentity{}, ErrInvalidMutationIdentity
	}

	idempotencyKey, ok := singleHeaderValue(header, HeaderIdempotencyKey)
	if !ok {
		return MutationIdentity{}, ErrInvalidMutationIdentity
	}
	if len(idempotencyKey) < minIdempotencyBytes || len(idempotencyKey) > maxIdempotencyBytes ||
		idempotencyKey != strings.TrimSpace(idempotencyKey) || !idempotencyKeyPattern.MatchString(idempotencyKey) {
		return MutationIdentity{}, ErrInvalidMutationIdentity
	}
	padded := idempotencyKey + strings.Repeat("=", (4-len(idempotencyKey)%4)%4)
	decoded, err := base64.URLEncoding.DecodeString(padded)
	if err != nil || len(decoded) < 16 {
		return MutationIdentity{}, ErrInvalidMutationIdentity
	}
	clear(decoded)

	return MutationIdentity{OperationID: operationID, IdempotencyKey: idempotencyKey}, nil
}

func ParseSourceSurface(header http.Header) (domain.SourceSurface, error) {
	values := header.Values(HeaderSourceSurface)
	if len(values) == 0 {
		return domain.SourceSurfaceUnknown, nil
	}
	if len(values) != 1 {
		return "", ErrInvalidSourceSurface
	}
	surface := domain.SourceSurface(values[0])
	if values[0] != strings.TrimSpace(values[0]) || !surface.IsValid() {
		return "", ErrInvalidSourceSurface
	}
	return surface, nil
}

func singleHeaderValue(header http.Header, name string) (string, bool) {
	values := header.Values(name)
	returnValue := ""
	if len(values) == 1 {
		returnValue = values[0]
	}
	return returnValue, len(values) == 1
}

func ParseSavedTargetPath(request *http.Request) (domain.SavedTarget, error) {
	if request == nil {
		return domain.SavedTarget{}, domain.ErrTargetUnavailable
	}
	return domain.NewSavedTarget(
		domain.EntityType(request.PathValue("entityType")),
		request.PathValue("entityKey"),
	)
}

func DecodeBoundedJSON(w http.ResponseWriter, request *http.Request, maxBytes int64, destination any) error {
	if request == nil || request.Body == nil || maxBytes <= 0 || destination == nil {
		return ErrInvalidJSONBody
	}
	request.Body = http.MaxBytesReader(w, request.Body, maxBytes)
	decoder := json.NewDecoder(request.Body)
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(destination); err != nil {
		return fmt.Errorf("%w: %v", ErrInvalidJSONBody, safeJSONDecodeError(err))
	}
	if err := decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		return ErrInvalidJSONBody
	}
	return nil
}

func RequireEmptyBody(w http.ResponseWriter, request *http.Request) error {
	if request == nil || request.Body == nil {
		return nil
	}
	request.Body = http.MaxBytesReader(w, request.Body, 1)
	var probe [1]byte
	read, err := request.Body.Read(probe[:])
	if read != 0 || (err != nil && !errors.Is(err, io.EOF)) {
		return ErrInvalidJSONBody
	}
	return nil
}

func safeJSONDecodeError(err error) error {
	var maxBytesError *http.MaxBytesError
	if errors.As(err, &maxBytesError) {
		return errors.New("request body exceeds the configured limit")
	}
	var syntaxError *json.SyntaxError
	if errors.As(err, &syntaxError) {
		return errors.New("malformed JSON")
	}
	var typeError *json.UnmarshalTypeError
	if errors.As(err, &typeError) {
		return errors.New("invalid JSON field type")
	}
	return errors.New("invalid JSON document")
}
