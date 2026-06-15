package app

import (
	"context"
	"errors"
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
		AuthorUserID:     authorID,
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

func TestBuildFeedDoesNotAddDeprecatedContentConversionBlocks(t *testing.T) {
	authorID := uuid.New()
	now := time.Now().UTC()
	repo := &feedPostRepositoryStub{
		posts: []*model.Post{newFeedTestPost(authorID, "ranked", now)},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

	page, err := useCase.BuildFeed(context.Background(), authorID.String(), BuildFeedInput{
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
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

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
	if len(repo.batchPostLikesCalls) != 1 || len(repo.batchPostLikesCalls[0]) != 2 {
		t.Fatalf("batch post like calls = %#v, want one call with two post ids", repo.batchPostLikesCalls)
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
	persistentPost := newFeedTestPost(authorID, "travel-post", now)

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
		Surface: "content",
		Limit:   2,
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
	if len(repo.listFeedPostCalls) != 1 {
		t.Fatalf("ListFeedPosts calls = %d, want 1", len(repo.listFeedPostCalls))
	}
	filter := repo.listFeedPostCalls[0]
	if !filter.OnlyPublished || filter.Sort != "latest_desc" || filter.Limit != 3 {
		t.Fatalf("feed filter = %+v, want public latest read-model query with limit+1", filter)
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
	if len(repo.listFeedPostCalls) != 1 {
		t.Fatalf("ListFeedPosts calls = %d, want 1 with cache hit on second call", len(repo.listFeedPostCalls))
	}
	if cache.gets != 2 || cache.sets != 1 || cache.versionReads != 2 {
		t.Fatalf("cache gets/sets/versionReads = %d/%d/%d, want 2/1/2", cache.gets, cache.sets, cache.versionReads)
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
	if len(repo.listFeedPostCalls) != 2 {
		t.Fatalf("ListFeedPosts calls = %d, want one miss per viewer", len(repo.listFeedPostCalls))
	}
	if cache.gets != 3 || cache.sets != 2 {
		t.Fatalf("cache gets/sets = %d/%d, want 3/2", cache.gets, cache.sets)
	}
	if cache.versionReads != 6 {
		t.Fatalf("versionReads = %d, want global+following per request", cache.versionReads)
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
	if len(repo.listFeedPostCalls) != 1 {
		t.Fatalf("ListFeedPosts calls = %d, want 1", len(repo.listFeedPostCalls))
	}
	filter := repo.listFeedPostCalls[0]
	if filter.ViewerUserID == nil || *filter.ViewerUserID != viewerID {
		t.Fatalf("viewer filter = %v, want %s", filter.ViewerUserID, viewerID)
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
			Action:             "conversion",
			EventCount:         12,
			UniqueViewers:      9,
			ConversionCount:    7,
			HideCount:          1,
			NotInterestedCount: 2,
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
	if metric.Action != "conversion" || metric.ConversionCount != 7 || metric.UniqueViewers != 9 {
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
}

type feedTrackedPostView struct {
	postID       uuid.UUID
	viewerUserID uuid.UUID
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
		if filter.FeedCursorPublishedAt != nil && filter.FeedCursorPostID != nil {
			publishedAt := post.CreatedAt
			if post.PublishedAt != nil {
				publishedAt = *post.PublishedAt
			}
			if publishedAt.After(*filter.FeedCursorPublishedAt) {
				continue
			}
			if publishedAt.Equal(*filter.FeedCursorPublishedAt) && post.ID.String() >= filter.FeedCursorPostID.String() {
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

func containsUUID(items []uuid.UUID, target uuid.UUID) bool {
	for _, item := range items {
		if item == target {
			return true
		}
	}
	return false
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
