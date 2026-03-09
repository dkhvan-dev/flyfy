package app

import "context"

type ReadinessChecker interface {
	Check(ctx context.Context) error
}
