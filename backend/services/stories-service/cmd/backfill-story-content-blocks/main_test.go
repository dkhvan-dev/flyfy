package main

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"reflect"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/stories-service/internal/domain/model"
)

func TestValidateBackfillOptionsRejectsNegativeLimit(t *testing.T) {
	_, err := validateBackfillOptions(backfillOptions{Limit: -1, BatchSize: 10})
	if err == nil {
		t.Fatal("validateBackfillOptions() error = nil, want error")
	}
}

func TestValidateBackfillOptionsRejectsInvalidBatchSize(t *testing.T) {
	for _, batchSize := range []int{0, -1} {
		t.Run(fmt.Sprintf("batch size %d", batchSize), func(t *testing.T) {
			_, err := validateBackfillOptions(backfillOptions{Limit: 0, BatchSize: batchSize})
			if err == nil {
				t.Fatal("validateBackfillOptions() error = nil, want error")
			}
		})
	}
}

func TestValidateBackfillOptionsRejectsTooLargeBatchSize(t *testing.T) {
	_, err := validateBackfillOptions(backfillOptions{Limit: 0, BatchSize: maxBatchSize + 1})
	if err == nil {
		t.Fatal("validateBackfillOptions() error = nil, want error")
	}
}

func TestApplyPostgresRuntimeTimeouts(t *testing.T) {
	poolCfg, err := pgxpool.ParseConfig("postgres://user:pass@localhost:5432/stories?sslmode=disable")
	if err != nil {
		t.Fatalf("ParseConfig() error = %v", err)
	}

	applyPostgresRuntimeTimeouts(poolCfg)

	if got := poolCfg.ConnConfig.RuntimeParams["lock_timeout"]; got != postgresLockTimeout.String() {
		t.Fatalf("lock_timeout = %q, want %q", got, postgresLockTimeout.String())
	}
	if got := poolCfg.ConnConfig.RuntimeParams["statement_timeout"]; got != postgresStatementTimeout.String() {
		t.Fatalf("statement_timeout = %q, want %q", got, postgresStatementTimeout.String())
	}
}

func TestBackfillDryRunDoesNotUpdate(t *testing.T) {
	store := &fakeBackfillStore{
		rows: []legacyStoryRow{
			{ID: uuid.MustParse("11111111-1111-1111-1111-111111111111"), Content: "Text\n\n[[story-image:file-1]]"},
		},
	}

	stats, err := backfill(context.Background(), store, backfillOptions{DryRun: true, Limit: 0, BatchSize: 10})
	if err != nil {
		t.Fatalf("backfill() error = %v", err)
	}

	if store.updateCalls != 0 {
		t.Fatalf("updateCalls = %d, want 0", store.updateCalls)
	}
	if stats.Scanned != 1 || stats.Converted != 1 || stats.Updated != 0 || stats.Failed != 0 {
		t.Fatalf("stats = %+v, want one converted dry-run row", stats)
	}
}

func TestBackfillHonorsLimitAcrossPages(t *testing.T) {
	store := &fakeBackfillStore{
		rows: []legacyStoryRow{
			{ID: uuid.MustParse("11111111-1111-1111-1111-111111111111"), Content: "One"},
			{ID: uuid.MustParse("22222222-2222-2222-2222-222222222222"), Content: "Two"},
			{ID: uuid.MustParse("33333333-3333-3333-3333-333333333333"), Content: "Three"},
			{ID: uuid.MustParse("44444444-4444-4444-4444-444444444444"), Content: "Four"},
		},
		updateResults: []bool{true, true, true, true},
	}

	stats, err := backfill(context.Background(), store, backfillOptions{Limit: 3, BatchSize: 2})
	if err != nil {
		t.Fatalf("backfill() error = %v", err)
	}

	if stats.Scanned != 3 || stats.Updated != 3 {
		t.Fatalf("stats = %+v, want scanned=3 updated=3", stats)
	}
	if store.updateCalls != 3 {
		t.Fatalf("updateCalls = %d, want 3", store.updateCalls)
	}
	if got, want := store.loadLimits, []int{2, 1}; !reflect.DeepEqual(got, want) {
		t.Fatalf("load limits = %v, want %v", got, want)
	}
}

func TestBackfillContinuesWhenUpdateAffectsNoRows(t *testing.T) {
	store := &fakeBackfillStore{
		rows: []legacyStoryRow{
			{ID: uuid.MustParse("11111111-1111-1111-1111-111111111111"), Content: "One"},
			{ID: uuid.MustParse("22222222-2222-2222-2222-222222222222"), Content: "Two"},
		},
		updateResults: []bool{false, true},
	}

	stats, err := backfill(context.Background(), store, backfillOptions{Limit: 0, BatchSize: 10})
	if err != nil {
		t.Fatalf("backfill() error = %v", err)
	}

	if stats.Skipped != 1 || stats.Updated != 1 || stats.Failed != 0 {
		t.Fatalf("stats = %+v, want skipped=1 updated=1 failed=0", stats)
	}
}

func TestBackfillContinuesAfterFailedRowUpdate(t *testing.T) {
	store := &fakeBackfillStore{
		rows: []legacyStoryRow{
			{ID: uuid.MustParse("11111111-1111-1111-1111-111111111111"), Content: "One"},
			{ID: uuid.MustParse("22222222-2222-2222-2222-222222222222"), Content: "Two"},
		},
		updateErrors:  []error{errors.New("lock timeout"), nil},
		updateResults: []bool{false, true},
	}

	stats, err := backfill(context.Background(), store, backfillOptions{Limit: 0, BatchSize: 10})
	if err != nil {
		t.Fatalf("backfill() error = %v", err)
	}

	if stats.Failed != 1 || stats.Updated != 1 || stats.Skipped != 0 {
		t.Fatalf("stats = %+v, want failed=1 updated=1 skipped=0", stats)
	}
}

type fakeBackfillStore struct {
	rows          []legacyStoryRow
	loadLimits    []int
	updateCalls   int
	updateErrors  []error
	updateResults []bool
}

func (s *fakeBackfillStore) LoadLegacyStoryRows(_ context.Context, after uuid.UUID, limit int) ([]legacyStoryRow, error) {
	s.loadLimits = append(s.loadLimits, limit)

	result := make([]legacyStoryRow, 0, limit)
	for _, row := range s.rows {
		if bytes.Compare(row.ID[:], after[:]) <= 0 {
			continue
		}
		result = append(result, row)
		if len(result) >= limit {
			break
		}
	}
	return result, nil
}

func (s *fakeBackfillStore) UpdateStoryDocument(_ context.Context, _ uuid.UUID, _ model.StoryDocument) (bool, error) {
	callIndex := s.updateCalls
	s.updateCalls++

	if callIndex < len(s.updateErrors) && s.updateErrors[callIndex] != nil {
		return false, s.updateErrors[callIndex]
	}
	if callIndex < len(s.updateResults) {
		return s.updateResults[callIndex], nil
	}
	return true, nil
}
