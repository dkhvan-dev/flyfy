package grpc

import (
	"errors"

	"github.com/dkhvan-dev/flyfy/backend/services/trust-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/trust-service/internal/domain/port"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func mapError(err error) error {
	switch {
	case err == nil:
		return nil
	case errors.Is(err, app.ErrInvalidInput):
		return status.Error(codes.InvalidArgument, err.Error())
	case errors.Is(err, port.ErrNotFound):
		return status.Error(codes.NotFound, "not found")
	default:
		return status.Error(codes.Internal, "internal server error")
	}
}
