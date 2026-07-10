package repository

import (
	"context"
	"fmt"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/translation-service/internal/domain/model"
)

func TestPGTranslationRepositoryReserveMonthlyUsageAllowsFirstReservation(t *testing.T) {
	dsn := strings.TrimSpace(os.Getenv("TRANSLATION_SERVICE_REPOSITORY_TEST_DSN"))
	if dsn == "" {
		t.Skip("TRANSLATION_SERVICE_REPOSITORY_TEST_DSN is not set")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatalf("connect postgres: %v", err)
	}
	defer pool.Close()

	repo := NewPGTranslationRepository(pool)
	environment := fmt.Sprintf("repository-test-%d", time.Now().UnixNano())
	t.Cleanup(func() {
		cleanupCtx, cleanupCancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cleanupCancel()
		_, _ = pool.Exec(cleanupCtx, "DELETE FROM translation_usage_monthly WHERE environment = $1", environment)
	})

	reservation := model.UsageReservation{
		Provider:               "azure_translator",
		Environment:            environment,
		YearMonth:              "2026-07",
		SourceLanguage:         model.LanguageRussian,
		TargetLanguage:         model.LanguageEnglish,
		ContentType:            model.ContentTypeExcursion,
		BillingMode:            model.BillingModeFreeOnly,
		Characters:             54,
		MonthlyLimit:           2_000_000,
		QuotaWarningThreshold:  0.80,
		QuotaCriticalThreshold: 0.95,
		ReservedAt:             time.Date(2026, 7, 10, 3, 33, 0, 0, time.UTC),
	}

	result, err := repo.ReserveMonthlyUsage(ctx, reservation)
	if err != nil {
		t.Fatalf("ReserveMonthlyUsage() error = %v", err)
	}
	if !result.Allowed {
		t.Fatalf("Allowed = false, want true for first reservation: %#v", result)
	}
	if result.ReservedCharacters != 54 || result.UsedCharacters != 54 || result.LimitCharacters != 2_000_000 {
		t.Fatalf("reservation result = %#v, want reserved/used/limit 54/54/2000000", result)
	}
	if result.WarningReached || result.CriticalReached {
		t.Fatalf("threshold flags = warning:%t critical:%t, want both false at 54/2000000", result.WarningReached, result.CriticalReached)
	}

	reservation.Characters = 2_000_000
	result, err = repo.ReserveMonthlyUsage(ctx, reservation)
	if err != nil {
		t.Fatalf("ReserveMonthlyUsage() second call error = %v", err)
	}
	if result.Allowed {
		t.Fatalf("Allowed = true, want false when reservation exceeds monthly limit: %#v", result)
	}
	if result.UsedCharacters != 54 || result.LimitCharacters != 2_000_000 {
		t.Fatalf("exhausted result = %#v, want current usage preserved at 54/2000000", result)
	}
}

func TestPGTranslationRepositoryReserveAndReleaseRecalculateStaleThresholdFlags(t *testing.T) {
	dsn := strings.TrimSpace(os.Getenv("TRANSLATION_SERVICE_REPOSITORY_TEST_DSN"))
	if dsn == "" {
		t.Skip("TRANSLATION_SERVICE_REPOSITORY_TEST_DSN is not set")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatalf("connect postgres: %v", err)
	}
	defer pool.Close()

	repo := NewPGTranslationRepository(pool)
	environment := fmt.Sprintf("repository-test-%d", time.Now().UnixNano())
	t.Cleanup(func() {
		cleanupCtx, cleanupCancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cleanupCancel()
		_, _ = pool.Exec(cleanupCtx, "DELETE FROM translation_usage_monthly WHERE environment = $1", environment)
	})

	_, err = pool.Exec(ctx, `
INSERT INTO translation_usage_monthly (
    provider,
    environment,
    year_month,
    source_language,
    target_language,
    content_type,
    billing_mode,
    reserved_characters,
    monthly_limit,
    warning_threshold,
    critical_threshold,
    warning_reached,
    critical_reached
) VALUES ($1, $2, $3, $4, $5, $6, $7, 0, $8, $9, $10, true, true)
`,
		"azure_translator",
		environment,
		"2026-07",
		string(model.LanguageRussian),
		string(model.LanguageKazakh),
		string(model.ContentTypeExcursion),
		string(model.BillingModeFreeOnly),
		2_000_000,
		0.80,
		0.95,
	)
	if err != nil {
		t.Fatalf("seed stale usage row: %v", err)
	}

	reservation := model.UsageReservation{
		Provider:               "azure_translator",
		Environment:            environment,
		YearMonth:              "2026-07",
		SourceLanguage:         model.LanguageRussian,
		TargetLanguage:         model.LanguageKazakh,
		ContentType:            model.ContentTypeExcursion,
		BillingMode:            model.BillingModeFreeOnly,
		Characters:             17,
		MonthlyLimit:           2_000_000,
		QuotaWarningThreshold:  0.80,
		QuotaCriticalThreshold: 0.95,
		ReservedAt:             time.Date(2026, 7, 10, 3, 41, 0, 0, time.UTC),
	}

	result, err := repo.ReserveMonthlyUsage(ctx, reservation)
	if err != nil {
		t.Fatalf("ReserveMonthlyUsage() error = %v", err)
	}
	if !result.Allowed || result.WarningReached || result.CriticalReached {
		t.Fatalf("reservation result = %#v, want allowed with threshold flags cleared", result)
	}

	err = repo.ReleaseMonthlyUsage(ctx, model.UsageRelease{
		Provider:       reservation.Provider,
		Environment:    reservation.Environment,
		YearMonth:      reservation.YearMonth,
		SourceLanguage: reservation.SourceLanguage,
		TargetLanguage: reservation.TargetLanguage,
		ContentType:    reservation.ContentType,
		Characters:     reservation.Characters,
		ReleasedAt:     reservation.ReservedAt.Add(time.Second),
	})
	if err != nil {
		t.Fatalf("ReleaseMonthlyUsage() error = %v", err)
	}

	var reservedCharacters int
	var warningReached bool
	var criticalReached bool
	err = pool.QueryRow(ctx, `
SELECT reserved_characters, warning_reached, critical_reached
FROM translation_usage_monthly
WHERE provider = $1
  AND environment = $2
  AND year_month = $3
  AND source_language = $4
  AND target_language = $5
  AND content_type = $6
`,
		reservation.Provider,
		reservation.Environment,
		reservation.YearMonth,
		string(reservation.SourceLanguage),
		string(reservation.TargetLanguage),
		string(reservation.ContentType),
	).Scan(&reservedCharacters, &warningReached, &criticalReached)
	if err != nil {
		t.Fatalf("query usage row: %v", err)
	}
	if reservedCharacters != 0 || warningReached || criticalReached {
		t.Fatalf("released row = reserved:%d warning:%t critical:%t, want 0/false/false", reservedCharacters, warningReached, criticalReached)
	}
}
