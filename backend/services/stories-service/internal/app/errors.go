package app

import "errors"

var (
	ErrStoryNotFound              = errors.New("story not found")
	ErrStoryCommentNotFound       = errors.New("story comment not found")
	ErrStoryAccessDenied          = errors.New("you do not have access to this story")
	ErrStoryCommentAccessDenied   = errors.New("you do not have access to this comment")
	ErrInvalidStoryID             = errors.New("invalid story id")
	ErrInvalidStoryAuthorID       = errors.New("invalid story author id")
	ErrInvalidCommentID           = errors.New("invalid comment id")
	ErrInvalidStoryTitle          = errors.New("story title is required and must be 160 characters or fewer")
	ErrInvalidStoryContent        = errors.New("story content is required and must be 2500 characters or fewer")
	ErrInvalidStoryFormat         = errors.New("story format is invalid")
	ErrInvalidStoryCategory       = errors.New("story category is invalid")
	ErrInvalidStoryStatus         = errors.New("story status is invalid")
	ErrInvalidStoryTags           = errors.New("story tags are invalid")
	ErrInvalidStoryPlace          = errors.New("story place is invalid")
	ErrInvalidStoryCover          = errors.New("story cover is required for published stories")
	ErrStoryValidationFailed      = errors.New("story validation failed")
	ErrStoryRevisionConflict      = errors.New("story revision conflict")
	ErrInvalidCommentBody         = errors.New("comment body is required and must be 800 characters or fewer")
	ErrStoryCommentRateLimited    = errors.New("you can leave only one comment every 3 hours")
	ErrUnauthenticatedWriter      = errors.New("missing authenticated subject")
	ErrCannotLikeOwnStory         = errors.New("you cannot like your own story")
	ErrCannotCommentOwnDeleted    = errors.New("cannot comment on deleted story")
	ErrCannotViewOwnStoryAsViewer = errors.New("author views are not counted")
	ErrUserNotFound               = errors.New("user not found")
)

type StoryValidationError struct {
	Fields map[string]string
	causes []error
}

func NewStoryValidationError(fields map[string]string, causes ...error) *StoryValidationError {
	copiedFields := make(map[string]string, len(fields))
	for field, code := range fields {
		copiedFields[field] = code
	}
	return &StoryValidationError{Fields: copiedFields, causes: causes}
}

func (e *StoryValidationError) Error() string {
	return ErrStoryValidationFailed.Error()
}

func (e *StoryValidationError) Is(target error) bool {
	if target == ErrStoryValidationFailed {
		return true
	}
	for _, cause := range e.causes {
		if errors.Is(cause, target) {
			return true
		}
	}
	return false
}
