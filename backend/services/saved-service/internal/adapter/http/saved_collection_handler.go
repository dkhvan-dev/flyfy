package http

import (
	"context"
	"errors"
	"math"
	"net/http"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/app/productrollout"
	"kz/inflap/backend/services/saved-service/internal/app/savedcollection"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

const maxSavedCollectionBodyBytes = 32 * 1024

var ErrInvalidSavedCollectionHandlerDependencies = errors.New("invalid saved collection handler dependencies")

type SavedCollectionReadUseCase interface {
	List(context.Context, savedcollection.ListQuery) ([]savedcollection.Collection, error)
	Get(context.Context, savedcollection.GetQuery) (savedcollection.Collection, error)
	TargetCollections(context.Context, savedcollection.TargetSnapshotQuery) (savedcollection.TargetCollectionsSnapshot, error)
}

type SavedCollectionMutationUseCase interface {
	Create(context.Context, savedcollection.CreateRequest) (*domain.SavedOperation, error)
	Rename(context.Context, savedcollection.RenameRequest) (*domain.SavedOperation, error)
	Delete(context.Context, savedcollection.DeleteRequest) (*domain.SavedOperation, error)
	ReplaceDesiredSet(context.Context, savedcollection.ReplaceDesiredSetRequest) (*domain.SavedOperation, error)
}

type SavedCollectionHandler struct {
	reader  SavedCollectionReadUseCase
	mutator SavedCollectionMutationUseCase
	clock   ResponseClock
}

func NewSavedCollectionHandler(
	reader SavedCollectionReadUseCase,
	mutator SavedCollectionMutationUseCase,
	clock ResponseClock,
) (*SavedCollectionHandler, error) {
	if reader == nil || mutator == nil {
		return nil, ErrInvalidSavedCollectionHandlerDependencies
	}
	if clock == nil {
		clock = systemResponseClock{}
	}
	return &SavedCollectionHandler{reader: reader, mutator: mutator, clock: clock}, nil
}

func (handler *SavedCollectionHandler) Register(mux *http.ServeMux) error {
	if handler == nil || handler.reader == nil || handler.mutator == nil || handler.clock == nil || mux == nil {
		return ErrInvalidSavedCollectionHandlerDependencies
	}
	collections := "/v1/users/me/saved-collections"
	collection := collections + "/{collectionId}"
	targetCollections := "/v1/users/me/saved-items/{entityType}/{entityKey}/collections"
	mux.HandleFunc("GET "+collections, handler.List)
	mux.HandleFunc("POST "+collections, handler.Create)
	mux.HandleFunc("GET "+collection, handler.Get)
	mux.HandleFunc("PATCH "+collection, handler.Rename)
	mux.HandleFunc("DELETE "+collection, handler.Delete)
	mux.HandleFunc("GET "+targetCollections, handler.GetTargetCollections)
	mux.HandleFunc("PUT "+targetCollections, handler.ReplaceTargetCollections)
	return nil
}

func (handler *SavedCollectionHandler) List(w http.ResponseWriter, request *http.Request) {
	principal, ok := PersonalPrincipalFromContext(request.Context())
	if !ok {
		writePersonalAuthError(w, request, "UNAUTHENTICATED")
		return
	}
	if !emptyQuery(request) {
		writeInvalidArgument(w, request)
		return
	}
	collections, err := handler.reader.List(request.Context(), savedcollection.ListQuery{
		OwnerUserID: principal.UserID,
		Locale:      effectiveSavedCollectionLocale(request.Header.Get("Accept-Language")),
		ReadAt:      handler.clock.Now().UTC(),
	})
	if err != nil {
		writeSavedCollectionError(w, request, err)
		return
	}
	response := savedCollectionsListResponse{Collections: make([]savedCollectionResponse, 0, len(collections))}
	for _, collection := range collections {
		mapped, err := mapSavedCollection(collection)
		if err != nil {
			writeDomainError(w, request, domain.ErrTemporarilyUnavailable)
			return
		}
		response.Collections = append(response.Collections, mapped)
	}
	writePersonalJSON(w, request, http.StatusOK, response)
}

func (handler *SavedCollectionHandler) Get(w http.ResponseWriter, request *http.Request) {
	principal, ok := PersonalPrincipalFromContext(request.Context())
	if !ok {
		writePersonalAuthError(w, request, "UNAUTHENTICATED")
		return
	}
	collectionID, err := parseCollectionIDPath(request)
	if err != nil || !emptyQuery(request) {
		writeInvalidArgument(w, request)
		return
	}
	collection, err := handler.reader.Get(request.Context(), savedcollection.GetQuery{
		OwnerUserID:  principal.UserID,
		CollectionID: collectionID,
		Locale:       effectiveSavedCollectionLocale(request.Header.Get("Accept-Language")),
		ReadAt:       handler.clock.Now().UTC(),
	})
	if err != nil {
		writeSavedCollectionError(w, request, err)
		return
	}
	mapped, err := mapSavedCollection(collection)
	if err != nil {
		writeDomainError(w, request, domain.ErrTemporarilyUnavailable)
		return
	}
	writePersonalJSON(w, request, http.StatusOK, savedCollectionDetailResponse{Collection: mapped})
}

func (handler *SavedCollectionHandler) GetTargetCollections(w http.ResponseWriter, request *http.Request) {
	principal, ok := PersonalPrincipalFromContext(request.Context())
	if !ok {
		writePersonalAuthError(w, request, "UNAUTHENTICATED")
		return
	}
	target, err := ParseSavedTargetPath(request)
	if err != nil || !emptyQuery(request) {
		writeInvalidArgument(w, request)
		return
	}
	snapshot, err := handler.reader.TargetCollections(request.Context(), savedcollection.TargetSnapshotQuery{
		OwnerUserID: principal.UserID,
		Target:      target,
		ReadAt:      handler.clock.Now().UTC(),
	})
	if err != nil {
		writeSavedCollectionError(w, request, err)
		return
	}
	mapped, err := mapTargetCollectionsSnapshot(snapshot)
	if err != nil {
		writeDomainError(w, request, domain.ErrTemporarilyUnavailable)
		return
	}
	writePersonalJSON(w, request, http.StatusOK, mapped)
}

func (handler *SavedCollectionHandler) Create(w http.ResponseWriter, request *http.Request) {
	principal, identity, surface, ok := parseCollectionMutationRequest(w, request)
	if !ok {
		return
	}
	var body createCollectionRequest
	if err := DecodeBoundedJSON(w, request, maxSavedCollectionBodyBytes, &body); err != nil {
		writeInvalidArgument(w, request)
		return
	}
	clientCreationID, err := parseUUIDv4(body.ClientCreationID)
	if err != nil {
		writeInvalidArgument(w, request)
		return
	}
	receipt, err := handler.mutator.Create(request.Context(), savedcollection.CreateRequest{
		Identity:         collectionClientIdentity(principal, identity, surface),
		ClientCreationID: clientCreationID,
		Title:            body.Title,
		DisableExpansion: !productExpansionAllowed(
			request.Context(),
			productrollout.CapabilitySavedCollections,
		),
	})
	handler.writeMutationResult(w, request, receipt, err)
}

func (handler *SavedCollectionHandler) Rename(w http.ResponseWriter, request *http.Request) {
	principal, identity, surface, ok := parseCollectionMutationRequest(w, request)
	if !ok {
		return
	}
	collectionID, err := parseCollectionIDPath(request)
	if err != nil {
		writeInvalidArgument(w, request)
		return
	}
	var body renameCollectionRequest
	if err := DecodeBoundedJSON(w, request, maxSavedCollectionBodyBytes, &body); err != nil ||
		body.ExpectedMetadataVersion == 0 || body.ExpectedMetadataVersion > math.MaxInt64 {
		writeInvalidArgument(w, request)
		return
	}
	receipt, err := handler.mutator.Rename(request.Context(), savedcollection.RenameRequest{
		Identity:                collectionClientIdentity(principal, identity, surface),
		CollectionID:            collectionID,
		ExpectedMetadataVersion: body.ExpectedMetadataVersion,
		Title:                   body.Title,
	})
	handler.writeMutationResult(w, request, receipt, err)
}

func (handler *SavedCollectionHandler) Delete(w http.ResponseWriter, request *http.Request) {
	principal, identity, surface, ok := parseCollectionMutationRequest(w, request)
	if !ok {
		return
	}
	collectionID, err := parseCollectionIDPath(request)
	if err != nil {
		writeInvalidArgument(w, request)
		return
	}
	var body deleteCollectionRequest
	if err := DecodeBoundedJSON(w, request, maxSavedCollectionBodyBytes, &body); err != nil ||
		body.ExpectedMetadataVersion == 0 || body.ExpectedMetadataVersion > math.MaxInt64 ||
		body.ExpectedLifecycleVersion == 0 || body.ExpectedLifecycleVersion > math.MaxInt64 {
		writeInvalidArgument(w, request)
		return
	}
	receipt, err := handler.mutator.Delete(request.Context(), savedcollection.DeleteRequest{
		Identity:                 collectionClientIdentity(principal, identity, surface),
		CollectionID:             collectionID,
		ExpectedMetadataVersion:  body.ExpectedMetadataVersion,
		ExpectedLifecycleVersion: body.ExpectedLifecycleVersion,
	})
	handler.writeMutationResult(w, request, receipt, err)
}

func (handler *SavedCollectionHandler) ReplaceTargetCollections(w http.ResponseWriter, request *http.Request) {
	principal, identity, surface, ok := parseCollectionMutationRequest(w, request)
	if !ok {
		return
	}
	target, err := ParseSavedTargetPath(request)
	if err != nil {
		writeInvalidArgument(w, request)
		return
	}
	var body desiredCollectionAssignmentRequest
	if err := DecodeBoundedJSON(w, request, maxSavedCollectionBodyBytes, &body); err != nil {
		writeInvalidArgument(w, request)
		return
	}
	desired, err := body.toDesiredSet(target)
	if err != nil {
		writeInvalidArgument(w, request)
		return
	}
	collectionsAllowed := productExpansionAllowed(
		request.Context(),
		productrollout.CapabilitySavedCollections,
	)
	entityExpansionAllowed := desired.ExpectedRelationship.State == savedcollection.ExpectedRelationshipActive ||
		savedTargetExpansionAllowed(request.Context(), target)
	receipt, err := handler.mutator.ReplaceDesiredSet(request.Context(), savedcollection.ReplaceDesiredSetRequest{
		Identity:         collectionClientIdentity(principal, identity, surface),
		Desired:          desired,
		DisableExpansion: !collectionsAllowed || !entityExpansionAllowed,
	})
	handler.writeMutationResult(w, request, receipt, err)
}

func (handler *SavedCollectionHandler) writeMutationResult(
	w http.ResponseWriter,
	request *http.Request,
	receipt *domain.SavedOperation,
	err error,
) {
	if err != nil {
		writeSavedCollectionError(w, request, err)
		return
	}
	if err := writeOperationResult(w, request, receipt, nil, handler.clock.Now().UTC()); err != nil {
		writeDomainError(w, request, domain.ErrTemporarilyUnavailable)
	}
}

type createCollectionRequest struct {
	ClientCreationID string `json:"client_creation_id"`
	Title            string `json:"title"`
}

type renameCollectionRequest struct {
	ExpectedMetadataVersion uint64 `json:"expected_metadata_version"`
	Title                   string `json:"title"`
}

type deleteCollectionRequest struct {
	ExpectedMetadataVersion  uint64 `json:"expected_metadata_version"`
	ExpectedLifecycleVersion uint64 `json:"expected_lifecycle_version"`
}

type expectedRelationshipRequest struct {
	State      string  `json:"state"`
	Generation *string `json:"generation,omitempty"`
	Version    *uint64 `json:"version,omitempty"`
}

type newCollectionRequest struct {
	ClientCreationID string `json:"client_creation_id"`
	Title            string `json:"title"`
}

type desiredCollectionAssignmentRequest struct {
	ExpectedRelationship               expectedRelationshipRequest `json:"expected_relationship"`
	ExpectedDependentMembershipVersion uint64                      `json:"expected_dependent_membership_version"`
	DesiredCollectionIDs               []string                    `json:"desired_collection_ids"`
	NewCollection                      *newCollectionRequest       `json:"new_collection,omitempty"`
}

func (body desiredCollectionAssignmentRequest) toDesiredSet(target domain.SavedTarget) (savedcollection.DesiredSet, error) {
	expected, err := body.ExpectedRelationship.toDomain()
	if err != nil || body.ExpectedDependentMembershipVersion > math.MaxInt64 ||
		len(body.DesiredCollectionIDs) > savedcollection.DefaultMaxDesiredCollectionIDs {
		return savedcollection.DesiredSet{}, savedcollection.ErrInvalidCommand
	}
	ids := make([]uuid.UUID, 0, len(body.DesiredCollectionIDs))
	seen := make(map[uuid.UUID]struct{}, len(body.DesiredCollectionIDs))
	for _, raw := range body.DesiredCollectionIDs {
		id, err := parseCanonicalUUID(raw)
		if err != nil {
			return savedcollection.DesiredSet{}, err
		}
		if _, duplicate := seen[id]; duplicate {
			return savedcollection.DesiredSet{}, savedcollection.ErrInvalidCommand
		}
		seen[id] = struct{}{}
		ids = append(ids, id)
	}
	desired := savedcollection.DesiredSet{
		Target:                             target,
		ExpectedRelationship:               expected,
		ExpectedDependentMembershipVersion: body.ExpectedDependentMembershipVersion,
		DesiredCollectionIDs:               ids,
	}
	if body.NewCollection != nil {
		creationID, err := parseUUIDv4(body.NewCollection.ClientCreationID)
		if err != nil {
			return savedcollection.DesiredSet{}, err
		}
		desired.NewCollection = &savedcollection.NewCollection{
			ClientCreationID: creationID,
			Title:            body.NewCollection.Title,
		}
	}
	if err := desired.Validate(savedcollection.DefaultMaxDesiredCollectionIDs); err != nil {
		return savedcollection.DesiredSet{}, err
	}
	return desired, nil
}

func (body expectedRelationshipRequest) toDomain() (savedcollection.ExpectedRelationship, error) {
	switch savedcollection.ExpectedRelationshipState(body.State) {
	case savedcollection.ExpectedRelationshipAbsent:
		if body.Generation != nil || body.Version != nil {
			return savedcollection.ExpectedRelationship{}, savedcollection.ErrInvalidCommand
		}
		return savedcollection.ExpectedRelationship{State: savedcollection.ExpectedRelationshipAbsent}, nil
	case savedcollection.ExpectedRelationshipActive, savedcollection.ExpectedRelationshipRemoved:
		if body.Generation == nil || body.Version == nil || *body.Version == 0 || *body.Version > math.MaxInt64 {
			return savedcollection.ExpectedRelationship{}, savedcollection.ErrInvalidCommand
		}
		generation, err := parseCanonicalUUID(*body.Generation)
		if err != nil {
			return savedcollection.ExpectedRelationship{}, err
		}
		return savedcollection.ExpectedRelationship{
			State:      savedcollection.ExpectedRelationshipState(body.State),
			Generation: generation,
			Version:    *body.Version,
		}, nil
	default:
		return savedcollection.ExpectedRelationship{}, savedcollection.ErrInvalidCommand
	}
}

type savedCollectionsListResponse struct {
	Collections []savedCollectionResponse `json:"collections"`
}

type savedCollectionDetailResponse struct {
	Collection savedCollectionResponse `json:"collection"`
}

type savedCollectionResponse struct {
	CollectionID     string                                   `json:"collection_id"`
	Title            string                                   `json:"title"`
	LifecycleState   savedcollection.CollectionLifecycleState `json:"lifecycle_state"`
	MetadataVersion  uint64                                   `json:"metadata_version"`
	LifecycleVersion uint64                                   `json:"lifecycle_version"`
	ActiveItemCount  uint64                                   `json:"active_item_count"`
	CoverPreview     collectionCoverPreviewResponse           `json:"cover_preview"`
	OrganizedAt      time.Time                                `json:"organized_at"`
	CreatedAt        time.Time                                `json:"created_at"`
	UpdatedAt        time.Time                                `json:"updated_at"`
}

type collectionCoverPreviewResponse struct {
	Kind     savedcollection.CoverKind `json:"kind"`
	Target   *savedTargetResponse      `json:"target,omitempty"`
	Title    *string                   `json:"title,omitempty"`
	ImageURL *string                   `json:"image_url,omitempty"`
}

type targetCollectionsSnapshotResponse struct {
	SnapshotVersion            uint64                       `json:"snapshot_version"`
	Target                     savedTargetResponse          `json:"target"`
	Relationship               relationshipSnapshotResponse `json:"relationship"`
	DependentMembershipVersion uint64                       `json:"dependent_membership_version"`
	EffectiveCollectionIDs     []string                     `json:"effective_collection_ids"`
	CollectionOptions          []collectionOptionResponse   `json:"collection_options"`
}

type relationshipSnapshotResponse struct {
	State      savedcollection.RelationshipSnapshotState `json:"state"`
	Generation *string                                   `json:"generation,omitempty"`
	Version    *uint64                                   `json:"version,omitempty"`
}

type collectionOptionResponse struct {
	CollectionID     string `json:"collection_id"`
	Title            string `json:"title"`
	MetadataVersion  uint64 `json:"metadata_version"`
	LifecycleVersion uint64 `json:"lifecycle_version"`
}

func mapSavedCollection(collection savedcollection.Collection) (savedCollectionResponse, error) {
	cover, err := mapCollectionCover(collection.Cover)
	if err != nil {
		return savedCollectionResponse{}, err
	}
	return savedCollectionResponse{
		CollectionID:     collection.ID.String(),
		Title:            collection.Title,
		LifecycleState:   collection.LifecycleState,
		MetadataVersion:  collection.MetadataVersion,
		LifecycleVersion: collection.LifecycleVersion,
		ActiveItemCount:  collection.ActiveItemCount,
		CoverPreview:     cover,
		OrganizedAt:      collection.OrganizedAt.UTC(),
		CreatedAt:        collection.CreatedAt.UTC(),
		UpdatedAt:        collection.UpdatedAt.UTC(),
	}, nil
}

func mapCollectionCover(cover savedcollection.CoverPreview) (collectionCoverPreviewResponse, error) {
	switch cover.Kind {
	case savedcollection.CoverKindGeneric:
		if cover.Target != nil || cover.Title != nil || cover.ResolvedImageURL != nil {
			return collectionCoverPreviewResponse{}, savedcollection.ErrDataInvariant
		}
		return collectionCoverPreviewResponse{Kind: savedcollection.CoverKindGeneric}, nil
	case savedcollection.CoverKindItem:
		if cover.Target == nil || cover.Title == nil || cover.ResolvedImageURL == nil {
			return collectionCoverPreviewResponse{}, savedcollection.ErrDataInvariant
		}
		target := mapSavedTarget(*cover.Target)
		return collectionCoverPreviewResponse{
			Kind:     savedcollection.CoverKindItem,
			Target:   &target,
			Title:    cover.Title,
			ImageURL: cover.ResolvedImageURL,
		}, nil
	default:
		return collectionCoverPreviewResponse{}, savedcollection.ErrDataInvariant
	}
}

func mapTargetCollectionsSnapshot(
	snapshot savedcollection.TargetCollectionsSnapshot,
) (targetCollectionsSnapshotResponse, error) {
	relationship := relationshipSnapshotResponse{State: snapshot.Relationship.State}
	snapshotVersion := snapshot.DependentMembershipVersion
	if snapshot.Relationship.State != savedcollection.RelationshipSnapshotAbsent {
		generation := snapshot.Relationship.Generation.String()
		version := snapshot.Relationship.Version
		relationship.Generation = &generation
		relationship.Version = &version
		if version > snapshotVersion {
			snapshotVersion = version
		}
	}
	effectiveIDs := make([]string, 0, len(snapshot.EffectiveCollectionIDs))
	for _, id := range snapshot.EffectiveCollectionIDs {
		effectiveIDs = append(effectiveIDs, id.String())
	}
	options := make([]collectionOptionResponse, 0, len(snapshot.CollectionOptions))
	for _, option := range snapshot.CollectionOptions {
		options = append(options, collectionOptionResponse{
			CollectionID:     option.ID.String(),
			Title:            option.Title,
			MetadataVersion:  option.MetadataVersion,
			LifecycleVersion: option.LifecycleVersion,
		})
	}
	return targetCollectionsSnapshotResponse{
		SnapshotVersion:            snapshotVersion,
		Target:                     mapSavedTarget(snapshot.Target),
		Relationship:               relationship,
		DependentMembershipVersion: snapshot.DependentMembershipVersion,
		EffectiveCollectionIDs:     effectiveIDs,
		CollectionOptions:          options,
	}, nil
}

func parseCollectionMutationRequest(
	w http.ResponseWriter,
	request *http.Request,
) (PersonalPrincipal, MutationIdentity, domain.SourceSurface, bool) {
	principal, ok := PersonalPrincipalFromContext(request.Context())
	if !ok {
		writePersonalAuthError(w, request, "UNAUTHENTICATED")
		return PersonalPrincipal{}, MutationIdentity{}, "", false
	}
	identity, err := ParseMutationIdentity(request.Header)
	if err != nil {
		writeInvalidArgument(w, request)
		return PersonalPrincipal{}, MutationIdentity{}, "", false
	}
	surface, err := ParseSourceSurface(request.Header)
	if err != nil {
		writeInvalidArgument(w, request)
		return PersonalPrincipal{}, MutationIdentity{}, "", false
	}
	return principal, identity, surface, true
}

func collectionClientIdentity(
	principal PersonalPrincipal,
	identity MutationIdentity,
	surface domain.SourceSurface,
) savedcollection.ClientMutationIdentity {
	return savedcollection.ClientMutationIdentity{
		SubjectID:         principal.Subject,
		OwnerUserID:       principal.UserID,
		SessionGeneration: principal.SessionGeneration,
		OperationID:       identity.OperationID,
		IdempotencyKey:    identity.IdempotencyKey,
		SourceSurface:     surface,
	}
}

func parseCollectionIDPath(request *http.Request) (uuid.UUID, error) {
	if request == nil {
		return uuid.Nil, savedcollection.ErrInvalidCommand
	}
	return parseCanonicalUUID(request.PathValue("collectionId"))
}

func parseUUIDv4(raw string) (uuid.UUID, error) {
	value, err := parseCanonicalUUID(raw)
	if err != nil || value.Version() != 4 || value.Variant() != uuid.RFC4122 {
		return uuid.Nil, savedcollection.ErrInvalidCommand
	}
	return value, nil
}

func parseCanonicalUUID(raw string) (uuid.UUID, error) {
	value, err := uuid.Parse(raw)
	if err != nil || value == uuid.Nil || value.String() != raw {
		return uuid.Nil, savedcollection.ErrInvalidCommand
	}
	return value, nil
}

func effectiveSavedCollectionLocale(value string) savedcollection.Locale {
	switch effectiveErrorLocale(value) {
	case "en":
		return savedcollection.LocaleEN
	case "kk":
		return savedcollection.LocaleKK
	default:
		return savedcollection.LocaleRU
	}
}

func emptyQuery(request *http.Request) bool {
	return request != nil && len(request.URL.Query()) == 0
}

func writeSavedCollectionError(w http.ResponseWriter, request *http.Request, err error) {
	var domainError *domain.DomainError
	switch {
	case errors.As(err, &domainError):
		writeDomainError(w, request, domainError)
	case errors.Is(err, savedcollection.ErrInvalidCommand):
		writeInvalidArgument(w, request)
	case errors.Is(err, savedcollection.ErrOperationNotFound):
		writeNotFound(w, request)
	default:
		writeDomainError(w, request, domain.ErrTemporarilyUnavailable)
	}
}
