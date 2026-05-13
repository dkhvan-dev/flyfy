package app

import "errors"

var (
	ErrInvalidActorUserID      = errors.New("invalid actor user id")
	ErrInvalidTourID           = errors.New("invalid tour id")
	ErrTourNotFound            = errors.New("tour not found")
	ErrTourAccessDenied        = errors.New("tour access denied")
	ErrGuideNotAllowed         = errors.New("guide is not allowed to manage tours")
	ErrTourAttractionRequired  = errors.New("tour must be based on an attraction")
	ErrInvalidTourIncludedItem = errors.New("invalid tour included item")
	ErrTourOfferNotFound       = errors.New("tour offer not found")
	ErrTourOfferNotBookable    = errors.New("tour offer is not available for booking")

	ErrTourCoverFileNotFound   = errors.New("tour cover file not found")
	ErrTourCoverFileNotReady   = errors.New("tour cover file is not ready")
	ErrTourCoverFileNotAllowed = errors.New("tour cover file is not allowed")
)
