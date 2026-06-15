package cache

import (
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"

	"kz/inflap/backend/services/feed-service/internal/domain/enum"
	"kz/inflap/backend/services/feed-service/internal/domain/model"
)

func TestRedisPostFeedCacheUsesDefaultPrefix(t *testing.T) {
	client := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
	t.Cleanup(func() { _ = client.Close() })

	cache := NewRedisPostFeedCache(client, "")

	if got, want := cache.dataKey("feed:v1:test"), defaultPostFeedCachePrefix+"data:feed:v1:test"; got != want {
		t.Fatalf("data key = %q, want %q", got, want)
	}
	if got, want := cache.versionKey("global"), defaultPostFeedCachePrefix+"version:global"; got != want {
		t.Fatalf("version key = %q, want %q", got, want)
	}
}

func TestPostFeedCachePayloadRoundTrip(t *testing.T) {
	now := time.Date(2026, 6, 12, 13, 0, 0, 0, time.UTC)
	post := &model.Post{
		ID:               uuid.New(),
		Slug:             "almaty-cafes",
		AuthorUserID:     uuid.New(),
		Title:            "Almaty cafes",
		Category:         enum.PostCategoryGuide,
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusApproved,
		MediaStatus:      enum.PostMediaStatusReady,
		CreatedAt:        now,
		UpdatedAt:        now,
		PublishedAt:      &now,
	}

	payload, err := marshalPostFeedCachePayload([]*model.Post{post})
	if err != nil {
		t.Fatalf("marshalPostFeedCachePayload returned error: %v", err)
	}
	decoded, err := unmarshalPostFeedCachePayload(payload)
	if err != nil {
		t.Fatalf("unmarshalPostFeedCachePayload returned error: %v", err)
	}
	if len(decoded) != 1 || decoded[0].ID != post.ID {
		t.Fatalf("decoded posts = %+v, want post %s", decoded, post.ID)
	}
}
