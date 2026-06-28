package http

import (
	"reflect"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

func TestAdminNavigationGroupsSupportItemsIntoHelpCenterSection(t *testing.T) {
	t.Parallel()

	staff := &model.StaffUser{
		ID: uuid.New(),
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
			enum.PermissionUsersRead,
			enum.PermissionPlaceManage,
			enum.PermissionSupportRead,
			enum.PermissionSupportReply,
			enum.PermissionSupportManage,
			enum.PermissionHelpContentEdit,
			enum.PermissionHelpContentPublish,
		},
	}

	data := NewAdminNavigationPageViewData(staff)

	management := navigationTestSection(data.Sections, "navigation.section.management")
	if management == nil {
		t.Fatal("management section is missing")
	}
	if got := navigationTestItemKeys(management.Items); !reflect.DeepEqual(got, []string{"feed_quality", "users", "trust", "places"}) {
		t.Fatalf("management item keys = %#v", got)
	}

	helpCenter := navigationTestSection(data.Sections, "navigation.section.helpCenter")
	if helpCenter == nil {
		t.Fatal("help center section is missing")
	}
	want := []string{"support", "support_saved_replies", "support_agents", "help_analytics", "help_categories", "help_content"}
	if got := navigationTestItemKeys(helpCenter.Items); !reflect.DeepEqual(got, want) {
		t.Fatalf("help center item keys = %#v, want %#v", got, want)
	}
}

func navigationTestSection(sections []AdminNavigationSectionView, titleKey string) *AdminNavigationSectionView {
	for index := range sections {
		if sections[index].TitleKey == titleKey {
			return &sections[index]
		}
	}
	return nil
}

func navigationTestItemKeys(items []AdminNavigationItemView) []string {
	keys := make([]string, 0, len(items))
	for _, item := range items {
		keys = append(keys, item.Key)
	}
	return keys
}
