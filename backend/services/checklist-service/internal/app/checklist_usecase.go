package app

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"

	"kz/inflap/backend/services/checklist-service/internal/domain/model"
)

type ChecklistUseCase struct {
	repo               ChecklistRepository
	notificationSender ChecklistNotificationSender
	now                func() time.Time
}

var (
	ErrChecklistUserRequired        = errors.New("checklist user id is required")
	ErrChecklistTripRequired        = errors.New("checklist trip id is required")
	ErrChecklistNotFound            = errors.New("checklist instance not found")
	ErrChecklistItemNotFound        = errors.New("checklist item not found")
	ErrInvalidChecklistItemStatus   = errors.New("invalid checklist item status")
	ErrInvalidChecklistFeedback     = errors.New("invalid checklist item feedback")
	ErrChecklistAssignmentForbidden = errors.New("checklist item assignment is forbidden")
	ErrInvalidCustomChecklistItem   = errors.New("invalid custom checklist item")
	ErrCustomChecklistItemNotFound  = errors.New("custom checklist item not found")
	ErrChecklistPersistenceFailed   = errors.New("checklist persistence failed")
	ErrChecklistPersistenceMissing  = errors.New("checklist persistence repository is missing")
)

const (
	checklistFeedbackCommentMaxLength = 500
	customChecklistTitleMaxRunes      = 120
	customChecklistNoteMaxRunes       = 500
)

var checklistReminderOffsets = []int{30, 14, 7, 2, 1}

type ChecklistUseCaseOption func(*ChecklistUseCase)

func WithChecklistNotificationSender(sender ChecklistNotificationSender) ChecklistUseCaseOption {
	return func(uc *ChecklistUseCase) {
		uc.notificationSender = sender
	}
}

func WithChecklistClock(now func() time.Time) ChecklistUseCaseOption {
	return func(uc *ChecklistUseCase) {
		if now != nil {
			uc.now = now
		}
	}
}

func NewChecklistUseCase(repo ChecklistRepository, opts ...ChecklistUseCaseOption) *ChecklistUseCase {
	uc := &ChecklistUseCase{
		repo: repo,
		now:  time.Now,
	}
	for _, opt := range opts {
		if opt != nil {
			opt(uc)
		}
	}
	return uc
}

type GenerateTripChecklistInput struct {
	UserID          string
	TripID          string
	Destination     model.TripDestination
	StartAt         time.Time
	EndAt           time.Time
	TransportModes  []model.TransportMode
	ActivitySlugs   []string
	TravelerProfile model.TravelerProfile
}

type SearchCarryItemsInput struct {
	Query         string
	TransportMode model.TransportMode
	PreferredLang string
	Limit         int
}

type UpdateChecklistItemStatusInput struct {
	UserID string
	TripID string
	ItemID string
	Status model.ChecklistItemStatus
}

type SubmitChecklistItemFeedbackInput struct {
	UserID       string
	TripID       string
	ItemID       string
	FeedbackType model.ChecklistFeedbackType
	Comment      string
}

type SetChecklistItemAssignmentInput struct {
	UserID     string
	TripID     string
	ItemID     string
	AssignToMe bool
}

type CreateCustomChecklistItemInput struct {
	UserID        string
	TripID        string
	Title         string
	Note          string
	Category      model.ChecklistCategory
	Priority      model.ChecklistPriority
	ReuseInFuture bool
}

type UpdateCustomChecklistItemInput struct {
	UserID        string
	TripID        string
	ItemID        string
	Title         string
	Note          string
	Category      model.ChecklistCategory
	Priority      model.ChecklistPriority
	ReuseInFuture bool
}

type UpdateCustomChecklistItemStatusInput struct {
	UserID string
	TripID string
	ItemID string
	Status model.ChecklistItemStatus
}

type SetCustomChecklistItemAssignmentInput struct {
	UserID     string
	TripID     string
	ItemID     string
	AssignToMe bool
}

type DeleteCustomChecklistItemInput struct {
	UserID string
	TripID string
	ItemID string
}

type ListPersonalChecklistTemplatesInput struct {
	UserID     string
	ActiveOnly bool
}

type ApplyPersonalChecklistTemplatesInput struct {
	UserID      string
	TripID      string
	TemplateIDs []string
}

type ListTripChecklistRemindersInput struct {
	UserID string
	TripID string
}

type ListTripChecklistsInput struct {
	UserID string
	Limit  int
}

type ListChecklistItemFeedbackInput struct {
	FeedbackType model.ChecklistFeedbackType
	Limit        int
}

type DispatchChecklistNotificationsInput struct {
	Limit             int
	PreferredLanguage string
}

type DispatchChecklistNotificationsResult struct {
	Scanned int
	Sent    int
	Skipped int
}

type ChecklistNotificationRequest struct {
	IdempotencyKey  string
	RecipientUserID string
	Category        string
	Priority        string
	Title           string
	Body            string
	DeepLink        string
	Data            map[string]string
	CollapseKey     string
	TTL             time.Duration
}

type ChecklistNotificationSender interface {
	SendChecklistNotification(ctx context.Context, request ChecklistNotificationRequest) error
}

type CarryItemMatch struct {
	ItemSlug             string              `json:"itemSlug"`
	CarryOn              model.CarryPolicy   `json:"carryOn"`
	CheckedBaggage       model.CarryPolicy   `json:"checkedBaggage"`
	RequiresAirlineCheck bool                `json:"requiresAirlineCheck"`
	ConditionSummary     model.LocalizedText `json:"conditionSummary"`
	Source               model.Source        `json:"source"`
}

func (uc *ChecklistUseCase) GenerateTripChecklist(input GenerateTripChecklistInput) (model.TripChecklist, error) {
	month := input.StartAt.Month()
	seasonalProfile := uc.matchSeasonalProfile(input.Destination, month)
	items := make([]model.ChecklistItem, 0, len(uc.repo.Templates()))

	for _, template := range uc.repo.Templates() {
		if !matchesCondition(template.AppliesTo, input, month) {
			continue
		}
		items = append(items, itemFromTemplate(template))
	}

	sort.SliceStable(items, func(i, j int) bool {
		if items[i].Priority != items[j].Priority {
			return priorityWeight(items[i].Priority) > priorityWeight(items[j].Priority)
		}
		if items[i].Category != items[j].Category {
			return items[i].Category < items[j].Category
		}
		return items[i].ID < items[j].ID
	})

	readiness := uc.CalculateReadiness(items, uc.now())

	return model.TripChecklist{
		UserID:          strings.TrimSpace(input.UserID),
		TripID:          strings.TrimSpace(input.TripID),
		Destination:     input.Destination,
		StartAt:         input.StartAt.UTC(),
		EndAt:           input.EndAt.UTC(),
		TransportModes:  normalizedTransportModes(input.TransportModes),
		ActivitySlugs:   normalizedStringTokens(input.ActivitySlugs),
		TravelerProfile: input.TravelerProfile,
		Items:           items,
		Readiness:       readiness,
		SeasonalProfile: seasonalProfile,
		TrustNotice:     trustNoticeForItems(items),
		GeneratedAt:     uc.now().UTC(),
	}, nil
}

func (uc *ChecklistUseCase) GetOrCreateTripChecklist(
	ctx context.Context,
	input GenerateTripChecklistInput,
) (model.TripChecklist, error) {
	userID := strings.TrimSpace(input.UserID)
	if userID == "" {
		return model.TripChecklist{}, ErrChecklistUserRequired
	}
	tripID := strings.TrimSpace(input.TripID)
	if tripID == "" {
		return model.TripChecklist{}, ErrChecklistTripRequired
	}

	existing, ok, err := uc.repo.FindTripChecklistInstance(ctx, userID, tripID)
	if err != nil {
		return model.TripChecklist{}, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
	}
	if ok {
		return uc.attachCustomItems(ctx, existing)
	}

	input.UserID = userID
	input.TripID = tripID
	checklist, err := uc.GenerateTripChecklist(input)
	if err != nil {
		return model.TripChecklist{}, err
	}
	now := uc.now().UTC()
	checklist.InstanceID = newChecklistInstanceID(now)
	checklist.UserID = userID
	checklist.UpdatedAt = now

	if err = uc.repo.SaveTripChecklistInstance(ctx, checklist); err != nil {
		return model.TripChecklist{}, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
	}

	return uc.attachCustomItems(ctx, checklist)
}

func (uc *ChecklistUseCase) ListTripChecklists(
	ctx context.Context,
	input ListTripChecklistsInput,
) ([]model.TripChecklist, error) {
	userID := strings.TrimSpace(input.UserID)
	if userID == "" {
		return nil, ErrChecklistUserRequired
	}
	limit := input.Limit
	if limit <= 0 {
		limit = 50
	}
	if limit > 100 {
		limit = 100
	}

	checklists, err := uc.repo.ListTripChecklistInstancesByUser(ctx, userID, limit)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
	}
	for i := range checklists {
		checklist, attachErr := uc.attachCustomItems(ctx, checklists[i])
		if attachErr != nil {
			return nil, attachErr
		}
		checklists[i] = checklist
	}
	return checklists, nil
}

func (uc *ChecklistUseCase) UpdateChecklistItemStatus(
	ctx context.Context,
	input UpdateChecklistItemStatusInput,
) (model.TripChecklist, error) {
	userID := strings.TrimSpace(input.UserID)
	if userID == "" {
		return model.TripChecklist{}, ErrChecklistUserRequired
	}
	tripID := strings.TrimSpace(input.TripID)
	if tripID == "" {
		return model.TripChecklist{}, ErrChecklistTripRequired
	}
	itemID := strings.TrimSpace(input.ItemID)
	if itemID == "" {
		return model.TripChecklist{}, ErrChecklistItemNotFound
	}
	if !isValidChecklistItemStatus(input.Status) {
		return model.TripChecklist{}, ErrInvalidChecklistItemStatus
	}

	checklist, ok, err := uc.repo.FindTripChecklistInstance(ctx, userID, tripID)
	if err != nil {
		return model.TripChecklist{}, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
	}
	if !ok {
		return model.TripChecklist{}, ErrChecklistNotFound
	}

	found := false
	for i := range checklist.Items {
		if checklist.Items[i].ID != itemID {
			continue
		}
		checklist.Items[i].Status = input.Status
		found = true
		break
	}
	if !found {
		return model.TripChecklist{}, ErrChecklistItemNotFound
	}

	checklist.Readiness = uc.CalculateReadiness(checklist.Items, uc.now())
	checklist.UpdatedAt = uc.now().UTC()

	if err = uc.repo.SaveTripChecklistInstance(ctx, checklist); err != nil {
		return model.TripChecklist{}, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
	}

	return uc.attachCustomItems(ctx, checklist)
}

func (uc *ChecklistUseCase) SubmitChecklistItemFeedback(
	ctx context.Context,
	input SubmitChecklistItemFeedbackInput,
) (model.ChecklistItemFeedback, error) {
	userID := strings.TrimSpace(input.UserID)
	if userID == "" {
		return model.ChecklistItemFeedback{}, ErrChecklistUserRequired
	}
	tripID := strings.TrimSpace(input.TripID)
	if tripID == "" {
		return model.ChecklistItemFeedback{}, ErrChecklistTripRequired
	}
	itemID := strings.TrimSpace(input.ItemID)
	if itemID == "" {
		return model.ChecklistItemFeedback{}, ErrChecklistItemNotFound
	}
	if !isValidChecklistFeedbackType(input.FeedbackType) {
		return model.ChecklistItemFeedback{}, ErrInvalidChecklistFeedback
	}
	comment := strings.TrimSpace(input.Comment)
	if len(comment) > checklistFeedbackCommentMaxLength {
		return model.ChecklistItemFeedback{}, ErrInvalidChecklistFeedback
	}

	checklist, ok, err := uc.repo.FindTripChecklistInstance(ctx, userID, tripID)
	if err != nil {
		return model.ChecklistItemFeedback{}, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
	}
	if !ok {
		return model.ChecklistItemFeedback{}, ErrChecklistNotFound
	}

	if !checklistHasItem(checklist.Items, itemID) {
		return model.ChecklistItemFeedback{}, ErrChecklistItemNotFound
	}

	now := uc.now().UTC()
	feedback := model.ChecklistItemFeedback{
		ID:                  newChecklistFeedbackID(now),
		ChecklistInstanceID: checklist.InstanceID,
		UserID:              userID,
		TripID:              tripID,
		ItemID:              itemID,
		FeedbackType:        input.FeedbackType,
		Comment:             comment,
		CreatedAt:           now,
	}
	if err = uc.repo.SaveChecklistItemFeedback(ctx, feedback); err != nil {
		return model.ChecklistItemFeedback{}, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
	}

	return feedback, nil
}

func (uc *ChecklistUseCase) SetChecklistItemAssignment(
	ctx context.Context,
	input SetChecklistItemAssignmentInput,
) (model.TripChecklist, error) {
	userID := strings.TrimSpace(input.UserID)
	if userID == "" {
		return model.TripChecklist{}, ErrChecklistUserRequired
	}
	tripID := strings.TrimSpace(input.TripID)
	if tripID == "" {
		return model.TripChecklist{}, ErrChecklistTripRequired
	}
	itemID := strings.TrimSpace(input.ItemID)
	if itemID == "" {
		return model.TripChecklist{}, ErrChecklistItemNotFound
	}

	checklist, ok, err := uc.repo.FindTripChecklistInstance(ctx, userID, tripID)
	if err != nil {
		return model.TripChecklist{}, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
	}
	if !ok {
		return model.TripChecklist{}, ErrChecklistNotFound
	}

	found := false
	for i := range checklist.Items {
		if checklist.Items[i].ID != itemID {
			continue
		}
		found = true
		if input.AssignToMe {
			checklist.Items[i].AssignedUserID = userID
			break
		}
		if checklist.Items[i].AssignedUserID != "" && checklist.Items[i].AssignedUserID != userID {
			return model.TripChecklist{}, ErrChecklistAssignmentForbidden
		}
		checklist.Items[i].AssignedUserID = ""
		break
	}
	if !found {
		return model.TripChecklist{}, ErrChecklistItemNotFound
	}

	checklist.UpdatedAt = uc.now().UTC()
	if err = uc.repo.SaveTripChecklistInstance(ctx, checklist); err != nil {
		return model.TripChecklist{}, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
	}

	return uc.attachCustomItems(ctx, checklist)
}

func (uc *ChecklistUseCase) CreateCustomChecklistItem(
	ctx context.Context,
	input CreateCustomChecklistItemInput,
) (model.TripChecklist, error) {
	userID, tripID, err := validateChecklistOwnerScope(input.UserID, input.TripID)
	if err != nil {
		return model.TripChecklist{}, err
	}
	title, note, category, priority, err := validateCustomChecklistItemFields(
		input.Title,
		input.Note,
		input.Category,
		input.Priority,
	)
	if err != nil {
		return model.TripChecklist{}, err
	}

	checklist, ok, err := uc.repo.FindTripChecklistInstance(ctx, userID, tripID)
	if err != nil {
		return model.TripChecklist{}, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
	}
	if !ok {
		return model.TripChecklist{}, ErrChecklistNotFound
	}

	now := uc.now().UTC()
	item := model.CustomChecklistItem{
		ID:                  newCustomChecklistItemID(now),
		ChecklistInstanceID: checklist.InstanceID,
		UserID:              userID,
		TripID:              tripID,
		Title:               title,
		Note:                note,
		Category:            category,
		Priority:            priority,
		Status:              model.ChecklistItemOpen,
		ReuseInFuture:       input.ReuseInFuture,
		CreatedAt:           now,
		UpdatedAt:           now,
	}
	if input.ReuseInFuture {
		template := newPersonalChecklistTemplate(userID, title, note, category, priority, now)
		if err = uc.repo.SavePersonalChecklistTemplate(ctx, template); err != nil {
			return model.TripChecklist{}, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
		}
		item.PersonalTemplateID = template.ID
	}

	if err = uc.repo.SaveCustomChecklistItem(ctx, item); err != nil {
		return model.TripChecklist{}, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
	}

	return uc.reloadTripChecklistWithCustomItems(ctx, userID, tripID)
}

func (uc *ChecklistUseCase) UpdateCustomChecklistItem(
	ctx context.Context,
	input UpdateCustomChecklistItemInput,
) (model.TripChecklist, error) {
	userID, tripID, err := validateChecklistOwnerScope(input.UserID, input.TripID)
	if err != nil {
		return model.TripChecklist{}, err
	}
	itemID := strings.TrimSpace(input.ItemID)
	if itemID == "" {
		return model.TripChecklist{}, ErrCustomChecklistItemNotFound
	}
	title, note, category, priority, err := validateCustomChecklistItemFields(
		input.Title,
		input.Note,
		input.Category,
		input.Priority,
	)
	if err != nil {
		return model.TripChecklist{}, err
	}

	item, ok, err := uc.repo.FindCustomChecklistItem(ctx, userID, tripID, itemID)
	if err != nil {
		return model.TripChecklist{}, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
	}
	if !ok {
		return model.TripChecklist{}, ErrCustomChecklistItemNotFound
	}

	now := uc.now().UTC()
	if input.ReuseInFuture {
		template := model.PersonalChecklistTemplate{
			ID:        strings.TrimSpace(item.PersonalTemplateID),
			UserID:    userID,
			Title:     title,
			Note:      note,
			Category:  category,
			Priority:  priority,
			IsActive:  true,
			CreatedAt: now,
			UpdatedAt: now,
		}
		if template.ID == "" {
			template.ID = newPersonalChecklistTemplateID(now)
		}
		if item.PersonalTemplateID != "" && !item.CreatedAt.IsZero() {
			template.CreatedAt = item.CreatedAt
		}
		if err = uc.repo.SavePersonalChecklistTemplate(ctx, template); err != nil {
			return model.TripChecklist{}, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
		}
		item.PersonalTemplateID = template.ID
	} else if item.PersonalTemplateID != "" {
		template := model.PersonalChecklistTemplate{
			ID:        item.PersonalTemplateID,
			UserID:    userID,
			Title:     title,
			Note:      note,
			Category:  category,
			Priority:  priority,
			IsActive:  false,
			CreatedAt: now,
			UpdatedAt: now,
		}
		if err = uc.repo.SavePersonalChecklistTemplate(ctx, template); err != nil {
			return model.TripChecklist{}, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
		}
		item.PersonalTemplateID = ""
	}

	item.Title = title
	item.Note = note
	item.Category = category
	item.Priority = priority
	item.ReuseInFuture = input.ReuseInFuture
	item.UpdatedAt = now
	if err = uc.repo.SaveCustomChecklistItem(ctx, item); err != nil {
		return model.TripChecklist{}, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
	}

	return uc.reloadTripChecklistWithCustomItems(ctx, userID, tripID)
}

func (uc *ChecklistUseCase) UpdateCustomChecklistItemStatus(
	ctx context.Context,
	input UpdateCustomChecklistItemStatusInput,
) (model.TripChecklist, error) {
	userID, tripID, err := validateChecklistOwnerScope(input.UserID, input.TripID)
	if err != nil {
		return model.TripChecklist{}, err
	}
	itemID := strings.TrimSpace(input.ItemID)
	if itemID == "" {
		return model.TripChecklist{}, ErrCustomChecklistItemNotFound
	}
	if !isValidChecklistItemStatus(input.Status) {
		return model.TripChecklist{}, ErrInvalidCustomChecklistItem
	}

	item, ok, err := uc.repo.FindCustomChecklistItem(ctx, userID, tripID, itemID)
	if err != nil {
		return model.TripChecklist{}, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
	}
	if !ok {
		return model.TripChecklist{}, ErrCustomChecklistItemNotFound
	}
	item.Status = input.Status
	item.UpdatedAt = uc.now().UTC()
	if err = uc.repo.SaveCustomChecklistItem(ctx, item); err != nil {
		return model.TripChecklist{}, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
	}

	return uc.reloadTripChecklistWithCustomItems(ctx, userID, tripID)
}

func (uc *ChecklistUseCase) SetCustomChecklistItemAssignment(
	ctx context.Context,
	input SetCustomChecklistItemAssignmentInput,
) (model.TripChecklist, error) {
	userID, tripID, err := validateChecklistOwnerScope(input.UserID, input.TripID)
	if err != nil {
		return model.TripChecklist{}, err
	}
	itemID := strings.TrimSpace(input.ItemID)
	if itemID == "" {
		return model.TripChecklist{}, ErrCustomChecklistItemNotFound
	}

	item, ok, err := uc.repo.FindCustomChecklistItem(ctx, userID, tripID, itemID)
	if err != nil {
		return model.TripChecklist{}, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
	}
	if !ok {
		return model.TripChecklist{}, ErrCustomChecklistItemNotFound
	}
	if input.AssignToMe {
		item.AssignedUserID = userID
	} else {
		if item.AssignedUserID != "" && item.AssignedUserID != userID {
			return model.TripChecklist{}, ErrChecklistAssignmentForbidden
		}
		item.AssignedUserID = ""
	}
	item.UpdatedAt = uc.now().UTC()
	if err = uc.repo.SaveCustomChecklistItem(ctx, item); err != nil {
		return model.TripChecklist{}, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
	}

	return uc.reloadTripChecklistWithCustomItems(ctx, userID, tripID)
}

func (uc *ChecklistUseCase) DeleteCustomChecklistItem(
	ctx context.Context,
	input DeleteCustomChecklistItemInput,
) (model.TripChecklist, error) {
	userID, tripID, err := validateChecklistOwnerScope(input.UserID, input.TripID)
	if err != nil {
		return model.TripChecklist{}, err
	}
	itemID := strings.TrimSpace(input.ItemID)
	if itemID == "" {
		return model.TripChecklist{}, ErrCustomChecklistItemNotFound
	}

	if _, ok, findErr := uc.repo.FindCustomChecklistItem(ctx, userID, tripID, itemID); findErr != nil {
		return model.TripChecklist{}, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, findErr)
	} else if !ok {
		return model.TripChecklist{}, ErrCustomChecklistItemNotFound
	}
	if err = uc.repo.SoftDeleteCustomChecklistItem(ctx, userID, tripID, itemID, uc.now().UTC()); err != nil {
		return model.TripChecklist{}, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
	}

	return uc.reloadTripChecklistWithCustomItems(ctx, userID, tripID)
}

func (uc *ChecklistUseCase) ListPersonalChecklistTemplates(
	ctx context.Context,
	input ListPersonalChecklistTemplatesInput,
) ([]model.PersonalChecklistTemplate, error) {
	userID := strings.TrimSpace(input.UserID)
	if userID == "" {
		return nil, ErrChecklistUserRequired
	}
	templates, err := uc.repo.ListPersonalChecklistTemplates(ctx, userID, input.ActiveOnly)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
	}
	return templates, nil
}

func (uc *ChecklistUseCase) ApplyPersonalChecklistTemplates(
	ctx context.Context,
	input ApplyPersonalChecklistTemplatesInput,
) (model.TripChecklist, error) {
	userID, tripID, err := validateChecklistOwnerScope(input.UserID, input.TripID)
	if err != nil {
		return model.TripChecklist{}, err
	}
	checklist, ok, err := uc.repo.FindTripChecklistInstance(ctx, userID, tripID)
	if err != nil {
		return model.TripChecklist{}, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
	}
	if !ok {
		return model.TripChecklist{}, ErrChecklistNotFound
	}

	templates, err := uc.repo.ListPersonalChecklistTemplates(ctx, userID, true)
	if err != nil {
		return model.TripChecklist{}, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
	}
	selected := selectedTemplateIDs(input.TemplateIDs)
	existingItems, err := uc.repo.ListCustomChecklistItems(ctx, userID, tripID)
	if err != nil {
		return model.TripChecklist{}, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
	}
	existingByTemplate := make(map[string]struct{}, len(existingItems))
	for _, item := range existingItems {
		if item.PersonalTemplateID != "" {
			existingByTemplate[item.PersonalTemplateID] = struct{}{}
		}
	}

	now := uc.now().UTC()
	for _, template := range templates {
		if len(selected) > 0 {
			if _, ok = selected[template.ID]; !ok {
				continue
			}
		}
		if _, exists := existingByTemplate[template.ID]; exists {
			continue
		}
		item := model.CustomChecklistItem{
			ID:                  newCustomChecklistItemID(now),
			ChecklistInstanceID: checklist.InstanceID,
			UserID:              userID,
			TripID:              tripID,
			Title:               template.Title,
			Note:                template.Note,
			Category:            template.Category,
			Priority:            template.Priority,
			Status:              model.ChecklistItemOpen,
			ReuseInFuture:       true,
			PersonalTemplateID:  template.ID,
			CreatedAt:           now,
			UpdatedAt:           now,
		}
		if err = uc.repo.SaveCustomChecklistItem(ctx, item); err != nil {
			return model.TripChecklist{}, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
		}
		existingByTemplate[template.ID] = struct{}{}
	}

	return uc.reloadTripChecklistWithCustomItems(ctx, userID, tripID)
}

func (uc *ChecklistUseCase) ListTripChecklistReminders(
	ctx context.Context,
	input ListTripChecklistRemindersInput,
) ([]model.ChecklistReminder, error) {
	userID := strings.TrimSpace(input.UserID)
	if userID == "" {
		return nil, ErrChecklistUserRequired
	}
	tripID := strings.TrimSpace(input.TripID)
	if tripID == "" {
		return nil, ErrChecklistTripRequired
	}

	checklist, ok, err := uc.repo.FindTripChecklistInstance(ctx, userID, tripID)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
	}
	if !ok {
		return nil, ErrChecklistNotFound
	}

	return buildTripReminderSchedule(checklist.StartAt, uc.now()), nil
}

func (uc *ChecklistUseCase) ListChecklistItemFeedback(
	ctx context.Context,
	input ListChecklistItemFeedbackInput,
) ([]model.ChecklistItemFeedback, error) {
	if input.FeedbackType != "" && !isValidChecklistFeedbackType(input.FeedbackType) {
		return nil, ErrInvalidChecklistFeedback
	}
	limit := input.Limit
	if limit <= 0 || limit > 100 {
		limit = 50
	}
	entries, err := uc.repo.ListChecklistItemFeedback(ctx, input.FeedbackType, limit)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
	}
	return entries, nil
}

func (uc *ChecklistUseCase) reloadTripChecklistWithCustomItems(
	ctx context.Context,
	userID string,
	tripID string,
) (model.TripChecklist, error) {
	checklist, ok, err := uc.repo.FindTripChecklistInstance(ctx, userID, tripID)
	if err != nil {
		return model.TripChecklist{}, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
	}
	if !ok {
		return model.TripChecklist{}, ErrChecklistNotFound
	}
	return uc.attachCustomItems(ctx, checklist)
}

func (uc *ChecklistUseCase) attachCustomItems(
	ctx context.Context,
	checklist model.TripChecklist,
) (model.TripChecklist, error) {
	items, err := uc.repo.ListCustomChecklistItems(ctx, checklist.UserID, checklist.TripID)
	if err != nil {
		return model.TripChecklist{}, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
	}
	return attachCustomItems(checklist, items), nil
}

func calculatePersonalProgress(items []model.CustomChecklistItem) model.PersonalChecklistProgress {
	total := 0
	done := 0
	for _, item := range items {
		if item.DeletedAt != nil {
			continue
		}
		total++
		if item.Status == model.ChecklistItemDone || item.Status == model.ChecklistItemSkipped {
			done++
		}
	}
	percent := 0
	if total > 0 {
		percent = int(float64(done) / float64(total) * 100)
	}
	return model.PersonalChecklistProgress{Total: total, Done: done, Percent: percent}
}

func attachCustomItems(
	checklist model.TripChecklist,
	items []model.CustomChecklistItem,
) model.TripChecklist {
	checklist.CustomItems = cloneCustomChecklistItemsForUseCase(items)
	checklist.PersonalProgress = calculatePersonalProgress(items)
	return checklist
}

func cloneCustomChecklistItemsForUseCase(items []model.CustomChecklistItem) []model.CustomChecklistItem {
	cloned := make([]model.CustomChecklistItem, len(items))
	for i, item := range items {
		if item.DeletedAt != nil {
			deletedAt := *item.DeletedAt
			item.DeletedAt = &deletedAt
		}
		cloned[i] = item
	}
	return cloned
}

func validateChecklistOwnerScope(userID string, tripID string) (string, string, error) {
	userID = strings.TrimSpace(userID)
	if userID == "" {
		return "", "", ErrChecklistUserRequired
	}
	tripID = strings.TrimSpace(tripID)
	if tripID == "" {
		return "", "", ErrChecklistTripRequired
	}
	return userID, tripID, nil
}

func validateCustomChecklistItemFields(
	title string,
	note string,
	category model.ChecklistCategory,
	priority model.ChecklistPriority,
) (string, string, model.ChecklistCategory, model.ChecklistPriority, error) {
	title = strings.TrimSpace(title)
	note = strings.TrimSpace(note)
	if runeLen(title) == 0 || runeLen(title) > customChecklistTitleMaxRunes {
		return "", "", "", "", ErrInvalidCustomChecklistItem
	}
	if runeLen(note) > customChecklistNoteMaxRunes {
		return "", "", "", "", ErrInvalidCustomChecklistItem
	}
	if category == "" {
		category = model.ChecklistCategoryCustom
	}
	if priority == "" {
		priority = model.ChecklistPriorityRecommended
	}
	if !isValidChecklistCategory(category) || !isValidChecklistPriority(priority) {
		return "", "", "", "", ErrInvalidCustomChecklistItem
	}
	return title, note, category, priority, nil
}

func newPersonalChecklistTemplate(
	userID string,
	title string,
	note string,
	category model.ChecklistCategory,
	priority model.ChecklistPriority,
	now time.Time,
) model.PersonalChecklistTemplate {
	return model.PersonalChecklistTemplate{
		ID:        newPersonalChecklistTemplateID(now),
		UserID:    userID,
		Title:     title,
		Note:      note,
		Category:  category,
		Priority:  priority,
		IsActive:  true,
		CreatedAt: now,
		UpdatedAt: now,
	}
}

func selectedTemplateIDs(templateIDs []string) map[string]struct{} {
	selected := make(map[string]struct{}, len(templateIDs))
	for _, templateID := range templateIDs {
		templateID = strings.TrimSpace(templateID)
		if templateID == "" {
			continue
		}
		selected[templateID] = struct{}{}
	}
	return selected
}

func runeLen(value string) int {
	return len([]rune(value))
}

func (uc *ChecklistUseCase) CalculateReadiness(items []model.ChecklistItem, _ time.Time) model.ReadinessSummary {
	totalWeight := 0
	doneWeight := 0
	blockers := make([]model.ReadinessBlocker, 0)

	for _, item := range items {
		weight := priorityWeight(item.Priority)
		if weight <= 0 {
			continue
		}
		totalWeight += weight

		switch item.Status {
		case model.ChecklistItemDone, model.ChecklistItemSkipped:
			doneWeight += weight
		default:
			if item.Priority == model.ChecklistPriorityCritical {
				blockers = append(blockers, model.ReadinessBlocker{
					ItemID:   item.ID,
					Priority: item.Priority,
					Reason:   item.Reason,
				})
			}
		}
	}

	score := 100
	if totalWeight > 0 {
		score = int(float64(doneWeight) / float64(totalWeight) * 100)
	}
	if len(blockers) > 0 && score > 50 {
		score = 50
	}

	return model.ReadinessSummary{
		Score:    score,
		Status:   readinessStatus(score, len(blockers) > 0),
		Blockers: blockers,
	}
}

func (uc *ChecklistUseCase) SearchCarryItems(input SearchCarryItemsInput) []CarryItemMatch {
	query := normalizeText(input.Query)
	if query == "" {
		return nil
	}

	limit := input.Limit
	if limit <= 0 || limit > 20 {
		limit = 10
	}

	matches := make([]CarryItemMatch, 0)
	for _, rule := range uc.repo.CarryRules() {
		if input.TransportMode != "" && rule.TransportMode != "" && rule.TransportMode != input.TransportMode {
			continue
		}
		if !carryRuleMatches(rule, query) {
			continue
		}
		matches = append(matches, CarryItemMatch{
			ItemSlug:             rule.ItemSlug,
			CarryOn:              rule.CarryOn,
			CheckedBaggage:       rule.CheckedBaggage,
			RequiresAirlineCheck: rule.RequiresAirlineCheck,
			ConditionSummary:     rule.ConditionSummary,
			Source:               rule.Source,
		})
		if len(matches) >= limit {
			break
		}
	}

	return matches
}

func (uc *ChecklistUseCase) matchSeasonalProfile(destination model.TripDestination, month time.Month) *model.SeasonalProfile {
	countryCode := strings.ToUpper(strings.TrimSpace(destination.CountryCode))
	cityName := normalizeText(destination.CityName)

	for _, profile := range uc.repo.SeasonalProfiles() {
		if strings.ToUpper(strings.TrimSpace(profile.Destination.CountryCode)) != countryCode {
			continue
		}
		if profile.Month != month {
			continue
		}
		if normalizeText(profile.Destination.CityName) != "" && normalizeText(profile.Destination.CityName) != cityName {
			continue
		}
		matched := profile
		return &matched
	}

	return nil
}

func matchesCondition(condition model.RuleCondition, input GenerateTripChecklistInput, month time.Month) bool {
	if condition.Always {
		return true
	}
	if condition.CountryCode != "" && strings.ToUpper(condition.CountryCode) != strings.ToUpper(input.Destination.CountryCode) {
		return false
	}
	if condition.CityName != "" && normalizeText(condition.CityName) != normalizeText(input.Destination.CityName) {
		return false
	}
	if condition.Month != 0 && condition.Month != month {
		return false
	}
	if condition.TravelerHasChildren && !input.TravelerProfile.HasChildren {
		return false
	}
	if condition.TransportMode != "" && !containsTransportMode(input.TransportModes, condition.TransportMode) {
		return false
	}
	if condition.ActivitySlug != "" && !containsNormalized(input.ActivitySlugs, condition.ActivitySlug) {
		return false
	}
	return true
}

func itemFromTemplate(template model.ChecklistTemplate) model.ChecklistItem {
	return model.ChecklistItem{
		ID:                       template.ID,
		Category:                 template.Category,
		Priority:                 template.Priority,
		Status:                   model.ChecklistItemOpen,
		Title:                    template.Title,
		Reason:                   template.Reason,
		TrustLevel:               template.TrustLevel,
		Source:                   template.Source,
		RequiresUserConfirmation: template.RequiresUserConfirmation,
	}
}

func readinessStatus(score int, hasCriticalBlockers bool) model.ReadinessStatus {
	if hasCriticalBlockers {
		return model.ReadinessStatusNotReady
	}
	switch {
	case score >= 95:
		return model.ReadinessStatusReady
	case score >= 85:
		return model.ReadinessStatusAlmostReady
	case score >= 65:
		return model.ReadinessStatusOnTrack
	default:
		return model.ReadinessStatusAtRisk
	}
}

func priorityWeight(priority model.ChecklistPriority) int {
	switch priority {
	case model.ChecklistPriorityCritical:
		return 40
	case model.ChecklistPriorityEssential:
		return 25
	case model.ChecklistPriorityImportant:
		return 15
	case model.ChecklistPriorityRecommended:
		return 8
	default:
		return 0
	}
}

func trustNoticeForItems(items []model.ChecklistItem) model.TrustNotice {
	for _, item := range items {
		if item.TrustLevel == model.TrustLevelOfficialLinkRequired {
			return model.TrustNotice{
				Code: "official_source_required",
				Title: model.LocalizedText{
					EN: "Official check required",
					RU: "Нужна проверка по официальному источнику",
					KK: "Ресми дереккөзден тексеру қажет",
				},
				Message: model.LocalizedText{
					EN: "Inflap helps you prepare, but entry, health, customs, and document requirements must be confirmed with official authorities.",
					RU: "Inflap помогает подготовиться, но требования въезда, медицины, таможни и документов нужно подтвердить по официальным источникам.",
					KK: "Inflap дайындалуға көмектеседі, бірақ кіру, медицина, кеден және құжат талаптарын ресми дереккөзден нақтылаңыз.",
				},
			}
		}
	}
	return model.TrustNotice{
		Code: "verified_curated",
		Title: model.LocalizedText{
			EN: "Curated guidance",
			RU: "Проверенные рекомендации",
			KK: "Тексерілген кеңестер",
		},
		Message: model.LocalizedText{
			EN: "This checklist uses curated no-paid travel preparation rules.",
			RU: "Этот чек-лист использует проверенные no-paid правила подготовки.",
			KK: "Бұл чек-лист тексерілген no-paid дайындық ережелерін қолданады.",
		},
	}
}

func carryRuleMatches(rule model.CarryRule, query string) bool {
	query = normalizeSearchText(query)
	queryCompact := compactSearchText(query)
	for _, alias := range rule.Aliases {
		if searchTextMatches(query, queryCompact, alias) {
			return true
		}
	}
	return searchTextMatches(query, queryCompact, rule.ItemSlug)
}

func searchTextMatches(query string, queryCompact string, candidate string) bool {
	candidate = normalizeSearchText(candidate)
	if candidate == "" {
		return false
	}
	candidateCompact := compactSearchText(candidate)
	if strings.Contains(query, candidate) || strings.Contains(candidate, query) {
		return len(query) >= 4 || query == candidate
	}
	if strings.Contains(queryCompact, candidateCompact) || strings.Contains(candidateCompact, queryCompact) {
		return len(queryCompact) >= 4 || queryCompact == candidateCompact
	}
	for _, token := range strings.Fields(candidate) {
		if len(query) >= 4 && strings.HasPrefix(token, query) {
			return true
		}
	}
	return false
}

func containsTransportMode(values []model.TransportMode, target model.TransportMode) bool {
	for _, value := range values {
		if value == target {
			return true
		}
	}
	return false
}

func normalizedTransportModes(values []model.TransportMode) []model.TransportMode {
	normalized := make([]model.TransportMode, 0, len(values))
	seen := make(map[model.TransportMode]struct{}, len(values))
	for _, value := range values {
		mode := model.TransportMode(strings.ToLower(strings.TrimSpace(string(value))))
		if mode == "" {
			continue
		}
		if _, ok := seen[mode]; ok {
			continue
		}
		seen[mode] = struct{}{}
		normalized = append(normalized, mode)
	}
	return normalized
}

func normalizedStringTokens(values []string) []string {
	normalized := make([]string, 0, len(values))
	seen := make(map[string]struct{}, len(values))
	for _, value := range values {
		token := normalizeText(value)
		if token == "" {
			continue
		}
		if _, ok := seen[token]; ok {
			continue
		}
		seen[token] = struct{}{}
		normalized = append(normalized, token)
	}
	return normalized
}

func containsNormalized(values []string, target string) bool {
	target = normalizeText(target)
	for _, value := range values {
		if normalizeText(value) == target {
			return true
		}
	}
	return false
}

func normalizeText(value string) string {
	return strings.ToLower(strings.TrimSpace(value))
}

func normalizeSearchText(value string) string {
	value = strings.ToLower(strings.TrimSpace(value))
	replacer := strings.NewReplacer(
		"_", " ",
		"-", " ",
		"ё", "е",
	)
	value = replacer.Replace(value)
	return strings.Join(strings.Fields(value), " ")
}

func compactSearchText(value string) string {
	value = normalizeSearchText(value)
	return strings.ReplaceAll(value, " ", "")
}

func isValidChecklistItemStatus(status model.ChecklistItemStatus) bool {
	switch status {
	case model.ChecklistItemOpen, model.ChecklistItemDone, model.ChecklistItemSkipped:
		return true
	default:
		return false
	}
}

func isValidChecklistCategory(category model.ChecklistCategory) bool {
	switch category {
	case model.ChecklistCategoryDocuments,
		model.ChecklistCategoryBaggage,
		model.ChecklistCategoryWeather,
		model.ChecklistCategoryActivity,
		model.ChecklistCategoryHealth,
		model.ChecklistCategorySafety,
		model.ChecklistCategoryMoney,
		model.ChecklistCategoryCustom:
		return true
	default:
		return false
	}
}

func isValidChecklistPriority(priority model.ChecklistPriority) bool {
	switch priority {
	case model.ChecklistPriorityCritical,
		model.ChecklistPriorityEssential,
		model.ChecklistPriorityImportant,
		model.ChecklistPriorityRecommended,
		model.ChecklistPriorityOptional:
		return true
	default:
		return false
	}
}

func isValidChecklistFeedbackType(feedbackType model.ChecklistFeedbackType) bool {
	switch feedbackType {
	case model.ChecklistFeedbackHelpful, model.ChecklistFeedbackNotHelpful, model.ChecklistFeedbackAddNextTime:
		return true
	default:
		return false
	}
}

func checklistHasItem(items []model.ChecklistItem, itemID string) bool {
	for _, item := range items {
		if item.ID == itemID {
			return true
		}
	}
	return false
}

func buildTripReminderSchedule(startAt time.Time, now time.Time) []model.ChecklistReminder {
	if startAt.IsZero() {
		startAt = now
	}
	reminders := make([]model.ChecklistReminder, 0, len(checklistReminderOffsets))
	for _, offset := range checklistReminderOffsets {
		dueAt := startAt.AddDate(0, 0, -offset)
		reminders = append(reminders, model.ChecklistReminder{
			ID:         fmt.Sprintf("trip-%d-days-before", offset),
			OffsetDays: offset,
			DueAt:      dueAt,
			Status:     reminderStatus(dueAt, now),
			Title:      reminderTitle(offset),
			Message:    reminderMessage(offset),
		})
	}
	return reminders
}

func reminderStatus(dueAt time.Time, now time.Time) model.ChecklistReminderStatus {
	if dueAt.After(now) {
		return model.ChecklistReminderScheduled
	}
	if dueAt.Year() == now.Year() && dueAt.YearDay() == now.YearDay() {
		return model.ChecklistReminderDue
	}
	return model.ChecklistReminderOverdue
}

func reminderTitle(offsetDays int) model.LocalizedText {
	switch offsetDays {
	case 30:
		return model.LocalizedText{EN: "Document check", RU: "Проверка документов", KK: "Құжаттарды тексеру"}
	case 14:
		return model.LocalizedText{EN: "Buy essentials", RU: "Купить нужное", KK: "Қажетті заттарды алу"}
	case 7:
		return model.LocalizedText{EN: "Baggage rules", RU: "Правила багажа", KK: "Багаж ережелері"}
	case 2:
		return model.LocalizedText{EN: "Pack critical items", RU: "Собрать важное", KK: "Маңызды заттарды жинау"}
	default:
		return model.LocalizedText{EN: "Final check", RU: "Финальная проверка", KK: "Соңғы тексеріс"}
	}
}

func reminderMessage(offsetDays int) model.LocalizedText {
	switch offsetDays {
	case 30:
		return model.LocalizedText{
			EN: "Confirm passport, visa or entry self-checks, insurance, and booking documents.",
			RU: "Проверьте паспорт, визу или требования въезда, страховку и документы бронирования.",
			KK: "Паспорт, виза немесе кіру талаптары, сақтандыру және брондау құжаттарын тексеріңіз.",
		}
	case 14:
		return model.LocalizedText{
			EN: "Buy seasonal or activity essentials while there is still time.",
			RU: "Купите сезонные и активити-вещи, пока еще есть время.",
			KK: "Маусымдық және белсенділікке қажет заттарды алдын ала алыңыз.",
		}
	case 7:
		return model.LocalizedText{
			EN: "Review baggage restrictions, power banks, liquids, medicine, and airline-specific rules.",
			RU: "Проверьте ограничения багажа, power bank, жидкости, лекарства и правила авиакомпании.",
			KK: "Багаж шектеулері, power bank, сұйықтықтар, дәрі-дәрмек және әуе компаниясы ережелерін тексеріңіз.",
		}
	case 2:
		return model.LocalizedText{
			EN: "Pack documents, chargers, money, weather protection, and critical activity items.",
			RU: "Соберите документы, зарядки, деньги, защиту от погоды и важные вещи для активностей.",
			KK: "Құжаттар, қуаттағыштар, ақша, ауа райынан қорғаныс және маңызды заттарды жинаңыз.",
		}
	default:
		return model.LocalizedText{
			EN: "Do the final readiness check and download offline essentials.",
			RU: "Сделайте финальную проверку готовности и скачайте нужное офлайн.",
			KK: "Соңғы дайындықты тексеріп, қажет нәрсені офлайн сақтаңыз.",
		}
	}
}

func newChecklistInstanceID(now time.Time) string {
	return newRandomID("checklist", now)
}

func newChecklistFeedbackID(now time.Time) string {
	return newRandomID("feedback", now)
}

func newCustomChecklistItemID(now time.Time) string {
	return newRandomID("custom-item", now)
}

func newPersonalChecklistTemplateID(now time.Time) string {
	return newRandomID("personal-template", now)
}

func newRandomID(prefix string, now time.Time) string {
	var b [16]byte
	if _, err := rand.Read(b[:]); err != nil {
		return fmt.Sprintf("%s-%d", prefix, now.UnixNano())
	}

	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80

	return fmt.Sprintf("%s-%x-%x-%x-%x-%x", prefix, b[0:4], b[4:6], b[6:8], b[8:10], b[10:16])
}
