package http

import (
	"context"
	"errors"
	"strings"

	"github.com/google/uuid"
)

type ActorResolver interface {
	ResolveUserIDBySubject(ctx context.Context, subject string) (uuid.UUID, error)
	ResolveRolesBySubject(ctx context.Context, subject string) ([]string, error)
}

func resolveActorUserID(ctx context.Context, resolver ActorResolver) (uuid.UUID, error) {
	subject := strings.TrimSpace(SubjectFromContext(ctx))
	if subject == "" {
		return uuid.Nil, errors.New("resolveActorUserID::missing authenticated user")
	}

	return resolver.ResolveUserIDBySubject(ctx, subject)
}
