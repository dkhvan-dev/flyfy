package http

import (
	"bytes"
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/config"
	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/domain/model"
)

func TestPublicBindFileRejectsDifferentUserOwner(t *testing.T) {
	fileID := uuid.New()
	actorID := uuid.New()
	ownerID := uuid.New()
	handler := NewHandler(nil, &fakeBindingUseCase{})
	mux := http.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(
		http.MethodPost,
		"/v1/files/"+fileID.String()+"/bindings",
		bytes.NewBufferString(`{"ownerType":"USER","ownerId":"`+ownerID.String()+`","purpose":"CHAT_STICKER"}`),
	)
	req.Header.Set("X-User-Id", actorID.String())
	rec := httptest.NewRecorder()

	Chain(testHTTPConfig(), mux).ServeHTTP(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Fatalf("expected 403, got %d body=%s", rec.Code, rec.Body.String())
	}
}

func TestInternalBindFileAllowsTrustedStickerOwnerBinding(t *testing.T) {
	fileID := uuid.New()
	actorID := uuid.New()
	ownerID := uuid.New()
	bindings := &fakeBindingUseCase{}
	handler := NewHandler(nil, bindings)
	mux := http.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(
		http.MethodPost,
		"/v1/internal/files/"+fileID.String()+"/bindings",
		bytes.NewBufferString(`{"ownerType":"USER","ownerId":"`+ownerID.String()+`","purpose":"CHAT_STICKER"}`),
	)
	req.Header.Set("X-User-Id", actorID.String())
	req.Header.Set("X-Internal-Service-Token", "internal-token")
	rec := httptest.NewRecorder()

	Chain(testHTTPConfig(), mux).ServeHTTP(rec, req)

	if rec.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d body=%s", rec.Code, rec.Body.String())
	}
	if bindings.lastInput.OwnerID != ownerID.String() {
		t.Fatalf("ownerId = %q, want %q", bindings.lastInput.OwnerID, ownerID.String())
	}
	if bindings.lastInput.CreatedByUserID == nil || *bindings.lastInput.CreatedByUserID != actorID.String() {
		t.Fatalf("createdByUserID = %v, want %s", bindings.lastInput.CreatedByUserID, actorID)
	}
}

func testHTTPConfig() *config.Config {
	return &config.Config{
		Security: config.SecurityConfig{
			InternalServiceToken:       "internal-token",
			RequireAuthenticatedWrites: true,
			TrustedGatewayHeaderUserID: "X-User-Id",
			TrustedGatewayHeaderRoles:  "X-User-Roles",
			RequestIDHeader:            "X-Request-Id",
		},
	}
}

type fakeBindingUseCase struct {
	lastInput app.BindFileInput
}

func (f *fakeBindingUseCase) BindFile(_ context.Context, input app.BindFileInput) (*model.FileBinding, error) {
	f.lastInput = input

	ownerID, err := uuid.Parse(input.OwnerID)
	if err != nil {
		return nil, err
	}

	var createdBy *uuid.UUID
	if input.CreatedByUserID != nil {
		parsed, err := uuid.Parse(*input.CreatedByUserID)
		if err != nil {
			return nil, err
		}
		createdBy = &parsed
	}

	return model.NewFileBinding(model.NewFileBindingParams{
		FileID:          input.FileID,
		OwnerType:       enum.OwnerType(input.OwnerType),
		OwnerID:         ownerID,
		Purpose:         enum.FilePurpose(input.Purpose),
		IsPrimary:       input.IsPrimary,
		CreatedByUserID: createdBy,
	})
}

func (f *fakeBindingUseCase) ListByFileID(context.Context, uuid.UUID) ([]*model.FileBinding, error) {
	return nil, nil
}

func (f *fakeBindingUseCase) ListByOwnerAndPurpose(
	context.Context,
	app.ListFileBindingsInput,
) ([]*model.FileBinding, error) {
	return nil, nil
}
