package grpcclient

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/dkhvan-dev/flyfy/backend/pkg/trustpolicy"
	trustv1 "github.com/dkhvan-dev/flyfy/proto/gen/go/trust/v1"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/metadata"
	"google.golang.org/protobuf/types/known/structpb"
	"google.golang.org/protobuf/types/known/timestamppb"
)

const (
	internalTokenHeader = "x-internal-service-token"
	serviceNameHeader   = "x-service-name"
	defaultTimeout      = 250 * time.Millisecond
)

type Client struct {
	conn          *grpc.ClientConn
	service       trustv1.TrustServiceClient
	internalToken string
	serviceName   string
	timeout       time.Duration
}

func New(target string, internalToken string, serviceName string, timeout time.Duration, opts ...grpc.DialOption) (*Client, error) {
	target = strings.TrimSpace(target)
	internalToken = strings.TrimSpace(internalToken)
	serviceName = strings.TrimSpace(serviceName)
	if target == "" {
		return nil, errors.New("trustpolicy: target is required")
	}
	if internalToken == "" {
		return nil, errors.New("trustpolicy: internal service token is required")
	}
	if serviceName == "" {
		return nil, errors.New("trustpolicy: service name is required")
	}
	if timeout <= 0 {
		timeout = defaultTimeout
	}
	if len(opts) == 0 {
		opts = []grpc.DialOption{grpc.WithTransportCredentials(insecure.NewCredentials())}
	}

	conn, err := grpc.NewClient(target, opts...)
	if err != nil {
		return nil, err
	}
	return &Client{
		conn:          conn,
		service:       trustv1.NewTrustServiceClient(conn),
		internalToken: internalToken,
		serviceName:   serviceName,
		timeout:       timeout,
	}, nil
}

func (c *Client) Close() error {
	if c == nil || c.conn == nil {
		return nil
	}
	return c.conn.Close()
}

func (c *Client) CheckActionPolicy(ctx context.Context, check trustpolicy.Check) (trustpolicy.Result, error) {
	callCtx, cancel := context.WithTimeout(ctx, c.timeout)
	defer cancel()
	callCtx = metadata.AppendToOutgoingContext(
		callCtx,
		internalTokenHeader, c.internalToken,
		serviceNameHeader, c.serviceName,
	)

	metadataStruct, err := structpb.NewStruct(check.Metadata)
	if err != nil {
		return trustpolicy.Result{}, err
	}
	resp, err := c.service.CheckActionPolicy(callCtx, &trustv1.CheckActionPolicyRequest{
		UserId:         check.UserID.String(),
		Action:         actionToProto(check.Action),
		ResourceType:   check.ResourceType,
		ResourceId:     check.ResourceID,
		IdempotencyKey: check.IdempotencyKey,
		Metadata:       metadataStruct,
		RequestedAt:    timestamppb.Now(),
	})
	if err != nil {
		return trustpolicy.Result{}, err
	}
	return trustpolicy.Result{
		Decision:         decisionFromProto(resp.GetDecision()),
		ReasonCode:       resp.GetReasonCode(),
		PublicMessageKey: resp.GetPublicMessageKey(),
		DecisionID:       resp.GetDecisionId(),
	}, nil
}

func actionToProto(action trustpolicy.Action) trustv1.PolicyAction {
	switch action {
	case trustpolicy.ActionActivityCreate:
		return trustv1.PolicyAction_POLICY_ACTION_ACTIVITY_CREATE
	case trustpolicy.ActionTourPublish:
		return trustv1.PolicyAction_POLICY_ACTION_TOUR_PUBLISH
	case trustpolicy.ActionChatSend:
		return trustv1.PolicyAction_POLICY_ACTION_CHAT_SEND
	case trustpolicy.ActionFileUpload:
		return trustv1.PolicyAction_POLICY_ACTION_FILE_UPLOAD
	case trustpolicy.ActionFileBind:
		return trustv1.PolicyAction_POLICY_ACTION_FILE_BIND
	case trustpolicy.ActionPayoutRequest:
		return trustv1.PolicyAction_POLICY_ACTION_PAYOUT_REQUEST
	case trustpolicy.ActionGuideApplicationSubmit:
		return trustv1.PolicyAction_POLICY_ACTION_GUIDE_APPLICATION_SUBMIT
	default:
		return trustv1.PolicyAction_POLICY_ACTION_UNSPECIFIED
	}
}

func decisionFromProto(decision trustv1.PolicyDecision) trustpolicy.Decision {
	switch decision {
	case trustv1.PolicyDecision_POLICY_DECISION_DENY:
		return trustpolicy.DecisionDeny
	case trustv1.PolicyDecision_POLICY_DECISION_REVIEW:
		return trustpolicy.DecisionReview
	case trustv1.PolicyDecision_POLICY_DECISION_QUARANTINE:
		return trustpolicy.DecisionQuarantine
	case trustv1.PolicyDecision_POLICY_DECISION_PENDING:
		return trustpolicy.DecisionPending
	default:
		return trustpolicy.DecisionAllow
	}
}
