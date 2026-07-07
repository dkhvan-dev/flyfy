package searchindex

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"kz/inflap/backend/pkg/serviceauth"
	"kz/inflap/backend/services/user-service/internal/app"
)

const (
	sourceService           = "user-service"
	documentEventTypeUpsert = "search_document_upsert"
	documentEventTypeDelete = "search_document_delete"
)

type Client struct {
	baseURL       string
	internalToken string
	httpClient    *http.Client
}

type Option func(*Client)

func WithServiceTokenSource(source serviceauth.TokenSource) Option {
	return func(c *Client) {
		if source != nil {
			c.httpClient.Transport = serviceauth.NewBearerTransport(source, c.httpClient.Transport)
		}
	}
}

func WithHTTPClient(httpClient *http.Client) Option {
	return func(c *Client) {
		if httpClient != nil {
			c.httpClient = httpClient
		}
	}
}

func New(baseURL string, internalToken string, timeout time.Duration, opts ...Option) *Client {
	if timeout <= 0 {
		timeout = 2 * time.Second
	}
	client := &Client{
		baseURL:       strings.TrimRight(strings.TrimSpace(baseURL), "/"),
		internalToken: strings.TrimSpace(internalToken),
		httpClient:    &http.Client{Timeout: timeout},
	}
	for _, opt := range opts {
		opt(client)
	}
	return client
}

func (c *Client) UpsertSearchDocument(ctx context.Context, document app.SearchIndexDocument) error {
	payload, err := json.Marshal(indexDocumentRequest{
		Domain:               document.Domain,
		EntityID:             document.EntityID,
		EntityVersion:        document.EntityVersion,
		Locale:               document.Locale,
		Title:                document.Title,
		Subtitle:             document.Subtitle,
		Description:          document.Description,
		Tags:                 document.Tags,
		CategoryCodes:        document.CategoryCodes,
		CityID:               document.CityID,
		CountryCode:          document.CountryCode,
		Latitude:             document.Latitude,
		Longitude:            document.Longitude,
		PriceMin:             document.PriceMin,
		PriceMax:             document.PriceMax,
		Currency:             document.Currency,
		Rating:               document.Rating,
		ReviewCount:          document.ReviewCount,
		PopularityScore:      document.PopularityScore,
		FreshnessScore:       document.FreshnessScore,
		TrustScore:           document.TrustScore,
		AvailabilityStatus:   document.AvailabilityStatus,
		Visibility:           document.Visibility,
		ModerationStatus:     document.ModerationStatus,
		DeepLink:             document.DeepLink,
		SearchText:           document.SearchText,
		SearchTextNormalized: document.SearchTextNormalized,
		SearchVariants:       document.SearchVariants,
	})
	if err != nil {
		return fmt.Errorf("encode search document payload: %w", err)
	}

	return c.publishIndexEvent(ctx, indexEventRequest{
		SourceService: sourceService,
		SourceEventID: sourceEventID(
			documentEventTypeUpsert,
			document.Domain,
			document.EntityID,
			document.Locale,
			fmt.Sprint(document.EntityVersion),
		),
		AggregateType: document.Domain,
		AggregateID:   document.EntityID,
		EventType:     documentEventTypeUpsert,
		Payload:       payload,
	})
}

func (c *Client) DeleteSearchDocument(ctx context.Context, deletion app.SearchIndexDelete) error {
	payload, err := json.Marshal(deleteDocumentRequest{
		Domain:   deletion.Domain,
		EntityID: deletion.EntityID,
		Locale:   deletion.Locale,
	})
	if err != nil {
		return fmt.Errorf("encode search document delete payload: %w", err)
	}

	return c.publishIndexEvent(ctx, indexEventRequest{
		SourceService: sourceService,
		SourceEventID: sourceEventID(
			documentEventTypeDelete,
			deletion.Domain,
			deletion.EntityID,
			deletion.Locale,
		),
		AggregateType: deletion.Domain,
		AggregateID:   deletion.EntityID,
		EventType:     documentEventTypeDelete,
		Payload:       payload,
	})
}

func (c *Client) publishIndexEvent(ctx context.Context, event indexEventRequest) error {
	body, err := json.Marshal(event)
	if err != nil {
		return fmt.Errorf("encode search index event: %w", err)
	}

	req, err := http.NewRequestWithContext(
		ctx,
		http.MethodPost,
		c.baseURL+"/v1/search/index/events",
		bytes.NewReader(body),
	)
	if err != nil {
		return fmt.Errorf("create search index event request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	c.authorize(req)

	return c.do(req)
}

func (c *Client) authorize(req *http.Request) {
	if c.internalToken != "" {
		req.Header.Set("X-Internal-Service-Token", c.internalToken)
	}
}

func (c *Client) do(req *http.Request) error {
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("call search-service: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 200 && resp.StatusCode < 300 {
		io.Copy(io.Discard, resp.Body)
		return nil
	}

	body, _ := io.ReadAll(io.LimitReader(resp.Body, 2048))
	return fmt.Errorf("search-service returned %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
}

func sourceEventID(eventType string, parts ...string) string {
	hasher := sha256.New()
	_, _ = hasher.Write([]byte(sourceService))
	_, _ = hasher.Write([]byte{0})
	_, _ = hasher.Write([]byte(eventType))
	for _, part := range parts {
		_, _ = hasher.Write([]byte{0})
		_, _ = hasher.Write([]byte(strings.TrimSpace(part)))
	}
	return eventType + ":" + hex.EncodeToString(hasher.Sum(nil))
}

type indexEventRequest struct {
	SourceService string          `json:"sourceService"`
	SourceEventID string          `json:"sourceEventId"`
	AggregateType string          `json:"aggregateType"`
	AggregateID   string          `json:"aggregateId"`
	EventType     string          `json:"eventType"`
	Payload       json.RawMessage `json:"payload"`
}

type indexDocumentRequest struct {
	Domain               string            `json:"domain"`
	EntityID             string            `json:"entityId"`
	EntityVersion        int64             `json:"entityVersion,omitempty"`
	Locale               string            `json:"locale,omitempty"`
	Title                map[string]string `json:"title,omitempty"`
	Subtitle             map[string]string `json:"subtitle,omitempty"`
	Description          map[string]string `json:"description,omitempty"`
	Tags                 []string          `json:"tags,omitempty"`
	CategoryCodes        []string          `json:"categoryCodes,omitempty"`
	CityID               string            `json:"cityId,omitempty"`
	CountryCode          string            `json:"countryCode,omitempty"`
	Latitude             *float64          `json:"latitude,omitempty"`
	Longitude            *float64          `json:"longitude,omitempty"`
	PriceMin             *float64          `json:"priceMin,omitempty"`
	PriceMax             *float64          `json:"priceMax,omitempty"`
	Currency             string            `json:"currency,omitempty"`
	Rating               *float64          `json:"rating,omitempty"`
	ReviewCount          int               `json:"reviewCount,omitempty"`
	PopularityScore      float64           `json:"popularityScore,omitempty"`
	FreshnessScore       float64           `json:"freshnessScore,omitempty"`
	TrustScore           float64           `json:"trustScore,omitempty"`
	AvailabilityStatus   string            `json:"availabilityStatus,omitempty"`
	Visibility           string            `json:"visibility,omitempty"`
	ModerationStatus     string            `json:"moderationStatus,omitempty"`
	DeepLink             string            `json:"deepLink"`
	SearchText           string            `json:"searchText,omitempty"`
	SearchTextNormalized string            `json:"searchTextNormalized,omitempty"`
	SearchVariants       []string          `json:"searchVariants,omitempty"`
}

type deleteDocumentRequest struct {
	Domain   string `json:"domain"`
	EntityID string `json:"entityId"`
	Locale   string `json:"locale,omitempty"`
}
