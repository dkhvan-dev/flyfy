package userservice

import (
	"context"
	"net"
	"testing"

	"github.com/google/uuid"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/test/bufconn"

	userv1 "github.com/dkhvan-dev/flyfy/proto/gen/go/user/v1"
)

func TestGetPublicUserProfilesMapsLegalNameFields(t *testing.T) {
	userID := uuid.New()
	firstName := "Aruzhan"
	lastName := "Tulegenova"

	listener := bufconn.Listen(1024 * 1024)
	server := grpc.NewServer()
	userv1.RegisterUserServiceServer(server, &publicProfilesServer{
		items: []*userv1.PublicProfile{
			{
				UserId:      userID.String(),
				FirstName:   firstName,
				LastName:    lastName,
				DisplayName: "@nomad_aru",
				Locale:      "ru",
				Timezone:    "Asia/Almaty",
				IsPublic:    true,
			},
		},
	})
	go func() {
		_ = server.Serve(listener)
	}()
	defer server.Stop()

	conn, err := grpc.NewClient(
		"passthrough:///bufnet",
		grpc.WithContextDialer(func(context.Context, string) (net.Conn, error) {
			return listener.Dial()
		}),
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		t.Fatalf("new grpc client: %v", err)
	}
	defer conn.Close()

	client := &Client{conn: conn, service: userv1.NewUserServiceClient(conn)}
	profiles, err := client.GetPublicUserProfiles(context.Background(), []uuid.UUID{userID})
	if err != nil {
		t.Fatalf("GetPublicUserProfiles() error = %v", err)
	}

	profile, ok := profiles[userID]
	if !ok {
		t.Fatalf("profile for %s not found", userID)
	}
	if profile.FirstName == nil || *profile.FirstName != firstName {
		t.Fatalf("first name = %v, want %q", profile.FirstName, firstName)
	}
	if profile.LastName == nil || *profile.LastName != lastName {
		t.Fatalf("last name = %v, want %q", profile.LastName, lastName)
	}
}

type publicProfilesServer struct {
	userv1.UnimplementedUserServiceServer
	items []*userv1.PublicProfile
}

func (s *publicProfilesServer) GetPublicProfilesByUserIds(
	context.Context,
	*userv1.GetPublicProfilesByUserIdsRequest,
) (*userv1.GetPublicProfilesByUserIdsResponse, error) {
	return &userv1.GetPublicProfilesByUserIdsResponse{Items: s.items}, nil
}
