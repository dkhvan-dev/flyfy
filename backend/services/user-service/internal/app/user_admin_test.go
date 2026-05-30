package app

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/user-service/internal/domain/model"
)

func TestListAdminUsersDefaultsAndClampsPageSize(t *testing.T) {
	ctx := context.Background()
	repo := &adminUserTestRepository{}
	useCase := NewUserUseCase(repo, nil)

	if _, err := useCase.ListAdminUsers(ctx, model.AdminUserListFilter{}); err != nil {
		t.Fatalf("ListAdminUsers default returned error: %v", err)
	}
	if repo.lastFilter.PageSize != 50 {
		t.Fatalf("default page size = %d, want 50", repo.lastFilter.PageSize)
	}

	if _, err := useCase.ListAdminUsers(ctx, model.AdminUserListFilter{PageSize: 500}); err != nil {
		t.Fatalf("ListAdminUsers clamped returned error: %v", err)
	}
	if repo.lastFilter.PageSize != 100 {
		t.Fatalf("clamped page size = %d, want 100", repo.lastFilter.PageSize)
	}
}

func TestListAdminUsersRejectsInvalidPageToken(t *testing.T) {
	ctx := context.Background()
	useCase := NewUserUseCase(&adminUserTestRepository{}, nil)

	_, err := useCase.ListAdminUsers(ctx, model.AdminUserListFilter{PageToken: "not-base64-json"})
	if !errors.Is(err, ErrInvalidPageToken) {
		t.Fatalf("error = %v, want %v", err, ErrInvalidPageToken)
	}
}

func TestListAdminUsersMasksSensitiveIdentityValues(t *testing.T) {
	ctx := context.Background()
	userID := uuid.New()
	repo := &adminUserTestRepository{
		listItems: []model.AdminUserListItem{
			{
				UserID:        userID,
				DisplayName:   "Aruzhan",
				MaskedPhone:   "+77011234567",
				MaskedEmail:   "aru@example.com",
				AccountStatus: string("ACTIVE"),
				CreatedAt:     time.Now().UTC(),
			},
		},
	}
	useCase := NewUserUseCase(repo, nil)

	page, err := useCase.ListAdminUsers(ctx, model.AdminUserListFilter{PageSize: 10})
	if err != nil {
		t.Fatalf("ListAdminUsers returned error: %v", err)
	}
	if len(page.Items) != 1 {
		t.Fatalf("items length = %d, want 1", len(page.Items))
	}
	if page.Items[0].MaskedPhone == "+77011234567" || strings.Contains(page.Items[0].MaskedPhone, "011234") {
		t.Fatalf("masked phone leaked raw value: %q", page.Items[0].MaskedPhone)
	}
	if page.Items[0].MaskedEmail == "aru@example.com" || strings.Contains(page.Items[0].MaskedEmail, "example.com") {
		t.Fatalf("masked email leaked raw value: %q", page.Items[0].MaskedEmail)
	}
}

func TestGetAdminUserDetailRejectsEmptyUserID(t *testing.T) {
	ctx := context.Background()
	useCase := NewUserUseCase(&adminUserTestRepository{}, nil)

	_, err := useCase.GetAdminUserDetail(ctx, uuid.Nil)
	if !errors.Is(err, ErrInvalidUserID) {
		t.Fatalf("error = %v, want %v", err, ErrInvalidUserID)
	}
}

func TestGetAdminUserDetailMasksSensitiveIdentityValues(t *testing.T) {
	ctx := context.Background()
	userID := uuid.New()
	repo := &adminUserTestRepository{
		detail: model.AdminUserDetail{
			UserID:        userID,
			DisplayName:   "Aruzhan",
			MaskedPhone:   "+77011234567",
			MaskedEmail:   "aru@example.com",
			AccountStatus: "ACTIVE",
			CreatedAt:     time.Now().UTC(),
			UpdatedAt:     time.Now().UTC(),
		},
	}
	useCase := NewUserUseCase(repo, nil)

	detail, err := useCase.GetAdminUserDetail(ctx, userID)
	if err != nil {
		t.Fatalf("GetAdminUserDetail returned error: %v", err)
	}
	if detail.MaskedPhone == "+77011234567" || strings.Contains(detail.MaskedPhone, "011234") {
		t.Fatalf("masked phone leaked raw value: %q", detail.MaskedPhone)
	}
	if detail.MaskedEmail == "aru@example.com" || strings.Contains(detail.MaskedEmail, "example.com") {
		t.Fatalf("masked email leaked raw value: %q", detail.MaskedEmail)
	}
}

type adminUserTestRepository struct {
	friendshipTestRepository
	lastFilter model.AdminUserListFilter
	listItems  []model.AdminUserListItem
	nextToken  string
	detail     model.AdminUserDetail
}

func (r *adminUserTestRepository) ListAdminUsers(
	_ context.Context,
	filter model.AdminUserListFilter,
) ([]model.AdminUserListItem, string, error) {
	r.lastFilter = filter
	return r.listItems, r.nextToken, nil
}

func (r *adminUserTestRepository) GetAdminUserDetail(
	_ context.Context,
	userID uuid.UUID,
) (model.AdminUserDetail, error) {
	if userID == uuid.Nil {
		return model.AdminUserDetail{}, ErrInvalidUserID
	}
	if r.detail.UserID == uuid.Nil {
		return model.AdminUserDetail{}, ErrUserNotFound
	}
	return r.detail, nil
}
