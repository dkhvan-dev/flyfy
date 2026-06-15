package app

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/model"
	"kz/inflap/backend/services/feed-service/internal/domain/port"
)

type PostFeedProjectionWorkerConfig struct {
	PollInterval time.Duration
	BatchSize    int
	MaxAttempts  int
	BaseBackoff  time.Duration
}

type PostFeedProjectionWorker struct {
	repo  port.PostFeedProjectionRepository
	cache port.PostFeedCache
	cfg   PostFeedProjectionWorkerConfig
}

func NewPostFeedProjectionWorker(
	repo port.PostFeedProjectionRepository,
	cfg PostFeedProjectionWorkerConfig,
) *PostFeedProjectionWorker {
	if cfg.PollInterval <= 0 {
		cfg.PollInterval = 5 * time.Second
	}
	if cfg.BatchSize <= 0 {
		cfg.BatchSize = 50
	}
	if cfg.MaxAttempts <= 0 {
		cfg.MaxAttempts = 20
	}
	if cfg.BaseBackoff <= 0 {
		cfg.BaseBackoff = time.Second
	}
	return &PostFeedProjectionWorker{
		repo: repo,
		cfg:  cfg,
	}
}

func (w *PostFeedProjectionWorker) WithPostFeedCache(cache port.PostFeedCache) *PostFeedProjectionWorker {
	w.cache = cache
	return w
}

func (w *PostFeedProjectionWorker) Start(ctx context.Context) {
	if w == nil {
		return
	}
	ticker := time.NewTicker(w.cfg.PollInterval)
	defer ticker.Stop()

	for {
		_ = w.ProcessOnce(ctx, time.Now().UTC())

		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
		}
	}
}

func (w *PostFeedProjectionWorker) ProcessOnce(ctx context.Context, now time.Time) error {
	if w == nil || w.repo == nil {
		return fmt.Errorf("post feed projection worker dependencies are required")
	}
	if now.IsZero() {
		now = time.Now().UTC()
	}

	events, err := w.repo.ListDuePostFeedProjectionEvents(ctx, w.cfg.BatchSize, now)
	if err != nil {
		return err
	}
	for _, event := range events {
		if _, err = w.repo.ProjectPostFeedItem(ctx, event); err != nil {
			nextAttemptAt := now.Add(w.backoff(event.AttemptCount + 1))
			if markErr := w.repo.MarkPostFeedProjectionOutboxFailed(ctx, event.ID, safePostFeedProjectionError(err), nextAttemptAt); markErr != nil {
				return markErr
			}
			continue
		}
		if w.cache != nil {
			_ = w.cache.BumpVersion(ctx, postFeedProjectionCacheScopes(event)...)
		}
		if err = w.repo.MarkPostFeedProjectionOutboxDelivered(ctx, event.ID, now); err != nil {
			return err
		}
	}
	return nil
}

type postFeedProjectionCachePayload struct {
	AuthorUserID string `json:"authorUserId"`
	CommunityID  string `json:"communityId"`
	Category     string `json:"category"`
}

func postFeedProjectionCacheScopes(event model.PostFeedProjectionOutboxEvent) []string {
	scopes := []string{postFeedCacheGlobalScope}
	if len(event.Payload) == 0 {
		return scopes
	}

	var payload postFeedProjectionCachePayload
	if err := json.Unmarshal(event.Payload, &payload); err != nil {
		return scopes
	}
	if authorID, err := uuid.Parse(strings.TrimSpace(payload.AuthorUserID)); err == nil && authorID != uuid.Nil {
		scopes = append(scopes, postFeedCacheAuthorScope(authorID))
	}
	if communityID, err := uuid.Parse(strings.TrimSpace(payload.CommunityID)); err == nil && communityID != uuid.Nil {
		scopes = append(scopes, postFeedCacheCommunityScope(communityID))
	}
	if category := strings.TrimSpace(payload.Category); category != "" {
		scopes = append(scopes, postFeedCacheCategoryScope(category))
	}
	return scopes
}

func (w *PostFeedProjectionWorker) backoff(attempt int) time.Duration {
	if attempt < 1 {
		attempt = 1
	}
	if w.cfg.MaxAttempts > 0 && attempt > w.cfg.MaxAttempts {
		attempt = w.cfg.MaxAttempts
	}
	if attempt > 6 {
		attempt = 6
	}
	return w.cfg.BaseBackoff * time.Duration(1<<uint(attempt-1))
}

func safePostFeedProjectionError(err error) string {
	if err == nil {
		return ""
	}
	value := strings.TrimSpace(err.Error())
	if len(value) > 512 {
		return value[:512]
	}
	return value
}
