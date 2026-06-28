package app

import (
	"context"
	"encoding/json"
	"net/http"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
	"kz/inflap/backend/services/admin-panel/internal/domain/port"
)

const (
	defaultPlaceListLimit = 50
	defaultMaxPlaceImage  = int64(20 << 20)
)

type PlaceContentUseCase struct {
	places   port.PlaceAdminClient
	files    port.FileUploadClient
	audit    port.AuditRepository
	maxImage int64
}

type PlaceContentConfig struct {
	MaxImageBytes int64
}

type PlaceImageUploadInput struct {
	FileName    string
	ContentType string
	Content     []byte
	Metadata    RequestMetadata
}

type PlaceMediaAction string

const (
	PlaceMediaActionManage  PlaceMediaAction = "manage"
	PlaceMediaActionAppend  PlaceMediaAction = "append"
	PlaceMediaActionReplace PlaceMediaAction = "replace"
)

type PlaceMediaUpdateInput struct {
	Action           PlaceMediaAction
	ExistingMediaIDs []uuid.UUID
	DeleteMediaIDs   []uuid.UUID
	Uploads          []PlaceImageUploadInput
	Metadata         RequestMetadata
}

func NewPlaceContentUseCase(
	places port.PlaceAdminClient,
	files port.FileUploadClient,
	audit port.AuditRepository,
	cfg PlaceContentConfig,
) *PlaceContentUseCase {
	maxImage := cfg.MaxImageBytes
	if maxImage <= 0 {
		maxImage = defaultMaxPlaceImage
	}
	return &PlaceContentUseCase{
		places:   places,
		files:    files,
		audit:    audit,
		maxImage: maxImage,
	}
}

func (u *PlaceContentUseCase) ListPlaces(ctx context.Context, actor *model.StaffUser, filter model.AdminPlaceFilter) ([]model.AdminPlace, int, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionPlaceManage) {
		return nil, 0, ErrPermissionDenied
	}
	filter.Limit = clampLimitWithDefault(filter.Limit, defaultPlaceListLimit)
	filter.Offset = normalizeOffset(filter.Offset)
	filter.Search = strings.TrimSpace(filter.Search)
	filter.Locale = normalizeAdminLocale(filter.Locale)
	filter.CountryCode = strings.ToUpper(strings.TrimSpace(filter.CountryCode))
	filter.CityID = strings.ToLower(strings.TrimSpace(filter.CityID))
	filter.Category = strings.ToUpper(strings.TrimSpace(filter.Category))
	filter.Status = strings.ToUpper(strings.TrimSpace(filter.Status))
	filter.IncludeDeleted = true
	return u.places.ListPlaces(ctx, filter)
}

func (u *PlaceContentUseCase) GetPlace(ctx context.Context, actor *model.StaffUser, id uuid.UUID) (*model.AdminPlace, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionPlaceManage) {
		return nil, ErrPermissionDenied
	}
	if id == uuid.Nil {
		return nil, ErrInvalidInput
	}
	item, err := u.places.GetPlace(ctx, id)
	if err != nil {
		return nil, err
	}
	if item == nil {
		return nil, ErrPlaceNotFound
	}
	return item, nil
}

func (u *PlaceContentUseCase) CreatePlace(ctx context.Context, actor *model.StaffUser, input model.PlaceInput, metadata ...RequestMetadata) (*model.AdminPlace, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionPlaceManage) {
		return nil, ErrPermissionDenied
	}
	normalized, err := normalizePlaceInput(input)
	if err != nil {
		return nil, err
	}
	item, err := u.places.CreatePlace(ctx, normalized)
	if err != nil {
		return nil, err
	}
	if item != nil {
		u.appendPlaceAudit(ctx, actor, "place.created", item.ID, input, item, inputAuditMeta(input), firstRequestMetadata(metadata))
	}
	return item, nil
}

func (u *PlaceContentUseCase) UpdatePlace(ctx context.Context, actor *model.StaffUser, id uuid.UUID, input model.PlaceInput, meta RequestMetadata) (*model.AdminPlace, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionPlaceManage) {
		return nil, ErrPermissionDenied
	}
	if id == uuid.Nil {
		return nil, ErrInvalidInput
	}
	before, _ := u.places.GetPlace(ctx, id)
	normalized, err := normalizePlaceInput(input)
	if err != nil {
		return nil, err
	}
	item, err := u.places.UpdatePlace(ctx, id, normalized)
	if err != nil {
		return nil, err
	}
	u.appendPlaceAudit(ctx, actor, "place.updated", id, before, item, inputAuditMeta(input), meta)
	return item, nil
}

func (u *PlaceContentUseCase) ReplaceCoverImage(ctx context.Context, actor *model.StaffUser, placeID uuid.UUID, input PlaceImageUploadInput) error {
	return u.ReplaceCarouselImages(ctx, actor, placeID, []PlaceImageUploadInput{input})
}

func (u *PlaceContentUseCase) ReplaceCarouselImages(ctx context.Context, actor *model.StaffUser, placeID uuid.UUID, inputs []PlaceImageUploadInput) error {
	if actor == nil || !actor.HasPermission(enum.PermissionPlaceManage) {
		return ErrPermissionDenied
	}
	if placeID == uuid.Nil {
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
	place, err := u.places.GetPlace(ctx, placeID)
	if err != nil {
		return err
	}
	if place == nil {
		return ErrPlaceNotFound
	}

	media := make([]model.PlaceMediaInput, 0, len(inputs))
	fileIDs := make([]uuid.UUID, 0, len(inputs))
	fileNames := make([]string, 0, len(inputs))
	for position, input := range inputs {
		uploaded, uploadErr := u.files.UploadPublicPlaceImage(ctx, model.FileUploadInput{
			FileName:    strings.TrimSpace(input.FileName),
			ContentType: normalizeContentType(input.ContentType, input.Content),
			Content:     input.Content,
			Purpose:     "PLACE_MEDIA",
			Visibility:  "PUBLIC",
			OwnerType:   "PLACE",
			OwnerID:     placeID,
		})
		if uploadErr != nil {
			return uploadErr
		}
		if uploaded == nil || uploaded.ID == uuid.Nil {
			return ErrInvalidInput
		}
		media = append(media, model.PlaceMediaInput{
			FileID:    uploaded.ID,
			MediaType: "PHOTO",
			Position:  position,
		})
		fileIDs = append(fileIDs, uploaded.ID)
		fileNames = append(fileNames, strings.TrimSpace(input.FileName))
	}
	if err = u.places.ReplaceMedia(ctx, placeID, media); err != nil {
		return err
	}
	u.appendPlaceAudit(ctx, actor, "place.media.replaced", placeID, place.Media, media, map[string]any{
		"fileNames": fileNames,
		"fileIds":   fileIDs,
	}, metadata)
	return nil
}

func (u *PlaceContentUseCase) UpdateCarouselImages(ctx context.Context, actor *model.StaffUser, placeID uuid.UUID, input PlaceMediaUpdateInput) error {
	if actor == nil || !actor.HasPermission(enum.PermissionPlaceManage) {
		return ErrPermissionDenied
	}
	if placeID == uuid.Nil {
		return ErrInvalidInput
	}
	action := normalizePlaceMediaAction(input.Action)
	if action == "" {
		return ErrInvalidInput
	}
	if action == PlaceMediaActionManage && len(input.Uploads) > 0 {
		return ErrInvalidInput
	}
	if (action == PlaceMediaActionAppend || action == PlaceMediaActionReplace) && len(input.Uploads) == 0 {
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

	place, err := u.places.GetPlace(ctx, placeID)
	if err != nil {
		return err
	}
	if place == nil {
		return ErrPlaceNotFound
	}

	finalMedia := make([]model.PlaceMediaInput, 0, len(place.Media)+len(input.Uploads))
	deleteIDs := uuidSet(input.DeleteMediaIDs)
	if action != PlaceMediaActionReplace {
		existing, existingErr := orderedExistingPlaceMedia(place.Media, input.ExistingMediaIDs, deleteIDs)
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
		uploaded, uploadErr := u.files.UploadPublicPlaceImage(ctx, model.FileUploadInput{
			FileName:    strings.TrimSpace(upload.FileName),
			ContentType: normalizeContentType(upload.ContentType, upload.Content),
			Content:     upload.Content,
			Purpose:     "PLACE_MEDIA",
			Visibility:  "PUBLIC",
			OwnerType:   "PLACE",
			OwnerID:     placeID,
		})
		if uploadErr != nil {
			return uploadErr
		}
		if uploaded == nil || uploaded.ID == uuid.Nil {
			return ErrInvalidInput
		}
		finalMedia = append(finalMedia, model.PlaceMediaInput{
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
	if err = u.places.ReplaceMedia(ctx, placeID, finalMedia); err != nil {
		return err
	}
	u.appendPlaceAudit(ctx, actor, "place.media.updated", placeID, place.Media, finalMedia, map[string]any{
		"action":          action,
		"fileNames":       fileNames,
		"fileIds":         fileIDs,
		"deletedMediaIds": input.DeleteMediaIDs,
	}, input.Metadata)
	return nil
}

func (u *PlaceContentUseCase) GetPublicImageContent(ctx context.Context, actor *model.StaffUser, fileID uuid.UUID) (*model.FileContent, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionPlaceManage) {
		return nil, ErrPermissionDenied
	}
	if fileID == uuid.Nil {
		return nil, ErrInvalidInput
	}
	return u.files.GetPublicContent(ctx, fileID)
}

func (u *PlaceContentUseCase) StartMediaBackfill(ctx context.Context, actor *model.StaffUser, countryCode string, meta RequestMetadata) (model.PlaceMediaBackfillJob, error) {
	if actor == nil || !actor.HasRole(enum.StaffRoleSuperAdmin) || !actor.HasPermission(enum.PermissionPlaceManage) {
		return model.PlaceMediaBackfillJob{}, ErrPermissionDenied
	}
	countryCode = strings.ToUpper(strings.TrimSpace(countryCode))
	if len(countryCode) != 2 {
		return model.PlaceMediaBackfillJob{}, ErrInvalidInput
	}
	job, err := u.places.StartMediaBackfill(ctx, countryCode)
	if err != nil {
		return model.PlaceMediaBackfillJob{}, err
	}
	u.appendPlaceAudit(ctx, actor, "place.media.backfill.started", uuid.Nil, nil, job, map[string]any{
		"countryCode": countryCode,
		"jobId":       job.JobID,
		"status":      job.Status,
	}, meta)
	return job, nil
}

func (u *PlaceContentUseCase) validateImageUpload(input PlaceImageUploadInput) error {
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

func normalizePlaceMediaAction(action PlaceMediaAction) PlaceMediaAction {
	switch PlaceMediaAction(strings.ToLower(strings.TrimSpace(string(action)))) {
	case "", PlaceMediaActionManage:
		return PlaceMediaActionManage
	case PlaceMediaActionAppend:
		return PlaceMediaActionAppend
	case PlaceMediaActionReplace:
		return PlaceMediaActionReplace
	default:
		return ""
	}
}

func orderedExistingPlaceMedia(media []model.AdminPlaceMedia, order []uuid.UUID, deleteIDs map[uuid.UUID]struct{}) ([]model.PlaceMediaInput, error) {
	byID := make(map[uuid.UUID]model.AdminPlaceMedia, len(media))
	for _, item := range media {
		if item.ID != uuid.Nil {
			byID[item.ID] = item
		}
	}
	ordered := make([]model.AdminPlaceMedia, 0, len(media))
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

	out := make([]model.PlaceMediaInput, 0, len(ordered))
	for _, item := range ordered {
		if _, deleted := deleteIDs[item.ID]; deleted {
			continue
		}
		out = append(out, model.PlaceMediaInput{
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

func normalizePlaceInput(input model.PlaceInput) (model.PlaceInput, error) {
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
		input.Translations = map[string]model.PlaceTranslation{}
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

func normalizeCityLinks(items []model.PlaceCityLink, fallbackCountry string) []model.PlaceCityLink {
	out := make([]model.PlaceCityLink, 0, len(items))
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
		out = append(out, model.PlaceCityLink{CountryCode: country, CityID: cityID})
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

func inputAuditMeta(input model.PlaceInput) map[string]any {
	return map[string]any{
		"title":       input.Title,
		"countryCode": input.CountryCode,
		"cityId":      input.CityID,
		"category":    input.Category,
		"status":      input.Status,
	}
}

func (u *PlaceContentUseCase) appendPlaceAudit(
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
		EntityType:       "place",
		EntityID:         &entityID,
		RequestID:        strings.TrimSpace(meta.RequestID),
		IPAddressHash:    HashPassiveIdentifier(meta.IPAddress),
		UserAgentHash:    HashPassiveIdentifier(meta.UserAgent),
		BeforeJSON:       placeAuditJSON(before),
		AfterJSON:        placeAuditJSON(after),
		Metadata:         placeAuditJSON(metadata),
		CreatedAt:        time.Now().UTC(),
	})
}

func placeAuditJSON(value any) json.RawMessage {
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
