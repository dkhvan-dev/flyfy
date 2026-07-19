package tokenservice

import (
	"testing"

	tokenpb "kz/inflap/proto/gen/go/token"
)

func TestTokenClaimsFromResponsePreservesSessionID(t *testing.T) {
	const sessionID = "c51500f3-f6c8-4d54-b9b8-ef6db7fc74aa"

	claims := tokenClaimsFromResponse(&tokenpb.ValidatedClaimsResponse{
		Subject:   "auth-subject-1",
		UserId:    "user-1",
		SessionId: sessionID,
		Roles:     []string{"USER"},
	})

	if claims.SessionID != sessionID {
		t.Fatalf("session ID = %q, want %q", claims.SessionID, sessionID)
	}
}
