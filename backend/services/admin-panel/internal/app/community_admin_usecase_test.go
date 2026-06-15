package app

import (
	"context"
	"encoding/json"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
	"kz/inflap/backend/services/admin-panel/internal/domain/port"
)

func TestCommunityAdminCreateRequiresSuperAdmin(t *testing.T) {
	useCase := NewCommunityAdminUseCase(&communityAdminClientStub{}, &communityAdminAuditStub{})
	actor := communityAdminStaff(enum.StaffRoleAdmin)

	_, err := useCase.CreateCommunity(context.Background(), actor, CreateCommunityAdminInput{
		Slug:            "investments",
		TitleI18n:       map[string]string{"ru": "Инвестиции", "en": "Investments", "kk": "Инвестициялар"},
		DescriptionI18n: map[string]string{"ru": "Описание", "en": "Description", "kk": "Сипаттама"},
	})

	if !errors.Is(err, ErrPermissionDenied) {
		t.Fatalf("CreateCommunity error = %v, want permission denied", err)
	}
}

func TestCommunityAdminCreateSendsLocalizedContentAndAudits(t *testing.T) {
	client := &communityAdminClientStub{}
	audit := &communityAdminAuditStub{}
	useCase := NewCommunityAdminUseCase(client, audit)
	actor := communityAdminStaff(enum.StaffRoleSuperAdmin)

	created, err := useCase.CreateCommunity(context.Background(), actor, CreateCommunityAdminInput{
		Slug:            "investments",
		TitleI18n:       map[string]string{"ru": "Инвестиции", "en": "Investments", "kk": "Инвестициялар"},
		DescriptionI18n: map[string]string{"ru": "Описание", "en": "Description", "kk": "Сипаттама"},
		RulesI18n:       map[string][]string{"ru": {"Без спама"}, "en": {"No spam"}, "kk": {"Спам жоқ"}},
		Topic:           "FINANCE",
		PostingPolicy:   "MEMBERS_AFTER_MODERATION",
		Status:          "ACTIVE",
		RequestID:       "req-1",
	})
	if err != nil {
		t.Fatalf("CreateCommunity returned error: %v", err)
	}

	if client.input.ActorStaffID != actor.ID ||
		client.input.TitleI18n["en"] != "Investments" ||
		client.input.DescriptionI18n["kk"] != "Сипаттама" ||
		client.input.RulesI18n["ru"][0] != "Без спама" {
		t.Fatalf("client input = %#v", client.input)
	}
	if created.Title != "Инвестиции" {
		t.Fatalf("created title = %q", created.Title)
	}
	if audit.event == nil || audit.event.ActorStaffID == nil || *audit.event.ActorStaffID != actor.ID {
		t.Fatalf("audit event = %#v", audit.event)
	}
	if audit.event.Action != "community.create" || audit.event.EntityType != "story_community" {
		t.Fatalf("audit action/entity = %s/%s", audit.event.Action, audit.event.EntityType)
	}
	var after map[string]any
	if err := json.Unmarshal(audit.event.AfterJSON, &after); err != nil {
		t.Fatalf("audit after json: %v", err)
	}
	if after["slug"] != "investments" {
		t.Fatalf("audit after = %#v", after)
	}
}

func TestCommunityAdminUpdateSendsLocalizedContentAndAudits(t *testing.T) {
	client := &communityAdminClientStub{}
	audit := &communityAdminAuditStub{}
	useCase := NewCommunityAdminUseCase(client, audit)
	actor := communityAdminStaff(enum.StaffRoleSuperAdmin)
	communityID := uuid.New()
	coverID := uuid.New()

	updated, err := useCase.UpdateCommunity(context.Background(), actor, communityID, CreateCommunityAdminInput{
		Slug:            "football-vn-da-nang",
		TitleI18n:       map[string]string{"ru": "Футбол", "en": "Football", "kk": "Футбол"},
		DescriptionI18n: map[string]string{"ru": "Игры", "en": "Games", "kk": "Ойындар"},
		RulesI18n:       map[string][]string{"ru": {"Без спама"}, "en": {"No spam"}, "kk": {"Спам жоқ"}},
		Topic:           "sports",
		CountryCode:     stringPtr("vn"),
		CityID:          stringPtr("da-nang"),
		CoverFileID:     &coverID,
		PostingPolicy:   "trusted_members",
		Status:          "active",
		Visibility:      "public",
		RequestID:       "req-update",
	})
	if err != nil {
		t.Fatalf("UpdateCommunity returned error: %v", err)
	}

	if client.updateID != communityID ||
		client.updateInput.ActorStaffID != actor.ID ||
		client.updateInput.CountryCode == nil ||
		*client.updateInput.CountryCode != "VN" ||
		client.updateInput.Status != "ACTIVE" ||
		client.updateInput.CoverFileID == nil ||
		*client.updateInput.CoverFileID != coverID {
		t.Fatalf("update id/input = %s/%#v", client.updateID, client.updateInput)
	}
	if updated.Slug != "football-vn-da-nang" {
		t.Fatalf("updated community = %#v", updated)
	}
	if audit.event == nil || audit.event.Action != "community.update" || audit.event.EntityType != "story_community" {
		t.Fatalf("audit event = %#v", audit.event)
	}
}

func TestCommunityAdminCatalogRequiresSuperAdminAndLoadsPlatformData(t *testing.T) {
	client := &communityAdminClientStub{
		catalog: model.CommunityPlatformCatalog{
			PostProfiles: []model.CommunityPostProfile{{Key: "quick_post_v1", PostKind: "QUICK_POST"}},
			Blueprints:   []model.CommunityBlueprint{{ID: uuid.New(), Key: "football", TitleI18n: map[string]string{"ru": "Футбол"}}},
			GeoHubs:      []model.CommunityGeoHub{{CountryCode: "VN", CityID: "da-nang", CommunityEnabled: true}},
			Instances:    []model.CommunityInstance{{ID: uuid.New(), Slug: "football-vn-da-nang", CountryCode: "VN"}},
		},
	}
	useCase := NewCommunityAdminUseCase(client, &communityAdminAuditStub{})

	_, err := useCase.CommunityPlatformCatalog(context.Background(), communityAdminStaff(enum.StaffRoleAdmin), CommunityPlatformCatalogInput{})
	if !errors.Is(err, ErrPermissionDenied) {
		t.Fatalf("CommunityPlatformCatalog non-superadmin error = %v, want permission denied", err)
	}

	page, err := useCase.CommunityPlatformCatalog(context.Background(), communityAdminStaff(enum.StaffRoleSuperAdmin), CommunityPlatformCatalogInput{
		CountryCode: "vn",
		CityID:      "da-nang",
		Limit:       500,
	})
	if err != nil {
		t.Fatalf("CommunityPlatformCatalog returned error: %v", err)
	}
	if len(page.Blueprints) != 1 || page.Blueprints[0].Key != "football" ||
		len(page.GeoHubs) != 1 || page.GeoHubs[0].CountryCode != "VN" ||
		client.catalogInput.CountryCode != "VN" || client.catalogInput.CityID != "da-nang" || client.catalogInput.Limit != 500 {
		t.Fatalf("catalog page = %+v, input = %+v", page, client.catalogInput)
	}
}

func TestCommunityAdminMaterializeRequiresSuperAdminAndAudits(t *testing.T) {
	client := &communityAdminClientStub{materializeResult: model.CommunityMaterializationResult{MaterializedCount: 45}}
	audit := &communityAdminAuditStub{}
	useCase := NewCommunityAdminUseCase(client, audit)
	actor := communityAdminStaff(enum.StaffRoleSuperAdmin)

	_, err := useCase.MaterializeCommunityInstances(context.Background(), communityAdminStaff(enum.StaffRoleAdmin), MaterializeCommunityInstancesInput{})
	if !errors.Is(err, ErrPermissionDenied) {
		t.Fatalf("MaterializeCommunityInstances non-superadmin error = %v, want permission denied", err)
	}

	result, err := useCase.MaterializeCommunityInstances(context.Background(), actor, MaterializeCommunityInstancesInput{
		CountryCode: "vn",
		CityID:      "da-nang",
		ScopeType:   "city",
		Limit:       9000,
		RequestID:   "req-materialize",
	})
	if err != nil {
		t.Fatalf("MaterializeCommunityInstances returned error: %v", err)
	}
	if result.MaterializedCount != 45 ||
		client.materializeInput.ActorStaffID != actor.ID ||
		client.materializeInput.CountryCode != "VN" ||
		client.materializeInput.ScopeType != "CITY" ||
		client.materializeInput.Limit != 5000 {
		t.Fatalf("result = %+v, input = %+v", result, client.materializeInput)
	}
	if audit.event == nil || audit.event.Action != "community.instances.materialize" || audit.event.EntityType != "community_platform" {
		t.Fatalf("audit event = %#v", audit.event)
	}
}

func communityAdminStaff(role enum.StaffRole) *model.StaffUser {
	return &model.StaffUser{
		ID:          uuid.New(),
		Email:       "admin@example.test",
		DisplayName: "Admin",
		Roles:       []enum.StaffRole{role},
	}
}

func stringPtr(value string) *string {
	return &value
}

type communityAdminClientStub struct {
	input             port.CreateCommunityInput
	updateID          uuid.UUID
	updateInput       port.UpdateCommunityInput
	catalog           model.CommunityPlatformCatalog
	catalogInput      port.CommunityPlatformCatalogInput
	materializeInput  port.MaterializeCommunityInstancesInput
	materializeResult model.CommunityMaterializationResult
}

func (s *communityAdminClientStub) CreateCommunity(_ context.Context, input port.CreateCommunityInput) (model.AdminCommunity, error) {
	s.input = input
	return model.AdminCommunity{
		ID:              uuid.New(),
		Slug:            input.Slug,
		Title:           input.TitleI18n["ru"],
		TitleI18n:       input.TitleI18n,
		Description:     input.DescriptionI18n["ru"],
		DescriptionI18n: input.DescriptionI18n,
		RulesI18n:       input.RulesI18n,
		Topic:           input.Topic,
		PostingPolicy:   input.PostingPolicy,
		Status:          input.Status,
		CreatedAt:       time.Now().UTC(),
		UpdatedAt:       time.Now().UTC(),
	}, nil
}

func (s *communityAdminClientStub) GetCommunity(_ context.Context, id uuid.UUID) (model.AdminCommunity, error) {
	return model.AdminCommunity{
		ID:              id,
		Slug:            "football-vn-da-nang",
		Title:           "Футбол",
		TitleI18n:       map[string]string{"ru": "Футбол", "en": "Football", "kk": "Футбол"},
		Description:     "Игры",
		DescriptionI18n: map[string]string{"ru": "Игры", "en": "Games", "kk": "Ойындар"},
		Status:          "ACTIVE",
		Visibility:      "PUBLIC",
		PostingPolicy:   "TRUSTED_MEMBERS",
	}, nil
}

func (s *communityAdminClientStub) UpdateCommunity(_ context.Context, id uuid.UUID, input port.UpdateCommunityInput) (model.AdminCommunity, error) {
	s.updateID = id
	s.updateInput = input
	return model.AdminCommunity{
		ID:              id,
		Slug:            input.Slug,
		Title:           input.TitleI18n["ru"],
		TitleI18n:       input.TitleI18n,
		Description:     input.DescriptionI18n["ru"],
		DescriptionI18n: input.DescriptionI18n,
		RulesI18n:       input.RulesI18n,
		Topic:           input.Topic,
		CityID:          input.CityID,
		CountryCode:     input.CountryCode,
		CoverFileID:     input.CoverFileID,
		PostingPolicy:   input.PostingPolicy,
		Status:          input.Status,
		Visibility:      input.Visibility,
		CreatedAt:       time.Now().UTC(),
		UpdatedAt:       time.Now().UTC(),
	}, nil
}

func (s *communityAdminClientStub) CommunityPlatformCatalog(_ context.Context, input port.CommunityPlatformCatalogInput) (model.CommunityPlatformCatalog, error) {
	s.catalogInput = input
	return s.catalog, nil
}

func (s *communityAdminClientStub) MaterializeCommunityInstances(_ context.Context, input port.MaterializeCommunityInstancesInput) (model.CommunityMaterializationResult, error) {
	s.materializeInput = input
	return s.materializeResult, nil
}

type communityAdminAuditStub struct {
	event *model.AuditEvent
}

func (s *communityAdminAuditStub) Append(_ context.Context, event *model.AuditEvent) error {
	copy := *event
	s.event = &copy
	return nil
}

func (s *communityAdminAuditStub) List(context.Context, model.AuditFilter) ([]*model.AuditEvent, error) {
	return nil, nil
}
