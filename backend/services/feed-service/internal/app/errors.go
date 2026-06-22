package app

import "errors"

var (
	ErrPostNotFound                 = errors.New("post not found")
	ErrStoryNotFound                = errors.New("story not found")
	ErrCommunityNotFound            = errors.New("community not found")
	ErrPostCommentNotFound          = errors.New("post comment not found")
	ErrPostAccessDenied             = errors.New("you do not have access to this post")
	ErrCommunityPostingDenied       = errors.New("you cannot publish to this community")
	ErrCommunityModerationDenied    = errors.New("you cannot moderate this community")
	ErrCommunityFollowDenied        = errors.New("you cannot follow this community")
	ErrCommunityInteractionDenied   = errors.New("you cannot interact with this community")
	ErrCommunityRoleChangeDenied    = errors.New("you cannot change community member roles")
	ErrCommunityMemberManageDenied  = errors.New("you cannot manage community members")
	ErrCommunityMembershipNotFound  = errors.New("community membership not found")
	ErrPostCommentAccessDenied      = errors.New("you do not have access to this comment")
	ErrInvalidPostID                = errors.New("invalid post id")
	ErrInvalidCommunityID           = errors.New("invalid community id")
	ErrInvalidUserID                = errors.New("invalid user id")
	ErrInvalidCommunityMemberRole   = errors.New("invalid community member role")
	ErrInvalidCommunityMemberStatus = errors.New("invalid community member status")
	ErrInvalidModerationDecision    = errors.New("invalid moderation decision")
	ErrInvalidPostReportReason      = errors.New("invalid post report reason")
	ErrInvalidPostReportStatus      = errors.New("invalid post report status")
	ErrInvalidPostReportDetails     = errors.New("post report details must be 800 characters or fewer")
	ErrInvalidPostReportDecision    = errors.New("invalid post report decision")
	ErrInvalidPostReportResolution  = errors.New("post report resolution note must be 800 characters or fewer")
	ErrInvalidFeedCursor            = errors.New("invalid feed cursor")
	ErrInvalidFeedEvent             = errors.New("invalid feed event")
	ErrInvalidPostAuthorID          = errors.New("invalid post author id")
	ErrInvalidCommentID             = errors.New("invalid comment id")
	ErrInvalidPostTitle             = errors.New("post title is required and must be 160 characters or fewer")
	ErrInvalidPostContent           = errors.New("post content is required and must be 2500 characters or fewer")
	ErrInvalidPostFormat            = errors.New("post format is invalid")
	ErrInvalidPostCategory          = errors.New("post category is invalid")
	ErrInvalidPostStatus            = errors.New("post status is invalid")
	ErrInvalidPostTags              = errors.New("post tags are invalid")
	ErrInvalidPostPlace             = errors.New("post place is invalid")
	ErrInvalidPostCover             = errors.New("post cover is required for published posts")
	ErrInvalidPostMedia             = errors.New("post media is invalid")
	ErrInvalidPostRouteReference    = errors.New("post route reference is invalid")
	ErrPostValidationFailed         = errors.New("post validation failed")
	ErrPostRevisionConflict         = errors.New("post revision conflict")
	ErrInvalidCommentBody           = errors.New("comment body is required and must be 800 characters or fewer")
	ErrPostRateLimited              = errors.New("you can create only 10 posts per hour")
	ErrPostCommentRateLimited       = errors.New("you can leave only one comment every 3 hours")
	ErrUnauthenticatedWriter        = errors.New("missing authenticated subject")
	ErrCannotLikeOwnPost            = errors.New("you cannot like your own post")
	ErrCannotLikeOwnStory           = errors.New("you cannot like your own story")
	ErrCannotCommentOwnDeleted      = errors.New("cannot comment on deleted post")
	ErrCannotViewOwnPostAsViewer    = errors.New("author views are not counted")
	ErrPostReportOwnContent         = errors.New("you cannot report your own post")
	ErrPostReportNotFound           = errors.New("post report not found")
	ErrPostReportAlreadyResolved    = errors.New("post report already resolved")
	ErrUserNotFound                 = errors.New("user not found")
)

type PostValidationError struct {
	Fields map[string]string
	causes []error
}

func NewPostValidationError(fields map[string]string, causes ...error) *PostValidationError {
	copiedFields := make(map[string]string, len(fields))
	for field, code := range fields {
		copiedFields[field] = code
	}
	return &PostValidationError{Fields: copiedFields, causes: causes}
}

func (e *PostValidationError) Error() string {
	return ErrPostValidationFailed.Error()
}

func (e *PostValidationError) Is(target error) bool {
	if target == ErrPostValidationFailed {
		return true
	}
	for _, cause := range e.causes {
		if errors.Is(cause, target) {
			return true
		}
	}
	return false
}
