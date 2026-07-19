package media

import (
	"errors"
	"fmt"
	"net/url"
	"strconv"
	"strings"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

var (
	ErrInvalidOrigin    = errors.New("invalid Saved public API origin")
	ErrInvalidReference = errors.New("invalid Saved media reference")
)

type Reference struct {
	Target            domain.SavedTarget
	OpaqueReference   string
	ReferenceRevision uint64
}

type RouteResolver struct {
	origin url.URL
}

func NewRouteResolver(origin string) (*RouteResolver, error) {
	parsed, err := url.Parse(origin)
	if err != nil || parsed.Host == "" || parsed.User != nil || parsed.RawQuery != "" ||
		parsed.Fragment != "" || (parsed.Path != "" && parsed.Path != "/") ||
		(parsed.Scheme != "https" && parsed.Scheme != "http") {
		return nil, ErrInvalidOrigin
	}
	parsed.Path = ""
	return &RouteResolver{origin: *parsed}, nil
}

func (resolver *RouteResolver) Resolve(reference Reference) (string, error) {
	if resolver == nil || resolver.origin.Host == "" || reference.Target.IsZero() ||
		reference.ReferenceRevision == 0 || reference.OpaqueReference == "" ||
		len(reference.OpaqueReference) > 2048 ||
		reference.OpaqueReference != strings.TrimSpace(reference.OpaqueReference) {
		return "", ErrInvalidReference
	}
	entityID, err := canonicalUUID(reference.Target.EntityID())
	if err != nil {
		return "", ErrInvalidReference
	}

	var path string
	switch reference.Target.EntityType() {
	case domain.EntityTypeActivity:
		if !validActivityReference(reference, entityID) {
			return "", ErrInvalidReference
		}
		path = "/api/v1/activities/" + entityID + "/cover"
	case domain.EntityTypeAttraction:
		if !validAttractionReference(reference, entityID) {
			return "", ErrInvalidReference
		}
		path = "/api/v1/places/" + entityID + "/saved-cover"
	case domain.EntityTypeGuide:
		if !validGuideReference(reference, entityID) {
			return "", ErrInvalidReference
		}
		path = "/api/v1/guides/public/by-user/" + entityID + "/saved-avatar"
	case domain.EntityTypeUser:
		avatarFileID, valid := validUserReference(reference, entityID)
		if !valid {
			return "", ErrInvalidReference
		}
		path = "/api/v1/public/files/" + avatarFileID + "/content"
	case domain.EntityTypePost:
		coverFileID, valid := validPostReference(reference, entityID)
		if !valid {
			return "", ErrInvalidReference
		}
		path = "/api/v1/public/files/" + coverFileID + "/content"
	default:
		return "", ErrInvalidReference
	}

	resolved := resolver.origin
	resolved.Path = path
	query := url.Values{}
	query.Set("saved_revision", strconv.FormatUint(reference.ReferenceRevision, 10))
	resolved.RawQuery = query.Encode()
	value := resolved.String()
	if len(value) > 2048 {
		return "", ErrInvalidReference
	}
	return value, nil
}

func validActivityReference(reference Reference, entityID string) bool {
	parsed, err := url.ParseRequestURI(reference.OpaqueReference)
	if err != nil || parsed.IsAbs() || parsed.Host != "" || parsed.Fragment != "" ||
		parsed.Path != "/api/v1/activities/"+entityID+"/cover" {
		return false
	}
	return exactRevisionQuery(parsed.Query(), reference.ReferenceRevision)
}

func validAttractionReference(reference Reference, entityID string) bool {
	parts := strings.Split(reference.OpaqueReference, ":")
	if len(parts) != 3 || parts[0] != "attraction-cover" || parts[1] != entityID {
		return false
	}
	return exactRevision(parts[2], reference.ReferenceRevision)
}

func validGuideReference(reference Reference, entityID string) bool {
	parts := strings.Split(reference.OpaqueReference, ":")
	if len(parts) != 4 || parts[0] != "guide-avatar" || parts[1] != entityID {
		return false
	}
	if _, err := canonicalUUID(parts[2]); err != nil {
		return false
	}
	return exactRevision(parts[3], reference.ReferenceRevision)
}

func validUserReference(reference Reference, entityID string) (string, bool) {
	parts := strings.Split(reference.OpaqueReference, ":")
	if len(parts) != 4 || parts[0] != "user-avatar" || parts[1] != entityID {
		return "", false
	}
	avatarFileID, err := canonicalUUID(parts[2])
	if err != nil || !exactRevision(parts[3], reference.ReferenceRevision) {
		return "", false
	}
	return avatarFileID, true
}

func validPostReference(reference Reference, entityID string) (string, bool) {
	parts := strings.Split(reference.OpaqueReference, ":")
	if len(parts) != 4 || parts[0] != "post-cover" || parts[1] != entityID {
		return "", false
	}
	coverFileID, err := canonicalUUID(parts[2])
	if err != nil || !exactRevision(parts[3], reference.ReferenceRevision) {
		return "", false
	}
	return coverFileID, true
}

func exactRevisionQuery(query url.Values, expected uint64) bool {
	if len(query) != 1 {
		return false
	}
	values, exists := query["saved_revision"]
	return exists && len(values) == 1 && exactRevision(values[0], expected)
}

func exactRevision(value string, expected uint64) bool {
	parsed, err := strconv.ParseUint(value, 10, 64)
	return err == nil && parsed == expected && value == strconv.FormatUint(parsed, 10)
}

func canonicalUUID(value string) (string, error) {
	parsed, err := uuid.Parse(value)
	if err != nil || parsed == uuid.Nil || parsed.String() != value {
		return "", fmt.Errorf("%w: non-canonical target", ErrInvalidReference)
	}
	return value, nil
}
