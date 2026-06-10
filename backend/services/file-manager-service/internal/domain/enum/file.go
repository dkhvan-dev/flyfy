package enum

type FileStatus string

const (
	FileStatusPendingUpload FileStatus = "PENDING_UPLOAD"
	FileStatusUploaded      FileStatus = "UPLOADED"
	FileStatusReady         FileStatus = "READY"
	FileStatusFailed        FileStatus = "FAILED"
	FileStatusDeleted       FileStatus = "DELETED"
)

func (s FileStatus) IsValid() bool {
	switch s {
	case FileStatusPendingUpload, FileStatusUploaded, FileStatusReady, FileStatusFailed, FileStatusDeleted:
		return true
	default:
		return false
	}
}

type FileVisibility string

const (
	FileVisibilityPrivate   FileVisibility = "PRIVATE"
	FileVisibilityProtected FileVisibility = "PROTECTED"
	FileVisibilityPublic    FileVisibility = "PUBLIC"
)

func (v FileVisibility) IsValid() bool {
	switch v {
	case FileVisibilityPrivate, FileVisibilityProtected, FileVisibilityPublic:
		return true
	default:
		return false
	}
}

type FilePurpose string

const (
	FilePurposeAvatar                FilePurpose = "AVATAR"
	FilePurposeGuideVerificationDoc  FilePurpose = "GUIDE_VERIFICATION_DOC"
	FilePurposeActivityMedia         FilePurpose = "ACTIVITY_MEDIA"
	FilePurposeStoryMedia            FilePurpose = "STORY_MEDIA"
	FilePurposeExcursionMedia        FilePurpose = "EXCURSION_MEDIA"
	FilePurposeAttractionMedia       FilePurpose = "ATTRACTION_MEDIA"
	FilePurposeAttractionReviewMedia FilePurpose = "ATTRACTION_REVIEW_MEDIA"
	FilePurposeChatAttachment        FilePurpose = "CHAT_ATTACHMENT"
	FilePurposeChatSticker           FilePurpose = "CHAT_STICKER"
	FilePurposeGenericDocument       FilePurpose = "GENERIC_DOCUMENT"
)

func (p FilePurpose) IsValid() bool {
	switch p {
	case FilePurposeAvatar,
		FilePurposeGuideVerificationDoc,
		FilePurposeActivityMedia,
		FilePurposeStoryMedia,
		FilePurposeExcursionMedia,
		FilePurposeAttractionMedia,
		FilePurposeAttractionReviewMedia,
		FilePurposeChatAttachment,
		FilePurposeChatSticker,
		FilePurposeGenericDocument:
		return true
	default:
		return false
	}
}

type OwnerType string

const (
	OwnerTypeUser                     OwnerType = "USER"
	OwnerTypeGuideProfile             OwnerType = "GUIDE_PROFILE"
	OwnerTypeGuideVerificationRequest OwnerType = "GUIDE_VERIFICATION_REQUEST"
	OwnerTypeActivity                 OwnerType = "ACTIVITY"
	OwnerTypeStory                    OwnerType = "STORY"
	OwnerTypeAttraction               OwnerType = "ATTRACTION"
	OwnerTypeExcursion                OwnerType = "EXCURSION"
	OwnerTypeOrganization             OwnerType = "ORGANIZATION"
)

func (o OwnerType) IsValid() bool {
	switch o {
	case OwnerTypeUser,
		OwnerTypeGuideProfile,
		OwnerTypeGuideVerificationRequest,
		OwnerTypeActivity,
		OwnerTypeStory,
		OwnerTypeAttraction,
		OwnerTypeExcursion,
		OwnerTypeOrganization:
		return true
	default:
		return false
	}
}
