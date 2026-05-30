package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/sticker-service/internal/domain/enum"
	"kz/inflap/backend/services/sticker-service/internal/domain/model"
	"kz/inflap/backend/services/sticker-service/internal/domain/port"
)

func TestGetMyPacksReturnsDefaultAndInstalledPacks(t *testing.T) {
	ctx := context.Background()
	userID := uuid.New()
	repo := newFakeStickerRepository(t)
	files := &fakeFileManagerClient{}
	useCase := NewStickerUseCase(repo, files)

	systemPack := mustPack(t, model.NewStickerPackParams{
		Slug:       "inflap-default",
		Type:       enum.PackTypeSystem,
		Visibility: enum.PackVisibilityPublic,
		Status:     enum.PackStatusActive,
		Title:      map[string]string{"en": "Inflap"},
	})
	customPack := mustPack(t, model.NewStickerPackParams{
		Slug:        "custom-" + userID.String(),
		Type:        enum.PackTypeUserCustom,
		Visibility:  enum.PackVisibilityPrivate,
		Status:      enum.PackStatusActive,
		OwnerUserID: &userID,
		Title:       map[string]string{"en": "My stickers"},
	})
	repo.defaultPacks = []*model.StickerPackWithStickers{{Pack: systemPack}}
	repo.userPacks[userID] = []*model.StickerPackWithStickers{{Pack: customPack}}

	packs, err := useCase.ListMyPacks(ctx, userID.String())
	if err != nil {
		t.Fatalf("ListMyPacks error: %v", err)
	}
	if len(packs) != 2 {
		t.Fatalf("expected 2 packs, got %d", len(packs))
	}
	if packs[0].Pack.ID != systemPack.ID || packs[1].Pack.ID != customPack.ID {
		t.Fatalf("unexpected pack order: %+v", packs)
	}
}

func TestEnsureCustomPackIsIdempotentPerUser(t *testing.T) {
	ctx := context.Background()
	userID := uuid.New()
	repo := newFakeStickerRepository(t)
	useCase := NewStickerUseCase(repo, &fakeFileManagerClient{})

	first, err := useCase.EnsureMyCustomPack(ctx, userID.String())
	if err != nil {
		t.Fatalf("first EnsureMyCustomPack error: %v", err)
	}
	second, err := useCase.EnsureMyCustomPack(ctx, userID.String())
	if err != nil {
		t.Fatalf("second EnsureMyCustomPack error: %v", err)
	}
	if first.ID != second.ID {
		t.Fatalf("expected idempotent custom pack, got %s and %s", first.ID, second.ID)
	}
}

func TestInstallPackRejectsPrivateForeignPack(t *testing.T) {
	ctx := context.Background()
	ownerID := uuid.New()
	actorID := uuid.New()
	repo := newFakeStickerRepository(t)
	privatePack := mustPack(t, model.NewStickerPackParams{
		Slug:        "custom-" + ownerID.String(),
		Type:        enum.PackTypeUserCustom,
		Visibility:  enum.PackVisibilityPrivate,
		Status:      enum.PackStatusActive,
		OwnerUserID: &ownerID,
		Title:       map[string]string{"en": "Owner stickers"},
	})
	repo.packs[privatePack.ID] = privatePack
	useCase := NewStickerUseCase(repo, &fakeFileManagerClient{})

	err := useCase.InstallPack(ctx, InstallStickerPackInput{
		UserID: actorID.String(),
		PackID: privatePack.ID.String(),
	})

	if !errors.Is(err, ErrPackNotAccessible) {
		t.Fatalf("expected ErrPackNotAccessible, got %v", err)
	}
}

func TestInstallPackPersistsManualUserPack(t *testing.T) {
	ctx := context.Background()
	actorID := uuid.New()
	repo := newFakeStickerRepository(t)
	publicPack := mustPack(t, model.NewStickerPackParams{
		Slug:       "travel-cats",
		Type:       enum.PackTypeSystem,
		Visibility: enum.PackVisibilityPublic,
		Status:     enum.PackStatusActive,
		Title:      map[string]string{"en": "Travel Cats"},
	})
	repo.packs[publicPack.ID] = publicPack
	useCase := NewStickerUseCase(repo, &fakeFileManagerClient{})

	if err := useCase.InstallPack(ctx, InstallStickerPackInput{
		UserID: actorID.String(),
		PackID: publicPack.ID.String(),
	}); err != nil {
		t.Fatalf("InstallPack error: %v", err)
	}

	if !repo.installed[actorID][publicPack.ID] {
		t.Fatalf("expected pack to be installed")
	}
}

func TestCreateUploadRequestRejectsPackOwnedByAnotherUser(t *testing.T) {
	ctx := context.Background()
	ownerID := uuid.New()
	actorID := uuid.New()
	repo := newFakeStickerRepository(t)
	foreignPack := mustPack(t, model.NewStickerPackParams{
		Slug:        "custom-" + ownerID.String(),
		Type:        enum.PackTypeUserCustom,
		Visibility:  enum.PackVisibilityPrivate,
		Status:      enum.PackStatusActive,
		OwnerUserID: &ownerID,
		Title:       map[string]string{"en": "Owner stickers"},
	})
	repo.packs[foreignPack.ID] = foreignPack
	useCase := NewStickerUseCase(repo, &fakeFileManagerClient{})

	_, err := useCase.CreateStickerUploadRequest(ctx, CreateStickerUploadInput{
		UserID:       actorID.String(),
		PackID:       foreignPack.ID.String(),
		OriginalName: "sticker.png",
		ContentType:  "image/png",
		SizeBytes:    1024,
	})

	if !errors.Is(err, ErrPackNotAccessible) {
		t.Fatalf("expected ErrPackNotAccessible, got %v", err)
	}
}

func TestFinalizeUploadReturnsExistingStickerForCompletedSession(t *testing.T) {
	ctx := context.Background()
	userID := uuid.New()
	fileID := uuid.New()
	repo := newFakeStickerRepository(t)
	files := &fakeFileManagerClient{}
	pack := mustPack(t, model.NewStickerPackParams{
		Slug:        "custom-" + userID.String(),
		Type:        enum.PackTypeUserCustom,
		Visibility:  enum.PackVisibilityPrivate,
		Status:      enum.PackStatusActive,
		OwnerUserID: &userID,
		Title:       map[string]string{"en": "My stickers"},
	})
	sticker := mustSticker(t, model.NewStickerParams{
		PackID:          pack.ID,
		FileID:          fileID,
		Status:          enum.StickerStatusActive,
		CreatedByUserID: &userID,
	})
	session := mustUploadSession(t, model.NewUploadSessionParams{
		UserID:    userID,
		PackID:    pack.ID,
		FileID:    fileID,
		Status:    enum.UploadSessionStatusPending,
		ExpiresAt: time.Now().UTC().Add(time.Minute),
	})
	repo.packs[pack.ID] = pack
	repo.stickers[sticker.ID] = sticker
	repo.sessions[session.ID] = session
	useCase := NewStickerUseCase(repo, files)

	result, err := useCase.FinalizeStickerUpload(ctx, FinalizeStickerUploadInput{
		UserID:          userID.String(),
		PackID:          pack.ID.String(),
		UploadSessionID: session.ID.String(),
	})

	if err != nil {
		t.Fatalf("FinalizeStickerUpload error: %v", err)
	}
	if result.ID != sticker.ID {
		t.Fatalf("expected existing sticker %s, got %s", sticker.ID, result.ID)
	}
	if files.bindCalls != 0 {
		t.Fatalf("expected no file rebind for completed session, got %d", files.bindCalls)
	}
}

func TestValidateSendRejectsPrivateStickerWithoutAccess(t *testing.T) {
	ctx := context.Background()
	ownerID := uuid.New()
	actorID := uuid.New()
	repo := newFakeStickerRepository(t)
	pack := mustPack(t, model.NewStickerPackParams{
		Slug:        "custom-" + ownerID.String(),
		Type:        enum.PackTypeUserCustom,
		Visibility:  enum.PackVisibilityPrivate,
		Status:      enum.PackStatusActive,
		OwnerUserID: &ownerID,
		Title:       map[string]string{"en": "Private"},
	})
	sticker := mustSticker(t, model.NewStickerParams{
		PackID: pack.ID,
		FileID: uuid.New(),
		Status: enum.StickerStatusActive,
	})
	repo.packs[pack.ID] = pack
	repo.stickers[sticker.ID] = sticker
	useCase := NewStickerUseCase(repo, &fakeFileManagerClient{})

	_, err := useCase.ValidateSend(ctx, ValidateStickerSendInput{
		SenderUserID: actorID.String(),
		StickerID:    sticker.ID.String(),
	})

	if !errors.Is(err, ErrStickerNotAccessible) {
		t.Fatalf("expected ErrStickerNotAccessible, got %v", err)
	}
}

func TestValidateSendAcceptsActiveDefaultSticker(t *testing.T) {
	ctx := context.Background()
	actorID := uuid.New()
	repo := newFakeStickerRepository(t)
	pack := mustPack(t, model.NewStickerPackParams{
		Slug:       "inflap-default",
		Type:       enum.PackTypeSystem,
		Visibility: enum.PackVisibilityPublic,
		Status:     enum.PackStatusActive,
		Title:      map[string]string{"en": "Inflap"},
	})
	sticker := mustSticker(t, model.NewStickerParams{
		PackID: pack.ID,
		FileID: uuid.New(),
		Status: enum.StickerStatusActive,
	})
	repo.packs[pack.ID] = pack
	repo.stickers[sticker.ID] = sticker
	useCase := NewStickerUseCase(repo, &fakeFileManagerClient{})

	result, err := useCase.ValidateSend(ctx, ValidateStickerSendInput{
		SenderUserID: actorID.String(),
		StickerID:    sticker.ID.String(),
	})

	if err != nil {
		t.Fatalf("ValidateSend error: %v", err)
	}
	if result.StickerID != sticker.ID || result.PackID != pack.ID || result.FileID != sticker.FileID {
		t.Fatalf("unexpected validate result: %+v", result)
	}
}

func TestListOfficialCatalogReturnsLocalizedGroupsAndActivePacks(t *testing.T) {
	ctx := context.Background()
	groupID := uuid.New()
	thumbnailID := uuid.New()
	repo := newFakeStickerRepository(t)
	repo.catalogVersion = 7
	repo.groups = []*model.StickerGroup{
		{
			ID:           groupID,
			Slug:         "travel",
			Title:        map[string]string{"en": "Travel", "ru": "Путешествия"},
			DisplayOrder: 1,
			Status:       enum.PackStatusActive,
		},
	}
	repo.groupPacks[groupID] = []*model.StickerPack{
		mustPack(t, model.NewStickerPackParams{
			GroupID:         &groupID,
			Slug:            "travel-basics",
			Type:            enum.PackTypeSystem,
			Visibility:      enum.PackVisibilityPublic,
			Status:          enum.PackStatusActive,
			IsOfficial:      true,
			Version:         3,
			ThumbnailFileID: &thumbnailID,
			Title:           map[string]string{"en": "Travel Basics", "ru": "Путешествие"},
		}),
	}
	useCase := NewStickerUseCase(repo, &fakeFileManagerClient{})

	catalog, err := useCase.ListOfficialCatalog(ctx, ListOfficialCatalogInput{Locale: "en"})

	if err != nil {
		t.Fatalf("ListOfficialCatalog error: %v", err)
	}
	if catalog.Version != 7 {
		t.Fatalf("expected catalog version 7, got %d", catalog.Version)
	}
	if len(catalog.Groups) != 1 {
		t.Fatalf("expected 1 group, got %d", len(catalog.Groups))
	}
	if catalog.Groups[0].Slug != "travel" || catalog.Groups[0].Title != "Travel" {
		t.Fatalf("unexpected group: %+v", catalog.Groups[0])
	}
	if len(catalog.Groups[0].Packs) != 1 {
		t.Fatalf("expected 1 pack, got %d", len(catalog.Groups[0].Packs))
	}
	if catalog.Groups[0].Packs[0].Slug != "travel-basics" ||
		catalog.Groups[0].Packs[0].Title != "Travel Basics" ||
		catalog.Groups[0].Packs[0].Version != 3 ||
		catalog.Groups[0].Packs[0].ThumbnailFileID != thumbnailID {
		t.Fatalf("unexpected pack: %+v", catalog.Groups[0].Packs[0])
	}
}

func TestListPackStickersReturnsExpandedAssetMetadata(t *testing.T) {
	ctx := context.Background()
	actorID := uuid.New()
	fallbackID := uuid.New()
	pack := mustPack(t, model.NewStickerPackParams{
		Slug:       "travel-basics",
		Type:       enum.PackTypeSystem,
		Visibility: enum.PackVisibilityPublic,
		Status:     enum.PackStatusActive,
		IsOfficial: true,
		Title:      map[string]string{"en": "Travel Basics"},
	})
	sticker := mustSticker(t, model.NewStickerParams{
		PackID:         pack.ID,
		Slug:           "boarding-pass",
		FileID:         uuid.New(),
		FallbackFileID: &fallbackID,
		Emoji:          ptrString("✈️"),
		Keywords:       []string{"flight"},
		Status:         enum.StickerStatusActive,
		ContentType:    "image/png",
		Width:          512,
		Height:         512,
		DurationMS:     1200,
		SizeBytes:      42000,
	})
	repo := newFakeStickerRepository(t)
	repo.packs[pack.ID] = pack
	repo.packStickers[pack.ID] = []*model.Sticker{sticker}
	useCase := NewStickerUseCase(repo, &fakeFileManagerClient{})

	result, err := useCase.ListPackStickers(ctx, ListPackStickersInput{
		UserID: actorID.String(),
		PackID: pack.ID.String(),
		Limit:  20,
	})

	if err != nil {
		t.Fatalf("ListPackStickers error: %v", err)
	}
	if len(result.Stickers) != 1 {
		t.Fatalf("expected 1 sticker, got %d", len(result.Stickers))
	}
	got := result.Stickers[0]
	if got.Slug != "boarding-pass" ||
		got.FallbackFileID != fallbackID ||
		got.ContentType != "image/png" ||
		got.Width != 512 ||
		got.Height != 512 ||
		got.DurationMS != 1200 {
		t.Fatalf("unexpected sticker metadata: %+v", got)
	}
}

func TestSearchOfficialStickersMatchesQuery(t *testing.T) {
	ctx := context.Background()
	actorID := uuid.New()
	sticker := mustSticker(t, model.NewStickerParams{
		PackID:      uuid.New(),
		Slug:        "coffee-break",
		FileID:      uuid.New(),
		Emoji:       ptrString("☕"),
		Keywords:    []string{"coffee"},
		Status:      enum.StickerStatusActive,
		ContentType: "image/png",
		Width:       512,
		Height:      512,
		DurationMS:  1000,
		SizeBytes:   32000,
	})
	repo := newFakeStickerRepository(t)
	repo.searchStickers = []*model.Sticker{sticker}
	useCase := NewStickerUseCase(repo, &fakeFileManagerClient{})

	result, err := useCase.SearchOfficialStickers(ctx, SearchOfficialStickersInput{
		UserID: actorID.String(),
		Query:  "coffee",
		Locale: "en",
		Limit:  20,
	})

	if err != nil {
		t.Fatalf("SearchOfficialStickers error: %v", err)
	}
	if len(result.Stickers) != 1 || result.Stickers[0].Slug != "coffee-break" {
		t.Fatalf("unexpected search result: %+v", result.Stickers)
	}
}

func TestValidateSendReturnsStickerPayloadWithFallbackMetadata(t *testing.T) {
	ctx := context.Background()
	actorID := uuid.New()
	fallbackID := uuid.New()
	previewID := uuid.New()
	repo := newFakeStickerRepository(t)
	pack := mustPack(t, model.NewStickerPackParams{
		Slug:       "inflap-default",
		Type:       enum.PackTypeSystem,
		Visibility: enum.PackVisibilityPublic,
		Status:     enum.PackStatusActive,
		Title:      map[string]string{"en": "Inflap"},
	})
	sticker := mustSticker(t, model.NewStickerParams{
		PackID:         pack.ID,
		Slug:           "boarding-pass",
		FileID:         uuid.New(),
		FallbackFileID: &fallbackID,
		PreviewFileID:  &previewID,
		Status:         enum.StickerStatusActive,
		ContentType:    "application/json",
		Width:          512,
		Height:         512,
		DurationMS:     1800,
		SizeBytes:      42000,
		Checksum:       "sha256:test",
	})
	repo.packs[pack.ID] = pack
	repo.stickers[sticker.ID] = sticker
	useCase := NewStickerUseCase(repo, &fakeFileManagerClient{})

	result, err := useCase.ValidateSend(ctx, ValidateStickerSendInput{
		SenderUserID: actorID.String(),
		StickerID:    sticker.ID.String(),
	})

	if err != nil {
		t.Fatalf("ValidateSend error: %v", err)
	}
	if result.Slug != "boarding-pass" ||
		result.FallbackFileID != fallbackID ||
		result.PreviewFileID == nil ||
		*result.PreviewFileID != previewID ||
		result.ContentType != "application/json" ||
		result.Width != 512 ||
		result.Height != 512 ||
		result.DurationMS != 1800 {
		t.Fatalf("unexpected validate result: %+v", result)
	}
}

func TestValidateSendRecordsRecentStickerUsage(t *testing.T) {
	ctx := context.Background()
	actorID := uuid.New()
	repo := newFakeStickerRepository(t)
	pack := mustPack(t, model.NewStickerPackParams{
		Slug:       "inflap-default",
		Type:       enum.PackTypeSystem,
		Visibility: enum.PackVisibilityPublic,
		Status:     enum.PackStatusActive,
		Title:      map[string]string{"en": "Inflap"},
	})
	sticker := mustSticker(t, model.NewStickerParams{
		PackID: pack.ID,
		FileID: uuid.New(),
		Status: enum.StickerStatusActive,
	})
	repo.packs[pack.ID] = pack
	repo.stickers[sticker.ID] = sticker
	useCase := NewStickerUseCase(repo, &fakeFileManagerClient{})

	_, err := useCase.ValidateSend(ctx, ValidateStickerSendInput{
		SenderUserID: actorID.String(),
		StickerID:    sticker.ID.String(),
	})

	if err != nil {
		t.Fatalf("ValidateSend error: %v", err)
	}
	if repo.recordedRecentUserID != actorID || repo.recordedRecentStickerID != sticker.ID {
		t.Fatalf(
			"recent usage = user %s sticker %s, want user %s sticker %s",
			repo.recordedRecentUserID,
			repo.recordedRecentStickerID,
			actorID,
			sticker.ID,
		)
	}
}

type fakeStickerRepository struct {
	t                       *testing.T
	packs                   map[uuid.UUID]*model.StickerPack
	stickers                map[uuid.UUID]*model.Sticker
	defaultPacks            []*model.StickerPackWithStickers
	groups                  []*model.StickerGroup
	groupPacks              map[uuid.UUID][]*model.StickerPack
	packStickers            map[uuid.UUID][]*model.Sticker
	searchStickers          []*model.Sticker
	recentStickers          []*model.Sticker
	recordedRecentUserID    uuid.UUID
	recordedRecentStickerID uuid.UUID
	userPacks               map[uuid.UUID][]*model.StickerPackWithStickers
	customPacks             map[uuid.UUID]*model.StickerPack
	sessions                map[uuid.UUID]*model.UploadSession
	installed               map[uuid.UUID]map[uuid.UUID]bool
	catalogVersion          int64
}

func newFakeStickerRepository(t *testing.T) *fakeStickerRepository {
	t.Helper()
	return &fakeStickerRepository{
		t:            t,
		packs:        map[uuid.UUID]*model.StickerPack{},
		stickers:     map[uuid.UUID]*model.Sticker{},
		groupPacks:   map[uuid.UUID][]*model.StickerPack{},
		packStickers: map[uuid.UUID][]*model.Sticker{},
		userPacks:    map[uuid.UUID][]*model.StickerPackWithStickers{},
		customPacks:  map[uuid.UUID]*model.StickerPack{},
		sessions:     map[uuid.UUID]*model.UploadSession{},
		installed:    map[uuid.UUID]map[uuid.UUID]bool{},
	}
}

func (r *fakeStickerRepository) ListDefaultPacks(context.Context) ([]*model.StickerPackWithStickers, error) {
	return r.defaultPacks, nil
}

func (r *fakeStickerRepository) ListOfficialGroups(context.Context) ([]*model.StickerGroup, error) {
	return r.groups, nil
}

func (r *fakeStickerRepository) ListActivePacksByGroup(_ context.Context, groupID uuid.UUID) ([]*model.StickerPack, error) {
	return r.groupPacks[groupID], nil
}

func (r *fakeStickerRepository) CatalogVersion(context.Context) (port.CatalogVersion, error) {
	return port.CatalogVersion{Version: r.catalogVersion, UpdatedAt: time.Now().UTC()}, nil
}

func (r *fakeStickerRepository) ListActiveStickersByPack(
	_ context.Context,
	packID uuid.UUID,
	_, _ int,
) ([]*model.Sticker, error) {
	return r.packStickers[packID], nil
}

func (r *fakeStickerRepository) SearchOfficialStickers(
	context.Context,
	string,
	int,
	int,
) ([]*model.Sticker, error) {
	return r.searchStickers, nil
}

func (r *fakeStickerRepository) RecordStickerUsage(_ context.Context, userID uuid.UUID, stickerID uuid.UUID) error {
	r.recordedRecentUserID = userID
	r.recordedRecentStickerID = stickerID
	return nil
}

func (r *fakeStickerRepository) ListRecentStickers(
	_ context.Context,
	_ uuid.UUID,
	_ int,
) ([]*model.Sticker, error) {
	return r.recentStickers, nil
}

func (r *fakeStickerRepository) ListUserPacks(_ context.Context, userID uuid.UUID) ([]*model.StickerPackWithStickers, error) {
	return r.userPacks[userID], nil
}

func (r *fakeStickerRepository) GetPackByID(_ context.Context, packID uuid.UUID) (*model.StickerPack, error) {
	return r.packs[packID], nil
}

func (r *fakeStickerRepository) GetStickerByID(_ context.Context, stickerID uuid.UUID) (*model.Sticker, error) {
	return r.stickers[stickerID], nil
}

func (r *fakeStickerRepository) EnsureCustomPack(_ context.Context, userID uuid.UUID) (*model.StickerPack, error) {
	if pack := r.customPacks[userID]; pack != nil {
		return pack, nil
	}
	pack := mustPack(r.t, model.NewStickerPackParams{
		Slug:        "custom-" + userID.String(),
		Type:        enum.PackTypeUserCustom,
		Visibility:  enum.PackVisibilityPrivate,
		Status:      enum.PackStatusActive,
		OwnerUserID: &userID,
		Title:       map[string]string{"en": "My stickers"},
	})
	r.customPacks[userID] = pack
	r.packs[pack.ID] = pack
	return pack, nil
}

func (r *fakeStickerRepository) InstallPack(_ context.Context, userID uuid.UUID, packID uuid.UUID, _ string) error {
	if r.installed[userID] == nil {
		r.installed[userID] = map[uuid.UUID]bool{}
	}
	r.installed[userID][packID] = true
	return nil
}

func (r *fakeStickerRepository) RemovePack(_ context.Context, userID uuid.UUID, packID uuid.UUID) error {
	delete(r.installed[userID], packID)
	return nil
}

func (r *fakeStickerRepository) CreateUploadSession(_ context.Context, session *model.UploadSession) error {
	r.sessions[session.ID] = session
	return nil
}

func (r *fakeStickerRepository) GetUploadSessionForUpdate(_ context.Context, sessionID uuid.UUID) (*model.UploadSession, error) {
	return r.sessions[sessionID], nil
}

func (r *fakeStickerRepository) CreateSticker(_ context.Context, sticker *model.Sticker) error {
	r.stickers[sticker.ID] = sticker
	return nil
}

func (r *fakeStickerRepository) GetStickerByPackAndFile(
	_ context.Context,
	packID uuid.UUID,
	fileID uuid.UUID,
) (*model.Sticker, error) {
	for _, sticker := range r.stickers {
		if sticker.PackID == packID && sticker.FileID == fileID && sticker.Status != enum.StickerStatusDeleted {
			return sticker, nil
		}
	}
	return nil, nil
}

func (r *fakeStickerRepository) UserHasPackAccess(_ context.Context, userID, packID uuid.UUID) (bool, error) {
	pack := r.packs[packID]
	if pack == nil {
		return false, nil
	}
	if pack.Type == enum.PackTypeSystem && pack.Visibility == enum.PackVisibilityPublic {
		return true, nil
	}
	if pack.OwnerUserID != nil && *pack.OwnerUserID == userID {
		return true, nil
	}
	for _, item := range r.userPacks[userID] {
		if item.Pack.ID == packID {
			return true, nil
		}
	}
	return false, nil
}

func (r *fakeStickerRepository) WithTx(ctx context.Context, fn func(repo port.StickerRepository) error) error {
	return fn(r)
}

type fakeFileManagerClient struct {
	fileID    uuid.UUID
	bindCalls int
}

func (c *fakeFileManagerClient) CreateStickerUploadRequest(context.Context, port.CreateStickerUploadRequest) (*port.CreateStickerUploadResponse, error) {
	fileID := c.fileID
	if fileID == uuid.Nil {
		fileID = uuid.New()
	}
	return &port.CreateStickerUploadResponse{
		FileID:    fileID,
		Method:    "PUT",
		URL:       "https://storage.local/upload",
		Headers:   map[string]string{"Content-Type": "image/png"},
		ExpiresAt: time.Now().UTC().Add(10 * time.Minute),
	}, nil
}

func (c *fakeFileManagerClient) GetFile(context.Context, uuid.UUID) (*port.FileMetadata, error) {
	return &port.FileMetadata{Status: "READY", ContentType: "image/png", SizeBytes: 1024}, nil
}

func (c *fakeFileManagerClient) BindStickerFileToUser(context.Context, uuid.UUID, uuid.UUID) error {
	c.bindCalls++
	return nil
}

func mustPack(t testing.TB, params model.NewStickerPackParams) *model.StickerPack {
	t.Helper()
	pack, err := model.NewStickerPack(params)
	if err != nil {
		t.Fatalf("NewStickerPack error: %v", err)
	}
	return pack
}

func mustSticker(t testing.TB, params model.NewStickerParams) *model.Sticker {
	t.Helper()
	sticker, err := model.NewSticker(params)
	if err != nil {
		t.Fatalf("NewSticker error: %v", err)
	}
	return sticker
}

func ptrString(value string) *string {
	return &value
}

func mustUploadSession(t testing.TB, params model.NewUploadSessionParams) *model.UploadSession {
	t.Helper()
	session, err := model.NewUploadSession(params)
	if err != nil {
		t.Fatalf("NewUploadSession error: %v", err)
	}
	return session
}
