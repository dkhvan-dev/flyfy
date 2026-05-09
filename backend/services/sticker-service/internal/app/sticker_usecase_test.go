package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/sticker-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/sticker-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/sticker-service/internal/domain/port"
)

func TestGetMyPacksReturnsDefaultAndInstalledPacks(t *testing.T) {
	ctx := context.Background()
	userID := uuid.New()
	repo := newFakeStickerRepository(t)
	files := &fakeFileManagerClient{}
	useCase := NewStickerUseCase(repo, files)

	systemPack := mustPack(t, model.NewStickerPackParams{
		Slug:       "flyfy-default",
		Type:       enum.PackTypeSystem,
		Visibility: enum.PackVisibilityPublic,
		Status:     enum.PackStatusActive,
		Title:      map[string]string{"en": "FlyFy"},
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
		Slug:       "flyfy-default",
		Type:       enum.PackTypeSystem,
		Visibility: enum.PackVisibilityPublic,
		Status:     enum.PackStatusActive,
		Title:      map[string]string{"en": "FlyFy"},
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

type fakeStickerRepository struct {
	t            *testing.T
	packs        map[uuid.UUID]*model.StickerPack
	stickers     map[uuid.UUID]*model.Sticker
	defaultPacks []*model.StickerPackWithStickers
	userPacks    map[uuid.UUID][]*model.StickerPackWithStickers
	customPacks  map[uuid.UUID]*model.StickerPack
	sessions     map[uuid.UUID]*model.UploadSession
	installed    map[uuid.UUID]map[uuid.UUID]bool
}

func newFakeStickerRepository(t *testing.T) *fakeStickerRepository {
	t.Helper()
	return &fakeStickerRepository{
		t:           t,
		packs:       map[uuid.UUID]*model.StickerPack{},
		stickers:    map[uuid.UUID]*model.Sticker{},
		userPacks:   map[uuid.UUID][]*model.StickerPackWithStickers{},
		customPacks: map[uuid.UUID]*model.StickerPack{},
		sessions:    map[uuid.UUID]*model.UploadSession{},
		installed:   map[uuid.UUID]map[uuid.UUID]bool{},
	}
}

func (r *fakeStickerRepository) ListDefaultPacks(context.Context) ([]*model.StickerPackWithStickers, error) {
	return r.defaultPacks, nil
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

func mustUploadSession(t testing.TB, params model.NewUploadSessionParams) *model.UploadSession {
	t.Helper()
	session, err := model.NewUploadSession(params)
	if err != nil {
		t.Fatalf("NewUploadSession error: %v", err)
	}
	return session
}
