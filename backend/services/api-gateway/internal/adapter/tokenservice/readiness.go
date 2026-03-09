package tokenservice

import (
	"context"
	"fmt"
)

func (c *Client) Check(ctx context.Context) error {
	_, err := c.getOrAuthenticateServiceToken(ctx)
	if err != nil {
		return fmt.Errorf("token-service auth check failed: %w", err)
	}
	return nil
}
