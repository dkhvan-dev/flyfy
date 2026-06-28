package main

import (
	"context"
	"log/slog"
	"time"
)

func runSLAAlertLoop(ctx context.Context, interval time.Duration, notify func(context.Context) (int, error)) {
	if interval <= 0 || notify == nil {
		return
	}
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		count, err := notify(ctx)
		if err != nil {
			slog.Warn("support SLA alert scan failed", "error", err)
		} else if count > 0 {
			slog.Info("support SLA alert scan completed", "notified", count)
		}
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
		}
	}
}
