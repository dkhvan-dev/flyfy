package main

import (
	"context"
	"log/slog"
	"time"
)

func runSegmentRefreshLoop(ctx context.Context, interval time.Duration, refresh func(context.Context) (int, error)) {
	if interval <= 0 || refresh == nil {
		return
	}
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		count, err := refresh(ctx)
		if err != nil {
			slog.Warn("support segment refresh scan failed", "error", err)
		} else if count > 0 {
			slog.Info("support segment refresh scan completed", "updated", count)
		}
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
		}
	}
}
