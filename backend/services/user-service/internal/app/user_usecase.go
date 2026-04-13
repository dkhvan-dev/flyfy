package app

import (
	"context"
	"errors"
	"fmt"
	"strings"
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
	input.SubjectID = strings.TrimSpace(input.SubjectID)
	if input.SubjectID == "" {
		return nil, ErrInvalidSubjectID
	}

	existingUser, err := u.repo.GetUserBySubject(ctx, input.SubjectID)
	if err != nil && !errors.Is(err, ErrUserNotFound) {
		return nil, fmt.Errorf("get user by subject: %w", err)
	}
	if existingUser != nil {
		return u.GetAggregateBySubject(ctx, input.SubjectID)
	}

	userID := uuid.New()
	defaultCurrency := "KZT"
	defaultLocale := "KZ"
	defaultTimezone := "Asia/Almaty"

	profile := &model.UserProfile{
		UserID:             userID,
		Locale:             defaultLocale,
		Timezone:           defaultTimezone,
		Currency:           &defaultCurrency,
		IsPublic:           true,
		IsProfileCompleted: false,
		CreatedAt:          time.Now().UTC(),
		UpdatedAt:          time.Now().UTC(),
	}

	user := &model.User{
		ID:            userID,
		AuthSubjectID: input.SubjectID,
		Status:        enum.UserStatusActive,
		PrimaryPhone:  normalizeOptionalString(input.PrimaryPhone),
		PrimaryEmail:  normalizeOptionalString(input.PrimaryEmail),
		CreatedAt:     time.Now().UTC(),
		UpdatedAt:     time.Now().UTC(),
	}

	settings := &model.UserSettings{
		UserID:                    userID,
		NotificationsPushEnabled:  true,
		NotificationsEmailEnabled: true,
		NotificationsSMSEnabled:   true,
		MarketingEnabled:          false,
		DarkModeEnabled:           false,
		CreatedAt:                 time.Now().UTC(),
		UpdatedAt:                 time.Now().UTC(),
	}

	reputation := &model.UserReputation{
		UserID:              userID,
		TrustScore:          0,
		RiskScore:           0,
		CompletedBookings:   0,
		CompletedActivities: 0,
		CancellationsCount:  0,
		ReportsCount:        0,
		CreatedAt:           time.Now().UTC(),
		UpdatedAt:           time.Now().UTC(),
	}

	defaultRole := &model.UserSystemRole{
		UserID:    userID,
		Role:      enum.SystemRoleUser,
		GrantedAt: time.Now().UTC(),
	}

	if err = u.repo.CreateUserAggregate(ctx, user, profile, settings, reputation, defaultRole); err != nil {
		return nil, fmt.Errorf("create user aggregate: %w", err)
	}

	return u.GetAggregateBySubject(ctx, input.SubjectID)
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

func (u *UserUseCase) UpdateProfile(ctx context.Context, userID uuid.UUID, input UpdateProfileInput) (*UserAggregate, error) {
	profile, err := u.repo.GetProfileByUserID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("get profile by user id: %w", err)
	}
	if profile == nil {
		return nil, ErrProfileNotFound
	}

	if avatarFileID := input.AvatarFileID; avatarFileID != nil {
		avatarChanged := profile.AvatarFileID == nil || *profile.AvatarFileID != *avatarFileID
		if avatarChanged {
			if err = u.fileManager.ValidateAvatarFile(ctx, *avatarFileID); err != nil {
				return nil, fmt.Errorf("validate avatar file: %w", err)
			}
			if err = u.fileManager.BindAvatarToUser(ctx, *avatarFileID, userID, &userID); err != nil {
				return nil, fmt.Errorf("bind avatar file: %w", err)
			}
		}
	}

	nextDisplayName := profile.DisplayName
	if input.DisplayName != nil {
		nextDisplayName = normalizeOptionalString(input.DisplayName)
	}
	if nextDisplayName != nil {
		taken, err := u.repo.IsDisplayNameTaken(ctx, *nextDisplayName, userID)
		if err != nil {
			return nil, fmt.Errorf("check display name uniqueness: %w", err)
		}
		if taken {
			return nil, ErrDisplayNameAlreadyTaken
		}
	}

	profile.FirstName = normalizeOptionalString(input.FirstName)
	profile.LastName = normalizeOptionalString(input.LastName)
	profile.DisplayName = normalizeOptionalString(input.DisplayName)
	profile.Bio = normalizeOptionalString(input.Bio)
	profile.BirthDate = input.BirthDate
	profile.AvatarFileID = input.AvatarFileID
	profile.CityID = input.CityID
	profile.CountryCode = normalizeOptionalString(input.CountryCode)

	if input.Locale != nil {
		if locale := strings.TrimSpace(*input.Locale); locale != "" {
			profile.Locale = locale
		}
	}
	if input.Timezone != nil {
		if timezone := strings.TrimSpace(*input.Timezone); timezone != "" {
			profile.Timezone = timezone
		}
	}

	profile.Currency = normalizeOptionalString(input.Currency)

	if input.IsPublic != nil {
		profile.IsPublic = *input.IsPublic
	}

	profile.IsProfileCompleted = computeProfileCompleted(profile)
	profile.UpdatedAt = time.Now().UTC()

	if err = u.repo.UpdateProfile(ctx, profile); err != nil {
		return nil, fmt.Errorf("update profile: %w", err)
	}

	return u.GetAggregateByUserID(ctx, userID)
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

func (u *UserUseCase) GetUserBySubject(ctx context.Context, subjectID string) (*UserAggregate, error) {
	subjectID = strings.TrimSpace(subjectID)
	if subjectID == "" {
		return nil, ErrInvalidSubjectID
	}

	user, err := u.repo.GetUserBySubject(ctx, subjectID)
	if err != nil {
		return nil, err
	}

	profile, err := u.repo.GetProfileByUserID(ctx, user.ID)
	if err != nil {
		return nil, err
	}

	settings, err := u.repo.GetSettingsByUserID(ctx, user.ID)
	if err != nil {
		return nil, err
	}

	reputation, err := u.repo.GetReputationByUserID(ctx, user.ID)
	if err != nil {
		return nil, err
	}

	roles, err := u.repo.ListRolesByUserID(ctx, user.ID)
	if err != nil {
		return nil, err
	}

	return &UserAggregate{
		User:       user,
		Profile:    profile,
		Settings:   settings,
		Reputation: reputation,
		Roles:      roles,
	}, nil
}

func computeProfileCompleted(profile *model.UserProfile) bool {
	if profile == nil {
		return false
	}

	firstName := ""
	if profile.FirstName != nil {
		firstName = strings.TrimSpace(*profile.FirstName)
	}

	lastName := ""
	if profile.LastName != nil {
		lastName = strings.TrimSpace(*profile.LastName)
	}

	return firstName != "" && lastName != ""
}
