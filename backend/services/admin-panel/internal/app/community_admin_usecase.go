package app

import (
	"context"
	"encoding/json"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
	"kz/inflap/backend/services/admin-panel/internal/domain/port"
)

var communityAdminLocales = []string{"ru", "en", "kk"}

const maxCommunityAdminCatalogLimit = 500

type CommunityAdminUseCase struct {
	communities port.CommunityAdminClient
	files       port.FileUploadClient
	audit       port.AuditRepository
	maxImage    int64
}

type CreateCommunityAdminInput struct {
	Slug            string
	TitleI18n       map[string]string
	DescriptionI18n map[string]string
	RulesI18n       map[string][]string
	Topic           string
	CityID          *string
	CountryCode     *string
	AvatarFileID    *uuid.UUID
	CoverFileID     *uuid.UUID
	Visibility      string
	PostingPolicy   string
	Status          string
	RequestID       string
}

type CommunityImageUploadInput struct {
	FileName    string
	ContentType string
	Content     []byte
	Metadata    RequestMetadata
}

type CommunityPlatformCatalogInput struct {
	CountryCode string
	CityID      string
	ScopeType   string
	Search      string
	Limit       int
	Offset      int
}

type MaterializeCommunityInstancesInput struct {
	BlueprintID uuid.UUID
	CountryCode string
	CityID      string
	ScopeType   string
	Limit       int
	RequestID   string
}

func NewCommunityAdminUseCase(
	communities port.CommunityAdminClient,
	audit port.AuditRepository,
	options ...CommunityAdminOption,
) *CommunityAdminUseCase {
	u := &CommunityAdminUseCase{
		communities: communities,
		audit:       audit,
		maxImage:    defaultMaxAttractionImage,
	}
	for _, option := range options {
		if option != nil {
			option(u)
		}
	}
	return u
}

type CommunityAdminOption func(*CommunityAdminUseCase)

func WithCommunityAdminFileUploads(files port.FileUploadClient, maxImageBytes int64) CommunityAdminOption {
	return func(u *CommunityAdminUseCase) {
		u.files = files
		if maxImageBytes > 0 {
			u.maxImage = maxImageBytes
		}
	}
}

func (u *CommunityAdminUseCase) CreateCommunity(
	ctx context.Context,
	actor *model.StaffUser,
	input CreateCommunityAdminInput,
) (model.AdminCommunity, error) {
	if actor == nil || !actor.HasRole(enum.StaffRoleSuperAdmin) {
		return model.AdminCommunity{}, ErrPermissionDenied
	}
	if u == nil || u.communities == nil {
		return model.AdminCommunity{}, ErrIntegrationNotReady
	}
	if !validCommunityAdminInput(input) {
		return model.AdminCommunity{}, ErrInvalidInput
	}

	created, err := u.communities.CreateCommunity(ctx, port.CreateCommunityInput{
		ActorStaffID:    actor.ID,
		Slug:            strings.TrimSpace(input.Slug),
		TitleI18n:       cloneAdminCommunityTextMap(input.TitleI18n),
		DescriptionI18n: cloneAdminCommunityTextMap(input.DescriptionI18n),
		RulesI18n:       cloneAdminCommunityRulesMap(input.RulesI18n),
		Topic:           strings.ToUpper(strings.TrimSpace(input.Topic)),
		CityID:          cloneStringPtr(input.CityID),
		CountryCode:     cloneUpperStringPtr(input.CountryCode),
		AvatarFileID:    cloneUUIDPtr(input.AvatarFileID),
		CoverFileID:     cloneUUIDPtr(input.CoverFileID),
		Visibility:      strings.ToUpper(strings.TrimSpace(input.Visibility)),
		PostingPolicy:   strings.ToUpper(strings.TrimSpace(input.PostingPolicy)),
		Status:          strings.ToUpper(strings.TrimSpace(input.Status)),
		RequestID:       strings.TrimSpace(input.RequestID),
	})
	if err != nil {
		return model.AdminCommunity{}, err
	}

	if u.audit != nil {
		_ = u.audit.Append(ctx, communityCreateAuditEvent(actor, input.RequestID, created))
	}
	return created, nil
}

func (u *CommunityAdminUseCase) GetCommunity(
	ctx context.Context,
	actor *model.StaffUser,
	id uuid.UUID,
) (model.AdminCommunity, error) {
	if actor == nil || !actor.HasRole(enum.StaffRoleSuperAdmin) {
		return model.AdminCommunity{}, ErrPermissionDenied
	}
	if u == nil || u.communities == nil {
		return model.AdminCommunity{}, ErrIntegrationNotReady
	}
	if id == uuid.Nil {
		return model.AdminCommunity{}, ErrInvalidInput
	}
	return u.communities.GetCommunity(ctx, id)
}

func (u *CommunityAdminUseCase) UpdateCommunity(
	ctx context.Context,
	actor *model.StaffUser,
	id uuid.UUID,
	input CreateCommunityAdminInput,
) (model.AdminCommunity, error) {
	if actor == nil || !actor.HasRole(enum.StaffRoleSuperAdmin) {
		return model.AdminCommunity{}, ErrPermissionDenied
	}
	if u == nil || u.communities == nil {
		return model.AdminCommunity{}, ErrIntegrationNotReady
	}
	if id == uuid.Nil || !validCommunityAdminInput(input) {
		return model.AdminCommunity{}, ErrInvalidInput
	}
	updated, err := u.communities.UpdateCommunity(ctx, id, port.UpdateCommunityInput{
		ActorStaffID:    actor.ID,
		Slug:            strings.TrimSpace(input.Slug),
		TitleI18n:       cloneAdminCommunityTextMap(input.TitleI18n),
		DescriptionI18n: cloneAdminCommunityTextMap(input.DescriptionI18n),
		RulesI18n:       cloneAdminCommunityRulesMap(input.RulesI18n),
		Topic:           strings.ToUpper(strings.TrimSpace(input.Topic)),
		CityID:          cloneStringPtr(input.CityID),
		CountryCode:     cloneUpperStringPtr(input.CountryCode),
		AvatarFileID:    cloneUUIDPtr(input.AvatarFileID),
		CoverFileID:     cloneUUIDPtr(input.CoverFileID),
		Visibility:      strings.ToUpper(strings.TrimSpace(input.Visibility)),
		PostingPolicy:   strings.ToUpper(strings.TrimSpace(input.PostingPolicy)),
		Status:          strings.ToUpper(strings.TrimSpace(input.Status)),
		RequestID:       strings.TrimSpace(input.RequestID),
	})
	if err != nil {
		return model.AdminCommunity{}, err
	}
	if u.audit != nil {
		_ = u.audit.Append(ctx, communityUpdateAuditEvent(actor, input.RequestID, updated))
	}
	return updated, nil
}

func (u *CommunityAdminUseCase) UploadCommunityImage(
	ctx context.Context,
	actor *model.StaffUser,
	communityID uuid.UUID,
	input CommunityImageUploadInput,
) (*model.UploadedFile, error) {
	if actor == nil || !actor.HasRole(enum.StaffRoleSuperAdmin) {
		return nil, ErrPermissionDenied
	}
	if u == nil || u.files == nil {
		return nil, ErrIntegrationNotReady
	}
	if communityID == uuid.Nil {
		return nil, ErrInvalidInput
	}
	if err := u.validateCommunityImageUpload(input); err != nil {
		return nil, err
	}
	return u.files.UploadPublicAttractionImage(ctx, model.FileUploadInput{
		FileName:    strings.TrimSpace(input.FileName),
		ContentType: normalizeContentType(input.ContentType, input.Content),
		Content:     input.Content,
		Purpose:     "COMMUNITY_MEDIA",
		Visibility:  "PUBLIC",
		OwnerType:   "COMMUNITY",
		OwnerID:     communityID,
	})
}

func (u *CommunityAdminUseCase) CommunityPlatformCatalog(
	ctx context.Context,
	actor *model.StaffUser,
	input CommunityPlatformCatalogInput,
) (model.CommunityPlatformCatalog, error) {
	if actor == nil || !actor.HasRole(enum.StaffRoleSuperAdmin) {
		return model.CommunityPlatformCatalog{}, ErrPermissionDenied
	}
	if u == nil || u.communities == nil {
		return model.CommunityPlatformCatalog{}, ErrIntegrationNotReady
	}
	return u.communities.CommunityPlatformCatalog(ctx, port.CommunityPlatformCatalogInput{
		CountryCode: normalizeCommunityCountry(input.CountryCode),
		CityID:      strings.TrimSpace(input.CityID),
		ScopeType:   strings.ToUpper(strings.TrimSpace(input.ScopeType)),
		Search:      strings.TrimSpace(input.Search),
		Limit:       normalizeCommunityAdminListLimit(input.Limit),
		Offset:      normalizeCommunityAdminOffset(input.Offset),
	})
}

func (u *CommunityAdminUseCase) MaterializeCommunityInstances(
	ctx context.Context,
	actor *model.StaffUser,
	input MaterializeCommunityInstancesInput,
) (model.CommunityMaterializationResult, error) {
	if actor == nil || !actor.HasRole(enum.StaffRoleSuperAdmin) {
		return model.CommunityMaterializationResult{}, ErrPermissionDenied
	}
	if u == nil || u.communities == nil {
		return model.CommunityMaterializationResult{}, ErrIntegrationNotReady
	}
	result, err := u.communities.MaterializeCommunityInstances(ctx, port.MaterializeCommunityInstancesInput{
		ActorStaffID: actor.ID,
		BlueprintID:  input.BlueprintID,
		CountryCode:  normalizeCommunityCountry(input.CountryCode),
		CityID:       strings.TrimSpace(input.CityID),
		ScopeType:    strings.ToUpper(strings.TrimSpace(input.ScopeType)),
		Limit:        normalizeCommunityMaterializationLimit(input.Limit),
		RequestID:    strings.TrimSpace(input.RequestID),
	})
	if err != nil {
		return model.CommunityMaterializationResult{}, err
	}
	if u.audit != nil {
		_ = u.audit.Append(ctx, communityMaterializeAuditEvent(actor, input, result))
	}
	return result, nil
}

func validCommunityAdminInput(input CreateCommunityAdminInput) bool {
	if strings.TrimSpace(input.Slug) == "" {
		return false
	}
	for _, locale := range communityAdminLocales {
		if strings.TrimSpace(input.TitleI18n[locale]) == "" ||
			strings.TrimSpace(input.DescriptionI18n[locale]) == "" {
			return false
		}
	}
	return true
}

func (u *CommunityAdminUseCase) validateCommunityImageUpload(input CommunityImageUploadInput) error {
	if len(input.Content) == 0 || int64(len(input.Content)) > u.maxImage {
		return ErrInvalidInput
	}
	name := strings.TrimSpace(input.FileName)
	if name == "" {
		return ErrInvalidInput
	}
	switch strings.ToLower(strings.TrimPrefix(filepath.Ext(name), ".")) {
	case "jpg", "jpeg", "png", "webp":
	default:
		return ErrInvalidInput
	}
	switch normalizeContentType(input.ContentType, input.Content) {
	case "image/jpeg", "image/png", "image/webp":
		return nil
	default:
		return ErrInvalidInput
	}
}

func communityMaterializeAuditEvent(
	actor *model.StaffUser,
	input MaterializeCommunityInstancesInput,
	result model.CommunityMaterializationResult,
) *model.AuditEvent {
	after, _ := json.Marshal(map[string]any{
		"blueprintId":       input.BlueprintID,
		"countryCode":       normalizeCommunityCountry(input.CountryCode),
		"cityId":            strings.TrimSpace(input.CityID),
		"scopeType":         strings.ToUpper(strings.TrimSpace(input.ScopeType)),
		"limit":             normalizeCommunityMaterializationLimit(input.Limit),
		"materializedCount": result.MaterializedCount,
	})
	return &model.AuditEvent{
		ID:               uuid.New(),
		ActorStaffID:     &actor.ID,
		ActorDisplayName: actor.DisplayName,
		ActorEmail:       actor.Email,
		Action:           "community.instances.materialize",
		EntityType:       "community_platform",
		RequestID:        strings.TrimSpace(input.RequestID),
		AfterJSON:        after,
		CreatedAt:        time.Now().UTC(),
	}
}

func communityCreateAuditEvent(
	actor *model.StaffUser,
	requestID string,
	created model.AdminCommunity,
) *model.AuditEvent {
	after, _ := json.Marshal(map[string]any{
		"id":              created.ID,
		"slug":            created.Slug,
		"titleI18n":       created.TitleI18n,
		"descriptionI18n": created.DescriptionI18n,
		"topic":           created.Topic,
		"postingPolicy":   created.PostingPolicy,
		"status":          created.Status,
	})
	entityID := created.ID
	return &model.AuditEvent{
		ID:               uuid.New(),
		ActorStaffID:     &actor.ID,
		ActorDisplayName: actor.DisplayName,
		ActorEmail:       actor.Email,
		Action:           "community.create",
		EntityType:       "story_community",
		EntityID:         &entityID,
		RequestID:        strings.TrimSpace(requestID),
		AfterJSON:        after,
		CreatedAt:        time.Now().UTC(),
	}
}

func communityUpdateAuditEvent(
	actor *model.StaffUser,
	requestID string,
	updated model.AdminCommunity,
) *model.AuditEvent {
	after, _ := json.Marshal(map[string]any{
		"id":              updated.ID,
		"slug":            updated.Slug,
		"titleI18n":       updated.TitleI18n,
		"descriptionI18n": updated.DescriptionI18n,
		"topic":           updated.Topic,
		"postingPolicy":   updated.PostingPolicy,
		"status":          updated.Status,
		"avatarFileId":    updated.AvatarFileID,
		"coverFileId":     updated.CoverFileID,
	})
	entityID := updated.ID
	return &model.AuditEvent{
		ID:               uuid.New(),
		ActorStaffID:     &actor.ID,
		ActorDisplayName: actor.DisplayName,
		ActorEmail:       actor.Email,
		Action:           "community.update",
		EntityType:       "story_community",
		EntityID:         &entityID,
		RequestID:        strings.TrimSpace(requestID),
		AfterJSON:        after,
		CreatedAt:        time.Now().UTC(),
	}
}

func normalizeCommunityAdminListLimit(limit int) int {
	if limit <= 0 {
		return 50
	}
	if limit > maxCommunityAdminCatalogLimit {
		return maxCommunityAdminCatalogLimit
	}
	return limit
}

func normalizeCommunityMaterializationLimit(limit int) int {
	if limit <= 0 {
		return 500
	}
	if limit > 5000 {
		return 5000
	}
	return limit
}

func normalizeCommunityAdminOffset(offset int) int {
	if offset < 0 {
		return 0
	}
	return offset
}

func normalizeCommunityCountry(value string) string {
	return strings.ToUpper(strings.TrimSpace(value))
}

func cloneAdminCommunityTextMap(input map[string]string) map[string]string {
	out := make(map[string]string, len(communityAdminLocales))
	for _, locale := range communityAdminLocales {
		out[locale] = strings.TrimSpace(input[locale])
	}
	return out
}

func cloneAdminCommunityRulesMap(input map[string][]string) map[string][]string {
	out := make(map[string][]string, len(communityAdminLocales))
	for _, locale := range communityAdminLocales {
		rules := make([]string, 0, len(input[locale]))
		for _, rule := range input[locale] {
			if trimmed := strings.TrimSpace(rule); trimmed != "" {
				rules = append(rules, trimmed)
			}
		}
		out[locale] = rules
	}
	return out
}

func cloneStringPtr(input *string) *string {
	if input == nil {
		return nil
	}
	trimmed := strings.TrimSpace(*input)
	if trimmed == "" {
		return nil
	}
	return &trimmed
}

func cloneUpperStringPtr(input *string) *string {
	if input == nil {
		return nil
	}
	trimmed := strings.ToUpper(strings.TrimSpace(*input))
	if trimmed == "" {
		return nil
	}
	return &trimmed
}

func cloneUUIDPtr(input *uuid.UUID) *uuid.UUID {
	if input == nil || *input == uuid.Nil {
		return nil
	}
	cloned := *input
	return &cloned
}
