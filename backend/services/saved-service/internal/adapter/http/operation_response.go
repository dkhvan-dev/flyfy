package http

import (
	"errors"
	"time"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

var errInvalidOperationResponse = errors.New("invalid operation response state")

type operationResultResponse struct {
	OperationID             string                          `json:"operation_id"`
	OperationKind           domain.OperationKind            `json:"operation_kind"`
	OperationStatus         domain.OperationStatus          `json:"operation_status"`
	OperationOutcome        domain.OperationOutcome         `json:"operation_outcome"`
	CommitDeadline          time.Time                       `json:"commit_deadline"`
	RefreshScope            domain.RefreshScope             `json:"refresh_scope"`
	AppliedResourceVersions appliedResourceVersionsResponse `json:"applied_resource_versions"`
	ResultRecordedAt        time.Time                       `json:"result_recorded_at"`
	OperationError          *operationErrorResponse         `json:"operation_error,omitempty"`
	CurrentResourceSnapshot any                             `json:"current_resource_snapshot,omitempty"`
}

type appliedResourceVersionsResponse struct {
	Relationship               *relationshipAppliedVersionResponse `json:"relationship,omitempty"`
	DependentMembershipVersion *uint64                             `json:"dependent_membership_version,omitempty"`
	Collection                 *collectionAppliedVersionResponse   `json:"collection,omitempty"`
}

type relationshipAppliedVersionResponse struct {
	Generation string `json:"generation"`
	Version    uint64 `json:"version"`
}

type collectionAppliedVersionResponse struct {
	CollectionID     string `json:"collection_id"`
	MetadataVersion  uint64 `json:"metadata_version"`
	LifecycleVersion uint64 `json:"lifecycle_version"`
}

type operationErrorResponse struct {
	Code         domain.ErrorCode `json:"code"`
	Retryable    bool             `json:"retryable"`
	RetryAfterMS *int64           `json:"retry_after_ms,omitempty"`
}

func mapOperationResult(
	receipt *domain.SavedOperation,
	currentResourceSnapshot any,
) (operationResultResponse, error) {
	if receipt == nil || !receipt.Kind().IsValid() || !receipt.Status().IsValid() ||
		!receipt.RefreshScope().IsValid() || receipt.CreatedAt().IsZero() || receipt.CommitDeadline().IsZero() {
		return operationResultResponse{}, errInvalidOperationResponse
	}

	resultRecordedAt := receipt.CreatedAt().UTC()
	if receipt.Status() != domain.OperationStatusPending {
		completedAt := receipt.CompletedAt()
		if completedAt == nil || completedAt.IsZero() {
			return operationResultResponse{}, errInvalidOperationResponse
		}
		resultRecordedAt = completedAt.UTC()
	}

	response := operationResultResponse{
		OperationID:             receipt.OperationID().String(),
		OperationKind:           receipt.Kind(),
		OperationStatus:         receipt.Status(),
		OperationOutcome:        receipt.Outcome(),
		CommitDeadline:          receipt.CommitDeadline().UTC(),
		RefreshScope:            receipt.RefreshScope(),
		AppliedResourceVersions: mapAppliedResourceVersions(receipt),
		ResultRecordedAt:        resultRecordedAt,
		CurrentResourceSnapshot: currentResourceSnapshot,
	}

	failure := receipt.Failure()
	if receipt.Status() == domain.OperationStatusRejected {
		if failure == nil || !failure.Code.IsValid() {
			return operationResultResponse{}, errInvalidOperationResponse
		}
		response.OperationError = &operationErrorResponse{
			Code:      failure.Code,
			Retryable: failure.Retryable,
		}
	} else if failure != nil {
		return operationResultResponse{}, errInvalidOperationResponse
	}

	return response, nil
}

func mapAppliedResourceVersions(receipt *domain.SavedOperation) appliedResourceVersionsResponse {
	response := appliedResourceVersionsResponse{
		DependentMembershipVersion: receipt.AppliedDependentMembershipVersion(),
	}
	if relationship := receipt.AppliedRelationship(); relationship != nil {
		response.Relationship = &relationshipAppliedVersionResponse{
			Generation: relationship.Generation.String(),
			Version:    relationship.Version,
		}
	}
	if collection := receipt.AppliedCollection(); collection != nil {
		response.Collection = &collectionAppliedVersionResponse{
			CollectionID:     collection.CollectionID.String(),
			MetadataVersion:  collection.MetadataVersion,
			LifecycleVersion: collection.LifecycleVersion,
		}
	}
	return response
}
