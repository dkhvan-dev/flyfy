package trust

import (
	"context"
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/timestamppb"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/admin-panel/internal/app"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
	trustv1 "kz/inflap/proto/gen/go/trust/v1"
)

const defaultTrustTimeout = 3 * time.Second

type Client struct {
	conn          *grpc.ClientConn
	service       trustv1.TrustServiceClient
	internalToken string
	serviceName   string
	timeout       time.Duration
}

func NewWithTransportAuth(
	target string,
	internalToken string,
	serviceName string,
	timeout time.Duration,
	auth transportauth.Config,
	opts ...grpc.DialOption,
) (*Client, error) {
	if len(opts) == 0 {
		dialOptions, err := transportauth.GRPCDialOptions(auth)
		if err != nil {
			return nil, fmt.Errorf("initialize admin trust mTLS transport: %w", err)
		}
		opts = dialOptions
	}
	return New(target, internalToken, serviceName, timeout, opts...)
}

func New(target string, internalToken string, serviceName string, timeout time.Duration, opts ...grpc.DialOption) (*Client, error) {
	if len(opts) == 0 {
		opts = []grpc.DialOption{grpc.WithTransportCredentials(insecure.NewCredentials())}
	}
	if timeout <= 0 {
		timeout = defaultTrustTimeout
	}
	conn, err := grpc.NewClient(strings.TrimSpace(target), opts...)
	if err != nil {
		return nil, err
	}
	return &Client{
		conn:          conn,
		service:       trustv1.NewTrustServiceClient(conn),
		internalToken: strings.TrimSpace(internalToken),
		serviceName:   strings.TrimSpace(serviceName),
		timeout:       timeout,
	}, nil
}

func (c *Client) Close() error {
	return c.conn.Close()
}

func (c *Client) ApplyUserRestrictionEvent(ctx context.Context, event model.UserRestrictionOutboxEvent) (bool, error) {
	payload, err := decodeRestrictionPayload(event)
	if err != nil {
		return false, err
	}

	callCtx, cancel := context.WithTimeout(ctx, c.timeout)
	defer cancel()
	callCtx = c.withInternalMetadata(callCtx)

	resp, err := c.service.ApplyUserRestrictionEvent(callCtx, &trustv1.ApplyUserRestrictionEventRequest{
		EventId:          event.ID.String(),
		EventType:        restrictionEventTypeToProto(event.EventType),
		RestrictionId:    payload.RestrictionID.String(),
		UserId:           payload.UserID.String(),
		CaseId:           uuidStringPtr(payload.CaseID),
		RestrictionCode:  string(payload.RestrictionCode),
		ReasonCode:       payload.ReasonCode,
		CreatedByStaffId: uuidString(payload.CreatedByStaffID),
		LiftedByStaffId:  uuidStringPtr(payload.LiftedByStaffID),
		ExpiresAt:        timestampPtr(payload.ExpiresAt),
		OccurredAt:       timestampValue(payload.OccurredAt),
	})
	if err != nil {
		return false, mapTrustServiceError(err)
	}
	return resp.GetApplied(), nil
}

func (c *Client) ListRestrictionAppeals(
	ctx context.Context,
	filter model.TrustRestrictionAppealFilter,
) (model.TrustRestrictionAppealListPage, error) {
	callCtx, cancel := context.WithTimeout(ctx, c.timeout)
	defer cancel()
	callCtx = c.withInternalMetadata(callCtx)

	resp, err := c.service.ListRestrictionAppeals(callCtx, &trustv1.ListRestrictionAppealsRequest{
		Status: trustAppealStatusToProto(filter.Status),
	})
	if err != nil {
		return model.TrustRestrictionAppealListPage{}, mapTrustServiceError(err)
	}

	items := make([]model.TrustRestrictionAppeal, 0, len(resp.GetAppeals()))
	query := strings.ToLower(strings.TrimSpace(filter.Query))
	for _, appeal := range resp.GetAppeals() {
		item := trustAppealFromProto(appeal)
		if query != "" && !trustAppealMatchesQuery(item, query) {
			continue
		}
		items = append(items, item)
	}

	offset := pageOffset(filter.PageToken)
	if offset > len(items) {
		offset = len(items)
	}
	limit := filter.PageSize
	if limit <= 0 {
		limit = 50
	}
	end := offset + limit
	nextPageToken := ""
	if end < len(items) {
		nextPageToken = strconv.Itoa(end)
	} else {
		end = len(items)
	}

	return model.TrustRestrictionAppealListPage{
		Items:         items[offset:end],
		NextPageToken: nextPageToken,
	}, nil
}

func (c *Client) GetRestrictionAppeal(
	ctx context.Context,
	id uuid.UUID,
) (model.TrustRestrictionAppeal, error) {
	if id == uuid.Nil {
		return model.TrustRestrictionAppeal{}, app.ErrInvalidInput
	}
	page, err := c.ListRestrictionAppeals(ctx, model.TrustRestrictionAppealFilter{
		PageSize: 1000,
	})
	if err != nil {
		return model.TrustRestrictionAppeal{}, err
	}
	for _, item := range page.Items {
		if item.ID == id {
			return item, nil
		}
	}
	return model.TrustRestrictionAppeal{}, app.ErrInvalidInput
}

func (c *Client) DecideRestrictionAppeal(
	ctx context.Context,
	input model.TrustRestrictionAppealDecisionInput,
) (model.TrustRestrictionAppeal, error) {
	callCtx, cancel := context.WithTimeout(ctx, c.timeout)
	defer cancel()
	callCtx = c.withInternalMetadata(callCtx, input.RequestID)

	resp, err := c.service.DecideRestrictionAppeal(callCtx, &trustv1.DecideRestrictionAppealRequest{
		AppealId:        uuidString(input.AppealID),
		ActorStaffId:    uuidString(input.ActorStaffID),
		Decision:        trustAppealDecisionToProto(input.Decision),
		ReasonCode:      strings.TrimSpace(input.ReasonCode),
		StaffComment:    strings.TrimSpace(input.StaffComment),
		DecisionEventId: decisionEventID(input),
	})
	if err != nil {
		return model.TrustRestrictionAppeal{}, mapTrustServiceError(err)
	}
	return trustAppealFromProto(resp.GetAppeal()), nil
}

func (c *Client) withInternalMetadata(ctx context.Context, requestID ...string) context.Context {
	md := metadata.New(map[string]string{
		"x-internal-service-token": c.internalToken,
		"x-service-name":           c.serviceName,
	})
	if len(requestID) > 0 && strings.TrimSpace(requestID[0]) != "" {
		md.Set("x-request-id", strings.TrimSpace(requestID[0]))
	}
	return metadata.NewOutgoingContext(ctx, md)
}

type restrictionPayload struct {
	RestrictionID    uuid.UUID                 `json:"restrictionId"`
	UserID           uuid.UUID                 `json:"userId"`
	CaseID           *uuid.UUID                `json:"caseId,omitempty"`
	RestrictionCode  model.UserRestrictionCode `json:"restrictionCode"`
	ReasonCode       string                    `json:"reasonCode"`
	CreatedByStaffID uuid.UUID                 `json:"createdByStaffId"`
	LiftedByStaffID  *uuid.UUID                `json:"liftedByStaffId,omitempty"`
	ExpiresAt        *time.Time                `json:"expiresAt,omitempty"`
	OccurredAt       time.Time                 `json:"occurredAt"`
}

func decodeRestrictionPayload(event model.UserRestrictionOutboxEvent) (restrictionPayload, error) {
	var payload restrictionPayload
	if len(event.Payload) > 0 {
		if err := json.Unmarshal(event.Payload, &payload); err != nil {
			return restrictionPayload{}, app.ErrInvalidInput
		}
	}
	if payload.RestrictionID == uuid.Nil {
		payload.RestrictionID = event.AggregateID
	}
	if payload.UserID == uuid.Nil {
		payload.UserID = event.UserID
	}
	if payload.OccurredAt.IsZero() {
		payload.OccurredAt = event.CreatedAt
	}
	return payload, nil
}

func restrictionEventTypeToProto(eventType string) trustv1.RestrictionEventType {
	switch eventType {
	case model.UserRestrictionOutboxEventCreated:
		return trustv1.RestrictionEventType_RESTRICTION_EVENT_TYPE_CREATED
	case model.UserRestrictionOutboxEventLifted:
		return trustv1.RestrictionEventType_RESTRICTION_EVENT_TYPE_LIFTED
	default:
		return trustv1.RestrictionEventType_RESTRICTION_EVENT_TYPE_UNSPECIFIED
	}
}

func trustAppealStatusToProto(status model.TrustRestrictionAppealStatus) trustv1.RestrictionAppealStatus {
	switch status {
	case model.TrustRestrictionAppealStatusOpen:
		return trustv1.RestrictionAppealStatus_RESTRICTION_APPEAL_STATUS_PENDING
	case model.TrustRestrictionAppealStatusApproved:
		return trustv1.RestrictionAppealStatus_RESTRICTION_APPEAL_STATUS_APPROVED
	case model.TrustRestrictionAppealStatusRejected:
		return trustv1.RestrictionAppealStatus_RESTRICTION_APPEAL_STATUS_REJECTED
	default:
		return trustv1.RestrictionAppealStatus_RESTRICTION_APPEAL_STATUS_UNSPECIFIED
	}
}

func trustAppealStatusFromProto(status trustv1.RestrictionAppealStatus) model.TrustRestrictionAppealStatus {
	switch status {
	case trustv1.RestrictionAppealStatus_RESTRICTION_APPEAL_STATUS_APPROVED:
		return model.TrustRestrictionAppealStatusApproved
	case trustv1.RestrictionAppealStatus_RESTRICTION_APPEAL_STATUS_REJECTED:
		return model.TrustRestrictionAppealStatusRejected
	default:
		return model.TrustRestrictionAppealStatusOpen
	}
}

func trustAppealDecisionToProto(decision model.TrustRestrictionAppealDecision) trustv1.RestrictionAppealDecision {
	switch decision {
	case model.TrustRestrictionAppealDecisionApprove:
		return trustv1.RestrictionAppealDecision_RESTRICTION_APPEAL_DECISION_APPROVE
	case model.TrustRestrictionAppealDecisionReject:
		return trustv1.RestrictionAppealDecision_RESTRICTION_APPEAL_DECISION_REJECT
	default:
		return trustv1.RestrictionAppealDecision_RESTRICTION_APPEAL_DECISION_UNSPECIFIED
	}
}

func trustAppealDecisionFromProto(status trustv1.RestrictionAppealStatus) *model.TrustRestrictionAppealDecision {
	switch status {
	case trustv1.RestrictionAppealStatus_RESTRICTION_APPEAL_STATUS_APPROVED:
		decision := model.TrustRestrictionAppealDecisionApprove
		return &decision
	case trustv1.RestrictionAppealStatus_RESTRICTION_APPEAL_STATUS_REJECTED:
		decision := model.TrustRestrictionAppealDecisionReject
		return &decision
	default:
		return nil
	}
}

func trustAppealFromProto(appeal *trustv1.RestrictionAppeal) model.TrustRestrictionAppeal {
	if appeal == nil {
		return model.TrustRestrictionAppeal{}
	}
	return model.TrustRestrictionAppeal{
		ID:               parseUUIDOrNil(appeal.GetAppealId()),
		RestrictionID:    parseUUIDOrNil(appeal.GetRestrictionId()),
		UserID:           parseUUIDOrNil(appeal.GetUserId()),
		Status:           trustAppealStatusFromProto(appeal.GetStatus()),
		ReasonCode:       appeal.GetReasonCode(),
		UserMessage:      appeal.GetUserMessage(),
		StaffDecision:    trustAppealDecisionFromProto(appeal.GetStatus()),
		StaffComment:     appeal.GetStaffComment(),
		DecidedByStaffID: uuidPtrFromString(appeal.GetDecidedByStaffId()),
		CreatedAt:        timeFromProto(appeal.GetCreatedAt()),
		UpdatedAt:        timeFromProto(appeal.GetUpdatedAt()),
		DecidedAt:        timePtrFromProto(appeal.GetDecidedAt()),
	}
}

func mapTrustServiceError(err error) error {
	if st, ok := status.FromError(err); ok {
		switch st.Code() {
		case codes.InvalidArgument:
			return app.ErrInvalidInput
		default:
			return err
		}
	}
	return err
}

func uuidString(value uuid.UUID) string {
	if value == uuid.Nil {
		return ""
	}
	return value.String()
}

func uuidStringPtr(value *uuid.UUID) string {
	if value == nil || *value == uuid.Nil {
		return ""
	}
	return value.String()
}

func timestampPtr(value *time.Time) *timestamppb.Timestamp {
	if value == nil || value.IsZero() {
		return nil
	}
	return timestamppb.New(*value)
}

func timestampValue(value time.Time) *timestamppb.Timestamp {
	if value.IsZero() {
		return nil
	}
	return timestamppb.New(value)
}

func trustAppealMatchesQuery(item model.TrustRestrictionAppeal, query string) bool {
	return strings.Contains(strings.ToLower(item.ID.String()), query) ||
		strings.Contains(strings.ToLower(item.UserID.String()), query) ||
		strings.Contains(strings.ToLower(item.RestrictionID.String()), query) ||
		strings.Contains(strings.ToLower(item.ReasonCode), query)
}

func pageOffset(token string) int {
	parsed, err := strconv.Atoi(strings.TrimSpace(token))
	if err != nil || parsed < 0 {
		return 0
	}
	return parsed
}

func parseUUIDOrNil(value string) uuid.UUID {
	id, err := uuid.Parse(strings.TrimSpace(value))
	if err != nil {
		return uuid.Nil
	}
	return id
}

func uuidPtrFromString(value string) *uuid.UUID {
	id := parseUUIDOrNil(value)
	if id == uuid.Nil {
		return nil
	}
	return &id
}

func timeFromProto(value *timestamppb.Timestamp) time.Time {
	if value == nil {
		return time.Time{}
	}
	return value.AsTime()
}

func timePtrFromProto(value *timestamppb.Timestamp) *time.Time {
	if value == nil {
		return nil
	}
	parsed := value.AsTime()
	if parsed.IsZero() {
		return nil
	}
	return &parsed
}

func decisionEventID(input model.TrustRestrictionAppealDecisionInput) string {
	key := strings.TrimSpace(input.IdempotencyKey)
	if parsed, err := uuid.Parse(key); err == nil {
		return parsed.String()
	}
	if key == "" {
		return uuid.NewString()
	}
	return uuid.NewSHA1(
		uuid.NameSpaceOID,
		[]byte(input.AppealID.String()+":"+key),
	).String()
}
