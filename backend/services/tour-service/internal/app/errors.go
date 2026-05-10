package app

import "errors"

var (
	ErrInvalidActorUserID = errors.New("invalid actor user id")
	ErrInvalidTourID      = errors.New("invalid tour id")
	ErrTourNotFound       = errors.New("tour not found")
	ErrTourAccessDenied   = errors.New("tour access denied")
	ErrGuideNotAllowed    = errors.New("guide is not allowed to manage tours")

	ErrTourCoverFileNotFound   = errors.New("tour cover file not found")
	ErrTourCoverFileNotReady   = errors.New("tour cover file is not ready")
	ErrTourCoverFileNotAllowed = errors.New("tour cover file is not allowed")
)
