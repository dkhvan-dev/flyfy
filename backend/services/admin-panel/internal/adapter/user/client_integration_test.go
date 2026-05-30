package user

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/model"
)

func TestClientListAdminUsersAgainstLiveUserService(t *testing.T) {
	target := os.Getenv("ADMIN_PANEL_USER_SERVICE_TEST_TARGET")
	if target == "" {
		t.Skip("set ADMIN_PANEL_USER_SERVICE_TEST_TARGET to run user-service client integration tests")
	}

	internalToken := os.Getenv("ADMIN_PANEL_INTERNAL_SERVICE_TEST_TOKEN")
	if internalToken == "" {
		t.Skip("set ADMIN_PANEL_INTERNAL_SERVICE_TEST_TOKEN to run user-service client integration tests")
	}

	client, err := New(target, internalToken, "admin-panel", 3*time.Second)
	if err != nil {
		t.Fatalf("create user-service client: %v", err)
	}
	defer client.Close()

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if _, err = client.ListAdminUsers(ctx, model.AdminUserListFilter{PageSize: 10}); err != nil {
		t.Fatalf("ListAdminUsers returned error: %v", err)
	}
}
