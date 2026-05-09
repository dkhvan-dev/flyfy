package http

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/sticker-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/sticker-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/sticker-service/internal/domain/model"
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
	userID := uuid.New()
	useCase := &fakeStickerUseCase{
		validateOutput: &app.ValidateStickerSendOutput{
			StickerID: stickerID,
			PackID:    packID,
			FileID:    fileID,
			Status:    "ACTIVE",
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
}

type fakeStickerUseCase struct {
	ensureCustomUserID string
	installUserID      string
	installPackID      string
	createUploadInput  app.CreateStickerUploadInput
	uploadOutput       *app.CreateStickerUploadOutput
	validateOutput     *app.ValidateStickerSendOutput
}

func (f *fakeStickerUseCase) ListDefaultPacks(context.Context) ([]*model.StickerPackWithStickers, error) {
	return nil, nil
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
