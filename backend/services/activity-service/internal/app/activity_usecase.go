package app

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/port"
)

type ActivityUseCase struct {
	repo        port.ActivityRepository
	policy      *PolicyService
	fileManager port.ActivityMediaFileManager
}

func NewActivityUseCase(repo port.ActivityRepository, fileManager ...port.ActivityMediaFileManager) *ActivityUseCase {
	var mediaFiles port.ActivityMediaFileManager
	if len(fileManager) > 0 {
		mediaFiles = fileManager[0]
	}

	return &ActivityUseCase{
		repo:        repo,
		policy:      NewPolicyService(repo),
		fileManager: mediaFiles,
	}
}

func (u *ActivityUseCase) ListActivityCategories() []model.ActivityCategory {
	return model.ListActivityCategories()
}

type CreateActivityInput struct {
	HostUserID   uuid.UUID
	Title        string
	Description  string
	Format       enum.ActivityFormat
	Visibility   enum.ActivityVisibility
	JoinMode     enum.ActivityJoinMode
	CategorySlug string
	Tags         []string
	LanguageCode string
	Timezone     string

	StartAt time.Time
	EndAt   time.Time

	CapacityType    enum.ActivityCapacityType
	MinParticipants *int
	MaxParticipants *int

	PriceType   enum.ActivityPriceType
	PriceAmount *float64
	Currency    *string

	RequiresProfileCompletion      bool
	RequiresAttendanceConfirmation bool
	ConfirmationDeadline           *time.Time

	CountryCode *string
	CityName    *string
	AddressText *string
	Latitude    *float64
	Longitude   *float64
	MapURL      *string
	MeetingURL  *string
	CoverFileID *uuid.UUID

	VisibilityPassword *string

	ReviewRequired bool
}

type UpdateActivityInput struct {
	ActorUserID uuid.UUID
	ActivityID  uuid.UUID

	Title        *string
	Description  *string
	Visibility   *enum.ActivityVisibility
	JoinMode     *enum.ActivityJoinMode
	CategorySlug *string
	Tags         []string
	HasTags      bool
	LanguageCode *string
	Timezone     *string

	StartAt *time.Time
	EndAt   *time.Time

	CapacityType       *enum.ActivityCapacityType
	MinParticipants    *int
	HasMinParticipants bool
	MaxParticipants    *int
	HasMaxParticipants bool

	PriceType      *enum.ActivityPriceType
	PriceAmount    *float64
	HasPriceAmount bool
	Currency       *string
	HasCurrency    bool

	RequiresProfileCompletion      *bool
	RequiresAttendanceConfirmation *bool
	ConfirmationDeadline           *time.Time
	HasConfirmationDeadline        bool

	CountryCode    *string
	HasCountryCode bool
	CityName       *string
	HasCityName    bool
	AddressText    *string
	HasAddressText bool
	Latitude       *float64
	HasLatitude    bool
	Longitude      *float64
	HasLongitude   bool
	MapURL         *string
	HasMapURL      bool
	MeetingURL     *string
	HasMeetingURL  bool
	CoverFileID    *uuid.UUID
	HasCoverFileID bool

	VisibilityPassword    *string
	HasVisibilityPassword bool
}

func (u *ActivityUseCase) CreateActivity(ctx context.Context, input CreateActivityInput) (*model.Activity, error) {
	if input.HostUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}

	categorySlug, err := model.NormalizeAndValidateActivityCategorySlug(input.CategorySlug)
	if err != nil {
		return nil, err
	}
	input.CategorySlug = categorySlug

	if err := u.policy.CheckCreateRateLimit(ctx, input.HostUserID); err != nil {
		return nil, err
	}

	if err := u.validateCoverMediaFile(ctx, input.CoverFileID); err != nil {
		return nil, err
	}

	if err := u.policy.ValidateURLs(
		ctx,
		input.MapURL,
		input.MeetingURL,
	); err != nil {
		return nil, err
	}

	visibilityPassword, err := normalizeVisibilityPassword(
		input.Visibility,
		input.VisibilityPassword,
	)
	if err != nil {
		return nil, err
	}
	visibilityPasswordHash, err := hashVisibilityPassword(visibilityPassword)
	if err != nil {
		return nil, fmt.Errorf("hash visibility password: %w", err)
	}

	item, err := model.NewActivity(model.NewActivityParams{
		HostUserID:                     input.HostUserID,
		Title:                          input.Title,
		Description:                    input.Description,
		Format:                         input.Format,
		Visibility:                     input.Visibility,
		JoinMode:                       input.JoinMode,
		CategorySlug:                   input.CategorySlug,
		LanguageCode:                   input.LanguageCode,
		Timezone:                       input.Timezone,
		StartAt:                        input.StartAt,
		EndAt:                          input.EndAt,
		RegistrationDeadline:           input.StartAt.UTC().Add(-1 * time.Hour),
		CapacityType:                   input.CapacityType,
		MinParticipants:                input.MinParticipants,
		MaxParticipants:                input.MaxParticipants,
		PriceType:                      input.PriceType,
		PriceAmount:                    input.PriceAmount,
		Currency:                       input.Currency,
		RequiresProfileCompletion:      input.RequiresProfileCompletion,
		RequiresAttendanceConfirmation: input.RequiresAttendanceConfirmation,
		ConfirmationDeadline:           input.ConfirmationDeadline,
		CountryCode:                    input.CountryCode,
		CityName:                       input.CityName,
		AddressText:                    input.AddressText,
		Latitude:                       input.Latitude,
		Longitude:                      input.Longitude,
		MapURL:                         input.MapURL,
		MeetingURL:                     input.MeetingURL,
		VisibilityPasswordHash:         visibilityPasswordHash,
	})
	if err != nil {
		return nil, err
	}

	if input.ReviewRequired {
		item.ModerationStatus = enum.ActivityModerationStatusPendingReview
		item.Status = enum.ActivityStatusReviewRequired
	}

	if err = u.repo.CreateActivity(ctx, item); err != nil {
		return nil, fmt.Errorf("create activity: %w", err)
	}

	if len(input.Tags) > 0 {
		if err = u.repo.ReplaceTags(ctx, item.ID, normalizeTags(input.Tags)); err != nil {
			return nil, fmt.Errorf("replace tags: %w", err)
		}
	}

	if err = u.syncCoverMedia(ctx, item.ID, input.HostUserID, input.CoverFileID, input.CoverFileID != nil); err != nil {
		return nil, err
	}

	event, eventErr := model.NewActivityEvent(model.NewActivityEventParams{
		ActivityID:  item.ID,
		EventType:   enum.ActivityEventTypeCreated,
		ActorUserID: &input.HostUserID,
		PayloadJSON: mustJSON(map[string]any{
			"status":           string(item.Status),
			"moderationStatus": string(item.ModerationStatus),
			"format":           string(item.Format),
			"priceType":        string(item.PriceType),
		}),
	})
	if eventErr == nil {
		_ = u.repo.CreateActivityEvent(ctx, event)
	}

	hostParticipant, participantErr := model.NewActivityParticipant(model.NewActivityParticipantParams{
		ActivityID: item.ID,
		UserID:     input.HostUserID,
		Status:     enum.ParticipantStatusApproved,
	})
	if participantErr == nil {
		now := time.Now().UTC()
		hostParticipant.ApprovedAt = &now

		if createErr := u.repo.CreateParticipant(ctx, hostParticipant); createErr == nil {
			participantEvent, pEventErr := model.NewParticipantEvent(model.NewParticipantEventParams{
				ActivityID:    item.ID,
				ParticipantID: hostParticipant.ID,
				UserID:        input.HostUserID,
				EventType:     string(enum.ParticipantStatusApproved),
				ActorUserID:   &input.HostUserID,
				PayloadJSON:   mustJSON(map[string]any{"status": string(enum.ParticipantStatusApproved), "isHost": true}),
			})
			if pEventErr == nil {
				_ = u.repo.CreateParticipantEvent(ctx, participantEvent)
			}
		}
	}

	return item, nil
}

func (u *ActivityUseCase) GetActivityByID(ctx context.Context, activityID uuid.UUID) (*model.Activity, error) {
	if activityID == uuid.Nil {
		return nil, ErrInvalidActivityID
	}

	item, err := u.repo.GetActivityByID(ctx, activityID)
	if err != nil {
		return nil, fmt.Errorf("get activity by id: %w", err)
	}
	if item == nil {
		return nil, ErrActivityNotFound
	}

	return item, nil
}

func (u *ActivityUseCase) ListActivities(ctx context.Context, filter port.ActivityFilter) ([]*model.Activity, error) {
	if filter.Limit <= 0 {
		filter.Limit = 20
	}
	if filter.Limit > 100 {
		filter.Limit = 100
	}
	if filter.Offset < 0 {
		filter.Offset = 0
	}

	items, err := u.repo.ListActivities(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("list activities: %w", err)
	}

	return items, nil
}

func (u *ActivityUseCase) PublishActivity(
	ctx context.Context,
	activityID uuid.UUID,
	actorUserID uuid.UUID,
	reviewRequired bool,
) (*model.Activity, error) {
	item, err := u.GetActivityByID(ctx, activityID)
	if err != nil {
		return nil, err
	}
	if actorUserID == uuid.Nil || actorUserID != item.HostUserID {
		return nil, ErrInvalidActorUserID
	}
	if item.Status == enum.ActivityStatusEnrollmentOpen || item.Status == enum.ActivityStatusPublished {
		return nil, ErrActivityAlreadyPublished
	}

	if err = item.Publish(time.Now().UTC(), reviewRequired); err != nil {
		return nil, err
	}

	if err = u.repo.UpdateActivity(ctx, item); err != nil {
		return nil, fmt.Errorf("update activity on publish: %w", err)
	}

	eventType := enum.ActivityEventTypePublished
	if reviewRequired {
		eventType = enum.ActivityEventTypeSubmittedForReview
	}

	event, eventErr := model.NewActivityEvent(model.NewActivityEventParams{
		ActivityID:  item.ID,
		EventType:   eventType,
		ActorUserID: &actorUserID,
		PayloadJSON: mustJSON(map[string]any{
			"status":           string(item.Status),
			"moderationStatus": string(item.ModerationStatus),
		}),
	})
	if eventErr == nil {
		_ = u.repo.CreateActivityEvent(ctx, event)
	}

	return item, nil
}

func (u *ActivityUseCase) DuplicateActivity(
	ctx context.Context,
	activityID uuid.UUID,
	actorUserID uuid.UUID,
	newStartAt time.Time,
	newEndAt time.Time,
	newRegistrationDeadline time.Time,
) (*model.Activity, error) {
	source, err := u.GetActivityByID(ctx, activityID)
	if err != nil {
		return nil, err
	}

	if err = source.CanDuplicate(actorUserID); err != nil {
		return nil, err
	}

	categorySlug, err := model.NormalizeAndValidateActivityCategorySlug(source.CategorySlug)
	if err != nil {
		return nil, err
	}

	dup, err := model.NewActivity(model.NewActivityParams{
		HostUserID:                     source.HostUserID,
		SourceActivityID:               &source.ID,
		Title:                          source.Title,
		Description:                    source.Description,
		Format:                         source.Format,
		Visibility:                     source.Visibility,
		JoinMode:                       source.JoinMode,
		CategorySlug:                   categorySlug,
		LanguageCode:                   source.LanguageCode,
		Timezone:                       source.Timezone,
		StartAt:                        newStartAt,
		EndAt:                          newEndAt,
		RegistrationDeadline:           newRegistrationDeadline,
		CapacityType:                   source.CapacityType,
		MinParticipants:                source.MinParticipants,
		MaxParticipants:                source.MaxParticipants,
		PriceType:                      source.PriceType,
		PriceAmount:                    source.PriceAmount,
		Currency:                       source.Currency,
		RequiresProfileCompletion:      source.RequiresProfileCompletion,
		RequiresAttendanceConfirmation: source.RequiresAttendanceConfirmation,
		ConfirmationDeadline:           source.ConfirmationDeadline,
		CountryCode:                    source.CountryCode,
		CityName:                       source.CityName,
		AddressText:                    source.AddressText,
		Latitude:                       source.Latitude,
		Longitude:                      source.Longitude,
		MapURL:                         source.MapURL,
		MeetingURL:                     source.MeetingURL,
		VisibilityPasswordHash:         source.VisibilityPasswordHash,
	})
	if err != nil {
		return nil, err
	}

	if err = u.repo.CreateActivity(ctx, dup); err != nil {
		return nil, fmt.Errorf("create duplicated activity: %w", err)
	}

	tags, err := u.repo.ListTagsByActivityID(ctx, source.ID)
	if err == nil && len(tags) > 0 {
		_ = u.repo.ReplaceTags(ctx, dup.ID, tags)
	}

	media, err := u.repo.ListMediaByActivityID(ctx, source.ID)
	if err == nil && len(media) > 0 {
		cloned := make([]*model.ActivityMedia, 0, len(media))
		for _, m := range media {
			item, mediaErr := model.NewActivityMedia(model.NewActivityMediaParams{
				ActivityID: dup.ID,
				FileID:     m.FileID,
				MediaType:  m.MediaType,
				SortOrder:  m.SortOrder,
				IsCover:    m.IsCover,
			})
			if mediaErr == nil {
				cloned = append(cloned, item)
			}
		}
		if len(cloned) > 0 {
			_ = u.repo.ReplaceMedia(ctx, dup.ID, cloned)
		}
	}

	event, eventErr := model.NewActivityEvent(model.NewActivityEventParams{
		ActivityID:  dup.ID,
		EventType:   enum.ActivityEventTypeDuplicated,
		ActorUserID: &actorUserID,
		PayloadJSON: mustJSON(map[string]any{
			"sourceActivityId": source.ID.String(),
		}),
	})
	if eventErr == nil {
		_ = u.repo.CreateActivityEvent(ctx, event)
	}

	return dup, nil
}

func (u *ActivityUseCase) StartActivity(
	ctx context.Context,
	activityID uuid.UUID,
	actorUserID uuid.UUID,
) (*model.Activity, error) {
	item, err := u.GetActivityByID(ctx, activityID)
	if err != nil {
		return nil, err
	}
	if actorUserID == uuid.Nil || actorUserID != item.HostUserID {
		return nil, ErrInvalidActorUserID
	}
	if item.Status == enum.ActivityStatusStarted {
		return nil, ErrActivityAlreadyStarted
	}
	if item.Status != enum.ActivityStatusEnrollmentOpen &&
		item.Status != enum.ActivityStatusFull &&
		item.Status != enum.ActivityStatusPublished {
		return nil, ErrActivityNotStartable
	}

	now := time.Now().UTC()
	item.Status = enum.ActivityStatusStarted
	item.StartedAt = &now
	item.Revision++
	item.UpdatedAt = now

	if err = u.repo.UpdateActivity(ctx, item); err != nil {
		return nil, fmt.Errorf("start activity: %w", err)
	}

	event, eventErr := model.NewActivityEvent(model.NewActivityEventParams{
		ActivityID:  item.ID,
		EventType:   enum.ActivityEventTypeStarted,
		ActorUserID: &actorUserID,
		PayloadJSON: mustJSON(map[string]any{
			"startedAt": now.Format(time.RFC3339),
		}),
	})
	if eventErr == nil {
		_ = u.repo.CreateActivityEvent(ctx, event)
	}

	return item, nil
}

func (u *ActivityUseCase) CompleteActivity(
	ctx context.Context,
	activityID uuid.UUID,
	actorUserID uuid.UUID,
) (*model.Activity, error) {
	item, err := u.GetActivityByID(ctx, activityID)
	if err != nil {
		return nil, err
	}
	if actorUserID == uuid.Nil || actorUserID != item.HostUserID {
		return nil, ErrInvalidActorUserID
	}
	if item.Status == enum.ActivityStatusCompleted {
		return nil, ErrActivityAlreadyCompleted
	}
	if item.Status != enum.ActivityStatusStarted {
		return nil, ErrActivityNotCompletable
	}

	now := time.Now().UTC()
	item.Status = enum.ActivityStatusCompleted
	item.CompletedAt = &now
	item.Revision++
	item.UpdatedAt = now

	if err = u.repo.UpdateActivity(ctx, item); err != nil {
		return nil, fmt.Errorf("complete activity: %w", err)
	}

	event, eventErr := model.NewActivityEvent(model.NewActivityEventParams{
		ActivityID:  item.ID,
		EventType:   enum.ActivityEventTypeCompleted,
		ActorUserID: &actorUserID,
		PayloadJSON: mustJSON(map[string]any{
			"completedAt": now.Format(time.RFC3339),
		}),
	})
	if eventErr == nil {
		_ = u.repo.CreateActivityEvent(ctx, event)
	}

	return item, nil
}

func (u *ActivityUseCase) CancelActivity(
	ctx context.Context,
	activityID uuid.UUID,
	actorUserID uuid.UUID,
	reason string,
) (*model.Activity, error) {
	item, err := u.GetActivityByID(ctx, activityID)
	if err != nil {
		return nil, err
	}
	if actorUserID == uuid.Nil || actorUserID != item.HostUserID {
		return nil, ErrInvalidActorUserID
	}
	if item.Status == enum.ActivityStatusCancelled {
		return nil, ErrActivityAlreadyCancelled
	}
	if item.Status.IsTerminal() {
		return nil, ErrActivityNotCancellable
	}

	now := time.Now().UTC()
	reason = strings.TrimSpace(reason)
	if reason == "" {
		return nil, ErrActivityCancellationReasonRequired
	}

	item.Status = enum.ActivityStatusCancelled
	item.CancelledAt = &now
	item.CancellationReason = model.NormalizeOptionalString(&reason)
	item.Revision++
	item.UpdatedAt = now

	if err = u.repo.UpdateActivity(ctx, item); err != nil {
		return nil, fmt.Errorf("cancel activity: %w", err)
	}

	event, eventErr := model.NewActivityEvent(model.NewActivityEventParams{
		ActivityID:  item.ID,
		EventType:   enum.ActivityEventTypeCancelled,
		ActorUserID: &actorUserID,
		PayloadJSON: mustJSON(map[string]any{
			"cancelledAt": now.Format(time.RFC3339),
			"reason":      reason,
		}),
	})
	if eventErr == nil {
		_ = u.repo.CreateActivityEvent(ctx, event)
	}

	return item, nil
}

func (u *ActivityUseCase) ArchiveActivity(
	ctx context.Context,
	activityID uuid.UUID,
	actorUserID uuid.UUID,
) (*model.Activity, error) {
	item, err := u.GetActivityByID(ctx, activityID)
	if err != nil {
		return nil, err
	}
	if actorUserID == uuid.Nil || actorUserID != item.HostUserID {
		return nil, ErrInvalidActorUserID
	}
	if item.Status == enum.ActivityStatusArchived {
		return nil, ErrActivityAlreadyArchived
	}
	if item.Status != enum.ActivityStatusCancelled {
		return nil, ErrActivityNotArchivable
	}

	now := time.Now().UTC()
	item.Status = enum.ActivityStatusArchived
	item.Revision++
	item.UpdatedAt = now

	if err = u.repo.UpdateActivity(ctx, item); err != nil {
		return nil, fmt.Errorf("archive activity: %w", err)
	}

	event, eventErr := model.NewActivityEvent(model.NewActivityEventParams{
		ActivityID:  item.ID,
		EventType:   enum.ActivityEventTypeArchived,
		ActorUserID: &actorUserID,
		PayloadJSON: mustJSON(map[string]any{
			"archivedAt": now.Format(time.RFC3339),
		}),
	})
	if eventErr == nil {
		_ = u.repo.CreateActivityEvent(ctx, event)
	}

	return item, nil
}

func (u *ActivityUseCase) UpdateActivity(ctx context.Context, input UpdateActivityInput) (*model.Activity, error) {
	if input.ActorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if input.ActivityID == uuid.Nil {
		return nil, ErrInvalidActivityID
	}

	item, err := u.GetActivityByID(ctx, input.ActivityID)
	if err != nil {
		return nil, err
	}
	if item.HostUserID != input.ActorUserID {
		return nil, ErrInvalidActorUserID
	}

	beforePriceType := item.PriceType
	beforePriceAmount := item.PriceAmount
	beforeCurrency := item.Currency
	beforeLocationSnapshot := locationSnapshot(item)

	if input.Title != nil {
		item.Title = strings.TrimSpace(*input.Title)
	}
	if input.Description != nil {
		item.Description = strings.TrimSpace(*input.Description)
	}
	if input.Visibility != nil {
		item.Visibility = *input.Visibility
	}
	if input.JoinMode != nil {
		item.JoinMode = *input.JoinMode
	}
	if input.CategorySlug != nil {
		categorySlug, categoryErr := model.NormalizeAndValidateActivityCategorySlug(*input.CategorySlug)
		if categoryErr != nil {
			return nil, categoryErr
		}
		item.CategorySlug = categorySlug
	}
	if input.LanguageCode != nil {
		item.LanguageCode = strings.TrimSpace(*input.LanguageCode)
	}
	if input.Timezone != nil {
		item.Timezone = strings.TrimSpace(*input.Timezone)
	}
	if input.StartAt != nil {
		item.StartAt = input.StartAt.UTC()
	}
	if input.EndAt != nil {
		item.EndAt = input.EndAt.UTC()
	}
	if input.StartAt != nil {
		item.RegistrationDeadline = input.StartAt.UTC().Add(-1 * time.Hour)
	}
	if input.CapacityType != nil {
		item.CapacityType = *input.CapacityType
	}
	if input.HasMinParticipants {
		item.MinParticipants = input.MinParticipants
	}
	if input.HasMaxParticipants {
		item.MaxParticipants = input.MaxParticipants
	}
	if input.PriceType != nil {
		item.PriceType = *input.PriceType
	}
	if input.HasPriceAmount {
		item.PriceAmount = input.PriceAmount
	}
	if input.HasCurrency {
		item.Currency = model.NormalizeOptionalString(input.Currency)
	}
	if input.RequiresProfileCompletion != nil {
		item.RequiresProfileCompletion = *input.RequiresProfileCompletion
	}
	if input.RequiresAttendanceConfirmation != nil {
		item.RequiresAttendanceConfirmation = *input.RequiresAttendanceConfirmation
	}
	if input.HasConfirmationDeadline {
		item.ConfirmationDeadline = input.ConfirmationDeadline
	}
	if input.HasCountryCode {
		item.CountryCode = model.NormalizeOptionalString(input.CountryCode)
	}
	if input.HasCityName {
		item.CityName = model.NormalizeOptionalString(input.CityName)
	}
	if input.HasAddressText {
		item.AddressText = model.NormalizeOptionalString(input.AddressText)
	}
	if input.HasLatitude {
		item.Latitude = input.Latitude
	}
	if input.HasLongitude {
		item.Longitude = input.Longitude
	}
	if input.HasMapURL {
		item.MapURL = model.NormalizeOptionalString(input.MapURL)
	}
	if input.HasMeetingURL {
		item.MeetingURL = model.NormalizeOptionalString(input.MeetingURL)
	}
	if input.HasVisibilityPassword {
		visibilityPassword, passwordErr := normalizeVisibilityPassword(
			item.Visibility,
			input.VisibilityPassword,
		)
		if passwordErr != nil {
			return nil, passwordErr
		}
		visibilityPasswordHash, hashErr := hashVisibilityPassword(visibilityPassword)
		if hashErr != nil {
			return nil, fmt.Errorf("hash visibility password: %w", hashErr)
		}
		item.VisibilityPasswordHash = visibilityPasswordHash
	} else if item.Visibility != enum.ActivityVisibilityPrivate {
		item.VisibilityPasswordHash = nil
	}

	if err = u.policy.ValidateURLs(
		ctx,
		item.MapURL,
		item.MeetingURL,
	); err != nil {
		return nil, err
	}

	if input.HasCoverFileID {
		if err = u.validateCoverMediaFile(ctx, input.CoverFileID); err != nil {
			return nil, err
		}
	}

	if err = u.validateUpdateRules(ctx, item, beforePriceType, beforePriceAmount, beforeCurrency, beforeLocationSnapshot, input.StartAt != nil); err != nil {
		return nil, err
	}

	item.Revision++
	item.UpdatedAt = time.Now().UTC()

	if err = u.repo.UpdateActivity(ctx, item); err != nil {
		return nil, fmt.Errorf("update activity: %w", err)
	}

	if input.HasTags {
		if err = u.repo.ReplaceTags(ctx, item.ID, normalizeTags(input.Tags)); err != nil {
			return nil, fmt.Errorf("replace tags: %w", err)
		}
	}

	if err = u.syncCoverMedia(ctx, item.ID, input.ActorUserID, input.CoverFileID, input.HasCoverFileID); err != nil {
		return nil, err
	}

	event, eventErr := model.NewActivityEvent(model.NewActivityEventParams{
		ActivityID:  item.ID,
		EventType:   enum.ActivityEventTypeUpdated,
		ActorUserID: &input.ActorUserID,
		PayloadJSON: mustJSON(map[string]any{
			"revision": item.Revision,
		}),
	})
	if eventErr == nil {
		_ = u.repo.CreateActivityEvent(ctx, event)
	}

	if priceChanged(beforePriceType, beforePriceAmount, beforeCurrency, item) {
		priceEvent, priceEventErr := model.NewActivityEvent(model.NewActivityEventParams{
			ActivityID:  item.ID,
			EventType:   enum.ActivityEventTypePriceChanged,
			ActorUserID: &input.ActorUserID,
			PayloadJSON: mustJSON(map[string]any{
				"priceType":   string(item.PriceType),
				"priceAmount": item.PriceAmount,
				"currency":    item.Currency,
			}),
		})
		if priceEventErr == nil {
			_ = u.repo.CreateActivityEvent(ctx, priceEvent)
		}
	}

	if locationSnapshot(item) != beforeLocationSnapshot {
		locEvent, locEventErr := model.NewActivityEvent(model.NewActivityEventParams{
			ActivityID:  item.ID,
			EventType:   enum.ActivityEventTypeLocationChanged,
			ActorUserID: &input.ActorUserID,
			PayloadJSON: mustJSON(map[string]any{
				"format":      string(item.Format),
				"countryCode": item.CountryCode,
				"cityName":    item.CityName,
				"meetingUrl":  item.MeetingURL,
			}),
		})
		if locEventErr == nil {
			_ = u.repo.CreateActivityEvent(ctx, locEvent)
		}
	}

	return item, nil
}

func (u *ActivityUseCase) validateUpdateRules(
	ctx context.Context,
	item *model.Activity,
	beforePriceType enum.ActivityPriceType,
	beforePriceAmount *float64,
	beforeCurrency *string,
	beforeLocationSnapshot string,
	startAtChanged bool,
) error {
	now := time.Now().UTC()

	if item.Status != enum.ActivityStatusDraft && item.Status != enum.ActivityStatusReviewRequired {
		if startAtChanged && !item.StartAt.After(now.Add(1*time.Hour)) {
			return model.ErrActivityTooSoon
		}
		if item.Format != enum.ActivityFormatOnline && locationSnapshot(item) != beforeLocationSnapshot {
			return ErrCriticalFieldsUpdateForbidden
		}
	}

	skipStartTimeCheck := !startAtChanged
	if err := item.Validate(now, skipStartTimeCheck); err != nil {
		if item.Status != enum.ActivityStatusDraft && item.Status != enum.ActivityStatusReviewRequired {
			switch {
			case errors.Is(err, model.ErrInvalidOfflineLocation),
				errors.Is(err, model.ErrInvalidMeetingURL),
				errors.Is(err, model.ErrInvalidActivityTimeRange),
				errors.Is(err, model.ErrInvalidRegistrationDeadline):
				return ErrCriticalFieldsUpdateForbidden
			}
		}
		return err
	}

	if priceChanged(beforePriceType, beforePriceAmount, beforeCurrency, item) {
		if err := item.CanChangePrice(); err != nil {
			return ErrPriceChangeForbidden
		}

		participants, err := u.repo.ListParticipantsByActivityID(ctx, item.ID, 1, 0)
		if err == nil && len(participants) > 0 {
			return ErrPriceChangeForbidden
		}
	}

	return nil
}

func (u *ActivityUseCase) ApproveModeration(
	ctx context.Context,
	activityID uuid.UUID,
	moderatorUserID uuid.UUID,
) (*model.Activity, error) {
	item, err := u.GetActivityByID(ctx, activityID)
	if err != nil {
		return nil, err
	}
	if moderatorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if item.ModerationStatus != enum.ActivityModerationStatusPendingReview {
		return nil, ErrModerationStateInvalid
	}

	if err = item.ApproveModeration(time.Now().UTC()); err != nil {
		return nil, err
	}

	if err = u.repo.UpdateActivity(ctx, item); err != nil {
		return nil, fmt.Errorf("approve moderation: %w", err)
	}

	event, eventErr := model.NewActivityEvent(model.NewActivityEventParams{
		ActivityID:  item.ID,
		EventType:   enum.ActivityEventTypeModerationApproved,
		ActorUserID: &moderatorUserID,
		PayloadJSON: mustJSON(map[string]any{
			"status":           string(item.Status),
			"moderationStatus": string(item.ModerationStatus),
		}),
	})
	if eventErr == nil {
		_ = u.repo.CreateActivityEvent(ctx, event)
	}

	return item, nil
}

func (u *ActivityUseCase) RejectModeration(
	ctx context.Context,
	activityID uuid.UUID,
	moderatorUserID uuid.UUID,
) (*model.Activity, error) {
	item, err := u.GetActivityByID(ctx, activityID)
	if err != nil {
		return nil, err
	}
	if moderatorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if item.ModerationStatus != enum.ActivityModerationStatusPendingReview {
		return nil, ErrModerationStateInvalid
	}

	if err = item.RejectModeration(time.Now().UTC()); err != nil {
		return nil, err
	}

	if err = u.repo.UpdateActivity(ctx, item); err != nil {
		return nil, fmt.Errorf("reject moderation: %w", err)
	}

	event, eventErr := model.NewActivityEvent(model.NewActivityEventParams{
		ActivityID:  item.ID,
		EventType:   enum.ActivityEventTypeModerationRejected,
		ActorUserID: &moderatorUserID,
		PayloadJSON: mustJSON(map[string]any{
			"status":           string(item.Status),
			"moderationStatus": string(item.ModerationStatus),
		}),
	})
	if eventErr == nil {
		_ = u.repo.CreateActivityEvent(ctx, event)
	}

	return item, nil
}

func (u *ActivityUseCase) ListHostedActivities(
	ctx context.Context,
	userID uuid.UUID,
	limit int,
	offset int,
) ([]*model.Activity, error) {
	if userID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}
	if offset < 0 {
		offset = 0
	}

	items, err := u.repo.ListHostedActivitiesByUserID(ctx, userID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("list hosted activities: %w", err)
	}

	return items, nil
}

func (u *ActivityUseCase) ListJoinedActivities(
	ctx context.Context,
	userID uuid.UUID,
	limit int,
	offset int,
) ([]*model.Activity, error) {
	if userID == uuid.Nil {
		return nil, ErrInvalidParticipantUserID
	}
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}
	if offset < 0 {
		offset = 0
	}

	items, err := u.repo.ListJoinedActivitiesByUserID(ctx, userID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("list joined activities: %w", err)
	}

	return items, nil
}

func (u *ActivityUseCase) validateCoverMediaFile(ctx context.Context, fileID *uuid.UUID) error {
	if fileID == nil || *fileID == uuid.Nil || u.fileManager == nil {
		return nil
	}

	return u.fileManager.ValidateActivityMediaFile(ctx, *fileID)
}

func (u *ActivityUseCase) syncCoverMedia(
	ctx context.Context,
	activityID uuid.UUID,
	actorUserID uuid.UUID,
	coverFileID *uuid.UUID,
	hasCover bool,
) error {
	if !hasCover {
		return nil
	}

	if coverFileID == nil || *coverFileID == uuid.Nil {
		if err := u.repo.ReplaceMedia(ctx, activityID, nil); err != nil {
			return fmt.Errorf("clear cover media: %w", err)
		}
		return nil
	}

	coverMedia, err := model.NewActivityMedia(model.NewActivityMediaParams{
		ActivityID: activityID,
		FileID:     *coverFileID,
		MediaType:  model.ActivityMediaTypeImage,
		SortOrder:  0,
		IsCover:    true,
	})
	if err != nil {
		return err
	}

	if err = u.repo.ReplaceMedia(ctx, activityID, []*model.ActivityMedia{coverMedia}); err != nil {
		return fmt.Errorf("replace cover media: %w", err)
	}

	if u.fileManager != nil {
		_ = u.fileManager.BindActivityMediaToActivity(ctx, *coverFileID, activityID, actorUserID)
	}

	return nil
}

func normalizeTags(tags []string) []string {
	seen := make(map[string]struct{}, len(tags))
	result := make([]string, 0, len(tags))

	for _, tag := range tags {
		tag = strings.ToLower(strings.TrimSpace(tag))
		if tag == "" {
			continue
		}
		if _, exists := seen[tag]; exists {
			continue
		}
		seen[tag] = struct{}{}
		result = append(result, tag)
	}

	return result
}

func mustJSON(v any) []byte {
	b, err := json.Marshal(v)
	if err != nil {
		return []byte(`{}`)
	}
	return b
}

func priceChanged(
	beforeType enum.ActivityPriceType,
	beforeAmount *float64,
	beforeCurrency *string,
	item *model.Activity,
) bool {
	if beforeType != item.PriceType {
		return true
	}

	switch {
	case beforeAmount == nil && item.PriceAmount != nil:
		return true
	case beforeAmount != nil && item.PriceAmount == nil:
		return true
	case beforeAmount != nil && item.PriceAmount != nil && *beforeAmount != *item.PriceAmount:
		return true
	}

	return model.ValueOrEmpty(beforeCurrency) != model.ValueOrEmpty(item.Currency)
}

func locationSnapshot(item *model.Activity) string {
	return strings.Join([]string{
		string(item.Format),
		model.ValueOrEmpty(item.CountryCode),
		model.ValueOrEmpty(item.CityName),
		model.ValueOrEmpty(item.AddressText),
		model.ValueOrEmpty(item.MapURL),
		model.ValueOrEmpty(item.MeetingURL),
	}, "|")
}
