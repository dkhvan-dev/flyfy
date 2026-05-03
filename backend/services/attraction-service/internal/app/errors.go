package app

import "errors"

var (
	ErrAttractionNotFound     = errors.New("attraction not found")
	ErrReviewNotFound         = errors.New("review not found")
	ErrAccessDenied           = errors.New("you do not have access to this resource")
	ErrUnauthenticated        = errors.New("missing authenticated subject")
	ErrInvalidAttractionID    = errors.New("invalid attraction id")
	ErrInvalidReviewID        = errors.New("invalid review id")
	ErrInvalidTitle           = errors.New("title is required and must be 200 characters or fewer")
	ErrInvalidLocale          = errors.New("locale must be one of: en, ru, kk")
	ErrInvalidCategory        = errors.New("invalid attraction category")
	ErrInvalidStatus          = errors.New("invalid attraction status")
	ErrInvalidCountryCode     = errors.New("country code must be an ISO-2 reference country code")
	ErrInvalidCityID          = errors.New("city id must be a reference city id")
	ErrInvalidRating          = errors.New("rating must be between 1.0 and 5.0")
	ErrInvalidMediaType       = errors.New("media type must be PHOTO or VIDEO")
	ErrInvalidDuration        = errors.New("invalid duration: value and unit must both be set or both be empty")
	ErrInvalidPrice           = errors.New("invalid price: amount and currency must both be set or both be empty")
	ErrInvalidVisitInfo       = errors.New("invalid visit info")
	ErrReviewConflict         = errors.New("you have already reviewed this attraction")
	ErrCannotReviewOwn        = errors.New("you cannot review your own attraction")
	ErrAttractionDeleted      = errors.New("attraction is deleted")
	ErrAttractionNotPublished = errors.New("attraction is not published")
	ErrUserNotFound           = errors.New("user not found")
)
