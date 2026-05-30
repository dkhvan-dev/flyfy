.PHONY: build run test lint proto migrate docker clean help

# Variables
APP_NAME     := token-service
CMD_DIR      := ./cmd
BUILD_DIR    := ./bin
PROTO_DIR    := ./proto
MIGRATIONS   := ./migrations
DOCKER_IMAGE := tourism-inflap/$(APP_NAME)

# Go settings
GOFLAGS := -v
LDFLAGS := -s -w

# ============================================
# Build & Run
# ============================================

build: ## Build the binary
	@echo "→ Building $(APP_NAME)..."
	@mkdir -p $(BUILD_DIR)
	go build $(GOFLAGS) -ldflags="$(LDFLAGS)" -o $(BUILD_DIR)/$(APP_NAME) $(CMD_DIR)/

run: build ## Build and run
	@echo "→ Running $(APP_NAME)..."
	$(BUILD_DIR)/$(APP_NAME)

run-dev: ## Run with live reload (requires air)
	air -c .air.toml

# ============================================
# Testing
# ============================================

test: ## Run unit tests
	go test -race -count=1 ./...

test-cover: ## Run tests with coverage
	go test -race -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html
	@echo "→ Coverage report: coverage.html"

test-integration: ## Run integration tests (requires running infra)
	go test -race -tags=integration -count=1 ./...

# ============================================
# Code Quality
# ============================================

lint: ## Run linters
	golangci-lint run ./...

fmt: ## Format code
	gofumpt -l -w .
	goimports -l -w .

vet: ## Run go vet
	go vet ./...

# ============================================
# Proto
# ============================================

proto: ## Generate protobuf Go code
	@echo "→ Generating protobuf..."
	protoc \
		--proto_path=$(PROTO_DIR) \
		--go_out=$(PROTO_DIR) --go_opt=paths=source_relative \
		--go-grpc_out=$(PROTO_DIR) --go-grpc_opt=paths=source_relative \
		$(PROTO_DIR)/token/token.proto

# ============================================
# Database
# ============================================

migrate-up: ## Run migrations up
	migrate -path $(MIGRATIONS) -database "$$PG_DSN" up

migrate-down: ## Rollback last migration
	migrate -path $(MIGRATIONS) -database "$$PG_DSN" down 1

migrate-create: ## Create new migration (usage: make migrate-create NAME=add_table)
	migrate create -ext sql -dir $(MIGRATIONS) -seq $(NAME)

# ============================================
# Docker
# ============================================

docker-build: ## Build Docker image
	docker build -t $(DOCKER_IMAGE):latest .

docker-run: ## Run in Docker
	docker run --rm -p 50051:50051 -p 8081:8081 \
		--env-file .env \
		$(DOCKER_IMAGE):latest

docker-compose-up: ## Start all dependencies
	docker compose -f deploy/docker-compose.yml up -d

docker-compose-down: ## Stop all dependencies
	docker compose -f deploy/docker-compose.yml down

# ============================================
# Utilities
# ============================================

clean: ## Clean build artifacts
	rm -rf $(BUILD_DIR) coverage.out coverage.html

deps: ## Download dependencies
	go mod download
	go mod tidy

tools: ## Install development tools
	go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
	go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	go install mvdan.cc/gofumpt@latest
	go install golang.org/x/tools/cmd/goimports@latest
	go install github.com/air-verse/air@latest
	go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help