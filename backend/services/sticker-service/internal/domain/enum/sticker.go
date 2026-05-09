package enum

type PackType string

const (
	PackTypeSystem     PackType = "SYSTEM"
	PackTypeUserCustom PackType = "USER_CUSTOM"
	PackTypeCreator    PackType = "CREATOR"
	PackTypePaid       PackType = "PAID"
)

func (v PackType) IsValid() bool {
	switch v {
	case PackTypeSystem, PackTypeUserCustom, PackTypeCreator, PackTypePaid:
		return true
	default:
		return false
	}
}

type PackVisibility string

const (
	PackVisibilityPublic   PackVisibility = "PUBLIC"
	PackVisibilityUnlisted PackVisibility = "UNLISTED"
	PackVisibilityPrivate  PackVisibility = "PRIVATE"
)

func (v PackVisibility) IsValid() bool {
	switch v {
	case PackVisibilityPublic, PackVisibilityUnlisted, PackVisibilityPrivate:
		return true
	default:
		return false
	}
}

type PackStatus string

const (
	PackStatusDraft    PackStatus = "DRAFT"
	PackStatusActive   PackStatus = "ACTIVE"
	PackStatusInReview PackStatus = "IN_REVIEW"
	PackStatusRejected PackStatus = "REJECTED"
	PackStatusBlocked  PackStatus = "BLOCKED"
	PackStatusDeleted  PackStatus = "DELETED"
)

func (v PackStatus) IsValid() bool {
	switch v {
	case PackStatusDraft,
		PackStatusActive,
		PackStatusInReview,
		PackStatusRejected,
		PackStatusBlocked,
		PackStatusDeleted:
		return true
	default:
		return false
	}
}

type StickerStatus string

const (
	StickerStatusActive   StickerStatus = "ACTIVE"
	StickerStatusInReview StickerStatus = "IN_REVIEW"
	StickerStatusRejected StickerStatus = "REJECTED"
	StickerStatusBlocked  StickerStatus = "BLOCKED"
	StickerStatusDeleted  StickerStatus = "DELETED"
)

func (v StickerStatus) IsValid() bool {
	switch v {
	case StickerStatusActive,
		StickerStatusInReview,
		StickerStatusRejected,
		StickerStatusBlocked,
		StickerStatusDeleted:
		return true
	default:
		return false
	}
}

type UploadSessionStatus string

const (
	UploadSessionStatusPending UploadSessionStatus = "PENDING_UPLOAD"
	UploadSessionStatusReady   UploadSessionStatus = "READY"
	UploadSessionStatusFailed  UploadSessionStatus = "FAILED"
	UploadSessionStatusExpired UploadSessionStatus = "EXPIRED"
)

func (v UploadSessionStatus) IsValid() bool {
	switch v {
	case UploadSessionStatusPending,
		UploadSessionStatusReady,
		UploadSessionStatusFailed,
		UploadSessionStatusExpired:
		return true
	default:
		return false
	}
}

type UserPackSource string

const (
	UserPackSourceDefault   UserPackSource = "DEFAULT"
	UserPackSourceInstalled UserPackSource = "INSTALLED"
	UserPackSourceCreated   UserPackSource = "CREATED"
	UserPackSourcePurchased UserPackSource = "PURCHASED"
)

func (v UserPackSource) IsValid() bool {
	switch v {
	case UserPackSourceDefault,
		UserPackSourceInstalled,
		UserPackSourceCreated,
		UserPackSourcePurchased:
		return true
	default:
		return false
	}
}
