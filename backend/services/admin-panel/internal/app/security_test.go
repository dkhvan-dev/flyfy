package app

import "testing"

func TestHashPasswordAndVerifyPassword(t *testing.T) {
	t.Parallel()

	hash, err := HashPassword("AdminPanelTestPass123!")
	if err != nil {
		t.Fatalf("HashPassword returned error: %v", err)
	}
	if hash == "" {
		t.Fatal("HashPassword returned empty hash")
	}
	if !VerifyPassword(hash, "AdminPanelTestPass123!") {
		t.Fatal("VerifyPassword rejected the original password")
	}
	if VerifyPassword(hash, "AdminPanelWrongPass123!") {
		t.Fatal("VerifyPassword accepted a wrong password")
	}
}

func TestHashPasswordRejectsShortPassword(t *testing.T) {
	t.Parallel()

	if _, err := HashPassword("short"); err == nil {
		t.Fatal("HashPassword accepted a short password")
	}
}

func TestHashTokenNormalizesWhitespace(t *testing.T) {
	t.Parallel()

	if HashToken(" token ") != HashToken("token") {
		t.Fatal("HashToken should trim accidental surrounding whitespace")
	}
}

func TestGenerateOpaqueToken(t *testing.T) {
	t.Parallel()

	first, err := GenerateOpaqueToken()
	if err != nil {
		t.Fatalf("GenerateOpaqueToken returned error: %v", err)
	}
	second, err := GenerateOpaqueToken()
	if err != nil {
		t.Fatalf("GenerateOpaqueToken returned error on second call: %v", err)
	}
	if first == "" || second == "" {
		t.Fatal("GenerateOpaqueToken returned empty token")
	}
	if first == second {
		t.Fatal("GenerateOpaqueToken returned duplicate tokens")
	}
}
