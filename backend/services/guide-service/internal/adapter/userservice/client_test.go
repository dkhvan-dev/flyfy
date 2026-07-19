package userservice

import (
	"context"
	"net"
	"testing"
	"time"

	"github.com/google/uuid"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/test/bufconn"

	userv1 "kz/inflap/proto/gen/go/user/v1"
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
				UserId:    userID.String(),
				FirstName: firstName,
				LastName:  lastName,
				Nickname:  "@nomad_aru",
				Locale:    "ru",
				Timezone:  "Asia/Almaty",
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

func TestGetSavedGuideUserSnapshotMapsPublicIdentityAndRevisions(t *testing.T) {
	userID := uuid.New()
	avatarFileID := uuid.New()
	accountUpdatedAt := time.Date(2026, 7, 10, 12, 0, 0, 0, time.UTC)
	profileUpdatedAt := accountUpdatedAt.Add(time.Minute)

	listener := bufconn.Listen(1024 * 1024)
	server := grpc.NewServer()
	userv1.RegisterUserServiceServer(server, &publicProfilesServer{
		aggregate: &userv1.UserAggregate{
			User: &userv1.User{
				Id:        userID.String(),
				Status:    "ACTIVE",
				UpdatedAt: accountUpdatedAt.Format(time.RFC3339Nano),
			},
			Profile: &userv1.UserProfile{
				UserId:       userID.String(),
				Nickname:     "Aruzhan",
				AvatarFileId: avatarFileID.String(),
				CountryCode:  "KZ",
				Locale:       "en",
				UpdatedAt:    profileUpdatedAt.Format(time.RFC3339Nano),
			},
		},
	})
	go func() { _ = server.Serve(listener) }()
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
	snapshot, err := client.GetSavedGuideUserSnapshot(context.Background(), userID)
	if err != nil {
		t.Fatalf("GetSavedGuideUserSnapshot() error = %v", err)
	}
	if snapshot.UserID != userID || snapshot.AccountStatus != "ACTIVE" || snapshot.IsDeleted {
		t.Fatalf("snapshot identity = %+v", snapshot)
	}
	if snapshot.AvatarFileID == nil || *snapshot.AvatarFileID != avatarFileID {
		t.Fatalf("avatar = %v", snapshot.AvatarFileID)
	}
	if !snapshot.AccountUpdatedAt.Equal(accountUpdatedAt) ||
		!snapshot.ProfileUpdatedAt.Equal(profileUpdatedAt) {
		t.Fatalf("snapshot revisions = %+v", snapshot)
	}
}

type publicProfilesServer struct {
	userv1.UnimplementedUserServiceServer
	items     []*userv1.PublicProfile
	aggregate *userv1.UserAggregate
}

func (s *publicProfilesServer) GetUserById(
	context.Context,
	*userv1.GetUserByIdRequest,
) (*userv1.GetUserByIdResponse, error) {
	return &userv1.GetUserByIdResponse{Aggregate: s.aggregate}, nil
}

func (s *publicProfilesServer) GetPublicProfilesByUserIds(
	context.Context,
	*userv1.GetPublicProfilesByUserIdsRequest,
) (*userv1.GetPublicProfilesByUserIdsResponse, error) {
	return &userv1.GetPublicProfilesByUserIdsResponse{Items: s.items}, nil
}
