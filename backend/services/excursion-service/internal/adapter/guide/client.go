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

	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/port"
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

func (c *Client) VerifyExcursionGuide(ctx context.Context, userID uuid.UUID) (port.GuideExcursionPermission, error) {
	callCtx, cancel := context.WithTimeout(ctx, verifyTimeout)
	defer cancel()

	resp, err := c.service.GetGuideProfileByUserId(callCtx, &guidev1.GetGuideProfileByUserIdRequest{
		UserId: userID.String(),
	})
	if err != nil {
		if st, ok := status.FromError(err); ok && st.Code() == codes.NotFound {
			return port.GuideExcursionPermission{}, app.ErrGuideNotAllowed
		}
		return port.GuideExcursionPermission{}, err
	}

	profile := resp.GetAggregate().GetProfile()
	if profile == nil {
		return port.GuideExcursionPermission{}, app.ErrGuideNotAllowed
	}
	profileID, err := uuid.Parse(strings.TrimSpace(profile.GetId()))
	if err != nil {
		return port.GuideExcursionPermission{}, app.ErrGuideNotAllowed
	}
	profileUserID, err := uuid.Parse(strings.TrimSpace(profile.GetUserId()))
	if err != nil {
		return port.GuideExcursionPermission{}, app.ErrGuideNotAllowed
	}

	userProfile := resp.GetAggregate().GetUserProfile()
	firstName := strings.TrimSpace(userProfile.GetFirstName())
	lastName := strings.TrimSpace(userProfile.GetLastName())
	nickname := normalizeGuideNamePart(userProfile.GetDisplayName())
	displayName := guideDisplayName(
		nickname,
		firstName,
		lastName,
	)
	searchText := guideSearchText(
		nickname,
		displayName,
		firstName,
		lastName,
		fullName(firstName, lastName),
		fullName(lastName, firstName),
		lastNameWithInitial(lastName, firstName),
		profile.GetHeadline(),
		profile.GetAbout(),
		profileID.String(),
		profileUserID.String(),
	)

	allowed := profileUserID == userID &&
		strings.EqualFold(profile.GetStatus(), "ACTIVE") &&
		profile.GetIsExcursionGuideAvailable()

	return port.GuideExcursionPermission{
		GuideProfileID:  profileID,
		GuideUserID:     profileUserID,
		Allowed:         allowed,
		RatingAvg:       profile.GetRatingAvg(),
		ReviewsCount:    int(profile.GetReviewsCount()),
		ExperienceYears: int(profile.GetExperienceYears()),
		DisplayName:     displayName,
		Nickname:        nickname,
		FirstName:       firstName,
		LastName:        lastName,
		GuideSearchText: searchText,
	}, nil
}

func guideDisplayName(displayName string, firstName string, lastName string) string {
	displayName = normalizeGuideNamePart(displayName)
	if displayName != "" {
		return displayName
	}
	return fullName(firstName, lastName)
}

func normalizeGuideNamePart(value string) string {
	return strings.Join(strings.Fields(strings.TrimSpace(value)), " ")
}

func guideSearchText(values ...string) string {
	seen := make(map[string]struct{}, len(values)*2)
	parts := make([]string, 0, len(values)*2)
	for _, value := range values {
		value = strings.Join(strings.Fields(strings.TrimSpace(value)), " ")
		if value == "" {
			continue
		}
		appendGuideSearchPart(&parts, seen, value)
		if strings.HasPrefix(value, "@") {
			appendGuideSearchPart(&parts, seen, strings.TrimPrefix(value, "@"))
		}
	}
	return strings.Join(parts, " ")
}

func appendGuideSearchPart(parts *[]string, seen map[string]struct{}, value string) {
	key := strings.ToLower(value)
	if _, ok := seen[key]; ok {
		return
	}
	seen[key] = struct{}{}
	*parts = append(*parts, value)
}

func fullName(first string, last string) string {
	return strings.Join(strings.Fields(strings.TrimSpace(first)+" "+strings.TrimSpace(last)), " ")
}

func lastNameWithInitial(last string, first string) string {
	last = strings.TrimSpace(last)
	first = strings.TrimSpace(first)
	if last == "" || first == "" {
		return ""
	}
	return last + " " + string([]rune(first)[0])
}
