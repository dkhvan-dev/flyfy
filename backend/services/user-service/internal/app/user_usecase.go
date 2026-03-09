package app

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/user-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/user-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/user-service/internal/domain/port"
)

type UserAggregate struct {
	User       *model.User
	Profile    *model.UserProfile
	Settings   *model.UserSettings
	Reputation *model.UserReputation
	Roles      []*model.UserSystemRole
}

type UserUseCase struct {
	repo        port.UserRepository
	fileManager FileManagerClient
}

func NewUserUseCase(repo port.UserRepository, fileManager FileManagerClient) *UserUseCase {
	return &UserUseCase{
		repo:        repo,
		fileManager: fileManager,
	}
}

type InitUserInput struct {
	SubjectID    string
	PrimaryPhone *string
	PrimaryEmail *string
}

func (u *UserUseCase) GetOrCreateBySubject(ctx context.Context, input InitUserInput) (*UserAggregate, error) {
	if input.SubjectID == "" {
		return nil, ErrInvalidSubjectID
	}

	existing, err := u.repo.GetUserBySubject(ctx, input.SubjectID)
	if err != nil {
		return nil, fmt.Errorf("get user by subject: %w", err)
	}

	if existing != nil && !existing.IsDeleted {
		return u.GetAggregateByUserID(ctx, existing.ID)
	}

	user, err := model.NewUser(model.NewUserParams{
		AuthSubjectID: input.SubjectID,
		PrimaryPhone:  input.PrimaryPhone,
		PrimaryEmail:  input.PrimaryEmail,
	})
	if err != nil {
		return nil, fmt.Errorf("new user: %w", err)
	}

	profile, err := model.NewUserProfile(model.NewUserProfileParams{
		UserID: user.ID,
	})
	if err != nil {
		return nil, fmt.Errorf("new user profile: %w", err)
	}

	settings, err := model.NewUserSettings(model.NewUserSettingsParams{
		UserID: user.ID,
	})
	if err != nil {
		return nil, fmt.Errorf("new user settings: %w", err)
	}

	reputation, err := model.NewUserReputation(model.NewUserReputationParams{
		UserID: user.ID,
	})
	if err != nil {
		return nil, fmt.Errorf("new user reputation: %w", err)
	}

	defaultRole, err := model.NewUserSystemRole(model.NewUserSystemRoleParams{
		UserID: user.ID,
		Role:   enum.SystemRoleUser,
	})
	if err != nil {
		return nil, fmt.Errorf("new default role: %w", err)
	}

	if err = u.repo.CreateUserAggregate(ctx, user, profile, settings, reputation, defaultRole); err != nil {
		return nil, fmt.Errorf("create user aggregate: %w", err)
	}

	return &UserAggregate{
		User:       user,
		Profile:    profile,
		Settings:   settings,
		Reputation: reputation,
		Roles:      []*model.UserSystemRole{defaultRole},
	}, nil
}

func (u *UserUseCase) GetAggregateByUserID(ctx context.Context, userID uuid.UUID) (*UserAggregate, error) {
	if userID == uuid.Nil {
		return nil, ErrInvalidUserID
	}

	user, err := u.repo.GetUserByID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("get user by id: %w", err)
	}
	if user == nil || user.IsDeleted {
		return nil, ErrUserNotFound
	}

	profile, err := u.repo.GetProfileByUserID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("get profile by user id: %w", err)
	}
	if profile == nil {
		return nil, ErrProfileNotFound
	}

	settings, err := u.repo.GetSettingsByUserID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("get settings by user id: %w", err)
	}
	if settings == nil {
		return nil, ErrSettingsNotFound
	}

	reputation, err := u.repo.GetReputationByUserID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("get reputation by user id: %w", err)
	}
	if reputation == nil {
		return nil, ErrReputationNotFound
	}

	roles, err := u.repo.ListRolesByUserID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("list roles by user id: %w", err)
	}

	return &UserAggregate{
		User:       user,
		Profile:    profile,
		Settings:   settings,
		Reputation: reputation,
		Roles:      roles,
	}, nil
}

func (u *UserUseCase) GetAggregateBySubject(ctx context.Context, subjectID string) (*UserAggregate, error) {
	if subjectID == "" {
		return nil, ErrInvalidSubjectID
	}

	user, err := u.repo.GetUserBySubject(ctx, subjectID)
	if err != nil {
		return nil, fmt.Errorf("get user by subject: %w", err)
	}
	if user == nil || user.IsDeleted {
		return nil, ErrUserNotFound
	}

	return u.GetAggregateByUserID(ctx, user.ID)
}

type UpdateProfileInput struct {
	UserID       uuid.UUID
	FirstName    *string
	LastName     *string
	DisplayName  *string
	Bio          *string
	BirthDate    *time.Time
	AvatarFileID *uuid.UUID
	CityID       *uuid.UUID
	CountryCode  *string
	Locale       *string
	Timezone     *string
	Currency     *string
	IsPublic     *bool
}

func (u *UserUseCase) UpdateProfile(ctx context.Context, input UpdateProfileInput) (*model.UserProfile, error) {
	if input.UserID == uuid.Nil {
		return nil, ErrInvalidUserID
	}

	profile, err := u.repo.GetProfileByUserID(ctx, input.UserID)
	if err != nil {
		return nil, fmt.Errorf("get profile by user id: %w", err)
	}
	if profile == nil {
		return nil, ErrProfileNotFound
	}

	if input.AvatarFileID != nil {
		if u.fileManager == nil {
			return nil, fmt.Errorf("file manager client is not configured")
		}

		if err = u.fileManager.ValidateAvatarFile(ctx, *input.AvatarFileID); err != nil {
			return nil, err
		}

		if err = u.fileManager.BindAvatarToUser(ctx, *input.AvatarFileID, input.UserID, &input.UserID); err != nil {
			return nil, fmt.Errorf("bind avatar in file-manager: %w", err)
		}
	}

	if err = profile.ApplyUpdate(model.UpdateUserProfileParams{
		FirstName:    input.FirstName,
		LastName:     input.LastName,
		DisplayName:  input.DisplayName,
		Bio:          input.Bio,
		BirthDate:    input.BirthDate,
		AvatarFileID: input.AvatarFileID,
		CityID:       input.CityID,
		CountryCode:  input.CountryCode,
		Locale:       input.Locale,
		Timezone:     input.Timezone,
		Currency:     input.Currency,
		IsPublic:     input.IsPublic,
	}); err != nil {
		return nil, fmt.Errorf("apply profile update: %w", err)
	}

	if err = u.repo.UpdateProfile(ctx, profile); err != nil {
		return nil, fmt.Errorf("update profile: %w", err)
	}

	return profile, nil
}

func (u *UserUseCase) GrantRole(
	ctx context.Context,
	userID uuid.UUID,
	role enum.SystemRole,
	grantedBy *uuid.UUID,
) error {
	if userID == uuid.Nil {
		return ErrInvalidUserID
	}
	if !role.IsValid() {
		return model.ErrInvalidSystemRole
	}

	exists, err := u.repo.HasRole(ctx, userID, role)
	if err != nil {
		return fmt.Errorf("check role exists: %w", err)
	}
	if exists {
		return ErrRoleAlreadyGranted
	}

	item, err := model.NewUserSystemRole(model.NewUserSystemRoleParams{
		UserID:    userID,
		Role:      role,
		GrantedBy: grantedBy,
	})
	if err != nil {
		return fmt.Errorf("new user role: %w", err)
	}

	if err = u.repo.GrantRole(ctx, item); err != nil {
		return fmt.Errorf("grant role: %w", err)
	}

	return nil
}

func (u *UserUseCase) UpdateSettings(
	ctx context.Context,
	userID uuid.UUID,
	params model.UpdateUserSettingsParams,
) (*model.UserSettings, error) {
	if userID == uuid.Nil {
		return nil, ErrInvalidUserID
	}

	settings, err := u.repo.GetSettingsByUserID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("get settings by user id: %w", err)
	}
	if settings == nil {
		return nil, ErrSettingsNotFound
	}

	if err = settings.ApplyUpdate(params); err != nil {
		return nil, fmt.Errorf("apply settings update: %w", err)
	}

	if err = u.repo.UpdateSettings(ctx, settings); err != nil {
		return nil, fmt.Errorf("update settings: %w", err)
	}

	return settings, nil
}

func (u *UserUseCase) ListPublicProfiles(
	ctx context.Context,
	limit int,
	offset int,
) ([]*model.UserProfile, error) {
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}
	if offset < 0 {
		offset = 0
	}

	items, err := u.repo.ListPublicProfiles(ctx, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("list public profiles: %w", err)
	}

	return items, nil
}

func (u *UserUseCase) GetPublicProfilesByUserIDs(
	ctx context.Context,
	userIDs []uuid.UUID,
) ([]*model.UserProfile, error) {
	if len(userIDs) == 0 {
		return []*model.UserProfile{}, nil
	}

	items, err := u.repo.GetPublicProfilesByUserIDs(ctx, userIDs)
	if err != nil {
		return nil, fmt.Errorf("get public profiles by user ids: %w", err)
	}

	return items, nil
}

type InitIdentityHints struct {
	PrimaryPhone *string
	PrimaryEmail *string
}

func (u *UserUseCase) GetOrCreateBySubjectWithIdentity(
	ctx context.Context,
	input InitUserInput,
	hints InitIdentityHints,
) (*UserAggregate, error) {
	_, err := u.GetOrCreateBySubject(ctx, input)
	if err != nil {
		return nil, err
	}

	if err = u.repo.PatchUserIdentityBySubject(
		ctx,
		input.SubjectID,
		hints.PrimaryPhone,
		hints.PrimaryEmail,
	); err != nil {
		return nil, fmt.Errorf("patch user identity by subject: %w", err)
	}

	return u.GetAggregateBySubject(ctx, input.SubjectID)
}
