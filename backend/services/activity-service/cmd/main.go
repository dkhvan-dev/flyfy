package main

import (
	"context"
	"log"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	grpcadapter "github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/adapter/grpc"
	httpadapter "github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/adapter/http"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/adapter/repository"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/config"
	activityv1 "github.com/dkhvan-dev/flyfy/proto/gen/go/activity/v1"
	"github.com/jackc/pgx/v5/pgxpool"
	"google.golang.org/grpc"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("load config: %v", err)
	}

	ctx := context.Background()

	poolCfg, err := pgxpool.ParseConfig(cfg.DatabaseURL())
	if err != nil {
		log.Fatalf("parse db config: %v", err)
	}

	poolCfg.MaxConns = cfg.DB.MaxConns
	poolCfg.MinConns = cfg.DB.MinConns
	poolCfg.MaxConnIdleTime = cfg.DB.MaxConnIdle
	poolCfg.MaxConnLifetime = cfg.DB.MaxConnLife

	dbpool, err := pgxpool.NewWithConfig(ctx, poolCfg)
	if err != nil {
		log.Fatalf("create db pool: %v", err)
	}
	defer dbpool.Close()

	if err = dbpool.Ping(ctx); err != nil {
		log.Fatalf("ping db: %v", err)
	}

	repo := repository.NewPGActivityRepository(dbpool)

	activityUC := app.NewActivityUseCase(repo)
	joinUC := app.NewJoinUseCase(repo)
	searchUC := app.NewSearchUseCase(repo)
	moderationUC := app.NewModerationUseCase(activityUC)

	httpHandler := httpadapter.NewHandler(activityUC, joinUC, repo)

	httpMux := http.NewServeMux()
	httpHandler.Register(httpMux)

	httpRootHandler := httpadapter.Chain(
		httpadapter.IdentityMiddleware,
	)(httpMux)

	httpServer := &http.Server{
		Addr:              ":" + cfg.HTTP.Port,
		Handler:           httpRootHandler,
		ReadHeaderTimeout: 10 * time.Second,
		ReadTimeout:       20 * time.Second,
		WriteTimeout:      20 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	grpcServer := grpc.NewServer()
	activityGRPCServer := grpcadapter.NewServer(
		activityUC,
		joinUC,
		searchUC,
		moderationUC,
	)
	activityv1.RegisterActivityServiceServer(grpcServer, activityGRPCServer)

	grpcLis, err := net.Listen("tcp", ":"+cfg.GRPC.Port)
	if err != nil {
		log.Fatalf("listen grpc: %v", err)
	}

	httpErrCh := make(chan error, 1)
	grpcErrCh := make(chan error, 1)

	go func() {
		log.Printf("%s HTTP started on :%s", cfg.App.Name, cfg.HTTP.Port)
		if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			httpErrCh <- err
			return
		}
		httpErrCh <- nil
	}()

	go func() {
		log.Printf("%s gRPC started on :%s", cfg.App.Name, cfg.GRPC.Port)
		if err := grpcServer.Serve(grpcLis); err != nil {
			grpcErrCh <- err
			return
		}
		grpcErrCh <- nil
	}()

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)

	select {
	case sig := <-stop:
		log.Printf("received shutdown signal: %s", sig.String())
	case err := <-httpErrCh:
		if err != nil {
			log.Fatalf("http server failed: %v", err)
		}
	case err := <-grpcErrCh:
		if err != nil {
			log.Fatalf("grpc server failed: %v", err)
		}
	}

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	log.Printf("shutting down %s", cfg.App.Name)

	if err := httpServer.Shutdown(shutdownCtx); err != nil {
		log.Printf("http shutdown failed: %v", err)
	}

	done := make(chan struct{})
	go func() {
		grpcServer.GracefulStop()
		close(done)
	}()

	select {
	case <-done:
		log.Printf("grpc server stopped gracefully")
	case <-time.After(10 * time.Second):
		log.Printf("grpc graceful stop timeout reached, forcing stop")
		grpcServer.Stop()
	}

	log.Printf("%s stopped", cfg.App.Name)
}
