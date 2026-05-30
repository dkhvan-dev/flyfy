package grpcclient

import (
	"context"
	"net"
	"testing"
	"time"

	"github.com/dkhvan-dev/flyfy/backend/pkg/trustpolicy"
	trustv1 "github.com/dkhvan-dev/flyfy/proto/gen/go/trust/v1"
	"github.com/google/uuid"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/test/bufconn"
)

func TestClientCheckActionPolicyMapsRequestAndResponse(t *testing.T) {
	t.Parallel()

	userID := uuid.New()
	server := &recordingTrustServer{
		response: &trustv1.CheckActionPolicyResponse{
			DecisionId:       "decision-1",
			Decision:         trustv1.PolicyDecision_POLICY_DECISION_REVIEW,
			ReasonCode:       "LOW_TRUST",
			PublicMessageKey: "trust.review_required",
		},
	}
	client := newTestClient(t, server)

	result, err := client.CheckActionPolicy(context.Background(), trustpolicy.Check{
		UserID:         userID,
		Action:         trustpolicy.ActionActivityCreate,
		ResourceType:   "activity",
		ResourceID:     "activity-1",
		IdempotencyKey: "idem-1",
		Metadata: map[string]any{
			"country": "KZ",
			"paid":    true,
		},
	})
	if err != nil {
		t.Fatalf("CheckActionPolicy returned error: %v", err)
	}

	if result.Decision != trustpolicy.DecisionReview {
		t.Fatalf("Decision = %q, want %q", result.Decision, trustpolicy.DecisionReview)
	}
	if result.DecisionID != "decision-1" || result.ReasonCode != "LOW_TRUST" || result.PublicMessageKey != "trust.review_required" {
		t.Fatalf("unexpected result: %+v", result)
	}
	if server.request.GetUserId() != userID.String() {
		t.Fatalf("UserId = %q, want %q", server.request.GetUserId(), userID.String())
	}
	if server.request.GetAction() != trustv1.PolicyAction_POLICY_ACTION_ACTIVITY_CREATE {
		t.Fatalf("Action = %s, want activity create", server.request.GetAction())
	}
	if server.request.GetResourceType() != "activity" || server.request.GetResourceId() != "activity-1" {
		t.Fatalf("unexpected resource fields: %+v", server.request)
	}
	if got := server.request.GetMetadata().GetFields()["country"].GetStringValue(); got != "KZ" {
		t.Fatalf("metadata.country = %q, want KZ", got)
	}
}

func TestClientCheckActionPolicySendsInternalMetadata(t *testing.T) {
	t.Parallel()

	server := &recordingTrustServer{
		response: &trustv1.CheckActionPolicyResponse{
			Decision: trustv1.PolicyDecision_POLICY_DECISION_ALLOW,
		},
	}
	client := newTestClient(t, server)

	if _, err := client.CheckActionPolicy(context.Background(), trustpolicy.Check{
		UserID: uuid.New(),
		Action: trustpolicy.ActionChatSend,
	}); err != nil {
		t.Fatalf("CheckActionPolicy returned error: %v", err)
	}

	if got := firstMetadataValue(server.metadata, "x-internal-service-token"); got != "internal-token" {
		t.Fatalf("x-internal-service-token = %q, want internal-token", got)
	}
	if got := firstMetadataValue(server.metadata, "x-service-name"); got != "activity-service" {
		t.Fatalf("x-service-name = %q, want activity-service", got)
	}
}

func TestClientCheckActionPolicyDefaultsUnspecifiedDecisionToAllow(t *testing.T) {
	t.Parallel()

	server := &recordingTrustServer{
		response: &trustv1.CheckActionPolicyResponse{},
	}
	client := newTestClient(t, server)

	result, err := client.CheckActionPolicy(context.Background(), trustpolicy.Check{
		UserID: uuid.New(),
		Action: trustpolicy.ActionFileBind,
	})
	if err != nil {
		t.Fatalf("CheckActionPolicy returned error: %v", err)
	}
	if result.Decision != trustpolicy.DecisionAllow {
		t.Fatalf("Decision = %q, want %q", result.Decision, trustpolicy.DecisionAllow)
	}
}

func newTestClient(t *testing.T, trustServer trustv1.TrustServiceServer) *Client {
	t.Helper()

	listener := bufconn.Listen(1024 * 1024)
	grpcServer := grpc.NewServer()
	trustv1.RegisterTrustServiceServer(grpcServer, trustServer)
	go func() {
		_ = grpcServer.Serve(listener)
	}()
	t.Cleanup(func() {
		grpcServer.Stop()
		_ = listener.Close()
	})

	client, err := New(
		"passthrough:///bufnet",
		"internal-token",
		"activity-service",
		time.Second,
		grpc.WithContextDialer(func(context.Context, string) (net.Conn, error) {
			return listener.Dial()
		}),
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		t.Fatalf("New returned error: %v", err)
	}
	t.Cleanup(func() {
		_ = client.Close()
	})
	return client
}

type recordingTrustServer struct {
	trustv1.UnimplementedTrustServiceServer

	request  *trustv1.CheckActionPolicyRequest
	metadata metadata.MD
	response *trustv1.CheckActionPolicyResponse
}

func (s *recordingTrustServer) CheckActionPolicy(ctx context.Context, req *trustv1.CheckActionPolicyRequest) (*trustv1.CheckActionPolicyResponse, error) {
	s.request = req
	s.metadata, _ = metadata.FromIncomingContext(ctx)
	return s.response, nil
}

func firstMetadataValue(md metadata.MD, key string) string {
	values := md.Get(key)
	if len(values) == 0 {
		return ""
	}
	return values[0]
}
