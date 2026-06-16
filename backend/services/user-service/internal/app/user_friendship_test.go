package app

import (
	"context"
	"errors"
	"sort"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/user-service/internal/domain/enum"
	"kz/inflap/backend/services/user-service/internal/domain/model"
	"kz/inflap/backend/services/user-service/internal/domain/port"
)

func TestSendFriendRequestCreatesOutgoingStatus(t *testing.T) {
	ctx := context.Background()
	viewerID := uuid.New()
	targetID := uuid.New()
	repo := newFriendshipTestRepository(viewerID, targetID)
	useCase := NewUserUseCase(repo, nil)

	got, err := useCase.SendFriendRequest(ctx, viewerID, targetID)
	if err != nil {
		t.Fatalf("SendFriendRequest returned error: %v", err)
	}

	if got.Status != FriendshipStatusOutgoingRequest {
		t.Fatalf("status = %q, want %q", got.Status, FriendshipStatusOutgoingRequest)
	}

	status, err := useCase.GetFriendshipSummary(ctx, viewerID, targetID)
	if err != nil {
		t.Fatalf("GetFriendshipSummary returned error: %v", err)
	}
	if status.Status != FriendshipStatusOutgoingRequest {
		t.Fatalf("viewer status = %q, want %q", status.Status, FriendshipStatusOutgoingRequest)
	}
}

func TestAcceptFriendRequestTransitionsToFriends(t *testing.T) {
	ctx := context.Background()
	viewerID := uuid.New()
	targetID := uuid.New()
	repo := newFriendshipTestRepository(viewerID, targetID)
	useCase := NewUserUseCase(repo, nil)

	if _, err := useCase.SendFriendRequest(ctx, targetID, viewerID); err != nil {
		t.Fatalf("SendFriendRequest returned error: %v", err)
	}

	incoming, err := useCase.GetFriendshipSummary(ctx, viewerID, targetID)
	if err != nil {
		t.Fatalf("GetFriendshipSummary returned error: %v", err)
	}
	if incoming.Status != FriendshipStatusIncomingRequest {
		t.Fatalf("status before accept = %q, want %q", incoming.Status, FriendshipStatusIncomingRequest)
	}

	accepted, err := useCase.AcceptFriendRequest(ctx, viewerID, targetID)
	if err != nil {
		t.Fatalf("AcceptFriendRequest returned error: %v", err)
	}
	if accepted.Status != FriendshipStatusFriends {
		t.Fatalf("status after accept = %q, want %q", accepted.Status, FriendshipStatusFriends)
	}
}

func TestDeclineIncomingFriendRequestClearsRelationship(t *testing.T) {
	ctx := context.Background()
	viewerID := uuid.New()
	targetID := uuid.New()
	repo := newFriendshipTestRepository(viewerID, targetID)
	useCase := NewUserUseCase(repo, nil)

	if _, err := useCase.SendFriendRequest(ctx, targetID, viewerID); err != nil {
		t.Fatalf("SendFriendRequest returned error: %v", err)
	}

	incoming, err := useCase.GetFriendshipSummary(ctx, viewerID, targetID)
	if err != nil {
		t.Fatalf("GetFriendshipSummary returned error: %v", err)
	}
	if incoming.Status != FriendshipStatusIncomingRequest {
		t.Fatalf("status before decline = %q, want %q", incoming.Status, FriendshipStatusIncomingRequest)
	}

	declined, err := useCase.DeclineFriendRequest(ctx, viewerID, targetID)
	if err != nil {
		t.Fatalf("DeclineFriendRequest returned error: %v", err)
	}
	if declined.Status != FriendshipStatusNone {
		t.Fatalf("status after decline = %q, want %q", declined.Status, FriendshipStatusNone)
	}
}

func TestRemoveFriendClearsRelationship(t *testing.T) {
	ctx := context.Background()
	viewerID := uuid.New()
	targetID := uuid.New()
	repo := newFriendshipTestRepository(viewerID, targetID)
	useCase := NewUserUseCase(repo, nil)

	if _, err := useCase.SendFriendRequest(ctx, viewerID, targetID); err != nil {
		t.Fatalf("SendFriendRequest returned error: %v", err)
	}
	if _, err := useCase.AcceptFriendRequest(ctx, targetID, viewerID); err != nil {
		t.Fatalf("AcceptFriendRequest returned error: %v", err)
	}

	got, err := useCase.RemoveFriend(ctx, viewerID, targetID)
	if err != nil {
		t.Fatalf("RemoveFriend returned error: %v", err)
	}
	if got.Status != FriendshipStatusNone {
		t.Fatalf("status after remove = %q, want %q", got.Status, FriendshipStatusNone)
	}
}

func TestListFriendsUsesAcceptedFriendshipsOnly(t *testing.T) {
	ctx := context.Background()
	viewerID := uuid.New()
	friendID := uuid.New()
	pendingID := uuid.New()
	repo := newFriendshipTestRepository(viewerID, friendID, pendingID)
	useCase := NewUserUseCase(repo, nil)

	if _, err := useCase.SendFriendRequest(ctx, viewerID, friendID); err != nil {
		t.Fatalf("SendFriendRequest returned error: %v", err)
	}
	if _, err := useCase.AcceptFriendRequest(ctx, friendID, viewerID); err != nil {
		t.Fatalf("AcceptFriendRequest returned error: %v", err)
	}
	if _, err := useCase.SendFriendRequest(ctx, viewerID, pendingID); err != nil {
		t.Fatalf("SendFriendRequest pending returned error: %v", err)
	}

	page, err := useCase.ListFriends(ctx, viewerID, ProfileConnectionsListInput{
		Limit:  10,
		Offset: 0,
	})
	if err != nil {
		t.Fatalf("ListFriends returned error: %v", err)
	}
	if len(page.Items) != 1 {
		t.Fatalf("friends length = %d, want 1", len(page.Items))
	}
	if page.Items[0].UserID != friendID {
		t.Fatalf("friend id = %s, want %s", page.Items[0].UserID, friendID)
	}
}

func TestListIncomingFriendRequestsUsesMostRecentPendingRequests(t *testing.T) {
	ctx := context.Background()
	viewerID := uuid.New()
	olderRequesterID := uuid.New()
	newerRequesterID := uuid.New()
	acceptedRequesterID := uuid.New()
	repo := newFriendshipTestRepository(
		viewerID,
		olderRequesterID,
		newerRequesterID,
		acceptedRequesterID,
	)
	useCase := NewUserUseCase(repo, nil)

	if _, err := useCase.SendFriendRequest(ctx, olderRequesterID, viewerID); err != nil {
		t.Fatalf("SendFriendRequest older returned error: %v", err)
	}
	if _, err := useCase.SendFriendRequest(ctx, newerRequesterID, viewerID); err != nil {
		t.Fatalf("SendFriendRequest newer returned error: %v", err)
	}
	if _, err := useCase.SendFriendRequest(ctx, acceptedRequesterID, viewerID); err != nil {
		t.Fatalf("SendFriendRequest accepted returned error: %v", err)
	}
	if _, err := useCase.AcceptFriendRequest(ctx, viewerID, acceptedRequesterID); err != nil {
		t.Fatalf("AcceptFriendRequest returned error: %v", err)
	}

	now := time.Now().UTC()
	olderRequestedAt := now.Add(-2 * time.Hour)
	newerRequestedAt := now.Add(-30 * time.Minute)
	repo.setFriendshipRequestedAt(olderRequesterID, viewerID, olderRequestedAt)
	repo.setFriendshipRequestedAt(newerRequesterID, viewerID, newerRequestedAt)

	page, err := useCase.ListIncomingFriendRequests(ctx, viewerID, ProfileConnectionsListInput{
		Limit:  1,
		Offset: 0,
	})
	if err != nil {
		t.Fatalf("ListIncomingFriendRequests returned error: %v", err)
	}
	if len(page.Items) != 1 {
		t.Fatalf("request length = %d, want 1", len(page.Items))
	}
	if page.Items[0].Profile.UserID != newerRequesterID {
		t.Fatalf("requester id = %s, want %s", page.Items[0].Profile.UserID, newerRequesterID)
	}
	if !page.Items[0].RequestedAt.Equal(newerRequestedAt) {
		t.Fatalf("requested at = %s, want %s", page.Items[0].RequestedAt, newerRequestedAt)
	}
	if page.NextOffset == nil || *page.NextOffset != 1 {
		t.Fatalf("next offset = %v, want 1", page.NextOffset)
	}

	nextPage, err := useCase.ListIncomingFriendRequests(ctx, viewerID, ProfileConnectionsListInput{
		Limit:  1,
		Offset: 1,
	})
	if err != nil {
		t.Fatalf("ListIncomingFriendRequests next page returned error: %v", err)
	}
	if len(nextPage.Items) != 1 {
		t.Fatalf("next request length = %d, want 1", len(nextPage.Items))
	}
	if nextPage.Items[0].Profile.UserID != olderRequesterID {
		t.Fatalf("next requester id = %s, want %s", nextPage.Items[0].Profile.UserID, olderRequesterID)
	}
	if nextPage.NextOffset != nil {
		t.Fatalf("next page offset = %v, want nil", *nextPage.NextOffset)
	}
}

func TestFilterFriendUserIDsReturnsOnlyAcceptedFriendships(t *testing.T) {
	ctx := context.Background()
	viewerID := uuid.New()
	friendID := uuid.New()
	pendingID := uuid.New()
	strangerID := uuid.New()
	repo := newFriendshipTestRepository(viewerID, friendID, pendingID, strangerID)
	useCase := NewUserUseCase(repo, nil)

	if _, err := useCase.SendFriendRequest(ctx, viewerID, friendID); err != nil {
		t.Fatalf("SendFriendRequest friend returned error: %v", err)
	}
	if _, err := useCase.AcceptFriendRequest(ctx, friendID, viewerID); err != nil {
		t.Fatalf("AcceptFriendRequest friend returned error: %v", err)
	}
	if _, err := useCase.SendFriendRequest(ctx, viewerID, pendingID); err != nil {
		t.Fatalf("SendFriendRequest pending returned error: %v", err)
	}

	got, err := useCase.FilterFriendUserIDs(ctx, viewerID, []uuid.UUID{
		friendID,
		pendingID,
		strangerID,
		friendID,
		uuid.Nil,
		viewerID,
	})
	if err != nil {
		t.Fatalf("FilterFriendUserIDs returned error: %v", err)
	}
	if len(got) != 1 || got[0] != friendID {
		t.Fatalf("filtered ids = %v, want [%s]", got, friendID)
	}
}

func TestFilterFollowingUserIDsReturnsOnlyFollowedCandidates(t *testing.T) {
	ctx := context.Background()
	viewerID := uuid.New()
	followedID := uuid.New()
	strangerID := uuid.New()
	repo := newFriendshipTestRepository(viewerID, followedID, strangerID)
	useCase := NewUserUseCase(repo, nil)

	if err := repo.FollowUser(ctx, viewerID, followedID); err != nil {
		t.Fatalf("FollowUser returned error: %v", err)
	}

	got, err := useCase.FilterFollowingUserIDs(ctx, viewerID, []uuid.UUID{
		followedID,
		strangerID,
		followedID,
		uuid.Nil,
		viewerID,
	})
	if err != nil {
		t.Fatalf("FilterFollowingUserIDs returned error: %v", err)
	}
	if len(got) != 1 || got[0] != followedID {
		t.Fatalf("filtered ids = %v, want [%s]", got, followedID)
	}
}

func TestListFollowingPaginatesFollowedUsers(t *testing.T) {
	ctx := context.Background()
	viewerID := uuid.New()
	firstID := uuid.New()
	secondID := uuid.New()
	repo := newFriendshipTestRepository(viewerID, firstID, secondID)
	useCase := NewUserUseCase(repo, nil)

	if err := repo.FollowUser(ctx, viewerID, firstID); err != nil {
		t.Fatalf("FollowUser first returned error: %v", err)
	}
	if err := repo.FollowUser(ctx, viewerID, secondID); err != nil {
		t.Fatalf("FollowUser second returned error: %v", err)
	}

	page, err := useCase.ListFollowing(ctx, viewerID, ProfileConnectionsListInput{
		Limit:  1,
		Offset: 0,
	})
	if err != nil {
		t.Fatalf("ListFollowing returned error: %v", err)
	}
	if len(page.Items) != 1 {
		t.Fatalf("following length = %d, want 1", len(page.Items))
	}
	if page.NextOffset == nil || *page.NextOffset != 1 {
		t.Fatalf("next offset = %v, want 1", page.NextOffset)
	}
}

func TestSendFriendRequestRejectsSelf(t *testing.T) {
	ctx := context.Background()
	viewerID := uuid.New()
	repo := newFriendshipTestRepository(viewerID)
	useCase := NewUserUseCase(repo, nil)

	_, err := useCase.SendFriendRequest(ctx, viewerID, viewerID)
	if !errors.Is(err, ErrCannotFriendSelf) {
		t.Fatalf("error = %v, want %v", err, ErrCannotFriendSelf)
	}
}

type friendshipTestRepository struct {
	users          map[uuid.UUID]*model.User
	bySubject      map[string]uuid.UUID
	profiles       map[uuid.UUID]*model.UserProfile
	nicknameOwners map[string]uuid.UUID
	friendships    map[string]*model.UserFriendship
	follows        map[string]struct{}
	roles          map[uuid.UUID]map[enum.SystemRole]struct{}
}

func newFriendshipTestRepository(userIDs ...uuid.UUID) *friendshipTestRepository {
	repo := &friendshipTestRepository{
		users:          make(map[uuid.UUID]*model.User, len(userIDs)),
		bySubject:      make(map[string]uuid.UUID, len(userIDs)),
		profiles:       make(map[uuid.UUID]*model.UserProfile, len(userIDs)),
		nicknameOwners: make(map[string]uuid.UUID),
		friendships:    make(map[string]*model.UserFriendship),
		follows:        make(map[string]struct{}),
		roles:          make(map[uuid.UUID]map[enum.SystemRole]struct{}, len(userIDs)),
	}
	for index, userID := range userIDs {
		subject := userID.String()
		repo.users[userID] = &model.User{
			ID:            userID,
			AuthSubjectID: subject,
			Status:        enum.UserStatusActive,
			CreatedAt:     time.Now().UTC(),
			UpdatedAt:     time.Now().UTC(),
		}
		repo.bySubject[subject] = userID
		_ = index
	}
	return repo
}

func followPairKey(followerUserID uuid.UUID, followedUserID uuid.UUID) string {
	return followerUserID.String() + ":" + followedUserID.String()
}

func friendshipPairKey(a uuid.UUID, b uuid.UUID) string {
	if a.String() < b.String() {
		return a.String() + ":" + b.String()
	}
	return b.String() + ":" + a.String()
}

func (r *friendshipTestRepository) GetFriendship(
	_ context.Context,
	userAID uuid.UUID,
	userBID uuid.UUID,
) (*model.UserFriendship, error) {
	item := r.friendships[friendshipPairKey(userAID, userBID)]
	if item == nil {
		return nil, nil
	}
	copy := *item
	return &copy, nil
}

func (r *friendshipTestRepository) CreateFriendRequest(
	_ context.Context,
	requesterUserID uuid.UUID,
	addresseeUserID uuid.UUID,
) error {
	now := time.Now().UTC()
	r.friendships[friendshipPairKey(requesterUserID, addresseeUserID)] = &model.UserFriendship{
		ID:              uuid.New(),
		RequesterUserID: requesterUserID,
		AddresseeUserID: addresseeUserID,
		Status:          enum.FriendshipStatusPending,
		RequestedAt:     now,
		UpdatedAt:       now,
	}
	return nil
}

func (r *friendshipTestRepository) AcceptFriendRequest(
	_ context.Context,
	requesterUserID uuid.UUID,
	addresseeUserID uuid.UUID,
) error {
	item := r.friendships[friendshipPairKey(requesterUserID, addresseeUserID)]
	if item == nil ||
		item.RequesterUserID != requesterUserID ||
		item.AddresseeUserID != addresseeUserID ||
		item.Status != enum.FriendshipStatusPending {
		return ErrFriendRequestNotFound
	}
	now := time.Now().UTC()
	item.Status = enum.FriendshipStatusAccepted
	item.RespondedAt = &now
	item.UpdatedAt = now
	return nil
}

func (r *friendshipTestRepository) DeleteFriendship(
	_ context.Context,
	userAID uuid.UUID,
	userBID uuid.UUID,
) error {
	delete(r.friendships, friendshipPairKey(userAID, userBID))
	return nil
}

func (r *friendshipTestRepository) setFriendshipRequestedAt(
	requesterUserID uuid.UUID,
	addresseeUserID uuid.UUID,
	requestedAt time.Time,
) {
	item := r.friendships[friendshipPairKey(requesterUserID, addresseeUserID)]
	if item == nil {
		return
	}
	item.RequestedAt = requestedAt
}

func (r *friendshipTestRepository) CreateUserAggregate(
	context.Context,
	*model.User,
	*model.UserProfile,
	*model.UserSettings,
	*model.UserReputation,
	*model.UserSystemRole,
) error {
	return nil
}

func (r *friendshipTestRepository) GetUserByID(_ context.Context, userID uuid.UUID) (*model.User, error) {
	return r.users[userID], nil
}

func (r *friendshipTestRepository) GetUserBySubject(_ context.Context, subject string) (*model.User, error) {
	userID, ok := r.bySubject[subject]
	if !ok {
		return nil, ErrUserNotFound
	}
	return r.users[userID], nil
}

func (r *friendshipTestRepository) ListAdminUsers(
	context.Context,
	model.AdminUserListFilter,
) ([]model.AdminUserListItem, string, error) {
	return nil, "", nil
}

func (r *friendshipTestRepository) GetAdminUserDetail(
	context.Context,
	uuid.UUID,
) (model.AdminUserDetail, error) {
	return model.AdminUserDetail{}, ErrUserNotFound
}

func (r *friendshipTestRepository) GetProfileByUserID(_ context.Context, userID uuid.UUID) (*model.UserProfile, error) {
	return r.profileForUserID(userID), nil
}

func (r *friendshipTestRepository) IsNicknameTaken(_ context.Context, nickname string, excludeUserID uuid.UUID) (bool, error) {
	ownerUserID, ok := r.nicknameOwners[strings.ToLower(strings.TrimSpace(nickname))]
	if ok && ownerUserID != excludeUserID {
		return true, nil
	}
	return false, nil
}

func (r *friendshipTestRepository) GetUserIDByNickname(_ context.Context, nickname string) (uuid.UUID, error) {
	return r.nicknameOwners[strings.ToLower(strings.TrimSpace(nickname))], nil
}

func (r *friendshipTestRepository) GetSettingsByUserID(_ context.Context, userID uuid.UUID) (*model.UserSettings, error) {
	return &model.UserSettings{
		UserID:                    userID,
		NotificationsPushEnabled:  true,
		NotificationsEmailEnabled: true,
		NotificationsSMSEnabled:   true,
		CreatedAt:                 time.Now().UTC(),
		UpdatedAt:                 time.Now().UTC(),
	}, nil
}

func (r *friendshipTestRepository) GetReputationByUserID(_ context.Context, userID uuid.UUID) (*model.UserReputation, error) {
	return &model.UserReputation{
		UserID:    userID,
		CreatedAt: time.Now().UTC(),
		UpdatedAt: time.Now().UTC(),
	}, nil
}

func (r *friendshipTestRepository) ListRolesByUserID(context.Context, uuid.UUID) ([]*model.UserSystemRole, error) {
	return nil, nil
}

func (r *friendshipTestRepository) CountFollowersByUserID(context.Context, uuid.UUID) (int, error) {
	return 0, nil
}

func (r *friendshipTestRepository) IsFollowing(_ context.Context, followerUserID uuid.UUID, followedUserID uuid.UUID) (bool, error) {
	_, ok := r.follows[followPairKey(followerUserID, followedUserID)]
	return ok, nil
}

func (r *friendshipTestRepository) UpdateProfile(_ context.Context, profile *model.UserProfile) error {
	profileCopy := *profile
	r.profiles[profile.UserID] = &profileCopy
	if profile.Nickname != nil {
		r.nicknameOwners[strings.ToLower(strings.TrimSpace(*profile.Nickname))] = profile.UserID
	}
	return nil
}

func (r *friendshipTestRepository) UpdateLastSeen(context.Context, uuid.UUID) (*model.User, error) {
	return nil, nil
}

func (r *friendshipTestRepository) UpdateSettings(context.Context, *model.UserSettings) error {
	return nil
}

func (r *friendshipTestRepository) FollowUser(_ context.Context, followerUserID uuid.UUID, followedUserID uuid.UUID) error {
	r.follows[followPairKey(followerUserID, followedUserID)] = struct{}{}
	return nil
}

func (r *friendshipTestRepository) UnfollowUser(_ context.Context, followerUserID uuid.UUID, followedUserID uuid.UUID) error {
	delete(r.follows, followPairKey(followerUserID, followedUserID))
	return nil
}

func (r *friendshipTestRepository) GrantRole(context.Context, *model.UserSystemRole) error {
	return nil
}

func (r *friendshipTestRepository) RevokeRole(_ context.Context, userID uuid.UUID, role enum.SystemRole) error {
	if r.roles != nil {
		delete(r.roles[userID], role)
	}
	return nil
}

func (r *friendshipTestRepository) HasRole(_ context.Context, userID uuid.UUID, role enum.SystemRole) (bool, error) {
	return r.hasRoleValue(userID, role), nil
}

func (r *friendshipTestRepository) hasRoleValue(userID uuid.UUID, role enum.SystemRole) bool {
	if r.roles == nil {
		return false
	}
	_, ok := r.roles[userID][role]
	return ok
}

func (r *friendshipTestRepository) ListPublicProfiles(context.Context, int, int) ([]*model.UserProfile, error) {
	return nil, nil
}

func (r *friendshipTestRepository) GetPublicProfilesByUserIDs(_ context.Context, userIDs []uuid.UUID) ([]*model.UserProfile, error) {
	result := make([]*model.UserProfile, 0, len(userIDs))
	for _, userID := range userIDs {
		if profile, ok := r.profiles[userID]; ok {
			result = append(result, profile)
		}
	}
	return result, nil
}

func (r *friendshipTestRepository) ListPublicUserIDsByCountryCodes(context.Context, []string) ([]uuid.UUID, error) {
	return nil, nil
}

func (r *friendshipTestRepository) ListFollowersByUserID(context.Context, uuid.UUID, string, int, int) ([]*model.UserProfile, error) {
	return nil, nil
}

func (r *friendshipTestRepository) ListFriendsByUserID(
	_ context.Context,
	userID uuid.UUID,
	options port.UserConnectionListOptions,
) ([]*model.UserProfile, error) {
	result := make([]*model.UserProfile, 0)
	for _, friendship := range r.friendships {
		if friendship.Status != enum.FriendshipStatusAccepted {
			continue
		}

		var friendID uuid.UUID
		switch userID {
		case friendship.RequesterUserID:
			friendID = friendship.AddresseeUserID
		case friendship.AddresseeUserID:
			friendID = friendship.RequesterUserID
		default:
			continue
		}

		result = append(result, r.profileForUserID(friendID))
	}
	return paginateTestProfiles(result, options.Limit, options.Offset), nil
}

func (r *friendshipTestRepository) ListIncomingFriendRequestsByUserID(
	_ context.Context,
	userID uuid.UUID,
	options port.UserConnectionListOptions,
) ([]*model.UserFriendRequest, error) {
	result := make([]*model.UserFriendRequest, 0)
	for _, friendship := range r.friendships {
		if friendship.AddresseeUserID != userID ||
			friendship.Status != enum.FriendshipStatusPending {
			continue
		}
		result = append(result, &model.UserFriendRequest{
			Profile:     r.profileForUserID(friendship.RequesterUserID),
			RequestedAt: friendship.RequestedAt,
		})
	}
	sort.SliceStable(result, func(i, j int) bool {
		if result[i].RequestedAt.Equal(result[j].RequestedAt) {
			return result[i].Profile.UserID.String() < result[j].Profile.UserID.String()
		}
		return result[i].RequestedAt.After(result[j].RequestedAt)
	})
	return paginateTestFriendRequests(result, options.Limit, options.Offset), nil
}

func (r *friendshipTestRepository) ListFollowingByUserID(
	_ context.Context,
	userID uuid.UUID,
	options port.UserConnectionListOptions,
) ([]*model.UserProfile, error) {
	result := make([]*model.UserProfile, 0)
	for key := range r.follows {
		prefix := userID.String() + ":"
		if !strings.HasPrefix(key, prefix) {
			continue
		}
		followedID, err := uuid.Parse(strings.TrimPrefix(key, prefix))
		if err != nil {
			continue
		}
		result = append(result, r.profileForUserID(followedID))
	}
	return paginateTestProfiles(result, options.Limit, options.Offset), nil
}

func (r *friendshipTestRepository) profileForUserID(userID uuid.UUID) *model.UserProfile {
	if profile := r.profiles[userID]; profile != nil {
		profileCopy := *profile
		return &profileCopy
	}
	name := "User " + userID.String()[:8]
	return &model.UserProfile{
		UserID:    userID,
		Nickname:  &name,
		Locale:    "en",
		Timezone:  "UTC",
		CreatedAt: time.Now().UTC(),
		UpdatedAt: time.Now().UTC(),
	}
}

func paginateTestProfiles(
	items []*model.UserProfile,
	limit int,
	offset int,
) []*model.UserProfile {
	if offset < 0 {
		offset = 0
	}
	if offset >= len(items) {
		return []*model.UserProfile{}
	}
	end := offset + limit
	if limit <= 0 || end > len(items) {
		end = len(items)
	}
	return items[offset:end]
}

func paginateTestFriendRequests(
	items []*model.UserFriendRequest,
	limit int,
	offset int,
) []*model.UserFriendRequest {
	if offset < 0 {
		offset = 0
	}
	if offset >= len(items) {
		return []*model.UserFriendRequest{}
	}
	end := offset + limit
	if limit <= 0 || end > len(items) {
		end = len(items)
	}
	return items[offset:end]
}

func (r *friendshipTestRepository) PatchUserIdentityBySubject(context.Context, string, *string, *string) error {
	return nil
}
