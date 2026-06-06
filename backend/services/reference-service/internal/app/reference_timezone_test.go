package app

import (
	"testing"

	"kz/inflap/backend/services/reference-service/data"
	"kz/inflap/backend/services/reference-service/internal/adapter/repository"
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

func TestReferenceUseCaseListsVietnamTimezone(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)
	timezones := uc.ListTimezones()

	for _, timezone := range timezones {
		if timezone.ID != "Asia/Ho_Chi_Minh" {
			continue
		}
		if timezone.Name.En != "Vietnam, Ho Chi Minh City / Hanoi" {
			t.Fatalf("Vietnam timezone English label = %q", timezone.Name.En)
		}
		if timezone.Name.Ru != "Вьетнам, Хошимин / Ханой" {
			t.Fatalf("Vietnam timezone Russian label = %q", timezone.Name.Ru)
		}
		if timezone.UTCOffset != "+07:00" {
			t.Fatalf("Vietnam timezone UTC offset = %q, want +07:00", timezone.UTCOffset)
		}
		return
	}

	t.Fatal("expected Asia/Ho_Chi_Minh in timezone reference list")
}
