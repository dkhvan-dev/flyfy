package app

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"reflect"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/enum"
	"kz/inflap/backend/services/feed-service/internal/domain/model"
	"kz/inflap/backend/services/feed-service/internal/domain/port"
)

func TestBuildFeedReturnsBlockBasedHomePage(t *testing.T) {
	authorID := uuid.New()
	now := time.Now().UTC()
	post := &model.Post{
		ID:               uuid.New(),
		Slug:             "almaty-weekend",
		AuthorUserID:     uuid.New(),
		Title:            "Almaty weekend",
		Excerpt:          "Short guide",
		Category:         enum.PostCategoryGuide,
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusNotRequired,
		CreatedAt:        now,
		UpdatedAt:        now,
		PublishedAt:      &now,
	}
	story := newFeedTestStory(authorID, "Camera moment", now)
	community := &model.Community{
		ID:            uuid.New(),
		Slug:          "almaty-guides",
		Title:         "Almaty Guides",
		Description:   "Local experiences",
		Topic:         "TRAVEL",
		LanguageCode:  "ru",
		Visibility:    enum.CommunityVisibilityPublic,
		PostingPolicy: enum.CommunityPostingPolicyMembersAfterModeration,
		Status:        enum.CommunityStatusActive,
		CreatedAt:     now,
		UpdatedAt:     now,
	}

	repo := &feedPostRepositoryStub{
		posts:       []*model.Post{post},
		stories:     []*model.Story{story},
		communities: []*model.Community{community},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

	page, err := useCase.BuildFeed(context.Background(), authorID.String(), BuildFeedInput{
		Surface: "home",
		Limit:   1,
	})
	if err != nil {
		t.Fatalf("BuildFeed returned error: %v", err)
	}

	if page.NextCursor != "" {
		t.Fatalf("NextCursor = %q, want empty cursor without another post", page.NextCursor)
	}
	if len(page.Items) != 3 {
		t.Fatalf("items = %d, want 3", len(page.Items))
	}
	if page.Items[0].Type != model.FeedBlockTypeStoriesTray {
		t.Fatalf("first block = %q, want stories tray", page.Items[0].Type)
	}
	if page.Items[1].Type != model.FeedBlockTypeSuggestedCommunities {
		t.Fatalf("second block = %q, want suggested communities", page.Items[1].Type)
	}
	if page.Items[2].Type != model.FeedBlockTypePostCard {
		t.Fatalf("third block = %q, want post card", page.Items[2].Type)
	}
}

func TestBuildFeedReturnsStoriesTrayForContextualDiscoverySurfaces(t *testing.T) {
	authorID := uuid.New()
	now := time.Now().UTC()
	story := newFeedTestStory(authorID, "Morning in Da Nang", now)

	for _, surface := range []string{"activities", "excursions"} {
		t.Run(surface, func(t *testing.T) {
			repo := &feedPostRepositoryStub{
				stories: []*model.Story{story},
			}
			useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

			page, err := useCase.BuildFeed(context.Background(), authorID.String(), BuildFeedInput{
				Surface: surface,
				Limit:   10,
			})
			if err != nil {
				t.Fatalf("BuildFeed returned error: %v", err)
			}
			if len(page.Items) != 1 {
				t.Fatalf("items = %d, want 1 stories tray block", len(page.Items))
			}

			block := page.Items[0]
			if block.Type != model.FeedBlockTypeStoriesTray {
				t.Fatalf("first block = %q, want stories tray", block.Type)
			}
			if block.ID != "posts:tray:"+surface {
				t.Fatalf("stories tray id = %q, want posts:tray:%s", block.ID, surface)
			}

			data, ok := block.Data.(StoriesTrayFeedData)
			if !ok {
				t.Fatalf("stories tray data = %T, want StoriesTrayFeedData", block.Data)
			}
			if len(data.Stories) != 1 || data.Stories[0].Story.ID != story.ID {
				t.Fatalf("stories tray stories = %#v, want story %s", data.Stories, story.ID)
			}
		})
	}
}

func TestBuildFeedSkipsStoriesTrayForGuests(t *testing.T) {
	authorID := uuid.New()
	now := time.Now().UTC()
	story := newFeedTestStory(authorID, "guest-hidden", now)

	repo := &feedPostRepositoryStub{
		stories: []*model.Story{story},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

	page, err := useCase.BuildFeed(context.Background(), "", BuildFeedInput{
		Surface: "home",
		Limit:   10,
	})
	if err != nil {
		t.Fatalf("BuildFeed returned error: %v", err)
	}

	for _, block := range page.Items {
		if block.Type == model.FeedBlockTypeStoriesTray {
			t.Fatalf("guest feed includes stories tray block: %+v", block)
		}
	}
}

func TestBuildFeedRequestsGeoScopedUnfollowedCommunitySuggestions(t *testing.T) {
	viewerID := uuid.New()
	authorID := uuid.New()
	now := time.Now().UTC()
	community := &model.Community{
		ID:            uuid.New(),
		Slug:          "da-nang-football",
		Title:         "Da Nang Football",
		Description:   "Pickup games",
		Topic:         "SPORT",
		CountryCode:   stringPtr("VN"),
		CityID:        stringPtr("da-nang"),
		LanguageCode:  "en",
		Visibility:    enum.CommunityVisibilityPublic,
		PostingPolicy: enum.CommunityPostingPolicyOpenMembers,
		Status:        enum.CommunityStatusActive,
		CreatedAt:     now,
		UpdatedAt:     now,
	}
	repo := &feedPostRepositoryStub{
		posts:                []*model.Post{newFeedTestPost(authorID, "latest", now)},
		communities:          []*model.Community{community},
		communityListFilters: make([]model.CommunityListFilter, 0),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test")

	page, err := useCase.BuildFeed(context.Background(), viewerID.String(), BuildFeedInput{
		Surface:     "home",
		CountryCode: " vn ",
		CityID:      " da-nang ",
		Limit:       10,
	})
	if err != nil {
		t.Fatalf("BuildFeed returned error: %v", err)
	}
	if len(repo.communityListFilters) != 1 {
		t.Fatalf("community list filters = %d, want 1", len(repo.communityListFilters))
	}
	filter := repo.communityListFilters[0]
	if filter.CountryCode != "VN" || filter.CityID != "da-nang" {
		t.Fatalf("community geo filter = %q/%q, want VN/da-nang", filter.CountryCode, filter.CityID)
	}
	if filter.ExcludeFollowedByUserID == nil || *filter.ExcludeFollowedByUserID != viewerID {
		t.Fatalf("exclude followed user = %v, want viewer id", filter.ExcludeFollowedByUserID)
	}
	if len(page.Items) < 1 || page.Items[0].Type != model.FeedBlockTypeSuggestedCommunities {
		t.Fatalf("first feed block = %#v, want suggested communities", page.Items)
	}
}

func TestBuildFeedReturnsRankingExperimentAssignment(t *testing.T) {
	authorID := uuid.New()
	now := time.Now().UTC()
	repo := &feedPostRepositoryStub{
		posts: []*model.Post{newFeedTestPost(authorID, "ranked", now)},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test").
		WithFeedExperimentAssignment("rank-v2")

	page, err := useCase.BuildFeed(context.Background(), "", BuildFeedInput{
		Surface: "content",
		Limit:   1,
	})
	if err != nil {
		t.Fatalf("BuildFeed returned error: %v", err)
	}
	if page.Assignment.RankingExperiment != "rank-v2" {
		t.Fatalf("ranking experiment = %q, want rank-v2", page.Assignment.RankingExperiment)
	}
}

func TestBuildFeedAssignsStickyRankingExperimentVariantForViewer(t *testing.T) {
	viewerID := uuid.New()
	authorID := uuid.New()
	now := time.Now().UTC()
	repo := &feedPostRepositoryStub{
		posts: []*model.Post{newFeedTestPost(authorID, "ranked", now)},
	}
	cache := &postFeedCacheFake{
		version: 3,
		posts:   make(map[string][]*model.Post),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test").
		WithPostFeedCache(cache, time.Minute, 30*time.Second).
		WithFeedExperimentAssignment("control").
		WithFeedExperimentVariants("rank-v2=100")

	firstPage, err := useCase.BuildFeed(context.Background(), viewerID.String(), BuildFeedInput{
		Surface: "content",
		Limit:   1,
	})
	if err != nil {
		t.Fatalf("BuildFeed first call returned error: %v", err)
	}
	secondPage, err := useCase.BuildFeed(context.Background(), viewerID.String(), BuildFeedInput{
		Surface: "content",
		Limit:   1,
	})
	if err != nil {
		t.Fatalf("BuildFeed second call returned error: %v", err)
	}
	if firstPage.Assignment.RankingExperiment != "rank-v2" ||
		secondPage.Assignment.RankingExperiment != "rank-v2" {
		t.Fatalf("sticky assignment = %q/%q, want rank-v2", firstPage.Assignment.RankingExperiment, secondPage.Assignment.RankingExperiment)
	}

	guestPage, err := useCase.BuildFeed(context.Background(), "", BuildFeedInput{
		Surface: "content",
		Limit:   1,
	})
	if err != nil {
		t.Fatalf("BuildFeed guest call returned error: %v", err)
	}
	if guestPage.Assignment.RankingExperiment != "control" {
		t.Fatalf("guest assignment = %q, want control", guestPage.Assignment.RankingExperiment)
	}

	key, _, cacheable := useCase.postFeedPostListCacheKey(
		context.Background(),
		&viewerID,
		20,
		0,
		nil,
		feedPostCandidateSource{Name: model.PostCandidateSourceInterest},
		"KZ",
		"almaty",
		nil,
		postFeedExpiryPersistent,
	)
	if !cacheable {
		t.Fatal("viewer experiment cache key should be cacheable")
	}
	if !strings.Contains(key, "rank:rank-v2") {
		t.Fatalf("cache key = %q, want assigned rank-v2 segment", key)
	}
}

func TestBuildFeedAppliesRankingPolicyOverridesForAssignedExperiment(t *testing.T) {
	viewerID := uuid.New()
	authorID := uuid.New()
	now := time.Now().UTC()
	post := newFeedTestPost(authorID, "experiment-policy-post", now)
	repo := &feedPostRepositoryStub{
		posts:             []*model.Post{post},
		listFeedPostCalls: make([]model.PostListFilter, 0),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test").
		WithFeedExperimentAssignment("control").
		WithFeedExperimentVariants("rank-social-v2=100").
		WithFeedExperimentPolicyOverrides("rank-social-v2:socialFriendBoostHours=34,socialFollowingBoostHours=21,postInterestWeight=1.4,maxPostsPerAuthorPerPage=2,directNegativeFeedbackDecayWindow=72h")

	page, err := useCase.BuildFeed(context.Background(), viewerID.String(), BuildFeedInput{
		Surface: "content",
		Tab:     "for_you",
		Limit:   5,
	})
	if err != nil {
		t.Fatalf("BuildFeed returned error: %v", err)
	}
	if page.Assignment.RankingExperiment != "rank-social-v2" {
		t.Fatalf("assignment = %q, want rank-social-v2", page.Assignment.RankingExperiment)
	}
	if len(repo.listFeedPostCalls) == 0 {
		t.Fatal("ListFeedPosts was not called")
	}
	override := repo.listFeedPostCalls[0].FeedRankingPolicyOverride
	if override == nil {
		t.Fatal("FeedRankingPolicyOverride is nil")
	}
	if override.ExperimentKey != "rank-social-v2" {
		t.Fatalf("override experiment = %q, want rank-social-v2", override.ExperimentKey)
	}
	if override.SocialFriendBoostHours == nil || *override.SocialFriendBoostHours != 34 {
		t.Fatalf("social friend override = %v, want 34", override.SocialFriendBoostHours)
	}
	if override.SocialFollowingBoostHours == nil || *override.SocialFollowingBoostHours != 21 {
		t.Fatalf("social following override = %v, want 21", override.SocialFollowingBoostHours)
	}
	if override.PostInterestWeight == nil || *override.PostInterestWeight != 1.4 {
		t.Fatalf("post interest override = %v, want 1.4", override.PostInterestWeight)
	}
	if override.MaxPostsPerAuthorPerPage == nil || *override.MaxPostsPerAuthorPerPage != 2 {
		t.Fatalf("author diversity cap override = %v, want 2", override.MaxPostsPerAuthorPerPage)
	}
	if override.DirectNegativeFeedbackDecayWindow == nil || *override.DirectNegativeFeedbackDecayWindow != 72*time.Hour {
		t.Fatalf("direct negative decay override = %v, want 72h", override.DirectNegativeFeedbackDecayWindow)
	}
}

func TestBuildFeedMarksFriendAuthors(t *testing.T) {
	viewerID := uuid.New()
	friendID := uuid.New()
	strangerID := uuid.New()
	now := time.Now().UTC()
	repo := &feedPostRepositoryStub{
		posts: []*model.Post{
			newFeedTestPost(friendID, "friend-post", now),
			newFeedTestPost(strangerID, "stranger-post", now.Add(-time.Minute)),
		},
		feedSocialEdges: map[uuid.UUID]model.FeedSocialEdgeSet{
			friendID: {Friend: true},
		},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{
		userID:     viewerID,
		friendsErr: errors.New("user social graph unavailable"),
	}, "https://posts.test")

	page, err := useCase.BuildFeed(context.Background(), viewerID.String(), BuildFeedInput{
		Surface: "content",
		Limit:   2,
	})
	if err != nil {
		t.Fatalf("BuildFeed returned error: %v", err)
	}
	cards := postCardFeedData(page.Items)
	if len(cards) != 2 {
		t.Fatalf("post cards = %d, want 2", len(cards))
	}
	if cards[0].Post == nil || !cards[0].Post.Author.IsFriendOfViewer {
		t.Fatalf("friend author marker = %+v, want friend", cards[0].Post)
	}
	if cards[1].Post == nil || cards[1].Post.Author.IsFriendOfViewer {
		t.Fatalf("stranger author marker = %+v, want not friend", cards[1].Post)
	}
}

func TestBuildFeedRepairsMissingFriendEdgesFromUserService(t *testing.T) {
	viewerID := uuid.New()
	friendID := uuid.New()
	strangerID := uuid.New()
	now := time.Now().UTC()
	repo := &feedPostRepositoryStub{
		posts: []*model.Post{
			newFeedTestPost(friendID, "friend-post", now),
			newFeedTestPost(strangerID, "stranger-post", now.Add(-time.Minute)),
		},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{
		userID: viewerID,
		friendUserIDs: map[uuid.UUID]bool{
			friendID: true,
		},
	}, "https://posts.test")

	page, err := useCase.BuildFeed(context.Background(), viewerID.String(), BuildFeedInput{
		Surface: "content",
		Limit:   2,
	})
	if err != nil {
		t.Fatalf("BuildFeed returned error: %v", err)
	}
	cards := postCardFeedData(page.Items)
	if len(cards) != 2 {
		t.Fatalf("post cards = %d, want 2", len(cards))
	}
	if cards[0].Post == nil || !cards[0].Post.Author.IsFriendOfViewer {
		t.Fatalf("friend author marker = %+v, want repaired friend marker", cards[0].Post)
	}
	if cards[1].Post == nil || cards[1].Post.Author.IsFriendOfViewer {
		t.Fatalf("stranger author marker = %+v, want not friend", cards[1].Post)
	}
	if len(repo.upsertedSocialEdges) != 1 {
		t.Fatalf("repaired edges = %d, want 1", len(repo.upsertedSocialEdges))
	}
	edge := repo.upsertedSocialEdges[0]
	if edge.ViewerUserID != viewerID ||
		edge.TargetUserID != friendID ||
		edge.EdgeType != model.FeedSocialEdgeTypeFriend ||
		edge.SourceEventID != nil ||
		edge.SourceUpdatedAt.IsZero() {
		t.Fatalf("repaired edge = %+v, want friend edge without event id", edge)
	}
}

func TestBuildFeedRemovesStaleFriendEdgesMissingFromUserService(t *testing.T) {
	viewerID := uuid.New()
	staleFriendID := uuid.New()
	now := time.Now().UTC()
	repo := &feedPostRepositoryStub{
		posts: []*model.Post{
			newFeedTestPost(staleFriendID, "stale-friend-post", now),
		},
		feedSocialEdges: map[uuid.UUID]model.FeedSocialEdgeSet{
			staleFriendID: {Friend: true},
		},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{
		userID:        viewerID,
		friendUserIDs: map[uuid.UUID]bool{},
	}, "https://posts.test")

	page, err := useCase.BuildFeed(context.Background(), viewerID.String(), BuildFeedInput{
		Surface: "content",
		Limit:   1,
	})
	if err != nil {
		t.Fatalf("BuildFeed returned error: %v", err)
	}
	cards := postCardFeedData(page.Items)
	if len(cards) != 1 {
		t.Fatalf("post cards = %d, want 1", len(cards))
	}
	if cards[0].Post == nil || cards[0].Post.Author.IsFriendOfViewer {
		t.Fatalf("friend author marker = %+v, want stale friend marker removed", cards[0].Post)
	}
	if len(repo.deletedSocialEdges) != 1 {
		t.Fatalf("deleted social edges = %d, want 1", len(repo.deletedSocialEdges))
	}
	deleted := repo.deletedSocialEdges[0]
	if deleted.viewerUserID != viewerID ||
		deleted.targetUserID != staleFriendID ||
		deleted.edgeType != model.FeedSocialEdgeTypeFriend ||
		deleted.sourceUpdatedAt.IsZero() {
		t.Fatalf("deleted edge = %+v, want stale friend tombstone", deleted)
	}
}

func TestBuildFeedRemovesStaleFollowingEdgesMissingFromUserService(t *testing.T) {
	viewerID := uuid.New()
	staleFollowedID := uuid.New()
	now := time.Now().UTC()
	repo := &feedPostRepositoryStub{
		posts: []*model.Post{
			newFeedTestPost(staleFollowedID, "stale-followed-post", now),
		},
		feedSocialEdges: map[uuid.UUID]model.FeedSocialEdgeSet{
			staleFollowedID: {Following: true},
		},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{
		userID:           viewerID,
		followingUserIDs: map[uuid.UUID]bool{},
	}, "https://posts.test")

	_, err := useCase.BuildFeed(context.Background(), viewerID.String(), BuildFeedInput{
		Surface: "content",
		Limit:   1,
	})
	if err != nil {
		t.Fatalf("BuildFeed returned error: %v", err)
	}
	if len(repo.deletedSocialEdges) != 1 {
		t.Fatalf("deleted social edges = %d, want 1", len(repo.deletedSocialEdges))
	}
	deleted := repo.deletedSocialEdges[0]
	if deleted.viewerUserID != viewerID ||
		deleted.targetUserID != staleFollowedID ||
		deleted.edgeType != model.FeedSocialEdgeTypeFollowing ||
		deleted.sourceUpdatedAt.IsZero() {
		t.Fatalf("deleted edge = %+v, want stale following tombstone", deleted)
	}
	if repo.feedSocialEdges[staleFollowedID].Following {
		t.Fatalf("following edge remains active after repair")
	}
}

func TestBuildFeedRepairingMissingSocialEdgesInvalidatesViewerFeedCache(t *testing.T) {
	viewerID := uuid.New()
	friendID := uuid.New()
	now := time.Now().UTC()
	repo := &feedPostRepositoryStub{
		posts: []*model.Post{
			newFeedTestPost(friendID, "friend-post", now),
		},
	}
	cache := &postFeedCacheFake{posts: make(map[string][]*model.Post)}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{
		userID: viewerID,
		friendUserIDs: map[uuid.UUID]bool{
			friendID: true,
		},
	}, "https://posts.test").WithPostFeedCache(cache, time.Minute, time.Minute)

	_, err := useCase.BuildFeed(context.Background(), viewerID.String(), BuildFeedInput{
		Surface: "content",
		Limit:   1,
	})
	if err != nil {
		t.Fatalf("BuildFeed returned error: %v", err)
	}

	wantScopes := []string{
		postFeedCacheViewerScope(viewerID),
		postFeedCacheFollowingScope(viewerID),
		postFeedCacheDiscoveryScope(viewerID),
	}
	for _, scope := range wantScopes {
		if !containsString(cache.bumpedScopes, scope) {
			t.Fatalf("bumped scopes = %#v, want repaired social edge to invalidate %s", cache.bumpedScopes, scope)
		}
	}
}

func TestBuildFeedRepairsMissingFollowingEdgesFromUserService(t *testing.T) {
	viewerID := uuid.New()
	followedAuthorID := uuid.New()
	strangerID := uuid.New()
	now := time.Now().UTC()
	repo := &feedPostRepositoryStub{
		posts: []*model.Post{
			newFeedTestPost(followedAuthorID, "followed-author-post", now),
			newFeedTestPost(strangerID, "stranger-post", now.Add(-time.Minute)),
		},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{
		userID: viewerID,
		followingUserIDs: map[uuid.UUID]bool{
			followedAuthorID: true,
		},
	}, "https://posts.test")

	page, err := useCase.BuildFeed(context.Background(), viewerID.String(), BuildFeedInput{
		Surface: "content",
		Limit:   2,
	})
	if err != nil {
		t.Fatalf("BuildFeed returned error: %v", err)
	}
	cards := postCardFeedData(page.Items)
	if len(cards) != 2 {
		t.Fatalf("post cards = %d, want 2", len(cards))
	}
	if cards[0].Post == nil || cards[0].Post.Author.IsFriendOfViewer {
		t.Fatalf("following author marker = %+v, want not friend", cards[0].Post)
	}
	if len(repo.upsertedSocialEdges) != 1 {
		t.Fatalf("repaired edges = %d, want 1", len(repo.upsertedSocialEdges))
	}
	edge := repo.upsertedSocialEdges[0]
	if edge.ViewerUserID != viewerID ||
		edge.TargetUserID != followedAuthorID ||
		edge.EdgeType != model.FeedSocialEdgeTypeFollowing ||
		edge.SourceEventID != nil ||
		edge.SourceUpdatedAt.IsZero() {
		t.Fatalf("repaired edge = %+v, want following edge without event id", edge)
	}
}

func TestApplyFeedSocialEventUpsertsEdgeAndInvalidatesViewerCache(t *testing.T) {
	viewerID := uuid.New()
	targetID := uuid.New()
	eventID := uuid.New()
	occurredAt := time.Date(2026, 6, 15, 10, 30, 0, 0, time.UTC)
	repo := &feedPostRepositoryStub{}
	cache := &postFeedCacheFake{}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{}, "https://posts.test").
		WithPostFeedCache(cache, time.Minute, time.Minute)

	err := useCase.ApplyFeedSocialEvent(context.Background(), ApplyFeedSocialEventInput{
		EventID:         eventID,
		ViewerUserID:    viewerID,
		TargetUserID:    targetID,
		EdgeType:        model.FeedSocialEdgeTypeFollowing,
		Active:          true,
		SourceUpdatedAt: occurredAt,
	})
	if err != nil {
		t.Fatalf("ApplyFeedSocialEvent returned error: %v", err)
	}

	if len(repo.upsertedSocialEdges) != 1 {
		t.Fatalf("upserted social edges = %d, want 1", len(repo.upsertedSocialEdges))
	}
	edge := repo.upsertedSocialEdges[0]
	if edge.ViewerUserID != viewerID ||
		edge.TargetUserID != targetID ||
		edge.EdgeType != model.FeedSocialEdgeTypeFollowing ||
		edge.SourceEventID == nil ||
		*edge.SourceEventID != eventID ||
		!edge.SourceUpdatedAt.Equal(occurredAt) {
		t.Fatalf("unexpected upserted edge: %+v", edge)
	}
	if !containsString(cache.bumpedScopes, postFeedCacheViewerScope(viewerID)) ||
		!containsString(cache.bumpedScopes, postFeedCacheFollowingScope(viewerID)) {
		t.Fatalf("bumped scopes = %#v, want viewer and following scopes", cache.bumpedScopes)
	}
}

func TestApplyFeedSocialEventSkipsCacheInvalidationWhenReadModelIsUnchanged(t *testing.T) {
	viewerID := uuid.New()
	targetID := uuid.New()
	repo := &feedPostRepositoryStub{
		feedSocialEdges: map[uuid.UUID]model.FeedSocialEdgeSet{
			targetID: {Following: true},
		},
	}
	cache := &postFeedCacheFake{}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{}, "https://posts.test").
		WithPostFeedCache(cache, time.Minute, time.Minute)

	err := useCase.ApplyFeedSocialEvent(context.Background(), ApplyFeedSocialEventInput{
		EventID:         uuid.New(),
		ViewerUserID:    viewerID,
		TargetUserID:    targetID,
		EdgeType:        model.FeedSocialEdgeTypeFollowing,
		Active:          true,
		SourceUpdatedAt: time.Date(2026, 6, 15, 10, 30, 0, 0, time.UTC),
	})
	if err != nil {
		t.Fatalf("ApplyFeedSocialEvent returned error: %v", err)
	}

	if len(repo.upsertedSocialEdges) != 0 {
		t.Fatalf("upserted social edges = %d, want unchanged read-model", len(repo.upsertedSocialEdges))
	}
	if cache.bumps != 0 || len(cache.bumpedScopes) != 0 {
		t.Fatalf("cache bumps = %d scopes = %#v, want no cache invalidation for unchanged edge", cache.bumps, cache.bumpedScopes)
	}
}

func TestApplyFeedSocialEventDeletesEdgeWithTombstoneSemantics(t *testing.T) {
	viewerID := uuid.New()
	targetID := uuid.New()
	occurredAt := time.Date(2026, 6, 15, 11, 0, 0, 0, time.UTC)
	repo := &feedPostRepositoryStub{}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{}, "https://posts.test")

	err := useCase.ApplyFeedSocialEvent(context.Background(), ApplyFeedSocialEventInput{
		EventID:         uuid.New(),
		ViewerUserID:    viewerID,
		TargetUserID:    targetID,
		EdgeType:        model.FeedSocialEdgeTypeFriend,
		Active:          false,
		SourceUpdatedAt: occurredAt,
	})
	if err != nil {
		t.Fatalf("ApplyFeedSocialEvent returned error: %v", err)
	}

	if len(repo.deletedSocialEdges) != 1 {
		t.Fatalf("deleted social edges = %d, want 1", len(repo.deletedSocialEdges))
	}
	deleted := repo.deletedSocialEdges[0]
	if deleted.viewerUserID != viewerID ||
		deleted.targetUserID != targetID ||
		deleted.edgeType != model.FeedSocialEdgeTypeFriend ||
		!deleted.sourceUpdatedAt.Equal(occurredAt) {
		t.Fatalf("unexpected deleted edge: %+v", deleted)
	}
}

func TestBuildFeedDoesNotAddDeprecatedContentConversionBlocks(t *testing.T) {
	viewerID := uuid.New()
	now := time.Now().UTC()
	repo := &feedPostRepositoryStub{
		posts: []*model.Post{newFeedTestPost(uuid.New(), "ranked", now)},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test")

	page, err := useCase.BuildFeed(context.Background(), viewerID.String(), BuildFeedInput{
		Surface: "content",
		Tab:     "for_you",
		Limit:   1,
	})
	if err != nil {
		t.Fatalf("BuildFeed returned error: %v", err)
	}
	conversionBlocks := conversionFeedBlocks(page.Items)
	if len(conversionBlocks) != 0 {
		t.Fatalf("conversion blocks = %d, want none: %+v", len(conversionBlocks), conversionBlocks)
	}
	postCards := postCardFeedData(page.Items)
	if len(postCards) != 1 {
		t.Fatalf("post cards = %d, want post card preserved", len(postCards))
	}
	if page.Items[0].Type != model.FeedBlockTypePostCard || page.Items[0].Rank != 0 {
		t.Fatalf("first block = %+v, want post card at rank 0 after removing conversion blocks", page.Items[0])
	}
}

func TestBuildFeedUsesOpaqueCursorAfterLastPost(t *testing.T) {
	authorID := uuid.New()
	firstPublishedAt := time.Date(2026, 6, 11, 12, 0, 0, 0, time.UTC)
	secondPublishedAt := firstPublishedAt.Add(-time.Minute)
	posts := []*model.Post{
		newFeedTestPost(authorID, "first", firstPublishedAt),
		newFeedTestPost(authorID, "second", secondPublishedAt),
	}

	repo := &feedPostRepositoryStub{posts: posts}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

	firstPage, err := useCase.BuildFeed(context.Background(), "", BuildFeedInput{
		Surface: "content",
		Limit:   1,
	})
	if err != nil {
		t.Fatalf("BuildFeed first page returned error: %v", err)
	}
	if firstPage.NextCursor == "" {
		t.Fatal("NextCursor is empty, want cursor after first post")
	}
	if firstPage.NextCursor == "1" || strings.Contains(firstPage.NextCursor, "offset") {
		t.Fatalf("NextCursor = %q, want opaque keyset cursor", firstPage.NextCursor)
	}

	secondPage, err := useCase.BuildFeed(context.Background(), "", BuildFeedInput{
		Surface: "content",
		Limit:   1,
		Cursor:  firstPage.NextCursor,
	})
	if err != nil {
		t.Fatalf("BuildFeed second page returned error: %v", err)
	}
	if len(secondPage.Items) != 1 {
		t.Fatalf("second page items = %d, want 1", len(secondPage.Items))
	}
	data, ok := secondPage.Items[0].Data.(PostCardFeedData)
	if !ok || data.Post == nil || data.Post.Post == nil {
		t.Fatalf("second page data = %#v, want post card data", secondPage.Items[0].Data)
	}
	if data.Post.Post.ID != posts[1].ID {
		t.Fatalf("second page post = %s, want %s", data.Post.Post.ID, posts[1].ID)
	}
}

func TestBuildFeedRejectsMalformedCursor(t *testing.T) {
	authorID := uuid.New()
	repo := &feedPostRepositoryStub{
		posts: []*model.Post{
			newFeedTestPost(authorID, "first", time.Now().UTC()),
		},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

	_, err := useCase.BuildFeed(context.Background(), "", BuildFeedInput{
		Surface: "content",
		Limit:   10,
		Cursor:  "not-a-valid-feed-cursor",
	})

	if !errors.Is(err, ErrInvalidFeedCursor) {
		t.Fatalf("BuildFeed error = %v, want %v", err, ErrInvalidFeedCursor)
	}
}

func TestBuildFeedRejectsCursorFromDifferentContext(t *testing.T) {
	authorID := uuid.New()
	viewerID := uuid.New()
	now := time.Now().UTC()
	repo := &feedPostRepositoryStub{
		posts: []*model.Post{
			newFeedTestPost(authorID, "first", now),
			newFeedTestPost(authorID, "second", now.Add(-time.Minute)),
		},
		userCommunityIDs: []uuid.UUID{uuid.New()},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test")

	firstPage, err := useCase.BuildFeed(context.Background(), viewerID.String(), BuildFeedInput{
		Surface: "content",
		Tab:     "for_you",
		Limit:   1,
	})
	if err != nil {
		t.Fatalf("BuildFeed first page returned error: %v", err)
	}
	if firstPage.NextCursor == "" {
		t.Fatal("NextCursor is empty, want cursor after first post")
	}

	tests := map[string]BuildFeedInput{
		"different_surface": {
			Surface: "home",
			Tab:     "for_you",
			Limit:   1,
			Cursor:  firstPage.NextCursor,
		},
		"different_tab": {
			Surface: "content",
			Tab:     "following",
			Limit:   1,
			Cursor:  firstPage.NextCursor,
		},
	}
	for name, input := range tests {
		t.Run(name, func(t *testing.T) {
			_, err := useCase.BuildFeed(context.Background(), viewerID.String(), input)

			if !errors.Is(err, ErrInvalidFeedCursor) {
				t.Fatalf("BuildFeed error = %v, want %v", err, ErrInvalidFeedCursor)
			}
		})
	}
}

func TestBuildFeedRejectsCursorFromDifferentRankingExperiment(t *testing.T) {
	authorID := uuid.New()
	viewerID := uuid.New()
	now := time.Now().UTC()
	repo := &feedPostRepositoryStub{
		posts: []*model.Post{
			newFeedTestPost(authorID, "first", now),
			newFeedTestPost(authorID, "second", now.Add(-time.Minute)),
		},
	}
	rankV2UseCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test").
		WithFeedExperimentAssignment("control").
		WithFeedExperimentVariants("rank-v2=100")

	firstPage, err := rankV2UseCase.BuildFeed(context.Background(), viewerID.String(), BuildFeedInput{
		Surface: "content",
		Tab:     "for_you",
		Limit:   1,
	})
	if err != nil {
		t.Fatalf("BuildFeed first page returned error: %v", err)
	}
	if firstPage.NextCursor == "" {
		t.Fatal("NextCursor is empty, want cursor after first post")
	}
	if firstPage.Assignment.RankingExperiment != "rank-v2" {
		t.Fatalf("first page assignment = %q, want rank-v2", firstPage.Assignment.RankingExperiment)
	}

	controlUseCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test").
		WithFeedExperimentAssignment("control")
	_, err = controlUseCase.BuildFeed(context.Background(), viewerID.String(), BuildFeedInput{
		Surface: "content",
		Tab:     "for_you",
		Limit:   1,
		Cursor:  firstPage.NextCursor,
	})
	if !errors.Is(err, ErrInvalidFeedCursor) {
		t.Fatalf("BuildFeed error = %v, want %v for ranking experiment switch", err, ErrInvalidFeedCursor)
	}
}

func TestDecodeFeedCursorRejectsStaleCandidateMixerPolicy(t *testing.T) {
	now := time.Now().UTC()
	payload, err := json.Marshal(map[string]any{
		"v":               feedCursorVersion,
		"surface":         "content",
		"tab":             "for_you",
		"publishedAt":     now.Format(time.RFC3339Nano),
		"postId":          uuid.New().String(),
		"candidatePolicy": "candidate-mixer:stale",
	})
	if err != nil {
		t.Fatalf("marshal cursor payload: %v", err)
	}
	cursor := base64.RawURLEncoding.EncodeToString(payload)

	_, err = decodeFeedCursor(cursor, "content", "for_you", "control")

	if !errors.Is(err, ErrInvalidFeedCursor) {
		t.Fatalf("decodeFeedCursor error = %v, want %v for stale candidate policy", err, ErrInvalidFeedCursor)
	}
}

func TestFeedCursorRoundTripPreservesColdStartRandomSeed(t *testing.T) {
	wantSeed := int64(987654321)
	wantPostID := uuid.New()
	wantPublishedAt := time.Date(2026, 7, 11, 12, 30, 0, 0, time.UTC)
	encoded := encodeFeedCursor(&feedCursor{
		PublishedAt:         wantPublishedAt,
		PostID:              wantPostID,
		ColdStartRandomSeed: wantSeed,
	}, "content", "for_you", "control")

	decoded, err := decodeFeedCursor(encoded, "content", "for_you", "control")
	if err != nil {
		t.Fatalf("decodeFeedCursor returned error: %v", err)
	}
	if decoded.ColdStartRandomSeed != wantSeed {
		t.Fatalf("decoded random seed = %d, want %d", decoded.ColdStartRandomSeed, wantSeed)
	}
	if decoded.PostID != wantPostID || !decoded.PublishedAt.Equal(wantPublishedAt) {
		t.Fatalf("decoded cursor = %+v, want post %s at %s", decoded, wantPostID, wantPublishedAt)
	}
}

func TestDecodeFeedCursorRejectsPreviousCandidateMixerV3Policy(t *testing.T) {
	now := time.Now().UTC()
	payload, err := json.Marshal(map[string]any{
		"v":               feedCursorVersion,
		"surface":         "content",
		"tab":             "following",
		"publishedAt":     now.Format(time.RFC3339Nano),
		"postId":          uuid.New().String(),
		"candidatePolicy": "candidate-mixer:v3",
	})
	if err != nil {
		t.Fatalf("marshal cursor payload: %v", err)
	}
	cursor := base64.RawURLEncoding.EncodeToString(payload)

	_, err = decodeFeedCursor(cursor, "content", "following", "control")

	if !errors.Is(err, ErrInvalidFeedCursor) {
		t.Fatalf("decodeFeedCursor error = %v, want %v for previous candidate policy", err, ErrInvalidFeedCursor)
	}
}

func TestDecodeFeedCursorRejectsPreviousCandidateMixerV4Policy(t *testing.T) {
	now := time.Now().UTC()
	payload, err := json.Marshal(map[string]any{
		"v":               feedCursorVersion,
		"surface":         "content",
		"tab":             "for_you",
		"publishedAt":     now.Format(time.RFC3339Nano),
		"postId":          uuid.New().String(),
		"candidatePolicy": "candidate-mixer:v4",
	})
	if err != nil {
		t.Fatalf("marshal cursor payload: %v", err)
	}
	cursor := base64.RawURLEncoding.EncodeToString(payload)

	_, err = decodeFeedCursor(cursor, "content", "for_you", "control")

	if !errors.Is(err, ErrInvalidFeedCursor) {
		t.Fatalf("decodeFeedCursor error = %v, want %v for previous candidate policy", err, ErrInvalidFeedCursor)
	}
}

func TestDecodeFeedCursorRejectsPreviousCandidateMixerV6Policy(t *testing.T) {
	now := time.Now().UTC()
	payload, err := json.Marshal(map[string]any{
		"v":               feedCursorVersion,
		"surface":         "content",
		"tab":             "for_you",
		"publishedAt":     now.Format(time.RFC3339Nano),
		"postId":          uuid.New().String(),
		"candidatePolicy": "candidate-mixer:v6",
	})
	if err != nil {
		t.Fatalf("marshal cursor payload: %v", err)
	}
	cursor := base64.RawURLEncoding.EncodeToString(payload)

	_, err = decodeFeedCursor(cursor, "content", "for_you", "control")

	if !errors.Is(err, ErrInvalidFeedCursor) {
		t.Fatalf("decodeFeedCursor error = %v, want %v for previous candidate policy", err, ErrInvalidFeedCursor)
	}
}

func TestDecodeFeedCursorRejectsPreviousCandidateMixerV7Policy(t *testing.T) {
	now := time.Now().UTC()
	payload, err := json.Marshal(map[string]any{
		"v":               feedCursorVersion,
		"surface":         "content",
		"tab":             "for_you",
		"publishedAt":     now.Format(time.RFC3339Nano),
		"postId":          uuid.New().String(),
		"candidatePolicy": "candidate-mixer:v7",
	})
	if err != nil {
		t.Fatalf("marshal cursor payload: %v", err)
	}
	cursor := base64.RawURLEncoding.EncodeToString(payload)

	_, err = decodeFeedCursor(cursor, "content", "for_you", "control")

	if !errors.Is(err, ErrInvalidFeedCursor) {
		t.Fatalf("decodeFeedCursor error = %v, want %v for previous candidate policy", err, ErrInvalidFeedCursor)
	}
}

func TestBuildFeedUsesBatchPostLikeLookup(t *testing.T) {
	authorID := uuid.New()
	viewerID := uuid.New()
	now := time.Now().UTC()
	posts := []*model.Post{
		newFeedTestPost(authorID, "first", now),
		newFeedTestPost(authorID, "second", now.Add(-time.Minute)),
	}

	repo := &feedPostRepositoryStub{
		posts:               posts,
		viewerLikedPostIDs:  map[uuid.UUID]bool{posts[1].ID: true},
		batchPostLikesCalls: make([][]uuid.UUID, 0),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test")

	page, err := useCase.BuildFeed(context.Background(), "subject", BuildFeedInput{
		Surface: "content",
		Limit:   2,
	})
	if err != nil {
		t.Fatalf("BuildFeed returned error: %v", err)
	}
	if repo.hasPostLikeCalls != 0 {
		t.Fatalf("HasPostLike calls = %d, want 0 batch-only lookup", repo.hasPostLikeCalls)
	}
	if len(repo.batchPostLikesCalls) == 0 {
		t.Fatal("batch post like calls are empty, want batch lookup")
	}
	for _, call := range repo.batchPostLikesCalls {
		if len(call) != 2 {
			t.Fatalf("batch post like calls = %#v, want calls with two post ids", repo.batchPostLikesCalls)
		}
	}
	likedByPostID := make(map[uuid.UUID]bool, len(page.Items))
	for _, item := range page.Items {
		data, ok := item.Data.(PostCardFeedData)
		if !ok || data.Post == nil || data.Post.Post == nil {
			continue
		}
		likedByPostID[data.Post.Post.ID] = data.Post.LikedByViewer
	}
	if likedByPostID[posts[0].ID] {
		t.Fatalf("first post likedByViewer = true, want false")
	}
	if !likedByPostID[posts[1].ID] {
		t.Fatalf("second post likedByViewer = false, want true")
	}
}

func TestBuildFeedDoesNotRepeatStoriesAsPostCards(t *testing.T) {
	authorID := uuid.New()
	now := time.Now().UTC()
	post := newFeedTestPost(authorID, "post", now)
	stories := []*model.Story{
		newFeedTestStory(authorID, "first", now),
		newFeedTestStory(authorID, "second", now.Add(-time.Minute)),
	}

	repo := &feedPostRepositoryStub{
		posts:   []*model.Post{post},
		stories: stories,
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

	page, err := useCase.BuildFeed(context.Background(), authorID.String(), BuildFeedInput{
		Surface: "home",
		Limit:   2,
	})
	if err != nil {
		t.Fatalf("BuildFeed returned error: %v", err)
	}

	storyIDs := make(map[uuid.UUID]string)
	for _, block := range page.Items {
		switch data := block.Data.(type) {
		case StoriesTrayFeedData:
			for _, story := range data.Stories {
				if story == nil || story.Story == nil {
					continue
				}
				storyIDs[story.Story.ID] = block.Type
			}
		case PostCardFeedData:
			if data.Post == nil || data.Post.Post == nil {
				continue
			}
			if previousBlockType, exists := storyIDs[data.Post.Post.ID]; exists {
				t.Fatalf("post %s appears in %s and %s", data.Post.Post.ID, previousBlockType, block.Type)
			}
		}
	}
	if len(storyIDs) != 2 {
		t.Fatalf("tray stories = %d, want 2", len(storyIDs))
	}
}

func TestBuildFeedSeparatesStoriesTrayFromPersistentPostCards(t *testing.T) {
	authorID := uuid.New()
	now := time.Now().UTC()
	story := newFeedTestStory(authorID, "your-post", now.Add(-time.Minute))
	persistentPost := newFeedTestPost(uuid.New(), "travel-post", now)

	repo := &feedPostRepositoryStub{
		posts:   []*model.Post{persistentPost},
		stories: []*model.Story{story},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

	page, err := useCase.BuildFeed(context.Background(), authorID.String(), BuildFeedInput{
		Surface: "home",
		Limit:   2,
	})
	if err != nil {
		t.Fatalf("BuildFeed returned error: %v", err)
	}

	trayStoryIDs := make(map[uuid.UUID]bool)
	for _, block := range page.Items {
		data, ok := block.Data.(StoriesTrayFeedData)
		if !ok {
			continue
		}
		for _, story := range data.Stories {
			if story == nil || story.Story == nil {
				continue
			}
			trayStoryIDs[story.Story.ID] = true
		}
	}
	if !trayStoryIDs[story.ID] {
		t.Fatalf("story %s is absent from stories tray", story.ID)
	}
	if trayStoryIDs[persistentPost.ID] {
		t.Fatalf("persistent post %s is present in stories tray", persistentPost.ID)
	}

	postCards := postCardFeedData(page.Items)
	if len(postCards) != 1 {
		t.Fatalf("post cards = %d, want one persistent post card", len(postCards))
	}
	if postCards[0].Post.Post.ID != persistentPost.ID {
		t.Fatalf("post card = %s, want persistent post %s", postCards[0].Post.Post.ID, persistentPost.ID)
	}
}

func TestBuildFollowingFeedUsesViewerMemberships(t *testing.T) {
	authorID := uuid.New()
	viewerID := uuid.New()
	followedCommunityID := uuid.New()
	unfollowedCommunityID := uuid.New()
	now := time.Now().UTC()
	followedPost := newFeedTestPost(authorID, "followed", now)
	followedPost.CommunityID = &followedCommunityID
	unfollowedPost := newFeedTestPost(authorID, "unfollowed", now.Add(-time.Minute))
	unfollowedPost.CommunityID = &unfollowedCommunityID

	repo := &feedPostRepositoryStub{
		posts:                   []*model.Post{followedPost, unfollowedPost},
		followedCommunityIDs:    map[uuid.UUID]bool{followedCommunityID: true},
		filterFollowedUserIDLog: make([]uuid.UUID, 0),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test")

	page, err := useCase.BuildFeed(context.Background(), viewerID.String(), BuildFeedInput{
		Surface: "content",
		Tab:     "following",
		Limit:   10,
	})
	if err != nil {
		t.Fatalf("BuildFeed returned error: %v", err)
	}
	if len(repo.filterFollowedUserIDLog) != 1 || repo.filterFollowedUserIDLog[0] != viewerID {
		t.Fatalf("followed user id filter log = %#v, want viewer id", repo.filterFollowedUserIDLog)
	}
	if len(page.Items) != 1 {
		t.Fatalf("items = %d, want 1", len(page.Items))
	}
	data, ok := page.Items[0].Data.(PostCardFeedData)
	if !ok || data.Post == nil || data.Post.Post == nil {
		t.Fatalf("item data = %#v, want post card", page.Items[0].Data)
	}
	if data.Post.Post.ID != followedPost.ID {
		t.Fatalf("post = %s, want followed post %s", data.Post.Post.ID, followedPost.ID)
	}
}

func TestBuildFollowingFeedUsesRepositoryMembershipFilter(t *testing.T) {
	authorID := uuid.New()
	viewerID := uuid.New()
	followedCommunityID := uuid.New()
	unfollowedCommunityID := uuid.New()
	now := time.Now().UTC()
	followedPost := newFeedTestPost(authorID, "followed", now)
	followedPost.CommunityID = &followedCommunityID
	unfollowedPost := newFeedTestPost(authorID, "unfollowed", now.Add(-time.Minute))
	unfollowedPost.CommunityID = &unfollowedCommunityID

	repo := &feedPostRepositoryStub{
		posts:                   []*model.Post{followedPost, unfollowedPost},
		followedCommunityIDs:    map[uuid.UUID]bool{followedCommunityID: true},
		filterFollowedUserIDLog: make([]uuid.UUID, 0),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test")

	page, err := useCase.BuildFeed(context.Background(), viewerID.String(), BuildFeedInput{
		Surface: "content",
		Tab:     "following",
		Limit:   10,
	})
	if err != nil {
		t.Fatalf("BuildFeed returned error: %v", err)
	}
	if len(repo.filterFollowedUserIDLog) != 1 || repo.filterFollowedUserIDLog[0] != viewerID {
		t.Fatalf("followed user id filter log = %#v, want viewer id", repo.filterFollowedUserIDLog)
	}
	if len(page.Items) != 1 {
		t.Fatalf("items = %d, want 1", len(page.Items))
	}
	data, ok := page.Items[0].Data.(PostCardFeedData)
	if !ok || data.Post == nil || data.Post.Post == nil {
		t.Fatalf("item data = %#v, want post card", page.Items[0].Data)
	}
	if data.Post.Post.ID != followedPost.ID {
		t.Fatalf("post = %s, want followed post %s", data.Post.Post.ID, followedPost.ID)
	}
}

func TestBuildFollowingFeedIncludesSocialAuthorPosts(t *testing.T) {
	viewerID := uuid.New()
	communityAuthorID := uuid.New()
	followedAuthorID := uuid.New()
	strangerID := uuid.New()
	followedCommunityID := uuid.New()
	unfollowedCommunityID := uuid.New()
	now := time.Now().UTC()

	communityPost := newFeedTestPost(communityAuthorID, "community-post", now)
	communityPost.CommunityID = &followedCommunityID
	socialPost := newFeedTestPost(followedAuthorID, "social-author-post", now.Add(-time.Second))
	socialPost.CommunityID = &unfollowedCommunityID
	strangerPost := newFeedTestPost(strangerID, "stranger-post", now.Add(-2*time.Second))
	strangerPost.CommunityID = &unfollowedCommunityID

	repo := &feedPostRepositoryStub{
		posts:                []*model.Post{communityPost, socialPost, strangerPost},
		followedCommunityIDs: map[uuid.UUID]bool{followedCommunityID: true},
		feedSocialEdges: map[uuid.UUID]model.FeedSocialEdgeSet{
			followedAuthorID: {Following: true},
		},
		listFeedPostCalls: make([]model.PostListFilter, 0),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test")

	page, err := useCase.BuildFeed(context.Background(), viewerID.String(), BuildFeedInput{
		Surface: "content",
		Tab:     "following",
		Limit:   10,
	})
	if err != nil {
		t.Fatalf("BuildFeed returned error: %v", err)
	}

	gotSources := make([]string, 0, len(repo.listFeedPostCalls))
	for _, filter := range repo.listFeedPostCalls {
		gotSources = append(gotSources, filter.CandidateSource)
	}
	wantSources := []string{
		model.PostCandidateSourceFollowing,
		model.PostCandidateSourceSocial,
	}
	if strings.Join(gotSources, ",") != strings.Join(wantSources, ",") {
		t.Fatalf("candidate sources = %v, want %v", gotSources, wantSources)
	}

	postCards := postCardFeedData(page.Items)
	if len(postCards) != 2 {
		t.Fatalf("post cards = %d, want community and social author posts", len(postCards))
	}
	gotPostIDs := []uuid.UUID{postCards[0].Post.Post.ID, postCards[1].Post.Post.ID}
	wantPostIDs := []uuid.UUID{communityPost.ID, socialPost.ID}
	if !uuidSlicesEqual(gotPostIDs, wantPostIDs) {
		t.Fatalf("post cards = %v, want %v", gotPostIDs, wantPostIDs)
	}
}

func TestBuildFollowingFeedReservesSpaceForSocialAuthorPosts(t *testing.T) {
	viewerID := uuid.New()
	firstCommunityAuthorID := uuid.New()
	secondCommunityAuthorID := uuid.New()
	followedAuthorID := uuid.New()
	followedCommunityID := uuid.New()
	unfollowedCommunityID := uuid.New()
	now := time.Now().UTC()

	firstCommunityPost := newFeedTestPost(firstCommunityAuthorID, "first-community-post", now)
	firstCommunityPost.CommunityID = &followedCommunityID
	secondCommunityPost := newFeedTestPost(secondCommunityAuthorID, "second-community-post", now.Add(-time.Second))
	secondCommunityPost.CommunityID = &followedCommunityID
	socialPost := newFeedTestPost(followedAuthorID, "social-author-post", now.Add(-2*time.Second))
	socialPost.CommunityID = &unfollowedCommunityID

	repo := &feedPostRepositoryStub{
		posts:                []*model.Post{firstCommunityPost, secondCommunityPost, socialPost},
		followedCommunityIDs: map[uuid.UUID]bool{followedCommunityID: true},
		feedSocialEdges: map[uuid.UUID]model.FeedSocialEdgeSet{
			followedAuthorID: {Following: true},
		},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test")

	page, err := useCase.BuildFeed(context.Background(), viewerID.String(), BuildFeedInput{
		Surface: "content",
		Tab:     "following",
		Limit:   2,
	})
	if err != nil {
		t.Fatalf("BuildFeed returned error: %v", err)
	}

	postCards := postCardFeedData(page.Items)
	if len(postCards) != 2 {
		t.Fatalf("post cards = %d, want reserved community and social author posts", len(postCards))
	}
	gotPostIDs := []uuid.UUID{postCards[0].Post.Post.ID, postCards[1].Post.Post.ID}
	wantPostIDs := []uuid.UUID{firstCommunityPost.ID, socialPost.ID}
	if !uuidSlicesEqual(gotPostIDs, wantPostIDs) {
		t.Fatalf("post cards = %v, want %v", gotPostIDs, wantPostIDs)
	}
}

func TestBuildForYouFeedPartitionsFollowedAndPersonalizedCandidateSources(t *testing.T) {
	authorID := uuid.New()
	viewerID := uuid.New()
	followedCommunityID := uuid.New()
	discoveryCommunityID := uuid.New()
	now := time.Now().UTC()
	followedPost := newFeedTestPost(authorID, "followed", now)
	followedPost.CommunityID = &followedCommunityID
	discoveryPost := newFeedTestPost(authorID, "discovery", now.Add(-time.Minute))
	discoveryPost.CommunityID = &discoveryCommunityID

	repo := &feedPostRepositoryStub{
		posts:                []*model.Post{followedPost, discoveryPost},
		followedCommunityIDs: map[uuid.UUID]bool{followedCommunityID: true},
		listFeedPostCalls:    make([]model.PostListFilter, 0),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test")

	page, err := useCase.BuildFeed(context.Background(), viewerID.String(), BuildFeedInput{
		Surface: "content",
		Tab:     "for_you",
		Limit:   10,
	})
	if err != nil {
		t.Fatalf("BuildFeed returned error: %v", err)
	}
	if len(repo.listFeedPostCalls) != 6 {
		t.Fatalf("ListFeedPosts calls = %d, want followed, social, system, interest, cold-start, and popular candidate sources", len(repo.listFeedPostCalls))
	}
	followedFilter := repo.listFeedPostCalls[0]
	if followedFilter.FollowedByUserID == nil || *followedFilter.FollowedByUserID != viewerID {
		t.Fatalf("followed source filter = %+v, want viewer FollowedByUserID", followedFilter)
	}
	gotSources := make([]string, 0, len(repo.listFeedPostCalls))
	for _, filter := range repo.listFeedPostCalls {
		gotSources = append(gotSources, filter.CandidateSource)
		if filter.CandidateSource == model.PostCandidateSourceColdStart && filter.ColdStartRandomSeed <= 0 {
			t.Fatalf("cold-start filter random seed = %d, want positive seed", filter.ColdStartRandomSeed)
		}
	}
	wantSources := []string{
		model.PostCandidateSourceFollowed,
		model.PostCandidateSourceSocial,
		model.PostCandidateSourceSystem,
		model.PostCandidateSourceInterest,
		model.PostCandidateSourceColdStart,
		model.PostCandidateSourcePopular,
	}
	if strings.Join(gotSources, ",") != strings.Join(wantSources, ",") {
		t.Fatalf("candidate sources = %v, want %v", gotSources, wantSources)
	}

	postCards := postCardFeedData(page.Items)
	if len(postCards) != 2 {
		t.Fatalf("post cards = %d, want followed and discovery posts", len(postCards))
	}
	if postCards[0].Post.Post.ID != followedPost.ID || postCards[1].Post.Post.ID != discoveryPost.ID {
		t.Fatalf("post cards = %+v, want followed then discovery by ranked time", postCards)
	}
	if postCards[0].CandidateSource != model.PostCandidateSourceFollowed {
		t.Fatalf("followed post candidate source = %q, want %q", postCards[0].CandidateSource, model.PostCandidateSourceFollowed)
	}
	if postCards[1].CandidateSource != model.PostCandidateSourceColdStart {
		t.Fatalf("discovery post candidate source = %q, want %q", postCards[1].CandidateSource, model.PostCandidateSourceColdStart)
	}
}

func TestBuildForYouFeedIncludesColdStartCandidateSourceForNewViewer(t *testing.T) {
	viewerID := uuid.New()
	authorID := uuid.New()
	now := time.Now().UTC()
	geoPost := newFeedTestPost(authorID, "almaty-start", now)
	geoPost.PlaceCountryCode = stringPtr("KZ")
	geoPost.PlaceCityID = stringPtr("almaty")
	popularPost := newFeedTestPost(uuid.New(), "popular-start", now.Add(-time.Minute))

	repo := &feedPostRepositoryStub{
		posts:             []*model.Post{geoPost, popularPost},
		listFeedPostCalls: make([]model.PostListFilter, 0),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test")

	page, err := useCase.BuildFeed(context.Background(), viewerID.String(), BuildFeedInput{
		Surface:     "content",
		Tab:         "for_you",
		CountryCode: "KZ",
		CityID:      "almaty",
		Limit:       10,
	})
	if err != nil {
		t.Fatalf("BuildFeed returned error: %v", err)
	}

	gotSources := make([]string, 0, len(repo.listFeedPostCalls))
	for _, filter := range repo.listFeedPostCalls {
		gotSources = append(gotSources, filter.CandidateSource)
	}
	wantSources := []string{
		model.PostCandidateSourceFollowed,
		model.PostCandidateSourceSocial,
		model.PostCandidateSourceSystem,
		model.PostCandidateSourceGeo,
		model.PostCandidateSourceInterest,
		model.PostCandidateSourceColdStart,
		model.PostCandidateSourcePopular,
	}
	if strings.Join(gotSources, ",") != strings.Join(wantSources, ",") {
		t.Fatalf("candidate sources = %v, want %v", gotSources, wantSources)
	}
	if postCards := postCardFeedData(page.Items); len(postCards) == 0 {
		t.Fatal("post cards are empty, want cold-start fallback content")
	}
}

func TestBuildForYouFeedIncludesEveryPostProfileOnHomeAndContentSurfaces(t *testing.T) {
	profiles := []enum.PostProfileKey{
		enum.PostProfileArticleV1,
		enum.PostProfileQuickPostV1,
		enum.PostProfileListingV1,
		enum.PostProfileEventAnnouncementV1,
		enum.PostProfileQuestionAnswerV1,
		enum.PostProfileTripPlanV1,
	}

	for _, surface := range []string{"home", "content"} {
		for _, profile := range profiles {
			t.Run(surface+"/"+string(profile), func(t *testing.T) {
				viewerID := uuid.New()
				post := newFeedTestPost(uuid.New(), surface+"-"+string(profile), time.Now().UTC())
				post.PostProfileKey = profile
				repo := &feedPostRepositoryStub{posts: []*model.Post{post}}
				useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test")

				page, err := useCase.BuildFeed(context.Background(), viewerID.String(), BuildFeedInput{
					Surface: surface,
					Tab:     "for_you",
					Limit:   10,
				})
				if err != nil {
					t.Fatalf("BuildFeed returned error: %v", err)
				}

				cards := postCardFeedData(page.Items)
				if len(cards) != 1 || cards[0].Post.Post.PostProfileKey != profile {
					t.Fatalf("post cards = %+v, want profile %q", cards, profile)
				}
			})
		}
	}
}

func TestBuildForYouFeedIncludesSystemCandidateSourceForAuthenticatedViewer(t *testing.T) {
	viewerID := uuid.New()
	now := time.Now().UTC()
	systemPost := newFeedTestPost(uuid.New(), "system-update", now)
	systemPost.PostProfileKey = enum.PostProfileArticleV1
	systemPost.Tags = []string{"official_updates"}

	repo := &feedPostRepositoryStub{
		posts:             []*model.Post{systemPost},
		listFeedPostCalls: make([]model.PostListFilter, 0),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test")

	page, err := useCase.BuildFeed(context.Background(), viewerID.String(), BuildFeedInput{
		Surface: "content",
		Tab:     "for_you",
		Limit:   10,
	})
	if err != nil {
		t.Fatalf("BuildFeed returned error: %v", err)
	}

	gotSources := make([]string, 0, len(repo.listFeedPostCalls))
	for _, filter := range repo.listFeedPostCalls {
		gotSources = append(gotSources, filter.CandidateSource)
	}
	wantSources := []string{
		model.PostCandidateSourceFollowed,
		model.PostCandidateSourceSocial,
		model.PostCandidateSourceSystem,
		model.PostCandidateSourceInterest,
		model.PostCandidateSourceColdStart,
		model.PostCandidateSourcePopular,
	}
	if strings.Join(gotSources, ",") != strings.Join(wantSources, ",") {
		t.Fatalf("candidate sources = %v, want %v", gotSources, wantSources)
	}
	postCards := postCardFeedData(page.Items)
	if len(postCards) != 1 || postCards[0].CandidateSource != model.PostCandidateSourceSystem {
		t.Fatalf("post cards = %+v, want system post card", postCards)
	}
}

func TestBuildForYouFeedIncludesColdStartCandidateSourceForNewViewerWithoutGeo(t *testing.T) {
	viewerID := uuid.New()
	authorID := uuid.New()
	now := time.Now().UTC()
	coldStartPost := newFeedTestPost(authorID, "cold-start-without-geo", now)

	repo := &feedPostRepositoryStub{
		posts:             []*model.Post{coldStartPost},
		listFeedPostCalls: make([]model.PostListFilter, 0),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test")

	page, err := useCase.BuildFeed(context.Background(), viewerID.String(), BuildFeedInput{
		Surface: "content",
		Tab:     "for_you",
		Limit:   10,
	})
	if err != nil {
		t.Fatalf("BuildFeed returned error: %v", err)
	}

	gotSources := make([]string, 0, len(repo.listFeedPostCalls))
	for _, filter := range repo.listFeedPostCalls {
		gotSources = append(gotSources, filter.CandidateSource)
	}
	wantSources := []string{
		model.PostCandidateSourceFollowed,
		model.PostCandidateSourceSocial,
		model.PostCandidateSourceSystem,
		model.PostCandidateSourceInterest,
		model.PostCandidateSourceColdStart,
		model.PostCandidateSourcePopular,
	}
	if strings.Join(gotSources, ",") != strings.Join(wantSources, ",") {
		t.Fatalf("candidate sources = %v, want %v", gotSources, wantSources)
	}
	if postCards := postCardFeedData(page.Items); len(postCards) == 0 {
		t.Fatal("post cards are empty, want cold-start fallback content")
	}
}

func TestMixFeedPostCandidateSourcesCapsSystemPostsPerPage(t *testing.T) {
	now := time.Now().UTC()
	systemPosts := make([]*PostView, 0, 6)
	for idx := range 6 {
		post := newFeedTestPost(uuid.New(), fmt.Sprintf("system-%d", idx), now.Add(-time.Duration(idx)*time.Minute))
		post.PostProfileKey = enum.PostProfileArticleV1
		post.Tags = []string{"official_updates"}
		systemPosts = append(systemPosts, &PostView{Post: post})
	}

	page := mixFeedPostCandidateSources(
		6,
		nil,
		[]feedPostCandidateSource{{Name: model.PostCandidateSourceSystem}},
		[]string{model.PostCandidateSourceSystem},
		map[string][]*PostView{model.PostCandidateSourceSystem: systemPosts},
	)

	if len(page.Posts) != 5 {
		t.Fatalf("system posts = %d, want cap of 5 per page", len(page.Posts))
	}
	for _, post := range page.Posts {
		if source := page.CandidateSourceByPostID[post.Post.ID]; source != model.PostCandidateSourceSystem {
			t.Fatalf("candidate source for %s = %q, want system", post.Post.ID, source)
		}
	}
	if page.NextCursor == nil {
		t.Fatal("next cursor is nil, want remaining system posts to stay pageable")
	}
}

func TestBuildForYouFeedUsesExplicitPersonalizedCandidateSources(t *testing.T) {
	viewerID := uuid.New()
	followedAuthorID := uuid.New()
	friendAuthorID := uuid.New()
	geoAuthorID := uuid.New()
	interestAuthorID := uuid.New()
	popularAuthorID := uuid.New()
	followedCommunityID := uuid.New()
	geoCommunityID := uuid.New()
	now := time.Now().UTC()

	followedPost := newFeedTestPost(followedAuthorID, "followed", now)
	followedPost.CommunityID = &followedCommunityID
	friendPost := newFeedTestPost(friendAuthorID, "friend", now.Add(-time.Minute))
	geoPost := newFeedTestPost(geoAuthorID, "geo", now.Add(-2*time.Minute))
	geoPost.CommunityID = &geoCommunityID
	geoPost.PlaceCountryCode = stringPtr("KZ")
	geoPost.PlaceCityID = stringPtr("almaty")
	interestPost := newFeedTestPost(interestAuthorID, "interest", now.Add(-3*time.Minute))
	interestPost.PostProfileKey = enum.PostProfileTripPlanV1
	popularPost := newFeedTestPost(popularAuthorID, "popular", now.Add(-4*time.Minute))

	repo := &feedPostRepositoryStub{
		posts: []*model.Post{
			followedPost,
			friendPost,
			geoPost,
			interestPost,
			popularPost,
		},
		followedCommunityIDs: map[uuid.UUID]bool{followedCommunityID: true},
		feedSocialEdges: map[uuid.UUID]model.FeedSocialEdgeSet{
			friendAuthorID: {Friend: true},
		},
		feedUserInterests: []model.FeedUserInterest{{
			ViewerUserID: viewerID,
			EntityType:   model.FeedInterestEntityTypePostProfile,
			EntityID:     string(enum.PostProfileTripPlanV1),
			Score:        1,
			LastEventAt:  now,
			UpdatedAt:    now,
		}},
		listFeedPostCalls: make([]model.PostListFilter, 0),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test")

	page, err := useCase.BuildFeed(context.Background(), viewerID.String(), BuildFeedInput{
		Surface:     "content",
		Tab:         "for_you",
		CountryCode: "KZ",
		CityID:      "almaty",
		Limit:       10,
	})
	if err != nil {
		t.Fatalf("BuildFeed returned error: %v", err)
	}

	gotSources := make([]string, 0, len(repo.listFeedPostCalls))
	for _, filter := range repo.listFeedPostCalls {
		gotSources = append(gotSources, filter.CandidateSource)
	}
	wantSources := []string{
		model.PostCandidateSourceFollowed,
		model.PostCandidateSourceSocial,
		model.PostCandidateSourceSystem,
		model.PostCandidateSourceGeo,
		model.PostCandidateSourceInterest,
		model.PostCandidateSourceColdStart,
		model.PostCandidateSourcePopular,
	}
	if strings.Join(gotSources, ",") != strings.Join(wantSources, ",") {
		t.Fatalf("candidate sources = %v, want %v", gotSources, wantSources)
	}

	postCards := postCardFeedData(page.Items)
	if got := postIDsFromPostCards(postCards); !sameUUIDsInOrder(got, []uuid.UUID{
		followedPost.ID,
		friendPost.ID,
		geoPost.ID,
		interestPost.ID,
		popularPost.ID,
	}) {
		t.Fatalf("post IDs = %v, want explicit sources merged by rank", got)
	}
}

func TestBuildForYouFeedQuotaMixingDoesNotSkipUnselectedPopularPosts(t *testing.T) {
	viewerID := uuid.New()
	followedAuthorID := uuid.New()
	friendAuthorID := uuid.New()
	popularAuthorID := uuid.New()
	followedCommunityID := uuid.New()
	now := time.Now().UTC()

	popularFirst := newFeedTestPost(popularAuthorID, "popular-first", now)
	popularSecond := newFeedTestPost(popularAuthorID, "popular-second", now.Add(-time.Minute))
	popularThird := newFeedTestPost(popularAuthorID, "popular-third", now.Add(-2*time.Minute))
	followedPost := newFeedTestPost(followedAuthorID, "followed", now.Add(-24*time.Hour))
	followedPost.CommunityID = &followedCommunityID
	friendPost := newFeedTestPost(friendAuthorID, "friend", now.Add(-25*time.Hour))

	repo := &feedPostRepositoryStub{
		posts: []*model.Post{
			popularFirst,
			popularSecond,
			popularThird,
			followedPost,
			friendPost,
		},
		followedCommunityIDs: map[uuid.UUID]bool{followedCommunityID: true},
		feedSocialEdges: map[uuid.UUID]model.FeedSocialEdgeSet{
			friendAuthorID: {Friend: true},
		},
		listFeedPostCalls: make([]model.PostListFilter, 0),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test")

	firstPage, err := useCase.BuildFeed(context.Background(), viewerID.String(), BuildFeedInput{
		Surface: "content",
		Tab:     "for_you",
		Limit:   3,
	})
	if err != nil {
		t.Fatalf("BuildFeed first page returned error: %v", err)
	}
	firstPageIDs := postIDsFromPostCards(postCardFeedData(firstPage.Items))
	if !containsUUID(firstPageIDs, followedPost.ID) || !containsUUID(firstPageIDs, friendPost.ID) {
		t.Fatalf("first page post IDs = %v, want reserved followed and social candidates", firstPageIDs)
	}
	if firstPage.NextCursor == "" {
		t.Fatal("first page cursor is empty, want source-aware cursor")
	}

	secondPage, err := useCase.BuildFeed(context.Background(), viewerID.String(), BuildFeedInput{
		Surface: "content",
		Tab:     "for_you",
		Limit:   3,
		Cursor:  firstPage.NextCursor,
	})
	if err != nil {
		t.Fatalf("BuildFeed second page returned error: %v", err)
	}
	secondPageIDs := postIDsFromPostCards(postCardFeedData(secondPage.Items))
	if !containsUUID(secondPageIDs, popularSecond.ID) || !containsUUID(secondPageIDs, popularThird.ID) {
		t.Fatalf("second page post IDs = %v, want unselected fresh popular posts", secondPageIDs)
	}
	if containsUUID(secondPageIDs, followedPost.ID) || containsUUID(secondPageIDs, friendPost.ID) {
		t.Fatalf("second page post IDs = %v, want no duplicates from first page", secondPageIDs)
	}
}

func TestMixFeedPostCandidateSourcesDoesNotLetSystemPostsStarveDiscoverySources(t *testing.T) {
	now := time.Date(2026, 6, 15, 12, 0, 0, 0, time.UTC)
	systemPosts := make([]*PostView, 0, 5)
	for idx := range 5 {
		post := newFeedTestPost(uuid.New(), fmt.Sprintf("system-%d", idx), now.Add(-time.Duration(idx)*time.Second))
		post.PostProfileKey = enum.PostProfileArticleV1
		post.Tags = []string{"official_updates"}
		systemPosts = append(systemPosts, &PostView{Post: post})
	}
	geoPost := newFeedTestPost(uuid.New(), "geo", now.Add(-time.Minute))
	geoPost.PlaceCountryCode = stringPtr("KZ")
	geoPost.PlaceCityID = stringPtr("almaty")
	interestPost := newFeedTestPost(uuid.New(), "interest", now.Add(-2*time.Minute))
	interestPost.PostProfileKey = enum.PostProfileTripPlanV1
	coldStartPost := newFeedTestPost(uuid.New(), "cold-start", now.Add(-3*time.Minute))
	coldStartPost.Category = enum.PostCategoryGuide

	page := mixFeedPostCandidateSources(
		5,
		nil,
		[]feedPostCandidateSource{
			{Name: model.PostCandidateSourceSystem},
			{Name: model.PostCandidateSourceGeo},
			{Name: model.PostCandidateSourceInterest},
			{Name: model.PostCandidateSourceColdStart},
		},
		[]string{
			model.PostCandidateSourceSystem,
			model.PostCandidateSourceGeo,
			model.PostCandidateSourceInterest,
			model.PostCandidateSourceColdStart,
		},
		map[string][]*PostView{
			model.PostCandidateSourceSystem:    systemPosts,
			model.PostCandidateSourceGeo:       {{Post: geoPost}},
			model.PostCandidateSourceInterest:  {{Post: interestPost}},
			model.PostCandidateSourceColdStart: {{Post: coldStartPost}},
		},
	)

	gotIDs := postIDsFromPostViews(page.Posts)
	for _, wantID := range []uuid.UUID{geoPost.ID, interestPost.ID, coldStartPost.ID} {
		if !containsUUID(gotIDs, wantID) {
			t.Fatalf("mixed post IDs = %v, want discovery source post %s", gotIDs, wantID)
		}
	}
	systemCount := 0
	for _, post := range page.Posts {
		if post != nil && post.Post != nil {
			if page.CandidateSourceByPostID[post.Post.ID] == model.PostCandidateSourceSystem {
				systemCount++
			}
		}
	}
	if systemCount > 2 {
		t.Fatalf("system posts = %d, want at most 2 system posts in a mixed page", systemCount)
	}
}

func TestMixFeedPostCandidateSourcesKeepsColdStartSeedInNextCursor(t *testing.T) {
	now := time.Date(2026, 7, 11, 12, 0, 0, 0, time.UTC)
	first := newFeedTestPost(uuid.New(), "random-first", now)
	second := newFeedTestPost(uuid.New(), "random-second", now.Add(-time.Minute))
	const randomSeed int64 = 987654321

	page := mixFeedPostCandidateSources(
		1,
		nil,
		[]feedPostCandidateSource{{
			Name:       model.PostCandidateSourceColdStart,
			RandomSeed: randomSeed,
		}},
		[]string{model.PostCandidateSourceColdStart},
		map[string][]*PostView{
			model.PostCandidateSourceColdStart: {{Post: first}, {Post: second}},
		},
	)

	if page.NextCursor == nil {
		t.Fatal("next cursor is nil, want a cursor for the remaining candidate")
	}
	if page.NextCursor.ColdStartRandomSeed != randomSeed {
		t.Fatalf("next cursor random seed = %d, want %d", page.NextCursor.ColdStartRandomSeed, randomSeed)
	}
}

func TestMixFeedPostCandidateSourcesDrainsUnselectableSourceCandidates(t *testing.T) {
	now := time.Date(2026, 6, 15, 12, 0, 0, 0, time.UTC)
	popularPost := newFeedTestPost(uuid.New(), "popular", now)

	page := mixFeedPostCandidateSources(
		1,
		nil,
		[]feedPostCandidateSource{
			{Name: model.PostCandidateSourceInterest},
			{Name: model.PostCandidateSourcePopular},
		},
		[]string{
			model.PostCandidateSourceInterest,
			model.PostCandidateSourcePopular,
		},
		map[string][]*PostView{
			model.PostCandidateSourceInterest: {
				nil,
				{},
				{Post: &model.Post{}},
			},
			model.PostCandidateSourcePopular: {{Post: popularPost}},
		},
	)

	got := postIDsFromPostViews(page.Posts)
	if !sameUUIDsInOrder(got, []uuid.UUID{popularPost.ID}) {
		t.Fatalf("mixed post IDs = %v, want only selectable popular post", got)
	}
	if page.NextCursor != nil {
		t.Fatalf("next cursor = %+v, want nil after all selectable candidates are consumed", page.NextCursor)
	}
}

func TestMixFeedPostCandidateSourcesAppliesDiversityCapsBeforeFallback(t *testing.T) {
	now := time.Date(2026, 6, 15, 12, 0, 0, 0, time.UTC)
	dominantAuthorID := uuid.New()
	dominantCommunityID := uuid.New()
	alternativeAuthorID := uuid.New()
	alternativeCommunityID := uuid.New()

	dominantFirst := newFeedTestPost(dominantAuthorID, "dominant-first", now)
	dominantFirst.CommunityID = &dominantCommunityID
	dominantFirst.PostProfileKey = enum.PostProfileQuickPostV1
	dominantSecond := newFeedTestPost(dominantAuthorID, "dominant-second", now.Add(-time.Minute))
	dominantSecond.CommunityID = &dominantCommunityID
	dominantSecond.PostProfileKey = enum.PostProfileQuickPostV1
	dominantThird := newFeedTestPost(dominantAuthorID, "dominant-third", now.Add(-2*time.Minute))
	dominantThird.CommunityID = &dominantCommunityID
	dominantThird.PostProfileKey = enum.PostProfileQuickPostV1
	dominantFourth := newFeedTestPost(dominantAuthorID, "dominant-fourth", now.Add(-3*time.Minute))
	dominantFourth.CommunityID = &dominantCommunityID
	dominantFourth.PostProfileKey = enum.PostProfileQuickPostV1
	alternativeFirst := newFeedTestPost(alternativeAuthorID, "alternative-first", now.Add(-4*time.Minute))
	alternativeFirst.CommunityID = &alternativeCommunityID
	alternativeFirst.PostProfileKey = enum.PostProfileArticleV1
	alternativeFirst.Category = enum.PostCategoryJournal
	alternativeSecond := newFeedTestPost(uuid.New(), "alternative-second", now.Add(-5*time.Minute))
	alternativeSecondCommunityID := uuid.New()
	alternativeSecond.CommunityID = &alternativeSecondCommunityID
	alternativeSecond.PostProfileKey = enum.PostProfileListingV1
	alternativeSecond.Category = enum.PostCategoryCulinary

	page := mixFeedPostCandidateSources(
		4,
		nil,
		[]feedPostCandidateSource{{Name: model.PostCandidateSourcePopular}},
		[]string{model.PostCandidateSourcePopular},
		map[string][]*PostView{
			model.PostCandidateSourcePopular: {
				{Post: dominantFirst},
				{Post: dominantSecond},
				{Post: dominantThird},
				{Post: dominantFourth},
				{Post: alternativeFirst},
				{Post: alternativeSecond},
			},
		},
	)

	if got := postIDsFromPostViews(page.Posts); !sameUUIDsInOrder(got, []uuid.UUID{
		dominantFirst.ID,
		dominantSecond.ID,
		alternativeFirst.ID,
		alternativeSecond.ID,
	}) {
		t.Fatalf("mixed post IDs = %v, want dominant source capped before fallback alternatives", got)
	}
}

func TestMixFeedPostCandidateSourcesPaginatesAllQuickPostsFromOneCommunity(t *testing.T) {
	now := time.Date(2026, 7, 11, 12, 0, 0, 0, time.UTC)
	authorID := uuid.New()
	communityID := uuid.New()
	allPosts := make([]*PostView, 0, 7)
	for index := range 7 {
		post := newFeedTestPost(
			authorID,
			fmt.Sprintf("quick-%d", index),
			now.Add(-time.Duration(index)*time.Minute),
		)
		post.CommunityID = &communityID
		post.PostProfileKey = enum.PostProfileQuickPostV1
		post.Category = enum.PostCategoryGuide
		allPosts = append(allPosts, &PostView{Post: post})
	}

	source := feedPostCandidateSource{Name: model.PostCandidateSourcePopular}
	first := mixFeedPostCandidateSources(
		3,
		nil,
		[]feedPostCandidateSource{source},
		[]string{model.PostCandidateSourcePopular},
		map[string][]*PostView{model.PostCandidateSourcePopular: allPosts},
	)
	if got := postIDsFromPostViews(first.Posts); !sameUUIDsInOrder(got, postIDsFromPostViews(allPosts[:3])) {
		t.Fatalf("first quick-post page = %v, want first three posts", got)
	}
	if first.NextCursor == nil {
		t.Fatal("first quick-post page cursor is nil")
	}

	second := mixFeedPostCandidateSources(
		3,
		first.NextCursor,
		[]feedPostCandidateSource{source},
		[]string{model.PostCandidateSourcePopular},
		map[string][]*PostView{model.PostCandidateSourcePopular: allPosts[3:]},
	)
	if got := postIDsFromPostViews(second.Posts); !sameUUIDsInOrder(got, postIDsFromPostViews(allPosts[3:6])) {
		t.Fatalf("second quick-post page = %v, want next three posts", got)
	}
	if second.NextCursor == nil {
		t.Fatal("second quick-post page cursor is nil")
	}

	third := mixFeedPostCandidateSources(
		3,
		second.NextCursor,
		[]feedPostCandidateSource{source},
		[]string{model.PostCandidateSourcePopular},
		map[string][]*PostView{model.PostCandidateSourcePopular: allPosts[6:]},
	)
	if got := postIDsFromPostViews(third.Posts); !sameUUIDsInOrder(got, postIDsFromPostViews(allPosts[6:])) {
		t.Fatalf("third quick-post page = %v, want final post", got)
	}
	if third.NextCursor != nil {
		t.Fatalf("third quick-post page cursor = %+v, want nil", third.NextCursor)
	}
}

func TestMixFeedPostCandidateSourcesAppliesCategoryDiversityBeforeFallback(t *testing.T) {
	now := time.Date(2026, 6, 15, 12, 0, 0, 0, time.UTC)
	firstGuide := newFeedTestPost(uuid.New(), "first-guide", now)
	firstGuide.CommunityID = uuidPtr(uuid.New())
	firstGuide.PostProfileKey = enum.PostProfileQuickPostV1
	firstGuide.Category = enum.PostCategoryGuide
	secondGuide := newFeedTestPost(uuid.New(), "second-guide", now.Add(-time.Minute))
	secondGuide.CommunityID = uuidPtr(uuid.New())
	secondGuide.PostProfileKey = enum.PostProfileArticleV1
	secondGuide.Category = enum.PostCategoryGuide
	thirdGuide := newFeedTestPost(uuid.New(), "third-guide", now.Add(-2*time.Minute))
	thirdGuide.CommunityID = uuidPtr(uuid.New())
	thirdGuide.PostProfileKey = enum.PostProfileListingV1
	thirdGuide.Category = enum.PostCategoryGuide
	journal := newFeedTestPost(uuid.New(), "journal", now.Add(-3*time.Minute))
	journal.CommunityID = uuidPtr(uuid.New())
	journal.PostProfileKey = enum.PostProfileEventAnnouncementV1
	journal.Category = enum.PostCategoryJournal
	culinary := newFeedTestPost(uuid.New(), "culinary", now.Add(-4*time.Minute))
	culinary.CommunityID = uuidPtr(uuid.New())
	culinary.PostProfileKey = enum.PostProfileQuickPostV1
	culinary.Category = enum.PostCategoryCulinary

	page := mixFeedPostCandidateSources(
		4,
		nil,
		[]feedPostCandidateSource{{Name: model.PostCandidateSourcePopular}},
		[]string{model.PostCandidateSourcePopular},
		map[string][]*PostView{
			model.PostCandidateSourcePopular: {
				{Post: firstGuide},
				{Post: secondGuide},
				{Post: thirdGuide},
				{Post: journal},
				{Post: culinary},
			},
		},
		FeedDiversityPolicy{MaxPostsPerCategoryPerPage: 2},
	)

	want := []uuid.UUID{
		firstGuide.ID,
		secondGuide.ID,
		journal.ID,
		culinary.ID,
	}
	if got := postIDsFromPostViews(page.Posts); !sameUUIDsInOrder(got, want) {
		t.Fatalf("mixed post IDs = %v, want %v category-capped feed before fallback", got, want)
	}
}

func TestMixFeedPostCandidateSourcesAppliesTagDiversityBeforeFallback(t *testing.T) {
	now := time.Date(2026, 6, 15, 12, 0, 0, 0, time.UTC)
	firstVisa := newFeedTestPost(uuid.New(), "first-visa", now)
	firstVisa.CommunityID = uuidPtr(uuid.New())
	firstVisa.PostProfileKey = enum.PostProfileQuickPostV1
	firstVisa.Category = enum.PostCategoryGuide
	firstVisa.Tags = []string{"visa", "documents"}
	secondVisa := newFeedTestPost(uuid.New(), "second-visa", now.Add(-time.Minute))
	secondVisa.CommunityID = uuidPtr(uuid.New())
	secondVisa.PostProfileKey = enum.PostProfileArticleV1
	secondVisa.Category = enum.PostCategoryJournal
	secondVisa.Tags = []string{" Visa ", "relocation"}
	thirdVisa := newFeedTestPost(uuid.New(), "third-visa", now.Add(-2*time.Minute))
	thirdVisa.CommunityID = uuidPtr(uuid.New())
	thirdVisa.PostProfileKey = enum.PostProfileListingV1
	thirdVisa.Category = enum.PostCategoryCulinary
	thirdVisa.Tags = []string{"visa", "bureaucracy"}
	housing := newFeedTestPost(uuid.New(), "housing", now.Add(-3*time.Minute))
	housing.CommunityID = uuidPtr(uuid.New())
	housing.PostProfileKey = enum.PostProfileEventAnnouncementV1
	housing.Category = enum.PostCategoryPhotoEssay
	housing.Tags = []string{"housing"}
	transport := newFeedTestPost(uuid.New(), "transport", now.Add(-4*time.Minute))
	transport.CommunityID = uuidPtr(uuid.New())
	transport.PostProfileKey = enum.PostProfileTripPlanV1
	transport.Category = enum.PostCategoryCulinary
	transport.Tags = []string{"transport"}

	page := mixFeedPostCandidateSources(
		4,
		nil,
		[]feedPostCandidateSource{{Name: model.PostCandidateSourcePopular}},
		[]string{model.PostCandidateSourcePopular},
		map[string][]*PostView{
			model.PostCandidateSourcePopular: {
				{Post: firstVisa},
				{Post: secondVisa},
				{Post: thirdVisa},
				{Post: housing},
				{Post: transport},
			},
		},
	)

	if got := postIDsFromPostViews(page.Posts); !sameUUIDsInOrder(got, []uuid.UUID{
		firstVisa.ID,
		secondVisa.ID,
		housing.ID,
		transport.ID,
	}) {
		t.Fatalf("mixed post IDs = %v, want tag-capped feed before fallback", got)
	}
}

func TestMixFeedPostCandidateSourcesResetsTagDiversityOnEachPage(t *testing.T) {
	now := time.Date(2026, 6, 15, 12, 0, 0, 0, time.UTC)
	visa := newFeedTestPost(uuid.New(), "visa-again", now)
	visa.CommunityID = uuidPtr(uuid.New())
	visa.PostProfileKey = enum.PostProfileQuickPostV1
	visa.Tags = []string{"visa"}
	housing := newFeedTestPost(uuid.New(), "housing-after-visa", now.Add(-time.Minute))
	housing.CommunityID = uuidPtr(uuid.New())
	housing.PostProfileKey = enum.PostProfileArticleV1
	housing.Category = enum.PostCategoryJournal
	housing.Tags = []string{"housing"}
	transport := newFeedTestPost(uuid.New(), "transport-after-visa", now.Add(-2*time.Minute))
	transport.CommunityID = uuidPtr(uuid.New())
	transport.PostProfileKey = enum.PostProfileListingV1
	transport.Category = enum.PostCategoryCulinary
	transport.Tags = []string{"transport"}

	page := mixFeedPostCandidateSources(
		2,
		&feedCursor{
			DeliveredTags: []string{" visa ", "visa"},
		},
		[]feedPostCandidateSource{{Name: model.PostCandidateSourcePopular}},
		[]string{model.PostCandidateSourcePopular},
		map[string][]*PostView{
			model.PostCandidateSourcePopular: {
				{Post: visa},
				{Post: housing},
				{Post: transport},
			},
		},
	)

	if got := postIDsFromPostViews(page.Posts); !sameUUIDsInOrder(got, []uuid.UUID{
		visa.ID,
		housing.ID,
	}) {
		t.Fatalf("mixed post IDs = %v, want current-page tag diversity", got)
	}
}

func TestMixFeedPostCandidateSourcesResetsAuthorDiversityOnEachPage(t *testing.T) {
	now := time.Date(2026, 6, 15, 12, 0, 0, 0, time.UTC)
	dominantAuthorID := uuid.New()
	dominant := newFeedTestPost(dominantAuthorID, "same-author-again", now)
	dominant.CommunityID = uuidPtr(uuid.New())
	dominant.PostProfileKey = enum.PostProfileQuickPostV1
	alternativeFirst := newFeedTestPost(uuid.New(), "alternative-one", now.Add(-time.Minute))
	alternativeFirst.CommunityID = uuidPtr(uuid.New())
	alternativeFirst.PostProfileKey = enum.PostProfileArticleV1
	alternativeSecond := newFeedTestPost(uuid.New(), "alternative-two", now.Add(-2*time.Minute))
	alternativeSecond.CommunityID = uuidPtr(uuid.New())
	alternativeSecond.PostProfileKey = enum.PostProfileListingV1

	page := mixFeedPostCandidateSources(
		2,
		&feedCursor{
			DeliveredAuthorUserIDs: []uuid.UUID{dominantAuthorID, dominantAuthorID},
		},
		[]feedPostCandidateSource{{Name: model.PostCandidateSourcePopular}},
		[]string{model.PostCandidateSourcePopular},
		map[string][]*PostView{
			model.PostCandidateSourcePopular: {
				{Post: dominant},
				{Post: alternativeFirst},
				{Post: alternativeSecond},
			},
		},
	)

	if got := postIDsFromPostViews(page.Posts); !sameUUIDsInOrder(got, []uuid.UUID{
		dominant.ID,
		alternativeFirst.ID,
	}) {
		t.Fatalf("mixed post IDs = %v, want current-page author diversity", got)
	}
}

func TestMixFeedPostCandidateSourcesResetsEntityDiversityOnEachPage(t *testing.T) {
	now := time.Date(2026, 6, 15, 12, 0, 0, 0, time.UTC)

	tests := map[string]struct {
		cursor        *feedCursor
		configurePost func(*model.Post)
	}{
		"community": {
			cursor: &feedCursor{
				DeliveredCommunityIDs: []uuid.UUID{uuid.MustParse("11111111-1111-4111-8111-111111111111"), uuid.MustParse("11111111-1111-4111-8111-111111111111")},
			},
			configurePost: func(post *model.Post) {
				communityID := uuid.MustParse("11111111-1111-4111-8111-111111111111")
				post.CommunityID = &communityID
				post.PostProfileKey = enum.PostProfileQuickPostV1
				post.Category = enum.PostCategoryGuide
			},
		},
		"post_profile": {
			cursor: &feedCursor{
				DeliveredPostProfileKeys: []enum.PostProfileKey{enum.PostProfileQuickPostV1, enum.PostProfileQuickPostV1},
			},
			configurePost: func(post *model.Post) {
				post.CommunityID = uuidPtr(uuid.New())
				post.PostProfileKey = enum.PostProfileQuickPostV1
				post.Category = enum.PostCategoryGuide
			},
		},
		"category": {
			cursor: &feedCursor{
				DeliveredCategories: []enum.PostCategory{enum.PostCategoryGuide, enum.PostCategoryGuide},
			},
			configurePost: func(post *model.Post) {
				post.CommunityID = uuidPtr(uuid.New())
				post.PostProfileKey = enum.PostProfileQuickPostV1
				post.Category = enum.PostCategoryGuide
			},
		},
	}

	for name, tc := range tests {
		t.Run(name, func(t *testing.T) {
			dominant := newFeedTestPost(uuid.New(), "dominant-"+name, now)
			tc.configurePost(dominant)
			alternativeFirst := newFeedTestPost(uuid.New(), "alternative-one-"+name, now.Add(-time.Minute))
			alternativeFirst.CommunityID = uuidPtr(uuid.New())
			alternativeFirst.PostProfileKey = enum.PostProfileArticleV1
			alternativeFirst.Category = enum.PostCategoryJournal
			alternativeSecond := newFeedTestPost(uuid.New(), "alternative-two-"+name, now.Add(-2*time.Minute))
			alternativeSecond.CommunityID = uuidPtr(uuid.New())
			alternativeSecond.PostProfileKey = enum.PostProfileListingV1
			alternativeSecond.Category = enum.PostCategoryCulinary

			page := mixFeedPostCandidateSources(
				2,
				tc.cursor,
				[]feedPostCandidateSource{{Name: model.PostCandidateSourcePopular}},
				[]string{model.PostCandidateSourcePopular},
				map[string][]*PostView{
					model.PostCandidateSourcePopular: {
						{Post: dominant},
						{Post: alternativeFirst},
						{Post: alternativeSecond},
					},
				},
			)

			if got := postIDsFromPostViews(page.Posts); !sameUUIDsInOrder(got, []uuid.UUID{
				dominant.ID,
				alternativeFirst.ID,
			}) {
				t.Fatalf("mixed post IDs = %v, want current-page %s diversity", got, name)
			}
		})
	}
}

func TestBuildForYouFeedMultiSourceCursorContinuesAfterMergedRank(t *testing.T) {
	authorID := uuid.New()
	viewerID := uuid.New()
	followedCommunityID := uuid.New()
	discoveryCommunityID := uuid.New()
	publishedAt := time.Date(2026, 6, 15, 8, 0, 0, 0, time.UTC)
	rankedAt := time.Date(2026, 6, 15, 12, 0, 0, 0, time.UTC)

	followedFirst := newFeedTestPost(authorID, "followed-first", publishedAt)
	followedFirst.CommunityID = &followedCommunityID
	followedFirst.FeedRankedAt = ptrTime(rankedAt)
	discoveryFirst := newFeedTestPost(authorID, "discovery-first", publishedAt)
	discoveryFirst.CommunityID = &discoveryCommunityID
	discoveryFirst.FeedRankedAt = ptrTime(rankedAt.Add(-time.Minute))
	followedSecond := newFeedTestPost(authorID, "followed-second", publishedAt)
	followedSecond.CommunityID = &followedCommunityID
	followedSecond.FeedRankedAt = ptrTime(rankedAt.Add(-2 * time.Minute))
	discoverySecond := newFeedTestPost(authorID, "discovery-second", publishedAt)
	discoverySecond.CommunityID = &discoveryCommunityID
	discoverySecond.FeedRankedAt = ptrTime(rankedAt.Add(-3 * time.Minute))

	repo := &feedPostRepositoryStub{
		posts: []*model.Post{
			followedFirst,
			discoveryFirst,
			followedSecond,
			discoverySecond,
		},
		followedCommunityIDs: map[uuid.UUID]bool{followedCommunityID: true},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test")

	firstPage, err := useCase.BuildFeed(context.Background(), viewerID.String(), BuildFeedInput{
		Surface: "content",
		Tab:     "for_you",
		Limit:   2,
	})
	if err != nil {
		t.Fatalf("BuildFeed first page returned error: %v", err)
	}
	if firstPage.NextCursor == "" {
		t.Fatal("first page cursor is empty, want cursor for next page")
	}
	firstPageCards := postCardFeedData(firstPage.Items)
	if got := postIDsFromPostCards(firstPageCards); !sameUUIDsInOrder(got, []uuid.UUID{followedFirst.ID, discoveryFirst.ID}) {
		t.Fatalf("first page post IDs = %v, want followed first then discovery first", got)
	}

	secondPage, err := useCase.BuildFeed(context.Background(), viewerID.String(), BuildFeedInput{
		Surface: "content",
		Tab:     "for_you",
		Limit:   2,
		Cursor:  firstPage.NextCursor,
	})
	if err != nil {
		t.Fatalf("BuildFeed second page returned error: %v", err)
	}
	secondPageCards := postCardFeedData(secondPage.Items)
	if got := postIDsFromPostCards(secondPageCards); !sameUUIDsInOrder(got, []uuid.UUID{followedSecond.ID, discoverySecond.ID}) {
		t.Fatalf("second page post IDs = %v, want remaining posts without first page duplicates", got)
	}
}

func TestBuildFeedUsesFeedReadModelRepositoryPath(t *testing.T) {
	authorID := uuid.New()
	now := time.Now().UTC()
	posts := []*model.Post{
		newFeedTestPost(authorID, "first", now),
		newFeedTestPost(authorID, "second", now.Add(-time.Minute)),
	}
	repo := &feedPostRepositoryStub{
		posts:             posts,
		listFeedPostCalls: make([]model.PostListFilter, 0),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

	page, err := useCase.BuildFeed(context.Background(), "", BuildFeedInput{
		Surface:     "content",
		CountryCode: "KZ",
		CityID:      "almaty",
		Limit:       2,
	})
	if err != nil {
		t.Fatalf("BuildFeed returned error: %v", err)
	}
	postCards := postCardFeedData(page.Items)
	if len(postCards) != 2 {
		t.Fatalf("post cards = %d, want 2", len(postCards))
	}
	if postCards[0].Post.Post.ID != posts[0].ID || postCards[1].Post.Post.ID != posts[1].ID {
		t.Fatalf("post cards = %+v, want read-model post order", postCards)
	}
	if len(repo.listFeedPostCalls) != 4 {
		t.Fatalf("ListFeedPosts calls = %d, want anonymous geo candidate sources", len(repo.listFeedPostCalls))
	}
	gotSources := make([]string, 0, len(repo.listFeedPostCalls))
	for _, filter := range repo.listFeedPostCalls {
		gotSources = append(gotSources, filter.CandidateSource)
		if !filter.OnlyPublished || filter.Sort != "latest_desc" || filter.Limit != 5 {
			t.Fatalf("feed filter = %+v, want public latest read-model candidate query", filter)
		}
		if filter.CurrentCountryCode != "KZ" || filter.CurrentCityID != "almaty" {
			t.Fatalf("feed geo context = %q/%q, want KZ/almaty", filter.CurrentCountryCode, filter.CurrentCityID)
		}
	}
	wantSources := []string{
		model.PostCandidateSourceSystem,
		model.PostCandidateSourceGeo,
		model.PostCandidateSourceColdStart,
		model.PostCandidateSourcePopular,
	}
	if strings.Join(gotSources, ",") != strings.Join(wantSources, ",") {
		t.Fatalf("candidate sources = %v, want %v", gotSources, wantSources)
	}
}

func TestBuildFeedSeparatesPostCacheByGeoContext(t *testing.T) {
	authorID := uuid.New()
	now := time.Now().UTC()
	posts := []*model.Post{
		newFeedTestPost(authorID, "first", now),
		newFeedTestPost(authorID, "second", now.Add(-time.Minute)),
	}
	repo := &feedPostRepositoryStub{
		posts:             posts,
		listFeedPostCalls: make([]model.PostListFilter, 0),
	}
	cache := &postFeedCacheFake{
		version: 7,
		posts:   make(map[string][]*model.Post),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test").
		WithPostFeedCache(cache, time.Minute, 30*time.Second)

	for _, cityID := range []string{"almaty", "da-nang"} {
		page, err := useCase.BuildFeed(context.Background(), "", BuildFeedInput{
			Surface:     "content",
			CountryCode: "KZ",
			CityID:      cityID,
			Limit:       2,
		})
		if err != nil {
			t.Fatalf("BuildFeed for %s returned error: %v", cityID, err)
		}
		if postCards := postCardFeedData(page.Items); len(postCards) != 2 {
			t.Fatalf("post cards for %s = %d, want 2", cityID, len(postCards))
		}
	}
	if len(repo.listFeedPostCalls) != 8 {
		t.Fatalf("ListFeedPosts calls = %d, want one cache miss per geo context", len(repo.listFeedPostCalls))
	}
	if cache.sets != 8 || len(cache.posts) != 8 {
		t.Fatalf("cache sets/map size = %d/%d, want one cache entry per geo candidate source", cache.sets, len(cache.posts))
	}
}

func TestPostFeedPostListCacheKeyIncludesCandidateMixerPolicy(t *testing.T) {
	cache := &postFeedCacheFake{
		version: 7,
		posts:   make(map[string][]*model.Post),
	}
	useCase := NewPostUseCase(
		&feedPostRepositoryStub{},
		postUseCaseUserClientStub{userID: uuid.New()},
		"https://posts.test",
	).WithPostFeedCache(cache, time.Minute, 30*time.Second)

	key, ttl, cacheable := useCase.postFeedPostListCacheKey(
		context.Background(),
		nil,
		20,
		0,
		nil,
		feedPostCandidateSource{Name: model.PostCandidateSourceGlobal},
		"KZ",
		"almaty",
		nil,
		postFeedExpiryPersistent,
	)

	if !cacheable || ttl <= 0 {
		t.Fatalf("cacheable/ttl = %v/%v, want cacheable key", cacheable, ttl)
	}
	if !strings.Contains(key, feedCandidateMixerPolicy) {
		t.Fatalf("cache key = %q, want candidate mixer policy segment", key)
	}
}

func TestPostFeedPostListCacheKeySeparatesColdStartRandomSeeds(t *testing.T) {
	cache := &postFeedCacheFake{
		version: 7,
		posts:   make(map[string][]*model.Post),
	}
	useCase := NewPostUseCase(
		&feedPostRepositoryStub{},
		postUseCaseUserClientStub{userID: uuid.New()},
		"https://posts.test",
	).WithPostFeedCache(cache, time.Minute, 30*time.Second)

	keyOne, _, cacheableOne := useCase.postFeedPostListCacheKey(
		context.Background(),
		nil,
		20,
		0,
		nil,
		feedPostCandidateSource{Name: model.PostCandidateSourceColdStart, RandomSeed: 41},
		"KZ",
		"almaty",
		nil,
		postFeedExpiryPersistent,
	)
	keyTwo, _, cacheableTwo := useCase.postFeedPostListCacheKey(
		context.Background(),
		nil,
		20,
		0,
		nil,
		feedPostCandidateSource{Name: model.PostCandidateSourceColdStart, RandomSeed: 42},
		"KZ",
		"almaty",
		nil,
		postFeedExpiryPersistent,
	)

	if !cacheableOne || !cacheableTwo {
		t.Fatalf("cacheable flags = %v/%v, want both cacheable", cacheableOne, cacheableTwo)
	}
	if keyOne == keyTwo {
		t.Fatalf("cold-start cache keys are equal for different random seeds: %q", keyOne)
	}
	if !strings.Contains(keyOne, "random:41") || !strings.Contains(keyTwo, "random:42") {
		t.Fatalf("cold-start cache keys = %q/%q, want explicit random seed segments", keyOne, keyTwo)
	}
}

func TestPostFeedPostListCacheKeySeparatesRankingExperiments(t *testing.T) {
	viewerID := uuid.New()
	cache := &postFeedCacheFake{
		version: 7,
		posts:   make(map[string][]*model.Post),
	}
	controlUseCase := NewPostUseCase(
		&feedPostRepositoryStub{},
		postUseCaseUserClientStub{userID: viewerID},
		"https://posts.test",
	).WithPostFeedCache(cache, time.Minute, 30*time.Second).
		WithFeedExperimentAssignment("control")
	rankV2UseCase := NewPostUseCase(
		&feedPostRepositoryStub{},
		postUseCaseUserClientStub{userID: viewerID},
		"https://posts.test",
	).WithPostFeedCache(cache, time.Minute, 30*time.Second).
		WithFeedExperimentAssignment("rank-v2")

	source := feedPostCandidateSource{Name: model.PostCandidateSourceInterest}
	controlKey, _, controlCacheable := controlUseCase.postFeedPostListCacheKey(
		context.Background(),
		&viewerID,
		20,
		0,
		nil,
		source,
		"KZ",
		"almaty",
		nil,
		postFeedExpiryPersistent,
	)
	rankV2Key, _, rankV2Cacheable := rankV2UseCase.postFeedPostListCacheKey(
		context.Background(),
		&viewerID,
		20,
		0,
		nil,
		source,
		"KZ",
		"almaty",
		nil,
		postFeedExpiryPersistent,
	)

	if !controlCacheable || !rankV2Cacheable {
		t.Fatalf("cacheable flags = %v/%v, want both cacheable", controlCacheable, rankV2Cacheable)
	}
	if controlKey == rankV2Key {
		t.Fatalf("cache keys are equal for different ranking experiments: %q", controlKey)
	}
	if !strings.Contains(controlKey, "rank:control") {
		t.Fatalf("control cache key = %q, want rank:control segment", controlKey)
	}
	if !strings.Contains(rankV2Key, "rank:rank-v2") {
		t.Fatalf("rank-v2 cache key = %q, want rank:rank-v2 segment", rankV2Key)
	}
}

func TestPostFeedPostListCacheKeySeparatesRankingPolicyOverrides(t *testing.T) {
	viewerID := uuid.New()
	cache := &postFeedCacheFake{
		version: 7,
		posts:   make(map[string][]*model.Post),
	}
	firstUseCase := NewPostUseCase(
		&feedPostRepositoryStub{},
		postUseCaseUserClientStub{userID: viewerID},
		"https://posts.test",
	).WithPostFeedCache(cache, time.Minute, 30*time.Second).
		WithFeedExperimentAssignment("rank-v2").
		WithFeedExperimentPolicyOverrides("rank-v2:socialFriendBoostHours=12")
	secondUseCase := NewPostUseCase(
		&feedPostRepositoryStub{},
		postUseCaseUserClientStub{userID: viewerID},
		"https://posts.test",
	).WithPostFeedCache(cache, time.Minute, 30*time.Second).
		WithFeedExperimentAssignment("rank-v2").
		WithFeedExperimentPolicyOverrides("rank-v2:socialFriendBoostHours=28")

	source := feedPostCandidateSource{Name: model.PostCandidateSourceInterest}
	firstKey, _, firstCacheable := firstUseCase.postFeedPostListCacheKey(
		context.Background(),
		&viewerID,
		20,
		0,
		nil,
		source,
		"KZ",
		"almaty",
		nil,
		postFeedExpiryPersistent,
	)
	secondKey, _, secondCacheable := secondUseCase.postFeedPostListCacheKey(
		context.Background(),
		&viewerID,
		20,
		0,
		nil,
		source,
		"KZ",
		"almaty",
		nil,
		postFeedExpiryPersistent,
	)

	if !firstCacheable || !secondCacheable {
		t.Fatalf("cacheable flags = %v/%v, want both cacheable", firstCacheable, secondCacheable)
	}
	if firstKey == secondKey {
		t.Fatalf("cache keys are equal after ranking policy override change: %q", firstKey)
	}
}

func TestBuildFeedUsesAnonymousFirstPagePostCache(t *testing.T) {
	authorID := uuid.New()
	now := time.Now().UTC()
	posts := []*model.Post{
		newFeedTestPost(authorID, "first", now),
		newFeedTestPost(authorID, "second", now.Add(-time.Minute)),
	}
	repo := &feedPostRepositoryStub{
		posts:             posts,
		listFeedPostCalls: make([]model.PostListFilter, 0),
	}
	cache := &postFeedCacheFake{
		version: 7,
		posts:   make(map[string][]*model.Post),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test").
		WithPostFeedCache(cache, time.Minute, 30*time.Second)

	for i := 0; i < 2; i++ {
		page, err := useCase.BuildFeed(context.Background(), "", BuildFeedInput{
			Surface: "content",
			Limit:   2,
		})
		if err != nil {
			t.Fatalf("BuildFeed call %d returned error: %v", i+1, err)
		}
		if postCards := postCardFeedData(page.Items); len(postCards) != 2 {
			t.Fatalf("call %d post cards = %d, want 2", i+1, len(postCards))
		}
	}
	if len(repo.listFeedPostCalls) != 4 {
		t.Fatalf("ListFeedPosts calls = %d, want one miss per anonymous candidate source", len(repo.listFeedPostCalls))
	}
	if cache.gets != 8 || cache.sets != 4 || cache.versionReads != 8 {
		t.Fatalf("cache gets/sets/versionReads = %d/%d/%d, want 8/4/8", cache.gets, cache.sets, cache.versionReads)
	}
}

func TestBuildFeedUsesViewerScopedFollowingPostCache(t *testing.T) {
	viewerOneID := uuid.New()
	viewerTwoID := uuid.New()
	authorID := uuid.New()
	communityID := uuid.New()
	now := time.Now().UTC()
	posts := []*model.Post{
		newFeedTestPost(authorID, "first", now),
		newFeedTestPost(authorID, "second", now.Add(-time.Minute)),
	}
	for _, post := range posts {
		post.CommunityID = &communityID
	}
	repo := &feedPostRepositoryStub{
		posts: posts,
		followedCommunityIDs: map[uuid.UUID]bool{
			communityID: true,
		},
		listFeedPostCalls: make([]model.PostListFilter, 0),
	}
	cache := &postFeedCacheFake{
		versionByScope: map[string]int64{
			postFeedCacheGlobalScope:                 7,
			postFeedCacheFollowingScope(viewerOneID): 3,
			postFeedCacheFollowingScope(viewerTwoID): 5,
		},
		posts: make(map[string][]*model.Post),
	}

	useCaseOne := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerOneID}, "https://posts.test").
		WithPostFeedCache(cache, time.Minute, 30*time.Second)
	useCaseTwo := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerTwoID}, "https://posts.test").
		WithPostFeedCache(cache, time.Minute, 30*time.Second)

	for i := 0; i < 2; i++ {
		page, err := useCaseOne.BuildFeed(context.Background(), "subject-one", BuildFeedInput{
			Surface: "content",
			Tab:     "following",
			Limit:   2,
		})
		if err != nil {
			t.Fatalf("viewer one BuildFeed call %d returned error: %v", i+1, err)
		}
		if len(page.Items) != 2 {
			t.Fatalf("viewer one call %d items = %d, want 2", i+1, len(page.Items))
		}
	}
	page, err := useCaseTwo.BuildFeed(context.Background(), "subject-two", BuildFeedInput{
		Surface: "content",
		Tab:     "following",
		Limit:   2,
	})
	if err != nil {
		t.Fatalf("viewer two BuildFeed returned error: %v", err)
	}
	if len(page.Items) != 2 {
		t.Fatalf("viewer two items = %d, want 2", len(page.Items))
	}
	if len(repo.listFeedPostCalls) != 4 {
		t.Fatalf("ListFeedPosts calls = %d, want following and social cache miss per viewer", len(repo.listFeedPostCalls))
	}
	if cache.gets != 6 || cache.sets != 4 {
		t.Fatalf("cache gets/sets = %d/%d, want 6/4", cache.gets, cache.sets)
	}
	if cache.versionReads != 12 {
		t.Fatalf("versionReads = %d, want global+following and global+viewer per request", cache.versionReads)
	}
}

func TestFollowCommunityInvalidatesViewerFollowingFeedCache(t *testing.T) {
	viewerID := uuid.New()
	communityID := uuid.New()
	now := time.Now().UTC()
	repo := &feedPostRepositoryStub{
		communities: []*model.Community{
			{
				ID:            communityID,
				Slug:          "almaty-guides",
				Title:         "Almaty Guides",
				Topic:         "TRAVEL",
				LanguageCode:  "en",
				Visibility:    enum.CommunityVisibilityPublic,
				PostingPolicy: enum.CommunityPostingPolicyMembersAfterModeration,
				Status:        enum.CommunityStatusActive,
				CreatedAt:     now,
				UpdatedAt:     now,
			},
		},
	}
	cache := &postFeedCacheFake{posts: make(map[string][]*model.Post)}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test").
		WithPostFeedCache(cache, time.Minute, 30*time.Second)

	if _, err := useCase.FollowCommunity(context.Background(), "subject", communityID); err != nil {
		t.Fatalf("FollowCommunity returned error: %v", err)
	}
	if !containsString(cache.bumpedScopes, postFeedCacheFollowingScope(viewerID)) {
		t.Fatalf("bumped scopes = %#v, want following scope", cache.bumpedScopes)
	}

	cache.bumpedScopes = nil
	if _, err := useCase.UnfollowCommunity(context.Background(), "subject", communityID); err != nil {
		t.Fatalf("UnfollowCommunity returned error: %v", err)
	}
	if !containsString(cache.bumpedScopes, postFeedCacheFollowingScope(viewerID)) {
		t.Fatalf("bumped scopes after unfollow = %#v, want following scope", cache.bumpedScopes)
	}
}

func TestBuildFeedExcludesViewerHiddenPosts(t *testing.T) {
	viewerID := uuid.New()
	authorID := uuid.New()
	now := time.Now().UTC()
	visiblePost := newFeedTestPost(authorID, "visible", now)
	hiddenPost := newFeedTestPost(authorID, "hidden", now.Add(-time.Minute))
	repo := &feedPostRepositoryStub{
		posts:             []*model.Post{visiblePost, hiddenPost},
		listFeedPostCalls: make([]model.PostListFilter, 0),
		hiddenPostIDsByViewer: map[uuid.UUID]map[uuid.UUID]bool{
			viewerID: {
				hiddenPost.ID: true,
			},
		},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test")

	page, err := useCase.BuildFeed(context.Background(), "subject", BuildFeedInput{
		Surface: "content",
		Limit:   2,
	})
	if err != nil {
		t.Fatalf("BuildFeed returned error: %v", err)
	}
	if len(repo.listFeedPostCalls) != 6 {
		t.Fatalf("ListFeedPosts calls = %d, want personalized candidate sources", len(repo.listFeedPostCalls))
	}
	for _, filter := range repo.listFeedPostCalls {
		if filter.ViewerUserID == nil || *filter.ViewerUserID != viewerID {
			t.Fatalf("viewer filter = %v, want %s", filter.ViewerUserID, viewerID)
		}
	}
	postCards := postCardFeedData(page.Items)
	if len(postCards) != 1 {
		t.Fatalf("post cards = %d, want 1", len(postCards))
	}
	data := postCards[0]
	if data.Post.Post.ID != visiblePost.ID {
		t.Fatalf("post = %s, want visible post %s", data.Post.Post.ID, visiblePost.ID)
	}
}

func TestFeedPostCandidateSourcesUsesGeoColdStartForAnonymousUsers(t *testing.T) {
	sources := feedPostCandidateSources("for_you", nil, " KZ ", " almaty ")

	got := make([]string, 0, len(sources))
	for _, source := range sources {
		got = append(got, source.Name)
		if source.FollowedByUserID != nil || source.ExcludeFollowedByUserID != nil {
			t.Fatalf("anonymous source %+v should not carry viewer-scoped filters", source)
		}
	}

	want := []string{
		model.PostCandidateSourceSystem,
		model.PostCandidateSourceGeo,
		model.PostCandidateSourceColdStart,
		model.PostCandidateSourcePopular,
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("anonymous geo candidate sources = %v, want %v", got, want)
	}
}

func TestFeedPostCandidateSourcesUsesColdStartForAnonymousUsersWithoutGeo(t *testing.T) {
	sources := feedPostCandidateSources("for_you", nil, "", "")

	got := make([]string, 0, len(sources))
	for _, source := range sources {
		got = append(got, source.Name)
	}
	want := []string{
		model.PostCandidateSourceSystem,
		model.PostCandidateSourceColdStart,
		model.PostCandidateSourcePopular,
		model.PostCandidateSourceGlobal,
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("anonymous candidate sources = %v, want %v", got, want)
	}
}

func TestFeedPostCandidateSourcesUsesNonPersonalizedTrendingSources(t *testing.T) {
	viewerID := uuid.New()
	sources := feedPostCandidateSources("trending", &viewerID, " KZ ", " almaty ")

	got := make([]string, 0, len(sources))
	for _, source := range sources {
		got = append(got, source.Name)
		if !source.DisablePersonalizedRanking {
			t.Fatalf("trending source %+v must disable personalized ranking", source)
		}
		if source.FollowedByUserID != nil || source.ExcludeFollowedByUserID != nil {
			t.Fatalf("trending source %+v must not carry follow filters", source)
		}
	}

	want := []string{
		model.PostCandidateSourceSystem,
		model.PostCandidateSourceGeo,
		model.PostCandidateSourcePopular,
		model.PostCandidateSourceGlobal,
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("trending candidate sources = %v, want %v", got, want)
	}
}

func TestBuildTrendingFeedKeepsViewerVisibilityWithoutPersonalizedRanking(t *testing.T) {
	viewerID := uuid.New()
	authorID := uuid.New()
	post := newFeedTestPost(authorID, "trending-post", time.Now().UTC().Add(-time.Hour))
	repo := &feedPostRepositoryStub{
		posts:             []*model.Post{post},
		stories:           []*model.Story{{ID: uuid.New()}},
		communities:       []*model.Community{{ID: uuid.New()}},
		listFeedPostCalls: make([]model.PostListFilter, 0),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test")

	page, err := useCase.BuildFeed(context.Background(), "subject", BuildFeedInput{
		Surface: "home",
		Tab:     "trending",
		Limit:   3,
	})
	if err != nil {
		t.Fatalf("BuildFeed returned error: %v", err)
	}
	if len(repo.listFeedPostCalls) != 3 {
		t.Fatalf("ListFeedPosts calls = %d, want system, popular, and global", len(repo.listFeedPostCalls))
	}
	for _, filter := range repo.listFeedPostCalls {
		if filter.ViewerUserID == nil || *filter.ViewerUserID != viewerID {
			t.Fatalf("trending viewer filter = %v, want %s", filter.ViewerUserID, viewerID)
		}
		if !filter.DisablePersonalizedRanking {
			t.Fatalf("trending filter %+v must disable personalized ranking", filter)
		}
	}
	for _, block := range page.Items {
		if block.Type == model.FeedBlockTypeStoriesTray || block.Type == model.FeedBlockTypeSuggestedCommunities {
			t.Fatalf("trending first page contains curated block %q", block.Type)
		}
	}
	if cards := postCardFeedData(page.Items); len(cards) != 1 || cards[0].Post.Post.ID != post.ID {
		t.Fatalf("trending post cards = %+v, want post %s", cards, post.ID)
	}
}

func TestNormalizeFeedTabSupportsTrending(t *testing.T) {
	if got := normalizeFeedTab(" TRENDING "); got != "trending" {
		t.Fatalf("normalizeFeedTab = %q, want trending", got)
	}
}

func TestFeedColdStartRandomSeedIsStableWithinDayAndScopedToViewer(t *testing.T) {
	viewerID := uuid.MustParse("11111111-1111-4111-8111-111111111111")
	now := time.Date(2026, 7, 11, 23, 59, 0, 0, time.FixedZone("UTC+5", 5*60*60))

	first := feedColdStartRandomSeed(&viewerID, " kz ", " Almaty ", " HOME ", now)
	second := feedColdStartRandomSeed(&viewerID, "KZ", "almaty", "home", now.Add(30*time.Second))
	if first <= 0 || first != second {
		t.Fatalf("same-day seed = %d/%d, want stable positive value", first, second)
	}

	nextDay := feedColdStartRandomSeed(&viewerID, "KZ", "almaty", "home", now.Add(24*time.Hour))
	if nextDay == first {
		t.Fatalf("next-day seed = %d, want value different from %d", nextDay, first)
	}

	otherViewerID := uuid.MustParse("22222222-2222-4222-8222-222222222222")
	otherViewer := feedColdStartRandomSeed(&otherViewerID, "KZ", "almaty", "home", now)
	if otherViewer == first {
		t.Fatalf("other-viewer seed = %d, want value different from %d", otherViewer, first)
	}
}

func TestWithColdStartRandomSeedOnlySeedsColdStartSource(t *testing.T) {
	sources := []feedPostCandidateSource{
		{Name: model.PostCandidateSourceSystem},
		{Name: model.PostCandidateSourceColdStart},
		{Name: model.PostCandidateSourcePopular},
	}

	seeded := withColdStartRandomSeed(sources, 42)
	if sources[1].RandomSeed != 0 {
		t.Fatal("withColdStartRandomSeed mutated the input slice")
	}
	for _, source := range seeded {
		if source.Name == model.PostCandidateSourceColdStart {
			if source.RandomSeed != 42 {
				t.Fatalf("cold-start random seed = %d, want 42", source.RandomSeed)
			}
			continue
		}
		if source.RandomSeed != 0 {
			t.Fatalf("source %q random seed = %d, want 0", source.Name, source.RandomSeed)
		}
	}
}

func TestTrackFeedEventsPersistsViewerScopedBatch(t *testing.T) {
	viewerID := uuid.New()
	postID := uuid.New()
	communityID := uuid.New()
	occurredAt := time.Date(2026, 6, 12, 9, 30, 0, 0, time.UTC)
	post := newFeedTestPost(uuid.New(), "viewed-post", occurredAt)
	post.ID = postID
	repo := &feedPostRepositoryStub{
		trackedFeedEvents: make([]model.FeedEvent, 0),
		posts:             []*model.Post{post},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test")

	accepted, err := useCase.TrackFeedEvents(context.Background(), "subject", TrackFeedEventsInput{
		Events: []FeedEventInput{{
			EventID:     uuid.New(),
			EventType:   "impression",
			Surface:     "HOME",
			Tab:         "",
			BlockID:     "post:" + postID.String(),
			BlockType:   model.FeedBlockTypePostCard,
			PostID:      postID,
			CommunityID: &communityID,
			Rank:        3,
			OccurredAt:  occurredAt,
			RequestID:   "req-feed-1",
			Metadata: map[string]any{
				"sessionId": "session-1",
			},
		}},
	})
	if err != nil {
		t.Fatalf("TrackFeedEvents returned error: %v", err)
	}
	if accepted != 1 {
		t.Fatalf("accepted = %d, want 1", accepted)
	}
	if len(repo.trackedFeedEvents) != 1 {
		t.Fatalf("tracked events = %d, want 1", len(repo.trackedFeedEvents))
	}
	if len(repo.trackedPostViews) != 1 {
		t.Fatalf("tracked post views = %d, want 1", len(repo.trackedPostViews))
	}
	if repo.trackedPostViews[0].postID != postID || repo.trackedPostViews[0].viewerUserID != viewerID {
		t.Fatalf("tracked post view = %+v, want post %s viewer %s", repo.trackedPostViews[0], postID, viewerID)
	}
	event := repo.trackedFeedEvents[0]
	if event.ViewerUserID == nil || *event.ViewerUserID != viewerID {
		t.Fatalf("viewer user id = %v, want %s", event.ViewerUserID, viewerID)
	}
	if event.EventType != model.FeedEventTypeImpression ||
		event.Surface != "home" ||
		event.Tab != "for_you" ||
		event.BlockID != "post:"+postID.String() ||
		event.BlockType != model.FeedBlockTypePostCard ||
		event.PostID == nil ||
		*event.PostID != postID ||
		event.CommunityID == nil ||
		*event.CommunityID != communityID ||
		event.Rank != 3 ||
		!event.OccurredAt.Equal(occurredAt) ||
		event.RequestID != "req-feed-1" {
		t.Fatalf("tracked event mismatch: %+v", event)
	}
	if got := event.Metadata["sessionId"]; got != "session-1" {
		t.Fatalf("metadata sessionId = %v, want session-1", got)
	}
}

func TestTrackFeedEventsAcceptsHomeEntityConversionClick(t *testing.T) {
	viewerID := uuid.New()
	occurredAt := time.Date(2026, 6, 12, 11, 0, 0, 0, time.UTC)
	repo := &feedPostRepositoryStub{
		trackedFeedEvents: make([]model.FeedEvent, 0),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test")

	accepted, err := useCase.TrackFeedEvents(context.Background(), "subject", TrackFeedEventsInput{
		Events: []FeedEventInput{{
			EventID:    uuid.New(),
			EventType:  model.FeedEventTypeClick,
			Surface:    "home",
			Tab:        "for_you",
			BlockID:    "home:recommended_activities",
			BlockType:  model.FeedBlockTypeActivityCard,
			Rank:       1,
			OccurredAt: occurredAt,
			Metadata: map[string]any{
				"action":     "conversion",
				"entityType": "activity",
				"entityId":   "activity-1",
				"source":     "home_recommended_activities",
				"tags":       []any{"hiking", "family", strings.Repeat("x", 80)},
			},
		}},
	})
	if err != nil {
		t.Fatalf("TrackFeedEvents returned error: %v", err)
	}
	if accepted != 1 {
		t.Fatalf("accepted = %d, want 1", accepted)
	}
	if len(repo.trackedFeedEvents) != 1 {
		t.Fatalf("tracked events = %d, want 1", len(repo.trackedFeedEvents))
	}
	event := repo.trackedFeedEvents[0]
	if event.EventType != model.FeedEventTypeClick ||
		event.Surface != "home" ||
		event.Tab != "for_you" ||
		event.BlockID != "home:recommended_activities" ||
		event.BlockType != model.FeedBlockTypeActivityCard ||
		event.PostID != nil ||
		event.Rank != 1 ||
		!event.OccurredAt.Equal(occurredAt) {
		t.Fatalf("tracked event mismatch: %+v", event)
	}
	if event.ViewerUserID == nil || *event.ViewerUserID != viewerID {
		t.Fatalf("viewer user id = %v, want %s", event.ViewerUserID, viewerID)
	}
	for key, want := range map[string]any{
		"action":     "conversion",
		"entityType": "activity",
		"entityId":   "activity-1",
		"source":     "home_recommended_activities",
	} {
		if got := event.Metadata[key]; got != want {
			t.Fatalf("metadata %s = %v, want %v", key, got, want)
		}
	}
	tags, ok := event.Metadata["tags"].([]string)
	if !ok {
		t.Fatalf("metadata tags = %#v, want string list", event.Metadata["tags"])
	}
	if len(tags) != 2 || tags[0] != "hiking" || tags[1] != "family" {
		t.Fatalf("metadata tags = %#v, want sanitized two-item list", tags)
	}
}

func TestTrackFeedEventsAcceptsGuideConversionBlock(t *testing.T) {
	viewerID := uuid.New()
	repo := &feedPostRepositoryStub{
		trackedFeedEvents: make([]model.FeedEvent, 0),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test")

	accepted, err := useCase.TrackFeedEvents(context.Background(), "subject", TrackFeedEventsInput{
		Events: []FeedEventInput{{
			EventID:   uuid.New(),
			EventType: model.FeedEventTypeClick,
			Surface:   "home",
			BlockID:   "guide:featured",
			BlockType: model.FeedBlockTypeGuideCard,
			Rank:      4,
			Metadata: map[string]any{
				"action":       "conversion",
				"entityType":   "guide",
				"entityId":     "featured",
				"semanticTags": []any{"guide", "local_expert"},
			},
		}},
	})
	if err != nil {
		t.Fatalf("TrackFeedEvents returned error: %v", err)
	}
	if accepted != 1 {
		t.Fatalf("accepted = %d, want 1", accepted)
	}
	if len(repo.trackedFeedEvents) != 1 {
		t.Fatalf("tracked events = %d, want 1", len(repo.trackedFeedEvents))
	}
	if repo.trackedFeedEvents[0].BlockType != model.FeedBlockTypeGuideCard {
		t.Fatalf("block type = %q, want guide card", repo.trackedFeedEvents[0].BlockType)
	}
	if repo.trackedFeedEvents[0].PostID != nil {
		t.Fatalf("guide conversion post id = %v, want nil", repo.trackedFeedEvents[0].PostID)
	}
	tags, ok := repo.trackedFeedEvents[0].Metadata["semanticTags"].([]string)
	if !ok || len(tags) != 2 || tags[0] != "guide" || tags[1] != "local_expert" {
		t.Fatalf("semantic tags = %#v, want sanitized tags", repo.trackedFeedEvents[0].Metadata["semanticTags"])
	}
}

func TestTrackFeedEventsPersistsNotInterestedAsNegativeSignal(t *testing.T) {
	viewerID := uuid.New()
	postID := uuid.New()
	repo := &feedPostRepositoryStub{
		trackedFeedEvents: make([]model.FeedEvent, 0),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test")

	accepted, err := useCase.TrackFeedEvents(context.Background(), "subject", TrackFeedEventsInput{
		Events: []FeedEventInput{{
			EventID:   uuid.New(),
			EventType: "NOT_INTERESTED",
			Surface:   "content",
			Tab:       "for_you",
			BlockID:   "post:" + postID.String(),
			BlockType: model.FeedBlockTypePostCard,
			PostID:    postID,
			Rank:      5,
		}},
	})
	if err != nil {
		t.Fatalf("TrackFeedEvents returned error: %v", err)
	}
	if accepted != 1 {
		t.Fatalf("accepted = %d, want 1", accepted)
	}
	if len(repo.trackedFeedEvents) != 1 {
		t.Fatalf("tracked events = %d, want 1", len(repo.trackedFeedEvents))
	}
	event := repo.trackedFeedEvents[0]
	if event.EventType != model.FeedEventTypeNotInterested {
		t.Fatalf("event type = %q, want %q", event.EventType, model.FeedEventTypeNotInterested)
	}
	if event.ViewerUserID == nil || *event.ViewerUserID != viewerID {
		t.Fatalf("viewer user id = %v, want %s", event.ViewerUserID, viewerID)
	}
}

func TestTrackFeedEventsAcceptsCommunityCardReportSignal(t *testing.T) {
	viewerID := uuid.New()
	communityID := uuid.New()
	repo := &feedPostRepositoryStub{
		trackedFeedEvents: make([]model.FeedEvent, 0),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test")

	accepted, err := useCase.TrackFeedEvents(context.Background(), "subject", TrackFeedEventsInput{
		Events: []FeedEventInput{{
			EventID:     uuid.New(),
			EventType:   model.FeedEventTypeReport,
			Surface:     "content",
			Tab:         "for_you",
			BlockID:     "community:" + communityID.String() + ":profile",
			BlockType:   model.FeedBlockTypeCommunityCard,
			CommunityID: &communityID,
			Rank:        0,
			Metadata: map[string]any{
				"entityType":   model.FeedInterestEntityTypeCommunity,
				"entityId":     communityID.String(),
				"feedbackType": model.FeedEventTypeReport,
			},
		}},
	})

	if err != nil {
		t.Fatalf("TrackFeedEvents returned error: %v", err)
	}
	if accepted != 1 {
		t.Fatalf("accepted = %d, want 1", accepted)
	}
	if len(repo.trackedFeedEvents) != 1 {
		t.Fatalf("tracked events = %d, want 1", len(repo.trackedFeedEvents))
	}
	event := repo.trackedFeedEvents[0]
	if event.BlockType != model.FeedBlockTypeCommunityCard ||
		event.CommunityID == nil ||
		*event.CommunityID != communityID ||
		event.EventType != model.FeedEventTypeReport {
		t.Fatalf("community report event = %+v, want community-card report", event)
	}
}

func TestTrackFeedEventsAcceptsEngagementEventTypes(t *testing.T) {
	viewerID := uuid.New()
	postID := uuid.New()
	communityID := uuid.New()
	repo := &feedPostRepositoryStub{
		trackedFeedEvents: make([]model.FeedEvent, 0),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test")

	inputs := []FeedEventInput{
		{
			EventID:   uuid.New(),
			EventType: "LIKE",
			Surface:   "content",
			Tab:       "for_you",
			BlockID:   "post:" + postID.String(),
			BlockType: model.FeedBlockTypePostCard,
			PostID:    postID,
			Rank:      1,
		},
		{
			EventID:   uuid.New(),
			EventType: "comment",
			Surface:   "content",
			Tab:       "for_you",
			BlockID:   "post:" + postID.String(),
			BlockType: model.FeedBlockTypePostCard,
			PostID:    postID,
			Rank:      1,
		},
		{
			EventID:   uuid.New(),
			EventType: "share",
			Surface:   "content",
			Tab:       "for_you",
			BlockID:   "post:" + postID.String(),
			BlockType: model.FeedBlockTypePostCard,
			PostID:    postID,
			Rank:      1,
		},
		{
			EventID:   uuid.New(),
			EventType: "report",
			Surface:   "content",
			Tab:       "for_you",
			BlockID:   "post:" + postID.String(),
			BlockType: model.FeedBlockTypePostCard,
			PostID:    postID,
			Rank:      1,
		},
		{
			EventID:   uuid.New(),
			EventType: "dwell",
			Surface:   "content",
			Tab:       "for_you",
			BlockID:   "post:" + postID.String(),
			BlockType: model.FeedBlockTypePostCard,
			PostID:    postID,
			Rank:      1,
			Metadata: map[string]any{
				"dwellMs": 4200,
			},
		},
		{
			EventID:     uuid.New(),
			EventType:   "subscribe",
			Surface:     "home",
			Tab:         "for_you",
			BlockID:     "communities:suggested",
			BlockType:   model.FeedBlockTypeSuggestedCommunities,
			CommunityID: &communityID,
			Rank:        0,
		},
	}

	accepted, err := useCase.TrackFeedEvents(context.Background(), "subject", TrackFeedEventsInput{Events: inputs})
	if err != nil {
		t.Fatalf("TrackFeedEvents returned error: %v", err)
	}
	if accepted != len(inputs) {
		t.Fatalf("accepted = %d, want %d", accepted, len(inputs))
	}

	got := make([]string, 0, len(repo.trackedFeedEvents))
	for _, event := range repo.trackedFeedEvents {
		got = append(got, event.EventType)
	}
	want := []string{
		model.FeedEventTypeLike,
		model.FeedEventTypeComment,
		model.FeedEventTypeShare,
		model.FeedEventTypeReport,
		model.FeedEventTypeDwell,
		model.FeedEventTypeSubscribe,
	}
	if strings.Join(got, ",") != strings.Join(want, ",") {
		t.Fatalf("event types = %#v, want %#v", got, want)
	}
}

func TestTrackFeedEventsInvalidatesViewerFeedCacheForNegativeSignals(t *testing.T) {
	viewerID := uuid.New()
	postID := uuid.New()
	repo := &feedPostRepositoryStub{
		trackedFeedEvents: make([]model.FeedEvent, 0),
	}
	cache := &postFeedCacheFake{}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test").
		WithPostFeedCache(cache, time.Minute, 30*time.Second)

	accepted, err := useCase.TrackFeedEvents(context.Background(), "subject", TrackFeedEventsInput{
		Events: []FeedEventInput{{
			EventID:   uuid.New(),
			EventType: model.FeedEventTypeHide,
			Surface:   "content",
			Tab:       "for_you",
			BlockID:   "post:" + postID.String(),
			BlockType: model.FeedBlockTypePostCard,
			PostID:    postID,
			Rank:      2,
		}},
	})
	if err != nil {
		t.Fatalf("TrackFeedEvents returned error: %v", err)
	}
	if accepted != 1 {
		t.Fatalf("accepted = %d, want 1", accepted)
	}
	if !containsString(cache.bumpedScopes, postFeedCacheViewerScope(viewerID)) {
		t.Fatalf("bumped scopes = %#v, want viewer scope", cache.bumpedScopes)
	}
	if !containsString(cache.bumpedScopes, postFeedCacheFollowingScope(viewerID)) {
		t.Fatalf("bumped scopes = %#v, want following scope", cache.bumpedScopes)
	}
}

func TestTrackFeedEventsInvalidatesViewerFeedCacheForEngagementSignals(t *testing.T) {
	viewerID := uuid.New()
	postID := uuid.New()
	repo := &feedPostRepositoryStub{
		trackedFeedEvents: make([]model.FeedEvent, 0),
	}
	cache := &postFeedCacheFake{}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test").
		WithPostFeedCache(cache, time.Minute, 30*time.Second)

	events := []FeedEventInput{{
		EventID:   uuid.New(),
		EventType: model.FeedEventTypeImpression,
		Surface:   "content",
		Tab:       "for_you",
		BlockID:   "post:" + postID.String(),
		BlockType: model.FeedBlockTypePostCard,
		PostID:    postID,
		Rank:      1,
	}, {
		EventID:   uuid.New(),
		EventType: model.FeedEventTypeClick,
		Surface:   "content",
		Tab:       "for_you",
		BlockID:   "post:" + postID.String(),
		BlockType: model.FeedBlockTypePostCard,
		PostID:    postID,
		Rank:      1,
	}, {
		EventID:   uuid.New(),
		EventType: model.FeedEventTypeDwell,
		Surface:   "content",
		Tab:       "for_you",
		BlockID:   "post:" + postID.String(),
		BlockType: model.FeedBlockTypePostCard,
		PostID:    postID,
		Rank:      1,
		Metadata:  map[string]any{"dwellMs": 4200},
	}, {
		EventID:   uuid.New(),
		EventType: model.FeedEventTypeLike,
		Surface:   "content",
		Tab:       "for_you",
		BlockID:   "post:" + postID.String(),
		BlockType: model.FeedBlockTypePostCard,
		PostID:    postID,
		Rank:      1,
	}, {
		EventID:   uuid.New(),
		EventType: model.FeedEventTypeComment,
		Surface:   "content",
		Tab:       "for_you",
		BlockID:   "post:" + postID.String(),
		BlockType: model.FeedBlockTypePostCard,
		PostID:    postID,
		Rank:      1,
	}, {
		EventID:   uuid.New(),
		EventType: model.FeedEventTypeShare,
		Surface:   "content",
		Tab:       "for_you",
		BlockID:   "post:" + postID.String(),
		BlockType: model.FeedBlockTypePostCard,
		PostID:    postID,
		Rank:      1,
	}, {
		EventID:   uuid.New(),
		EventType: model.FeedEventTypeSubscribe,
		Surface:   "content",
		Tab:       "for_you",
		BlockID:   "community:" + postID.String(),
		BlockType: model.FeedBlockTypeSuggestedCommunities,
		Rank:      1,
		Metadata:  map[string]any{"communityId": postID.String()},
	}}

	accepted, err := useCase.TrackFeedEvents(context.Background(), "subject", TrackFeedEventsInput{Events: events})
	if err != nil {
		t.Fatalf("TrackFeedEvents returned error: %v", err)
	}
	if accepted != len(events) {
		t.Fatalf("accepted = %d, want %d", accepted, len(events))
	}
	if cache.bumps != 1 {
		t.Fatalf("cache bumps = %d, want one batch bump", cache.bumps)
	}
	for _, scope := range []string{
		postFeedCacheViewerScope(viewerID),
		postFeedCacheFollowingScope(viewerID),
		postFeedCacheDiscoveryScope(viewerID),
	} {
		if !containsString(cache.bumpedScopes, scope) {
			t.Fatalf("bumped scopes = %#v, want %s", cache.bumpedScopes, scope)
		}
	}
}

func TestTrackFeedEventsKeepsViewerFeedCacheForImpressionOnlyBatch(t *testing.T) {
	viewerID := uuid.New()
	postID := uuid.New()
	repo := &feedPostRepositoryStub{
		trackedFeedEvents: make([]model.FeedEvent, 0),
	}
	cache := &postFeedCacheFake{}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test").
		WithPostFeedCache(cache, time.Minute, 30*time.Second)

	accepted, err := useCase.TrackFeedEvents(context.Background(), "subject", TrackFeedEventsInput{
		Events: []FeedEventInput{{
			EventID:   uuid.New(),
			EventType: model.FeedEventTypeImpression,
			Surface:   "content",
			Tab:       "for_you",
			BlockID:   "post:" + postID.String(),
			BlockType: model.FeedBlockTypePostCard,
			PostID:    postID,
			Rank:      1,
		}},
	})
	if err != nil {
		t.Fatalf("TrackFeedEvents returned error: %v", err)
	}
	if accepted != 1 {
		t.Fatalf("accepted = %d, want 1", accepted)
	}
	if cache.bumps != 0 || len(cache.bumpedScopes) != 0 {
		t.Fatalf("cache bumped for impression-only batch: bumps=%d scopes=%#v", cache.bumps, cache.bumpedScopes)
	}
}

func TestTrackFeedEventsRejectsInvalidEvent(t *testing.T) {
	repo := &feedPostRepositoryStub{}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: uuid.New()}, "https://posts.test")

	_, err := useCase.TrackFeedEvents(context.Background(), "subject", TrackFeedEventsInput{
		Events: []FeedEventInput{{
			EventID:   uuid.New(),
			EventType: "unknown",
			Surface:   "content",
			BlockID:   "post:" + uuid.NewString(),
			BlockType: model.FeedBlockTypePostCard,
			Rank:      1,
		}},
	})

	if !errors.Is(err, ErrInvalidFeedEvent) {
		t.Fatalf("TrackFeedEvents error = %v, want %v", err, ErrInvalidFeedEvent)
	}
}

func TestListFeedUserInterestsReturnsViewerScopedReadModel(t *testing.T) {
	viewerID := uuid.New()
	updatedAt := time.Date(2026, 6, 12, 12, 0, 0, 0, time.UTC)
	repo := &feedPostRepositoryStub{
		feedUserInterests: []model.FeedUserInterest{{
			ViewerUserID:     viewerID,
			EntityType:       model.FeedInterestEntityTypeActivity,
			EntityID:         "activity-1",
			Score:            3.5,
			ClickCount:       1,
			ConversionCount:  1,
			LastEventAt:      updatedAt,
			UpdatedAt:        updatedAt,
			RepresentativeID: "activity-1",
			Metadata: map[string]any{
				"source": "home_recommended_activities",
			},
		}},
		listFeedUserInterestFilters: make([]model.FeedUserInterestListFilter, 0),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test")

	interests, err := useCase.ListFeedUserInterests(context.Background(), "subject", ListFeedUserInterestsInput{
		EntityTypes: []string{model.FeedInterestEntityTypeActivity},
		Limit:       5,
	})
	if err != nil {
		t.Fatalf("ListFeedUserInterests returned error: %v", err)
	}
	if len(interests) != 1 {
		t.Fatalf("interests = %d, want 1", len(interests))
	}
	if interests[0].EntityType != model.FeedInterestEntityTypeActivity ||
		interests[0].EntityID != "activity-1" ||
		interests[0].Score != 3.5 ||
		interests[0].ConversionCount != 1 {
		t.Fatalf("interest mismatch: %+v", interests[0])
	}
	if len(repo.listFeedUserInterestFilters) != 1 {
		t.Fatalf("ListFeedUserInterests calls = %d, want 1", len(repo.listFeedUserInterestFilters))
	}
	filter := repo.listFeedUserInterestFilters[0]
	if filter.ViewerUserID != viewerID || filter.Limit != 5 || len(filter.EntityTypes) != 1 || filter.EntityTypes[0] != model.FeedInterestEntityTypeActivity {
		t.Fatalf("interest filter = %+v, want viewer scoped activity limit 5", filter)
	}
}

func TestListFeedUserInterestsAllowsPostProfileAffinity(t *testing.T) {
	viewerID := uuid.New()
	repo := &feedPostRepositoryStub{
		feedUserInterests: []model.FeedUserInterest{{
			ViewerUserID: viewerID,
			EntityType:   model.FeedInterestEntityTypePostProfile,
			EntityID:     "quick_post",
			Score:        2.25,
		}},
		listFeedUserInterestFilters: make([]model.FeedUserInterestListFilter, 0),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test")

	interests, err := useCase.ListFeedUserInterests(context.Background(), "subject", ListFeedUserInterestsInput{
		EntityTypes: []string{
			model.FeedInterestEntityTypePostProfile,
			strings.ToUpper(model.FeedInterestEntityTypePostProfile),
			"unknown",
		},
		Limit: 5,
	})
	if err != nil {
		t.Fatalf("ListFeedUserInterests returned error: %v", err)
	}
	if len(interests) != 1 || interests[0].EntityType != model.FeedInterestEntityTypePostProfile {
		t.Fatalf("interests = %+v, want one post profile interest", interests)
	}
	if len(repo.listFeedUserInterestFilters) != 1 {
		t.Fatalf("ListFeedUserInterests calls = %d, want 1", len(repo.listFeedUserInterestFilters))
	}
	filter := repo.listFeedUserInterestFilters[0]
	if filter.ViewerUserID != viewerID || len(filter.EntityTypes) != 1 || filter.EntityTypes[0] != model.FeedInterestEntityTypePostProfile {
		t.Fatalf("interest filter = %+v, want normalized post profile only", filter)
	}
}

func TestListFeedUserInterestsReturnsEmptyForAnonymousViewer(t *testing.T) {
	repo := &feedPostRepositoryStub{
		listFeedUserInterestFilters: make([]model.FeedUserInterestListFilter, 0),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: uuid.New()}, "https://posts.test")

	interests, err := useCase.ListFeedUserInterests(context.Background(), "", ListFeedUserInterestsInput{Limit: 5})
	if err != nil {
		t.Fatalf("ListFeedUserInterests returned error: %v", err)
	}
	if len(interests) != 0 {
		t.Fatalf("interests = %d, want empty anonymous interest profile", len(interests))
	}
	if len(repo.listFeedUserInterestFilters) != 0 {
		t.Fatalf("ListFeedUserInterests calls = %d, want 0 for anonymous viewer", len(repo.listFeedUserInterestFilters))
	}
}

func TestListFeedQualityMetricsReturnsAggregatedCounters(t *testing.T) {
	since := time.Date(2026, 6, 1, 0, 0, 0, 0, time.UTC)
	until := time.Date(2026, 6, 8, 0, 0, 0, 0, time.UTC)
	repo := &feedPostRepositoryStub{
		feedQualityMetrics: []model.FeedQualityMetric{{
			Surface:            "home",
			BlockType:          model.FeedBlockTypeTourCard,
			CommunityID:        "00000000-0000-4000-8000-000000000222",
			Action:             "conversion",
			EventCount:         12,
			UniqueViewers:      9,
			ConversionCount:    7,
			HideCount:          1,
			NotInterestedCount: 2,
			ReportCount:        3,
		}},
		listFeedQualityMetricFilters: make([]model.FeedQualityMetricsFilter, 0),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: uuid.New()}, "https://posts.test")

	metrics, err := useCase.ListFeedQualityMetrics(context.Background(), ListFeedQualityMetricsInput{
		Since:   since,
		Until:   until,
		Surface: " HOME ",
		Limit:   500,
	})
	if err != nil {
		t.Fatalf("ListFeedQualityMetrics returned error: %v", err)
	}
	if len(metrics) != 1 {
		t.Fatalf("metrics = %d, want 1", len(metrics))
	}
	metric := metrics[0]
	if metric.Action != "conversion" ||
		metric.CommunityID != "00000000-0000-4000-8000-000000000222" ||
		metric.ConversionCount != 7 ||
		metric.UniqueViewers != 9 ||
		metric.ReportCount != 3 {
		t.Fatalf("unexpected metric: %+v", metric)
	}
	if len(repo.listFeedQualityMetricFilters) != 1 {
		t.Fatalf("filters = %d, want 1", len(repo.listFeedQualityMetricFilters))
	}
	filter := repo.listFeedQualityMetricFilters[0]
	if !filter.Since.Equal(since) || !filter.Until.Equal(until) {
		t.Fatalf("filter window = %v..%v, want %v..%v", filter.Since, filter.Until, since, until)
	}
	if filter.Surface != "home" {
		t.Fatalf("surface = %q, want home", filter.Surface)
	}
	if filter.Limit != maxFeedQualityMetricsLimit {
		t.Fatalf("limit = %d, want max clamp %d", filter.Limit, maxFeedQualityMetricsLimit)
	}
}

func TestFeedCursorUsesFeedRankedAtWhenPresent(t *testing.T) {
	publishedAt := time.Date(2026, 6, 12, 12, 0, 0, 0, time.UTC)
	feedRankedAt := publishedAt.Add(-14 * 24 * time.Hour)
	post := newFeedTestPost(uuid.New(), "negative-signal", publishedAt)
	post.FeedRankedAt = &feedRankedAt

	cursor := feedCursorFromPostView(&PostView{Post: post})
	if cursor == nil {
		t.Fatal("cursor is nil, want feed cursor")
	}
	if !cursor.PublishedAt.Equal(feedRankedAt) {
		t.Fatalf("cursor ranked time = %v, want %v", cursor.PublishedAt, feedRankedAt)
	}
}

type feedPostRepositoryStub struct {
	port.PostRepository
	posts                        []*model.Post
	stories                      []*model.Story
	communities                  []*model.Community
	communityListFilters         []model.CommunityListFilter
	userCommunityIDs             []uuid.UUID
	followedCommunityIDs         map[uuid.UUID]bool
	memberships                  map[uuid.UUID]*model.CommunityMembership
	filterCommunityIDsLog        [][]uuid.UUID
	filterFollowedUserIDLog      []uuid.UUID
	listFeedPostCalls            []model.PostListFilter
	hiddenPostIDsByViewer        map[uuid.UUID]map[uuid.UUID]bool
	viewerLikedPostIDs           map[uuid.UUID]bool
	batchPostLikesCalls          [][]uuid.UUID
	hasPostLikeCalls             int
	trackedFeedEvents            []model.FeedEvent
	trackedPostViews             []feedTrackedPostView
	feedUserInterests            []model.FeedUserInterest
	listFeedUserInterestFilters  []model.FeedUserInterestListFilter
	feedQualityMetrics           []model.FeedQualityMetric
	listFeedQualityMetricFilters []model.FeedQualityMetricsFilter
	feedSocialEdges              map[uuid.UUID]model.FeedSocialEdgeSet
	upsertedSocialEdges          []model.FeedSocialEdge
	deletedSocialEdges           []feedDeletedSocialEdge
}

type feedTrackedPostView struct {
	postID       uuid.UUID
	viewerUserID uuid.UUID
}

type feedDeletedSocialEdge struct {
	viewerUserID    uuid.UUID
	targetUserID    uuid.UUID
	edgeType        string
	sourceUpdatedAt time.Time
}

func (r *feedPostRepositoryStub) ListPosts(_ context.Context, filter model.PostListFilter) ([]*model.Post, error) {
	return r.listPosts(filter)
}

func (r *feedPostRepositoryStub) ListFeedPosts(_ context.Context, filter model.PostListFilter) ([]*model.Post, error) {
	if r.listFeedPostCalls != nil {
		r.listFeedPostCalls = append(r.listFeedPostCalls, filter)
	}
	return r.listPosts(filter)
}

func (r *feedPostRepositoryStub) GetPostByID(_ context.Context, postID uuid.UUID) (*model.Post, error) {
	for _, post := range r.posts {
		if post != nil && post.ID == postID {
			copy := *post
			return &copy, nil
		}
	}
	return nil, nil
}

func (r *feedPostRepositoryStub) ListStories(_ context.Context, filter model.StoryListFilter) ([]*model.Story, error) {
	items := make([]*model.Story, 0, len(r.stories))
	for _, story := range r.stories {
		if story == nil {
			continue
		}
		if filter.StoryID != nil && *filter.StoryID != uuid.Nil && story.ID != *filter.StoryID {
			continue
		}
		copy := *story
		items = append(items, &copy)
	}
	if filter.Offset >= len(items) {
		return []*model.Story{}, nil
	}
	end := filter.Offset + filter.Limit
	if filter.Limit <= 0 || end > len(items) {
		end = len(items)
	}
	return items[filter.Offset:end], nil
}

func (r *feedPostRepositoryStub) listPosts(filter model.PostListFilter) ([]*model.Post, error) {
	if r.filterCommunityIDsLog != nil {
		r.filterCommunityIDsLog = append(r.filterCommunityIDsLog, append([]uuid.UUID(nil), filter.CommunityIDs...))
	}
	if r.filterFollowedUserIDLog != nil && filter.FollowedByUserID != nil {
		r.filterFollowedUserIDLog = append(r.filterFollowedUserIDLog, *filter.FollowedByUserID)
	}

	items := make([]*model.Post, 0, len(r.posts))
	for _, post := range r.posts {
		if post == nil {
			continue
		}
		if !post.IsPubliclyVisible() {
			continue
		}
		if filter.OnlyExpiring && post.ExpiresAt == nil {
			continue
		}
		if filter.ExcludeExpiring && post.ExpiresAt != nil {
			continue
		}
		if filter.ViewerUserID != nil {
			hiddenPostIDs := r.hiddenPostIDsByViewer[*filter.ViewerUserID]
			if hiddenPostIDs[post.ID] {
				continue
			}
			if filter.CandidateSource != "" &&
				filter.CandidateSource != model.PostCandidateSourceFollowing &&
				post.AuthorUserID == *filter.ViewerUserID {
				continue
			}
		}
		if len(filter.CommunityIDs) > 0 {
			if post.CommunityID == nil || !containsUUID(filter.CommunityIDs, *post.CommunityID) {
				continue
			}
		}
		if filter.FollowedByUserID != nil {
			if post.CommunityID == nil || !r.followedCommunityIDs[*post.CommunityID] {
				continue
			}
		}
		if filter.ExcludeFollowedByUserID != nil &&
			post.CommunityID != nil &&
			r.followedCommunityIDs[*post.CommunityID] {
			continue
		}
		if !r.postMatchesCandidateSource(filter, post) {
			continue
		}
		if filter.FeedCursorPublishedAt != nil && filter.FeedCursorPostID != nil {
			rankedAt := feedTestPostRankedAt(post)
			if rankedAt.After(*filter.FeedCursorPublishedAt) {
				continue
			}
			if rankedAt.Equal(*filter.FeedCursorPublishedAt) && post.ID.String() >= filter.FeedCursorPostID.String() {
				continue
			}
		}
		items = append(items, post)
	}
	if filter.Offset >= len(items) {
		return []*model.Post{}, nil
	}
	end := filter.Offset + filter.Limit
	if filter.Limit <= 0 || end > len(items) {
		end = len(items)
	}
	return items[filter.Offset:end], nil
}

func (r *feedPostRepositoryStub) postMatchesCandidateSource(filter model.PostListFilter, post *model.Post) bool {
	switch filter.CandidateSource {
	case "", model.PostCandidateSourceGlobal, model.PostCandidateSourceFollowing, model.PostCandidateSourceFollowed, model.PostCandidateSourcePopular:
		return true
	case model.PostCandidateSourceSocial:
		if filter.ViewerUserID == nil || *filter.ViewerUserID == uuid.Nil {
			return false
		}
		edge := r.feedSocialEdges[post.AuthorUserID]
		return edge.Friend || edge.Following
	case model.PostCandidateSourceSystem:
		return postMatchesFeedSystemSource(post)
	case model.PostCandidateSourceGeo:
		return postMatchesFeedGeo(filter, post)
	case model.PostCandidateSourceInterest:
		if filter.ViewerUserID == nil || *filter.ViewerUserID == uuid.Nil {
			return false
		}
		return r.postMatchesFeedInterest(*filter.ViewerUserID, post)
	case model.PostCandidateSourceColdStart:
		hasViewer := filter.ViewerUserID != nil && *filter.ViewerUserID != uuid.Nil
		if hasViewer && r.viewerHasPositiveFeedInterest(*filter.ViewerUserID) {
			return false
		}
		if strings.TrimSpace(filter.CurrentCityID) != "" || strings.TrimSpace(filter.CurrentCountryCode) != "" {
			return postMatchesFeedGeo(filter, post)
		}
		return true
	default:
		return true
	}
}

func postMatchesFeedSystemSource(post *model.Post) bool {
	if post == nil || post.PostProfileKey != enum.PostProfileArticleV1 {
		return false
	}
	for _, tag := range post.Tags {
		switch strings.ToLower(strings.TrimSpace(tag)) {
		case "official_updates", "travel_alerts", "local_news":
			return true
		}
	}
	return false
}

func postMatchesFeedGeo(filter model.PostListFilter, post *model.Post) bool {
	cityID := strings.ToLower(strings.TrimSpace(filter.CurrentCityID))
	countryCode := strings.ToUpper(strings.TrimSpace(filter.CurrentCountryCode))
	if cityID == "" && countryCode == "" {
		return false
	}
	if cityID != "" && post.PlaceCityID != nil && strings.EqualFold(strings.TrimSpace(*post.PlaceCityID), cityID) {
		return true
	}
	if countryCode != "" && post.PlaceCountryCode != nil && strings.EqualFold(strings.TrimSpace(*post.PlaceCountryCode), countryCode) {
		return true
	}
	return false
}

func (r *feedPostRepositoryStub) postMatchesFeedInterest(viewerID uuid.UUID, post *model.Post) bool {
	for _, interest := range r.feedUserInterests {
		if interest.ViewerUserID != viewerID || interest.Score <= 0 {
			continue
		}
		entityID := strings.ToLower(strings.TrimSpace(interest.EntityID))
		if entityID == "" {
			continue
		}
		switch strings.TrimSpace(interest.EntityType) {
		case model.FeedInterestEntityTypePost:
			if strings.EqualFold(entityID, post.ID.String()) {
				return true
			}
		case model.FeedInterestEntityTypePostProfile:
			if entityID == strings.ToLower(strings.TrimSpace(string(post.PostProfileKey))) {
				return true
			}
		case model.FeedInterestEntityTypeCommunity:
			if post.CommunityID != nil && strings.EqualFold(entityID, post.CommunityID.String()) {
				return true
			}
		case model.FeedInterestEntityTypeCity:
			if post.PlaceCityID != nil && entityID == strings.ToLower(strings.TrimSpace(*post.PlaceCityID)) {
				return true
			}
		case model.FeedInterestEntityTypeCountry:
			if post.PlaceCountryCode != nil && entityID == strings.ToLower(strings.TrimSpace(*post.PlaceCountryCode)) {
				return true
			}
		case model.FeedInterestEntityTypeCategory:
			if entityID == strings.ToLower(strings.TrimSpace(string(post.Category))) {
				return true
			}
		case model.FeedInterestEntityTypeTag:
			for _, tag := range post.Tags {
				if entityID == strings.ToLower(strings.TrimSpace(tag)) {
					return true
				}
			}
		}
	}
	return false
}

func (r *feedPostRepositoryStub) viewerHasPositiveFeedInterest(viewerID uuid.UUID) bool {
	for _, interest := range r.feedUserInterests {
		if interest.ViewerUserID == viewerID && interest.Score > 0 {
			return true
		}
	}
	return false
}

func (r *feedPostRepositoryStub) HasPostLike(_ context.Context, _ uuid.UUID, _ uuid.UUID) (bool, error) {
	r.hasPostLikeCalls++
	return false, nil
}

func (r *feedPostRepositoryStub) ListPostLikesByUser(_ context.Context, postIDs []uuid.UUID, _ uuid.UUID) (map[uuid.UUID]bool, error) {
	if r.batchPostLikesCalls != nil {
		r.batchPostLikesCalls = append(r.batchPostLikesCalls, append([]uuid.UUID(nil), postIDs...))
	}
	likes := make(map[uuid.UUID]bool, len(postIDs))
	for _, postID := range postIDs {
		if r.viewerLikedPostIDs[postID] {
			likes[postID] = true
		}
	}
	return likes, nil
}

func (r *feedPostRepositoryStub) ListPostSeenByUser(_ context.Context, postIDs []uuid.UUID, _ uuid.UUID) (map[uuid.UUID]time.Time, error) {
	return make(map[uuid.UUID]time.Time, len(postIDs)), nil
}

func (r *feedPostRepositoryStub) ListStorySeenByUser(_ context.Context, storyIDs []uuid.UUID, _ uuid.UUID) (map[uuid.UUID]time.Time, error) {
	return make(map[uuid.UUID]time.Time, len(storyIDs)), nil
}

func (r *feedPostRepositoryStub) ListCommunities(_ context.Context, filter model.CommunityListFilter) ([]*model.Community, error) {
	if r.communityListFilters != nil {
		r.communityListFilters = append(r.communityListFilters, filter)
	}
	items := make([]*model.Community, 0, len(r.communities))
	for _, community := range r.communities {
		if community == nil {
			continue
		}
		if countryCode := strings.TrimSpace(filter.CountryCode); countryCode != "" {
			if community.CountryCode == nil || !strings.EqualFold(*community.CountryCode, countryCode) {
				continue
			}
		}
		if cityID := strings.TrimSpace(filter.CityID); cityID != "" {
			if community.CityID == nil || *community.CityID != cityID {
				continue
			}
		}
		if filter.ExcludeFollowedByUserID != nil && r.followedCommunityIDs[community.ID] {
			continue
		}
		items = append(items, community)
	}
	if filter.Offset >= len(items) {
		return []*model.Community{}, nil
	}
	end := filter.Offset + filter.Limit
	if filter.Limit <= 0 || end > len(items) {
		end = len(items)
	}
	return items[filter.Offset:end], nil
}

func (r *feedPostRepositoryStub) GetCommunityByID(_ context.Context, communityID uuid.UUID) (*model.Community, error) {
	for _, community := range r.communities {
		if community != nil && community.ID == communityID {
			return community, nil
		}
	}
	return nil, nil
}

func (r *feedPostRepositoryStub) UpdateCommunity(_ context.Context, community *model.Community) error {
	for index, item := range r.communities {
		if item != nil && community != nil && item.ID == community.ID {
			r.communities[index] = community
			return nil
		}
	}
	if community != nil {
		r.communities = append(r.communities, community)
	}
	return nil
}

func (r *feedPostRepositoryStub) GetCommunityMembership(_ context.Context, communityID uuid.UUID, userID uuid.UUID) (*model.CommunityMembership, error) {
	if r.memberships == nil {
		return nil, nil
	}
	return r.memberships[communityIDAndUserKey(communityID, userID)], nil
}

func (r *feedPostRepositoryStub) FollowCommunity(_ context.Context, communityID uuid.UUID, userID uuid.UUID) (bool, int, error) {
	if r.followedCommunityIDs == nil {
		r.followedCommunityIDs = make(map[uuid.UUID]bool)
	}
	changed := !r.followedCommunityIDs[communityID]
	r.followedCommunityIDs[communityID] = true
	if r.memberships == nil {
		r.memberships = make(map[uuid.UUID]*model.CommunityMembership)
	}
	r.memberships[communityIDAndUserKey(communityID, userID)] = &model.CommunityMembership{
		CommunityID: communityID,
		UserID:      userID,
		Role:        enum.CommunityMembershipRoleMember,
		Status:      enum.CommunityMembershipStatusActive,
	}
	return changed, len(r.followedCommunityIDs), nil
}

func (r *feedPostRepositoryStub) UnfollowCommunity(_ context.Context, communityID uuid.UUID, userID uuid.UUID) (bool, int, error) {
	changed := r.followedCommunityIDs != nil && r.followedCommunityIDs[communityID]
	if r.followedCommunityIDs != nil {
		delete(r.followedCommunityIDs, communityID)
	}
	if r.memberships != nil {
		delete(r.memberships, communityIDAndUserKey(communityID, userID))
	}
	return changed, len(r.followedCommunityIDs), nil
}

func (r *feedPostRepositoryStub) ListFollowedCommunityIDs(_ context.Context, _ uuid.UUID, communityIDs []uuid.UUID) (map[uuid.UUID]bool, error) {
	result := make(map[uuid.UUID]bool, len(communityIDs))
	for _, communityID := range communityIDs {
		result[communityID] = r.followedCommunityIDs[communityID]
	}
	return result, nil
}

func (r *feedPostRepositoryStub) ListUserCommunityIDs(_ context.Context, _ uuid.UUID, limit int, offset int) ([]uuid.UUID, error) {
	if offset >= len(r.userCommunityIDs) {
		return []uuid.UUID{}, nil
	}
	end := offset + limit
	if limit <= 0 || end > len(r.userCommunityIDs) {
		end = len(r.userCommunityIDs)
	}
	return r.userCommunityIDs[offset:end], nil
}

func (r *feedPostRepositoryStub) CreateFeedEvents(_ context.Context, events []model.FeedEvent) error {
	r.trackedFeedEvents = append(r.trackedFeedEvents, events...)
	return nil
}

func (r *feedPostRepositoryStub) TrackPostView(_ context.Context, postID uuid.UUID, viewerUserID uuid.UUID) (bool, int, error) {
	r.trackedPostViews = append(r.trackedPostViews, feedTrackedPostView{
		postID:       postID,
		viewerUserID: viewerUserID,
	})
	return true, len(r.trackedPostViews), nil
}

func (r *feedPostRepositoryStub) ListFeedUserInterests(_ context.Context, filter model.FeedUserInterestListFilter) ([]model.FeedUserInterest, error) {
	if r.listFeedUserInterestFilters != nil {
		r.listFeedUserInterestFilters = append(r.listFeedUserInterestFilters, filter)
	}
	return append([]model.FeedUserInterest(nil), r.feedUserInterests...), nil
}

func (r *feedPostRepositoryStub) ListFeedQualityMetrics(_ context.Context, filter model.FeedQualityMetricsFilter) ([]model.FeedQualityMetric, error) {
	if r.listFeedQualityMetricFilters != nil {
		r.listFeedQualityMetricFilters = append(r.listFeedQualityMetricFilters, filter)
	}
	return append([]model.FeedQualityMetric(nil), r.feedQualityMetrics...), nil
}

func (r *feedPostRepositoryStub) ListFeedSocialEdges(
	_ context.Context,
	_ uuid.UUID,
	targetUserIDs []uuid.UUID,
) (map[uuid.UUID]model.FeedSocialEdgeSet, error) {
	result := make(map[uuid.UUID]model.FeedSocialEdgeSet, len(targetUserIDs))
	for _, targetUserID := range targetUserIDs {
		if r.feedSocialEdges == nil {
			continue
		}
		if set := r.feedSocialEdges[targetUserID]; set.Friend || set.Following {
			result[targetUserID] = set
		}
	}
	return result, nil
}

func (r *feedPostRepositoryStub) UpsertFeedSocialEdge(_ context.Context, edge model.FeedSocialEdge) (bool, error) {
	if r.feedSocialEdges == nil {
		r.feedSocialEdges = make(map[uuid.UUID]model.FeedSocialEdgeSet)
	}
	current := r.feedSocialEdges[edge.TargetUserID]
	switch edge.EdgeType {
	case model.FeedSocialEdgeTypeFriend:
		if current.Friend {
			return false, nil
		}
		current.Friend = true
	case model.FeedSocialEdgeTypeFollowing:
		if current.Following {
			return false, nil
		}
		current.Following = true
	}
	r.feedSocialEdges[edge.TargetUserID] = current
	r.upsertedSocialEdges = append(r.upsertedSocialEdges, edge)
	return true, nil
}

func (r *feedPostRepositoryStub) DeleteFeedSocialEdge(
	_ context.Context,
	viewerUserID uuid.UUID,
	targetUserID uuid.UUID,
	edgeType string,
	sourceUpdatedAt time.Time,
) (bool, error) {
	if r.feedSocialEdges != nil {
		current := r.feedSocialEdges[targetUserID]
		switch edgeType {
		case model.FeedSocialEdgeTypeFriend:
			if !current.Friend {
				return false, nil
			}
			current.Friend = false
		case model.FeedSocialEdgeTypeFollowing:
			if !current.Following {
				return false, nil
			}
			current.Following = false
		}
		r.feedSocialEdges[targetUserID] = current
	}
	r.deletedSocialEdges = append(r.deletedSocialEdges, feedDeletedSocialEdge{
		viewerUserID:    viewerUserID,
		targetUserID:    targetUserID,
		edgeType:        edgeType,
		sourceUpdatedAt: sourceUpdatedAt,
	})
	return true, nil
}

type postFeedCacheFake struct {
	version        int64
	versionByScope map[string]int64
	gets           int
	sets           int
	bumps          int
	versionReads   int
	bumpedScopes   []string
	posts          map[string][]*model.Post
}

func (c *postFeedCacheFake) GetPosts(_ context.Context, key string) ([]*model.Post, bool, error) {
	c.gets++
	posts, ok := c.posts[key]
	if !ok {
		return nil, false, nil
	}
	return append([]*model.Post(nil), posts...), true, nil
}

func (c *postFeedCacheFake) SetPosts(_ context.Context, key string, posts []*model.Post, _ time.Duration) error {
	c.sets++
	c.posts[key] = append([]*model.Post(nil), posts...)
	return nil
}

func (c *postFeedCacheFake) CurrentVersion(_ context.Context, scope string) (int64, error) {
	c.versionReads++
	if c.versionByScope != nil {
		return c.versionByScope[scope], nil
	}
	return c.version, nil
}

func (c *postFeedCacheFake) BumpVersion(_ context.Context, scopes ...string) error {
	c.bumps++
	c.bumpedScopes = append(c.bumpedScopes, scopes...)
	c.version++
	if c.versionByScope != nil {
		for _, scope := range scopes {
			c.versionByScope[scope]++
		}
	}
	return nil
}

func newFeedTestPost(authorID uuid.UUID, slug string, publishedAt time.Time) *model.Post {
	return &model.Post{
		ID:               uuid.New(),
		Slug:             slug,
		AuthorUserID:     authorID,
		Title:            slug,
		Excerpt:          "Short guide",
		Category:         enum.PostCategoryGuide,
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusNotRequired,
		CreatedAt:        publishedAt,
		UpdatedAt:        publishedAt,
		PublishedAt:      &publishedAt,
	}
}

func newFeedTestExpiringPost(authorID uuid.UUID, slug string, publishedAt time.Time) *model.Post {
	post := newFeedTestPost(authorID, slug, publishedAt)
	expiresAt := publishedAt.Add(24 * time.Hour)
	post.ExpiresAt = &expiresAt
	return post
}

func feedTestPostRankedAt(post *model.Post) time.Time {
	if post == nil {
		return time.Time{}
	}
	if post.FeedRankedAt != nil && !post.FeedRankedAt.IsZero() {
		return post.FeedRankedAt.UTC()
	}
	if post.PublishedAt != nil && !post.PublishedAt.IsZero() {
		return post.PublishedAt.UTC()
	}
	return post.CreatedAt.UTC()
}

func newFeedTestStory(authorID uuid.UUID, caption string, createdAt time.Time) *model.Story {
	return &model.Story{
		ID:           uuid.New(),
		AuthorUserID: authorID,
		Caption:      caption,
		MediaFileID:  uuid.New(),
		CoverFileID:  uuid.New(),
		MediaType:    enum.PostMediaTypeImage,
		ExpiresAt:    createdAt.Add(24 * time.Hour),
		CreatedAt:    createdAt,
		UpdatedAt:    createdAt,
	}
}

func ptrTime(value time.Time) *time.Time {
	return &value
}

func stringPtr(value string) *string {
	return &value
}

func uuidPtr(value uuid.UUID) *uuid.UUID {
	return &value
}

func containsUUID(items []uuid.UUID, target uuid.UUID) bool {
	for _, item := range items {
		if item == target {
			return true
		}
	}
	return false
}

func uuidSlicesEqual(left []uuid.UUID, right []uuid.UUID) bool {
	if len(left) != len(right) {
		return false
	}
	for index := range left {
		if left[index] != right[index] {
			return false
		}
	}
	return true
}

func containsString(items []string, target string) bool {
	for _, item := range items {
		if item == target {
			return true
		}
	}
	return false
}

func postCardFeedData(items []FeedBlock) []PostCardFeedData {
	result := make([]PostCardFeedData, 0, len(items))
	for _, item := range items {
		data, ok := item.Data.(PostCardFeedData)
		if !ok || data.Post == nil || data.Post.Post == nil {
			continue
		}
		result = append(result, data)
	}
	return result
}

func postIDsFromPostCards(items []PostCardFeedData) []uuid.UUID {
	result := make([]uuid.UUID, 0, len(items))
	for _, item := range items {
		if item.Post == nil || item.Post.Post == nil {
			continue
		}
		result = append(result, item.Post.Post.ID)
	}
	return result
}

func postIDsFromPostViews(items []*PostView) []uuid.UUID {
	result := make([]uuid.UUID, 0, len(items))
	for _, item := range items {
		if item == nil || item.Post == nil {
			continue
		}
		result = append(result, item.Post.ID)
	}
	return result
}

func sameUUIDsInOrder(left []uuid.UUID, right []uuid.UUID) bool {
	if len(left) != len(right) {
		return false
	}
	for index := range left {
		if left[index] != right[index] {
			return false
		}
	}
	return true
}

func conversionFeedBlocks(items []FeedBlock) []FeedBlock {
	result := make([]FeedBlock, 0, len(items))
	for _, item := range items {
		switch item.Type {
		case model.FeedBlockTypeOfficialNewsCard, model.FeedBlockTypeProfileCard:
			result = append(result, item)
		}
	}
	return result
}

func communityIDAndUserKey(communityID uuid.UUID, userID uuid.UUID) uuid.UUID {
	return uuid.NewSHA1(uuid.NameSpaceOID, []byte(communityID.String()+":"+userID.String()))
}
