package grpc

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/trust-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/trust-service/internal/domain/model"
	trustv1 "github.com/dkhvan-dev/flyfy/proto/gen/go/trust/v1"
	"google.golang.org/protobuf/types/known/timestamppb"
)

type Server struct {
	trustv1.UnimplementedTrustServiceServer
	usecase *app.PolicyUseCase
}

func NewServer(usecase *app.PolicyUseCase) *Server {
	return &Server{usecase: usecase}
}

func (s *Server) CheckActionPolicy(ctx context.Context, req *trustv1.CheckActionPolicyRequest) (*trustv1.CheckActionPolicyResponse, error) {
	if req == nil {
		return nil, mapError(fmt.Errorf("%w: request is required", app.ErrInvalidInput))
	}
	userID, err := parseRequiredUUID(req.GetUserId(), "user id")
	if err != nil {
		return nil, mapError(err)
	}
	action, err := policyActionFromProto(req.GetAction())
	if err != nil {
		return nil, mapError(err)
	}

	var requestedAt time.Time
	if req.GetRequestedAt() != nil {
		requestedAt = req.GetRequestedAt().AsTime()
	}
	var metadata map[string]any
	if req.GetMetadata() != nil {
		metadata = req.GetMetadata().AsMap()
	}

	decision, err := s.usecase.CheckActionPolicy(ctx, model.PolicyCheckInput{
		UserID:         userID,
		Action:         action,
		ResourceType:   strings.TrimSpace(req.GetResourceType()),
		ResourceID:     strings.TrimSpace(req.GetResourceId()),
		IdempotencyKey: strings.TrimSpace(req.GetIdempotencyKey()),
		Metadata:       metadata,
		RequestedAt:    requestedAt,
	})
	if err != nil {
		return nil, mapError(err)
	}

	return &trustv1.CheckActionPolicyResponse{
		DecisionId:       decision.ID.String(),
		Decision:         policyDecisionToProto(decision.Decision),
		ReasonCode:       decision.ReasonCode,
		PublicMessageKey: decision.PublicMessageKey,
		InternalMessage:  decision.InternalMessage,
		TrustBand:        trustBandToProto(decision.TrustBand),
		Score:            int32(decision.Score),
		RestrictionIds:   uuidStrings(decision.RestrictionIDs),
	}, nil
}

func (s *Server) ApplyUserRestrictionEvent(ctx context.Context, req *trustv1.ApplyUserRestrictionEventRequest) (*trustv1.ApplyUserRestrictionEventResponse, error) {
	if req == nil {
		return nil, mapError(fmt.Errorf("%w: request is required", app.ErrInvalidInput))
	}
	eventID, err := parseRequiredUUID(req.GetEventId(), "event id")
	if err != nil {
		return nil, mapError(err)
	}
	restrictionID, err := parseRequiredUUID(req.GetRestrictionId(), "restriction id")
	if err != nil {
		return nil, mapError(err)
	}
	userID, err := parseRequiredUUID(req.GetUserId(), "user id")
	if err != nil {
		return nil, mapError(err)
	}
	eventType, err := restrictionEventTypeFromProto(req.GetEventType())
	if err != nil {
		return nil, mapError(err)
	}
	caseID, err := parseOptionalUUID(req.GetCaseId(), "case id")
	if err != nil {
		return nil, mapError(err)
	}
	createdBy, err := parseOptionalUUID(req.GetCreatedByStaffId(), "created by staff id")
	if err != nil {
		return nil, mapError(err)
	}
	liftedBy, err := parseOptionalUUID(req.GetLiftedByStaffId(), "lifted by staff id")
	if err != nil {
		return nil, mapError(err)
	}

	var expiresAt *time.Time
	if req.GetExpiresAt() != nil {
		value := req.GetExpiresAt().AsTime()
		expiresAt = &value
	}
	var occurredAt time.Time
	if req.GetOccurredAt() != nil {
		occurredAt = req.GetOccurredAt().AsTime()
	}

	applied, err := s.usecase.ApplyUserRestrictionEvent(ctx, model.RestrictionEventInput{
		EventID:          eventID,
		EventType:        eventType,
		RestrictionID:    restrictionID,
		UserID:           userID,
		CaseID:           caseID,
		RestrictionCode:  strings.TrimSpace(req.GetRestrictionCode()),
		ReasonCode:       strings.TrimSpace(req.GetReasonCode()),
		CreatedByStaffID: createdBy,
		LiftedByStaffID:  liftedBy,
		ExpiresAt:        expiresAt,
		OccurredAt:       occurredAt,
	})
	if err != nil {
		return nil, mapError(err)
	}
	return &trustv1.ApplyUserRestrictionEventResponse{Applied: applied}, nil
}

func (s *Server) GetTrustProfile(ctx context.Context, req *trustv1.GetTrustProfileRequest) (*trustv1.GetTrustProfileResponse, error) {
	if req == nil {
		return nil, mapError(fmt.Errorf("%w: request is required", app.ErrInvalidInput))
	}
	userID, err := parseRequiredUUID(req.GetUserId(), "user id")
	if err != nil {
		return nil, mapError(err)
	}

	profile, err := s.usecase.GetTrustProfile(ctx, userID)
	if err != nil {
		return nil, mapError(err)
	}
	return &trustv1.GetTrustProfileResponse{
		Profile: trustProfileToProto(profile),
	}, nil
}

func policyActionFromProto(action trustv1.PolicyAction) (model.PolicyAction, error) {
	switch action {
	case trustv1.PolicyAction_POLICY_ACTION_ACTIVITY_CREATE:
		return model.PolicyActionActivityCreate, nil
	case trustv1.PolicyAction_POLICY_ACTION_TOUR_PUBLISH:
		return model.PolicyActionTourPublish, nil
	case trustv1.PolicyAction_POLICY_ACTION_CHAT_SEND:
		return model.PolicyActionChatSend, nil
	case trustv1.PolicyAction_POLICY_ACTION_FILE_UPLOAD:
		return model.PolicyActionFileUpload, nil
	case trustv1.PolicyAction_POLICY_ACTION_FILE_BIND:
		return model.PolicyActionFileBind, nil
	case trustv1.PolicyAction_POLICY_ACTION_PAYOUT_REQUEST:
		return model.PolicyActionPayoutRequest, nil
	case trustv1.PolicyAction_POLICY_ACTION_GUIDE_APPLICATION_SUBMIT:
		return model.PolicyActionGuideApplicationSubmit, nil
	default:
		return "", fmt.Errorf("%w: unsupported policy action", app.ErrInvalidInput)
	}
}

func policyDecisionToProto(decision model.PolicyDecision) trustv1.PolicyDecision {
	switch decision {
	case model.PolicyDecisionAllow:
		return trustv1.PolicyDecision_POLICY_DECISION_ALLOW
	case model.PolicyDecisionDeny:
		return trustv1.PolicyDecision_POLICY_DECISION_DENY
	case model.PolicyDecisionReview:
		return trustv1.PolicyDecision_POLICY_DECISION_REVIEW
	case model.PolicyDecisionQuarantine:
		return trustv1.PolicyDecision_POLICY_DECISION_QUARANTINE
	case model.PolicyDecisionPending:
		return trustv1.PolicyDecision_POLICY_DECISION_PENDING
	default:
		return trustv1.PolicyDecision_POLICY_DECISION_UNSPECIFIED
	}
}

func restrictionEventTypeFromProto(eventType trustv1.RestrictionEventType) (string, error) {
	switch eventType {
	case trustv1.RestrictionEventType_RESTRICTION_EVENT_TYPE_CREATED:
		return model.RestrictionEventTypeCreated, nil
	case trustv1.RestrictionEventType_RESTRICTION_EVENT_TYPE_LIFTED:
		return model.RestrictionEventTypeLifted, nil
	default:
		return "", fmt.Errorf("%w: unsupported restriction event type", app.ErrInvalidInput)
	}
}

func trustProfileToProto(profile model.TrustProfile) *trustv1.TrustProfile {
	return &trustv1.TrustProfile{
		UserId:       profile.UserID.String(),
		Score:        int32(profile.Score),
		Band:         trustBandToProto(profile.Band),
		Status:       trustStatusToProto(profile.Status),
		CalculatedAt: timestampOrNil(profile.CalculatedAt),
		UpdatedAt:    timestampOrNil(profile.UpdatedAt),
	}
}

func trustBandToProto(band model.TrustBand) trustv1.TrustBand {
	switch band {
	case model.TrustBandNew:
		return trustv1.TrustBand_TRUST_BAND_NEW
	case model.TrustBandLow:
		return trustv1.TrustBand_TRUST_BAND_LOW
	case model.TrustBandNormal:
		return trustv1.TrustBand_TRUST_BAND_NORMAL
	case model.TrustBandTrusted:
		return trustv1.TrustBand_TRUST_BAND_TRUSTED
	case model.TrustBandRisky:
		return trustv1.TrustBand_TRUST_BAND_RISKY
	case model.TrustBandBlocked:
		return trustv1.TrustBand_TRUST_BAND_BLOCKED
	default:
		return trustv1.TrustBand_TRUST_BAND_UNSPECIFIED
	}
}

func trustStatusToProto(status model.TrustStatus) trustv1.TrustStatus {
	switch status {
	case model.TrustStatusActive:
		return trustv1.TrustStatus_TRUST_STATUS_ACTIVE
	case model.TrustStatusUnderReview:
		return trustv1.TrustStatus_TRUST_STATUS_UNDER_REVIEW
	case model.TrustStatusRestricted:
		return trustv1.TrustStatus_TRUST_STATUS_RESTRICTED
	default:
		return trustv1.TrustStatus_TRUST_STATUS_UNSPECIFIED
	}
}

func parseRequiredUUID(raw string, field string) (uuid.UUID, error) {
	value, err := uuid.Parse(strings.TrimSpace(raw))
	if err != nil {
		return uuid.Nil, fmt.Errorf("%w: invalid %s", app.ErrInvalidInput, field)
	}
	if value == uuid.Nil {
		return uuid.Nil, fmt.Errorf("%w: %s is required", app.ErrInvalidInput, field)
	}
	return value, nil
}

func parseOptionalUUID(raw string, field string) (*uuid.UUID, error) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return nil, nil
	}
	value, err := uuid.Parse(raw)
	if err != nil {
		return nil, fmt.Errorf("%w: invalid %s", app.ErrInvalidInput, field)
	}
	return &value, nil
}

func uuidStrings(ids []uuid.UUID) []string {
	if len(ids) == 0 {
		return nil
	}
	values := make([]string, 0, len(ids))
	for _, id := range ids {
		values = append(values, id.String())
	}
	return values
}

func timestampOrNil(value time.Time) *timestamppb.Timestamp {
	if value.IsZero() {
		return nil
	}
	return timestamppb.New(value)
}
