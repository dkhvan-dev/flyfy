package savedcapability

import "errors"

var (
	ErrInvalidConfiguration  = errors.New("invalid Saved capability configuration")
	ErrInvalidRequest        = errors.New("invalid Saved capability request")
	ErrDataInvariant         = errors.New("Saved capability data invariant violated")
	ErrRepositoryUnavailable = errors.New("Saved capability repository unavailable")
)
