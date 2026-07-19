package productrollout

import "errors"

var (
	ErrInvalidConfiguration = errors.New("product rollout: invalid configuration")
	ErrInvalidRequest       = errors.New("product rollout: invalid request")
)
