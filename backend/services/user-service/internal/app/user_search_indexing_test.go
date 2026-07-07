package app

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/user-service/internal/domain/enum"
	"kz/inflap/backend/services/user-service/internal/domain/model"
	"kz/inflap/backend/services/user-service/internal/domain/port"
)

func TestBackfillUserSearchIndexReconcilesDocuments(t *testing.T) {
	t.Parallel()

	activeUserID := uuid.New()
	blockedUserID := uuid.New()
	now := time.Now().UTC()

	repo := &userSearchBackfillRepoStub{
		pages: [][]port.UserSearchIndexBackfillAggregate{
			{
				{
					User: &model.User{
						ID:            activeUserID,
						AuthSubjectID: "subject-active",
						Status:        enum.UserStatusActive,
						CreatedAt:     now,
						UpdatedAt:     now,
					},
					Profile: &model.UserProfile{
						UserID:      activeUserID,
						FirstName:   stringPtr("Aruzhan"),
						LastName:    stringPtr("Sapar"),
						Nickname:    stringPtr("aru"),
						CountryCode: stringPtr("KZ"),
						Locale:      "en",
						Timezone:    "Asia/Almaty",
						CreatedAt:   now,
						UpdatedAt:   now,
					},
					Reputation: &model.UserReputation{
						UserID:     activeUserID,
						TrustScore: 87,
					},
					FollowersCount: 12,
				},
			},
			{
				{
					User: &model.User{
						ID:            blockedUserID,
						AuthSubjectID: "subject-blocked",
						Status:        enum.UserStatusBlocked,
						CreatedAt:     now,
						UpdatedAt:     now,
					},
					Profile: &model.UserProfile{
						UserID:    blockedUserID,
						FirstName: stringPtr("Hidden"),
						Locale:    "en",
						Timezone:  "Asia/Almaty",
						CreatedAt: now,
						UpdatedAt: now,
					},
				},
			},
		},
	}
	indexer := &userSearchIndexerStub{}

	stats, err := BackfillUserSearchIndex(context.Background(), repo, indexer, SearchIndexBackfillOptions{
		BatchSize:   1,
		DeleteStale: true,
	})
	if err != nil {
		t.Fatalf("BackfillUserSearchIndex() error = %v", err)
	}

	if stats.Scanned != 2 || stats.Upserted != 1 || stats.Deleted != 1 || stats.Skipped != 0 {
		t.Fatalf("stats = %#v", stats)
	}
	if len(indexer.upserts) != 1 {
		t.Fatalf("upserts = %d, want 1", len(indexer.upserts))
	}
	doc := indexer.upserts[0]
	if doc.Domain != "user" || doc.EntityID != activeUserID.String() {
		t.Fatalf("upsert domain/entity = %s/%s", doc.Domain, doc.EntityID)
	}
	if doc.Title["en"] != "Aruzhan Sapar" {
		t.Fatalf("title = %#v", doc.Title)
	}
	if doc.PopularityScore != 12 {
		t.Fatalf("popularity = %v, want 12", doc.PopularityScore)
	}
	if doc.TrustScore != 0.87 {
		t.Fatalf("trust score = %v, want 0.87", doc.TrustScore)
	}
	if len(indexer.deletes) != 1 {
		t.Fatalf("deletes = %d, want 1", len(indexer.deletes))
	}
	if indexer.deletes[0].EntityID != blockedUserID.String() {
		t.Fatalf("delete entity = %s, want %s", indexer.deletes[0].EntityID, blockedUserID)
	}
}

type userSearchBackfillRepoStub struct {
	pages     [][]port.UserSearchIndexBackfillAggregate
	listCalls int
}

func (s *userSearchBackfillRepoStub) ListUserSearchIndexBackfillAggregates(
	_ context.Context,
	limit int,
	offset int,
) ([]port.UserSearchIndexBackfillAggregate, error) {
	index := s.listCalls
	s.listCalls++
	if index >= len(s.pages) {
		return []port.UserSearchIndexBackfillAggregate{}, nil
	}
	return s.pages[index], nil
}

func stringPtr(value string) *string {
	return &value
}
