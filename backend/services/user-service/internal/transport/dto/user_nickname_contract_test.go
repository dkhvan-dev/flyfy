package dto

import (
	"encoding/json"
	"testing"
)

func TestUserProfileDTOUsesNicknameJSONContract(t *testing.T) {
	nickname := "@nomad_aru"
	payload, err := json.Marshal(UserProfileResponse{
		UserID:   "user-1",
		Nickname: &nickname,
		Locale:   "ru",
		Timezone: "Asia/Almaty",
	})
	if err != nil {
		t.Fatalf("marshal profile response: %v", err)
	}

	var decoded map[string]any
	if err = json.Unmarshal(payload, &decoded); err != nil {
		t.Fatalf("unmarshal profile response: %v", err)
	}

	if decoded["nickname"] != nickname {
		t.Fatalf("nickname = %v, want %q", decoded["nickname"], nickname)
	}
	if _, ok := decoded["displayName"]; ok {
		t.Fatal("profile response must not expose displayName")
	}
}

func TestUpdateMyProfileDTOUsesNicknameJSONContract(t *testing.T) {
	body := []byte(`{"firstName":"Aruzhan","lastName":"T.","nickname":"@nomad_aru"}`)

	var req UpdateMyProfileRequest
	if err := json.Unmarshal(body, &req); err != nil {
		t.Fatalf("unmarshal update request: %v", err)
	}

	if req.Nickname == nil || *req.Nickname != "@nomad_aru" {
		t.Fatalf("nickname = %v, want @nomad_aru", req.Nickname)
	}
}
