package app

import (
	"context"
	"sort"
	"strings"
	"sync"
	"time"

	"kz/inflap/backend/services/checklist-service/internal/domain/model"
)

type ChecklistRepository interface {
	Templates() []model.ChecklistTemplate
	SeasonalProfiles() []model.SeasonalProfile
	CarryRules() []model.CarryRule
	FindTripChecklistInstance(ctx context.Context, userID string, tripID string) (model.TripChecklist, bool, error)
	SaveTripChecklistInstance(ctx context.Context, checklist model.TripChecklist) error
	ListTripChecklistInstances(ctx context.Context, limit int) ([]model.TripChecklist, error)
	ListTripChecklistInstancesByUser(ctx context.Context, userID string, limit int) ([]model.TripChecklist, error)
	ListCustomChecklistItems(ctx context.Context, userID string, tripID string) ([]model.CustomChecklistItem, error)
	SaveCustomChecklistItem(ctx context.Context, item model.CustomChecklistItem) error
	SoftDeleteCustomChecklistItem(ctx context.Context, userID string, tripID string, itemID string, deletedAt time.Time) error
	FindCustomChecklistItem(
		ctx context.Context,
		userID string,
		tripID string,
		itemID string,
	) (model.CustomChecklistItem, bool, error)
	SavePersonalChecklistTemplate(ctx context.Context, template model.PersonalChecklistTemplate) error
	ListPersonalChecklistTemplates(
		ctx context.Context,
		userID string,
		activeOnly bool,
	) ([]model.PersonalChecklistTemplate, error)
	SaveChecklistItemFeedback(ctx context.Context, feedback model.ChecklistItemFeedback) error
	ListChecklistItemFeedback(
		ctx context.Context,
		feedbackType model.ChecklistFeedbackType,
		limit int,
	) ([]model.ChecklistItemFeedback, error)
}

type MemoryChecklistRepository struct {
	mu                sync.RWMutex
	templates         []model.ChecklistTemplate
	seasonalProfiles  []model.SeasonalProfile
	carryRules        []model.CarryRule
	instances         map[string]model.TripChecklist
	customItems       map[string]model.CustomChecklistItem
	personalTemplates map[string]model.PersonalChecklistTemplate
	feedback          []model.ChecklistItemFeedback
}

func NewMemoryChecklistRepository(seed model.CatalogSeed) *MemoryChecklistRepository {
	return &MemoryChecklistRepository{
		templates:         append([]model.ChecklistTemplate(nil), seed.Templates...),
		seasonalProfiles:  append([]model.SeasonalProfile(nil), seed.SeasonalProfiles...),
		carryRules:        append([]model.CarryRule(nil), seed.CarryRules...),
		instances:         make(map[string]model.TripChecklist),
		customItems:       make(map[string]model.CustomChecklistItem),
		personalTemplates: make(map[string]model.PersonalChecklistTemplate),
	}
}

func (r *MemoryChecklistRepository) Templates() []model.ChecklistTemplate {
	return append([]model.ChecklistTemplate(nil), r.templates...)
}

func (r *MemoryChecklistRepository) SeasonalProfiles() []model.SeasonalProfile {
	return append([]model.SeasonalProfile(nil), r.seasonalProfiles...)
}

func (r *MemoryChecklistRepository) CarryRules() []model.CarryRule {
	return append([]model.CarryRule(nil), r.carryRules...)
}

func (r *MemoryChecklistRepository) FindTripChecklistInstance(
	_ context.Context,
	userID string,
	tripID string,
) (model.TripChecklist, bool, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	checklist, ok := r.instances[tripChecklistInstanceKey(userID, tripID)]
	if !ok {
		return model.TripChecklist{}, false, nil
	}
	return cloneTripChecklist(checklist), true, nil
}

func (r *MemoryChecklistRepository) SaveTripChecklistInstance(
	_ context.Context,
	checklist model.TripChecklist,
) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	checklist = cloneTripChecklist(checklist)
	checklist.CustomItems = nil
	checklist.PersonalProgress = model.PersonalChecklistProgress{}
	r.instances[tripChecklistInstanceKey(checklist.UserID, checklist.TripID)] = checklist
	return nil
}

func (r *MemoryChecklistRepository) ListTripChecklistInstances(
	_ context.Context,
	limit int,
) ([]model.TripChecklist, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	checklists := make([]model.TripChecklist, 0, len(r.instances))
	for _, checklist := range r.instances {
		checklists = append(checklists, cloneTripChecklist(checklist))
	}
	sort.SliceStable(checklists, func(i, j int) bool {
		if !checklists[i].StartAt.Equal(checklists[j].StartAt) {
			return checklists[i].StartAt.Before(checklists[j].StartAt)
		}
		if checklists[i].UserID != checklists[j].UserID {
			return checklists[i].UserID < checklists[j].UserID
		}
		return checklists[i].TripID < checklists[j].TripID
	})
	if limit > 0 && len(checklists) > limit {
		checklists = checklists[:limit]
	}
	return checklists, nil
}

func (r *MemoryChecklistRepository) ListTripChecklistInstancesByUser(
	_ context.Context,
	userID string,
	limit int,
) ([]model.TripChecklist, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	userID = strings.TrimSpace(userID)
	checklists := make([]model.TripChecklist, 0, len(r.instances))
	for _, checklist := range r.instances {
		if checklist.UserID != userID {
			continue
		}
		checklists = append(checklists, cloneTripChecklist(checklist))
	}
	sort.SliceStable(checklists, func(i, j int) bool {
		if !checklists[i].StartAt.Equal(checklists[j].StartAt) {
			return checklists[i].StartAt.Before(checklists[j].StartAt)
		}
		return checklists[i].TripID < checklists[j].TripID
	})
	if limit > 0 && len(checklists) > limit {
		checklists = checklists[:limit]
	}
	return checklists, nil
}

func (r *MemoryChecklistRepository) ListCustomChecklistItems(
	_ context.Context,
	userID string,
	tripID string,
) ([]model.CustomChecklistItem, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	userID = strings.TrimSpace(userID)
	tripID = strings.TrimSpace(tripID)
	items := make([]model.CustomChecklistItem, 0)
	for _, item := range r.customItems {
		if item.UserID != userID || item.TripID != tripID || item.DeletedAt != nil {
			continue
		}
		items = append(items, cloneCustomChecklistItem(item))
	}
	sort.SliceStable(items, func(i, j int) bool {
		if !items[i].UpdatedAt.Equal(items[j].UpdatedAt) {
			return items[i].UpdatedAt.After(items[j].UpdatedAt)
		}
		return items[i].ID < items[j].ID
	})
	return items, nil
}

func (r *MemoryChecklistRepository) SaveCustomChecklistItem(
	_ context.Context,
	item model.CustomChecklistItem,
) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.customItems[customChecklistItemKey(item.UserID, item.TripID, item.ID)] = cloneCustomChecklistItem(item)
	return nil
}

func (r *MemoryChecklistRepository) SoftDeleteCustomChecklistItem(
	_ context.Context,
	userID string,
	tripID string,
	itemID string,
	deletedAt time.Time,
) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := customChecklistItemKey(userID, tripID, itemID)
	item, ok := r.customItems[key]
	if !ok {
		return nil
	}
	deletedAt = deletedAt.UTC()
	item.DeletedAt = &deletedAt
	item.UpdatedAt = deletedAt
	r.customItems[key] = cloneCustomChecklistItem(item)
	return nil
}

func (r *MemoryChecklistRepository) FindCustomChecklistItem(
	_ context.Context,
	userID string,
	tripID string,
	itemID string,
) (model.CustomChecklistItem, bool, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	item, ok := r.customItems[customChecklistItemKey(userID, tripID, itemID)]
	if !ok || item.DeletedAt != nil {
		return model.CustomChecklistItem{}, false, nil
	}
	return cloneCustomChecklistItem(item), true, nil
}

func (r *MemoryChecklistRepository) SavePersonalChecklistTemplate(
	_ context.Context,
	template model.PersonalChecklistTemplate,
) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.personalTemplates[personalChecklistTemplateKey(template.UserID, template.ID)] = template
	return nil
}

func (r *MemoryChecklistRepository) ListPersonalChecklistTemplates(
	_ context.Context,
	userID string,
	activeOnly bool,
) ([]model.PersonalChecklistTemplate, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	userID = strings.TrimSpace(userID)
	templates := make([]model.PersonalChecklistTemplate, 0)
	for _, template := range r.personalTemplates {
		if template.UserID != userID {
			continue
		}
		if activeOnly && !template.IsActive {
			continue
		}
		templates = append(templates, template)
	}
	sort.SliceStable(templates, func(i, j int) bool {
		if !templates[i].UpdatedAt.Equal(templates[j].UpdatedAt) {
			return templates[i].UpdatedAt.After(templates[j].UpdatedAt)
		}
		return templates[i].ID < templates[j].ID
	})
	return templates, nil
}

func (r *MemoryChecklistRepository) SaveChecklistItemFeedback(
	_ context.Context,
	feedback model.ChecklistItemFeedback,
) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.feedback = append(r.feedback, feedback)
	return nil
}

func (r *MemoryChecklistRepository) ListChecklistItemFeedback(
	_ context.Context,
	feedbackType model.ChecklistFeedbackType,
	limit int,
) ([]model.ChecklistItemFeedback, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	matches := make([]model.ChecklistItemFeedback, 0)
	for i := len(r.feedback) - 1; i >= 0; i-- {
		entry := r.feedback[i]
		if feedbackType != "" && entry.FeedbackType != feedbackType {
			continue
		}
		matches = append(matches, entry)
		if limit > 0 && len(matches) >= limit {
			break
		}
	}
	return matches, nil
}

func (r *MemoryChecklistRepository) FeedbackEntries() []model.ChecklistItemFeedback {
	r.mu.RLock()
	defer r.mu.RUnlock()

	return append([]model.ChecklistItemFeedback(nil), r.feedback...)
}

func tripChecklistInstanceKey(userID string, tripID string) string {
	return strings.TrimSpace(userID) + "\x00" + strings.TrimSpace(tripID)
}

func customChecklistItemKey(userID string, tripID string, itemID string) string {
	return strings.TrimSpace(userID) + "\x00" + strings.TrimSpace(tripID) + "\x00" + strings.TrimSpace(itemID)
}

func personalChecklistTemplateKey(userID string, templateID string) string {
	return strings.TrimSpace(userID) + "\x00" + strings.TrimSpace(templateID)
}

func cloneTripChecklist(checklist model.TripChecklist) model.TripChecklist {
	checklist.TransportModes = append([]model.TransportMode(nil), checklist.TransportModes...)
	checklist.ActivitySlugs = append([]string(nil), checklist.ActivitySlugs...)
	checklist.Items = append([]model.ChecklistItem(nil), checklist.Items...)
	checklist.CustomItems = cloneCustomChecklistItems(checklist.CustomItems)
	return checklist
}

func cloneCustomChecklistItems(items []model.CustomChecklistItem) []model.CustomChecklistItem {
	cloned := make([]model.CustomChecklistItem, len(items))
	for i, item := range items {
		cloned[i] = cloneCustomChecklistItem(item)
	}
	return cloned
}

func cloneCustomChecklistItem(item model.CustomChecklistItem) model.CustomChecklistItem {
	if item.DeletedAt != nil {
		deletedAt := *item.DeletedAt
		item.DeletedAt = &deletedAt
	}
	return item
}
