package enum

import "strings"

type PostMediaStatus string

const (
	PostMediaStatusReady       PostMediaStatus = "READY"
	PostMediaStatusPendingBind PostMediaStatus = "PENDING_BIND"
	PostMediaStatusFailed      PostMediaStatus = "FAILED"
)

func (s PostMediaStatus) IsValid() bool {
	switch s {
	case PostMediaStatusReady, PostMediaStatusPendingBind, PostMediaStatusFailed:
		return true
	default:
		return false
	}
}

func NormalizePostMediaStatus(status PostMediaStatus) PostMediaStatus {
	normalized := PostMediaStatus(strings.ToUpper(strings.TrimSpace(string(status))))
	if normalized == "" {
		return PostMediaStatusReady
	}
	return normalized
}

type PostMediaType string

const (
	PostMediaTypeImage    PostMediaType = "IMAGE"
	PostMediaTypeVideo    PostMediaType = "VIDEO"
	PostMediaTypeAudio    PostMediaType = "AUDIO"
	PostMediaTypeDocument PostMediaType = "DOCUMENT"
)

func (t PostMediaType) IsValid() bool {
	switch t {
	case PostMediaTypeImage, PostMediaTypeVideo, PostMediaTypeAudio, PostMediaTypeDocument:
		return true
	default:
		return false
	}
}

type StoryMediaType = PostMediaType

const (
	StoryMediaTypeImage StoryMediaType = PostMediaTypeImage
	StoryMediaTypeVideo StoryMediaType = PostMediaTypeVideo
)

type PostMediaProcessingStatus string

const (
	PostMediaProcessingStatusPendingBind PostMediaProcessingStatus = "PENDING_BIND"
	PostMediaProcessingStatusBound       PostMediaProcessingStatus = "BOUND"
	PostMediaProcessingStatusBindFailed  PostMediaProcessingStatus = "BIND_FAILED"
)

func (s PostMediaProcessingStatus) IsValid() bool {
	switch s {
	case PostMediaProcessingStatusPendingBind,
		PostMediaProcessingStatusBound,
		PostMediaProcessingStatusBindFailed:
		return true
	default:
		return false
	}
}
