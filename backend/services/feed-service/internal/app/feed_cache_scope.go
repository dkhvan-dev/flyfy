package app

import (
	"fmt"
	"strings"

	"github.com/google/uuid"
)

func postFeedCacheViewerScope(viewerUserID uuid.UUID) string {
	if viewerUserID == uuid.Nil {
		return postFeedCacheGlobalScope
	}
	return "post-feed:user:" + viewerUserID.String()
}

func postFeedCacheFollowingScope(viewerUserID uuid.UUID) string {
	if viewerUserID == uuid.Nil {
		return postFeedCacheGlobalScope
	}
	return "post-feed:user:" + viewerUserID.String() + ":following"
}

func postFeedCacheDiscoveryScope(viewerUserID uuid.UUID) string {
	if viewerUserID == uuid.Nil {
		return postFeedCacheGlobalScope
	}
	return "post-feed:user:" + viewerUserID.String() + ":discovery"
}

func postFeedCacheAuthorScope(authorUserID uuid.UUID) string {
	if authorUserID == uuid.Nil {
		return postFeedCacheGlobalScope
	}
	return "post-feed:author:" + authorUserID.String()
}

func postFeedCacheCommunityScope(communityID uuid.UUID) string {
	if communityID == uuid.Nil {
		return postFeedCacheGlobalScope
	}
	return "post-feed:community:" + communityID.String()
}

func postFeedCacheCategoryScope(category string) string {
	normalized := strings.ToLower(strings.TrimSpace(category))
	if normalized == "" {
		return postFeedCacheGlobalScope
	}
	return "post-feed:category:" + normalized
}

func postFeedCacheVersionSegment(scope string, version int64) string {
	return fmt.Sprintf("%s:%d", strings.ReplaceAll(scope, ":", "_"), version)
}
