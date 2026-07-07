package guiderating

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/google/uuid"
)

const applySnapshotsTimeout = 10 * time.Second

type Snapshot struct {
	GuideProfileID uuid.UUID
	RatingAvg      float64
	ReviewsCount   int
}

type Client struct {
	baseURL       string
	internalToken string
	httpClient    *http.Client
}

type Option func(*Client)

func WithHTTPClient(httpClient *http.Client) Option {
	return func(c *Client) {
		if httpClient != nil {
			c.httpClient = httpClient
		}
	}
}

func NewClient(baseURL string, internalToken string, options ...Option) *Client {
	client := &Client{
		baseURL:       strings.TrimRight(strings.TrimSpace(baseURL), "/"),
		internalToken: strings.TrimSpace(internalToken),
		httpClient:    &http.Client{Timeout: applySnapshotsTimeout},
	}
	for _, option := range options {
		option(client)
	}
	return client
}

func (c *Client) ApplySnapshots(ctx context.Context, snapshots []Snapshot) error {
	if c == nil || c.baseURL == "" || len(snapshots) == 0 {
		return nil
	}
	endpoint, err := url.JoinPath(c.baseURL, "internal/v1/guides/ratings/snapshots")
	if err != nil {
		return fmt.Errorf("build guide rating url: %w", err)
	}

	payload := struct {
		Items []struct {
			GuideProfileID string  `json:"guideProfileId"`
			RatingAvg      float64 `json:"ratingAvg"`
			ReviewsCount   int     `json:"reviewsCount"`
		} `json:"items"`
	}{Items: make([]struct {
		GuideProfileID string  `json:"guideProfileId"`
		RatingAvg      float64 `json:"ratingAvg"`
		ReviewsCount   int     `json:"reviewsCount"`
	}, 0, len(snapshots))}
	for _, item := range snapshots {
		if item.GuideProfileID == uuid.Nil {
			continue
		}
		payload.Items = append(payload.Items, struct {
			GuideProfileID string  `json:"guideProfileId"`
			RatingAvg      float64 `json:"ratingAvg"`
			ReviewsCount   int     `json:"reviewsCount"`
		}{
			GuideProfileID: item.GuideProfileID.String(),
			RatingAvg:      item.RatingAvg,
			ReviewsCount:   item.ReviewsCount,
		})
	}
	if len(payload.Items) == 0 {
		return nil
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("marshal guide rating snapshots: %w", err)
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("create guide rating request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	if c.internalToken != "" {
		req.Header.Set("X-Internal-Service-Token", c.internalToken)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("apply guide rating snapshots: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 200 && resp.StatusCode < 300 {
		return nil
	}
	respBody, _ := io.ReadAll(io.LimitReader(resp.Body, 512))
	return fmt.Errorf("apply guide rating snapshots status %d: %s", resp.StatusCode, strings.TrimSpace(string(respBody)))
}
