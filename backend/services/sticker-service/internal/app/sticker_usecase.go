package app

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/sticker-service/internal/domain/enum"
	"kz/inflap/backend/services/sticker-service/internal/domain/model"
	"kz/inflap/backend/services/sticker-service/internal/domain/port"
)

const defaultUploadSessionTTL = 15 * time.Minute

type StickerUseCase struct {
	repo           port.StickerRepository
	files          port.FileManagerClient
	postModeration bool
	uploadTTL      time.Duration
}

type StickerUseCaseOption func(*StickerUseCase)

func WithPostModeration(enabled bool) StickerUseCaseOption {
	return func(u *StickerUseCase) {
		u.postModeration = enabled
	}
}

func WithUploadSessionTTL(ttl time.Duration) StickerUseCaseOption {
	return func(u *StickerUseCase) {
		if ttl > 0 {
			u.uploadTTL = ttl
		}
	}
}

func NewStickerUseCase(
	repo port.StickerRepository,
	files port.FileManagerClient,
	options ...StickerUseCaseOption,
) *StickerUseCase {
	useCase := &StickerUseCase{
		repo:           repo,
		files:          files,
		postModeration: true,
		uploadTTL:      defaultUploadSessionTTL,
	}
	for _, option := range options {
		option(useCase)
	}
	return useCase
}

type CreateStickerUploadInput struct {
	UserID         string
	PackID         string
	OriginalName   string
	ContentType    string
	SizeBytes      int64
	IdempotencyKey *string
}

type CreateStickerUploadOutput struct {
	UploadSessionID uuid.UUID
	FileID          uuid.UUID
	Method          string
	URL             string
	Headers         map[string]string
	ExpiresAt       time.Time
}

type FinalizeStickerUploadInput struct {
	UserID          string
	PackID          string
	UploadSessionID string
	Emoji           *string
	Keywords        []string
}

type InstallStickerPackInput struct {
	UserID string
	PackID string
}

type RemoveStickerPackInput struct {
	UserID string
	PackID string
}

type ValidateStickerSendInput struct {
	SenderUserID string
	StickerID    string
}

type ValidateStickerSendOutput struct {
	StickerID      uuid.UUID
	PackID         uuid.UUID
	Slug           string
	FileID         uuid.UUID
	FallbackFileID uuid.UUID
	PreviewFileID  *uuid.UUID
	ContentType    string
	Width          int
	Height         int
	DurationMS     int
	Status         string
}

func (u *StickerUseCase) ListDefaultPacks(ctx context.Context) ([]*model.StickerPackWithStickers, error) {
	return u.repo.ListDefaultPacks(ctx)
}

type ListOfficialCatalogInput struct {
	Locale string
}

type OfficialCatalogOutput struct {
	Version int64
	Groups  []StickerGroupOutput
}

type StickerGroupOutput struct {
	ID    uuid.UUID
	Slug  string
	Title string
	Packs []StickerPackOutput
}

type StickerPackOutput struct {
	ID              uuid.UUID
	Slug            string
	Title           string
	Description     string
	Version         int
	ThumbnailFileID uuid.UUID
}

type ListPackStickersInput struct {
	UserID string
	PackID string
	Limit  int
	Offset int
}

type SearchOfficialStickersInput struct {
	UserID string
	Query  string
	Locale string
	Limit  int
	Offset int
}

type ListRecentStickersInput struct {
	UserID string
	Limit  int
}

type StickerListOutput struct {
	Stickers []StickerOutput
}

type StickerOutput struct {
	ID             uuid.UUID
	PackID         uuid.UUID
	Slug           string
	FileID         uuid.UUID
	FallbackFileID uuid.UUID
	PreviewFileID  *uuid.UUID
	Emoji          *string
	Keywords       []string
	Status         string
	ContentType    string
	Width          int
	Height         int
	DurationMS     int
	SortOrder      int
	CreatedAt      time.Time
	UpdatedAt      time.Time
}

func (u *StickerUseCase) ListOfficialCatalog(
	ctx context.Context,
	input ListOfficialCatalogInput,
) (*OfficialCatalogOutput, error) {
	version, err := u.repo.CatalogVersion(ctx)
	if err != nil {
		return nil, err
	}
	groups, err := u.repo.ListOfficialGroups(ctx)
	if err != nil {
		return nil, err
	}

	output := &OfficialCatalogOutput{
		Version: version.Version,
		Groups:  make([]StickerGroupOutput, 0, len(groups)),
	}
	for _, group := range groups {
		if group == nil {
			continue
		}
		packs, err := u.repo.ListActivePacksByGroup(ctx, group.ID)
		if err != nil {
			return nil, err
		}
		groupOutput := StickerGroupOutput{
			ID:    group.ID,
			Slug:  group.Slug,
			Title: localizedText(group.Title, input.Locale),
			Packs: make([]StickerPackOutput, 0, len(packs)),
		}
		for _, pack := range packs {
			if pack == nil {
				continue
			}
			groupOutput.Packs = append(groupOutput.Packs, mapPackOutput(pack, input.Locale))
		}
		output.Groups = append(output.Groups, groupOutput)
	}

	return output, nil
}

func (u *StickerUseCase) ListPackStickers(
	ctx context.Context,
	input ListPackStickersInput,
) (*StickerListOutput, error) {
	if _, err := parseUUID(input.UserID, ErrInvalidUserID); err != nil {
		return nil, err
	}
	packID, err := parseUUID(input.PackID, ErrInvalidPackID)
	if err != nil {
		return nil, err
	}

	pack, err := u.repo.GetPackByID(ctx, packID)
	if err != nil {
		return nil, err
	}
	if pack == nil || pack.Status != enum.PackStatusActive {
		return nil, ErrPackNotFound
	}
	if pack.Type != enum.PackTypeSystem || pack.Visibility != enum.PackVisibilityPublic {
		return nil, ErrPackNotFound
	}

	stickers, err := u.repo.ListActiveStickersByPack(
		ctx,
		packID,
		normalizeLimit(input.Limit, 50, 100),
		normalizeOffset(input.Offset),
	)
	if err != nil {
		return nil, err
	}

	return &StickerListOutput{Stickers: mapStickerOutputs(stickers)}, nil
}

func (u *StickerUseCase) SearchOfficialStickers(
	ctx context.Context,
	input SearchOfficialStickersInput,
) (*StickerListOutput, error) {
	if _, err := parseUUID(input.UserID, ErrInvalidUserID); err != nil {
		return nil, err
	}

	query := strings.TrimSpace(input.Query)
	if query == "" {
		return &StickerListOutput{Stickers: []StickerOutput{}}, nil
	}

	stickers, err := u.repo.SearchOfficialStickers(
		ctx,
		query,
		normalizeLimit(input.Limit, 50, 100),
		normalizeOffset(input.Offset),
	)
	if err != nil {
		return nil, err
	}

	return &StickerListOutput{Stickers: mapStickerOutputs(stickers)}, nil
}

func (u *StickerUseCase) ListRecentStickers(
	ctx context.Context,
	input ListRecentStickersInput,
) (*StickerListOutput, error) {
	userID, err := parseUUID(input.UserID, ErrInvalidUserID)
	if err != nil {
		return nil, err
	}

	stickers, err := u.repo.ListRecentStickers(
		ctx,
		userID,
		normalizeLimit(input.Limit, 40, 100),
	)
	if err != nil {
		return nil, err
	}
	return &StickerListOutput{Stickers: mapStickerOutputs(stickers)}, nil
}

func (u *StickerUseCase) ListMyPacks(ctx context.Context, userID string) ([]*model.StickerPackWithStickers, error) {
	parsedUserID, err := parseUUID(userID, ErrInvalidUserID)
	if err != nil {
		return nil, err
	}

	defaultPacks, err := u.repo.ListDefaultPacks(ctx)
	if err != nil {
		return nil, err
	}
	userPacks, err := u.repo.ListUserPacks(ctx, parsedUserID)
	if err != nil {
		return nil, err
	}

	result := make([]*model.StickerPackWithStickers, 0, len(defaultPacks)+len(userPacks))
	result = append(result, defaultPacks...)
	result = append(result, userPacks...)
	return result, nil
}

func (u *StickerUseCase) EnsureMyCustomPack(ctx context.Context, userID string) (*model.StickerPack, error) {
	parsedUserID, err := parseUUID(userID, ErrInvalidUserID)
	if err != nil {
		return nil, err
	}
	return u.repo.EnsureCustomPack(ctx, parsedUserID)
}

func (u *StickerUseCase) InstallPack(ctx context.Context, input InstallStickerPackInput) error {
	userID, err := parseUUID(input.UserID, ErrInvalidUserID)
	if err != nil {
		return err
	}
	packID, err := parseUUID(input.PackID, ErrInvalidPackID)
	if err != nil {
		return err
	}

	pack, err := u.repo.GetPackByID(ctx, packID)
	if err != nil {
		return err
	}
	if pack == nil || pack.Status == enum.PackStatusDeleted {
		return ErrPackNotFound
	}
	if !userCanInstallPack(userID, pack) {
		return ErrPackNotAccessible
	}

	return u.repo.InstallPack(ctx, userID, packID, string(enum.UserPackSourceInstalled))
}

func (u *StickerUseCase) RemovePack(ctx context.Context, input RemoveStickerPackInput) error {
	userID, err := parseUUID(input.UserID, ErrInvalidUserID)
	if err != nil {
		return err
	}
	packID, err := parseUUID(input.PackID, ErrInvalidPackID)
	if err != nil {
		return err
	}

	return u.repo.RemovePack(ctx, userID, packID)
}

func (u *StickerUseCase) CreateStickerUploadRequest(
	ctx context.Context,
	input CreateStickerUploadInput,
) (*CreateStickerUploadOutput, error) {
	userID, err := parseUUID(input.UserID, ErrInvalidUserID)
	if err != nil {
		return nil, err
	}
	packID, err := parseUUID(input.PackID, ErrInvalidPackID)
	if err != nil {
		return nil, err
	}

	pack, err := u.repo.GetPackByID(ctx, packID)
	if err != nil {
		return nil, err
	}
	if pack == nil || pack.Status == enum.PackStatusDeleted {
		return nil, ErrPackNotFound
	}
	if !userCanCreateStickerInPack(userID, pack) {
		return nil, ErrPackNotAccessible
	}

	upload, err := u.files.CreateStickerUploadRequest(ctx, port.CreateStickerUploadRequest{
		UserID:       userID,
		OriginalName: input.OriginalName,
		ContentType:  input.ContentType,
		SizeBytes:    input.SizeBytes,
	})
	if err != nil {
		return nil, err
	}

	session, err := model.NewUploadSession(model.NewUploadSessionParams{
		UserID:         userID,
		PackID:         packID,
		FileID:         upload.FileID,
		Status:         enum.UploadSessionStatusPending,
		IdempotencyKey: input.IdempotencyKey,
		ExpiresAt:      time.Now().UTC().Add(u.uploadTTL),
	})
	if err != nil {
		return nil, err
	}
	if err = u.repo.CreateUploadSession(ctx, session); err != nil {
		return nil, err
	}

	return &CreateStickerUploadOutput{
		UploadSessionID: session.ID,
		FileID:          upload.FileID,
		Method:          upload.Method,
		URL:             upload.URL,
		Headers:         upload.Headers,
		ExpiresAt:       upload.ExpiresAt,
	}, nil
}

func (u *StickerUseCase) FinalizeStickerUpload(
	ctx context.Context,
	input FinalizeStickerUploadInput,
) (*model.Sticker, error) {
	userID, err := parseUUID(input.UserID, ErrInvalidUserID)
	if err != nil {
		return nil, err
	}
	packID, err := parseUUID(input.PackID, ErrInvalidPackID)
	if err != nil {
		return nil, err
	}
	sessionID, err := parseUUID(input.UploadSessionID, ErrInvalidUploadSessionID)
	if err != nil {
		return nil, err
	}

	var created *model.Sticker
	err = u.repo.WithTx(ctx, func(repo port.StickerRepository) error {
		session, err := repo.GetUploadSessionForUpdate(ctx, sessionID)
		if err != nil {
			return err
		}
		if session == nil {
			return ErrUploadSessionNotFound
		}
		if session.UserID != userID || session.PackID != packID {
			return ErrPackNotAccessible
		}

		pack, err := repo.GetPackByID(ctx, packID)
		if err != nil {
			return err
		}
		if pack == nil || pack.Status == enum.PackStatusDeleted {
			return ErrPackNotFound
		}
		if !userCanCreateStickerInPack(userID, pack) {
			return ErrPackNotAccessible
		}

		existing, err := repo.GetStickerByPackAndFile(ctx, packID, session.FileID)
		if err != nil {
			return err
		}
		if existing != nil {
			created = existing
			return nil
		}

		if time.Now().UTC().After(session.ExpiresAt) {
			return ErrUploadSessionExpired
		}

		file, err := u.files.GetFile(ctx, session.FileID)
		if err != nil {
			return err
		}
		if file == nil || !strings.EqualFold(file.Status, "READY") {
			return ErrFileNotReady
		}
		if !isStickerContentType(file.ContentType) {
			return ErrUnsupportedMedia
		}
		if err = u.files.BindStickerFileToUser(ctx, session.FileID, userID); err != nil {
			return err
		}

		status := enum.StickerStatusInReview
		if u.postModeration {
			status = enum.StickerStatusActive
		}
		sticker, err := model.NewSticker(model.NewStickerParams{
			PackID:          packID,
			FileID:          session.FileID,
			Emoji:           input.Emoji,
			Keywords:        input.Keywords,
			Status:          status,
			CreatedByUserID: &userID,
		})
		if err != nil {
			return err
		}
		if err = repo.CreateSticker(ctx, sticker); err != nil {
			return err
		}
		created = sticker
		return nil
	})
	if err != nil {
		return nil, err
	}
	return created, nil
}

func (u *StickerUseCase) ValidateSend(
	ctx context.Context,
	input ValidateStickerSendInput,
) (*ValidateStickerSendOutput, error) {
	userID, err := parseUUID(input.SenderUserID, ErrInvalidUserID)
	if err != nil {
		return nil, err
	}
	stickerID, err := parseUUID(input.StickerID, ErrInvalidStickerID)
	if err != nil {
		return nil, err
	}

	sticker, err := u.repo.GetStickerByID(ctx, stickerID)
	if err != nil {
		return nil, err
	}
	if sticker == nil || sticker.Status == enum.StickerStatusDeleted {
		return nil, ErrStickerNotFound
	}
	if sticker.Status == enum.StickerStatusBlocked || sticker.Status == enum.StickerStatusRejected {
		return nil, ErrStickerBlocked
	}
	if sticker.Status != enum.StickerStatusActive {
		return nil, ErrStickerNotAccessible
	}

	allowed, err := u.repo.UserHasPackAccess(ctx, userID, sticker.PackID)
	if err != nil {
		return nil, err
	}
	if !allowed {
		return nil, ErrStickerNotAccessible
	}
	if err = u.repo.RecordStickerUsage(ctx, userID, stickerID); err != nil {
		return nil, err
	}

	return &ValidateStickerSendOutput{
		StickerID:      sticker.ID,
		PackID:         sticker.PackID,
		Slug:           sticker.Slug,
		FileID:         sticker.FileID,
		FallbackFileID: valueOrNilUUID(sticker.FallbackFileID),
		PreviewFileID:  sticker.PreviewFileID,
		ContentType:    sticker.ContentType,
		Width:          sticker.Width,
		Height:         sticker.Height,
		DurationMS:     sticker.DurationMS,
		Status:         string(sticker.Status),
	}, nil
}

func mapPackOutput(pack *model.StickerPack, locale string) StickerPackOutput {
	var thumbnailID uuid.UUID
	if pack.ThumbnailFileID != nil {
		thumbnailID = *pack.ThumbnailFileID
	}
	return StickerPackOutput{
		ID:              pack.ID,
		Slug:            pack.Slug,
		Title:           localizedText(pack.Title, locale),
		Description:     localizedText(pack.Description, locale),
		Version:         pack.Version,
		ThumbnailFileID: thumbnailID,
	}
}

func mapStickerOutputs(stickers []*model.Sticker) []StickerOutput {
	output := make([]StickerOutput, 0, len(stickers))
	for _, sticker := range stickers {
		if sticker == nil {
			continue
		}
		output = append(output, mapStickerOutput(sticker))
	}
	return output
}

func mapStickerOutput(sticker *model.Sticker) StickerOutput {
	return StickerOutput{
		ID:             sticker.ID,
		PackID:         sticker.PackID,
		Slug:           sticker.Slug,
		FileID:         sticker.FileID,
		FallbackFileID: valueOrNilUUID(sticker.FallbackFileID),
		PreviewFileID:  sticker.PreviewFileID,
		Emoji:          sticker.Emoji,
		Keywords:       sticker.Keywords,
		Status:         string(sticker.Status),
		ContentType:    sticker.ContentType,
		Width:          sticker.Width,
		Height:         sticker.Height,
		DurationMS:     sticker.DurationMS,
		SortOrder:      sticker.SortOrder,
		CreatedAt:      sticker.CreatedAt,
		UpdatedAt:      sticker.UpdatedAt,
	}
}

func localizedText(values map[string]string, locale string) string {
	locale = strings.ToLower(strings.TrimSpace(locale))
	if locale != "" {
		if value := strings.TrimSpace(values[locale]); value != "" {
			return value
		}
	}
	if value := strings.TrimSpace(values["en"]); value != "" {
		return value
	}
	for _, value := range values {
		if value = strings.TrimSpace(value); value != "" {
			return value
		}
	}
	return ""
}

func valueOrNilUUID(value *uuid.UUID) uuid.UUID {
	if value == nil {
		return uuid.Nil
	}
	return *value
}

func normalizeLimit(value, fallback, max int) int {
	if value <= 0 {
		return fallback
	}
	if value > max {
		return max
	}
	return value
}

func normalizeOffset(value int) int {
	if value < 0 {
		return 0
	}
	return value
}

func userCanCreateStickerInPack(userID uuid.UUID, pack *model.StickerPack) bool {
	if pack == nil || pack.Type != enum.PackTypeUserCustom {
		return false
	}
	return pack.OwnerUserID != nil && *pack.OwnerUserID == userID && pack.Status == enum.PackStatusActive
}

func userCanInstallPack(userID uuid.UUID, pack *model.StickerPack) bool {
	if pack == nil || pack.Status != enum.PackStatusActive {
		return false
	}
	if pack.Visibility == enum.PackVisibilityPublic {
		return true
	}
	return pack.OwnerUserID != nil && *pack.OwnerUserID == userID
}

func isStickerContentType(contentType string) bool {
	switch strings.ToLower(strings.TrimSpace(contentType)) {
	case "image/gif", "image/jpeg", "image/png", "image/webp":
		return true
	default:
		return false
	}
}

func parseUUID(raw string, invalidErr error) (uuid.UUID, error) {
	value, err := uuid.Parse(strings.TrimSpace(raw))
	if err != nil || value == uuid.Nil {
		return uuid.Nil, invalidErr
	}
	return value, nil
}
