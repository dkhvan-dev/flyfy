package main

import (
	"context"
	"sync/atomic"
	"testing"
	"time"
)

func TestRunSLAAlertLoopRunsImmediatelyAndOnInterval(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	done := make(chan struct{})
	var calls atomic.Int32

	go func() {
		runSLAAlertLoop(ctx, time.Millisecond, func(context.Context) (int, error) {
			if calls.Add(1) >= 2 {
				cancel()
			}
			return 0, nil
		})
		close(done)
	}()

	select {
	case <-done:
	case <-time.After(time.Second):
		t.Fatal("SLA alert loop did not stop after context cancellation")
	}
	if calls.Load() < 2 {
		t.Fatalf("notify calls = %d, want at least 2", calls.Load())
	}
}
