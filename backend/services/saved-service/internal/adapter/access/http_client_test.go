package access

import (
	"context"
	"errors"
	"io"
	"net/http"
	"strings"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/app/savedaccess"
)

type roundTripperFunc func(*http.Request) (*http.Response, error)

func (function roundTripperFunc) RoundTrip(request *http.Request) (*http.Response, error) {
	return function(request)
}

func TestClientChecksDeniedUsersWithStrictInternalContract(t *testing.T) {
	t.Parallel()

	ownerUserID := uuid.New()
	allowedUserID := uuid.New()
	deniedUserID := uuid.New()
	transport := roundTripperFunc(func(request *http.Request) (*http.Response, error) {
		if request.Method != http.MethodPost || request.URL.Path != savedUserAccessPath {
			t.Fatalf("request = %s %s", request.Method, request.URL.Path)
		}
		if request.Header.Get(internalServiceTokenHeader) != "internal-token-value" ||
			request.Header.Get(serviceNameHeader) != serviceName {
			t.Fatalf("internal headers = %v", request.Header)
		}
		body, _ := io.ReadAll(request.Body)
		if !strings.Contains(string(body), ownerUserID.String()) ||
			!strings.Contains(string(body), deniedUserID.String()) {
			t.Fatalf("request body = %s", body)
		}
		return &http.Response{
			StatusCode: http.StatusOK,
			Header:     http.Header{"Content-Type": []string{"application/json"}},
			Body: io.NopCloser(strings.NewReader(
				`{"deniedTargetUserIds":["` + deniedUserID.String() + `"]}`,
			)),
		}, nil
	})
	client, err := NewClient(ClientConfig{
		BaseURL:       "https://chat-service:9488",
		InternalToken: "internal-token-value",
		HTTPClient:    &http.Client{Transport: transport},
	})
	if err != nil {
		t.Fatalf("NewClient() error = %v", err)
	}

	denied, err := client.DeniedUserIDs(
		context.Background(),
		ownerUserID,
		[]uuid.UUID{allowedUserID, deniedUserID},
	)
	if err != nil {
		t.Fatalf("DeniedUserIDs() error = %v", err)
	}
	if len(denied) != 1 {
		t.Fatalf("denied = %v", denied)
	}
	if _, ok := denied[deniedUserID]; !ok {
		t.Fatalf("denied = %v", denied)
	}
}

func TestClientRejectsMalformedOrOverreachingResponses(t *testing.T) {
	t.Parallel()

	ownerUserID := uuid.New()
	targetUserID := uuid.New()
	unknownUserID := uuid.New()
	for _, responseBody := range []string{
		`{}`,
		`{"deniedTargetUserIds":null}`,
		`{"deniedTargetUserIds":["` + unknownUserID.String() + `"]}`,
		`{"deniedTargetUserIds":["` + targetUserID.String() + `","` + targetUserID.String() + `"]}`,
		`{"deniedTargetUserIds":[],"unexpected":true}`,
	} {
		responseBody := responseBody
		t.Run(responseBody, func(t *testing.T) {
			client, err := NewClient(ClientConfig{
				BaseURL:       "https://chat-service:9488",
				InternalToken: "internal-token-value",
				HTTPClient: &http.Client{Transport: roundTripperFunc(func(*http.Request) (*http.Response, error) {
					return &http.Response{
						StatusCode: http.StatusOK,
						Header:     http.Header{"Content-Type": []string{"application/json"}},
						Body:       io.NopCloser(strings.NewReader(responseBody)),
					}, nil
				})},
			})
			if err != nil {
				t.Fatalf("NewClient() error = %v", err)
			}
			_, err = client.DeniedUserIDs(context.Background(), ownerUserID, []uuid.UUID{targetUserID})
			if !errors.Is(err, savedaccess.ErrPolicyUnavailable) {
				t.Fatalf("DeniedUserIDs() error = %v", err)
			}
		})
	}
}
