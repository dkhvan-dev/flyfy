package grpc

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/user-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/user-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/user-service/internal/domain/model"
	userv1 "github.com/dkhvan-dev/flyfy/proto/gen/go/user/v1"
)

type Server struct {
	userv1.UnimplementedUserServiceServer
	useCase *app.UserUseCase
}

func NewServer(useCase *app.UserUseCase) *Server {
	return &Server{
		useCase: useCase,
	}
}

func (s *Server) GetOrCreateUserBySubject(
	ctx context.Context,
	req *userv1.GetOrCreateUserBySubjectRequest,
) (*userv1.GetOrCreateUserBySubjectResponse, error) {
	resp, err := s.useCase.GetOrCreateBySubjectWithIdentity(
		ctx,
		app.InitUserInput{
			SubjectID: strings.TrimSpace(req.GetSubjectId()),
		},
		app.InitIdentityHints{
			PrimaryPhone: stringPtrOrNil(req.GetPrimaryPhone()),
			PrimaryEmail: stringPtrOrNil(req.GetPrimaryEmail()),
		},
	)
	if err != nil {
		return nil, mapError(err)
	}

	return &userv1.GetOrCreateUserBySubjectResponse{
		Aggregate: toProtoAggregate(resp),
	}, nil
}

func (s *Server) GetUserById(
	ctx context.Context,
	req *userv1.GetUserByIdRequest,
) (*userv1.GetUserByIdResponse, error) {
	userID, err := uuid.Parse(strings.TrimSpace(req.GetUserId()))
	if err != nil {
		return nil, mapError(app.ErrInvalidUserID)
	}

	resp, err := s.useCase.GetAggregateByUserID(ctx, userID)
	if err != nil {
		return nil, mapError(err)
	}

	return &userv1.GetUserByIdResponse{
		Aggregate: toProtoAggregate(resp),
	}, nil
}

func (s *Server) GetUserProfile(
	ctx context.Context,
	req *userv1.GetUserProfileRequest,
) (*userv1.GetUserProfileResponse, error) {
	userID, err := uuid.Parse(strings.TrimSpace(req.GetUserId()))
	if err != nil {
		return nil, mapError(app.ErrInvalidUserID)
	}

	resp, err := s.useCase.GetAggregateByUserID(ctx, userID)
	if err != nil {
		return nil, mapError(err)
	}

	return &userv1.GetUserProfileResponse{
		Profile: toProtoProfile(resp.Profile),
	}, nil
}

func (s *Server) UpdateUserProfile(
	ctx context.Context,
	req *userv1.UpdateUserProfileRequest,
) (*userv1.UpdateUserProfileResponse, error) {
	userID, err := uuid.Parse(strings.TrimSpace(req.GetUserId()))
	if err != nil {
		return nil, mapError(app.ErrInvalidUserID)
	}

	birthDate, err := parseOptionalDateProto(req.GetBirthDate())
	if err != nil {
		return nil, mapError(err)
	}

	avatarFileID, err := parseOptionalUUIDProto(req.GetAvatarFileId())
	if err != nil {
		return nil, mapError(err)
	}

	cityID, err := parseOptionalUUIDProto(req.GetCityId())
	if err != nil {
		return nil, mapError(err)
	}

	updatedAggregate, err := s.useCase.UpdateProfile(ctx, userID, app.UpdateProfileInput{
		UserID:       userID,
		FirstName:    stringPtrOrNil(req.GetFirstName()),
		LastName:     stringPtrOrNil(req.GetLastName()),
		DisplayName:  stringPtrOrNil(req.GetDisplayName()),
		Bio:          stringPtrOrNil(req.GetBio()),
		BirthDate:    birthDate,
		AvatarFileID: avatarFileID,
		CityID:       cityID,
		CountryCode:  stringPtrOrNil(req.GetCountryCode()),
		Locale:       stringPtrOrNil(req.GetLocale()),
		Timezone:     stringPtrOrNil(req.GetTimezone()),
		Currency:     stringPtrOrNil(req.GetCurrency()),
		IsPublic:     req.IsPublic,
	})
	if err != nil {
		return nil, mapError(err)
	}

	return &userv1.UpdateUserProfileResponse{
		Profile: toProtoProfile(updatedAggregate.Profile),
	}, nil
}

func (s *Server) UpdateUserSettings(
	ctx context.Context,
	req *userv1.UpdateUserSettingsRequest,
) (*userv1.UpdateUserSettingsResponse, error) {
	userID, err := uuid.Parse(strings.TrimSpace(req.GetUserId()))
	if err != nil {
		return nil, mapError(app.ErrInvalidUserID)
	}

	settings, err := s.useCase.UpdateSettings(ctx, userID, model.UpdateUserSettingsParams{
		NotificationsPushEnabled:  optionalBoolPtr(req.NotificationsPushEnabled),
		NotificationsEmailEnabled: optionalBoolPtr(req.NotificationsEmailEnabled),
		NotificationsSMSEnabled:   optionalBoolPtr(req.NotificationsSmsEnabled),
		MarketingEnabled:          optionalBoolPtr(req.MarketingEnabled),
		DarkModeEnabled:           optionalBoolPtr(req.DarkModeEnabled),
	})
	if err != nil {
		return nil, mapError(err)
	}

	return &userv1.UpdateUserSettingsResponse{
		Settings: toProtoSettings(settings),
	}, nil
}

func (s *Server) GrantUserRole(
	ctx context.Context,
	req *userv1.GrantUserRoleRequest,
) (*userv1.GrantUserRoleResponse, error) {
	userID, err := uuid.Parse(strings.TrimSpace(req.GetUserId()))
	if err != nil {
		return nil, mapError(app.ErrInvalidUserID)
	}

	role := enum.SystemRole(strings.TrimSpace(req.GetRole()))

	var grantedBy *uuid.UUID
	if strings.TrimSpace(req.GetGrantedBy()) != "" {
		parsed, parseErr := uuid.Parse(strings.TrimSpace(req.GetGrantedBy()))
		if parseErr != nil {
			return nil, mapError(app.ErrInvalidUserID)
		}
		grantedBy = &parsed
	}

	if err = s.useCase.GrantRole(ctx, userID, role, grantedBy); err != nil {
		return nil, mapError(err)
	}

	return &userv1.GrantUserRoleResponse{
		Success: true,
	}, nil
}

func (s *Server) ListPublicProfiles(
	ctx context.Context,
	req *userv1.ListPublicProfilesRequest,
) (*userv1.ListPublicProfilesResponse, error) {
	items, err := s.useCase.ListPublicProfiles(ctx, int(req.GetLimit()), int(req.GetOffset()))
	if err != nil {
		return nil, mapError(err)
	}

	resp := &userv1.ListPublicProfilesResponse{
		Items: make([]*userv1.PublicProfile, 0, len(items)),
	}
	for _, item := range items {
		resp.Items = append(resp.Items, toProtoPublicProfile(item))
	}

	return resp, nil
}

func (s *Server) GetPublicProfilesByUserIds(
	ctx context.Context,
	req *userv1.GetPublicProfilesByUserIdsRequest,
) (*userv1.GetPublicProfilesByUserIdsResponse, error) {
	rawIDs := req.GetUserIds()
	userIDs := make([]uuid.UUID, 0, len(rawIDs))

	for _, raw := range rawIDs {
		raw = strings.TrimSpace(raw)
		if raw == "" {
			continue
		}

		parsed, err := uuid.Parse(raw)
		if err != nil {
			return nil, mapError(app.ErrInvalidUserID)
		}
		userIDs = append(userIDs, parsed)
	}

	items, err := s.useCase.GetPublicProfilesByUserIDs(ctx, userIDs)
	if err != nil {
		return nil, mapError(err)
	}

	resp := &userv1.GetPublicProfilesByUserIdsResponse{
		Items: make([]*userv1.PublicProfile, 0, len(items)),
	}
	for _, item := range items {
		resp.Items = append(resp.Items, toProtoPublicProfile(item))
	}

	return resp, nil
}

func (s *Server) GetUserBySubject(
	ctx context.Context,
	req *userv1.GetUserBySubjectRequest,
) (*userv1.GetUserBySubjectResponse, error) {
	aggregate, err := s.useCase.GetUserBySubject(ctx, req.GetSubjectId())
	if err != nil {
		return nil, mapError(err)
	}

	return &userv1.GetUserBySubjectResponse{
		Aggregate: toProtoAggregate(aggregate),
	}, nil
}

func toProtoAggregate(aggregate *app.UserAggregate) *userv1.UserAggregate {
	roles := make([]string, 0, len(aggregate.Roles))
	for _, role := range aggregate.Roles {
		roles = append(roles, string(role.Role))
	}

	return &userv1.UserAggregate{
		User:       toProtoUser(aggregate.User),
		Profile:    toProtoProfile(aggregate.Profile),
		Settings:   toProtoSettings(aggregate.Settings),
		Reputation: toProtoReputation(aggregate.Reputation),
		Roles:      roles,
	}
}

func toProtoUser(user *model.User) *userv1.User {
	var deletedAt string
	if user.DeletedAt != nil {
		deletedAt = user.DeletedAt.UTC().Format(time.RFC3339)
	}

	var lastSeenAt string
	if user.LastSeenAt != nil {
		lastSeenAt = user.LastSeenAt.UTC().Format(time.RFC3339)
	}

	return &userv1.User{
		Id:            user.ID.String(),
		AuthSubjectId: user.AuthSubjectID,
		Status:        string(user.Status),
		PrimaryPhone:  valueOrEmpty(user.PrimaryPhone),
		PrimaryEmail:  valueOrEmpty(user.PrimaryEmail),
		IsDeleted:     user.IsDeleted,
		DeletedAt:     deletedAt,
		CreatedAt:     user.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:     user.UpdatedAt.UTC().Format(time.RFC3339),
		LastSeenAt:    lastSeenAt,
	}
}

func toProtoProfile(profile *model.UserProfile) *userv1.UserProfile {
	var birthDate string
	if profile.BirthDate != nil {
		birthDate = profile.BirthDate.UTC().Format("2006-01-02")
	}

	var avatarFileID string
	if profile.AvatarFileID != nil {
		avatarFileID = profile.AvatarFileID.String()
	}

	var cityID string
	if profile.CityID != nil {
		cityID = profile.CityID.String()
	}

	var lastSeenAt string
	if profile.LastSeenAt != nil {
		lastSeenAt = profile.LastSeenAt.UTC().Format(time.RFC3339)
	}

	return &userv1.UserProfile{
		UserId:       profile.UserID.String(),
		FirstName:    valueOrEmpty(profile.FirstName),
		LastName:     valueOrEmpty(profile.LastName),
		DisplayName:  valueOrEmpty(profile.DisplayName),
		Bio:          valueOrEmpty(profile.Bio),
		BirthDate:    birthDate,
		AvatarFileId: avatarFileID,
		CityId:       cityID,
		CountryCode:  valueOrEmpty(profile.CountryCode),
		Locale:       profile.Locale,
		Timezone:     profile.Timezone,
		Currency:     valueOrEmpty(profile.Currency),
		IsPublic:     profile.IsPublic,
		CreatedAt:    profile.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:    profile.UpdatedAt.UTC().Format(time.RFC3339),
		IsOnline:     profile.IsOnline,
		LastSeenAt:   lastSeenAt,
	}
}

func toProtoSettings(settings *model.UserSettings) *userv1.UserSettings {
	return &userv1.UserSettings{
		UserId:                    settings.UserID.String(),
		NotificationsPushEnabled:  settings.NotificationsPushEnabled,
		NotificationsEmailEnabled: settings.NotificationsEmailEnabled,
		NotificationsSmsEnabled:   settings.NotificationsSMSEnabled,
		MarketingEnabled:          settings.MarketingEnabled,
		DarkModeEnabled:           settings.DarkModeEnabled,
		CreatedAt:                 settings.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:                 settings.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toProtoReputation(rep *model.UserReputation) *userv1.UserReputation {
	return &userv1.UserReputation{
		UserId:              rep.UserID.String(),
		TrustScore:          int32(rep.TrustScore),
		RiskScore:           int32(rep.RiskScore),
		CompletedBookings:   int32(rep.CompletedBookings),
		CompletedActivities: int32(rep.CompletedActivities),
		CancellationsCount:  int32(rep.CancellationsCount),
		ReportsCount:        int32(rep.ReportsCount),
		CreatedAt:           rep.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:           rep.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toProtoPublicProfile(profile *model.UserProfile) *userv1.PublicProfile {
	var avatarFileID string
	if profile.AvatarFileID != nil {
		avatarFileID = profile.AvatarFileID.String()
	}

	var lastSeenAt string
	if profile.LastSeenAt != nil {
		lastSeenAt = profile.LastSeenAt.UTC().Format(time.RFC3339)
	}

	return &userv1.PublicProfile{
		UserId:       profile.UserID.String(),
		DisplayName:  valueOrEmpty(profile.DisplayName),
		Bio:          valueOrEmpty(profile.Bio),
		AvatarFileId: avatarFileID,
		CountryCode:  valueOrEmpty(profile.CountryCode),
		Locale:       profile.Locale,
		Timezone:     profile.Timezone,
		IsPublic:     profile.IsPublic,
		IsOnline:     profile.IsOnline,
		LastSeenAt:   lastSeenAt,
	}
}

func stringPtrOrNil(v string) *string {
	v = strings.TrimSpace(v)
	if v == "" {
		return nil
	}
	return &v
}

func valueOrEmpty(v *string) string {
	if v == nil {
		return ""
	}
	return *v
}

func parseOptionalUUIDProto(v string) (*uuid.UUID, error) {
	v = strings.TrimSpace(v)
	if v == "" {
		return nil, nil
	}

	parsed, err := uuid.Parse(v)
	if err != nil {
		return nil, app.ErrInvalidUserID
	}
	return &parsed, nil
}

func parseOptionalDateProto(v string) (*time.Time, error) {
	v = strings.TrimSpace(v)
	if v == "" {
		return nil, nil
	}

	parsed, err := time.Parse("2006-01-02", v)
	if err != nil {
		return nil, fmt.Errorf("invalid birth date")
	}

	t := parsed.UTC()
	return &t, nil
}

func optionalBoolPtr(v *bool) *bool {
	if v == nil {
		return nil
	}
	b := *v
	return &b
}
