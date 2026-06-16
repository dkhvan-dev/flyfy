package app

import (
	"context"
	"fmt"
	"strings"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/enum"
	"kz/inflap/backend/services/feed-service/internal/domain/model"
)

type CommunityView struct {
	Community         *model.Community
	FollowedByViewer  bool
	ViewerRole        enum.CommunityMembershipRole
	ViewerCanModerate bool
	MutedByViewer     bool
	ViewerTrustStatus string
}

type ListCommunitiesInput struct {
	Topic           string
	CountryCode     string
	CityID          string
	Search          string
	ExcludeFollowed bool
	OnlyFollowed    bool
	Limit           int
	Offset          int
}

type SubmitCommunityReportInput struct {
	CommunityID uuid.UUID
	Reason      string
	Details     string
}

type UpdateCommunityMemberRoleInput struct {
	CommunityID uuid.UUID
	UserID      uuid.UUID
	Role        string
}

type UpdateCommunityMemberStatusInput struct {
	CommunityID uuid.UUID
	UserID      uuid.UUID
	Status      string
}

type ListCommunityMembersInput struct {
	CommunityID uuid.UUID
	Role        string
	Status      string
	Limit       int
	Offset      int
}

type CommunityMemberView struct {
	Membership *model.CommunityMembership
	User       PostAuthor
}

type ListCommunityMemberRoleChangesInput struct {
	CommunityID uuid.UUID
	UserID      uuid.UUID
	Limit       int
	Offset      int
}

type CommunityMemberRoleChangeView struct {
	Change *model.CommunityMemberRoleChange
	Actor  PostAuthor
}

func (u *PostUseCase) ListCommunities(ctx context.Context, subject string, input ListCommunitiesInput) ([]*CommunityView, error) {
	viewerUserID, err := u.optionalUserID(ctx, subject)
	if err != nil {
		return nil, err
	}

	filter := model.CommunityListFilter{
		Topic:       strings.ToUpper(strings.TrimSpace(input.Topic)),
		CountryCode: normalizeCountryCode(input.CountryCode),
		CityID:      strings.TrimSpace(input.CityID),
		Search:      strings.TrimSpace(input.Search),
		PublicOnly:  true,
		Limit:       input.Limit,
		Offset:      input.Offset,
	}
	if input.OnlyFollowed {
		if viewerUserID == nil || *viewerUserID == uuid.Nil {
			return []*CommunityView{}, nil
		}
		filter.OnlyFollowedByUserID = viewerUserID
	} else if input.ExcludeFollowed && viewerUserID != nil && *viewerUserID != uuid.Nil {
		filter.ExcludeFollowedByUserID = viewerUserID
	}
	if filter.Limit <= 0 {
		filter.Limit = defaultListLimit
	}
	if filter.Limit > maxListLimit {
		filter.Limit = maxListLimit
	}
	if filter.Offset < 0 {
		filter.Offset = 0
	}

	items, err := u.repo.ListCommunities(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("list communities: %w", err)
	}
	views, err := u.buildCommunityViews(ctx, items, viewerUserID)
	if err != nil {
		return nil, err
	}
	if input.OnlyFollowed {
		filtered := make([]*CommunityView, 0, len(views))
		for _, view := range views {
			if view != nil && view.FollowedByViewer {
				filtered = append(filtered, view)
			}
		}
		return filtered, nil
	}
	if !input.ExcludeFollowed {
		return views, nil
	}
	filtered := make([]*CommunityView, 0, len(views))
	for _, view := range views {
		if view != nil && !view.FollowedByViewer {
			filtered = append(filtered, view)
		}
	}
	return filtered, nil
}

func (u *PostUseCase) GetCommunity(ctx context.Context, subject string, communityID uuid.UUID) (*CommunityView, error) {
	if communityID == uuid.Nil {
		return nil, ErrInvalidCommunityID
	}
	viewerUserID, err := u.optionalUserID(ctx, subject)
	if err != nil {
		return nil, err
	}

	community, err := u.repo.GetCommunityByID(ctx, communityID)
	if err != nil {
		return nil, fmt.Errorf("get community: %w", err)
	}
	if community == nil || !community.IsPubliclyVisible() {
		return nil, ErrCommunityNotFound
	}

	views, err := u.buildCommunityViews(ctx, []*model.Community{community}, viewerUserID)
	if err != nil {
		return nil, err
	}
	if len(views) == 0 {
		return nil, ErrCommunityNotFound
	}
	return views[0], nil
}

func (u *PostUseCase) FollowCommunity(ctx context.Context, subject string, communityID uuid.UUID) (*CommunityView, error) {
	userID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}
	if communityID == uuid.Nil {
		return nil, ErrInvalidCommunityID
	}
	community, err := u.repo.GetCommunityByID(ctx, communityID)
	if err != nil {
		return nil, fmt.Errorf("get community before follow: %w", err)
	}
	if community == nil || !community.IsPubliclyVisible() {
		return nil, ErrCommunityNotFound
	}

	membership, err := u.repo.GetCommunityMembership(ctx, communityID, userID)
	if err != nil {
		return nil, fmt.Errorf("get community membership before follow: %w", err)
	}
	if membership != nil {
		switch membership.Status {
		case enum.CommunityMembershipStatusMuted, enum.CommunityMembershipStatusBanned:
			return nil, ErrCommunityFollowDenied
		}
	}

	if _, _, err = u.repo.FollowCommunity(ctx, communityID, userID); err != nil {
		return nil, fmt.Errorf("follow community: %w", err)
	}
	u.bumpPostFeedCacheScopes(ctx, postFeedCacheFollowingScope(userID), postFeedCacheDiscoveryScope(userID))
	return u.GetCommunity(ctx, subject, communityID)
}

func (u *PostUseCase) UnfollowCommunity(ctx context.Context, subject string, communityID uuid.UUID) (*CommunityView, error) {
	userID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}
	if communityID == uuid.Nil {
		return nil, ErrInvalidCommunityID
	}
	community, err := u.repo.GetCommunityByID(ctx, communityID)
	if err != nil {
		return nil, fmt.Errorf("get community before unfollow: %w", err)
	}
	if community == nil || !community.IsPubliclyVisible() {
		return nil, ErrCommunityNotFound
	}

	if _, _, err = u.repo.UnfollowCommunity(ctx, communityID, userID); err != nil {
		return nil, fmt.Errorf("unfollow community: %w", err)
	}
	u.bumpPostFeedCacheScopes(ctx, postFeedCacheFollowingScope(userID), postFeedCacheDiscoveryScope(userID))
	return u.GetCommunity(ctx, subject, communityID)
}

func (u *PostUseCase) SubmitCommunityReport(ctx context.Context, subject string, input SubmitCommunityReportInput) (*model.CommunityReportSubmissionResult, error) {
	userID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}
	if input.CommunityID == uuid.Nil {
		return nil, ErrInvalidCommunityID
	}

	reason := enum.NormalizePostReportReason(enum.PostReportReason(input.Reason))
	if !reason.IsValid() {
		return nil, ErrInvalidPostReportReason
	}
	details := strings.TrimSpace(input.Details)
	if len([]rune(details)) > maxPostReportDetailsChars {
		return nil, ErrInvalidPostReportDetails
	}

	community, err := u.repo.GetCommunityByID(ctx, input.CommunityID)
	if err != nil {
		return nil, fmt.Errorf("get community before report: %w", err)
	}
	if community == nil || !community.IsPubliclyVisible() {
		return nil, ErrCommunityNotFound
	}

	report := model.NewCommunityReport(model.NewCommunityReportParams{
		CommunityID:    input.CommunityID,
		ReporterUserID: userID,
		Reason:         reason,
		Details:        details,
	})
	result, err := u.repo.CreateCommunityReport(ctx, report)
	if err != nil {
		return nil, fmt.Errorf("create community report: %w", err)
	}
	if err = u.trackCommunityNegativeFeedSignal(ctx, userID, input.CommunityID, "community_report", string(reason)); err != nil {
		return nil, err
	}
	return result, nil
}

func (u *PostUseCase) MuteCommunity(ctx context.Context, subject string, communityID uuid.UUID) (*CommunityView, error) {
	return u.setCommunityMute(ctx, subject, communityID, true)
}

func (u *PostUseCase) UnmuteCommunity(ctx context.Context, subject string, communityID uuid.UUID) (*CommunityView, error) {
	return u.setCommunityMute(ctx, subject, communityID, false)
}

func (u *PostUseCase) setCommunityMute(ctx context.Context, subject string, communityID uuid.UUID, muted bool) (*CommunityView, error) {
	userID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}
	if communityID == uuid.Nil {
		return nil, ErrInvalidCommunityID
	}
	community, err := u.repo.GetCommunityByID(ctx, communityID)
	if err != nil {
		return nil, fmt.Errorf("get community before mute update: %w", err)
	}
	if community == nil || !community.IsPubliclyVisible() {
		return nil, ErrCommunityNotFound
	}
	if _, err = u.repo.SetCommunityMuted(ctx, communityID, userID, muted); err != nil {
		return nil, fmt.Errorf("set community muted: %w", err)
	}
	if muted {
		if err = u.trackCommunityNegativeFeedSignal(ctx, userID, communityID, "community_mute", ""); err != nil {
			return nil, err
		}
	}
	u.bumpPostFeedCacheScopes(ctx, postFeedCacheFollowingScope(userID), postFeedCacheDiscoveryScope(userID))
	return u.GetCommunity(ctx, subject, communityID)
}

func (u *PostUseCase) UpdateCommunityMemberRole(ctx context.Context, subject string, input UpdateCommunityMemberRoleInput) (*model.CommunityMembership, error) {
	actorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}
	if input.CommunityID == uuid.Nil {
		return nil, ErrInvalidCommunityID
	}
	if input.UserID == uuid.Nil {
		return nil, ErrInvalidUserID
	}
	if input.UserID == actorUserID {
		return nil, ErrCommunityRoleChangeDenied
	}

	nextRole := enum.CommunityMembershipRole(strings.ToUpper(strings.TrimSpace(input.Role)))
	if !nextRole.IsValid() {
		return nil, ErrInvalidCommunityMemberRole
	}

	community, err := u.repo.GetCommunityByID(ctx, input.CommunityID)
	if err != nil {
		return nil, fmt.Errorf("get role-change community: %w", err)
	}
	if community == nil || !community.IsActive() {
		return nil, ErrCommunityNotFound
	}

	actorMembership, err := u.repo.GetCommunityMembership(ctx, input.CommunityID, actorUserID)
	if err != nil {
		return nil, fmt.Errorf("get role-change actor membership: %w", err)
	}
	if actorMembership == nil ||
		actorMembership.Status != enum.CommunityMembershipStatusActive ||
		actorMembership.Role != enum.CommunityMembershipRoleAdmin {
		return nil, ErrCommunityRoleChangeDenied
	}

	targetMembership, err := u.repo.GetCommunityMembership(ctx, input.CommunityID, input.UserID)
	if err != nil {
		return nil, fmt.Errorf("get role-change target membership: %w", err)
	}
	if targetMembership == nil || targetMembership.Status != enum.CommunityMembershipStatusActive {
		return nil, ErrCommunityMembershipNotFound
	}

	updated, err := u.repo.UpdateCommunityMembershipRole(ctx, input.CommunityID, input.UserID, actorUserID, nextRole)
	if err != nil {
		return nil, fmt.Errorf("update community membership role: %w", err)
	}
	if updated == nil {
		return nil, ErrCommunityMembershipNotFound
	}
	return updated, nil
}

func (u *PostUseCase) UpdateCommunityMemberStatus(ctx context.Context, subject string, input UpdateCommunityMemberStatusInput) (*model.CommunityMembership, error) {
	actorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}
	if input.CommunityID == uuid.Nil {
		return nil, ErrInvalidCommunityID
	}
	if input.UserID == uuid.Nil {
		return nil, ErrInvalidUserID
	}
	if input.UserID == actorUserID {
		return nil, ErrCommunityMemberManageDenied
	}

	nextStatus := enum.CommunityMembershipStatus(strings.ToUpper(strings.TrimSpace(input.Status)))
	if !nextStatus.IsValid() {
		return nil, ErrInvalidCommunityMemberStatus
	}

	community, err := u.repo.GetCommunityByID(ctx, input.CommunityID)
	if err != nil {
		return nil, fmt.Errorf("get status-change community: %w", err)
	}
	if community == nil || !community.IsActive() {
		return nil, ErrCommunityNotFound
	}

	actorMembership, err := u.repo.GetCommunityMembership(ctx, input.CommunityID, actorUserID)
	if err != nil {
		return nil, fmt.Errorf("get status-change actor membership: %w", err)
	}
	if actorMembership == nil ||
		actorMembership.Status != enum.CommunityMembershipStatusActive ||
		actorMembership.Role != enum.CommunityMembershipRoleAdmin {
		return nil, ErrCommunityMemberManageDenied
	}

	targetMembership, err := u.repo.GetCommunityMembership(ctx, input.CommunityID, input.UserID)
	if err != nil {
		return nil, fmt.Errorf("get status-change target membership: %w", err)
	}
	if targetMembership == nil {
		return nil, ErrCommunityMembershipNotFound
	}

	updated, err := u.repo.UpdateCommunityMembershipStatus(ctx, input.CommunityID, input.UserID, actorUserID, nextStatus)
	if err != nil {
		return nil, fmt.Errorf("update community membership status: %w", err)
	}
	if updated == nil {
		return nil, ErrCommunityMembershipNotFound
	}
	return updated, nil
}

func (u *PostUseCase) ListCommunityMembers(ctx context.Context, subject string, input ListCommunityMembersInput) ([]*CommunityMemberView, error) {
	actorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}
	if input.CommunityID == uuid.Nil {
		return nil, ErrInvalidCommunityID
	}

	community, err := u.repo.GetCommunityByID(ctx, input.CommunityID)
	if err != nil {
		return nil, fmt.Errorf("get member-list community: %w", err)
	}
	if community == nil || !community.IsActive() {
		return nil, ErrCommunityNotFound
	}

	actorMembership, err := u.repo.GetCommunityMembership(ctx, input.CommunityID, actorUserID)
	if err != nil {
		return nil, fmt.Errorf("get member-list actor membership: %w", err)
	}
	if actorMembership == nil ||
		actorMembership.Status != enum.CommunityMembershipStatusActive ||
		actorMembership.Role != enum.CommunityMembershipRoleAdmin {
		return nil, ErrCommunityMemberManageDenied
	}

	filter := model.CommunityMemberListFilter{
		CommunityID: input.CommunityID,
		Limit:       input.Limit,
		Offset:      input.Offset,
	}
	if filter.Limit <= 0 {
		filter.Limit = defaultListLimit
	}
	if filter.Limit > maxListLimit {
		filter.Limit = maxListLimit
	}
	if filter.Offset < 0 {
		filter.Offset = 0
	}

	if roleRaw := strings.ToUpper(strings.TrimSpace(input.Role)); roleRaw != "" {
		role := enum.CommunityMembershipRole(roleRaw)
		if !role.IsValid() {
			return nil, ErrInvalidCommunityMemberRole
		}
		filter.Role = &role
	}

	statusRaw := strings.ToUpper(strings.TrimSpace(input.Status))
	if statusRaw == "" {
		statusRaw = string(enum.CommunityMembershipStatusActive)
	}
	status := enum.CommunityMembershipStatus(statusRaw)
	if !status.IsValid() {
		return nil, ErrInvalidCommunityMemberStatus
	}
	filter.Status = &status

	memberships, err := u.repo.ListCommunityMemberships(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("list community memberships: %w", err)
	}

	userIDs := make([]uuid.UUID, 0, len(memberships))
	for _, membership := range memberships {
		if membership != nil && membership.UserID != uuid.Nil {
			userIDs = append(userIDs, membership.UserID)
		}
	}
	profiles, err := u.users.GetPublicUserProfiles(ctx, userIDs)
	if err != nil {
		return nil, fmt.Errorf("load community member profiles: %w", err)
	}

	result := make([]*CommunityMemberView, 0, len(memberships))
	for _, membership := range memberships {
		if membership == nil {
			continue
		}
		result = append(result, &CommunityMemberView{
			Membership: membership,
			User:       toPostAuthor(membership.UserID, profiles[membership.UserID]),
		})
	}
	return result, nil
}

func (u *PostUseCase) ListCommunityMemberRoleChanges(
	ctx context.Context,
	subject string,
	input ListCommunityMemberRoleChangesInput,
) ([]*CommunityMemberRoleChangeView, error) {
	actorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}
	if input.CommunityID == uuid.Nil {
		return nil, ErrInvalidCommunityID
	}
	if input.UserID == uuid.Nil {
		return nil, ErrInvalidUserID
	}

	community, err := u.repo.GetCommunityByID(ctx, input.CommunityID)
	if err != nil {
		return nil, fmt.Errorf("get role-change-hipost community: %w", err)
	}
	if community == nil || !community.IsActive() {
		return nil, ErrCommunityNotFound
	}

	actorMembership, err := u.repo.GetCommunityMembership(ctx, input.CommunityID, actorUserID)
	if err != nil {
		return nil, fmt.Errorf("get role-change-hipost actor membership: %w", err)
	}
	if actorMembership == nil ||
		actorMembership.Status != enum.CommunityMembershipStatusActive ||
		actorMembership.Role != enum.CommunityMembershipRoleAdmin {
		return nil, ErrCommunityMemberManageDenied
	}

	filter := model.CommunityMemberRoleChangeListFilter{
		CommunityID:  input.CommunityID,
		TargetUserID: input.UserID,
		Limit:        input.Limit,
		Offset:       input.Offset,
	}
	if filter.Limit <= 0 {
		filter.Limit = defaultListLimit
	}
	if filter.Limit > maxListLimit {
		filter.Limit = maxListLimit
	}
	if filter.Offset < 0 {
		filter.Offset = 0
	}

	changes, err := u.repo.ListCommunityMemberRoleChanges(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("list community member role changes: %w", err)
	}

	actorIDs := make([]uuid.UUID, 0, len(changes))
	for _, change := range changes {
		if change != nil && change.ActorUserID != uuid.Nil {
			actorIDs = append(actorIDs, change.ActorUserID)
		}
	}
	profiles, err := u.users.GetPublicUserProfiles(ctx, actorIDs)
	if err != nil {
		return nil, fmt.Errorf("load community role-change actors: %w", err)
	}

	result := make([]*CommunityMemberRoleChangeView, 0, len(changes))
	for _, change := range changes {
		if change == nil {
			continue
		}
		result = append(result, &CommunityMemberRoleChangeView{
			Change: change,
			Actor:  toPostAuthor(change.ActorUserID, profiles[change.ActorUserID]),
		})
	}
	return result, nil
}

func (u *PostUseCase) buildCommunityViews(ctx context.Context, communities []*model.Community, viewerUserID *uuid.UUID) ([]*CommunityView, error) {
	views := make([]*CommunityView, 0, len(communities))
	communityIDs := make([]uuid.UUID, 0, len(communities))
	for _, community := range communities {
		if community == nil || !community.IsPubliclyVisible() {
			continue
		}
		communityIDs = append(communityIDs, community.ID)
	}

	followed := map[uuid.UUID]bool{}
	memberships := map[uuid.UUID]*model.CommunityMembership{}
	if viewerUserID != nil && *viewerUserID != uuid.Nil && len(communityIDs) > 0 {
		var err error
		followed, err = u.repo.ListFollowedCommunityIDs(ctx, *viewerUserID, communityIDs)
		if err != nil {
			return nil, fmt.Errorf("list followed community ids: %w", err)
		}
		for _, communityID := range communityIDs {
			membership, err := u.repo.GetCommunityMembership(ctx, communityID, *viewerUserID)
			if err != nil {
				return nil, fmt.Errorf("get community membership: %w", err)
			}
			if membership != nil {
				memberships[communityID] = membership
			}
		}
	}

	for _, community := range communities {
		if community == nil || !community.IsPubliclyVisible() {
			continue
		}
		membership := memberships[community.ID]
		views = append(views, &CommunityView{
			Community:         community,
			FollowedByViewer:  followed[community.ID],
			ViewerRole:        communityViewerRole(membership),
			ViewerCanModerate: communityViewerCanModerate(membership),
			MutedByViewer:     membership != nil && membership.Status == enum.CommunityMembershipStatusMuted,
			ViewerTrustStatus: communityViewerTrustStatus(membership),
		})
	}
	return views, nil
}

func communityViewerTrustStatus(membership *model.CommunityMembership) string {
	if membership == nil {
		return "ACTIVE"
	}
	switch membership.Status {
	case enum.CommunityMembershipStatusMuted:
		return "MUTED"
	case enum.CommunityMembershipStatusBanned:
		return "BANNED"
	default:
		return "ACTIVE"
	}
}

func communityViewerRole(membership *model.CommunityMembership) enum.CommunityMembershipRole {
	if membership == nil || membership.Status != enum.CommunityMembershipStatusActive {
		return ""
	}
	return membership.Role
}

func communityViewerCanModerate(membership *model.CommunityMembership) bool {
	if membership == nil || membership.Status != enum.CommunityMembershipStatusActive {
		return false
	}
	switch membership.Role {
	case enum.CommunityMembershipRoleModerator, enum.CommunityMembershipRoleAdmin:
		return true
	default:
		return false
	}
}
