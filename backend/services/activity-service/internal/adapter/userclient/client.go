package userclient

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"time"
)

type Client struct {
	baseURL    string
	httpClient *http.Client
}

func New(baseURL string) *Client {
	return &Client{
		baseURL: strings.TrimRight(baseURL, "/"),
		httpClient: &http.Client{
			Timeout: 5 * time.Second,
		},
	}
}

type FindUserBySubjectResponse struct {
	User *struct {
		ID            string `json:"id"`
		AuthSubjectID string `json:"authSubjectId"`
	} `json:"user"`
}

func (c *Client) ResolveUserIDBySubject(ctx context.Context, subject string) (string, error) {
	if strings.TrimSpace(subject) == "" {
		return "", fmt.Errorf("subject is empty")
	}

	u := c.baseURL + "/internal/v1/users/by-subject?subject=" + url.QueryEscape(subject)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, u, nil)
	if err != nil {
		return "", err
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusNotFound {
		return "", fmt.Errorf("user not found by subject")
	}
	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("user-service returned status %d", resp.StatusCode)
	}

	var result FindUserBySubjectResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", err
	}

	if result.User == nil || strings.TrimSpace(result.User.ID) == "" {
		return "", fmt.Errorf("user id is empty in user-service response")
	}

	return result.User.ID, nil
}
