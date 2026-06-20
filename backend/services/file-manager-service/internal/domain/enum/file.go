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
	FilePurposeAvatar               FilePurpose = "AVATAR"
	FilePurposeGuideVerificationDoc FilePurpose = "GUIDE_VERIFICATION_DOC"
	FilePurposeActivityMedia        FilePurpose = "ACTIVITY_MEDIA"
	FilePurposePostMedia            FilePurpose = "POST_MEDIA"
	FilePurposeStoryMedia           FilePurpose = "STORY_MEDIA"
	FilePurposeCommunityMedia       FilePurpose = "COMMUNITY_MEDIA"
	FilePurposeExcursionMedia       FilePurpose = "EXCURSION_MEDIA"
	FilePurposePlaceMedia           FilePurpose = "PLACE_MEDIA"
	FilePurposePlaceReviewMedia     FilePurpose = "PLACE_REVIEW_MEDIA"
	FilePurposeChatAttachment       FilePurpose = "CHAT_ATTACHMENT"
	FilePurposeChatSticker          FilePurpose = "CHAT_STICKER"
	FilePurposeGenericDocument      FilePurpose = "GENERIC_DOCUMENT"
)

func (p FilePurpose) IsValid() bool {
	switch p {
	case FilePurposeAvatar,
		FilePurposeGuideVerificationDoc,
		FilePurposeActivityMedia,
		FilePurposePostMedia,
		FilePurposeStoryMedia,
		FilePurposeCommunityMedia,
		FilePurposeExcursionMedia,
		FilePurposePlaceMedia,
		FilePurposePlaceReviewMedia,
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
	OwnerTypePost                     OwnerType = "POST"
	OwnerTypeStory                    OwnerType = "STORY"
	OwnerTypeCommunity                OwnerType = "COMMUNITY"
	OwnerTypePlace                    OwnerType = "PLACE"
	OwnerTypeExcursion                OwnerType = "EXCURSION"
	OwnerTypeOrganization             OwnerType = "ORGANIZATION"
)

func (o OwnerType) IsValid() bool {
	switch o {
	case OwnerTypeUser,
		OwnerTypeGuideProfile,
		OwnerTypeGuideVerificationRequest,
		OwnerTypeActivity,
		OwnerTypePost,
		OwnerTypeStory,
		OwnerTypeCommunity,
		OwnerTypePlace,
		OwnerTypeExcursion,
		OwnerTypeOrganization:
		return true
	default:
		return false
	}
}
