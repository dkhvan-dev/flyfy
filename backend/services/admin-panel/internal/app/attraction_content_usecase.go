package app

import (
	"context"
	"encoding/json"
	"net/http"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/port"
)

const (
	defaultAttractionListLimit = 50
	defaultMaxAttractionImage  = int64(20 << 20)
)

type AttractionContentUseCase struct {
	attractions port.AttractionAdminClient
	files       port.FileUploadClient
	audit       port.AuditRepository
	maxImage    int64
}

type AttractionContentConfig struct {
	MaxImageBytes int64
}

type AttractionImageUploadInput struct {
	FileName    string
	ContentType string
	Content     []byte
	Metadata    RequestMetadata
}

type AttractionMediaAction string

const (
	AttractionMediaActionManage  AttractionMediaAction = "manage"
	AttractionMediaActionAppend  AttractionMediaAction = "append"
	AttractionMediaActionReplace AttractionMediaAction = "replace"
)

type AttractionMediaUpdateInput struct {
	Action           AttractionMediaAction
	ExistingMediaIDs []uuid.UUID
	DeleteMediaIDs   []uuid.UUID
	Uploads          []AttractionImageUploadInput
	Metadata         RequestMetadata
}

func NewAttractionContentUseCase(
	attractions port.AttractionAdminClient,
	files port.FileUploadClient,
	audit port.AuditRepository,
	cfg AttractionContentConfig,
) *AttractionContentUseCase {
	maxImage := cfg.MaxImageBytes
	if maxImage <= 0 {
		maxImage = defaultMaxAttractionImage
	}
	return &AttractionContentUseCase{
		attractions: attractions,
		files:       files,
		audit:       audit,
		maxImage:    maxImage,
	}
}

func (u *AttractionContentUseCase) ListAttractions(ctx context.Context, actor *model.StaffUser, filter model.AdminAttractionFilter) ([]model.AdminAttraction, int, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionAttractionManage) {
		return nil, 0, ErrPermissionDenied
	}
	filter.Limit = clampLimitWithDefault(filter.Limit, defaultAttractionListLimit)
	filter.Offset = normalizeOffset(filter.Offset)
	filter.Search = strings.TrimSpace(filter.Search)
	filter.Locale = normalizeAdminLocale(filter.Locale)
	filter.CountryCode = strings.ToUpper(strings.TrimSpace(filter.CountryCode))
	filter.CityID = strings.ToLower(strings.TrimSpace(filter.CityID))
	filter.Category = strings.ToUpper(strings.TrimSpace(filter.Category))
	filter.Status = strings.ToUpper(strings.TrimSpace(filter.Status))
	filter.IncludeDeleted = true
	return u.attractions.ListAttractions(ctx, filter)
}

func (u *AttractionContentUseCase) GetAttraction(ctx context.Context, actor *model.StaffUser, id uuid.UUID) (*model.AdminAttraction, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionAttractionManage) {
		return nil, ErrPermissionDenied
	}
	if id == uuid.Nil {
		return nil, ErrInvalidInput
	}
	item, err := u.attractions.GetAttraction(ctx, id)
	if err != nil {
		return nil, err
	}
	if item == nil {
		return nil, ErrAttractionNotFound
	}
	return item, nil
}

func (u *AttractionContentUseCase) CreateAttraction(ctx context.Context, actor *model.StaffUser, input model.AttractionInput, metadata ...RequestMetadata) (*model.AdminAttraction, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionAttractionManage) {
		return nil, ErrPermissionDenied
	}
	normalized, err := normalizeAttractionInput(input)
	if err != nil {
		return nil, err
	}
	item, err := u.attractions.CreateAttraction(ctx, normalized)
	if err != nil {
		return nil, err
	}
	if item != nil {
		u.appendAttractionAudit(ctx, actor, "attraction.created", item.ID, input, item, inputAuditMeta(input), firstRequestMetadata(metadata))
	}
	return item, nil
}

func (u *AttractionContentUseCase) UpdateAttraction(ctx context.Context, actor *model.StaffUser, id uuid.UUID, input model.AttractionInput, meta RequestMetadata) (*model.AdminAttraction, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionAttractionManage) {
		return nil, ErrPermissionDenied
	}
	if id == uuid.Nil {
		return nil, ErrInvalidInput
	}
	before, _ := u.attractions.GetAttraction(ctx, id)
	normalized, err := normalizeAttractionInput(input)
	if err != nil {
		return nil, err
	}
	item, err := u.attractions.UpdateAttraction(ctx, id, normalized)
	if err != nil {
		return nil, err
	}
	u.appendAttractionAudit(ctx, actor, "attraction.updated", id, before, item, inputAuditMeta(input), meta)
	return item, nil
}

func (u *AttractionContentUseCase) ReplaceCoverImage(ctx context.Context, actor *model.StaffUser, attractionID uuid.UUID, input AttractionImageUploadInput) error {
	return u.ReplaceCarouselImages(ctx, actor, attractionID, []AttractionImageUploadInput{input})
}

func (u *AttractionContentUseCase) ReplaceCarouselImages(ctx context.Context, actor *model.StaffUser, attractionID uuid.UUID, inputs []AttractionImageUploadInput) error {
	if actor == nil || !actor.HasPermission(enum.PermissionAttractionManage) {
		return ErrPermissionDenied
	}
	if attractionID == uuid.Nil {
		return ErrInvalidInput
	}
	if len(inputs) == 0 || len(inputs) > 10 {
		return ErrInvalidInput
	}
	for _, input := range inputs {
		if err := u.validateImageUpload(input); err != nil {
			return err
		}
	}
	metadata := inputs[0].Metadata
	attraction, err := u.attractions.GetAttraction(ctx, attractionID)
	if err != nil {
		return err
	}
	if attraction == nil {
		return ErrAttractionNotFound
	}

	media := make([]model.AttractionMediaInput, 0, len(inputs))
	fileIDs := make([]uuid.UUID, 0, len(inputs))
	fileNames := make([]string, 0, len(inputs))
	for position, input := range inputs {
		uploaded, uploadErr := u.files.UploadPublicAttractionImage(ctx, model.FileUploadInput{
			FileName:    strings.TrimSpace(input.FileName),
			ContentType: normalizeContentType(input.ContentType, input.Content),
			Content:     input.Content,
			Purpose:     "ATTRACTION_MEDIA",
			Visibility:  "PUBLIC",
			OwnerType:   "ATTRACTION",
			OwnerID:     attractionID,
		})
		if uploadErr != nil {
			return uploadErr
		}
		if uploaded == nil || uploaded.ID == uuid.Nil {
			return ErrInvalidInput
		}
		media = append(media, model.AttractionMediaInput{
			FileID:    uploaded.ID,
			MediaType: "PHOTO",
			Position:  position,
		})
		fileIDs = append(fileIDs, uploaded.ID)
		fileNames = append(fileNames, strings.TrimSpace(input.FileName))
	}
	if err = u.attractions.ReplaceMedia(ctx, attractionID, media); err != nil {
		return err
	}
	u.appendAttractionAudit(ctx, actor, "attraction.media.replaced", attractionID, attraction.Media, media, map[string]any{
		"fileNames": fileNames,
		"fileIds":   fileIDs,
	}, metadata)
	return nil
}

func (u *AttractionContentUseCase) UpdateCarouselImages(ctx context.Context, actor *model.StaffUser, attractionID uuid.UUID, input AttractionMediaUpdateInput) error {
	if actor == nil || !actor.HasPermission(enum.PermissionAttractionManage) {
		return ErrPermissionDenied
	}
	if attractionID == uuid.Nil {
		return ErrInvalidInput
	}
	action := normalizeAttractionMediaAction(input.Action)
	if action == "" {
		return ErrInvalidInput
	}
	if action == AttractionMediaActionManage && len(input.Uploads) > 0 {
		return ErrInvalidInput
	}
	if (action == AttractionMediaActionAppend || action == AttractionMediaActionReplace) && len(input.Uploads) == 0 {
		return ErrInvalidInput
	}
	if len(input.Uploads) > 10 {
		return ErrInvalidInput
	}
	for _, upload := range input.Uploads {
		if err := u.validateImageUpload(upload); err != nil {
			return err
		}
	}

	attraction, err := u.attractions.GetAttraction(ctx, attractionID)
	if err != nil {
		return err
	}
	if attraction == nil {
		return ErrAttractionNotFound
	}

	finalMedia := make([]model.AttractionMediaInput, 0, len(attraction.Media)+len(input.Uploads))
	deleteIDs := uuidSet(input.DeleteMediaIDs)
	if action != AttractionMediaActionReplace {
		existing, existingErr := orderedExistingAttractionMedia(attraction.Media, input.ExistingMediaIDs, deleteIDs)
		if existingErr != nil {
			return existingErr
		}
		finalMedia = append(finalMedia, existing...)
	}
	if len(finalMedia)+len(input.Uploads) > 10 {
		return ErrInvalidInput
	}

	fileIDs := make([]uuid.UUID, 0, len(input.Uploads))
	fileNames := make([]string, 0, len(input.Uploads))
	for _, upload := range input.Uploads {
		uploaded, uploadErr := u.files.UploadPublicAttractionImage(ctx, model.FileUploadInput{
			FileName:    strings.TrimSpace(upload.FileName),
			ContentType: normalizeContentType(upload.ContentType, upload.Content),
			Content:     upload.Content,
			Purpose:     "ATTRACTION_MEDIA",
			Visibility:  "PUBLIC",
			OwnerType:   "ATTRACTION",
			OwnerID:     attractionID,
		})
		if uploadErr != nil {
			return uploadErr
		}
		if uploaded == nil || uploaded.ID == uuid.Nil {
			return ErrInvalidInput
		}
		finalMedia = append(finalMedia, model.AttractionMediaInput{
			FileID:    uploaded.ID,
			MediaType: "PHOTO",
		})
		fileIDs = append(fileIDs, uploaded.ID)
		fileNames = append(fileNames, strings.TrimSpace(upload.FileName))
	}

	if len(finalMedia) > 10 {
		return ErrInvalidInput
	}
	for position := range finalMedia {
		finalMedia[position].Position = position
		if strings.TrimSpace(finalMedia[position].MediaType) == "" {
			finalMedia[position].MediaType = "PHOTO"
		}
	}
	if err = u.attractions.ReplaceMedia(ctx, attractionID, finalMedia); err != nil {
		return err
	}
	u.appendAttractionAudit(ctx, actor, "attraction.media.updated", attractionID, attraction.Media, finalMedia, map[string]any{
		"action":          action,
		"fileNames":       fileNames,
		"fileIds":         fileIDs,
		"deletedMediaIds": input.DeleteMediaIDs,
	}, input.Metadata)
	return nil
}

func (u *AttractionContentUseCase) GetPublicImageContent(ctx context.Context, actor *model.StaffUser, fileID uuid.UUID) (*model.FileContent, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionAttractionManage) {
		return nil, ErrPermissionDenied
	}
	if fileID == uuid.Nil {
		return nil, ErrInvalidInput
	}
	return u.files.GetPublicContent(ctx, fileID)
}

func (u *AttractionContentUseCase) validateImageUpload(input AttractionImageUploadInput) error {
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
	contentType := normalizeContentType(input.ContentType, input.Content)
	switch contentType {
	case "image/jpeg", "image/png", "image/webp":
		return nil
	default:
		return ErrInvalidInput
	}
}

func normalizeAttractionMediaAction(action AttractionMediaAction) AttractionMediaAction {
	switch AttractionMediaAction(strings.ToLower(strings.TrimSpace(string(action)))) {
	case "", AttractionMediaActionManage:
		return AttractionMediaActionManage
	case AttractionMediaActionAppend:
		return AttractionMediaActionAppend
	case AttractionMediaActionReplace:
		return AttractionMediaActionReplace
	default:
		return ""
	}
}

func orderedExistingAttractionMedia(media []model.AdminAttractionMedia, order []uuid.UUID, deleteIDs map[uuid.UUID]struct{}) ([]model.AttractionMediaInput, error) {
	byID := make(map[uuid.UUID]model.AdminAttractionMedia, len(media))
	for _, item := range media {
		if item.ID != uuid.Nil {
			byID[item.ID] = item
		}
	}
	ordered := make([]model.AdminAttractionMedia, 0, len(media))
	if len(order) == 0 {
		ordered = append(ordered, media...)
	} else {
		seen := make(map[uuid.UUID]struct{}, len(order))
		for _, id := range order {
			if id == uuid.Nil {
				return nil, ErrInvalidInput
			}
			if _, ok := seen[id]; ok {
				continue
			}
			seen[id] = struct{}{}
			item, ok := byID[id]
			if !ok {
				return nil, ErrInvalidInput
			}
			ordered = append(ordered, item)
		}
		for _, item := range media {
			if item.ID == uuid.Nil {
				continue
			}
			if _, ok := seen[item.ID]; !ok {
				ordered = append(ordered, item)
			}
		}
	}

	out := make([]model.AttractionMediaInput, 0, len(ordered))
	for _, item := range ordered {
		if _, deleted := deleteIDs[item.ID]; deleted {
			continue
		}
		out = append(out, model.AttractionMediaInput{
			FileID:      item.FileID,
			ExternalURL: strings.TrimSpace(item.ExternalURL),
			SourceURL:   strings.TrimSpace(item.SourceURL),
			Credit:      strings.TrimSpace(item.Credit),
			License:     strings.TrimSpace(item.License),
			MediaType:   strings.TrimSpace(item.MediaType),
		})
	}
	return out, nil
}

func uuidSet(values []uuid.UUID) map[uuid.UUID]struct{} {
	out := make(map[uuid.UUID]struct{}, len(values))
	for _, value := range values {
		if value != uuid.Nil {
			out[value] = struct{}{}
		}
	}
	return out
}

func normalizeAttractionInput(input model.AttractionInput) (model.AttractionInput, error) {
	input.Title = strings.TrimSpace(input.Title)
	input.Description = strings.TrimSpace(input.Description)
	input.DefaultLocale = normalizeAdminLocale(input.DefaultLocale)
	input.CountryCode = strings.ToUpper(strings.TrimSpace(input.CountryCode))
	input.CityID = strings.ToLower(strings.TrimSpace(input.CityID))
	input.Category = strings.ToUpper(strings.TrimSpace(input.Category))
	input.Status = strings.ToUpper(strings.TrimSpace(input.Status))
	input.LocationSourceURL = strings.TrimSpace(input.LocationSourceURL)
	if input.Title == "" || input.Description == "" || input.CountryCode == "" || input.CityID == "" || input.Category == "" || input.Status == "" {
		return input, ErrInvalidInput
	}
	if input.Translations == nil {
		input.Translations = map[string]model.AttractionTranslation{}
	}
	for locale, tr := range input.Translations {
		normalizedLocale := normalizeAdminLocale(locale)
		tr.Title = strings.TrimSpace(tr.Title)
		tr.Description = strings.TrimSpace(tr.Description)
		if tr.Title == "" || tr.Description == "" {
			delete(input.Translations, locale)
			continue
		}
		if normalizedLocale != locale {
			delete(input.Translations, locale)
		}
		input.Translations[normalizedLocale] = tr
	}
	input.Tags = normalizeStringList(input.Tags)
	input.AccessCities = normalizeCityLinks(input.AccessCities, input.CountryCode)
	input.DepartureCities = normalizeCityLinks(input.DepartureCities, input.CountryCode)
	return input, nil
}

func normalizeCityLinks(items []model.AttractionCityLink, fallbackCountry string) []model.AttractionCityLink {
	out := make([]model.AttractionCityLink, 0, len(items))
	seen := map[string]struct{}{}
	for _, item := range items {
		cityID := strings.ToLower(strings.TrimSpace(item.CityID))
		if cityID == "" {
			continue
		}
		country := strings.ToUpper(strings.TrimSpace(item.CountryCode))
		if country == "" {
			country = fallbackCountry
		}
		key := country + ":" + cityID
		if _, exists := seen[key]; exists {
			continue
		}
		seen[key] = struct{}{}
		out = append(out, model.AttractionCityLink{CountryCode: country, CityID: cityID})
	}
	return out
}

func normalizeAdminLocale(raw string) string {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "ru":
		return "ru"
	case "kk":
		return "kk"
	default:
		return "en"
	}
}

func normalizeStringList(values []string) []string {
	out := make([]string, 0, len(values))
	seen := map[string]struct{}{}
	for _, value := range values {
		value = strings.TrimSpace(value)
		if value == "" {
			continue
		}
		key := strings.ToLower(value)
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		out = append(out, value)
	}
	return out
}

func normalizeContentType(raw string, content []byte) string {
	raw = strings.ToLower(strings.TrimSpace(raw))
	if idx := strings.Index(raw, ";"); idx >= 0 {
		raw = strings.TrimSpace(raw[:idx])
	}
	if raw != "" {
		return raw
	}
	return strings.ToLower(http.DetectContentType(content))
}

func clampLimitWithDefault(limit int, fallback int) int {
	if limit <= 0 {
		return fallback
	}
	return clampLimit(limit)
}

func inputAuditMeta(input model.AttractionInput) map[string]any {
	return map[string]any{
		"title":       input.Title,
		"countryCode": input.CountryCode,
		"cityId":      input.CityID,
		"category":    input.Category,
		"status":      input.Status,
	}
}

func (u *AttractionContentUseCase) appendAttractionAudit(
	ctx context.Context,
	actor *model.StaffUser,
	action string,
	entityID uuid.UUID,
	before any,
	after any,
	metadata any,
	meta RequestMetadata,
) {
	if u.audit == nil || actor == nil {
		return
	}
	_ = u.audit.Append(ctx, &model.AuditEvent{
		ID:               uuid.New(),
		ActorStaffID:     &actor.ID,
		ActorDisplayName: actor.DisplayName,
		ActorEmail:       actor.Email,
		Action:           action,
		EntityType:       "attraction",
		EntityID:         &entityID,
		RequestID:        strings.TrimSpace(meta.RequestID),
		IPAddressHash:    HashPassiveIdentifier(meta.IPAddress),
		UserAgentHash:    HashPassiveIdentifier(meta.UserAgent),
		BeforeJSON:       attractionAuditJSON(before),
		AfterJSON:        attractionAuditJSON(after),
		Metadata:         attractionAuditJSON(metadata),
		CreatedAt:        time.Now().UTC(),
	})
}

func attractionAuditJSON(value any) json.RawMessage {
	if value == nil {
		return nil
	}
	raw, err := json.Marshal(value)
	if err != nil {
		return nil
	}
	return raw
}

func firstRequestMetadata(values []RequestMetadata) RequestMetadata {
	if len(values) == 0 {
		return RequestMetadata{}
	}
	return values[0]
}
