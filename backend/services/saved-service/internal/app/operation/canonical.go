package operation

import (
	"encoding/binary"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

const (
	semanticCanonicalDomain  = "inflap.saved.semantic-request\x00"
	semanticCanonicalVersion = byte(1)
	semanticLengthBytes      = 4
)

// canonicalSemanticRequest uses closed numeric discriminants and a
// length-prefixed opaque entity ID. The result is used only as transient HMAC
// input and must never be logged or persisted.
func canonicalSemanticRequest(kind domain.OperationKind, target domain.SavedTarget) ([]byte, error) {
	if kind != domain.OperationKindSave && kind != domain.OperationKindUnsave {
		return nil, domain.ErrMutationStale
	}
	kindCode, err := canonicalOperationKindCode(kind)
	if err != nil {
		return nil, err
	}

	entityTypeCode, err := canonicalEntityTypeCode(target.EntityType())
	if err != nil {
		return nil, err
	}
	if target.IsZero() {
		return nil, domain.ErrTargetUnavailable
	}

	entityID := target.EntityID()
	headerLength := len(semanticCanonicalDomain) + 3 + semanticLengthBytes
	canonical := make([]byte, headerLength+len(entityID))

	offset := copy(canonical, semanticCanonicalDomain)
	canonical[offset] = semanticCanonicalVersion
	offset++
	canonical[offset] = kindCode
	offset++
	canonical[offset] = entityTypeCode
	offset++
	binary.BigEndian.PutUint32(canonical[offset:offset+semanticLengthBytes], uint32(len(entityID)))
	offset += semanticLengthBytes
	copy(canonical[offset:], entityID)

	return canonical, nil
}

func canonicalOperationKindCode(kind domain.OperationKind) (byte, error) {
	switch kind {
	case domain.OperationKindSave:
		return 1, nil
	case domain.OperationKindUnsave:
		return 2, nil
	case domain.OperationKindSetTargetCollections:
		return 3, nil
	case domain.OperationKindCreateCollection:
		return 4, nil
	case domain.OperationKindRenameCollection:
		return 5, nil
	case domain.OperationKindDeleteCollection:
		return 6, nil
	default:
		return 0, domain.ErrMutationStale
	}
}

func canonicalEntityTypeCode(entityType domain.EntityType) (byte, error) {
	switch entityType {
	case domain.EntityTypeAttraction:
		return 1, nil
	case domain.EntityTypeActivity:
		return 2, nil
	case domain.EntityTypeGuide:
		// Code 3 is retired with EXCURSION and must never be reused.
		return 4, nil
	case domain.EntityTypeUser:
		return 5, nil
	case domain.EntityTypePost:
		return 6, nil
	default:
		return 0, domain.ErrTargetTypeUnsupported
	}
}
