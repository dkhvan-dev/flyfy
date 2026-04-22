package app

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/port"
)

type ActivityUseCase struct {
	repo        port.ActivityRepository
	policy      *PolicyService
	fileManager port.ActivityMediaFileManager
	chatGateway port.ActivityChatGateway
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

func (u *ActivityUseCase) SetChatGateway(chatGateway port.ActivityChatGateway) {
	u.chatGateway = chatGateway
}

func (u *ActivityUseCase) syncActivityChat(ctx context.Context, item *model.Activity) {
	if u.chatGateway == nil || item == nil || item.ID == uuid.Nil {
		return
	}

	activityID := item.ID
	title := item.Title
	until := activityChatMessagingAvailableUntil(item)

	go func() {
		chatCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), 5*time.Second)
		defer cancel()

		coverFileID := ""
		media, err := u.repo.ListMediaByActivityID(chatCtx, activityID)
		if err != nil {
			log.Warn().
				Err(err).
				Str("activity_id", activityID.String()).
				Msg("failed to resolve activity cover for chat sync")
		} else {
			coverFileID = activityCoverFileID(media)
		}

		if err := u.chatGateway.SyncActivityConversation(chatCtx, port.SyncActivityConversationInput{
			ActivityID:              activityID,
			ActivityTitle:           title,
			ActivityAvatarFileID:    coverFileID,
			MessagingAvailableUntil: &until,
		}); err != nil {
			log.Warn().
				Err(err).
				Str("activity_id", activityID.String()).
				Msg("failed to sync activity chat")
		}
	}()
}

func activityChatMessagingAvailableUntil(item *model.Activity) time.Time {
	if item == nil {
		return time.Now().UTC()
	}
	closedAt := item.EndAt
	if item.CancelledAt != nil {
		closedAt = item.CancelledAt.UTC()
	} else if item.CompletedAt != nil {
		closedAt = item.CompletedAt.UTC()
	}
	return closedAt.UTC().Add(time.Hour)
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
		Status:     enum.ParticipantStatusCheckedIn,
	})
	if participantErr == nil {
		now := time.Now().UTC()
		approvedAt := now
		checkedInAt := now
		hostParticipant.ApprovedAt = &approvedAt
		hostParticipant.CheckedInAt = &checkedInAt

		if createErr := u.repo.CreateParticipant(ctx, hostParticipant); createErr == nil {
			participantEvent, pEventErr := model.NewParticipantEvent(model.NewParticipantEventParams{
				ActivityID:    item.ID,
				ParticipantID: hostParticipant.ID,
				UserID:        input.HostUserID,
				EventType:     string(enum.ParticipantStatusCheckedIn),
				ActorUserID:   &input.HostUserID,
				PayloadJSON:   mustJSON(map[string]any{"status": string(enum.ParticipantStatusCheckedIn), "isHost": true}),
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

	return u.normalizeLifecycle(ctx, item)
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

	return u.normalizeLifecycleList(ctx, items)
}

func isActivityAutoCompletableStatus(status enum.ActivityStatus) bool {
	switch status {
	case enum.ActivityStatusPublished,
		enum.ActivityStatusEnrollmentOpen,
		enum.ActivityStatusFull,
		enum.ActivityStatusStarted:
		return true
	default:
		return false
	}
}

func isActivityAutoStartableStatus(status enum.ActivityStatus) bool {
	switch status {
	case enum.ActivityStatusPublished,
		enum.ActivityStatusEnrollmentOpen,
		enum.ActivityStatusFull:
		return true
	default:
		return false
	}
}

func isActivityManuallyCompletableStatus(status enum.ActivityStatus) bool {
	return isActivityAutoCompletableStatus(status)
}

func isActivityExtendableStatus(status enum.ActivityStatus) bool {
	switch status {
	case enum.ActivityStatusPublished,
		enum.ActivityStatusEnrollmentOpen,
		enum.ActivityStatusFull,
		enum.ActivityStatusStarted:
		return true
	default:
		return false
	}
}

func (u *ActivityUseCase) normalizeLifecycle(
	ctx context.Context,
	item *model.Activity,
) (*model.Activity, error) {
	if item == nil {
		return item, nil
	}

	now := time.Now().UTC()
	if isActivityAutoCompletableStatus(item.Status) && !now.Before(item.EndAt) {
		return u.completeActivityInternal(
			ctx,
			item,
			nil,
			item.EndAt,
			nil,
			"automatic",
		)
	}

	if isActivityAutoStartableStatus(item.Status) && !now.Before(item.StartAt) {
		return u.startActivityInternal(
			ctx,
			item,
			nil,
			item.StartAt,
			"automatic",
		)
	}

	return item, nil
}

func (u *ActivityUseCase) normalizeLifecycleList(
	ctx context.Context,
	items []*model.Activity,
) ([]*model.Activity, error) {
	for index, item := range items {
		normalized, err := u.normalizeLifecycle(ctx, item)
		if err != nil {
			return nil, err
		}
		items[index] = normalized
	}
	return items, nil
}

func (u *ActivityUseCase) AutoCompleteDueActivities(
	ctx context.Context,
	limit int,
) (int, error) {
	items, err := u.repo.ListActivitiesDueForCompletion(ctx, time.Now().UTC(), limit)
	if err != nil {
		return 0, fmt.Errorf("list activities due for completion: %w", err)
	}

	completedCount := 0
	for _, item := range items {
		if item == nil || !isActivityAutoCompletableStatus(item.Status) {
			continue
		}

		if _, err = u.completeActivityInternal(
			ctx,
			item,
			nil,
			item.EndAt,
			nil,
			"automatic_scheduler",
		); err != nil {
			return completedCount, fmt.Errorf(
				"complete due activity %s: %w",
				item.ID,
				err,
			)
		}
		completedCount++
	}

	return completedCount, nil
}

func (u *ActivityUseCase) AutoStartDueActivities(
	ctx context.Context,
	limit int,
) (int, error) {
	items, err := u.repo.ListActivitiesDueForStart(ctx, time.Now().UTC(), limit)
	if err != nil {
		return 0, fmt.Errorf("list activities due for start: %w", err)
	}

	startedCount := 0
	for _, item := range items {
		if item == nil || !isActivityAutoStartableStatus(item.Status) {
			continue
		}

		if _, err = u.startActivityInternal(
			ctx,
			item,
			nil,
			item.StartAt,
			"automatic_scheduler",
		); err != nil {
			return startedCount, fmt.Errorf("start due activity %s: %w", item.ID, err)
		}
		startedCount++
	}

	return startedCount, nil
}

func (u *ActivityUseCase) startActivityInternal(
	ctx context.Context,
	item *model.Activity,
	actorUserID *uuid.UUID,
	startedAt time.Time,
	trigger string,
) (*model.Activity, error) {
	startedAt = startedAt.UTC()
	now := time.Now().UTC()

	item.Status = enum.ActivityStatusStarted
	item.StartedAt = &startedAt
	item.Revision++
	item.UpdatedAt = now

	if err := u.repo.UpdateActivity(ctx, item); err != nil {
		return nil, fmt.Errorf("start activity: %w", err)
	}

	event, eventErr := model.NewActivityEvent(model.NewActivityEventParams{
		ActivityID:  item.ID,
		EventType:   enum.ActivityEventTypeStarted,
		ActorUserID: actorUserID,
		PayloadJSON: mustJSON(map[string]any{
			"startedAt": startedAt.Format(time.RFC3339),
			"trigger":   trigger,
		}),
	})
	if eventErr == nil {
		_ = u.repo.CreateActivityEvent(ctx, event)
	}

	u.syncActivityChat(ctx, item)

	return item, nil
}

func (u *ActivityUseCase) completeActivityInternal(
	ctx context.Context,
	item *model.Activity,
	actorUserID *uuid.UUID,
	completedAt time.Time,
	reason *string,
	trigger string,
) (*model.Activity, error) {
	completedAt = completedAt.UTC()
	now := time.Now().UTC()

	item.Status = enum.ActivityStatusCompleted
	item.CompletedAt = &completedAt
	item.CompletionReason = model.NormalizeOptionalString(reason)
	if item.StartedAt == nil && !completedAt.Before(item.StartAt) {
		startedAt := item.StartAt.UTC()
		item.StartedAt = &startedAt
	}
	item.Revision++
	item.UpdatedAt = now

	if err := u.repo.UpdateActivity(ctx, item); err != nil {
		return nil, fmt.Errorf("complete activity: %w", err)
	}

	event, eventErr := model.NewActivityEvent(model.NewActivityEventParams{
		ActivityID:  item.ID,
		EventType:   enum.ActivityEventTypeCompleted,
		ActorUserID: actorUserID,
		PayloadJSON: mustJSON(map[string]any{
			"completedAt":    completedAt.Format(time.RFC3339),
			"completedEarly": completedAt.Before(item.EndAt),
			"reason":         item.CompletionReason,
			"trigger":        trigger,
		}),
	})
	if eventErr == nil {
		_ = u.repo.CreateActivityEvent(ctx, event)
	}

	u.syncActivityChat(ctx, item)

	return item, nil
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

	u.syncActivityChat(ctx, item)

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
	return u.startActivityInternal(ctx, item, &actorUserID, now, "manual")
}

func (u *ActivityUseCase) CompleteActivity(
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
	if item.Status == enum.ActivityStatusCompleted {
		return nil, ErrActivityAlreadyCompleted
	}
	if !isActivityManuallyCompletableStatus(item.Status) {
		return nil, ErrActivityNotCompletable
	}

	now := time.Now().UTC()
	if now.Before(item.StartAt) {
		return nil, ErrActivityNotCompletable
	}

	if now.Before(item.EndAt) {
		totalDuration := item.EndAt.Sub(item.StartAt)
		if totalDuration <= 0 {
			return nil, ErrActivityNotCompletable
		}

		remaining := item.EndAt.Sub(now)
		if remaining > totalDuration/2 {
			return nil, ErrActivityShouldBeCancelledInstead
		}
		if remaining > totalDuration/4 {
			return nil, ErrActivityTooEarlyToComplete
		}

		reason = strings.TrimSpace(reason)
		if reason == "" {
			return nil, ErrActivityCompletionReasonRequired
		}

		return u.completeActivityInternal(
			ctx,
			item,
			&actorUserID,
			now,
			&reason,
			"manual_early",
		)
	}

	return u.completeActivityInternal(
		ctx,
		item,
		&actorUserID,
		item.EndAt,
		nil,
		"manual_after_end",
	)
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
	item.CompletedAt = nil
	item.CompletionReason = nil
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

	u.syncActivityChat(ctx, item)

	return item, nil
}

func (u *ActivityUseCase) ExtendActivity(
	ctx context.Context,
	activityID uuid.UUID,
	actorUserID uuid.UUID,
	minutes int,
) (*model.Activity, error) {
	item, err := u.GetActivityByID(ctx, activityID)
	if err != nil {
		return nil, err
	}
	if actorUserID == uuid.Nil || actorUserID != item.HostUserID {
		return nil, ErrInvalidActorUserID
	}
	if minutes != 30 && minutes != 60 {
		return nil, ErrActivityExtendDurationInvalid
	}
	if !isActivityExtendableStatus(item.Status) {
		return nil, ErrActivityNotExtendable
	}

	now := time.Now().UTC()
	if now.Before(item.StartAt) {
		return nil, ErrActivityNotExtendable
	}
	if !now.Before(item.EndAt) {
		return nil, ErrActivityNotExtendable
	}

	previousEndAt := item.EndAt
	item.EndAt = item.EndAt.Add(time.Duration(minutes) * time.Minute).UTC()
	item.Revision++
	item.UpdatedAt = now

	if err = u.repo.UpdateActivity(ctx, item); err != nil {
		return nil, fmt.Errorf("extend activity: %w", err)
	}

	event, eventErr := model.NewActivityEvent(model.NewActivityEventParams{
		ActivityID:  item.ID,
		EventType:   enum.ActivityEventTypeExtended,
		ActorUserID: &actorUserID,
		PayloadJSON: mustJSON(map[string]any{
			"minutes":       minutes,
			"previousEndAt": previousEndAt.Format(time.RFC3339),
			"newEndAt":      item.EndAt.Format(time.RFC3339),
		}),
	})
	if eventErr == nil {
		_ = u.repo.CreateActivityEvent(ctx, event)
	}

	u.syncActivityChat(ctx, item)

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

	if err = u.validateUpdateRules(
		ctx,
		item,
		beforePriceType,
		beforePriceAmount,
		beforeCurrency,
		beforeLocationSnapshot,
		input.StartAt != nil,
		input.EndAt != nil,
	); err != nil {
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

	u.syncActivityChat(ctx, item)

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
	endAtChanged bool,
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
	skipDurationCheck := !startAtChanged && !endAtChanged
	if err := item.Validate(now, skipStartTimeCheck, skipDurationCheck); err != nil {
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
		participants, err := u.repo.ListParticipantsByActivityID(ctx, item.ID, 1000, 0)
		if err == nil && hasOtherPriceBlockingParticipants(participants, item.HostUserID) {
			return ErrPriceChangeForbidden
		}
	}

	return nil
}

func hasOtherPriceBlockingParticipants(
	participants []*model.ActivityParticipant,
	hostUserID uuid.UUID,
) bool {
	for _, participant := range participants {
		if participant == nil || participant.UserID == hostUserID {
			continue
		}

		switch participant.Status {
		case enum.ParticipantStatusCancelled,
			enum.ParticipantStatusDeclined,
			enum.ParticipantStatusExpired:
			continue
		default:
			return true
		}
	}

	return false
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

	return u.normalizeLifecycleList(ctx, items)
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

	return u.normalizeLifecycleList(ctx, items)
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
