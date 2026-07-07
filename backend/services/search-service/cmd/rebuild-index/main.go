package main

import (
	"context"
	"flag"
	"fmt"
	"io"
	"os"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/search-service/internal/adapter/repository"
	"kz/inflap/backend/services/search-service/internal/app"
	"kz/inflap/backend/services/search-service/internal/config"
)

func main() {
	var inputPath string
	var domain string
	var countryCode string
	var cityID string
	var dryRun bool
	flag.StringVar(&inputPath, "input", "-", "NDJSON search document export path, or - for stdin")
	flag.StringVar(&domain, "domain", "", "optional search domain filter")
	flag.StringVar(&countryCode, "country-code", "", "optional country code filter")
	flag.StringVar(&cityID, "city-id", "", "optional city id filter")
	flag.BoolVar(&dryRun, "dry-run", false, "validate input without writing to the index")
	flag.Parse()

	ctx := context.Background()
	cfg, err := config.Load(ctx)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to load config")
	}
	if cfg.Database.DSN == "" {
		log.Fatal().Msg("DATABASE_DSN is required")
	}

	reader, closeReader, err := openInput(inputPath)
	if err != nil {
		log.Fatal().Err(err).Str("input", inputPath).Msg("failed to open rebuild input")
	}
	defer closeReader()

	pool, err := pgxpool.New(ctx, cfg.Database.DSN)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to connect database")
	}
	defer pool.Close()

	indexing := app.NewIndexingUseCase(repository.NewPGSearchRepository(pool))
	rebuild := app.NewRebuildUseCase(indexing)
	stats, err := rebuild.RebuildFromJSONLines(ctx, reader, app.RebuildOptions{
		Domain:      domain,
		CountryCode: countryCode,
		CityID:      cityID,
		DryRun:      dryRun,
	})
	if err != nil {
		log.Fatal().Err(err).Msg("failed to rebuild search index")
	}

	fmt.Printf(
		"search index rebuild completed: scanned=%d upserted=%d skipped=%d dry_run_validated=%d\n",
		stats.Scanned,
		stats.Upserted,
		stats.Skipped,
		stats.DryRunValidated,
	)
}

func openInput(path string) (io.Reader, func(), error) {
	if path == "" || path == "-" {
		return os.Stdin, func() {}, nil
	}
	file, err := os.Open(path)
	if err != nil {
		return nil, func() {}, err
	}
	return file, func() { _ = file.Close() }, nil
}
