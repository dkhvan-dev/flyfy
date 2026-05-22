package app

import (
	"testing"

	"github.com/dkhvan-dev/flyfy/backend/services/reference-service/data"
	"github.com/dkhvan-dev/flyfy/backend/services/reference-service/internal/adapter/repository"
)

func TestReferenceUseCaseListsTimezones(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)
	timezones := uc.ListTimezones()

	if len(timezones) == 0 {
		t.Fatal("expected non-empty timezone reference list")
	}

	for _, timezone := range timezones {
		if timezone.ID == "Asia/Almaty" {
			if timezone.Name.En != "Almaty" {
				t.Fatalf("expected English timezone place label, got %q", timezone.Name.En)
			}
			if timezone.Name.Ru != "Алматы" {
				t.Fatalf("expected Russian timezone place label, got %q", timezone.Name.Ru)
			}
			if timezone.Name.Kk != "Алматы" {
				t.Fatalf("expected Kazakh timezone place label, got %q", timezone.Name.Kk)
			}
			if timezone.UTCOffset == "" {
				t.Fatal("expected UTC offset for Asia/Almaty")
			}
			return
		}
	}

	t.Fatal("expected Asia/Almaty in timezone reference list")
}
