package guide

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/status"

	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/port"
	guidev1 "github.com/dkhvan-dev/flyfy/proto/gen/go/guide/v1"
)

const verifyTimeout = 3 * time.Second

type Client struct {
	conn    *grpc.ClientConn
	service guidev1.GuideServiceClient
}

func New(target string, opts ...grpc.DialOption) (*Client, error) {
	if len(opts) == 0 {
		opts = []grpc.DialOption{grpc.WithTransportCredentials(insecure.NewCredentials())}
	}
	conn, err := grpc.NewClient(strings.TrimSpace(target), opts...)
	if err != nil {
		return nil, err
	}
	return &Client{conn: conn, service: guidev1.NewGuideServiceClient(conn)}, nil
}

func (c *Client) Close() error {
	return c.conn.Close()
}

func (c *Client) VerifyTourGuide(ctx context.Context, userID uuid.UUID) (port.GuideTourPermission, error) {
	callCtx, cancel := context.WithTimeout(ctx, verifyTimeout)
	defer cancel()

	resp, err := c.service.GetGuideProfileByUserId(callCtx, &guidev1.GetGuideProfileByUserIdRequest{
		UserId: userID.String(),
	})
	if err != nil {
		if st, ok := status.FromError(err); ok && st.Code() == codes.NotFound {
			return port.GuideTourPermission{}, app.ErrGuideNotAllowed
		}
		return port.GuideTourPermission{}, err
	}

	profile := resp.GetAggregate().GetProfile()
	if profile == nil {
		return port.GuideTourPermission{}, app.ErrGuideNotAllowed
	}
	profileID, err := uuid.Parse(strings.TrimSpace(profile.GetId()))
	if err != nil {
		return port.GuideTourPermission{}, app.ErrGuideNotAllowed
	}
	profileUserID, err := uuid.Parse(strings.TrimSpace(profile.GetUserId()))
	if err != nil {
		return port.GuideTourPermission{}, app.ErrGuideNotAllowed
	}

	allowed := profileUserID == userID &&
		strings.EqualFold(profile.GetStatus(), "ACTIVE") &&
		profile.GetIsTourGuideAvailable()

	return port.GuideTourPermission{
		GuideProfileID: profileID,
		GuideUserID:    profileUserID,
		Allowed:        allowed,
	}, nil
}
