package http

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/sticker-service/internal/app"
	"kz/inflap/backend/services/sticker-service/internal/domain/enum"
	"kz/inflap/backend/services/sticker-service/internal/domain/model"
)

func TestListMyPacksRequiresUserContext(t *testing.T) {
	handler := NewHandler(&fakeStickerUseCase{}, "internal-token")
	mux := http.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(http.MethodGet, "/v1/sticker-packs/my", nil)
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", rec.Code)
	}
}

func TestListOfficialCatalogRequiresUserContext(t *testing.T) {
	handler := NewHandler(&fakeStickerUseCase{}, "internal-token")
	mux := http.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(http.MethodGet, "/v1/stickers/catalog", nil)
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", rec.Code)
	}
}

func TestListOfficialCatalogReturnsGroups(t *testing.T) {
	userID := uuid.New()
	groupID := uuid.New()
	packID := uuid.New()
	thumbnailID := uuid.New()
	useCase := &fakeStickerUseCase{
		catalogOutput: &app.OfficialCatalogOutput{
			Version: 12,
			Groups: []app.StickerGroupOutput{
				{
					ID:    groupID,
					Slug:  "travel",
					Title: "Travel",
					Packs: []app.StickerPackOutput{
						{
							ID:              packID,
							Slug:            "travel-basics",
							Title:           "Travel Basics",
							Description:     "Trip essentials",
							Version:         3,
							ThumbnailFileID: thumbnailID,
						},
					},
				},
			},
		},
	}
	handler := NewHandler(useCase, "internal-token")
	mux := http.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(http.MethodGet, "/v1/stickers/catalog?locale=en", nil)
	req = req.WithContext(withUserID(req.Context(), userID.String()))
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d body=%s", rec.Code, rec.Body.String())
	}
	if useCase.catalogLocale != "en" {
		t.Fatalf("expected locale en, got %q", useCase.catalogLocale)
	}

	var response officialCatalogResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &response); err != nil {
		t.Fatalf("unmarshal response: %v", err)
	}
	if response.Version != 12 || len(response.Groups) != 1 {
		t.Fatalf("unexpected catalog response: %+v", response)
	}
	if response.Groups[0].Slug != "travel" || response.Groups[0].Packs[0].Slug != "travel-basics" {
		t.Fatalf("unexpected catalog payload: %+v", response)
	}
}

func TestListPackStickersReturnsStickerMetadata(t *testing.T) {
	userID := uuid.New()
	packID := uuid.New()
	stickerID := uuid.New()
	fileID := uuid.New()
	fallbackID := uuid.New()
	useCase := &fakeStickerUseCase{
		stickerListOutput: &app.StickerListOutput{
			Stickers: []app.StickerOutput{
				{
					ID:             stickerID,
					PackID:         packID,
					Slug:           "boarding-pass",
					FileID:         fileID,
					FallbackFileID: fallbackID,
					ContentType:    "image/png",
					Width:          512,
					Height:         512,
					DurationMS:     1200,
					Status:         "ACTIVE",
				},
			},
		},
	}
	handler := NewHandler(useCase, "internal-token")
	mux := http.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(http.MethodGet, "/v1/stickers/packs/"+packID.String()+"/stickers?limit=24", nil)
	req = req.WithContext(withUserID(req.Context(), userID.String()))
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d body=%s", rec.Code, rec.Body.String())
	}
	if useCase.listPackInput.UserID != userID.String() ||
		useCase.listPackInput.PackID != packID.String() ||
		useCase.listPackInput.Limit != 24 {
		t.Fatalf("unexpected list pack input: %+v", useCase.listPackInput)
	}
	var response map[string][]stickerResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &response); err != nil {
		t.Fatalf("unmarshal response: %v", err)
	}
	stickers := response["stickers"]
	if len(stickers) != 1 {
		t.Fatalf("expected 1 sticker, got %d", len(stickers))
	}
	if stickers[0].Slug != "boarding-pass" ||
		stickers[0].FallbackFileID != fallbackID.String() ||
		stickers[0].ContentType != "image/png" {
		t.Fatalf("unexpected sticker response: %+v", stickers[0])
	}
}

func TestEnsureCustomPackUsesAuthenticatedUser(t *testing.T) {
	userID := uuid.New()
	useCase := &fakeStickerUseCase{}
	handler := NewHandler(useCase, "internal-token")
	mux := http.NewServeMux()
	handler.Register(mux)

	body := bytes.NewBufferString(`{"ownerId":"` + uuid.NewString() + `"}`)
	req := httptest.NewRequest(http.MethodPost, "/v1/sticker-packs/my/custom", body)
	req = req.WithContext(withUserID(req.Context(), userID.String()))
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d body=%s", rec.Code, rec.Body.String())
	}
	if useCase.ensureCustomUserID != userID.String() {
		t.Fatalf("expected authenticated user id, got %q", useCase.ensureCustomUserID)
	}
}

func TestInstallPackUsesAuthenticatedUser(t *testing.T) {
	userID := uuid.New()
	packID := uuid.New()
	useCase := &fakeStickerUseCase{}
	handler := NewHandler(useCase, "internal-token")
	mux := http.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(http.MethodPost, "/v1/sticker-packs/"+packID.String()+"/install", nil)
	req = req.WithContext(withUserID(req.Context(), userID.String()))
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusNoContent {
		t.Fatalf("expected 204, got %d body=%s", rec.Code, rec.Body.String())
	}
	if useCase.installUserID != userID.String() || useCase.installPackID != packID.String() {
		t.Fatalf("unexpected install input: user=%q pack=%q", useCase.installUserID, useCase.installPackID)
	}
}

func TestCreateStickerUploadRequestUsesAuthenticatedUserAndPathPack(t *testing.T) {
	userID := uuid.New()
	packID := uuid.New()
	fileID := uuid.New()
	sessionID := uuid.New()
	useCase := &fakeStickerUseCase{
		uploadOutput: &app.CreateStickerUploadOutput{
			UploadSessionID: sessionID,
			FileID:          fileID,
			Method:          "PUT",
			URL:             "https://storage.local/upload",
			Headers:         map[string]string{"Content-Type": "image/webp"},
		},
	}
	handler := NewHandler(useCase, "internal-token")
	mux := http.NewServeMux()
	handler.Register(mux)

	body := bytes.NewBufferString(`{"userId":"` + uuid.NewString() + `","originalName":"sticker.webp","contentType":"image/webp","sizeBytes":1024}`)
	req := httptest.NewRequest(http.MethodPost, "/v1/sticker-packs/"+packID.String()+"/upload-requests", body)
	req = req.WithContext(withUserID(req.Context(), userID.String()))
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d body=%s", rec.Code, rec.Body.String())
	}
	if useCase.createUploadInput.UserID != userID.String() || useCase.createUploadInput.PackID != packID.String() {
		t.Fatalf("unexpected upload input: %+v", useCase.createUploadInput)
	}
}

func TestValidateSendReturnsStickerMetadata(t *testing.T) {
	stickerID := uuid.New()
	packID := uuid.New()
	fileID := uuid.New()
	fallbackID := uuid.New()
	previewID := uuid.New()
	userID := uuid.New()
	useCase := &fakeStickerUseCase{
		validateOutput: &app.ValidateStickerSendOutput{
			StickerID:      stickerID,
			PackID:         packID,
			Slug:           "boarding-pass",
			FileID:         fileID,
			FallbackFileID: fallbackID,
			PreviewFileID:  &previewID,
			ContentType:    "application/json",
			Width:          512,
			Height:         512,
			DurationMS:     1800,
			Status:         "ACTIVE",
		},
	}
	handler := NewHandler(useCase, "internal-token")
	mux := http.NewServeMux()
	handler.Register(mux)

	payload := map[string]string{
		"senderUserId": userID.String(),
		"stickerId":    stickerID.String(),
	}
	body, _ := json.Marshal(payload)
	req := httptest.NewRequest(http.MethodPost, "/v1/internal/stickers/validate-send", bytes.NewReader(body))
	req.Header.Set("X-Internal-Service-Token", "internal-token")
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d body=%s", rec.Code, rec.Body.String())
	}

	var response validateSendResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &response); err != nil {
		t.Fatalf("unmarshal response: %v", err)
	}
	if response.StickerID != stickerID.String() || response.PackID != packID.String() || response.FileID != fileID.String() {
		t.Fatalf("unexpected response: %+v", response)
	}
	if response.Slug != "boarding-pass" ||
		response.FallbackFileID != fallbackID.String() ||
		response.PreviewFileID == nil ||
		*response.PreviewFileID != previewID.String() ||
		response.ContentType != "application/json" ||
		response.Width != 512 ||
		response.Height != 512 ||
		response.DurationMS != 1800 {
		t.Fatalf("unexpected sticker metadata: %+v", response)
	}
}

type fakeStickerUseCase struct {
	ensureCustomUserID string
	installUserID      string
	installPackID      string
	catalogLocale      string
	listPackInput      app.ListPackStickersInput
	searchInput        app.SearchOfficialStickersInput
	createUploadInput  app.CreateStickerUploadInput
	catalogOutput      *app.OfficialCatalogOutput
	stickerListOutput  *app.StickerListOutput
	uploadOutput       *app.CreateStickerUploadOutput
	validateOutput     *app.ValidateStickerSendOutput
}

func (f *fakeStickerUseCase) ListDefaultPacks(context.Context) ([]*model.StickerPackWithStickers, error) {
	return nil, nil
}

func (f *fakeStickerUseCase) ListOfficialCatalog(_ context.Context, input app.ListOfficialCatalogInput) (*app.OfficialCatalogOutput, error) {
	f.catalogLocale = input.Locale
	return f.catalogOutput, nil
}

func (f *fakeStickerUseCase) ListPackStickers(_ context.Context, input app.ListPackStickersInput) (*app.StickerListOutput, error) {
	f.listPackInput = input
	return f.stickerListOutput, nil
}

func (f *fakeStickerUseCase) SearchOfficialStickers(_ context.Context, input app.SearchOfficialStickersInput) (*app.StickerListOutput, error) {
	f.searchInput = input
	return f.stickerListOutput, nil
}

func (f *fakeStickerUseCase) ListRecentStickers(context.Context, app.ListRecentStickersInput) (*app.StickerListOutput, error) {
	return f.stickerListOutput, nil
}

func (f *fakeStickerUseCase) ListMyPacks(context.Context, string) ([]*model.StickerPackWithStickers, error) {
	return nil, nil
}

func (f *fakeStickerUseCase) EnsureMyCustomPack(_ context.Context, userID string) (*model.StickerPack, error) {
	f.ensureCustomUserID = userID
	parsed := uuid.MustParse(userID)
	return model.NewStickerPack(model.NewStickerPackParams{
		Slug:        "custom-" + userID,
		Type:        enum.PackTypeUserCustom,
		Visibility:  enum.PackVisibilityPrivate,
		Status:      enum.PackStatusActive,
		OwnerUserID: &parsed,
		Title:       map[string]string{"en": "My stickers"},
	})
}

func (f *fakeStickerUseCase) InstallPack(_ context.Context, input app.InstallStickerPackInput) error {
	f.installUserID = input.UserID
	f.installPackID = input.PackID
	return nil
}

func (f *fakeStickerUseCase) RemovePack(context.Context, app.RemoveStickerPackInput) error {
	return nil
}

func (f *fakeStickerUseCase) CreateStickerUploadRequest(
	_ context.Context,
	input app.CreateStickerUploadInput,
) (*app.CreateStickerUploadOutput, error) {
	f.createUploadInput = input
	return f.uploadOutput, nil
}

func (f *fakeStickerUseCase) FinalizeStickerUpload(
	context.Context,
	app.FinalizeStickerUploadInput,
) (*model.Sticker, error) {
	return nil, nil
}

func (f *fakeStickerUseCase) ValidateSend(
	context.Context,
	app.ValidateStickerSendInput,
) (*app.ValidateStickerSendOutput, error) {
	return f.validateOutput, nil
}
