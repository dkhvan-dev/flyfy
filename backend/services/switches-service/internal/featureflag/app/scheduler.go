package app

import (
	"context"
	"time"
)

type Scheduler struct {
	interval time.Duration
	run      func(context.Context) error
}

func NewScheduler(interval time.Duration, run func(context.Context) error) *Scheduler {
	if interval <= 0 {
		interval = time.Minute
	}
	return &Scheduler{interval: interval, run: run}
}

func (s *Scheduler) Start(ctx context.Context) {
	_ = s.run(ctx)
	ticker := time.NewTicker(s.interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			_ = s.run(ctx)
		}
	}
}
