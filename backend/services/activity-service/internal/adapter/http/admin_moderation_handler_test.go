package http

import (
	"context"
	"encoding/json"
	"strings"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/activity-service/internal/transport/dto"
)

func TestResolveActivityHostNamesUsesDisplayNameAndFullName(t *testing.T) {
	t.Parallel()

	hostID := uuid.New()
	resolver := activityAdminNameResolverStub{
		displayName: "@nomad_aru",
		fullName:    "Аружан Тулегенова",
	}

	names := resolveActivityHostNames(context.Background(), resolver, hostID)

	if names.DisplayName != resolver.displayName {
		t.Fatalf("DisplayName = %q, want %q", names.DisplayName, resolver.displayName)
	}
	if names.FullName != resolver.fullName {
		t.Fatalf("FullName = %q, want %q", names.FullName, resolver.fullName)
	}
}

func TestAdminActivityModerationResponseExposesHostFullName(t *testing.T) {
	t.Parallel()

	payload, err := json.Marshal(dto.AdminActivityModerationResponse{
		HostDisplayName: "@nomad_aru",
		HostFullName:    "Аружан Тулегенова",
	})
	if err != nil {
		t.Fatalf("json.Marshal returned error: %v", err)
	}
	body := string(payload)
	for _, expected := range []string{
		`"hostDisplayName":"@nomad_aru"`,
		`"hostFullName":"Аружан Тулегенова"`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("response JSON did not contain %q: %s", expected, body)
		}
	}
}

type activityAdminNameResolverStub struct {
	displayName string
	fullName    string
}

func (s activityAdminNameResolverStub) ResolveUserIDBySubject(context.Context, string) (uuid.UUID, error) {
	return uuid.Nil, nil
}

func (s activityAdminNameResolverStub) ResolveRolesBySubject(context.Context, string) ([]string, error) {
	return nil, nil
}

func (s activityAdminNameResolverStub) DisplayNameForUserID(context.Context, uuid.UUID) (string, error) {
	return s.displayName, nil
}

func (s activityAdminNameResolverStub) FullNameForUserID(context.Context, uuid.UUID) (string, error) {
	return s.fullName, nil
}
