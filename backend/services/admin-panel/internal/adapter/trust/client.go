package trust

import (
	"context"
	"encoding/json"
	"strings"
	"time"

	"github.com/google/uuid"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/timestamppb"

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

func (c *Client) withInternalMetadata(ctx context.Context) context.Context {
	md := metadata.New(map[string]string{
		"x-internal-service-token": c.internalToken,
		"x-service-name":           c.serviceName,
	})
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
