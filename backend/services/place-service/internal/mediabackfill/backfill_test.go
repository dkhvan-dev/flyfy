package mediabackfill

import (
	"bytes"
	"context"
	"errors"
	"io"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
)

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(r *http.Request) (*http.Response, error) {
	return f(r)
}

func TestRunRejectsWikimediaCommonsImport(t *testing.T) {
	_, err := Run(context.Background(), nil, Config{
		CommonsMinMediaPerPlace: 1,
	})
	if !errors.Is(err, ErrCommonsImportDisabled) {
		t.Fatalf("Run() error = %v, want ErrCommonsImportDisabled", err)
	}
}

func TestDownloadImageRetriesRateLimitedResponses(t *testing.T) {
	attempts := 0
	client := &http.Client{Transport: roundTripFunc(func(r *http.Request) (*http.Response, error) {
		attempts++
		if attempts == 1 {
			return &http.Response{
				StatusCode: http.StatusTooManyRequests,
				Header:     http.Header{"Retry-After": []string{"0"}},
				Body:       io.NopCloser(strings.NewReader("rate limited")),
			}, nil
		}

		return &http.Response{
			StatusCode: http.StatusOK,
			Header:     http.Header{"Content-Type": []string{"image/jpeg"}},
			Body:       io.NopCloser(bytes.NewReader([]byte{0xff, 0xd8, 0xff, 0xd9})),
		}, nil
	})}

	body, contentType, originalName, err := downloadImage(
		context.Background(),
		client,
		mediaRow{
			MediaID:     uuid.New(),
			Title:       "Retry image",
			ExternalURL: "https://example.com/image.jpg",
			SourceURL:   "https://commons.wikimedia.org/wiki/File:Retry_image.jpg",
		},
		defaultUserAgent,
	)
	if err != nil {
		t.Fatalf("downloadImage() error = %v", err)
	}

	if attempts != 2 {
		t.Fatalf("attempts = %d, want 2", attempts)
	}
	if len(body) == 0 {
		t.Fatal("body is empty")
	}
	if contentType != "image/jpeg" {
		t.Fatalf("contentType = %q, want image/jpeg", contentType)
	}
	if originalName == "" {
		t.Fatal("originalName is empty")
	}
}

func TestDownloadImageStopsRetryDelayWhenContextIsCanceled(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	client := &http.Client{Transport: roundTripFunc(func(r *http.Request) (*http.Response, error) {
		cancel()
		return &http.Response{
			StatusCode: http.StatusTooManyRequests,
			Header:     http.Header{"Retry-After": []string{"0"}},
			Body:       io.NopCloser(strings.NewReader("rate limited")),
		}, nil
	})}

	startedAt := time.Now()
	_, _, _, err := downloadImage(
		ctx,
		client,
		mediaRow{
			MediaID:     uuid.New(),
			Title:       "Canceled retry image",
			ExternalURL: "https://example.com/image.jpg",
			SourceURL:   "https://commons.wikimedia.org/wiki/File:Canceled_retry_image.jpg",
		},
		defaultUserAgent,
	)
	if !errors.Is(err, context.Canceled) {
		t.Fatalf("downloadImage() error = %v, want context.Canceled", err)
	}
	if elapsed := time.Since(startedAt); elapsed > 500*time.Millisecond {
		t.Fatalf("downloadImage() waited %s after context cancellation", elapsed)
	}
}

func TestCommonsRetryDelayCapsRetryAfter(t *testing.T) {
	if got := commonsRetryDelay(1, time.Hour); got != maxCommonsRetryDelay {
		t.Fatalf("commonsRetryDelay() = %s, want %s", got, maxCommonsRetryDelay)
	}
}
