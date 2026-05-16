package app

import "errors"

var (
	ErrInvalidActorUserID           = errors.New("invalid actor user id")
	ErrInvalidExcursionID           = errors.New("invalid excursion id")
	ErrExcursionNotFound            = errors.New("excursion not found")
	ErrExcursionAccessDenied        = errors.New("excursion access denied")
	ErrGuideNotAllowed              = errors.New("guide is not allowed to manage excursions")
	ErrExcursionAttractionRequired  = errors.New("excursion must be based on an attraction")
	ErrInvalidExcursionIncludedItem = errors.New("invalid excursion included item")
	ErrExcursionOfferNotFound       = errors.New("excursion offer not found")
	ErrExcursionOfferNotBookable    = errors.New("excursion offer is not available for booking")
	ErrExcursionTranslationFailed   = errors.New("failed to translate excursion content")

	ErrExcursionCoverFileNotFound   = errors.New("excursion cover file not found")
	ErrExcursionCoverFileNotReady   = errors.New("excursion cover file is not ready")
	ErrExcursionCoverFileNotAllowed = errors.New("excursion cover file is not allowed")
)
