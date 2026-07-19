package operation

import (
	"bytes"
	"encoding/binary"
	"sort"
	"strings"
	"unicode"
	"unicode/utf8"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

const (
	collectionSemanticCanonicalDomain  = "inflap.saved.collection-semantic-request\x00"
	collectionSemanticCanonicalVersion = byte(1)
	maxDesiredCollectionIDs            = 200
	maxCollectionTitleRunes            = 80
	maxCollectionTitleBytes            = 320
)

type ExpectedRelationshipState string

const (
	ExpectedRelationshipAbsent  ExpectedRelationshipState = "EXPECTED_ABSENT"
	ExpectedRelationshipActive  ExpectedRelationshipState = "EXPECTED_ACTIVE"
	ExpectedRelationshipRemoved ExpectedRelationshipState = "EXPECTED_REMOVED"
)

type ExpectedRelationship struct {
	State      ExpectedRelationshipState
	Generation uuid.UUID
	Version    uint64
}

type NewCollectionSemanticRequest struct {
	ClientCreationID uuid.UUID
	Title            string
}

// CollectionSemanticRequest is a closed set so every collection operation has
// one stable canonical representation. The canonical bytes are transient HMAC
// input and are never written to the operation journal.
type CollectionSemanticRequest interface {
	operationKind() domain.OperationKind
	appendCanonicalFields(*canonicalFieldEncoder) error
}

type SetTargetCollectionsSemanticRequest struct {
	Target                             domain.SavedTarget
	ExpectedRelationship               ExpectedRelationship
	ExpectedDependentMembershipVersion uint64
	DesiredCollectionIDs               []uuid.UUID
	NewCollection                      *NewCollectionSemanticRequest
}

func (SetTargetCollectionsSemanticRequest) operationKind() domain.OperationKind {
	return domain.OperationKindSetTargetCollections
}

func (request SetTargetCollectionsSemanticRequest) appendCanonicalFields(encoder *canonicalFieldEncoder) error {
	if err := encoder.appendTarget(request.Target); err != nil {
		return err
	}
	if err := encoder.appendExpectedRelationship(request.ExpectedRelationship); err != nil {
		return err
	}
	encoder.appendUint64(request.ExpectedDependentMembershipVersion)

	identifiers, err := canonicalCollectionIDs(request.DesiredCollectionIDs)
	if err != nil {
		return err
	}
	encoder.appendUint64(uint64(len(identifiers)))
	for _, identifier := range identifiers {
		encoder.appendField(identifier[:])
	}

	if request.NewCollection == nil {
		encoder.appendBool(false)
		return nil
	}
	if err := validateClientCreationID(request.NewCollection.ClientCreationID); err != nil {
		return err
	}
	if err := validateCollectionTitle(request.NewCollection.Title); err != nil {
		return err
	}
	encoder.appendBool(true)
	encoder.appendField(request.NewCollection.ClientCreationID[:])
	encoder.appendField([]byte(request.NewCollection.Title))
	return nil
}

type CreateCollectionSemanticRequest struct {
	ClientCreationID uuid.UUID
	Title            string
}

func (CreateCollectionSemanticRequest) operationKind() domain.OperationKind {
	return domain.OperationKindCreateCollection
}

func (request CreateCollectionSemanticRequest) appendCanonicalFields(encoder *canonicalFieldEncoder) error {
	if err := validateClientCreationID(request.ClientCreationID); err != nil {
		return err
	}
	if err := validateCollectionTitle(request.Title); err != nil {
		return err
	}
	encoder.appendField(request.ClientCreationID[:])
	encoder.appendField([]byte(request.Title))
	return nil
}

type RenameCollectionSemanticRequest struct {
	CollectionID            uuid.UUID
	ExpectedMetadataVersion uint64
	Title                   string
}

func (RenameCollectionSemanticRequest) operationKind() domain.OperationKind {
	return domain.OperationKindRenameCollection
}

func (request RenameCollectionSemanticRequest) appendCanonicalFields(encoder *canonicalFieldEncoder) error {
	if request.CollectionID == uuid.Nil || request.ExpectedMetadataVersion == 0 {
		return domain.ErrMutationStale
	}
	if err := validateCollectionTitle(request.Title); err != nil {
		return err
	}
	encoder.appendField(request.CollectionID[:])
	encoder.appendUint64(request.ExpectedMetadataVersion)
	encoder.appendField([]byte(request.Title))
	return nil
}

type DeleteCollectionSemanticRequest struct {
	CollectionID             uuid.UUID
	ExpectedMetadataVersion  uint64
	ExpectedLifecycleVersion uint64
}

func (DeleteCollectionSemanticRequest) operationKind() domain.OperationKind {
	return domain.OperationKindDeleteCollection
}

func (request DeleteCollectionSemanticRequest) appendCanonicalFields(encoder *canonicalFieldEncoder) error {
	if request.CollectionID == uuid.Nil || request.ExpectedMetadataVersion == 0 || request.ExpectedLifecycleVersion == 0 {
		return domain.ErrMutationStale
	}
	encoder.appendField(request.CollectionID[:])
	encoder.appendUint64(request.ExpectedMetadataVersion)
	encoder.appendUint64(request.ExpectedLifecycleVersion)
	return nil
}

func canonicalCollectionSemanticRequest(request CollectionSemanticRequest) ([]byte, domain.OperationKind, error) {
	if request == nil {
		return nil, "", domain.ErrMutationStale
	}
	kind := request.operationKind()
	if kind != domain.OperationKindSetTargetCollections &&
		kind != domain.OperationKindCreateCollection &&
		kind != domain.OperationKindRenameCollection &&
		kind != domain.OperationKindDeleteCollection {
		return nil, "", domain.ErrMutationStale
	}
	kindCode, err := canonicalOperationKindCode(kind)
	if err != nil {
		return nil, "", err
	}

	canonical := make([]byte, 0, 256)
	canonical = append(canonical, collectionSemanticCanonicalDomain...)
	canonical = append(canonical, collectionSemanticCanonicalVersion, kindCode)
	encoder := canonicalFieldEncoder{canonical: canonical}
	if err := request.appendCanonicalFields(&encoder); err != nil {
		clear(encoder.canonical)
		return nil, "", err
	}
	return encoder.canonical, kind, nil
}

type canonicalFieldEncoder struct {
	canonical []byte
}

func (encoder *canonicalFieldEncoder) appendField(value []byte) {
	var length [semanticLengthBytes]byte
	binary.BigEndian.PutUint32(length[:], uint32(len(value)))
	encoder.canonical = append(encoder.canonical, length[:]...)
	encoder.canonical = append(encoder.canonical, value...)
}

func (encoder *canonicalFieldEncoder) appendUint64(value uint64) {
	var encoded [8]byte
	binary.BigEndian.PutUint64(encoded[:], value)
	encoder.appendField(encoded[:])
}

func (encoder *canonicalFieldEncoder) appendBool(value bool) {
	if value {
		encoder.appendField([]byte{1})
		return
	}
	encoder.appendField([]byte{0})
}

func (encoder *canonicalFieldEncoder) appendTarget(target domain.SavedTarget) error {
	if target.IsZero() {
		return domain.ErrTargetUnavailable
	}
	entityTypeCode, err := canonicalEntityTypeCode(target.EntityType())
	if err != nil {
		return err
	}
	encoder.appendField([]byte{entityTypeCode})
	encoder.appendField([]byte(target.EntityID()))
	return nil
}

func (encoder *canonicalFieldEncoder) appendExpectedRelationship(expected ExpectedRelationship) error {
	var stateCode byte
	switch expected.State {
	case ExpectedRelationshipAbsent:
		if expected.Generation != uuid.Nil || expected.Version != 0 {
			return domain.ErrMutationStale
		}
		stateCode = 1
	case ExpectedRelationshipActive:
		if expected.Generation == uuid.Nil || expected.Version == 0 {
			return domain.ErrMutationStale
		}
		stateCode = 2
	case ExpectedRelationshipRemoved:
		if expected.Generation == uuid.Nil || expected.Version == 0 {
			return domain.ErrMutationStale
		}
		stateCode = 3
	default:
		return domain.ErrMutationStale
	}
	encoder.appendField([]byte{stateCode})
	if expected.State == ExpectedRelationshipAbsent {
		return nil
	}
	encoder.appendField(expected.Generation[:])
	encoder.appendUint64(expected.Version)
	return nil
}

func canonicalCollectionIDs(values []uuid.UUID) ([]uuid.UUID, error) {
	if len(values) > maxDesiredCollectionIDs {
		return nil, domain.ErrMutationStale
	}
	copyOfValues := append([]uuid.UUID(nil), values...)
	for _, value := range copyOfValues {
		if value == uuid.Nil {
			return nil, domain.ErrMutationStale
		}
	}
	sort.Slice(copyOfValues, func(left, right int) bool {
		return bytes.Compare(copyOfValues[left][:], copyOfValues[right][:]) < 0
	})
	for index := 1; index < len(copyOfValues); index++ {
		if copyOfValues[index] == copyOfValues[index-1] {
			return nil, domain.ErrMutationStale
		}
	}
	return copyOfValues, nil
}

func validateClientCreationID(value uuid.UUID) error {
	if value == uuid.Nil {
		return domain.ErrMutationStale
	}
	return nil
}

func validateCollectionTitle(value string) error {
	if value == "" || value != strings.TrimSpace(value) || !utf8.ValidString(value) ||
		len(value) > maxCollectionTitleBytes || utf8.RuneCountInString(value) > maxCollectionTitleRunes ||
		strings.IndexFunc(value, unicode.IsControl) >= 0 {
		return domain.ErrCollectionTitleInvalid
	}
	return nil
}
