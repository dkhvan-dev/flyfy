package main

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/saved-service/internal/adapter/repository"
	savedsearchmigration "kz/inflap/backend/services/saved-service/internal/app/savedsearchmigration"
)

const connectTimeout = 10 * time.Second

type commandConfig struct {
	Mode             string
	BatchSize        int
	MaxBatches       int
	Pause            time.Duration
	LockTimeout      time.Duration
	StatementTimeout time.Duration
	ContractTimeout  time.Duration
}

type statusOutput struct {
	Mode   string                      `json:"mode"`
	Ready  bool                        `json:"ready"`
	Status savedsearchmigration.Status `json:"status"`
}

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	if err := run(ctx, os.Args[1:], os.Stdout); err != nil {
		_, _ = fmt.Fprintf(os.Stderr, "saved search migration command failed: %v\n", err)
		os.Exit(1)
	}
}

func run(ctx context.Context, arguments []string, output io.Writer) error {
	config, err := parseFlags(arguments)
	if err != nil {
		return err
	}
	poolConfig, err := pgxpool.ParseConfig("")
	if err != nil {
		return fmt.Errorf("parse PostgreSQL environment: %w", err)
	}
	poolConfig.MaxConns = 2
	poolConfig.MinConns = 0

	connectCtx, cancel := context.WithTimeout(ctx, connectTimeout)
	defer cancel()
	pool, err := pgxpool.NewWithConfig(connectCtx, poolConfig)
	if err != nil {
		return fmt.Errorf("open PostgreSQL pool: %w", err)
	}
	defer pool.Close()
	if err := pool.Ping(connectCtx); err != nil {
		return fmt.Errorf("ping PostgreSQL: %w", err)
	}

	store, err := repository.NewPGSavedSearchMigrationRepository(
		pool,
		repository.SavedSearchMigrationOptions{
			LockTimeout:      config.LockTimeout,
			StatementTimeout: config.StatementTimeout,
			ContractTimeout:  config.ContractTimeout,
		},
	)
	if err != nil {
		return err
	}
	service, err := savedsearchmigration.NewService(store, savedsearchmigration.Config{
		BatchSize:  config.BatchSize,
		MaxBatches: config.MaxBatches,
		Pause:      config.Pause,
	})
	if err != nil {
		return err
	}

	encoder := json.NewEncoder(output)
	switch config.Mode {
	case "rollout":
		result, rolloutErr := service.Rollout(ctx)
		if err := encoder.Encode(struct {
			Mode string `json:"mode"`
			savedsearchmigration.RolloutResult
		}{Mode: config.Mode, RolloutResult: result}); err != nil {
			return fmt.Errorf("encode saved search rollout status: %w", err)
		}
		return rolloutErr
	case "backfill":
		result, err := service.Backfill(ctx)
		if err != nil {
			return err
		}
		return encoder.Encode(result)
	case "contract":
		status, err := service.Contract(ctx)
		if err != nil {
			return err
		}
		return encoder.Encode(statusOutput{Mode: config.Mode, Ready: status.Ready(), Status: status})
	case "status":
		status, err := service.Status(ctx)
		if err != nil {
			return err
		}
		return encoder.Encode(statusOutput{Mode: config.Mode, Ready: status.Ready(), Status: status})
	default:
		return errors.New("unsupported mode")
	}
}

func parseFlags(arguments []string) (commandConfig, error) {
	flags := flag.NewFlagSet("saved-search-backfill", flag.ContinueOnError)
	flags.SetOutput(io.Discard)
	config := commandConfig{}
	flags.StringVar(&config.Mode, "mode", "status", "status, backfill, contract, or rollout")
	flags.IntVar(&config.BatchSize, "batch-size", 500, "rows per transaction")
	flags.IntVar(&config.MaxBatches, "max-batches", 100, "transactions per invocation")
	flags.DurationVar(&config.Pause, "pause", 25*time.Millisecond, "pause between batches")
	flags.DurationVar(&config.LockTimeout, "lock-timeout", time.Second, "PostgreSQL lock timeout")
	flags.DurationVar(&config.StatementTimeout, "statement-timeout", 10*time.Second, "backfill statement timeout")
	flags.DurationVar(&config.ContractTimeout, "contract-timeout", 30*time.Minute, "constraint validation timeout")
	if err := flags.Parse(arguments); err != nil {
		return commandConfig{}, err
	}
	if flags.NArg() != 0 {
		return commandConfig{}, errors.New("positional arguments are not supported")
	}
	config.Mode = strings.ToLower(strings.TrimSpace(config.Mode))
	switch config.Mode {
	case "status", "backfill", "contract", "rollout":
	default:
		return commandConfig{}, errors.New("mode must be status, backfill, contract, or rollout")
	}
	if err := (savedsearchmigration.Config{
		BatchSize:  config.BatchSize,
		MaxBatches: config.MaxBatches,
		Pause:      config.Pause,
	}).Validate(); err != nil {
		return commandConfig{}, err
	}
	if err := (repository.SavedSearchMigrationOptions{
		LockTimeout:      config.LockTimeout,
		StatementTimeout: config.StatementTimeout,
		ContractTimeout:  config.ContractTimeout,
	}).Validate(); err != nil {
		return commandConfig{}, err
	}
	return config, nil
}
