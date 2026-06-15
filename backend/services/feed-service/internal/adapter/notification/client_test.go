package notification

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/port"
)

func TestSendPostLikeNotificationSendsContentPayload(t *testing.T) {
	postID := uuid.New()
	authorID := uuid.New()
	actorID := uuid.New()
	coverID := uuid.New()
	var received sendNotificationRequest

	client := New("http://notification-service.test", "internal-token", "feed-service", time.Second)
	client.httpClient = &http.Client{Transport: roundTripFunc(func(r *http.Request) (*http.Response, error) {
		if r.URL.Path != internalSendPath {
			t.Fatalf("path = %q, want %q", r.URL.Path, internalSendPath)
		}
		if r.Header.Get(internalTokenHeader) != "internal-token" {
			t.Fatalf("%s = %q", internalTokenHeader, r.Header.Get(internalTokenHeader))
		}
		if r.Header.Get(internalServiceNameHeader) != "feed-service" {
			t.Fatalf("%s = %q", internalServiceNameHeader, r.Header.Get(internalServiceNameHeader))
		}
		if err := json.NewDecoder(r.Body).Decode(&received); err != nil {
			t.Fatalf("decode request: %v", err)
		}
		return &http.Response{
			StatusCode: http.StatusAccepted,
			Header:     make(http.Header),
			Body:       io.NopCloser(strings.NewReader("{}")),
			Request:    r,
		}, nil
	})}

	err := client.SendPostLikeNotification(
		context.Background(),
		port.PostLikeNotificationInput{
			PostID:           postID,
			PostSlug:         "almaty-morning",
			PostTitle:        "Almaty morning",
			PostCoverFileID:  &coverID,
			PostAuthorUserID: authorID,
			ActorUserID:      actorID,
			ActorDisplayName: "devdone",
		},
	)
	if err != nil {
		t.Fatalf("SendPostLikeNotification returned error: %v", err)
	}

	if received.Category != "content" || received.Priority != "normal" {
		t.Fatalf("category/priority = %q/%q, want content/normal", received.Category, received.Priority)
	}
	if received.Title != defaultPostLikeTitle {
		t.Fatalf("title = %q, want %q", received.Title, defaultPostLikeTitle)
	}
	if received.Body != "devdone нравится ваша история" {
		t.Fatalf("body = %q", received.Body)
	}
	if received.DeepLink != "/posts/almaty-morning" {
		t.Fatalf("deepLink = %q", received.DeepLink)
	}
	if len(received.RecipientUserIDs) != 1 || received.RecipientUserIDs[0] != authorID.String() {
		t.Fatalf("recipients = %#v, want %s", received.RecipientUserIDs, authorID)
	}
	if received.Data["type"] != "post_like" ||
		received.Data["category"] != "content" ||
		received.Data["postId"] != postID.String() ||
		received.Data["actorUserId"] != actorID.String() ||
		received.Data["postPreviewFileId"] != coverID.String() {
		t.Fatalf("data = %#v", received.Data)
	}
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(req *http.Request) (*http.Response, error) {
	return f(req)
}
