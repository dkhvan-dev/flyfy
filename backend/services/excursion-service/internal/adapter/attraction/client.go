package attraction

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

	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/port"
	"github.com/google/uuid"
)

const recalculateRatingTimeout = 3 * time.Second

type Client struct {
	baseURL       string
	internalToken string
	httpClient    *http.Client
}

func NewClient(baseURL string, internalToken string) *Client {
	return &Client{
		baseURL:       strings.TrimRight(strings.TrimSpace(baseURL), "/"),
		internalToken: strings.TrimSpace(internalToken),
		httpClient:    &http.Client{Timeout: recalculateRatingTimeout},
	}
}

func (c *Client) ApplyAttractionRatingSnapshot(ctx context.Context, snapshot port.AttractionRatingSnapshot) error {
	if c == nil || c.baseURL == "" || snapshot.AttractionID == uuid.Nil {
		return nil
	}

	endpoint, err := url.JoinPath(c.baseURL, "internal/v1/attractions", snapshot.AttractionID.String(), "rating/sources")
	if err != nil {
		return fmt.Errorf("build attraction rating url: %w", err)
	}
	body, err := json.Marshal(struct {
		Source      string  `json:"source"`
		RatingAvg   float64 `json:"ratingAvg"`
		ReviewCount int     `json:"reviewCount"`
	}{
		Source:      snapshot.Source,
		RatingAvg:   snapshot.RatingAvg,
		ReviewCount: snapshot.ReviewCount,
	})
	if err != nil {
		return fmt.Errorf("marshal attraction rating snapshot: %w", err)
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("create attraction rating request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	if c.internalToken != "" {
		req.Header.Set("X-Internal-Service-Token", c.internalToken)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("recalculate attraction rating: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 200 && resp.StatusCode < 300 {
		return nil
	}
	respBody, _ := io.ReadAll(io.LimitReader(resp.Body, 512))
	return fmt.Errorf("apply attraction rating snapshot status %d: %s", resp.StatusCode, strings.TrimSpace(string(respBody)))
}
